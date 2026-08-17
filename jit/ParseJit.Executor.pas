{ ************************************************************************** }
{                                                                            }
{ ParseJit.Executor                                                          }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseJit.Executor;

{$B-}
{$O+}
{$R-}
{$Q-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, ParseConsts, ParseTypes, Parser, ValueConsts, ValueTypes, ValueUtils,
  ParseJit.Decoder;
  {$ELSE}
  System.SysUtils, ParseConsts, ParseTypes, Parser, ValueConsts, ValueTypes, ValueUtils,
  ParseJit.Decoder;
  {$ENDIF}

type
  TJitStepKind = (skTermBegin, skTermEnd, skConst, skVariable, skCall,
    skScriptBegin, skScriptEnd);

  TJitFastOp = (foNone, foMultiply, foDivide);

  TJitStep = record
    Kind: TJitStepKind;
    Value: TValue;
    VariablePtr: Pointer;
    VariableType: TValueType;
    AFunction: PFunction;
    MethodType: TMethodType;
    Method0: TMethod0;
    Method1: TMethod1;
    Method2: TMethod2;
    HasLeft, HasRight: Boolean;
    FastOp: TJitFastOp;
    Sign: NativeInt;
  end;
  PJitStep = ^TJitStep;
  TJitStepArray = array of TJitStep;

  TJitExecutor = class
  private
    FParser: TParser;
    FDecoder: TJitDecoder;
    FSteps: TJitStepArray;
    FCount: Integer;
    FHeader: PScriptHeader;
    FReady: Boolean;
    FReason: string;
    procedure RunScript(var Index: Integer; var Value: TValue);
    procedure RunTerm(var Index: Integer; var Value: TValue; const OneStep: Boolean);
    procedure ReadOperand(var Index: Integer; var Value: TValue);
    function Build: Boolean;
  public
    constructor Create(const AParser: TParser); virtual;
    destructor Destroy; override;
    function Prepare(const Script: TScript): Boolean; virtual;
    function Execute: TValue; virtual;
    function DumpSteps: string; virtual;
    property Ready: Boolean read FReady;
    property Reason: string read FReason;
    property StepCount: Integer read FCount;
    property Decoder: TJitDecoder read FDecoder;
  end;

implementation

uses
  TextBuilder;

function IsFloat(const Value: TValue): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
begin
  Result := Value.ValueType in [ValueTypes.vtSingle, ValueTypes.vtDouble, ValueTypes.vtExtended];
end;

function FloatOf(const Value: TValue): Extended;
begin
  case Value.ValueType of
    ValueTypes.vtDouble: Result := Value.Float64;
    ValueTypes.vtExtended: Result := Value.Float80;
    ValueTypes.vtSingle: Result := Value.Float32;
    ValueTypes.vtByte: Result := Value.Unsigned8;
    ValueTypes.vtShortint: Result := Value.Signed8;
    ValueTypes.vtWord: Result := Value.Unsigned16;
    ValueTypes.vtSmallint: Result := Value.Signed16;
    ValueTypes.vtLongWord: Result := Value.Unsigned32;
    ValueTypes.vtInteger: Result := Value.Signed32;
    ValueTypes.vtNativeInt: Result := Value.NativeInt;
    ValueTypes.vtNativeUInt: Result := Value.NativeUInt;
    ValueTypes.vtInt64: Result := Value.Signed64;
  else
    Result := 0;
  end;
end;

procedure SetFloat(var Target: TValue; const Source: Extended); {$IFDEF DELPHI_10.2}inline;{$ENDIF}
begin
  Target.Float80 := Source;
  Target.ValueType := ValueTypes.vtExtended;
end;

constructor TJitExecutor.Create(const AParser: TParser);
begin
  inherited Create;
  FParser := AParser;
  FDecoder := TJitDecoder.Create(AParser);
end;

destructor TJitExecutor.Destroy;
begin
  FDecoder.Free;
  inherited;
end;

function TJitExecutor.Build: Boolean;
var
  I, K: Integer;
  Op: TJitOp;
  AFunction: PFunction;
begin
  FCount := 0;
  SetLength(FSteps, FDecoder.Count);
  for I := 0 to FDecoder.Count - 1 do
  begin
    Op := FDecoder.Ops[I];
    K := FCount;
    FillChar(FSteps[K], SizeOf(TJitStep), 0);
    case Op.Code of
      joTermBegin:
        begin
          if Op.UserType.Active then
          begin
            FReason := 'explicit item type';
            Exit(False);
          end;
          FSteps[K].Kind := skTermBegin;
          FSteps[K].Sign := Op.Sign;
        end;
      joTermEnd: FSteps[K].Kind := skTermEnd;
      joScriptBegin: FSteps[K].Kind := skScriptBegin;
      joScriptEnd: FSteps[K].Kind := skScriptEnd;
      joConst:
        begin
          FSteps[K].Kind := skConst;
          FSteps[K].Value := Op.Value;
        end;
      joVariable:
        begin
          FSteps[K].Kind := skVariable;
          if Assigned(Op.Variable) then
          begin
            FSteps[K].VariablePtr := Op.Variable;
            FSteps[K].VariableType := ValueTypes.vtUnknown;
          end
          else if Assigned(Op.VariableRef) then
          begin
            FSteps[K].VariablePtr := Op.VariableRef;
            FSteps[K].VariableType := Op.VariableType;
          end
          else begin
            FReason := 'unbound variable ' + Op.Name;
            Exit(False);
          end;
        end;
      joCall:
        begin
          AFunction := Op.AFunction;
          if not Assigned(AFunction) then
          begin
            FReason := 'unresolved call';
            Exit(False);
          end;
          if AFunction.Method.Parameter.Count > 0 then
          begin
            FReason := 'parametric function ' + Op.Name;
            Exit(False);
          end;
          if not (AFunction.Method.MethodType in [mtMethod0, mtMethod1, mtMethod2]) then
          begin
            FReason := 'unsupported method kind ' + Op.Name;
            Exit(False);
          end;
          FSteps[K].Kind := skCall;
          FSteps[K].AFunction := AFunction;
          FSteps[K].MethodType := AFunction.Method.MethodType;
          FSteps[K].Method0 := AFunction.Method.Method0;
          FSteps[K].Method1 := AFunction.Method.Method1;
          FSteps[K].Method2 := AFunction.Method.Method2;
          FSteps[K].HasLeft := AFunction.Method.Parameter.L;
          FSteps[K].HasRight := AFunction.Method.Parameter.R;
          if AFunction.Handle^ = FParser.MultiplyHandle then
            FSteps[K].FastOp := foMultiply
          else
            if AFunction.Handle^ = FParser.DivideHandle then
              FSteps[K].FastOp := foDivide;
        end;
    else
      FReason := 'unsupported element';
      Exit(False);
    end;
    Inc(FCount);
  end;
  Result := True;
end;

function TJitExecutor.Prepare(const Script: TScript): Boolean;
begin
  FReady := False;
  FReason := '';
  if not FDecoder.Decode(Script) then
  begin
    FReason := FDecoder.Reason;
    Exit(False);
  end;
  FHeader := PScriptHeader(Script);
  FReady := Build;
  Result := FReady;
end;

procedure TJitExecutor.ReadOperand(var Index: Integer; var Value: TValue);
var
  Step: PJitStep;
begin
  Step := @FSteps[Index];
  case Step.Kind of
    skConst:
      begin
        Value := Step.Value;
        Inc(Index);
      end;
    skVariable:
      begin
        case Step.VariableType of
          ValueTypes.vtUnknown: Value := PValue(Step.VariablePtr)^;
          ValueTypes.vtDouble: AssignDouble(Value, PDouble(Step.VariablePtr)^);
          ValueTypes.vtExtended: AssignExtended(Value, PExtended(Step.VariablePtr)^);
          ValueTypes.vtSingle: AssignSingle(Value, PSingle(Step.VariablePtr)^);
          ValueTypes.vtInteger: AssignInteger(Value, PInteger(Step.VariablePtr)^);
          ValueTypes.vtInt64: AssignInt64(Value, PInt64(Step.VariablePtr)^);
          ValueTypes.vtNativeInt: AssignNativeInt(Value, PNativeInt(Step.VariablePtr)^);
          ValueTypes.vtByte: AssignByte(Value, PByte(Step.VariablePtr)^);
          ValueTypes.vtWord: AssignWord(Value, PWord(Step.VariablePtr)^);
          ValueTypes.vtLongWord: AssignLongWord(Value, PLongWord(Step.VariablePtr)^);
          ValueTypes.vtShortint: AssignShortint(Value, PShortint(Step.VariablePtr)^);
          ValueTypes.vtSmallint: AssignSmallint(Value, PSmallint(Step.VariablePtr)^);
          ValueTypes.vtNativeUInt: AssignNativeUInt(Value, PNativeUInt(Step.VariablePtr)^);
        else
          Value := EmptyValue;
        end;
        Inc(Index);
      end;
    skScriptBegin:
      begin
        Inc(Index);
        RunScript(Index, Value);
        Inc(Index);
      end;

    skCall: RunTerm(Index, Value, True);
  else
    Value := EmptyValue;
    Inc(Index);
  end;
end;

procedure TJitExecutor.RunTerm(var Index: Integer; var Value: TValue; const OneStep: Boolean);
var
  LValue, RValue: TValue;
  Step: PJitStep;
begin
  Value := EmptyValue;
  while (Index < FCount) and (FSteps[Index].Kind <> skTermEnd) do
  begin
    if FSteps[Index].Kind = skCall then
    begin
      LValue := Value;
      Step := @FSteps[Index];
      Inc(Index);
      if Step.HasRight then
        ReadOperand(Index, RValue)
      else
        RValue := EmptyValue;
      if (Step.FastOp <> foNone) and (IsFloat(LValue) or IsFloat(RValue)) and
        (LValue.ValueType <> ValueTypes.vtUnknown) and
        (RValue.ValueType <> ValueTypes.vtUnknown) then
        begin
          if Step.FastOp = foMultiply then
            SetFloat(Value, FloatOf(LValue) * FloatOf(RValue))
          else
            SetFloat(Value, FloatOf(LValue) / FloatOf(RValue));
        end
        else
          case Step.MethodType of
            mtMethod0: Value := Step.Method0(FHeader, Step.AFunction, nil);
            mtMethod1:
              if Step.HasLeft then
                Value := Step.Method1(FHeader, Step.AFunction, nil, LValue)
              else
                Value := Step.Method1(FHeader, Step.AFunction, nil, RValue);
            mtMethod2: Value := Step.Method2(FHeader, Step.AFunction, nil, LValue, RValue);
          end;
    end
    else
      ReadOperand(Index, Value);
    if OneStep then Break;
  end;
end;

procedure TJitExecutor.RunScript(var Index: Integer; var Value: TValue);
var
  TermValue: TValue;
  Sign: NativeInt;
  First: Boolean;
begin
  Value := EmptyValue;
  First := True;
  while (Index < FCount) and (FSteps[Index].Kind = skTermBegin) do
  begin
    Sign := FSteps[Index].Sign;
    Inc(Index);
    RunTerm(Index, TermValue, False);
    Inc(Index);
    if First and (Sign = 0) then
      Value := TermValue
    else if IsFloat(Value) or IsFloat(TermValue) then
    begin
      if Sign = 0 then
        SetFloat(Value, FloatOf(Value) + FloatOf(TermValue))
      else
        SetFloat(Value, FloatOf(Value) - FloatOf(TermValue));
    end
    else
      Value := Operation(Value, TermValue, TOperationType(Ord(otAdd) + Sign));
    First := False;
  end;
end;

function TJitExecutor.DumpSteps: string;
const
  KindText: array[TJitStepKind] of string = ('term.begin', 'term.end', 'const', 'var', 'call', 'script.begin', 'script.end');
var
  B: TTextBuilder;
  I: Integer;
begin
  B := TTextBuilder.Create;
  try
    for I := 0 to FCount - 1 do
      B.Append(
        Format(
          '%4d  %-12s method=%d L=%d R=%d fast=%d',
          [
            I,
            KindText[FSteps[I].Kind],
            Ord(FSteps[I].MethodType),
            Ord(FSteps[I].HasLeft),
            Ord(FSteps[I].HasRight),
            Ord(FSteps[I].FastOp)
          ]
        ),
        sLineBreak
      );
    Result := B.Text;
  finally
    B.Free;
  end;
end;

function TJitExecutor.Execute: TValue;
var
  Index: Integer;
begin
  if not FReady then
    raise Exception.Create('jit executor is not ready: ' + FReason);
  Index := 0;
  RunScript(Index, Result);
end;

end.
