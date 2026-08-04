{ ************************************************************************** }
{                                                                            }
{ ParseJit.Decoder                                                           }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseJit.Decoder;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, BaseTypes, ParseConsts, ParseTypes, Parser, ValueTypes, ValueUtils;
  {$ELSE}
  System.SysUtils, BaseTypes, ParseConsts, ParseTypes, Parser, ValueTypes, ValueUtils;
  {$ENDIF}

type
  TJitOpcode = (
    joTermBegin,
    joTermEnd,
    joConst,
    joString,
    joCall,
    joVariable,
    joScriptBegin,
    joScriptEnd,
    joParameterBegin,
    joParameterEnd);

  TJitClass = (jcUnknown, jcInt, jcFloat, jcString, jcMixed);

  TJitOp = record
    Code: TJitOpcode;
    Depth: Integer;
    Offset: NativeInt;
    Value: TValue;
    Handle: NativeInt;
    AFunction: PFunction;
    Variable: PValue;
    VariableRef: Pointer;
    VariableType: TValueType;
    Sign: NativeInt;
    UserType: TUserType;
    ValueClass: TJitClass;
    Name: string;
    Text: string;
    ParameterCount: NativeInt;
    Lazy: Boolean;
  end;
  TJitOpArray = array of TJitOp;

  TJitAssumption = record
    Source, Target: NativeInt;
  end;
  TJitAssumptionArray = array of TJitAssumption;

  TJitDecoder = class
  private
    FParser: TParser;
    FOps: TJitOpArray;
    FCount: Integer;
    FSupported: Boolean;
    FReason: string;
    FScriptSize: NativeInt;
    FMaxDepth: Integer;
    FBase: NativeInt;
    FCategory: NativeInt;
    FAssumptions: TJitAssumptionArray;
    FAssumptionCount: Integer;
    function Resolve(var AHandle: NativeInt; var AFunction: PFunction): Boolean;
    function Add(const Code: TJitOpcode; const Depth: Integer; const Offset: NativeInt): Integer;
    procedure DecodeScript(const Index: NativeInt; const Depth: Integer);
    procedure Infer;
    function GetOp(Index: Integer): TJitOp;
  protected
    procedure Reject(const AReason: string); virtual;
  public
    constructor Create(const AParser: TParser); virtual;
    function Decode(const Script: TScript): Boolean; virtual;
    function Dump: string; virtual;
    function CallCount: Integer; virtual;
    function VariableCount: Integer; virtual;
    function Valid: Boolean; virtual;
    property Count: Integer read FCount;
    property Op[Index: Integer]: TJitOp read GetOp; default;
    property Ops: TJitOpArray read FOps;
    property Supported: Boolean read FSupported;
    property Reason: string read FReason;
    property ScriptSize: NativeInt read FScriptSize;
    property MaxDepth: Integer read FMaxDepth;
    property Category: NativeInt read FCategory;
    property AssumptionCount: Integer read FAssumptionCount;
  end;

function ClassOfType(const AValueType: TValueType): TJitClass;
function DumpScript(const AParser: TParser; const Script: TScript): string;

implementation

uses
  TextBuilder;

const
  OpcodeName: array[TJitOpcode] of string = (
    'term.begin', 'term.end', 'const', 'string', 'call', 'var',
    'script.begin', 'script.end', 'param.begin', 'param.end');
  ClassText: array[TJitClass] of string = ('?', 'int', 'float', 'str', 'mixed');
  MaxRedirectHop = 64;

function ClassOfType(const AValueType: TValueType): TJitClass;
begin
  case AValueType of
    ValueTypes.vtByte, ValueTypes.vtShortint, ValueTypes.vtWord, ValueTypes.vtSmallint, ValueTypes.vtLongWord, ValueTypes.vtInteger, ValueTypes.vtNativeInt, ValueTypes.vtNativeUInt, ValueTypes.vtInt64: Result := jcInt;
    ValueTypes.vtSingle, ValueTypes.vtDouble, ValueTypes.vtExtended: Result := jcFloat;
  else
    Result := jcUnknown;
  end;
end;

constructor TJitDecoder.Create(const AParser: TParser);
begin
  inherited Create;
  FParser := AParser;
end;

function TJitDecoder.Add(const Code: TJitOpcode; const Depth: Integer; const Offset: NativeInt): Integer;
begin
  if FCount = Length(FOps) then SetLength(FOps, (FCount * 2) + 32);
  Result := FCount;
  Inc(FCount);
  Finalize(FOps[Result]);
  FillChar(FOps[Result], SizeOf(TJitOp), 0);
  FOps[Result].Code := Code;
  FOps[Result].Depth := Depth;
  FOps[Result].Offset := Offset - FBase;
  if Depth > FMaxDepth then FMaxDepth := Depth;
end;

function TJitDecoder.Resolve(var AHandle: NativeInt; var AFunction: PFunction): Boolean;
var
  Source, Target: NativeInt;
  BFunction: PFunction;
  Hop, Index: Integer;
begin
  Result := True;
  if FCategory = 0 then Exit;
  Source := AHandle;
  Hop := 0;
  while FParser.GetRedirect(FCategory, AFunction.Handle^, Target) do
  begin
    BFunction := FParser.GetFunction(Target);
    if not Assigned(BFunction) then Break;
    AFunction := BFunction;
    AHandle := Target;
    Inc(Hop);
    if Hop > MaxRedirectHop then
    begin
      Reject('redirect loop');
      Exit(False);
    end;
  end;
  if Hop = 0 then Exit;
  Index := FAssumptionCount;
  if Index = Length(FAssumptions) then SetLength(FAssumptions, (Index * 2) + 8);
  FAssumptions[Index].Source := Source;
  FAssumptions[Index].Target := AHandle;
  Inc(FAssumptionCount);
end;

procedure TJitDecoder.Reject(const AReason: string);
begin
  if FSupported then
  begin
    FSupported := False;
    FReason := AReason;
  end;
end;

procedure TJitDecoder.DecodeScript(const Index: NativeInt; const Depth: Integer);
var
  Header: PScriptHeader;
  ItemHeader: PItemHeader;
  Item: PScriptItem;
  Position, ItemStart, Size, AHandle: NativeInt;
  K: Integer;
  AFunction: PFunction;
begin
  Header := PScriptHeader(Index);
  Position := Index + Header.HeaderSize;
  while Position - Index < Header.ScriptSize do
  begin
    ItemHeader := PItemHeader(Position);
    ItemStart := Position;
    if (ItemHeader.Size <= 0) or (ItemStart + ItemHeader.Size > Index + Header.ScriptSize) then
    begin
      Reject('broken item header');
      Exit;
    end;
    K := Add(joTermBegin, Depth, Position);
    FOps[K].Sign := ItemHeader.Sign;
    FOps[K].UserType := ItemHeader.UserType;
    Inc(Position, SizeOf(TItemHeader));
    while Position - ItemStart < ItemHeader.Size do
    begin
      Item := PScriptItem(Position);
      case Item.Code of
        NumberCode:
          begin
            K := Add(joConst, Depth, Position);
            FOps[K].Value := Item.ScriptNumber.Value;
            Inc(Position, SizeOf(TCode) + SizeOf(TScriptNumber));
          end;
        StringCode:
          begin
            K := Add(joString, Depth, Position);
            Size := Item.ScriptString.Size;
            SetString(FOps[K].Text, PChar(Position + SizeOf(TCode) + SizeOf(TScriptString)), Size div SizeOf(Char));
            Inc(Position, SizeOf(TCode) + SizeOf(TScriptString) + Size);
          end;
        FunctionCode:
          begin
            AHandle := Item.ScriptFunction.Handle;
            AFunction := FParser.GetFunction(AHandle);
            if not Assigned(AFunction) then
            begin
              Reject('unknown function handle ' + IntToStr(AHandle));
              Exit;
            end;
            if not Resolve(AHandle, AFunction) then Exit;
            if AFunction.Method.MethodType = mtVariable then
            begin
              K := Add(joVariable, Depth, Position);
              if AFunction.Method.Variable.VariableType = ParseTypes.vtValue then
              begin
                FOps[K].Variable := AFunction.Method.Variable.Variable;
                if Assigned(FOps[K].Variable) then
                  FOps[K].VariableType := FOps[K].Variable.ValueType;
              end
              else begin
                FOps[K].VariableRef := AFunction.Method.Variable.VariableRef.Float64;
                FOps[K].VariableType := AFunction.Method.Variable.VariableRef.ValueType;
              end;
            end
            else
              K := Add(joCall, Depth, Position);
            FOps[K].Handle := AHandle;
            FOps[K].AFunction := AFunction;
            FOps[K].Name := AFunction.Name;
            FOps[K].ParameterCount := AFunction.Method.Parameter.Count;
            FOps[K].Lazy := AFunction.Method.Parameter.Kind = pkReference;
            Inc(Position, SizeOf(TCode) + SizeOf(TScriptFunction));
          end;
        ScriptCode:
          begin
            Add(joScriptBegin, Depth, Position);
            DecodeScript(NativeInt(@Item.Script.Header), Depth + 1);
            if not FSupported then Exit;
            Add(joScriptEnd, Depth, Position);
            Inc(Position, SizeOf(TCode) + Item.Script.Header.ScriptSize);
          end;
        ParameterCode:
          begin
            Add(joParameterBegin, Depth, Position);
            DecodeScript(NativeInt(@Item.Script.Header), Depth + 1);
            if not FSupported then Exit;
            Add(joParameterEnd, Depth, Position);
            Inc(Position, SizeOf(TCode) + Item.Script.Header.ScriptSize);
          end;
      else
        Reject('unknown element code ' + IntToStr(Item.Code));
        Exit;
      end;
    end;
    if Position - ItemStart <> ItemHeader.Size then
    begin
      Reject('item size mismatch');
      Exit;
    end;
    Add(joTermEnd, Depth, Position);
  end;
  if Position - Index <> Header.ScriptSize then Reject('script size mismatch');
end;

procedure TJitDecoder.Infer;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    case FOps[I].Code of
      joConst: FOps[I].ValueClass := ClassOfType(FOps[I].Value.ValueType);
      joString: FOps[I].ValueClass := jcString;
      joVariable: FOps[I].ValueClass := ClassOfType(FOps[I].VariableType);
      joCall:
        if Assigned(FOps[I].AFunction) then
          FOps[I].ValueClass := ClassOfType(FOps[I].AFunction.ReturnType);
    end;
end;

function TJitDecoder.Decode(const Script: TScript): Boolean;
begin
  FCount := 0;
  FMaxDepth := 0;
  FOps := nil;
  FReason := '';
  FSupported := Assigned(Script) and Assigned(FParser);
  if not FSupported then
  begin
    FReason := 'no script or parser';
    Result := False;
    Exit;
  end;
  FScriptSize := PScriptHeader(Script).ScriptSize;
  FBase := NativeInt(Script);
  FCategory := PScriptHeader(Script).RedirectCategory;
  FAssumptionCount := 0;
  DecodeScript(NativeInt(Script), 0);
  if FSupported then Infer;
  Result := FSupported;
end;

function TJitDecoder.CallCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FCount - 1 do
    if FOps[I].Code = joCall then Inc(Result);
end;

function TJitDecoder.VariableCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FCount - 1 do
    if FOps[I].Code = joVariable then Inc(Result);
end;

function TJitDecoder.Valid: Boolean;
var
  I, Hop: Integer;
  AFunction: PFunction;
  Target: NativeInt;
begin
  for I := 0 to FAssumptionCount - 1 do
  begin
    AFunction := FParser.GetFunction(FAssumptions[I].Source);
    if not Assigned(AFunction) then Exit(False);
    Hop := 0;
    while FParser.GetRedirect(FCategory, AFunction.Handle^, Target) do
    begin
      AFunction := FParser.GetFunction(Target);
      if not Assigned(AFunction) then Exit(False);
      Inc(Hop);
      if Hop > MaxRedirectHop then Exit(False);
    end;
    if (Hop = 0) or (AFunction.Handle^ <> FAssumptions[I].Target) then
      Exit(False);
  end;
  Result := True;
end;

function TJitDecoder.GetOp(Index: Integer): TJitOp;
begin
  if (Index < 0) or (Index >= FCount) then
    raise Exception.Create('jit op index out of range');
  Result := FOps[Index];
end;

function TJitDecoder.Dump: string;
var
  B: TTextBuilder;
  I: Integer;
  Line, Indent: string;
begin
  B := TTextBuilder.Create;
  try
    for I := 0 to FCount - 1 do
    begin
      Indent := StringOfChar(' ', FOps[I].Depth * 2);
      Line := Format('%4d %6d  %s%-13s', [I, FOps[I].Offset, Indent, OpcodeName[FOps[I].Code]]);
      case FOps[I].Code of
        joTermBegin:
          begin
            if FOps[I].Sign <> 0 then Line := Line + ' sign=-';
            if FOps[I].UserType.Active then
              Line := Line + Format(' type=%d', [FOps[I].UserType.Handle]);
          end;
        joConst:
          Line := Line + ' ' + ValueToText(FOps[I].Value) + ' [' + ClassText[FOps[I].ValueClass] + ']';
        joString: Line := Line + ' "' + FOps[I].Text + '"';
        joCall:
          begin
            Line := Line + ' ' + FOps[I].Name + Format(' #%d', [FOps[I].Handle]);
            if FOps[I].ParameterCount > 0 then
              Line := Line + Format(' params=%d', [FOps[I].ParameterCount]);
            if FOps[I].Lazy then Line := Line + ' lazy';
            Line := Line + ' [' + ClassText[FOps[I].ValueClass] + ']';
          end;
        joVariable:
          begin
            Line := Line + ' ' + FOps[I].Name;
            if Assigned(FOps[I].Variable) then
              Line := Line + ' value@' + IntToHex(NativeInt(FOps[I].Variable), 8)
            else
              if Assigned(FOps[I].VariableRef) then
                Line := Line + ' ref@' + IntToHex(NativeInt(FOps[I].VariableRef), 8);
            Line := Line + ' [' + ClassText[FOps[I].ValueClass] + ']';
          end;
      end;
      B.Append(Line, sLineBreak)
    end;
    Result := B.Text;
  finally
    B.Free;
  end;
end;

function DumpScript(const AParser: TParser; const Script: TScript): string;
var
  Decoder: TJitDecoder;
begin
  Decoder := TJitDecoder.Create(AParser);
  try
    if Decoder.Decode(Script) then
      Result := Decoder.Dump
    else
      Result := 'not decoded: ' + Decoder.Reason + sLineBreak;
  finally
    Decoder.Free;
  end;
end;

end.
