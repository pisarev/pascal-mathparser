{ ************************************************************************** }
{                                                                            }
{ ParseUtils                                                                 }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Types, MemoryUtils, ParseErrors, Parser, ParseTypes, TextConsts, TextTypes,
  TextUtils, ValueTypes, ValueUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.SysUtils, System.Types, BaseTypes, MemoryUtils, ParseErrors,
  Parser, ParseTypes, TextConsts, TextTypes, TextUtils, ValueTypes, ValueUtils;
  {$ELSE}
  Windows, SysUtils, Types, MemoryUtils, ParseErrors, Parser, ParseTypes, TextConsts,
  TextTypes, TextUtils, ValueTypes, ValueUtils;
  {$ENDIF}
  {$ENDIF}

type
  TBracketMethod = function(var Text: string; const FromIndex, TillIndex: NativeInt;
    const Data: Pointer): TError of object;

  PFindData = ^TFindData;
  TFindData = record
    Code, Index, FromIndex: NativeInt;
    Item: ^PScriptItem;
  end;

  TParseHelper = class
  protected
    function FindMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function FAMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function NAMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
  public
    function FindItem(const Script: TScript; const ACode, AFromIndex: NativeInt): PScriptItem; virtual;
    procedure GetFunctionArray(const Script: TScript;
      out FArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}); virtual;
    procedure GetNumberArray(const Script: TScript; out NArray: TValueArray); virtual;
    function Optimizable(const Script: TScript; const Data: PFunctionData): Boolean;
  end;

function ParseScript(Index: NativeInt; const Method: TScriptMethod; const P: Pointer): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
procedure BuildScript(const Parser: TCustomParser; const ItemArray: TScriptArray; out Script: TScript;
  const Optimize: Boolean; Number: PNumber = nil); {$IFDEF DELPHI_10.2}inline;{$ENDIF}

function CheckFHandle(const FData: PFunctionData; const Handle: NativeInt): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function CheckTHandle(const TData: PTypeData; const Handle: NativeInt): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}

function RestoreText(const Parser: TCustomParser; const Source: string;
  out Target: string; const SA: TScriptArray;
  const Parameter: Boolean = False): NativeInt; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;
function RestoreText(const Parser: TCustomParser; const Text: string;
  const SA: TScriptArray;
  const Parameter: Boolean = False): string; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;
function RestoreText(const Parser: TCustomParser; const TextArray: TTextItemArray1;
  const SA: TScriptArray;
  const Parameter: Boolean = False): string; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;

procedure Read(const Parser: TCustomParser; var Index: NativeInt; out AFunction: PFunction); {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function ParameterToScript(const Script: TScript; const THandle: NativeInt = -1): TScript; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function GetScriptFromValue(const Parser: TCustomParser; Value: TValue;
  const TypeFlag: Boolean;
  const ScriptType: TScriptType): TScript; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;
function GetScriptFromValue(const Parser: TCustomParser; const Number: TNumber;
  const ScriptType: TScriptType): TScript; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;
function GetValueFromScript(const Parser: TCustomParser; const Script: TScript; const ScriptType: TScriptType; const UserType: PUserType = nil): TValue; {$IFDEF DELPHI_10.2}inline;{$ENDIF}

function GetParameter(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): TParameter; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsValue(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): TValue; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsByte(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Byte; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsShortint(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Shortint; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsBoolean(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;
function AsWord(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Word; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsSmallint(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Smallint; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsWordBool(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): WordBool; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsLongWord(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): LongWord; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsNativeInt(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): NativeInt; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsLongBool(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): LongBool; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsInt64(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Int64; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsSingle(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Single; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsDouble(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Double; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsExtended(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Extended; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsText(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): string; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function AsBoolean(const Parser: TCustomParser; const Header: PScriptHeader; const PA: TParameterArray; const Index: NativeInt;
  const Default: Boolean): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}overload;

function Optimal(const Script: TScript; const ScriptType: TScriptType): Boolean;
function TypeFlag(const Script: TScript; const ScriptType: TScriptType): Boolean;

function GetFFArray(const Text: string; const LockType: TLockType; const FData: PFunctionData;
  const TData: PTypeData; out FFArray: TFunctionFlagArray; const CleanText: PString = nil;
  const TypeArray: PHandleArray = nil; const Method: TFunctionFlagMethod = nil): Boolean;
function GetTIArray(const Text: string; const FData: PFunctionData; const TData: PTypeData;
  out TIArray: TTextItemArray1; const InternalHandle: NativeInt = -1;
  const LockType: TLockType = ltChar): Boolean;

function TrimPOperator(var Text: string): Boolean;
function FindSign(const Text: string; var Index: NativeInt; out Sign: Boolean): Boolean;
function GetSign(const Text: string; const Index: PNativeInt = nil): Boolean; overload;
function GetSign(const Item: TTextItem;
  const TOHArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}): Boolean; overload;
function SetSign(const Text: string): string;
function TrimFunction(const Data: PFunctionData; var Text: string; const Trim: Boolean): PFunction; overload;
function TrimType(const Data: PTypeData; const StringHandle: NativeInt; var Text: string;
  const Trim: Boolean): PType; overload;

procedure WriteItemHeader(const ItemHeader: PItemHeader; const ASign: Boolean;
  const THandle, DefaultTypeHandle: NativeInt);

function GetISIndex(const Text: string; out Parameter: Boolean): NativeInt; overload;
function GetISIndex(var Text: string; const Parameter: PBoolean): NativeInt; overload;
function GetIS(const Text: string; const SA: TScriptArray; out Parameter: Boolean): TScript;

procedure ParseBracket(var Text: string; const Bracket: TBracket; const Method: TBracketMethod;
  const Data: Pointer; out Error: TError); overload;
procedure ParseBracket(var Text: string; const Bracket: TBracket; const Method: TBracketMethod;
  const Data: Pointer); overload;
function Embrace(const Text: string; const Bracket: TBracket): string;
function InBrace(const Text: string; const Bracket: TBracket): Boolean;
procedure DeleteBracket(var Text: string; const Index: NativeInt; const Bracket: TBracket);
procedure ChangeBracket(var Text: string; const Index: NativeInt;
  const BracketFrom, BracketTo: TBracket); overload;
function BracketFunction(const AFunction: PFunction): Boolean;
procedure ChangeBracket(var Text: string; const Data: PFunctionData;
  const BracketFrom, BracketTo: TBracket); overload;

function Lower(const Text: string): string;
function Upper(const Text: string): string;
function Whole(const Text: string; const Index, Count: NativeInt): Boolean;
function FollowingText(const Text: string; const Index: NativeInt): string; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function PrecedingText(const Text: string; const Index: NativeInt): string; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function WholeValue(const Parser: TCustomParser; const Text: string; const Index, Count: NativeInt): Boolean;

function Dequote(const Text: string): string;
function DequoteDouble(const Text, FunctionName: string; const Bracket: TBracket): string;
function Quoted(const Text: string): Boolean;

function MakeTemplate(const Parser: TCustomParser; const Text: string; const ValueArray: PValueArray;
  const NumberTemplate: string = Inquiry): string;
function WriteValue(Index: NativeInt; var ValueIndex: NativeInt; const ValueArray: TValueArray;
  const ScriptType: TScriptType): Boolean;

function AddSmallint(var Target: TScript; const Value: Smallint): Integer;
function AddWord(var Target: TScript; const Value: Word): Integer;
function AddNativeInt(var Target: TScript; const Value: NativeInt): Integer;
function AddLongWord(var Target: TScript; const Value: LongWord): Integer;
function AddInt64(var Target: TScript; const Value: Int64): Integer;
function AddSingle(var Target: TScript; const Value: Single): Integer;
function AddDouble(var Target: TScript; const Value: Double): Integer;
function AddExtended(var Target: TScript; const Value: Extended): Integer;
function AddValue(var Target: TScript; const Value: TValue): Integer; overload;

function AddScriptNumber(var Target: TScript; const Value: TScriptNumber): Integer;
function AddScriptFunction(var Target: TScript; const Value: TScriptFunction): Integer;
function AddScript(var Target: TScript; const Source: TScript): Integer; overload;
function AddMemory(var Target: TScript; const Source: Pointer; const Count: NativeInt): Integer;
function AddString(var Target: TScript; const Value: string): Integer; overload;

procedure Reset(var Target: TScriptArray; var Data: TArrayData); overload;
procedure Apply(var Target: TScriptArray; const Data: TArrayData); overload;
function AddScript(var Target: TScriptArray; var Data: TArrayData; const Value: TScript): Integer; overload;
function AddScript(var Target: TScriptArray; const Value: TScript): Integer; overload;

function AddFunction(var Target: TFunctionData; const Value: TFunction): Integer;
function AddType(var Target: TTypeData; const Value: TType): Integer;

procedure Reset(var Target: TParameterArray; var Data: TArrayData); overload;
procedure Apply(var Target: TParameterArray; const Data: TArrayData); overload;
function AddParameter(var Target: TParameterArray; var Data: TArrayData;
  const Value: TParameter): Integer; overload;
function AddParameter(var Target: TParameterArray; var Data: TArrayData; const THandle: NativeInt;
  const Value: TValue): Integer; overload;
function AddParameter(var Target: TParameterArray; var Data: TArrayData; const THandle: NativeInt;
  const Text: string): Integer; overload;
function AddParameter(var Target: TParameterArray; const THandle: NativeInt;
  const Value: TValue): Integer; overload;
function AddParameter(var Target: TParameterArray; const THandle: NativeInt;
  const Text: string): Integer; overload;

procedure Reset(var Target: TFunctionFlagArray; var Data: TArrayData); overload;
procedure Apply(var Target: TFunctionFlagArray; const Data: TArrayData); overload;
function AddFlag(var Target: TFunctionFlagArray; var Data: TArrayData;
  const Value: TFunctionFlag): Integer; overload;
function AddFlag(var Target: TFunctionFlagArray; var Data: TArrayData;
  const Index, Handle: NativeInt): Integer; overload;
function AddFlag(var Target: TFunctionFlagArray; const Value: TFunctionFlag): Integer; overload;
function AddFlag(var Target: TFunctionFlagArray; const Index, Handle: NativeInt): Integer; overload;

procedure Reset(var Target: TTextItemArray1; var Data: TArrayData); overload;
procedure Apply(var Target: TTextItemArray1; const Data: TArrayData); overload;
function AddItem(var Target: TTextItemArray1; var Data: TArrayData;
  const Value: TTextItem): Integer; overload;
function AddItem(var Target: TTextItemArray1; var Data: TArrayData; const Text: string;
  const FHandle, THandle: NativeInt): Integer; overload;
function AddItem(var Target: TTextItemArray1; const Value: TTextItem): Integer; overload;
function AddItem(var Target: TTextItemArray1; const Text: string;
  const FHandle, THandle: NativeInt): Integer; overload;

function InsertInt64(var Target: TScript; Value: Int64; Index: Integer): Boolean;
function InsertNativeInt(var Target: TScript; Value: NativeInt; Index: Integer): Boolean;
function InsertByte(var Target: TScript; Value: Byte; Index: Integer): Boolean;

procedure IncNumber(var Number: TNumber; const Value: TValue); overload;
procedure IncNumber(var Number: TNumber; const Parser: TCustomParser; const Script: TScript;
  const ScriptType: TScriptType); overload;

procedure Delete(var SA: TScriptArray);

function GetFunction(const Data: PFunctionData; Index: NativeInt;
  out AFunction: PFunction): Boolean; overload;
function FunctionByIndex(const Data: PFunctionData; const Index: NativeInt): PFunction;
function FunctionCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.TValueRelationship{$ELSE}TValueRelationship{$ENDIF};
procedure FunctionExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
function Prepare(const Data: PFunctionData): Boolean; overload;

function GetType(const Data: PTypeData; Index: NativeInt; out AType: PType): Boolean; overload;
function TypeByIndex(const Data: PTypeData; const Index: NativeInt): PType;
function TypeCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.TValueRelationship{$ELSE}TValueRelationship{$ENDIF};
procedure TypeExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
function Prepare(const Data: PTypeData): Boolean; overload;

function MakeTypeHandle(const Data: TTypeData; const ValueType: TValueType;
  const DefaultTypeHandle: NativeInt): NativeInt;
function AssignUserType(const Parser: TCustomParser; const ItemHeader: PItemHeader; const TypeFlag: Boolean;
  const ValueType: TValueType): Boolean;
function GetType(const Parser: TCustomParser; const ItemHeader: PItemHeader): PType; overload;

function TestFormula(const Parser: TCustomParser; const Text: string; out Script: TScript): TError;
function FindFormula(const Parser: TCustomParser; const Text: string; out Script: TScript): Boolean;

var
  Helper: TParseHelper;

implementation

uses
  {$IFDEF FPC}
  Math, Cache, FlagCache, FlexibleList, ItemCache, NumberConsts, ParseConsts, ScriptFormat,
  StrUtils, TextBuilder, ValueConsts;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.Math, Cache, FlagCache, FlexibleList, ItemCache, NumberConsts, ParseConsts,
  ScriptFormat, StrUtils, TextBuilder, ValueConsts;
  {$ELSE}
  Math, Cache, FlagCache, FlexibleList, ItemCache, NumberConsts, ParseConsts, ScriptFormat,
  StrUtils, TextBuilder, ValueConsts;
  {$ENDIF}
  {$ENDIF}

const
  ArrayIncrement: Integer = 64;

{ TParseHelper }

function TParseHelper.FAMethod(var Index: NativeInt; const Header: PScriptHeader;
  const ItemHeader: PItemHeader; const Item: PScriptItem; const P: Pointer): Boolean;
var
  FArray: ^{$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};
begin
  FArray := P;
  case Item.Code of
    NumberCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
    FunctionCode:
      begin
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction));
        MemoryUtils.Add(FArray^, Item.ScriptFunction.Handle);
      end;
    StringCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
    ScriptCode, ParameterCode:
      begin
        ParseScript(Index + SizeOf(TCode), FAMethod, P);
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
  else
    raise Error(ScriptError);
  end;
  Result := True;
end;

function TParseHelper.FindItem(const Script: TScript; const ACode, AFromIndex: NativeInt): PScriptItem;
var
  FindData: TFindData;
begin
  Result := nil;
  FillChar(FindData, SizeOf(TFindData), 0);
  with FindData do
  begin
    Code := ACode;
    FromIndex := AFromIndex;
    Item := @Result;
  end;
  ParseScript(NativeInt(Script), FindMethod, @FindData);
end;

function TParseHelper.FindMethod(var Index: NativeInt; const Header: PScriptHeader;
  const ItemHeader: PItemHeader; const Item: PScriptItem; const P: Pointer): Boolean;
var
  Data: PFindData;
begin
  Data := P;
  Result := Data.Index < Data.FromIndex;
  if Result then
    Inc(Data.Index)
  else
    Result := Data.Code <> Item.Code;
  if Result then
    case Item.Code of
      NumberCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
      FunctionCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction));
      StringCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
      ScriptCode, ParameterCode:
        begin
          ParseScript(Index + SizeOf(TCode), FindMethod, Data);
          Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
        end;
    else
      raise Error(ScriptError);
    end
  else
    Data.Item^ := Item;
end;

procedure TParseHelper.GetFunctionArray(const Script: TScript;
  out FArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF});
begin
  ParseScript(NativeInt(Script), FAMethod, @FArray);
end;

procedure TParseHelper.GetNumberArray(const Script: TScript; out NArray: TValueArray);
begin
  ParseScript(NativeInt(Script), NAMethod, @NArray);
end;

function TParseHelper.NAMethod(var Index: NativeInt; const Header: PScriptHeader;
  const ItemHeader: PItemHeader; const Item: PScriptItem; const P: Pointer): Boolean;
var
  NArray: ^TValueArray;
begin
  NArray := P;
  case Item.Code of
    NumberCode:
      begin
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
        ValueTypes.AddValue(NArray^, Item.ScriptNumber.Value);
      end;
    FunctionCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction));
    StringCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
    ScriptCode, ParameterCode:
      begin
        ParseScript(Index + SizeOf(TCode), NAMethod, P);
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
  else
    raise Error(ScriptError);
  end;
  Result := True;
end;

function TParseHelper.Optimizable(const Script: TScript; const Data: PFunctionData): Boolean;
var
  FArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};
  I: Integer;
begin
  GetFunctionArray(Script, FArray);
  try
    for I := Low(FArray) to High(FArray) do
      if not Data.FA[FArray[I]].Optimizable then
      begin
        Result := False;
        Exit;
      end;
    Result := True;
  finally
    FArray := nil;
  end;
end;

function MakeArray(const HandleArray: array of NativeInt): TNativeIntDynArray;
var
  I: NativeInt;
begin
  I := Length(HandleArray);
  SetLength(Result, I);
  CopyMemory(Result, @HandleArray, I * SizeOf(NativeInt));
end;

function ParseScript(Index: NativeInt; const Method: TScriptMethod; const P: Pointer): Boolean;
var
  I, J, K: NativeInt;
  Header: ^PScriptHeader;
  ItemHeader: ^PItemHeader;
  Item: ^Pointer;
begin
  if Assigned(Method) then
  begin
    Header := @I;
    ItemHeader := @J;
    Item := @K;
    I := Index;
    Inc(Index, Header^.HeaderSize);
    while Index - I < Header^.ScriptSize do
    begin
      J := Index;
      Inc(Index, SizeOf(TItemHeader));
      while Index - J < ItemHeader^.Size do
      begin
        K := Index;
        if not Method(Index, Header^, ItemHeader^, Item^, P) then
        begin
          Result := False;
          Exit;
        end;
      end;
    end;
  end;
  Result := True;
end;

procedure BuildScript(const Parser: TCustomParser; const ItemArray: TScriptArray; out Script: TScript;
  const Optimize: Boolean; Number: PNumber);
var
  ANumber: TNumber;
  Data: TArrayData;
  I, J, K: Integer;
  AItemArray: TScriptArray;
  ItemHeader: PItemHeader;
  Item: PScriptItem;
  {$IFDEF FPC}
  FlagArray: TArray<NativeInt>;
  {$ELSE}
  FlagArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};
  {$ENDIF}
  Header: ^PScriptHeader;
begin
  if not Assigned(Number) then
  begin
    FillChar(ANumber, SizeOf(TNumber), 0);
    Number := @ANumber;
  end;
  AItemArray := nil;
  try
    if Optimize then
    begin
      Reset(AItemArray, Data);
      try
        for I := Low(ItemArray) to High(ItemArray) do
          if Assigned(ItemArray[I]) then
            if Optimal(ItemArray[I], stScriptItem) then
              IncNumber(Number^, Parser, ItemArray[I], stScriptItem)
            else
              AddScript(AItemArray, Data, ItemArray[I]);
        if Number.Valid then
        begin
          Script := GetScriptFromValue(Parser, Number^, stScriptItem);
          try
            AddScript(AItemArray, Data, Script);
          finally
            Script := nil;
          end;
        end;
      finally
        Apply(AItemArray, Data);
      end;
    end
    else
      AItemArray := ItemArray;
    Script := nil;
    K := 0;
    try
      for I := Low(AItemArray) to High(AItemArray) do
        if Assigned(AItemArray[I]) then
        begin
          ItemHeader := Pointer(AItemArray[I]);
          J := SizeOf(TItemHeader);
          while J < ItemHeader.Size do
          begin
            Item := @AItemArray[I, J];
            case Item.Code of
              NumberCode: Inc(J, SizeOf(TCode) + SizeOf(TScriptNumber));
              FunctionCode: Inc(J, SizeOf(TCode) + SizeOf(TScriptFunction));
              StringCode: Inc(J, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
              ScriptCode:
                begin
                  MemoryUtils.Add(FlagArray, K + J + SizeOf(TCode));
                  Inc(J, SizeOf(TCode) + Item.Script.Header.ScriptSize);
                end;
              ParameterCode: Inc(J, SizeOf(TCode) + Item.Script.Header.ScriptSize);
            else
              raise Error(ScriptError);
            end;
          end;
          Inc(K, ItemHeader.Size);
        end;
      I := Length(FlagArray);
      K := SizeOf(TScriptHeader) + I * SizeOf(NativeInt);
      Resize(Script, K);
      Header := @Script;
      Header^.ScriptCount := I;
      J := SizeOf(TScriptHeader);
      for I := Low(FlagArray) to High(FlagArray) do
      begin
        PNativeInt(@Script[J])^ := K + FlagArray[I];
        Inc(J, SizeOf(NativeInt));
      end;
      for I := Low(AItemArray) to High(AItemArray) do
        AddScript(Script, AItemArray[I]);
      Header^.ScriptSize := Length(Script);
      Header^.HeaderSize := K;
    finally
      FlagArray := nil;
    end;
  finally
    Delete(AItemArray);
  end;
end;

function CheckFHandle(const FData: PFunctionData; const Handle: NativeInt): Boolean;
begin
  Result := (Handle >= Low(FData.FA)) and (Handle <= High(FData.FA));
end;

function CheckTHandle(const TData: PTypeData; const Handle: NativeInt): Boolean;
begin
  Result := (Handle >= Low(TData.TA)) and (Handle <= High(TData.TA));
end;

{$WARNINGS OFF}
function RestoreText(const Parser: TCustomParser; const Source: string; out Target: string;
  const SA: TScriptArray; const Parameter: Boolean = False): NativeInt;
var
  B: TTextBuilder;
  StringArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  I, J: Integer;
  Script: TScript;
  S: string;
begin
  B := TTextBuilder.Create;
  try
    Split(Source, BracketArray[bkBrace, btL], StringArray, True);
    try
      Result := 0;
      for I := Low(StringArray) to High(StringArray) do
        if Contains(StringArray[I], BracketArray[bkBrace, btR]) then
        begin
          J := GetISIndex(StringArray[I], nil);
          if B.Size = 0 then
            B.Append(Parser.ScriptToString(SA[J], rmUser) + StringArray[I])
          else begin
            if Parameter then
            begin
              Script := ParameterToScript(SA[J], Parser.DefaultTypeHandle);
              try
                S := Parser.ScriptToString(Script, rmUser);
              finally
                Script := nil;
              end;
            end
            else
              S := Parser.ScriptToString(SA[J], rmUser);
            B.Append(Embrace(S + StringArray[I], Parser.Bracket));
          end;
          Inc(Result);
        end
        else
          B.Append(StringArray[I]);
    finally
      StringArray := nil;
    end;
    Target := B.Text;
  finally
    B.Free;
  end;
end;
{$WARNINGS ON}

function RestoreText(const Parser: TCustomParser; const Text: string; const SA: TScriptArray;
  const Parameter: Boolean = False): string;
begin
  RestoreText(Parser, Text, Result, SA, Parameter);
end;

function RestoreText(const Parser: TCustomParser; const TextArray: TTextItemArray1; const SA: TScriptArray;
  const Parameter: Boolean): string;
var
  B: TTextBuilder;
  I: Integer;
  S: string;
begin
  B := TTextBuilder.Create;
  try
    for I := Low(TextArray) to High(TextArray) do
    begin
      if TextArray[I].THandle >= 0 then
        B.Append(Parser.TData.TA[TextArray[I].THandle].Name, Space);
      if RestoreText(Parser, TextArray[I].Text, S, SA, Parameter) > 0 then
        S := Embrace(S, Parser.Bracket);
      B.Append(S, Space);
    end;
    Result := B.Text;
  finally
    B.Free;
  end;
end;

procedure Read(const Parser: TCustomParser; var Index: NativeInt; out AFunction: PFunction);
var
  Item: ^PScriptItem;
begin
  Item := @Index;
  if (Item^.Code = FunctionCode) and Parser.GetFunction(Item^.ScriptFunction.Handle, AFunction) then
    Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction))
  else
    raise Error(ScriptError);
end;

function ParameterToScript(const Script: TScript; const THandle: NativeInt): TScript;
begin
  Resize(Result, SizeOf(TScriptHeader) + SizeOf(TItemHeader));
  WriteScript(Result, Script, True);
  with PItemHeader(@Result[SizeOf(TScriptHeader)])^ do
  begin
    Size := Length(Result) - SizeOf(TScriptHeader);
    UserType.Handle := THandle;
  end;
  PScriptHeader(Result).ScriptSize := Length(Script);
end;

{$WARNINGS OFF}
function GetScriptFromValue(const Parser: TCustomParser; Value: TValue; const TypeFlag: Boolean;
  const ScriptType: TScriptType): TScript;
var
  ItemHeader: ^PItemHeader;
  Script: TScript;
  ScriptHeader: ^PScriptHeader;
begin
  Result := nil;
  case ScriptType of
    stScriptItem:
      begin
        ItemHeader := @Result;
        Resize(Result, SizeOf(TItemHeader));
        ItemHeader^.Size := SizeOf(TItemHeader) + SizeOf(TCode) + SizeOf(TScriptNumber);
        ItemHeader^.Sign := Ord(LessZero(Value));
        Value := Positive(Value);
        ItemHeader^.UserType.Active := TypeFlag;
        ItemHeader^.UserType.Handle := MakeTypeHandle(Parser.TData^, Value.ValueType, Parser.DefaultTypeHandle);
        WriteNumber(Result, Value);
      end;
    stScript:
      begin
        ScriptHeader := @Result;
        Resize(Result, SizeOf(TScriptHeader));
        Script := GetScriptFromValue(Parser, Value, TypeFlag, stScriptItem);
        try
          AddMemory(Result, Script, Length(Script));
        finally
          Script := nil;
        end;
        ScriptHeader^.ScriptSize := Length(Result);
        ScriptHeader^.HeaderSize := SizeOf(TScriptHeader);
      end;
  end;
end;
{$WARNINGS ON}

function GetScriptFromValue(const Parser: TCustomParser; const Number: TNumber;
  const ScriptType: TScriptType): TScript;
begin
  Result := GetScriptFromValue(Parser, Number.Value, False, ScriptType);
end;

function GetValueFromScript(const Parser: TCustomParser; const Script: TScript; const ScriptType: TScriptType;
  const UserType: PUserType): TValue;
var
  ItemHeader: PItemHeader;
begin
  ItemHeader := PItemHeader(Script);
  case ScriptType of
    stScriptItem:
      begin
        Result := PScriptItem(@Script[SizeOf(TItemHeader)]).ScriptNumber.Value;
        if Assigned(UserType) then UserType^ := ItemHeader.UserType;
        if Boolean(ItemHeader.Sign) then Result := Negative(Result);
      end;
    stScript:
      Result := GetValueFromScript(Parser, {$IFDEF DELPHI_10.2}TArray<Byte>{$ELSE}TByteDynArray{$ENDIF}(@Script[SizeOf(TScriptHeader)]),
        stScriptItem, UserType);
  end;
end;

function GetParameter(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): TParameter;
var
  Item: ^PScriptItem;
  I, J: NativeInt;
  ItemHeader: PItemHeader;
begin
  Item := @I;
  with Parameter.Value do
  begin
    I := NativeIntRec.Lo;
    ItemHeader := PItemHeader(NativeIntRec.Hi);
  end;
  Result.THandle := ItemHeader.UserType.Handle;
  case Item^.Code of
    NumberCode: Result.Value := Item^.ScriptNumber.Value;
    FunctionCode: Result.Value := Parser.ExecuteFunction(I, Header, ItemHeader, EmptyValue);
    StringCode:
      begin
        J := Item^.ScriptString.Size;
        if J > SizeOf(TString) - SizeOf(Char) then
          J := SizeOf(TString) - SizeOf(Char);
        ZeroMemory(@Result.Text, SizeOf(TString));
        CopyMemory(@Result.Text, PAnsiChar(I) + SizeOf(TCode) + SizeOf(TScriptString), J);
      end;
    ScriptCode: Result.Value := Parser.ExecuteScript(NativeInt(@Item^.Script.Header))^;
  else
    raise ParseErrors.Error(ScriptError);
  end;
  if (Item^.Code <> StringCode) and Boolean(ItemHeader.Sign) then
    Result.Value := Negative(Result.Value);
end;

function AsValue(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): TValue;
begin
  Result := GetParameter(Parser, Header, Parameter).Value;
end;

function AsByte(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Byte;
begin
  Result := GetByte(AsValue(Parser, Header, Parameter));
end;

function AsShortint(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Shortint;
begin
  Result := GetShortint(AsValue(Parser, Header, Parameter));
end;

function AsBoolean(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Boolean;
begin
  Result := GetBoolean(AsValue(Parser, Header, Parameter));
end;

function AsWord(const Parser: TCustomParser; const Header: PScriptHeader; const Parameter: TParameter): Word;
begin
  Result := GetWord(AsValue(Parser, Header, Parameter));
end;

function AsSmallint(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Smallint;
begin
  Result := GetSmallint(AsValue(Parser, Header, Parameter));
end;

function AsWordBool(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): WordBool;
begin
  Result := GetWordBool(AsValue(Parser, Header, Parameter));
end;

function AsLongWord(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): LongWord;
begin
  Result := GetLongWord(AsValue(Parser, Header, Parameter));
end;

function AsNativeInt(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): NativeInt;
begin
  Result := GetNativeInt(AsValue(Parser, Header, Parameter));
end;

function AsLongBool(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): LongBool;
begin
  Result := GetLongBool(AsValue(Parser, Header, Parameter));
end;

function AsInt64(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Int64;
begin
  Result := GetInt64(AsValue(Parser, Header, Parameter));
end;

function AsSingle(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Single;
begin
  Result := GetSingle(AsValue(Parser, Header, Parameter));
end;

function AsDouble(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Double;
begin
  Result := GetDouble(AsValue(Parser, Header, Parameter));
end;

function AsExtended(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): Extended;
begin
  Result := GetExtended(AsValue(Parser, Header, Parameter));
end;

function AsText(const Parser: TCustomParser; const Header: PScriptHeader;
  const Parameter: TParameter): string;
begin
  Result := GetParameter(Parser, Header, Parameter).Text;
end;

function AsBoolean(const Parser: TCustomParser; const Header: PScriptHeader; const PA: TParameterArray;
  const Index: NativeInt; const Default: Boolean): Boolean;
begin
  if Default then
    Result := (High(PA) < Index) or AsBoolean(Parser, Header, PA[Index])
  else
    Result := (High(PA) >= Index) and AsBoolean(Parser, Header, PA[Index]);
end;

function Optimal(const Script: TScript; const ScriptType: TScriptType): Boolean;
const
  ScriptSize: array[TScriptType] of NativeInt = (
    SizeOf(TItemHeader) + SizeOf(TCode) + SizeOf(TScriptNumber),
    SizeOf(TScriptHeader) + SizeOf(TItemHeader) + SizeOf(TCode) + SizeOf(TScriptNumber));
  CodeOffset: array[TScriptType] of NativeInt = (
    SizeOf(TItemHeader),
    SizeOf(TScriptHeader) + SizeOf(TItemHeader));
begin
  Result := Assigned(Script);
  if Result then
    case ScriptType of
      stScriptItem:
        Result := (PItemHeader(Script).Size = ScriptSize[ScriptType]) and
          (PNativeInt(@Script[CodeOffset[ScriptType]])^ = NumberCode);
      stScript:
        Result := (PScriptHeader(Script).ScriptSize = ScriptSize[ScriptType]) and
          (PNativeInt(@Script[CodeOffset[ScriptType]])^ = NumberCode);
    end;
end;

function TypeFlag(const Script: TScript; const ScriptType: TScriptType): Boolean;
begin
  Result := Optimal(Script, ScriptType);
  if Result then
    case ScriptType of
      stScriptItem: Result := PItemHeader(Script).UserType.Active;
      stScript: Result := PItemHeader(@Script[SizeOf(TScriptHeader)]).UserType.Active;
    end;
end;

function GetFunction(const Data: PFunctionData; Index: NativeInt; out AFunction: PFunction): Boolean;
begin
  Result := (Index >= Low(Data.FOrder)) and (Index <= High(Data.FOrder)) and
    (Data.FOrder[Index] >= Low(Data.FA)) and (Data.FOrder[Index] <= High(Data.FA));
  if Result then
    AFunction := @Data.FA[Data.FOrder[Index]]
  else
    AFunction := nil;
end;

function FunctionByIndex(const Data: PFunctionData; const Index: NativeInt): PFunction;
begin
  GetFunction(Data, Index, Result);
end;

function GetFFArray(const Text: string; const LockType: TLockType; const FData: PFunctionData;
  const TData: PTypeData; out FFArray: TFunctionFlagArray; const CleanText: PString;
  const TypeArray: PHandleArray; const Method: TFunctionFlagMethod): Boolean;
type
  TItem = record
    Index: NativeInt;
    THandle: PNativeInt;
  end;

  function MakeTemplate: string;
  const
    Template = '(0x%x)(0x%x)(0x%x)(%s)';
  begin
    Result := Format(Template, [NativeInt(FData), NativeInt(TData), NativeInt(@Method), Text]);
  end;

  procedure Resize(var Target: THandleArray; const Size: NativeInt);
  var
    ASize, I: Integer;
  begin
    ASize := Length(Target);
    SetLength(Target, Size);
    for I := ASize to Size - 1 do Target[I] := -1;
  end;

  function MakeItem(const AIndex: NativeInt; const AHandle: PNativeInt): TItem;
  begin
    FillChar(Result, SizeOf(TItem), 0);
    with Result do
    begin
      Index := AIndex;
      THandle := AHandle;
    end;
  end;

  function Add(const AText: string; const BText: TTextBuilder; const Index: NativeInt; var Prior: TItem;
    const AType: PType; var ATypeArray: THandleArray): Boolean; overload;
  var
    I: NativeInt;
  begin
    Result := Assigned(AType);
    if Result then
    begin
      if Assigned(Prior.THandle) then
        I := Prior.Index + NativeInt(StrLen(TData.TA[Prior.THandle^].Name))
      else
        I := 1;
      BText.Append(Trim(Copy(AText, I, Index - I)), Space);
      if BText.Size > 0 then
        I := BText.Size + 1
      else
        I := 0;
      Resize(ATypeArray, I + 1);
      ATypeArray[I] := AType.Handle^;
    end;
  end;

  function Add(var Data: TArrayData; const Index, FHandle: NativeInt): Boolean; overload;
  begin
    Result := not Assigned(Method) or not CheckFHandle(FData, FHandle) or Method(@FData.FA[FHandle]);
    if Result then AddFlag(FFArray, Data, Index, FHandle);
  end;

var
  AText: string;
  FlagArray: TFlagArray;
  BText: TTextBuilder;
  ATypeArray: THandleArray;
  Prior: TItem;
  I, J, K, Count: NativeInt;
  Data: TArrayData;
  AType: PType;
  AFunction: PFunction;
begin
  if not Assigned(FData.FlagCache) or not TFlagCache(FData.FlagCache).Find(MakeTemplate, FFArray, CleanText, TypeArray) then
  begin
    Prepare(FData);
    AText := Text;
    FlagArray := GetFlagArray(AText, LockType);
    try
      ATypeArray := nil;
      if Assigned(TData) then
      begin
        BText := TTextBuilder.Create;
        try
          FillChar(Prior, SizeOf(TItem), 0);
          I := 1;
          Count := Length(AText);
          while I <= Count do if Locked(I, FlagArray) or CharInSet(AText[I], Blanks) then Inc(I)
          else begin
            J := Low(TData.TOrder);
            K := 1;
            while GetType(TData, J, AType) do
            begin
              K := StrLen(AType.Name);
              if (K = 0) or (I + K - 1 > Count) or not Whole(AText, I, K) or not SameText(AType.Name, @AText[I], K) then
              begin
                Inc(J);
                K := 1;
              end
              else begin
                Add(AText, BText, I, Prior, AType, ATypeArray);
                Prior := MakeItem(I, AType.Handle);
                Break;
              end;
            end;
            Inc(I, K);
          end;
          if Assigned(Prior.THandle) then
            I := Prior.Index + NativeInt(StrLen(TData.TA[Prior.THandle^].Name))
          else
            I := 1;
          BText.Append(Trim(Copy(AText, I, MaxInt)), Space);
          AText := BText.Text;
        finally
          BText.Free;
        end;
      end;
      if Assigned(CleanText) then CleanText^ := AText;
      if Assigned(TypeArray) then TypeArray^ := ATypeArray;
      FFArray := nil;
      Reset(FFArray, Data);
      try
        I := 1;
        Count := Length(AText);
        while I <= Count do if Locked(I, FlagArray) or CharInSet(AText[I], Blanks) then Inc(I)
        else begin
          J := Low(FData.FOrder);
          K := 1;
          while GetFunction(FData, J, AFunction) do
          begin
            K := StrLen(AFunction.Name);
            if (K = 0) or (I + K - 1 > Count) or not SameText(AFunction.Name, @AText[I], K) then
            begin
              Inc(J);
              K := 1;
            end
            else begin
              if Assigned(AFunction.Handle) then
                Add(Data, I, AFunction.Handle^)
              else
                Add(Data, I, -1);
              Break;
            end;
          end;
          Inc(I, K);
        end;
      finally
        Apply(FFArray, Data);
      end;
    finally
      FlagArray := nil;
    end;
    if Assigned(FData.FlagCache) then
      TFlagCache(FData.FlagCache).Add(MakeTemplate, FFArray, CleanText, TypeArray);
  end;
  Result := Assigned(FFArray);
end;

function GetTIArray(const Text: string; const FData: PFunctionData; const TData: PTypeData;
  out TIArray: TTextItemArray1; const InternalHandle: NativeInt; const LockType: TLockType): Boolean;
var
  TypeArray: THandleArray;

  function GetHandle(const Index: NativeInt): NativeInt;
  begin
    if (Index < Low(TypeArray)) or (Index > High(TypeArray)) then
      Result := -1
    else
      Result := TypeArray[Index];
  end;

var
  Data: TArrayData;
  FlagArray: TFunctionFlagArray;
  AText, S: string;
  I, J, K, FHandle: Integer;
begin
  TIArray := nil;
  if not Assigned(FData.ItemCache) or not TItemCache(FData.ItemCache).Find(Text, TIArray) then
  begin
    if GetFFArray(Text, LockType, FData, TData, FlagArray, @AText, @TypeArray) then
      try
        Reset(TIArray, Data);
        try
          for I := Low(FlagArray) to Length(FlagArray) do
          begin
            if I > Low(FlagArray) then
            begin
              J := FlagArray[I - 1].Index;
              if I < Length(FlagArray) then
                K := FlagArray[I].Index - J
              else
                K := MaxInt;
              FHandle := FlagArray[I - 1].Handle;
            end
            else begin
              J := 1;
              K := FlagArray[I].Index - 1;
              FHandle := -1;
            end;
            S := Copy(AText, J, K);
            if Trim(S) <> '' then
              if (FHandle < 0) or (InternalHandle < 0) or (FHandle = InternalHandle) then
                AddItem(TIArray, Data, Trim(S), FHandle, GetHandle(J - 1))
              else begin
                AddItem(TIArray, Data, FData.FA[FHandle].Name, FHandle, GetHandle(J - 1));
                J := StrLen(FData.FA[FHandle].Name) + 1;
                K := Length(S);
                while (J <= K) and (S[J] = Space) do Inc(J);
                S := Trim(Copy(S, J, MaxInt));
                if S <> '' then
                begin
                  if I > Low(FlagArray) then Inc(J, FlagArray[I - 1].Index - 1);
                  AddItem(TIArray, Data, S, -1, GetHandle(J - 1));
                end;
              end;
          end;
        finally
          Apply(TIArray, Data);
        end;
      finally
        FlagArray := nil;
        TypeArray := nil;
      end;
    if not Assigned(TIArray) then
    begin
      S := Trim(AText);
      if S <> '' then AddItem(TIArray, S, -1, GetHandle(0));
    end;
    if Assigned(FData.ItemCache) then
      TItemCache(FData.ItemCache).Add(Text, TIArray);
  end;
  Result := Assigned(TIArray);
end;

function TrimPOperator(var Text: string): Boolean;
var
  I: Integer;
begin
  repeat
    for I := Ord(Low(POperatorArray)) to Ord(High(POperatorArray)) do
    begin
      Result := DeletePrefix(Text, POperatorArray[TParameterOperator(I)]);
      if Result then Break;
    end;
  until not Result;
end;

function FindSign(const Text: string; var Index: NativeInt; out Sign: Boolean): Boolean;
var
  J: TTextOperator;
begin
  Result := (Index > 0) and (Index <= Length(Text));
  if Result then
  begin
    while (Index <= Length(Text)) and CharInSet(Text[Index], Blanks) do
      Inc(Index);
    for J := Low(TOperatorArray) to High(TOperatorArray) do
      if Text[Index] = TOperatorArray[J] then
      begin
        Sign := J = toNegative;
        Exit;
      end;
    Result := False;
  end;
end;

function GetSign(const Text: string; const Index: PNativeInt): Boolean; overload;
var
  I: NativeInt;
  Sign, Flag: Boolean;
begin
  Result := False;
  if Assigned(Index) then
    I := Index^
  else
    I := 1;
  repeat
    Flag := FindSign(Text, I, Sign);
    if Flag then
    begin
      if Result then
        Result := Result xor Sign
      else
        Result := Sign;
      Inc(I);
    end;
  until not Flag;
  if Assigned(Index) then Index^ := I;
end;

function GetSign(const Item: TTextItem;
  const TOHArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}): Boolean;
begin
  Result := Item.FHandle = TOHArray[NativeInt(toNegative)];
end;

function SetSign(const Text: string): string;
var
  I: NativeInt;
begin
  I := 1;
  if GetSign(Text, @I) then
    Result := TOperatorArray[toNegative] + Copy(Text, I, MaxInt)
  else
    Result := Copy(Text, I, MaxInt);
end;

function TrimFunction(const Data: PFunctionData; var Text: string; const Trim: Boolean): PFunction;
var
  I: Integer;
  AFunction: PFunction;
begin
  Prepare(Data);
  for I := Low(Data.FOrder) to High(Data.FOrder) do
    if GetFunction(Data, I, AFunction) and DeletePrefix(Text, AFunction.Name, Trim) then
    begin
      Result := AFunction;
      Exit;
    end;
  Result := nil;
end;

function TrimType(const Data: PTypeData; const StringHandle: NativeInt; var Text: string;
  const Trim: Boolean): PType;
var
  I: Integer;
  AType: PType;
begin
  if Quoted(Text) then
    Result := @Data.TA[StringHandle]
  else begin
    for I := Low(Data.TOrder) to High(Data.TOrder) do
      if GetType(Data, I, AType) and Whole(Text, 1, StrLen(AType.Name)) and DeletePrefix(Text, AType.Name, Trim) then
      begin
        Result := AType;
        Exit;
      end;
    Result := nil;
  end;
end;

procedure WriteItemHeader(const ItemHeader: PItemHeader; const ASign: Boolean;
  const THandle, DefaultTypeHandle: NativeInt);
begin
  ItemHeader.Sign := Ord(ASign);
  if THandle < 0 then
    ItemHeader.UserType.Handle := DefaultTypeHandle
  else
    ItemHeader.UserType.Handle := THandle;
end;

function GetISIndex(const Text: string; out Parameter: Boolean): NativeInt;
var
  S: string;
  Code: Integer;
begin
  S := Extract(Text, BracketArray[bkBrace, btL], 1, True);
  Parameter := DeletePrefix(S, ParameterPrefix);
  Val(SubStr(S, BracketArray[bkBrace, btR], 0, False), Result, Code);
  if Code <> 0 then Result := -1;
end;

function GetISIndex(var Text: string; const Parameter: PBoolean): NativeInt;
var
  I: NativeInt;
begin
  if Assigned(Parameter) then
    Parameter^ := DeletePrefix(Text, ParameterPrefix)
  else
    DeletePrefix(Text, ParameterPrefix);
  I := Pos(BracketArray[bkBrace, btR], Text);
  if I > 0 then
  begin
    Result := StrToInt(Copy(Text, 1, I - 1));
    System.Delete(Text, 1, I);
  end
  else
    Result := StrToInt(Text);
end;

function GetIS(const Text: string; const SA: TScriptArray; out Parameter: Boolean): TScript;
var
  I: NativeInt;
begin
  I := GetISIndex(Text, Parameter);
  if (I < Low(SA)) or (I > High(SA)) then
    Result := nil
  else
    Result := SA[I];
end;

procedure ParseBracket(var Text: string; const Bracket: TBracket; const Method: TBracketMethod;
  const Data: Pointer; out Error: TError);
var
  I, J: Integer;
  FlagArray: TFlagArray;
  BD: TBD;

  procedure Reset;
  begin
    I := 1;
    FlagArray := GetFlagArray(Text, ltChar);
    FillChar(BD, SizeOf(TBD), 0);
    BD.Index1 := MaxInt;
  end;

begin
  FillChar(Error, SizeOf(TError), 0);
  if Assigned(Method) then
    if SubStrCnt(Text, Bracket[btL], True) <> SubStrCnt(Text, Bracket[btR], True) then
      Error := MakeError(etBracketError, BracketError)
    else
      try
        Reset;
        J := Length(Text);
        while I <= J do
        begin
          if not Locked(I, FlagArray) then
            if Text[I] = Bracket[btL] then
            begin
              if BD.Index1 > I then BD.Index1 := I;
              Inc(BD.Count1);
            end
            else if Text[I] = Bracket[btR] then
            begin
              BD.Index2 := I;
              Inc(BD.Count2);
            end;
          if (BD.Count1 > 0) and (BD.Count1 = BD.Count2) and (BD.Index1 < BD.Index2) then
          begin
            Error := Method(Text, BD.Index1, BD.Index2, Data);
            J := Length(Text);
            if Error.ErrorType = etOK then
              Reset
            else
              Break
          end
          else
            Inc(I);
        end;
      finally
        FlagArray := nil;
      end;
end;

procedure ParseBracket(var Text: string; const Bracket: TBracket; const Method: TBracketMethod;
  const Data: Pointer);
var
  Error: TError;
begin
  ParseBracket(Text, Bracket, Method, Data, Error);
  if Error.ErrorType <> etOK then raise ParseErrors.Error(Error.ErrorText);
end;

function Embrace(const Text: string; const Bracket: TBracket): string;
begin
  Result := Bracket[btL] + Text + Bracket[btR];
end;

function InBrace(const Text: string; const Bracket: TBracket): Boolean;
var
  I: Integer;
begin
  I := Length(Text);
  Result := (I >= Length(Bracket)) and (Text[1] = Bracket[btL]) and (Text[I] = Bracket[btR]);
end;

procedure DeleteBracket(var Text: string; const Index: NativeInt; const Bracket: TBracket);
var
  I, J: Integer;
begin
  for I := Index to Length(Text) do
  begin
    if Text[I] = Bracket[btL] then
    begin
      J := NextBracket(Text, Bracket, Index);
      if J > 0 then
      begin
        System.Delete(Text, I, 1);
        System.Delete(Text, J - 1, 1);
      end;
      Break;
    end
    else if not CharInSet(Text[I], Blanks) then
      Break;
  end;
end;

procedure ChangeBracket(var Text: string; const Index: NativeInt; const BracketFrom, BracketTo: TBracket);
var
  I, J: Integer;
begin
  for I := Index to Length(Text) do
  begin
    if Text[I] = BracketFrom[btL] then
    begin
      J := NextBracket(Text, BracketFrom, Index);
      if J > 0 then
      begin
        Text[I] := BracketTo[btL];
        Text[J] := BracketTo[btR];
      end;
      Break;
    end
    else if not CharInSet(Text[I], Blanks) then
      Break;
  end;
end;

function BracketFunction(const AFunction: PFunction): Boolean;
begin
  Result := AFunction.Method.Parameter.Count > 0;
end;

procedure ChangeBracket(var Text: string; const Data: PFunctionData; const BracketFrom, BracketTo: TBracket);
var
  FFArray: TFunctionFlagArray;
  I: Integer;
begin
  if GetFFArray(Text, ltChar, Data, nil, FFArray, nil, nil, BracketFunction) then
    try
      for I := Low(FFArray) to High(FFArray) do
        ChangeBracket(Text, FFArray[I].Index + NativeInt(StrLen(Data.FA[FFArray[I].Handle].Name)), BracketFrom, BracketTo);
    finally
      FFArray := nil;
    end;
end;

function Lower(const Text: string): string;
var
  B: TTextBuilder;
  I: Integer;
begin
  B := TTextBuilder.Create;
  try
    for I := 0 to SubStrCnt(Text, LockText, True) do
      if Odd(I) then
        B.Append(SubStr(Text, LockText, I, False))
      else
        B.Append(LowerCase(SubStr(Text, LockText, I, False)));
    Result := B.Text;
  finally
    B.Free;
  end;
end;

function Upper(const Text: string): string;
var
  B: TTextBuilder;
  I: Integer;
begin
  B := TTextBuilder.Create;
  try
    for I := 0 to SubStrCnt(Text, LockText, True) do
      if Odd(I) then
        B.Append(SubStr(Text, LockText, I, False))
      else
        B.Append(UpperCase(SubStr(Text, LockText, I, False)));
    Result := B.Text;
  finally
    B.Free;
  end;
end;

function Whole(const Text: string; const Index, Count: NativeInt): Boolean;
begin
  Result := (Index + Count - 1 <= Length(Text)) and ((Index = 1) or
    CharInSet(Text[Index - 1], DelimiterArray)) and ((Index + Count - 1 = Length(Text)) or
    CharInSet(Text[Index + Count], DelimiterArray));
end;

function FollowingText(const Text: string; const Index: NativeInt): string;
var
  I, J: Integer;
begin
  I := Index;
  J := Length(Text);
  while (I < J) and not CharInSet(Text[I + 1], DelimiterArray) do Inc(I);
  Result := Copy(Text, Index, I - Index + 1);
end;

function PrecedingText(const Text: string; const Index: NativeInt): string;
var
  I: Integer;
begin
  I := Index;
  while (I > 1) and not CharInSet(Text[I - 1], DelimiterArray) do Dec(I);
  Result := Copy(Text, I, Index - I);
end;

function WholeValue(const Parser: TCustomParser; const Text: string; const Index, Count: NativeInt): Boolean;

  function Check(const S: string): Boolean;
  begin
    Result := (S = '') or Assigned(Parser.FindFunction(S)) or Assigned(Parser.FindType(S));
  end;

var
  L, R: string;
  FFArray: TFunctionFlagArray;
  I, J: Integer;
  Flag: PFunctionFlag;
begin
  L := Trim(PrecedingText(Text, Index));
  R := Trim(FollowingText(Text, Index + Count));
  if not Whole(Text, Index, Count) and (not Check(L) or not Check(R)) then
  begin
    GetFFArray(Text, ltChar, Parser.FData, nil, FFArray);
    try
      J := Index + Count;
      for I := Low(FFArray) to High(FFArray) do
      begin
        Flag := @FFArray[I];
        if (Flag.Index <= Index) and
          (Flag.Index + NativeInt(StrLen(Parser.FData.FA[Flag.Handle].Name)) >= J) then
          begin
            Result := False;
            Exit;
          end;
      end;
    finally
      FFArray := nil;
    end;
  end;
  Result := True;
end;

function Dequote(const Text: string): string;
var
  I, J: Integer;
begin
  Result := Trim(Text);
  I := 1;
  J := Length(Result);
  while Result[I] = LockText do Inc(I);
  if I > J then
    Result := ''
  else begin
    while Result[J] = LockText do Dec(J);
    Result := Trim(Copy(Result, I, J - I + 1));
  end;
end;

function DequoteDouble(const Text, FunctionName: string; const Bracket: TBracket): string;
var
  I, J, AIndex, BIndex: Integer;
begin
  Result := Text;
  I := Pos(FunctionName, Result);
  if I > 0 then
  begin
    I := PosEx(Bracket[btL], Result, I + Length(FunctionName));
    if I > 0 then
    begin
      J := PosEx(LockText, Result, I);
      if (J > 0) and (J < Length(Result)) then
      begin
        AIndex := J;
        I := NextBracket(Result, Bracket, I);
        while (I > 0) and (Result[I] <> LockText) do Dec(I);
        BIndex := I;
        if (BIndex < Length(Result)) and (Result[BIndex] = LockText) and (AIndex < BIndex) and
          (Result[BIndex] = LockText) then
          begin
            System.Delete(Result, AIndex, 1);
            System.Delete(Result, BIndex - 1, 1);
          end;
      end;
    end;
  end;
end;

function Quoted(const Text: string): Boolean;
begin
  Result := (Length(Text) > 1) and (Text[1] = LockText) and (Text[Length(Text)] = LockText);
end;

function MakeTemplate(const Parser: TCustomParser; const Text: string; const ValueArray: PValueArray;
  const NumberTemplate: string): string;
var
  B: TTextBuilder;
  FlagArray: TFlagArray;
  I, J, K, L, Count: NativeInt;
  Sign, Flag: Boolean;
  Value: TValue;
begin
  B := TTextBuilder.Create(Length(Text));
  try
    FlagArray := GetFlagArray(Text, ltChar);
    try
      I := 1;
      Count := Length(Text);
      while I <= Count do
        repeat
          if Locked(I, FlagArray) then
          begin
            B.Append(Text[I]);
            Inc(I);
            Continue;
          end;
          if CharInSet(Text[I], Operators + Digits) then
          begin
            K := I;
            Flag := CharInSet(Text[I], Operators);
            if Flag then
              Sign := GetSign(Text, @I)
            else
              Sign := False;
            while (I <= Count) and CharInSet(Text[I], Blanks) do Inc(I);
            J := I;
            L := 0;
            while (J <= Count) and CharInSet(Text[J], Digits) do
            begin
              Inc(J);
              if (J < Count) and (Text[J] = ParseFormat.DecimalSeparator) and CharInSet(Text[J + 1], Digits) then
                if L = 0 then
                begin
                  Inc(J);
                  Inc(L);
                end
                else
                  Break;
            end;
            Dec(J, I);
            repeat
              if (J > 0) and WholeValue(Parser, Text, I, J) and TryTextToValue(Copy(Text, I, J), Value) then
              begin
                if Flag then
                  B.Append(TOperatorArray[toPositive] + NumberTemplate)
                else
                  B.Append(NumberTemplate);
                if Assigned(ValueArray) then
                  if Sign then
                    ValueTypes.AddValue(ValueArray^, ValueUtils.Negative(Value))
                  else
                    ValueTypes.AddValue(ValueArray^, Value);
                Break;
              end;
              while K <= I + J do
              begin
                if not CharInSet(Text[K], Blanks) then B.Append(Text[K]);
                Inc(K);
              end;
            until True;
            Inc(I, J);
            Continue;
          end;
          if not CharInSet(Text[I], Blanks) then B.Append(Text[I]);
          Inc(I);
        until True;
      Result := B.Text;
      if Result = '' then Result := NumberChar[ntZero];
    finally
      FlagArray := nil;
    end;
  finally
    B.Free;
  end;
end;

function WriteValue(Index: NativeInt; var ValueIndex: NativeInt; const ValueArray: TValueArray;
  const ScriptType: TScriptType): Boolean;
var
  Header: ^PScriptHeader;
  ItemHeader: ^PItemHeader;
  Item: ^PScriptItem;
  I, J: NativeInt;
begin
  Header := @I;
  ItemHeader := @J;
  Item := @Index;
  Result := Assigned(ValueArray) and (ValueIndex < Length(ValueArray));
  if Result then
    case ScriptType of
      stScriptItem:
        begin
          J := Index;
          Inc(Index, SizeOf(TItemHeader));
          while Index - J < ItemHeader^.Size do
            case Item^.Code of
              NumberCode:
                begin
                  if not Boolean(ItemHeader^.Sign) then
                    ItemHeader^.Sign := NativeInt(LessZero(ValueArray[ValueIndex]));
                  Item^.ScriptNumber.Value := Positive(ValueArray[ValueIndex]);
                  Inc(ValueIndex);
                  if ValueIndex > High(ValueArray) then Exit;
                  Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
                end;
              FunctionCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction));
              StringCode:
                Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item^.ScriptString.Size);
              ScriptCode, ParameterCode:
                begin
                  WriteValue(Index + SizeOf(TCode), ValueIndex, ValueArray, ScriptType);
                  if ValueIndex > High(ValueArray) then Exit;
                  Inc(Index, SizeOf(TCode) + Item^.Script.Header.ScriptSize);
                end;
            else
              raise Error(ScriptError);
            end;
        end;
      stScript:
        begin
          I := Index;
          Inc(Index, Header^.HeaderSize);
          while Index - I < Header^.ScriptSize do
          begin
            J := Index;
            Inc(Index, SizeOf(TItemHeader));
            while Index - J < ItemHeader^.Size do
              case Item^.Code of
                NumberCode:
                  begin
                    if not Boolean(ItemHeader^.Sign) then
                      ItemHeader^.Sign := NativeInt(LessZero(ValueArray[ValueIndex]));
                    Item^.ScriptNumber.Value := Positive(ValueArray[ValueIndex]);
                    Inc(ValueIndex);
                    if ValueIndex > High(ValueArray) then Exit;
                    Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
                  end;
                FunctionCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction));
                StringCode:
                  Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item^.ScriptString.Size);
                ScriptCode, ParameterCode:
                  begin
                    WriteValue(Index + SizeOf(TCode), ValueIndex, ValueArray, ScriptType);
                    if ValueIndex > High(ValueArray) then Exit;
                    Inc(Index, SizeOf(TCode) + Item^.Script.Header.ScriptSize);
                  end;
              else
                raise Error(ScriptError);
              end;
          end;
        end;
    end;
end;

function AddSmallint(var Target: TScript; const Value: Smallint): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(Smallint));
  PSmallint(@Target[Result])^ := Value;
end;

function AddWord(var Target: TScript; const Value: Word): Integer;
begin
  Result := AddSmallint(Target, Value);
end;

function AddNativeInt(var Target: TScript; const Value: NativeInt): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(NativeInt));
  PNativeInt(@Target[Result])^ := Value;
end;

function AddLongWord(var Target: TScript; const Value: LongWord): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(LongWord));
  PLongWord(@Target[Result])^ := Value;
end;

function AddInt64(var Target: TScript; const Value: Int64): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(Int64));
  PInt64(@Target[Result])^ := Value;
end;

function AddSingle(var Target: TScript; const Value: Single): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(Double));
  PDouble(@Target[Result])^ := Value;
end;

function AddDouble(var Target: TScript; const Value: Double): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(Double));
  PDouble(@Target[Result])^ := Value;
end;

function AddExtended(var Target: TScript; const Value: Extended): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(Double));
  PDouble(@Target[Result])^ := Value;
end;

function AddValue(var Target: TScript; const Value: TValue): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(TValue));
  PValue(@Target[Result])^ := Value;
end;

function AddScriptNumber(var Target: TScript; const Value: TScriptNumber): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(TScriptNumber));
  PScriptNumber(@Target[Result])^ := Value;
end;

function AddScriptFunction(var Target: TScript; const Value: TScriptFunction): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + SizeOf(TScriptFunction));
  PScriptFunction(@Target[Result])^ := Value;
end;

function AddScript(var Target: TScript; const Source: TScript): Integer;
begin
  Result := AddMemory(Target, Source, Length(Source));
end;

function AddMemory(var Target: TScript; const Source: Pointer; const Count: NativeInt): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + Count);
  CopyMemory(@Target[Result], Source, Count);
end;

function AddString(var Target: TScript; const Value: string): Integer;
begin
  Result := AddMemory(Target, Pointer(Value), Length(Value) * SizeOf(Char));
end;

procedure Reset(var Target: TScriptArray; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Apply(var Target: TScriptArray; const Data: TArrayData);
begin
  SetLength(Target, Data.Index);
end;

function AddScript(var Target: TScriptArray; var Data: TArrayData; const Value: TScript): Integer;
begin
  Data.Count := Length(Target);
  if Data.Index >= Data.Count then
  begin
    Data.Count := Data.Count + ArrayIncrement;
    SetLength(Target, Data.Count);
  end;
  if Assigned(Value) then AddMemory(Target[Data.Index], Value, Length(Value));
  Result := Data.Index;
  Inc(Data.Index);
end;

function AddScript(var Target: TScriptArray; const Value: TScript): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  if Assigned(Value) then AddMemory(Target[Result], Value, Length(Value));
end;

function AddFunction(var Target: TFunctionData; const Value: TFunction): Integer;
var
  I: Integer;
  AFunction: PFunction;
begin
  for I := Low(Target.FA) to High(Target.FA) do
  begin
    AFunction := @Target.FA[I];
    if StrLen(AFunction.Name) = 0 then
    begin
      Result := I;
      AFunction^ := Value;
      Exit;
    end;
  end;
  Result := Length(Target.FA);
  SetLength(Target.FA, Result + 1);
  MemoryUtils.Add(Target.FA, @Value, Result * SizeOf(TFunction), SizeOf(TFunction));
  if Assigned(Target.ItemCache) then TItemCache(Target.ItemCache).Clear;
  if Assigned(Target.FlagCache) then TFlagCache(Target.FlagCache).Clear;
  Target.Prepared := False;
end;

function AddType(var Target: TTypeData; const Value: TType): Integer;
var
  I: Integer;
  AType: PType;
begin
  for I := Low(Target.TA) to High(Target.TA) do
  begin
    AType := @Target.TA[I];
    if StrLen(AType.Name) = 0 then
    begin
      Result := I;
      AType^ := Value;
      Exit;
    end;
  end;
  Result := Length(Target.TA);
  SetLength(Target.TA, Result + 1);
  MemoryUtils.Add(Target.TA, @Value, Result * SizeOf(TType), SizeOf(TType));
  Target.Prepared := False;
end;

procedure Reset(var Target: TParameterArray; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Apply(var Target: TParameterArray; const Data: TArrayData);
begin
  SetLength(Target, Data.Index);
end;

function AddParameter(var Target: TParameterArray; var Data: TArrayData; const Value: TParameter): Integer;
const
  Increment = 2;
begin
  Data.Count := Length(Target);
  if Data.Index >= Data.Count then
  begin
    Data.Count := Data.Count + Increment;
    SetLength(Target, Data.Count);
  end;
  Target[Data.Index] := Value;
  Result := Data.Index;
  Inc(Data.Index);
end;

function AddParameter(var Target: TParameterArray; var Data: TArrayData; const THandle: NativeInt;
  const Value: TValue): Integer;
begin
  Result := AddParameter(Target, Data, MakeParameter(THandle, Value));
end;

function AddParameter(var Target: TParameterArray; var Data: TArrayData; const THandle: NativeInt;
  const Text: string): Integer;
begin
  Result := AddParameter(Target, Data, MakeParameter(THandle, Text));
end;

function AddParameter(var Target: TParameterArray; const THandle: NativeInt; const Value: TValue): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  Target[Result] := MakeParameter(THandle, Value);
end;

function AddParameter(var Target: TParameterArray; const THandle: NativeInt; const Text: string): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  Target[Result] := MakeParameter(THandle, Text);
end;

procedure Reset(var Target: TFunctionFlagArray; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Apply(var Target: TFunctionFlagArray; const Data: TArrayData);
begin
  SetLength(Target, Data.Index);
end;

function AddFlag(var Target: TFunctionFlagArray; var Data: TArrayData; const Value: TFunctionFlag): Integer;
begin
  Data.Count := Length(Target);
  if Data.Index >= Data.Count then
  begin
    Data.Count := Data.Count + ArrayIncrement;
    SetLength(Target, Data.Count);
  end;
  Target[Data.Index] := Value;
  Result := Data.Index;
  Inc(Data.Index);
end;

function AddFlag(var Target: TFunctionFlagArray; var Data: TArrayData;
  const Index, Handle: NativeInt): Integer;
begin
  Result := AddFlag(Target, Data, MakeFunctionFlag(Index, Handle));
end;

function AddFlag(var Target: TFunctionFlagArray; const Value: TFunctionFlag): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  Target[Result] := Value;
end;

function AddFlag(var Target: TFunctionFlagArray; const Index, Handle: NativeInt): Integer;
begin
  Result := AddFlag(Target, MakeFunctionFlag(Index, Handle));
end;

procedure Reset(var Target: TTextItemArray1; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Apply(var Target: TTextItemArray1; const Data: TArrayData);
begin
  SetLength(Target, Data.Index);
end;

function AddItem(var Target: TTextItemArray1; var Data: TArrayData; const Value: TTextItem): Integer;
begin
  Data.Count := Length(Target);
  if Data.Index >= Data.Count then
  begin
    Data.Count := Data.Count + ArrayIncrement;
    SetLength(Target, Data.Count);
  end;
  Target[Data.Index] := Value;
  Result := Data.Index;
  Inc(Data.Index);
end;

function AddItem(var Target: TTextItemArray1; var Data: TArrayData; const Text: string;
  const FHandle, THandle: NativeInt): Integer;
begin
  Result := AddItem(Target, Data, MakeTextItem(Text, FHandle, THandle));
end;

function AddItem(var Target: TTextItemArray1; const Value: TTextItem): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  Target[Result] := Value;
end;

function AddItem(var Target: TTextItemArray1; const Text: string; const FHandle, THandle: NativeInt): Integer;
begin
  Result := AddItem(Target, MakeTextItem(Text, FHandle, THandle));
end;

function InsertInt64(var Target: TScript; Value: Int64; Index: Integer): Boolean;
var
  I: NativeInt;
begin
  I := Length(Target);
  SetLength(Target, I + SizeOf(Int64));
  Result := Insert(Target, @Value, Index, I, SizeOf(Int64));
end;

function InsertNativeInt(var Target: TScript; Value: NativeInt; Index: Integer): Boolean;
var
  I: NativeInt;
begin
  I := Length(Target);
  SetLength(Target, I + SizeOf(NativeInt));
  Result := Insert(Target, @Value, Index, I, SizeOf(NativeInt));
end;

function InsertByte(var Target: TScript; Value: Byte; Index: Integer): Boolean;
var
  I: NativeInt;
begin
  I := Length(Target);
  SetLength(Target, I + SizeOf(Byte));
  Result := Insert(Target, @Value, Index, I, SizeOf(Byte));
end;

procedure IncNumber(var Number: TNumber; const Value: TValue);
begin
  if Number.Valid then
    Number.Value := Operation(Number.Value, Value, otAdd)
  else begin
    Number.Value := Value;
    Number.Valid := True;
  end;
end;

procedure IncNumber(var Number: TNumber; const Parser: TCustomParser; const Script: TScript;
  const ScriptType: TScriptType);
begin
  IncNumber(Number, GetValueFromScript(Parser, Script, ScriptType));
end;

procedure Delete(var SA: TScriptArray);
var
  I: Integer;
begin
  for I := Low(SA) to High(SA) do SA[I] := nil;
  SA := nil;
end;

function FunctionCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.TValueRelationship{$ELSE}TValueRelationship{$ENDIF};
var
  Data: PFunctionData;
begin
  Data := PFunctionData(Target);
  Result := CompareValue(StrLen(FunctionByIndex(Data, BIndex).Name), StrLen(FunctionByIndex(Data, AIndex).Name));
end;

procedure FunctionExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Data: PFunctionData;
  I: NativeInt;
begin
  Data := PFunctionData(Target);
  I := Data.FOrder[AIndex];
  Data.FOrder[AIndex] := Data.FOrder[BIndex];
  Data.FOrder[BIndex] := I;
end;

function Prepare(const Data: PFunctionData): Boolean;
var
  I: Integer;
begin
  Result := not Data.Prepared;
  if Result then
  begin
    SetLength(Data.FOrder, Length(Data.FA));
    for I := Low(Data.FOrder) to High(Data.FOrder) do
      Data.FOrder[I] := I;
    QSort(Data, Low(Data.FA), High(Data.FA), {$IFDEF FPC}@{$ENDIF}FunctionCompare, {$IFDEF FPC}@{$ENDIF}FunctionExchange);
    for I := Low(Data.FA) to High(Data.FA) do
    begin
      case Data.FA[I].Kind of
        fkMethod:
          case Data.FA[I].Method.MethodType of
            mtVariable: Data.FA[I].Handle := @Data.FA[I].Method.Variable.Handle;
          end;
      end;
      if Assigned(Data.FA[I].Handle) then Data.FA[I].Handle^ := I;
    end;
    if not Assigned(Data.NameList) then
    begin
      Data.NameList := TFlexibleList.Create(nil);
      {$IFDEF DELPHI_7}
      Data.NameList.NameValueSeparator := Pipe;
      {$ENDIF}
    end;
    Data.NameList.List.Clear;
    for I := Low(Data.FA) to High(Data.FA) do
      Data.NameList.List.AddObject(Data.FA[I].Name, Pointer(I));
    Data.Prepared := True;
    Cache.TCache(Data.FlagCache).Compile;
    Cache.TCache(Data.ItemCache).Compile;
  end;
end;

function GetType(const Data: PTypeData; Index: NativeInt; out AType: PType): Boolean;
begin
  Result := (Index >= Low(Data.TOrder)) and (Index <= High(Data.TOrder)) and
    (Data.TOrder[Index] >= Low(Data.TA)) and (Data.TOrder[Index] <= High(Data.TA));
  if Result then
    AType := @Data.TA[Data.TOrder[Index]]
  else
    AType := nil;
end;

function TypeByIndex(const Data: PTypeData; const Index: NativeInt): PType;
begin
  GetType(Data, Index, Result);
end;

function TypeCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.TValueRelationship{$ELSE}TValueRelationship{$ENDIF};
var
  Data: PTypeData;
begin
  Data := PTypeData(Target);
  Result := CompareValue(StrLen(TypeByIndex(Data, BIndex).Name), StrLen(TypeByIndex(Data, AIndex).Name));
end;

procedure TypeExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Data: PTypeData;
  I: NativeInt;
begin
  Data := PTypeData(Target);
  I := Data.TOrder[AIndex];
  Data.TOrder[AIndex] := Data.TOrder[BIndex];
  Data.TOrder[BIndex] := I;
end;

function Prepare(const Data: PTypeData): Boolean;
var
  I: Integer;
begin
  Result := not Data.Prepared;
  if Result then
  begin
    SetLength(Data.TOrder, Length(Data.TA));
    for I := Low(Data.TOrder) to High(Data.TOrder) do Data.TOrder[I] := I;
    QSort(Data, Low(Data.TA), High(Data.TA), {$IFDEF FPC}@{$ENDIF}TypeCompare, {$IFDEF FPC}@{$ENDIF}TypeExchange);
    if not Assigned(Data.NameList) then
    begin
      Data.NameList := TFlexibleList.Create(nil);
      {$IFDEF DELPHI_7}
      Data.NameList.NameValueSeparator := Pipe;
      {$ENDIF}
    end;
    Data.NameList.List.Clear;
    for I := Low(Data.TA) to High(Data.TA) do
      Data.NameList.List.AddObject(Data.TA[I].Name, Pointer(I));
    Data.Prepared := True;
  end;
end;

function MakeTypeHandle(const Data: TTypeData; const ValueType: TValueType;
  const DefaultTypeHandle: NativeInt): NativeInt;
var
  I: Integer;
begin
  for I := Low(Data.TA) to High(Data.TA) do
    if Data.TA[I].ValueType = ValueType then
    begin
      Result := I;
      Exit;
    end;
  Result := DefaultTypeHandle;
end;

function AssignUserType(const Parser: TCustomParser; const ItemHeader: PItemHeader; const TypeFlag: Boolean;
  const ValueType: TValueType): Boolean;
var
  AType: PType;
begin
  Result := Parser.GetType(ItemHeader.UserType.Handle, AType);
  if Result then
  begin
    ItemHeader.UserType.Active := TypeFlag;
    ItemHeader.UserType.Handle := MakeTypeHandle(Parser.TData^, ValueType, Parser.DefaultTypeHandle);
  end;
end;

function GetType(const Parser: TCustomParser; const ItemHeader: PItemHeader): PType;
begin
  if not Parser.GetType(ItemHeader.UserType.Handle, Result) then
    Result := Parser.GetType(Parser.DefaultTypeHandle);
end;

function TestFormula(const Parser: TCustomParser; const Text: string; out Script: TScript): TError;
begin
  try
    Parser.StringToScript(Text, Script, Result);
  except
    on E: Exception do Result := MakeError(etUnknown, E.Message);
  end;
  if Result.ErrorType <> etOK then Script := nil;
end;

function FindFormula(const Parser: TCustomParser; const Text: string; out Script: TScript): Boolean;
var
  S: string;
  I, J: Integer;
begin
  S := Trim(Text);
  for I := 1 to Length(S) do for J := Length(S) downto I do
  begin
    Result := TestFormula(Parser, Copy(S, I, J - I + 1), Script).ErrorType = etOK;
    if Result then Exit;
  end;
  Result := False;
end;

initialization
  Helper := TParseHelper.Create;

finalization
  Helper.Free;

end.
