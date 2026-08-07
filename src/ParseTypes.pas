{ ************************************************************************** }
{                                                                            }
{ ParseTypes                                                                 }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseTypes;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Types, FlexibleList, MemoryUtils, TextTypes, ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils, System.Types, BaseTypes, FlexibleList, MemoryUtils, TextTypes, ValueTypes;
  {$ELSE}
  SysUtils, Types, FlexibleList, MemoryUtils, TextTypes, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  TItemCode = (icNumber, icFunction, icString, icScript, icParameter);

  PRedirect = ^TRedirect;
  TRedirect = record
    Index: NativeInt;
    Category: NativeInt;
    Source: NativeInt;
    Target: NativeInt;
  end;
  TRedirectArray = array of TRedirect;

  PScriptHeader = ^TScriptHeader;
  TScriptHeader = record
    Value: TValue;
    ScriptSize: NativeInt;
    ScriptCount: NativeInt;
    HeaderSize: NativeInt;
    RedirectCategory: NativeInt;
  end;

  PUserType = ^TUserType;
  TUserType = record
    Active: Boolean;
    Handle: NativeInt;
  end;

  PItemHeader = ^TItemHeader;
  TItemHeader = record
    Size: NativeInt;
    Sign: NativeInt;
    UserType: TUserType;
  end;

  TCode = NativeInt;

  PScriptNumber = ^TScriptNumber;
  TScriptNumber = record
    Value: TValue;
  end;

  PScriptFunction = ^TScriptFunction;
  TScriptFunction = record
    Handle: NativeInt;
  end;

  PInternalScript = ^TInternalScript;
  TInternalScript = record
    Header: TScriptHeader;
  end;

  TScriptString = record
    Size: NativeInt;
  end;

  PScriptItem = ^TScriptItem;
  TScriptItem = packed record
    Code: TCode;
    case Byte of
      0: (ScriptNumber: TScriptNumber);
      1: (ScriptFunction: TScriptFunction);
      2: (Script: TInternalScript);
      3: (ScriptString: TScriptString);
  end;

  THandle2 = array[0..1] of NativeInt;

  PHandleArray = ^THandleArray;
  THandleArray = array of NativeInt;

  PPType = ^PType;

  PType = ^TType;
  TType = record
    Handle: PNativeInt;
    ValueType: TValueType;
    Name: TString;
  end;

  TTypeArray = array of TType;

  TTypeOrder = {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};

  PTypeData = ^TTypeData;
  TTypeData = record
    TA: TTypeArray;
    TOrder: TTypeOrder;
    NameList: TFlexibleList;
    Prepared: Boolean;
  end;

  TParameter = record
    THandle: NativeInt;
    case Byte of
      0: (Value: TValue);
      1: (Text: TString);
  end;
  PParameterArray = ^TParameterArray;
  TParameterArray = array of TParameter;

  PFunction = ^TFunction;
  TFunctionKind = (fkHandle, fkMethod);

  TMethod0 = function(const Header: PScriptHeader; const AFunction: PFunction;
    const AType: PType): TValue of object;
  TMethod1 = function(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
    const Value: TValue): TValue of object;
  TMethod2 = function(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
    const LValue, RValue: TValue): TValue of object;
  TMethod3 = function(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
    const PA: TParameterArray): TValue of object;

  TMethodType = (mtEmpty, mtMethod0, mtMethod1, mtMethod2, mtMethod3, mtVariable);

  TParameterKind = (pkValue, pkReference);

  PFunctionParameter = ^TFunctionParameter;
  TFunctionParameter = record
    Kind: TParameterKind;
    L, R: Boolean;
    Count: NativeInt;
  end;

  TVariableType = (vtValue, vtValueRef);

  PFunctionVariable = ^TFunctionVariable;
  TFunctionVariable = record
    VariableType: TVariableType;
    Handle: NativeInt;
    case Byte of
      0: (Variable: PValue);
      1: (VariableRef: TValueRef);
  end;

  PFunctionMethod = ^TFunctionMethod;
  TFunctionMethod = record
    Parameter: TFunctionParameter;
    MethodType: TMethodType;
    Variable: TFunctionVariable;
    case Byte of
      0: (Method0: TMethod0);
      1: (Method1: TMethod1);
      2: (Method2: TMethod2);
      3: (Method3: TMethod3);
  end;

  TFunctionPriority = (fpLower, fpNormal, fpHigher);
  TPriorityCoverage = (pcLocal, pcTotal);

  TPriority = record
    Priority: TFunctionPriority;
    Coverage: TPriorityCoverage;
  end;

  TFunction = record
    Handle: PNativeInt;
    ReturnType: TValueType;
    Kind: TFunctionKind;
    Name: TString;
    Method: TFunctionMethod;
    Optimizable: Boolean;
    Priority: TPriority;
  end;
  TFunctionArray = array of TFunction;
  PFunctionArray = array of PFunction;

  TFunctionOrder = {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};

  TFunctionHandle = NativeInt;

  PFunctionData = ^TFunctionData;
  TFunctionData = record
    FA: TFunctionArray;
    FOrder: TFunctionOrder;
    NameList: TFlexibleList;
    FlagCache, ItemCache: TObject;
    Prepared: Boolean;
  end;

  PScript = ^TScript;
  TScript = {$IFDEF DELPHI_10.2}TArray<Byte>{$ELSE}TByteDynArray{$ENDIF};

  TScriptType = (stScriptItem, stScript);

  PScriptArray = ^TScriptArray;
  TScriptArray = array of TScript;

  TItemData = record
    Code: TItemCode;
    case Byte of
      0: (Number: PValue);
      1: (Handle: PNativeInt);
      2: (Text: PString);
      3: (Script: PScript);
  end;

  TBD = record
    Index1, Count1, Index2, Count2: NativeInt;
  end;

  PNumber = ^TNumber;
  TNumber = record
    Value: TValue;
    Valid: Boolean;
  end;

  TScriptMethod = function(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
    const Item: PScriptItem; const Data: Pointer): Boolean of object;

  TFunctionFlagMethod = function(const AFunction: PFunction): Boolean;

  PFunctionFlag = ^TFunctionFlag;
  TFunctionFlag = record
    Index, Handle: NativeInt;
  end;
  TFunctionFlagArray = array of TFunctionFlag;

  PTextItem = ^TTextItem;
  TTextItem = record
    Text: string;
    FHandle: NativeInt;
    THandle: NativeInt;
  end;
  TTextItemArray1 = array of TTextItem;
  TTextItemArray2 = array of TTextItemArray1;

function MakeType(const Name: string; var Handle: NativeInt; const ValueType: TValueType): TType;
function MakeFunction(const Name: string; var Handle: NativeInt; const ReturnType: TValueType;
  const Kind: TFunctionKind; const Method: TFunctionMethod; const Optimizable: Boolean;
  const Priority: TPriority): TFunction;
function MakeParameter(const THandle: NativeInt; const Value: TValue): TParameter; overload;
function MakeParameter(const THandle: NativeInt; const Text: string): TParameter; overload;
function MakeParameter(const L, R: Boolean; const Count: NativeInt;
  const Kind: TParameterKind = pkValue): TFunctionParameter; overload;
function MakeFunctionVariable(const Variable: PValue;
  const Handle: PNativeInt = nil): TFunctionVariable; overload;
function MakeFunctionVariable(const VariableRef: TValueRef;
  const Handle: PNativeInt = nil): TFunctionVariable; overload;
function MakeFunctionMethod(const Parameter: TFunctionParameter): TFunctionMethod; overload;
function MakeFunctionMethod(const LParameter, RParameter: Boolean; const Count: NativeInt;
  const Kind: TParameterKind = pkValue): TFunctionMethod; overload;
function MakeFunctionMethod(const Method: TMethod0): TFunctionMethod; overload;
function MakeFunctionMethod(const Method: TMethod1;
  const Parameter: TFunctionParameter): TFunctionMethod; overload;
function MakeFunctionMethod(const Method: TMethod1; const LParameter, RParameter: Boolean;
  Kind: TParameterKind = pkValue): TFunctionMethod; overload;
function MakeFunctionMethod(const Method: TMethod2): TFunctionMethod; overload;
function MakeFunctionMethod(const Method: TMethod3;
  const Parameter: TFunctionParameter): TFunctionMethod; overload;
function MakeFunctionMethod(const Method: TMethod3; const Count: NativeInt;
  const Kind: TParameterKind = pkValue): TFunctionMethod; overload;
function MakeFunctionMethod(const Variable: TFunctionVariable): TFunctionMethod; overload;
function MakeFunctionMethod(const Variable: PValue;
  const Handle: PNativeInt = nil): TFunctionMethod; overload;
function MakeFunctionMethod(const Variable: TValueRef;
  const Handle: PNativeInt = nil): TFunctionMethod; overload;
function MakePriority(const Priority: TFunctionPriority; const Coverage: TPriorityCoverage): TPriority;
function MakeItemData(var Number: TValue): TItemData; overload;
function MakeItemData(var Handle: NativeInt): TItemData; overload;
function MakeItemData(var Text: TString): TItemData; overload;
function MakeItemData(var Script: TScript; const Parameter: Boolean): TItemData; overload;
function MakeNumber(const Value: TValue; const Valid: Boolean): TNumber;
function MakeUserType(const Active: Boolean; const Handle: NativeInt): TUserType; overload;
function MakeUserType(const AType: PType; DefaultTypeHandle: NativeInt): TUserType; overload;
function MakeFunctionFlag(const Index, Handle: NativeInt): TFunctionFlag;
function MakeTextItem(const Text: string; const FHandle, THandle: NativeInt): TTextItem;
function ConvertToFunction(const AFunction: PFunction; const Handle: PNativeInt): Boolean;
function ConvertToVariable(const AFunction: PFunction; const Variable: PValue): Boolean;
procedure WriteNumber(var Script: TScript; const Value: TValue);
procedure WriteFunction(var Script: TScript; const Handle: NativeInt);
procedure WriteScript(var Target: TScript; const Source: TScript; const Parameter: Boolean;
  const ItemIndex: PNativeInt = nil);
procedure WriteString(var Script: TScript; const S: string); overload;
procedure WriteString(var Script: TScript; const Source: Pointer; const Count: NativeInt); overload;

threadvar
  ParseBreak: PBoolean;
  ParseLoopLeft: NativeInt;

type
  TLoopGuard = record
    Flag: PBoolean;
    Left: NativeInt;
  end;

procedure ArmLoopGuard(out Saved: TLoopGuard; const Turns: NativeInt; const Flag: PBoolean = nil);
procedure DisarmLoopGuard(const Saved: TLoopGuard);

implementation

uses
  {$IFDEF FPC}
  ParseConsts, ParseUtils, ValueUtils;
  {$ELSE}
  ParseConsts, ParseUtils, ValueUtils;
  {$ENDIF}

function MakeType(const Name: string; var Handle: NativeInt; const ValueType: TValueType): TType;
begin
  FillChar(Result, SizeOf(TType), 0);
  StrLCopy(Result.Name, PChar(Name), High(TString));
  Result.Handle := @Handle;
  Result.ValueType := ValueType;
end;

function MakeFunction(const Name: string; var Handle: NativeInt; const ReturnType: TValueType;
  const Kind: TFunctionKind; const Method: TFunctionMethod; const Optimizable: Boolean;
  const Priority: TPriority): TFunction;
begin
  FillChar(Result, SizeOf(TFunction), 0);
  StrLCopy(Result.Name, PChar(Name), High(TString));
  Result.Handle := @Handle;
  Result.ReturnType := ReturnType;
  Result.Kind := Kind;
  Result.Method := Method;
  Result.Optimizable := Optimizable;
  Result.Priority := Priority;
end;

function MakeParameter(const THandle: NativeInt; const Value: TValue): TParameter;
begin
  FillChar(Result, SizeOf(TParameter), 0);
  Result.THandle := THandle;
  Result.Value := Value;
end;

function MakeParameter(const THandle: NativeInt; const Text: string): TParameter;
begin
  FillChar(Result, SizeOf(TParameter), 0);
  Result.THandle := THandle;
  StrLCopy(Result.Text, PChar(Text), High(TString));
end;

function MakeParameter(const L, R: Boolean; const Count: NativeInt;
  const Kind: TParameterKind): TFunctionParameter;
begin
  FillChar(Result, SizeOf(TFunctionParameter), 0);
  Result.L := L;
  Result.R := R;
  Result.Count := Count;
  Result.Kind := Kind;
end;

function MakeFunctionVariable(const Variable: PValue; const Handle: PNativeInt): TFunctionVariable;
begin
  FillChar(Result, SizeOf(TFunctionVariable), 0);
  Result.VariableType := vtValue;
  if Assigned(Handle) then Result.Handle := Handle^;
  Result.Variable := Variable;
end;

function MakeFunctionVariable(const VariableRef: TValueRef; const Handle: PNativeInt): TFunctionVariable;
begin
  FillChar(Result, SizeOf(TFunctionVariable), 0);
  Result.VariableType := vtValueRef;
  if Assigned(Handle) then Result.Handle := Handle^;
  Result.VariableRef := VariableRef;
end;

function MakeFunctionMethod(const Parameter: TFunctionParameter): TFunctionMethod;
begin
  FillChar(Result, SizeOf(TFunctionMethod), 0);
  Result.Parameter := Parameter;
end;

function MakeFunctionMethod(const LParameter, RParameter: Boolean; const Count: NativeInt;
  const Kind: TParameterKind = pkValue): TFunctionMethod;
begin
  Result := MakeFunctionMethod(MakeParameter(LParameter, RParameter, Count, Kind));
end;

function MakeFunctionMethod(const Method: TMethod0): TFunctionMethod;
begin
  FillChar(Result, SizeOf(TFunctionMethod), 0);
  Result.MethodType := mtMethod0;
  Result.Method0 := Method;
end;

function MakeFunctionMethod(const Method: TMethod1; const Parameter: TFunctionParameter): TFunctionMethod;
begin
  FillChar(Result, SizeOf(TFunctionMethod), 0);
  Result.Parameter := Parameter;
  Result.MethodType := mtMethod1;
  Result.Method1 := Method;
end;

function MakeFunctionMethod(const Method: TMethod1; const LParameter, RParameter: Boolean;
  Kind: TParameterKind): TFunctionMethod;
begin
  Result := MakeFunctionMethod(Method, MakeParameter(LParameter, RParameter, 0, Kind));
end;

function MakeFunctionMethod(const Method: TMethod2): TFunctionMethod;
begin
  FillChar(Result, SizeOf(TFunctionMethod), 0);
  Result.Parameter.L := True;
  Result.Parameter.R := True;
  Result.MethodType := mtMethod2;
  Result.Method2 := Method;
end;

function MakeFunctionMethod(const Method: TMethod3; const Parameter: TFunctionParameter): TFunctionMethod;
begin
  FillChar(Result, SizeOf(TFunctionMethod), 0);
  Result.Parameter := Parameter;
  Result.MethodType := mtMethod3;
  Result.Method3 := Method;
end;

function MakeFunctionMethod(const Method: TMethod3; const Count: NativeInt;
  const Kind: TParameterKind = pkValue): TFunctionMethod;
begin
  Result := MakeFunctionMethod(Method, MakeParameter(False, False, Count, Kind));
end;

function MakeFunctionMethod(const Variable: TFunctionVariable): TFunctionMethod;
begin
  FillChar(Result, SizeOf(TFunctionMethod), 0);
  Result.MethodType := mtVariable;
  Result.Variable := Variable;
end;

function MakeFunctionMethod(const Variable: PValue; const Handle: PNativeInt): TFunctionMethod;
begin
  Result := MakeFunctionMethod(MakeFunctionVariable(Variable, Handle));
end;

function MakeFunctionMethod(const Variable: TValueRef; const Handle: PNativeInt): TFunctionMethod;
begin
  Result := MakeFunctionMethod(MakeFunctionVariable(Variable, Handle));
end;

procedure ArmLoopGuard(out Saved: TLoopGuard; const Turns: NativeInt; const Flag: PBoolean);
begin
  Saved.Flag := ParseBreak;
  Saved.Left := ParseLoopLeft;
  ParseBreak := Flag;
  ParseLoopLeft := Turns;
end;

procedure DisarmLoopGuard(const Saved: TLoopGuard);
begin
  ParseBreak := Saved.Flag;
  ParseLoopLeft := Saved.Left;
end;

function MakePriority(const Priority: TFunctionPriority; const Coverage: TPriorityCoverage): TPriority;
begin
  FillChar(Result, SizeOf(TPriority), 0);
  Result.Priority := Priority;
  Result.Coverage := Coverage;
end;

function MakeItemData(var Number: TValue): TItemData;
begin
  FillChar(Result, SizeOf(TItemData), 0);
  Result.Code := icNumber;
  Result.Number := @Number;
end;

function MakeItemData(var Handle: NativeInt): TItemData;
begin
  FillChar(Result, SizeOf(TItemData), 0);
  Result.Code := icFunction;
  Result.Handle := @Handle;
end;

function MakeItemData(var Text: TString): TItemData;
begin
  FillChar(Result, SizeOf(TItemData), 0);
  Result.Code := icString;
  Result.Text := @Text;
end;

function MakeItemData(var Script: TScript; const Parameter: Boolean): TItemData;
begin
  FillChar(Result, SizeOf(TItemData), 0);
  Result.Code := TItemCode(Ord(icScript) + Ord(Parameter));
  Result.Script := @Script;
end;

function MakeNumber(const Value: TValue; const Valid: Boolean): TNumber;
begin
  FillChar(Result, SizeOf(TNumber), 0);
  Result.Value := Value;
  Result.Valid := Valid;
end;

function MakeUserType(const Active: Boolean; const Handle: NativeInt): TUserType;
begin
  FillChar(Result, SizeOf(TUserType), 0);
  Result.Active := Active;
  Result.Handle := Handle;
end;

function MakeUserType(const AType: PType; DefaultTypeHandle: NativeInt): TUserType;
begin
  if Assigned(AType) then DefaultTypeHandle := AType.Handle^;
  Result := MakeUserType(Assigned(AType), DefaultTypeHandle);
end;

function MakeFunctionFlag(const Index, Handle: NativeInt): TFunctionFlag;
begin
  FillChar(Result, SizeOf(TFunctionFlag), 0);
  Result.Index := Index;
  Result.Handle := Handle;
end;

function MakeTextItem(const Text: string; const FHandle, THandle: NativeInt): TTextItem;
begin
  FillChar(Result, SizeOf(TTextItem), 0);
  Result.Text := Text;
  Result.FHandle := FHandle;
  Result.THandle := THandle;
end;

function ConvertToFunction(const AFunction: PFunction; const Handle: PNativeInt): Boolean;
begin
  Result := (AFunction.Kind = fkMethod) and (AFunction.Method.MethodType = mtVariable);
  if Result then
  begin
    AFunction.Handle := Handle;
    if Assigned(AFunction.Handle) then
      AFunction.Handle^ := AFunction.Method.Variable.Handle;
    AFunction.Kind := fkHandle;
  end;
end;

function ConvertToVariable(const AFunction: PFunction; const Variable: PValue): Boolean;
begin
  Result := AFunction.Kind = fkHandle;
  if Result then
  begin
    if Assigned(AFunction.Handle) then
      AFunction.Method.Variable.Handle := AFunction.Handle^;
    AFunction.Handle := @AFunction.Method.Variable.Handle;
    AFunction.Method.MethodType := mtVariable;
    AFunction.Method.Variable.Variable := Variable;
    AFunction.Kind := fkMethod;
  end;
end;

procedure WriteNumber(var Script: TScript; const Value: TValue);
var
  Number: TScriptNumber;
begin
  AddNativeInt(Script, NativeInt(NumberCode));
  FillChar(Number, SizeOf(TScriptNumber), 0);
  Number.Value := Value;
  AddScriptNumber(Script, Number);
end;

procedure WriteFunction(var Script: TScript; const Handle: NativeInt);
var
  AFunction: TScriptFunction;
begin
  AddNativeInt(Script, NativeInt(FunctionCode));
  FillChar(AFunction, SizeOf(TScriptFunction), 0);
  AFunction.Handle := Handle;
  AddScriptFunction(Script, AFunction);
end;

procedure WriteScript(var Target: TScript; const Source: TScript; const Parameter: Boolean;
  const ItemIndex: PNativeInt);
var
  I: Integer;
  J: NativeInt;
  Header: PScriptHeader absolute Target;
begin
  if Parameter then
    AddNativeInt(Target, NativeInt(ParameterCode))
  else
    if Assigned(ItemIndex) then
    begin
      J := SizeOf(TScriptHeader);
      for I := 0 to Header.ScriptCount - 1 do
      begin
        Inc(PNativeInt(@Target[J])^, SizeOf(NativeInt));
        Inc(J, SizeOf(NativeInt));
      end;
      I := SizeOf(TScriptHeader) + Header.ScriptCount * SizeOf(NativeInt);
      Inc(Header.ScriptCount);
      J := Length(Target) + SizeOf(NativeInt) + SizeOf(TCode);
      InsertNativeInt(Target, J, I);
      if Assigned(ItemIndex) then Inc(ItemIndex^, SizeOf(NativeInt));
      AddNativeInt(Target, ScriptCode);
    end
    else
      AddNativeInt(Target, ScriptCode);
  AddMemory(Target, Source, Length(Source));
end;

procedure WriteString(var Script: TScript; const S: string);
begin
  AddNativeInt(Script, StringCode);
  AddNativeInt(Script, Length(S) * SizeOf(Char));
  AddString(Script, S);
end;

procedure WriteString(var Script: TScript; const Source: Pointer; const Count: NativeInt);
begin
  AddNativeInt(Script, NativeInt(StringCode));
  AddNativeInt(Script, Count);
  AddMemory(Script, Source, Count);
end;

end.
