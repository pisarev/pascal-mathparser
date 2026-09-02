{ ************************************************************************** }
{                                                                            }
{ Parser                                                                     }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit Parser;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  {$IFDEF MSWINDOWS}Windows, Messages,{$ELSE}WinMem, Compat.Messages,{$ENDIF}
  SysUtils, Classes, Types, Math, FlexibleList, MemoryUtils, Notifier, ParseCache,
  ParseConsts, ParseErrors, ParseMethod, ParseTypes, TextConsts, TextBuilder, TextTypes,
  ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, WinApi.Messages, System.SysUtils, System.Classes, System.Types,
  System.Math, BaseTypes, FlexibleList, MemoryUtils, Notifier, ParseCache, ParseConsts,
  ParseErrors, ParseMethod, ParseTypes, TextConsts, TextBuilder, TextTypes, ValueTypes;
  {$ELSE}
  Windows, Messages, SysUtils, Classes, Types, Math, FlexibleList, MemoryUtils,
  Notifier, ParseCache, ParseConsts, ParseErrors, ParseMethod, ParseTypes, TextConsts,
  TextBuilder, TextTypes, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  TFunctionEvent = function(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
    out Value: TValue; const LValue, RValue: TValue; const PA: TParameterArray): Boolean of object;

  TTextType = (ttUnknown, ttNumber, ttFunction, ttString, ttScript);
  TTextData = record
    TextType: TTextType;
    Value: TValue;
    Handle: NativeInt;
    Text: TString;
  end;

  TOperatorKind = (okBof, okEof, okNumber, okFunction, okScript, okParameter);
  TSyntax = record
    PriorKind: TOperatorKind;
    PriorHandle: NativeInt;
  end;

  PBracketData = ^TBracketData;
  TBracketData = record
    SA: PScriptArray;
    Parameter: Boolean;
    Text: TTextBuilder;
    Idle: PFunction;
  end;

  PPAData = ^TPAData;
  TPAData = record
    Idle: Boolean;
    PA: PParameterArray;
    AD: TArrayData;
    Index: PNativeInt;
  end;

  PPOData = ^TPOData;
  TPOData = record
    ItemArray: TScriptArray;
    Optimal: Boolean;
  end;

  POSData = ^TOSData;
  TOSData = record
    ItemArray: TScriptArray;
    Number: TNumber;
  end;

  TRetrieveMode = (rmNone, rmUser, rmFull);

  PDSData = ^TDSData;
  TDSData = record
    Text, ItemText: TTextBuilder;
    Delimiter: string;
    AFunction: PFunction;
    Parameter: Boolean;
    ParameterBracket: TBracket;
    TypeMode: TRetrieveMode;
  end;

const
  CacheSeparator = #1;

type
  TCacheType = (ctRawscript, ctScript, ctParameter, ctSubscript, ctSubparameter);
  TCacheArray = array[TCacheType] of TParseCache;

  TCustomParser = class;

  TCache = class(TComponent)
  private
    FSubscript: TParseCache;
    FRawscript: TParseCache;
    FScript: TParseCache;
    FSubparameter: TParseCache;
    {$IFDEF DELPHI_7}
    FNameValueSeparator: Char;
    {$ENDIF}
    FParser: TCustomParser;
    FParameter: TParseCache;
    FCacheArray: TCacheArray;
    function GetCache(CacheType: TCacheType): TParseCache;
    procedure SetSubcache(const Value: TParseCache);
    {$IFDEF DELPHI_7}
    procedure SetNameValueSeparator(const Value: Char);
    {$ENDIF}
  protected
    procedure SetCacheType(const Value: TListType); virtual;
    property CacheArray: TCacheArray read FCacheArray;
    property Parser: TCustomParser read FParser write FParser;
  public
    constructor Create(const AParser: TCustomParser;
      const AConnector: TComponent); reintroduce; overload; virtual;
    procedure Prepare; virtual;
    procedure Clear; virtual;
    {$IFDEF DELPHI_7}
    procedure WriteNameValueSeparator; virtual;
    {$ENDIF}
    property Cache[CacheType: TCacheType]: TParseCache read GetCache;
    property CacheType: TListType write SetCacheType;
  published
    {$IFDEF DELPHI_7}
    property NameValueSeparator: Char read FNameValueSeparator write SetNameValueSeparator default CacheSeparator;
    {$ENDIF}
    property Rawscript: TParseCache read FRawscript write SetSubcache;
    property Script: TParseCache read FScript write SetSubcache;
    property Parameter: TParseCache read FParameter write SetSubcache;
    property Subscript: TParseCache read FSubscript write SetSubcache;
    property Subparameter: TParseCache read FSubparameter write SetSubcache;
  end;

  TParameterType = (ptParameter, ptScript);

  TNotify = record
    NotifyType: TNotifyType;
    Component: TComponent;
  end;
  TNotifyArray = array of TNotify;

  TExecuteKind = (ekSubsequent);
  TExecuteKindSet = set of TExecuteKind;
  TBooleanMode = (bmShortCircuit, bmComplete);

  TCustomParser = class(TComponent)
  private
    FAddressee: TComponent;
    FBeforeFunction: TFunctionEvent;
    FBooleanMode: TBooleanMode;
    FBracket: TBracket;
    FConstantList: TFlexibleList;
    FDefaultTypeHandle: NativeInt;
    FDefaultValueType: TValueType;
    FDeleteHandle: NativeInt;
    FExceptionMask: TFPUExceptionMask;
    FExecuteHandle: NativeInt;
    FExecuteKindSet: TExecuteKindSet;
    FFData: PFunctionData;
    FFindHandle: NativeInt;
    FForHandle: NativeInt;
    FGetHandle: NativeInt;
    FIgnoreType: array[TItemCode] of Boolean;
    FInternalHandle: NativeInt;
    FMethod: TMethod;
    FNegativeHandle: PNativeInt;
    FNegativeValue: TValue;
    FNewHandle: NativeInt;
    FNotifyArray: TNotifyArray;
    FOArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};
    FOnFunction: TFunctionEvent;
    FParameterBracket: TBracket;
    FPData: PFunctionData;
    FPositiveHandle: PNativeInt;
    FPositiveValue: TValue;
    FPrioritize: Boolean;
    FRepeatHandle: NativeInt;
    FScriptHandle: NativeInt;
    FSetHandle: NativeInt;
    FStringHandle: NativeInt;
    FTData: PTypeData;
    FUpdateCount: Integer;
    FVoidHandle: NativeInt;
    FWhileHandle: NativeInt;
    {$IFNDEF FPC}
    FWindowHandle: THandle;
    {$ENDIF}
    function GetBoolean32(const Index: Boolean): NativeInt;
    function GetIgnoreType(const ItemCode: TItemCode): Boolean;
    procedure SetBoolean32(const Index: Boolean; const Value: NativeInt);
    procedure SetIgnoreType(const ItemCode: TItemCode; const Value: Boolean);
    function InternalAddFunction(const AFunction: TFunction): Boolean; overload;
    function InternalAddFunction(const AName: string; var Handle: NativeInt; const Kind: TFunctionKind;
      const Method: TFunctionMethod; const Optimizable: Boolean; const ReturnType: TValueType = vtUnknown;
      const Priority: TFunctionPriority = fpNormal;
      const Coverage: TPriorityCoverage = pcLocal): Boolean; overload;
    function InternalAddVariable(const AName: string; var Variable: TValue; const Optimizable: Boolean;
      const ReturnType: TValueType = vtUnknown): Boolean; overload;
    function InternalAddVariable(const AName: string; const Variable: TValueRef; const Optimizable: Boolean;
      const ReturnType: TValueType = vtUnknown): Boolean; overload;
    function InternalAddConstant(const AName: string; const Value: TValue): Boolean;
    function GetFInternal: PFunction;
  protected
    procedure Notification(Component: TComponent; Operation: TOperation); override;
    procedure WindowMethod(var Message: TMessage); virtual;
    function Notifiable(const NotifyType: TNotifyType): Boolean; virtual;
    procedure Notify; overload; virtual;
    function DoEvent(const Event: TFunctionEvent; const Header: PScriptHeader; const AFunction: PFunction;
      const AType: PType; out Value: TValue; const LValue, RValue: TValue;
      const PA: TParameterArray): Boolean; virtual;
    procedure ReadParameterArray(var AIndex: NativeInt; out AParameterArray: TParameterArray;
      const ParameterType: TParameterType = ptParameter; const AIdle: Boolean = False); virtual; abstract;
    function GetTextData(const Text: string): TTextData; virtual;
    function CheckFHandle(const Handle: NativeInt): Boolean; virtual;
    function CheckTHandle(const Handle: NativeInt): Boolean; virtual;
    function Check(const Text: string): TError; overload; virtual;
    function Check(var Syntax: TSyntax; const Kind: TOperatorKind; const Text: string; const SA: TScriptArray;
      const Handle: NativeInt): TError; overload; virtual;
    function Check(const ItemArray: TTextItemArray1; const Index: NativeInt; const Data: TItemData;
      const SA: TScriptArray; const Parameter: Boolean = False): TError; overload; virtual;
    function InternalCompile(const Text: string; var SA: TScriptArray; const Parameter: Boolean;
      var Idle: PFunction; out Error: TError): TScript; overload; virtual; abstract;
    function InternalCompile(const Text: string; var SA: TScriptArray; const Parameter: Boolean;
      var Idle: PFunction): TScript; overload; virtual; abstract;
    procedure InternalOptimizeScript(const Index: NativeInt; out Script: TScript); virtual; abstract;
    function InternalDecompile(const Index: NativeInt; const ADelimiter: string; const AParameter: Boolean;
      const ABracket: TBracket; const ATypeMode: TRetrieveMode): string; virtual; abstract;
    property NotifyArray: TNotifyArray read FNotifyArray write FNotifyArray;
    property Method: TMethod read FMethod write FMethod;
    property TextData[const Text: string]: TTextData read GetTextData;
    property ConstantList: TFlexibleList read FConstantList write FConstantList;
    property FInternal: PFunction read GetFInternal;
    property InternalHandle: NativeInt read FInternalHandle;
    property NegativeHandle: PNativeInt read FNegativeHandle;
    property PositiveHandle: PNativeInt read FPositiveHandle;
    property OArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF} read FOArray write FOArray;
  public
    constructor Create(AOwner: TComponent); override;
    property ExceptionMask: TFPUExceptionMask read FExceptionMask write FExceptionMask;
    destructor Destroy; override;
    function Connect(const ABeforeFunction: TFunctionEvent;
      const AAddressee: TCustomAddressee): TFunctionEvent; virtual;
    procedure Notify(const NotifyType: TNotifyType; const Sender: TComponent); overload; virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    function AddConstant(const AName: string; const Value: TValue): Boolean; overload; virtual;
    {$IFDEF DELPHI_2006}
    function AddConstant(const AName: string; const Value: Byte): Boolean; overload; virtual;
    function AddConstant(const AName: string; const Value: Shortint): Boolean; overload; virtual;
    function AddConstant(const AName: string; const Value: Word): Boolean; overload; virtual;
    function AddConstant(const AName: string; const Value: Smallint): Boolean; overload; virtual;
    function AddConstant(const AName: string; const Value: LongWord): Boolean; overload; virtual;
    function AddConstant(const AName: string; const Value: NativeInt): Boolean; overload; virtual;
    {$ENDIF}
    function AddConstant(const AName: string; const Value: Int64): Boolean; overload; virtual;
    {$IFDEF DELPHI_2006}
    function AddConstant(const AName: string; const Value: Single): Boolean; overload; virtual;
    {$ENDIF}
    function AddConstant(const AName: string; const Value: Double): Boolean; overload; virtual;
    {$IFDEF DELPHI_2006}
    function AddConstant(const AName: string; const Value: Extended): Boolean; overload; virtual;
    {$ENDIF}
    function AddConstant(const AName: string; const Value: Boolean): Boolean; overload; virtual;
    function AddFunction(const AFunction: TFunction): Boolean; overload; virtual;
    function AddFunction(const AName: string; var Handle: NativeInt; const Kind: TFunctionKind;
      const Method: TFunctionMethod; const Optimizable: Boolean; const ReturnType: TValueType = vtUnknown;
      const Priority: TFunctionPriority = fpNormal;
      const Coverage: TPriorityCoverage = pcLocal): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: TValue; const Optimizable: Boolean;
      const ReturnType: TValueType = vtUnknown): Boolean; overload; virtual;
    function AddVariable(const AName: string; const Variable: TValueRef; const Optimizable: Boolean;
      const ReturnType: TValueType = vtUnknown): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: TValue): Boolean; overload; virtual;
    function AddVariable(const AName: string; const Variable: TValueRef): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Byte): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Shortint): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Word): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Smallint): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: LongWord): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Integer): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: NativeInt): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Int64): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Single): Boolean; overload; virtual;
    {$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
    function AddVariable(const AName: string; var Variable: Double): Boolean; overload; virtual;
    {$ENDIF}
    function AddVariable(const AName: string; var Variable: Extended): Boolean; overload; virtual;
    function AddVariable(const AName: string; var Variable: Boolean): Boolean; overload; virtual;
    function DeleteConstant(const AName: string): Boolean; virtual;
    function DeleteFunction(const Handle: NativeInt): Boolean; overload; virtual;
    function DeleteFunction(const HandleArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}): NativeInt; overload; virtual;
    function DeleteVariable(var Variable: TValue): Boolean; virtual;
    function FindConstant(const AName: string): PValue; overload; virtual;
    function FindConstant(const AName: string; out Value: PValue): Boolean; overload; virtual;
    function FindFunction(const AName: string): PFunction; overload; virtual;
    function GetFunction(const Handle: NativeInt; var AFunction: PFunction): Boolean; overload; virtual;
    function GetFunction(const Handle: NativeInt): PFunction; overload; virtual;
    function GetFunction(const Variable: PValue): PFunction; overload; virtual;
    function AddType(const AType: TType): Boolean; overload; virtual;
    function AddType(const AName: string; var Handle: NativeInt;
      const ValueType: TValueType): Boolean; overload; virtual;
    function DeleteType(const Handle: NativeInt): Boolean; overload; virtual;
    function DeleteType(const HandleArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}): NativeInt; overload; virtual;
    function FindType(const AName: string): PType; overload; virtual;
    function GetType(const Handle: NativeInt; var AType: PType): Boolean; overload; virtual;
    function GetType(const Handle: NativeInt): PType; overload; virtual;
    procedure StringToScript(const Text: string; out Script: TScript;
      out Error: TError); overload; virtual; abstract;
    procedure StringToScript(const Text: string; out Script: TScript); overload; virtual; abstract;
    procedure OptimizeScript(const Source: TScript; out Target: TScript); overload; virtual; abstract;
    procedure OptimizeScript(var Script: TScript); overload; virtual; abstract;
    function ScriptToString(const Script: TScript;
      const TypeMode: TRetrieveMode = rmUser): string; overload; virtual; abstract;
    function ScriptToString(const Script: TScript; const Delimiter: string;
      const TypeMode: TRetrieveMode = rmUser): string; overload; virtual; abstract;
    function ScriptToString(const Script: TScript; const Delimiter: string; const ABracket: TBracket;
      const TypeMode: TRetrieveMode = rmUser): string; overload; virtual; abstract;
    function ExecuteScript(const NativeInt: NativeInt): PValue; virtual; abstract;
    function ExecuteFunction(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const LValue: TValue; const Idle: Boolean = False): TValue; virtual; abstract;
    function AsValue(const Text: string): TValue; virtual;
    function AsByte(const Text: string): Byte; virtual;
    function AsShortint(const Text: string): Shortint; virtual;
    function AsWord(const Text: string): Word; virtual;
    function AsSmallint(const Text: string): Smallint; virtual;
    function AsLongWord(const Text: string): LongWord; virtual;
    function AsInteger(const Text: string): NativeInt; virtual;
    function AsInt64(const Text: string): Int64; virtual;
    function AsSingle(const Text: string): Single; virtual;
    function AsDouble(const Text: string): Double; virtual;
    function AsExtended(const Text: string): Extended; virtual;
    function AsBoolean(const Text: string): Boolean; virtual;
    function AsPointer(const Text: string): Pointer; virtual;
    function AsString(const Text: string): string; virtual;
    function DefaultFunction(const Header: PScriptHeader; const AFunction: PFunction; out Value: TValue;
      const LValue, RValue: TValue; const PA: TParameterArray): Boolean; virtual;
    procedure Prepare; virtual;
    property Addressee: TComponent read FAddressee write FAddressee;
    property IgnoreType[const ItemCode: TItemCode]: Boolean read GetIgnoreType write SetIgnoreType;
    {$IFNDEF FPC}
    property WindowHandle: THandle read FWindowHandle write FWindowHandle;
    {$ENDIF}
    property BeforeFunction: TFunctionEvent read FBeforeFunction write FBeforeFunction;
    property UpdateCount: Integer read FUpdateCount;
    property FData: PFunctionData read FFData write FFData;
    property TData: PTypeData read FTData write FTData;
    property DefaultTypeHandle: NativeInt read FDefaultTypeHandle write FDefaultTypeHandle;
    property PData: PFunctionData read FPData;
    property Bracket: TBracket read FBracket write FBracket;
    property ParameterBracket: TBracket read FParameterBracket write FParameterBracket;
    property PositiveValue: TValue read FPositiveValue write FPositiveValue;
    property NegativeValue: TValue read FNegativeValue write FNegativeValue;
    property Boolean32[const Index: Boolean]: NativeInt read GetBoolean32 write SetBoolean32;
    property VoidHandle: NativeInt read FVoidHandle;
    property NewHandle: NativeInt read FNewHandle;
    property DeleteHandle: NativeInt read FDeleteHandle;
    property FindHandle: NativeInt read FFindHandle;
    property GetHandle: NativeInt read FGetHandle;
    property SetHandle: NativeInt read FSetHandle;
    property ScriptHandle: NativeInt read FScriptHandle;
    property ExecuteHandle: NativeInt read FExecuteHandle;
    property ForHandle: NativeInt read FForHandle;
    property RepeatHandle: NativeInt read FRepeatHandle;
    property WhileHandle: NativeInt read FWhileHandle;
    property StringHandle: NativeInt read FStringHandle;
  published
    property Prioritize: Boolean read FPrioritize write FPrioritize default True;
    property ExecuteKindSet: TExecuteKindSet read FExecuteKindSet write FExecuteKindSet default [ekSubsequent];
    property BooleanMode: TBooleanMode read FBooleanMode write FBooleanMode;
    property DefaultValueType: TValueType read FDefaultValueType write FDefaultValueType default vtInteger;
    property OnFunction: TFunctionEvent read FOnFunction write FOnFunction;
  end;

  TExceptionType = (etZeroDivide);
  TExceptionTypeSet = set of TExceptionType;

const
  DefaultExceptionTypeSet = [etZeroDivide];

type
  TParser = class(TCustomParser)
  private
    FAboveHandle: NativeInt;
    FAboveOrEqualHandle: NativeInt;
    FAndHandle: THandle2;
    FBelowHandle: NativeInt;
    FBelowOrEqualHandle: NativeInt;
    FBitwiseAndHandle: NativeInt;
    FBitwiseNotHandle: NativeInt;
    FBitwiseOrHandle: NativeInt;
    FBitwiseXorHandle: NativeInt;
    FByteHandle: NativeInt;
    FCache: TCache;
    FCached: Boolean;
    FConnector: TComponent;
    FDerivHandle: NativeInt;
    FDivideHandle: NativeInt;
    FDoubleHandle: NativeInt;
    FEnsureRangeHandle: NativeInt;
    FEpsilonHandle: NativeInt;
    FEqualHandle: NativeInt;
    FExceptionTypeSet: TExceptionTypeSet;
    FExitHandle: NativeInt;
    FExtendedHandle: NativeInt;
    FFalseHandle: NativeInt;
    FGetEpsilonHandle: NativeInt;
    FIfHandle: NativeInt;
    FIfThenHandle: NativeInt;
    FInt64Handle: NativeInt;
    FIntegerHandle: NativeInt;
    FIsZeroHandle: NativeInt;
    FLongWordHandle: NativeInt;
    FMultiplyHandle: NativeInt;
    FNativeIntHandle: NativeInt;
    FNativeUIntHandle: NativeInt;
    FNotEqualHandle: NativeInt;
    FNotHandle: THandle2;
    FOrHandle: THandle2;
    FParseHandle: NativeInt;
    FParseManager: TObject;
    FPredHandle: NativeInt;
    FRedirectList: TList;
    FSameValueHandle: NativeInt;
    FScript: TScript;
    FSetDecimalSeparatorHandle: NativeInt;
    FSetEpsilonHandle: NativeInt;
    FShlHandle: THandle2;
    FShortintHandle: NativeInt;
    FShrHandle: THandle2;
    FSingleHandle: NativeInt;
    FSmallintHandle: NativeInt;
    FStrToFloatDefHandle: NativeInt;
    FStrToFloatHandle: NativeInt;
    FStrToIntDefHandle: NativeInt;
    FStrToIntHandle: NativeInt;
    FSuccHandle: NativeInt;
    FText: string;
    FTrueHandle: NativeInt;
    FTryExceptHandle: NativeInt;
    FTryFinallyHandle: NativeInt;
    FWordHandle: NativeInt;
    FXorHandle: THandle2;
  protected
    function ParseMethod(var Text: string; const FromIndex, TillIndex: NativeInt;
      const P: Pointer): TError; virtual;
    function ESMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function SAMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function PAMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function OSMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function POMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function DSMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function SCMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const Item: PScriptItem; const P: Pointer): Boolean; virtual;
    function Order(const Coverage: TPriorityCoverage; var ItemArray: TTextItemArray1; var SA: TScriptArray;
      var Idle: PFunction): Boolean; virtual;
    function Morph(var ItemArray1: TTextItemArray1; out ItemArray2: TTextItemArray2): Boolean;
    procedure Parse(var Text: string; var SA: TScriptArray; var Idle: PFunction;
      out Error: TError); overload; virtual;
    procedure Parse(var Text: string; var SA: TScriptArray; var Idle: PFunction); overload; virtual;
    function InternalCompile(const Text: string; var SA: TScriptArray; const Parameter: Boolean;
      var Idle: PFunction; out Error: TError): TScript; overload; override;
    function InternalCompile(const Text: string; var SA: TScriptArray; const Parameter: Boolean;
      var Idle: PFunction): TScript; overload; override;
    procedure ExecuteInternalScript(Index: NativeInt); virtual;
    procedure ReadParameterArray(var Index: NativeInt; out PA: TParameterArray;
      const ParameterType: TParameterType = ptParameter; const Idle: Boolean = False); override;
    procedure InternalOptimizeScript(const Index: NativeInt; out Script: TScript); override;
    function OptimizeParameterArray(Index: NativeInt; out Script: TScript): Boolean; virtual;
    function Optimizable(var Index: NativeInt; const Number: Boolean; out Offset: NativeInt;
      out Parameter: Boolean; out Script: TScript): Boolean; virtual;
    function InternalDecompile(const Index: NativeInt; const Delimiter: string; const Parameter: Boolean;
      const ParameterBracket: TBracket; const TypeMode: TRetrieveMode): string; override;
    property RedirectList: TList read FRedirectList write FRedirectList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Connect(const ABeforeFunction: TFunctionEvent;
      const AAddressee: TCustomAddressee): TFunctionEvent; override;
    procedure StringToScript(const Text: string; out Script: TScript; out Error: TError); overload; override;
    procedure StringToScript(const Text: string; out Script: TScript); overload; override;
    procedure StringToScriptInto(const Text: string; var Script: TScript);
    procedure StringToScript(const Text: string); reintroduce; overload;
    procedure StringToScript; reintroduce; overload;
    procedure OptimizeScript(const Source: TScript; out Target: TScript); overload; override;
    procedure OptimizeScript(var Script: TScript); overload; override;
    procedure OptimizeScript; reintroduce; overload;
    function ScriptToString(const Script: TScript; const TypeMode: TRetrieveMode = rmUser): string; override;
    function ScriptToString(const Script: TScript; const Delimiter: string;
      const TypeMode: TRetrieveMode = rmUser): string; override;
    function ScriptToString(const Script: TScript; const Delimiter: string; const ABracket: TBracket;
      const TypeMode: TRetrieveMode = rmUser): string; override;
    function ScriptToString(const TypeMode: TRetrieveMode = rmUser): string; reintroduce; overload;
    function ExecuteScript(const Index: NativeInt): PValue; overload; override;
    function ExecuteScript(const Script: TScript): PValue; reintroduce; overload;
    function ExecuteScript: PValue; reintroduce; overload;
    function ExecuteFunction(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
      const LValue: TValue; const Idle: Boolean = False): TValue; override;
    function CreateRedirect: Integer; virtual;
    function DeleteRedirect(const Index: Integer): Boolean; virtual;
    function SetRedirect(const Index: Integer; const Category, Source, Target: NativeInt): Boolean; virtual;
    function GetRedirect(const Category, Source: NativeInt; var Target: NativeInt): Boolean; virtual;
    procedure SetRedirectCategory(const Script: TScript; const RedirectCategory: NativeInt); virtual;
    property Connector: TComponent read FConnector write FConnector;
    property ParseManager: TObject read FParseManager write FParseManager;
    property Script: TScript read FScript write FScript;
    property MultiplyHandle: NativeInt read FMultiplyHandle;
    property DivideHandle: NativeInt read FDivideHandle;
    property SuccHandle: NativeInt read FSuccHandle;
    property PredHandle: NativeInt read FPredHandle;
    property NotHandle: THandle2 read FNotHandle;
    property AndHandle: THandle2 read FAndHandle;
    property OrHandle: THandle2 read FOrHandle;
    property XorHandle: THandle2 read FXorHandle;
    property ShlHandle: THandle2 read FShlHandle;
    property ShrHandle: THandle2 read FShrHandle;
    property BitwiseNotHandle: NativeInt read FBitwiseNotHandle;
    property BitwiseAndHandle: NativeInt read FBitwiseAndHandle;
    property BitwiseOrHandle: NativeInt read FBitwiseOrHandle;
    property BitwiseXorHandle: NativeInt read FBitwiseXorHandle;
    property ExitHandle: NativeInt read FExitHandle;
    property TryExceptHandle: NativeInt read FTryExceptHandle;
    property TryFinallyHandle: NativeInt read FTryFinallyHandle;
    property SameValueHandle: NativeInt read FSameValueHandle;
    property IsZeroHandle: NativeInt read FIsZeroHandle;
    property IfHandle: NativeInt read FIfHandle;
    property IfThenHandle: NativeInt read FIfThenHandle;
    property EnsureRangeHandle: NativeInt read FEnsureRangeHandle;
    property StrToIntHandle: NativeInt read FStrToIntHandle;
    property StrToIntDefHandle: NativeInt read FStrToIntDefHandle;
    property StrToFloatHandle: NativeInt read FStrToFloatHandle;
    property StrToFloatDefHandle: NativeInt read FStrToFloatDefHandle;
    property ParseHandle: NativeInt read FParseHandle;
    property DerivHandle: NativeInt read FDerivHandle;
    property TrueHandle: NativeInt read FTrueHandle;
    property FalseHandle: NativeInt read FFalseHandle;
    property EqualHandle: NativeInt read FEqualHandle;
    property NotEqualHandle: NativeInt read FNotEqualHandle;
    property AboveHandle: NativeInt read FAboveHandle;
    property BelowHandle: NativeInt read FBelowHandle;
    property AboveOrEqualHandle: NativeInt read FAboveOrEqualHandle;
    property BelowOrEqualHandle: NativeInt read FBelowOrEqualHandle;
    property EpsilonHandle: NativeInt read FEpsilonHandle;
    property GetEpsilonHandle: NativeInt read FGetEpsilonHandle;
    property SetEpsilonHandle: NativeInt read FSetEpsilonHandle;
    property SetDecimalSeparatorHandle: NativeInt read FSetDecimalSeparatorHandle;
    property ShortintHandle: NativeInt read FShortintHandle;
    property ByteHandle: NativeInt read FByteHandle;
    property SmallintHandle: NativeInt read FSmallintHandle;
    property WordHandle: NativeInt read FWordHandle;
    property IntegerHandle: NativeInt read FIntegerHandle;
    property LongWordHandle: NativeInt read FLongWordHandle;
    property NativeIntHandle: NativeInt read FNativeIntHandle;
    property NativeUIntHandle: NativeInt read FNativeUIntHandle;
    property Int64Handle: NativeInt read FInt64Handle;
    property SingleHandle: NativeInt read FSingleHandle;
    property DoubleHandle: NativeInt read FDoubleHandle;
    property ExtendedHandle: NativeInt read FExtendedHandle;
  published
    property Cache: TCache read FCache stored False;
    property Cached: Boolean read FCached write FCached default True;
    property Text: string read FText write FText;
    property ExceptionTypeSet: TExceptionTypeSet read FExceptionTypeSet write FExceptionTypeSet default DefaultExceptionTypeSet;
  end;

  TMathParser = class(TParser)
  private
    FCscHandle: NativeInt;
    FLog10Handle: NativeInt;
    FLnHandle: NativeInt;
    FMinuteOfTheHourHandle: NativeInt;
    FSameTimeHandle: NativeInt;
    FRandomFromHandle: NativeInt;
    FGetDayOfWeekHandle: NativeInt;
    FArcSinHHandle: NativeInt;
    FSecondOfTheMonthHandle: NativeInt;
    FGetTickCountHandle: NativeInt;
    FAbsHandle: NativeInt;
    FCscHHandle: NativeInt;
    FRoundHandle: NativeInt;
    FLdexpHandle: NativeInt;
    FSqrHandle: NativeInt;
    FHourOfHandle: NativeInt;
    FMilliSecondOfTheWeekHandle: NativeInt;
    FDayHandle: NativeInt;
    FRadToGradHandle: NativeInt;
    FGradToRadHandle: NativeInt;
    FCosHandle: NativeInt;
    FRadToCycleHandle: NativeInt;
    FMilliSecondOfTheMinuteHandle: NativeInt;
    FMilliSecondOfHandle: NativeInt;
    FDayOfTheYearHandle: NativeInt;
    FMinuteOfHandle: NativeInt;
    FIntHandle: NativeInt;
    FMinIntValueHandle: NativeInt;
    FCycleToRadHandle: NativeInt;
    FNormHandle: NativeInt;
    FMinuteOfTheWeekHandle: NativeInt;
    FFactorialHandle: NativeInt;
    FMonthOfTheYearHandle: NativeInt;
    FWeekOfHandle: NativeInt;
    FSecondsBetweenHandle: NativeInt;
    FSecondOfTheDayHandle: NativeInt;
    FCosHHandle: NativeInt;
    FYearsBetweenHandle: NativeInt;
    FSqrtHandle: NativeInt;
    FArcSinHandle: NativeInt;
    FArcTan2Handle: NativeInt;
    FSecHHandle: NativeInt;
    FFloorHandle: NativeInt;
    FMinuteOfTheYearHandle: NativeInt;
    FYearOfHandle: NativeInt;
    FMonthsBetweenHandle: NativeInt;
    FArcCosHHandle: NativeInt;
    FSecHandle: NativeInt;
    FCompareDateTimeHandle: NativeInt;
    FStrToDateHandle: NativeInt;
    FDayOfTheMonthHandle: NativeInt;
    FGetHourHandle: NativeInt;
    FDateOfHandle: NativeInt;
    FPopnStdDevHandle: NativeInt;
    FLgHandle: NativeInt;
    FArcCscHandle: NativeInt;
    FCycleToGradHandle: NativeInt;
    FDayOfWeekHandle: NativeInt;
    FGradToCycleHandle: NativeInt;
    FSecondOfHandle: NativeInt;
    FSecondOfTheMinuteHandle: NativeInt;
    FGetMinuteHandle: NativeInt;
    FEncodeTimeHandle: NativeInt;
    FMonthHandle: NativeInt;
    FTanHHandle: NativeInt;
    FMinHandle: NativeInt;
    FRoundToHandle: NativeInt;
    FTanHandle: NativeInt;
    FDivHandle: NativeInt;
    FMilliSecondOfTheHourHandle: NativeInt;
    FSameDateTimeHandle: NativeInt;
    FHypotHandle: NativeInt;
    FGetMilliSecondHandle: NativeInt;
    FArcCosHandle: NativeInt;
    FTotalVarianceHandle: NativeInt;
    FDaysBetweenHandle: NativeInt;
    FLnXP1Handle: NativeInt;
    FLog2Handle: NativeInt;
    FCompareTimeHandle: NativeInt;
    FEncodeDateTimeHandle: NativeInt;
    FHourOfTheWeekHandle: NativeInt;
    FStdDevHandle: NativeInt;
    FGetYearHandle: NativeInt;
    FArcSecHHandle: NativeInt;
    FMinutesBetweenHandle: NativeInt;
    FExpHandle: NativeInt;
    FModHandle: NativeInt;
    FCoTanHHandle: NativeInt;
    FSameDateHandle: NativeInt;
    FDayOfHandle: NativeInt;
    FMinuteOfTheDayHandle: NativeInt;
    FEncodeDateHandle: NativeInt;
    FMonthOfHandle: NativeInt;
    FHourHandle: NativeInt;
    FDegreeHandle: NativeInt;
    FPopnVarianceHandle: NativeInt;
    FRandomRangeHandle: NativeInt;
    FGetSecondHandle: NativeInt;
    FMaxIntValueHandle: NativeInt;
    FMinuteOfTheMonthHandle: NativeInt;
    FMilliSecondOfTheDayHandle: NativeInt;
    FArcSecHandle: NativeInt;
    FMinuteHandle: NativeInt;
    FWeekOfTheYearHandle: NativeInt;
    FPolyHandle: NativeInt;
    FFracHandle: NativeInt;
    FArcTanHHandle: NativeInt;
    FArcCscHHandle: NativeInt;
    FMilliSecondOfTheYearHandle: NativeInt;
    FMilliSecondOfTheSecondHandle: NativeInt;
    FArcTanHandle: NativeInt;
    FTimeHandle: NativeInt;
    FRadToDegHandle: NativeInt;
    FDegToRadHandle: NativeInt;
    FCoTanHandle: NativeInt;
    FMaxValueHandle: NativeInt;
    FSecondOfTheHourHandle: NativeInt;
    FDateTimeHandle: NativeInt;
    FSecondOfTheWeekHandle: NativeInt;
    FLogHandle: NativeInt;
    FMilliSecondHandle: NativeInt;
    FHourOfTheYearHandle: NativeInt;
    FArcCoTanHHandle: NativeInt;
    FIntPowerHandle: NativeInt;
    FYearHandle: NativeInt;
    FMaxHandle: NativeInt;
    FVarianceHandle: NativeInt;
    FArcCoTanHandle: NativeInt;
    FHoursBetweenHandle: NativeInt;
    FHourOfTheMonthHandle: NativeInt;
    FGetDayHandle: NativeInt;
    FStrToTimeHandle: NativeInt;
    FSecondHandle: NativeInt;
    FDateHandle: NativeInt;
    FSumOfSquaresHandle: NativeInt;
    FDegToGradHandle: NativeInt;
    FGradToDegHandle: NativeInt;
    FMeanHandle: NativeInt;
    FMinValueHandle: NativeInt;
    FTimeOfHandle: NativeInt;
    FGetMonthHandle: NativeInt;
    FStrToDateTimeHandle: NativeInt;
    FRootHandle: NativeInt;
    FSumHandle: NativeInt;
    FWeeksBetweenHandle: NativeInt;
    FCeilHandle: NativeInt;
    FRandGHandle: NativeInt;
    FRandomHandle: NativeInt;
    FMilliSecondsBetweenHandle: NativeInt;
    FCompareDateHandle: NativeInt;
    FMilliSecondOfTheMonthHandle: NativeInt;
    FDayOfTheWeekHandle: NativeInt;
    FSecondOfTheYearHandle: NativeInt;
    FWeekOfTheMonthHandle: NativeInt;
    FSumIntHandle: NativeInt;
    FSinHHandle: NativeInt;
    FPowerHandle: NativeInt;
    FSinHandle: NativeInt;
    FDegToCycleHandle: NativeInt;
    FCycleToDegHandle: NativeInt;
    FHourOfTheDayHandle: NativeInt;
    FTruncHandle: NativeInt;
    FMathMethod: TMathMethod;
  protected
    property MathMethod: TMathMethod read FMathMethod write FMathMethod;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property DivHandle: NativeInt read FDivHandle;
    property ModHandle: NativeInt read FModHandle;
    property DegreeHandle: NativeInt read FDegreeHandle;
    property FactorialHandle: NativeInt read FFactorialHandle;
    property SqrHandle: NativeInt read FSqrHandle;
    property SqrtHandle: NativeInt read FSqrtHandle;
    property IntHandle: NativeInt read FIntHandle;
    property RoundHandle: NativeInt read FRoundHandle;
    property RoundToHandle: NativeInt read FRoundToHandle;
    property TruncHandle: NativeInt read FTruncHandle;
    property AbsHandle: NativeInt read FAbsHandle;
    property FracHandle: NativeInt read FFracHandle;
    property LnHandle: NativeInt read FLnHandle;
    property LgHandle: NativeInt read FLgHandle;
    property LogHandle: NativeInt read FLogHandle;
    property ExpHandle: NativeInt read FExpHandle;
    property RandomHandle: NativeInt read FRandomHandle;
    property SinHandle: NativeInt read FSinHandle;
    property ArcSinHandle: NativeInt read FArcSinHandle;
    property SinHHandle: NativeInt read FSinHHandle;
    property ArcSinHHandle: NativeInt read FArcSinHHandle;
    property CosHandle: NativeInt read FCosHandle;
    property ArcCosHandle: NativeInt read FArcCosHandle;
    property CosHHandle: NativeInt read FCosHHandle;
    property ArcCosHHandle: NativeInt read FArcCosHHandle;
    property TanHandle: NativeInt read FTanHandle;
    property ArcTanHandle: NativeInt read FArcTanHandle;
    property TanHHandle: NativeInt read FTanHHandle;
    property ArcTanHHandle: NativeInt read FArcTanHHandle;
    property CoTanHandle: NativeInt read FCoTanHandle;
    property ArcCoTanHandle: NativeInt read FArcCoTanHandle;
    property CoTanHHandle: NativeInt read FCoTanHHandle;
    property ArcCoTanHHandle: NativeInt read FArcCoTanHHandle;
    property SecHandle: NativeInt read FSecHandle;
    property ArcSecHandle: NativeInt read FArcSecHandle;
    property SecHHandle: NativeInt read FSecHHandle;
    property ArcSecHHandle: NativeInt read FArcSecHHandle;
    property CscHandle: NativeInt read FCscHandle;
    property ArcCscHandle: NativeInt read FArcCscHandle;
    property CscHHandle: NativeInt read FCscHHandle;
    property ArcCscHHandle: NativeInt read FArcCscHHandle;
    property ArcTan2Handle: NativeInt read FArcTan2Handle;
    property HypotHandle: NativeInt read FHypotHandle;
    property RadToDegHandle: NativeInt read FRadToDegHandle;
    property RadToGradHandle: NativeInt read FRadToGradHandle;
    property RadToCycleHandle: NativeInt read FRadToCycleHandle;
    property DegToRadHandle: NativeInt read FDegToRadHandle;
    property DegToGradHandle: NativeInt read FDegToGradHandle;
    property DegToCycleHandle: NativeInt read FDegToCycleHandle;
    property GradToRadHandle: NativeInt read FGradToRadHandle;
    property GradToDegHandle: NativeInt read FGradToDegHandle;
    property GradToCycleHandle: NativeInt read FGradToCycleHandle;
    property CycleToRadHandle: NativeInt read FCycleToRadHandle;
    property CycleToDegHandle: NativeInt read FCycleToDegHandle;
    property CycleToGradHandle: NativeInt read FCycleToGradHandle;
    property LnXP1Handle: NativeInt read FLnXP1Handle;
    property Log10Handle: NativeInt read FLog10Handle;
    property Log2Handle: NativeInt read FLog2Handle;
    property IntPowerHandle: NativeInt read FIntPowerHandle;
    property PowerHandle: NativeInt read FPowerHandle;
    property RootHandle: NativeInt read FRootHandle;
    property LdexpHandle: NativeInt read FLdexpHandle;
    property CeilHandle: NativeInt read FCeilHandle;
    property FloorHandle: NativeInt read FFloorHandle;
    property PolyHandle: NativeInt read FPolyHandle;
    property MeanHandle: NativeInt read FMeanHandle;
    property SumHandle: NativeInt read FSumHandle;
    property SumIntHandle: NativeInt read FSumIntHandle;
    property SumOfSquaresHandle: NativeInt read FSumOfSquaresHandle;
    property MinValueHandle: NativeInt read FMinValueHandle;
    property MinIntValueHandle: NativeInt read FMinIntValueHandle;
    property MinHandle: NativeInt read FMinHandle;
    property MaxValueHandle: NativeInt read FMaxValueHandle;
    property MaxIntValueHandle: NativeInt read FMaxIntValueHandle;
    property MaxHandle: NativeInt read FMaxHandle;
    property StdDevHandle: NativeInt read FStdDevHandle;
    property PopnStdDevHandle: NativeInt read FPopnStdDevHandle;
    property VarianceHandle: NativeInt read FVarianceHandle;
    property PopnVarianceHandle: NativeInt read FPopnVarianceHandle;
    property TotalVarianceHandle: NativeInt read FTotalVarianceHandle;
    property NormHandle: NativeInt read FNormHandle;
    property RandGHandle: NativeInt read FRandGHandle;
    property RandomRangeHandle: NativeInt read FRandomRangeHandle;
    property RandomFromHandle: NativeInt read FRandomFromHandle;
    property YearHandle: NativeInt read FYearHandle;
    property MonthHandle: NativeInt read FMonthHandle;
    property DayHandle: NativeInt read FDayHandle;
    property DayOfWeekHandle: NativeInt read FDayOfWeekHandle;
    property HourHandle: NativeInt read FHourHandle;
    property MinuteHandle: NativeInt read FMinuteHandle;
    property SecondHandle: NativeInt read FSecondHandle;
    property MilliSecondHandle: NativeInt read FMilliSecondHandle;
    property DateTimeHandle: NativeInt read FDateTimeHandle;
    property DateHandle: NativeInt read FDateHandle;
    property TimeHandle: NativeInt read FTimeHandle;
    property GetYearHandle: NativeInt read FGetYearHandle;
    property GetMonthHandle: NativeInt read FGetMonthHandle;
    property GetDayHandle: NativeInt read FGetDayHandle;
    property GetDayOfWeekHandle: NativeInt read FGetDayOfWeekHandle;
    property GetHourHandle: NativeInt read FGetHourHandle;
    property GetMinuteHandle: NativeInt read FGetMinuteHandle;
    property GetSecondHandle: NativeInt read FGetSecondHandle;
    property GetMilliSecondHandle: NativeInt read FGetMilliSecondHandle;
    property EncodeDateTimeHandle: NativeInt read FEncodeDateTimeHandle;
    property EncodeDateHandle: NativeInt read FEncodeDateHandle;
    property EncodeTimeHandle: NativeInt read FEncodeTimeHandle;
    property StrToDateTimeHandle: NativeInt read FStrToDateTimeHandle;
    property StrToDateHandle: NativeInt read FStrToDateHandle;
    property StrToTimeHandle: NativeInt read FStrToTimeHandle;
    property DateOfHandle: NativeInt read FDateOfHandle;
    property TimeOfHandle: NativeInt read FTimeOfHandle;
    property YearOfHandle: NativeInt read FYearOfHandle;
    property MonthOfHandle: NativeInt read FMonthOfHandle;
    property WeekOfHandle: NativeInt read FWeekOfHandle;
    property DayOfHandle: NativeInt read FDayOfHandle;
    property HourOfHandle: NativeInt read FHourOfHandle;
    property MinuteOfHandle: NativeInt read FMinuteOfHandle;
    property SecondOfHandle: NativeInt read FSecondOfHandle;
    property MilliSecondOfHandle: NativeInt read FMilliSecondOfHandle;
    property YearsBetweenHandle: NativeInt read FYearsBetweenHandle;
    property MonthsBetweenHandle: NativeInt read FMonthsBetweenHandle;
    property WeeksBetweenHandle: NativeInt read FWeeksBetweenHandle;
    property DaysBetweenHandle: NativeInt read FDaysBetweenHandle;
    property HoursBetweenHandle: NativeInt read FHoursBetweenHandle;
    property MinutesBetweenHandle: NativeInt read FMinutesBetweenHandle;
    property SecondsBetweenHandle: NativeInt read FSecondsBetweenHandle;
    property MilliSecondsBetweenHandle: NativeInt read FMilliSecondsBetweenHandle;
    property MonthOfTheYearHandle: NativeInt read FMonthOfTheYearHandle;
    property WeekOfTheYearHandle: NativeInt read FWeekOfTheYearHandle;
    property DayOfTheYearHandle: NativeInt read FDayOfTheYearHandle;
    property HourOfTheYearHandle: NativeInt read FHourOfTheYearHandle;
    property MinuteOfTheYearHandle: NativeInt read FMinuteOfTheYearHandle;
    property SecondOfTheYearHandle: NativeInt read FSecondOfTheYearHandle;
    property MilliSecondOfTheYearHandle: NativeInt read FMilliSecondOfTheYearHandle;
    property WeekOfTheMonthHandle: NativeInt read FWeekOfTheMonthHandle;
    property DayOfTheMonthHandle: NativeInt read FDayOfTheMonthHandle;
    property HourOfTheMonthHandle: NativeInt read FHourOfTheMonthHandle;
    property MinuteOfTheMonthHandle: NativeInt read FMinuteOfTheMonthHandle;
    property SecondOfTheMonthHandle: NativeInt read FSecondOfTheMonthHandle;
    property MilliSecondOfTheMonthHandle: NativeInt read FMilliSecondOfTheMonthHandle;
    property DayOfTheWeekHandle: NativeInt read FDayOfTheWeekHandle;
    property HourOfTheWeekHandle: NativeInt read FHourOfTheWeekHandle;
    property MinuteOfTheWeekHandle: NativeInt read FMinuteOfTheWeekHandle;
    property SecondOfTheWeekHandle: NativeInt read FSecondOfTheWeekHandle;
    property MilliSecondOfTheWeekHandle: NativeInt read FMilliSecondOfTheWeekHandle;
    property HourOfTheDayHandle: NativeInt read FHourOfTheDayHandle;
    property MinuteOfTheDayHandle: NativeInt read FMinuteOfTheDayHandle;
    property SecondOfTheDayHandle: NativeInt read FSecondOfTheDayHandle;
    property MilliSecondOfTheDayHandle: NativeInt read FMilliSecondOfTheDayHandle;
    property MinuteOfTheHourHandle: NativeInt read FMinuteOfTheHourHandle;
    property SecondOfTheHourHandle: NativeInt read FSecondOfTheHourHandle;
    property MilliSecondOfTheHourHandle: NativeInt read FMilliSecondOfTheHourHandle;
    property SecondOfTheMinuteHandle: NativeInt read FSecondOfTheMinuteHandle;
    property MilliSecondOfTheMinuteHandle: NativeInt read FMilliSecondOfTheMinuteHandle;
    property MilliSecondOfTheSecondHandle: NativeInt read FMilliSecondOfTheSecondHandle;
    property CompareDateTimeHandle: NativeInt read FCompareDateTimeHandle;
    property SameDateTimeHandle: NativeInt read FSameDateTimeHandle;
    property CompareDateHandle: NativeInt read FCompareDateHandle;
    property SameDateHandle: NativeInt read FSameDateHandle;
    property CompareTimeHandle: NativeInt read FCompareTimeHandle;
    property SameTimeHandle: NativeInt read FSameTimeHandle;
    property GetTickCountHandle: NativeInt read FGetTickCountHandle;
  end;

const
  InternalRawscriptCacheName = 'RawscriptCache';
  InternalScriptCacheName = 'ScriptCache';
  InternalSubscriptCacheName = 'SubscriptCache';
  InternalParameterCacheName = 'ParameterCache';
  InternalSubparameterCacheName = 'SubparameterCache';
  InternalCacheName = 'Cache';
  InternalFlagCacheName = 'FlagCache';
  InternalPOperatorFlagCacheName = 'POperatorFlagCache';
  InternalItemCacheName = 'ItemCache';
  InternalPOperatorItemCacheName = 'POperatorItemCache';
  InternalConnectorName = 'Connector';
  InternalParseManagerName = 'ParseManager';

function GetRedirectCategory: Int64;

function Put(var NotifyArray: TNotifyArray; const Notify: TNotify): NativeInt;

function MakePAData(const Idle: Boolean; const PA: PParameterArray; const Index: PNativeInt): TPAData;
function MakeDSData(const Delimiter: string; const Parameter: Boolean; const ParameterBracket: TBracket;
  const TypeMode: TRetrieveMode): TDSData;
function MakeBracketData(const SA: PScriptArray; const Parameter: Boolean;
  const Idle: PFunction): TBracketData;
function MakeNotify(const NotifyType: TNotifyType; const Component: TComponent): TNotify;

procedure Register;

var
  PreviousDecimalSeparator: Char = Dot;

procedure ApplyDecimalSeparator;
procedure RestoreDecimalSeparator;

implementation

{$IFDEF FPC}
{$R crosspascal_parser_icons.res}
{$ENDIF}

uses
  {$IFDEF FPC}
  DateUtils, Connector, FlagCache, ItemCache, NumberConsts, NumberUtils, ParseCommon,
  ParseExecution, ParseManager, ParseMessages, ParseUtils, ParseValidator, ScriptFormat,
  TextUtils, ThreadUtils, ValueConsts, ValueUtils, Variants;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.DateUtils, System.UITypes, System.Variants, Connector, FlagCache, ItemCache,
  NumberConsts, NumberUtils, ParseCommon, ParseExecution, ParseManager, ParseMessages,
  ParseUtils, ParseValidator, ScriptFormat, TextUtils, ThreadUtils, ValueConsts,
  ValueUtils;
  {$ELSE}
  DateUtils, Connector, FlagCache, ItemCache, NumberConsts, NumberUtils, ParseCommon,
  ParseExecution, ParseManager, ParseMessages, ParseUtils, ParseValidator, ScriptFormat,
  TextUtils, ThreadUtils, ValueConsts, ValueUtils, Variants;
  {$ENDIF}
  {$ENDIF}

procedure Register;
begin
  RegisterComponents('CrossPascal', [TParser, TMathParser]);
end;

var
  RedirectCategory: Int64 = 0;
  RedirectCategorySync: TRTLCriticalSection;

function GetRedirectCategory: Int64;
begin
  Enter(RedirectCategorySync);
  try
    Inc(RedirectCategory);
    Result := RedirectCategory;
  finally
    Leave(RedirectCategorySync);
  end;
end;

function Put(var NotifyArray: TNotifyArray; const Notify: TNotify): NativeInt;
var
  I: Integer;
begin
  for I := Low(NotifyArray) to High(NotifyArray) do
    if NotifyArray[I].NotifyType = Notify.NotifyType then
    begin
      Result := I;
      NotifyArray[Result] := Notify;
      Exit;
    end;
  Result := Length(NotifyArray);
  SetLength(NotifyArray, Result + 1);
  NotifyArray[Result] := Notify;
end;

function MakePAData(const Idle: Boolean; const PA: PParameterArray; const Index: PNativeInt): TPAData;
begin
  FillChar(Result, SizeOf(TPAData), 0);
  Result.Idle := Idle;
  Result.PA := PA;
  Result.Index := Index;
end;

function MakeDSData(const Delimiter: string; const Parameter: Boolean; const ParameterBracket: TBracket;
  const TypeMode: TRetrieveMode): TDSData;
begin
  FillChar(Result, SizeOf(TDSData), 0);
  Result.Delimiter := Delimiter;
  Result.Parameter := Parameter;
  Result.ParameterBracket := ParameterBracket;
  Result.TypeMode := TypeMode;
end;

function MakeBracketData(const SA: PScriptArray; const Parameter: Boolean;
  const Idle: PFunction): TBracketData;
begin
  FillChar(Result, SizeOf(TBracketData), 0);
  Result.SA := SA;
  Result.Parameter := Parameter;
  Result.Idle := Idle;
end;

function MakeNotify(const NotifyType: TNotifyType; const Component: TComponent): TNotify;
begin
  FillChar(Result, SizeOf(TNotify), 0);
  Result.NotifyType := NotifyType;
  Result.Component := Component;
end;

procedure TCache.Clear;
var
  I: TCacheType;
begin
  for I := Low(TCacheType) to High(TCacheType) do
    if Available(FCacheArray[I]) then FCacheArray[I].Clear;
end;

constructor TCache.Create(const AParser: TCustomParser; const AConnector: TComponent);
begin
  inherited Create(AParser);
  FParser := AParser;
  FRawscript := TParseCache.Create(AParser);
  with FRawscript do
  begin
    Cache1.Connector := AConnector;
    Cache2.Connector := AConnector;
    Name := InternalRawscriptCacheName;
    ScriptType := stScript;
    SetSubComponent(True);
  end;
  FScript := TParseCache.Create(AParser);
  with FScript do
  begin
    Cache1.Connector := AConnector;
    Cache2.Connector := AConnector;
    Name := InternalScriptCacheName;
    ScriptType := stScript;
    SetSubComponent(True);
  end;
  FSubscript := TParseCache.Create(AParser);
  with FSubscript do
  begin
    Cache1.Connector := AConnector;
    Cache2.Connector := AConnector;
    Name := InternalSubscriptCacheName;
    ScriptType := stScriptItem;
    Cache2.Enabled := False;
    SetSubComponent(True);
  end;
  FParameter := TParseCache.Create(AParser);
  with FParameter do
  begin
    Cache1.Connector := AConnector;
    Cache2.Connector := AConnector;
    Name := InternalParameterCacheName;
    ScriptType := stScript;
    SetSubComponent(True);
  end;
  FSubparameter := TParseCache.Create(AParser);
  with FSubparameter do
  begin
    Cache1.Connector := AConnector;
    Cache2.Connector := AConnector;
    Name := InternalSubparameterCacheName;
    ScriptType := stScriptItem;
    Cache2.Enabled := False;
    SetSubComponent(True);
  end;
  FCacheArray[ctRawscript] := FRawscript;
  FCacheArray[ctScript] := FScript;
  FCacheArray[ctSubscript] := FSubscript;
  FCacheArray[ctParameter] := FParameter;
  FCacheArray[ctSubparameter] := FSubparameter;
  {$IFDEF DELPHI_7}
  FNameValueSeparator := CacheSeparator;
  WriteNameValueSeparator;
  {$ENDIF}
end;

function TCache.GetCache(CacheType: TCacheType): TParseCache;
begin
  Result := FCacheArray[CacheType];
end;

procedure TCache.SetSubcache(const Value: TParseCache);
begin
end;

procedure TCache.Prepare;
var
  I: TCacheType;
begin
  if Assigned(FParser) then FParser.BeginUpdate;
  try
    for I := Low(TCacheType) to High(TCacheType) do
    begin
      FCacheArray[I].Cache1.Compile;
      FCacheArray[I].Cache2.Compile;
    end;
  finally
    if Assigned(FParser) then FParser.EndUpdate;
  end;
end;

procedure TCache.SetCacheType(const Value: TListType);
var
  I: TCacheType;
begin
  for I := Low(TCacheType) to High(TCacheType) do
  begin
    FCacheArray[I].Cache1.CacheType := Value;
    FCacheArray[I].Cache2.CacheType := Value;
  end;
end;

{$IFDEF DELPHI_7}
procedure TCache.SetNameValueSeparator(const Value: Char);
begin
  if FNameValueSeparator <> Value then
  begin
    FNameValueSeparator := Value;
    WriteNameValueSeparator;
  end;
end;

procedure TCache.WriteNameValueSeparator;
var
  I: TCacheType;
begin
  for I := Low(TCacheType) to High(TCacheType) do
  begin
    FCacheArray[I].Cache1.NameValueSeparator := FNameValueSeparator;
    FCacheArray[I].Cache2.NameValueSeparator := FNameValueSeparator;
  end;
end;
{$ENDIF}

function TCustomParser.AddConstant(const AName: string; const Value: TValue): Boolean;
var
  Item: PValue;
begin
  Result := not Assigned(FindFunction(AName));
  if Result then
  begin
    New(Item);
    try
      Item^ := Value;
      Result := AddVariable(AName, Item^, True);
      if Result then
        FConstantList.List.AddObject(AName, Pointer(Item))
      else
        Dispose(Item);
    except
      Dispose(Item);
      raise;
    end;
  end;
end;

{$IFDEF DELPHI_2006}
function TCustomParser.AddConstant(const AName: string; const Value: Byte): Boolean;
begin
  Result := AddConstant(AName, MakeByte(Value));
end;

function TCustomParser.AddConstant(const AName: string; const Value: Shortint): Boolean;
begin
  Result := AddConstant(AName, MakeShortint(Value));
end;

function TCustomParser.AddConstant(const AName: string; const Value: Word): Boolean;
begin
  Result := AddConstant(AName, MakeWord(Value));
end;

function TCustomParser.AddConstant(const AName: string; const Value: Smallint): Boolean;
begin
  Result := AddConstant(AName, MakeSmallint(Value));
end;

function TCustomParser.AddConstant(const AName: string; const Value: LongWord): Boolean;
begin
  Result := AddConstant(AName, MakeLongWord(Value));
end;

function TCustomParser.AddConstant(const AName: string; const Value: NativeInt): Boolean;
begin
  Result := AddConstant(AName, MakeNativeInt(Value));
end;
{$ENDIF}

function TCustomParser.AddConstant(const AName: string; const Value: Int64): Boolean;
begin
  Result := AddConstant(AName, MakeInt64(Value));
end;

{$IFDEF DELPHI_2006}
function TCustomParser.AddConstant(const AName: string; const Value: Single): Boolean;
begin
  Result := AddConstant(AName, MakeSingle(Value));
end;
{$ENDIF}

function TCustomParser.AddConstant(const AName: string; const Value: Double): Boolean;
begin
  Result := AddConstant(AName, MakeDouble(Value));
end;

{$IFDEF DELPHI_2006}
function TCustomParser.AddConstant(const AName: string; const Value: Extended): Boolean;
begin
  Result := AddConstant(AName, MakeExtended(Value));
end;
{$ENDIF}

function TCustomParser.AddConstant(const AName: string; const Value: Boolean): Boolean;
begin
  Result := AddConstant(AName, MakeByte(Byte(Value)));
end;

function TCustomParser.AddFunction(const AFunction: TFunction): Boolean;
begin
  Result := InternalAddFunction(AFunction);
end;

function TCustomParser.AddFunction(const AName: string; var Handle: NativeInt; const Kind: TFunctionKind;
  const Method: TFunctionMethod; const Optimizable: Boolean; const ReturnType: TValueType;
  const Priority: TFunctionPriority; const Coverage: TPriorityCoverage): Boolean;
begin
  Result := AddFunction(MakeFunction(AName, Handle, ReturnType, Kind, Method, Optimizable,
    MakePriority(Priority, Coverage)));
end;

function TCustomParser.AddType(const AType: TType): Boolean;
var
  Error: TError;
begin
  Result := (AType.Name <> '') and not Assigned(FindType(AType.Name));
  if Result then
  begin
    Notify(ntBTA, Self);
    Error := Validator.Check(AType.Name, rtName);
    if Error.ErrorType <> etOK then raise ParseErrors.Error(Error.ErrorText);
    AType.Handle^ := ParseUtils.AddType(FTData^, AType);
    Notify(ntATA, Self);
  end
  else
    AType.Handle^ := -1;
end;

function TCustomParser.AddType(const AName: string; var Handle: NativeInt;
  const ValueType: TValueType): Boolean;
begin
  Result := AddType(MakeType(AName, Handle, ValueType));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: TValue; const Optimizable: Boolean;
  const ReturnType: TValueType): Boolean;
begin
  Result := InternalAddVariable(AName, Variable, Optimizable, ReturnType);
end;

function TCustomParser.AddVariable(const AName: string; const Variable: TValueRef; const Optimizable: Boolean;
  const ReturnType: TValueType): Boolean;
begin
  Result := InternalAddVariable(AName, Variable, Optimizable, ReturnType);
end;

function TCustomParser.AddVariable(const AName: string; var Variable: TValue): Boolean;
begin
  Result := AddVariable(AName, Variable, False);
end;

function TCustomParser.AddVariable(const AName: string; const Variable: TValueRef): Boolean;
begin
  Result := AddVariable(AName, Variable, False);
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Byte): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Shortint): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Word): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Smallint): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: LongWord): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Integer): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: NativeInt): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Int64): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Single): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function TCustomParser.AddVariable(const AName: string; var Variable: Double): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;
{$ENDIF}

function TCustomParser.AddVariable(const AName: string; var Variable: Extended): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(Variable));
end;

function TCustomParser.AddVariable(const AName: string; var Variable: Boolean): Boolean;
begin
  Result := AddVariable(AName, MakeValueRef(PByte(@Variable)^));
end;

function TCustomParser.AsBoolean(const Text: string): Boolean;
begin
  Result := Boolean(AsByte(Text));
end;

function TCustomParser.AsByte(const Text: string): Byte;
begin
  Result := GetByte(AsValue(Text));
end;

function TCustomParser.AsDouble(const Text: string): Double;
begin
  Result := GetDouble(AsValue(Text));
end;

function TCustomParser.AsExtended(const Text: string): Extended;
begin
  Result := GetExtended(AsValue(Text));
end;

function TCustomParser.AsInt64(const Text: string): Int64;
begin
  Result := GetInt64(AsValue(Text));
end;

function TCustomParser.AsInteger(const Text: string): NativeInt;
begin
  Result := GetInteger(AsValue(Text));
end;

function TCustomParser.AsLongWord(const Text: string): LongWord;
begin
  Result := GetLongWord(AsValue(Text));
end;

function TCustomParser.AsPointer(const Text: string): Pointer;
begin
  Result := Pointer(AsInt64(Text));
end;

function TCustomParser.AsShortint(const Text: string): Shortint;
begin
  Result := GetShortint(AsValue(Text));
end;

function TCustomParser.AsSingle(const Text: string): Single;
begin
  Result := GetSingle(AsValue(Text));
end;

function TCustomParser.AsSmallint(const Text: string): Smallint;
begin
  Result := GetSmallint(AsValue(Text));
end;

function TCustomParser.AsString(const Text: string): string;
begin
  Result := ValueToText(AsValue(Text));
end;

function TCustomParser.AsValue(const Text: string): TValue;
var
  Script: TScript;
begin
  StringToScript(Text, Script);
  try
    Result := ExecuteScript(NativeInt(Script))^;
  finally
    Script := nil;
  end;
end;

function TCustomParser.AsWord(const Text: string): Word;
begin
  Result := GetWord(AsValue(Text));
end;

procedure TCustomParser.BeginUpdate;
begin
  InterlockedIncrement(FUpdateCount);
end;

function TCustomParser.Check(const Text: string): TError;
var
  FFArray: TFunctionFlagArray;
  I, J: Integer;
  AFunction: PFunction;
begin
  GetFFArray(Text, ltChar, FFData, nil, FFArray);
  try
    for I := Low(FFArray) to High(FFArray) do
      if GetFunction(FFArray[I].Handle, AFunction) then
        for J := FFArray[I].Index + Integer(StrLen(AFunction.Name)) to Length(Text) do
          if not CharInSet(Text[J], Blanks) then
            if Text[J] = FBracket[btL] then
              if not AFunction.Method.Parameter.R and (AFunction.Method.Parameter.Count = 0) then
              begin
                Result := MakeError(etRTextExcessError, EText(RTextExcessError, [AFunction.Name]));
                Exit;
              end
              else
                Break
            else
              if AFunction.Method.Parameter.Count > 0 then
              begin
                Result := MakeError(etAParamExpectError, EText(AParamExpectError, [AFunction.Name]));
                Exit;
              end
              else
                Break;
  finally
    FFArray := nil;
  end;
  FillChar(Result, SizeOf(TError), 0);
end;

{$WARNINGS OFF}
function TCustomParser.Check(const ItemArray: TTextItemArray1; const Index: NativeInt; const Data: TItemData;
  const SA: TScriptArray; const Parameter: Boolean): TError;
var
  AFlag, BFlag: Boolean;
  AType: PType;
  AFunction: PFunction;
  Script: TScript;
begin
  if GetType(ItemArray[Index].THandle, AType) then
    case Data.Code of
      icNumber:
        begin
          if AType.Handle^ = FStringHandle then
          begin
            Result := MakeError(etStringTypeError, EText(StringTypeError, [ValueToText(Data.Number^)]));
            Exit;
          end;
          if Index > Low(ItemArray) then
          begin
            Result := MakeError(etNumberTypeError,
              EText(NumberTypeError, [AType.Name, ValueToText(Data.Number^), RestoreText(Self, ItemArray, SA, Parameter)]));
            Exit;
          end;
        end;
      icFunction:
        begin
          AFlag := AType.Handle^ = FStringHandle;
          BFlag := Index > Low(ItemArray);
          if (AFlag or BFlag) and GetFunction(Data.Handle^, AFunction) then
          begin
            if AFlag then
            begin
              Result := MakeError(etStringTypeError, EText(StringTypeError, [AFunction.Name]));
              Exit;
            end;
            if BFlag then
            begin
              Result := MakeError(etFunctionTypeError,
                EText(FunctionTypeError, [AType.Name, AFunction.Name, RestoreText(Self, ItemArray, SA, Parameter)]));
              Exit;
            end;
          end;
        end;
      icScript:
        begin
          AFlag := AType.Handle^ = FStringHandle;
          BFlag := Index > Low(ItemArray);
          if (AFlag or BFlag) and GetFunction(Data.Handle^, AFunction) then
          begin
            if AFlag then
            begin
              Result := MakeError(etStringTypeError,
                EText(StringTypeError, [ScriptToString(Data.Script^, rmUser)]));
              Exit;
            end;
            if BFlag then
            begin
              Result := MakeError(
                etScriptTypeError,
                EText(
                  ScriptTypeError,
                  [
                    AType.Name,
                    Embrace(
                      ScriptToString(
                        Data.Script^,
                        rmUser
                      ),
                      FBracket
                    ),
                    RestoreText(
                      Self,
                      ItemArray,
                      SA,
                      Parameter
                    )
                  ]
                )
              );
              Exit;
            end;
          end;
        end;
      icParameter:
        if AType.Handle^ = FStringHandle then
        begin
          Script := ParameterToScript(Data.Script^);
          try
            Result := MakeError(etStringTypeError, EText(StringTypeError, [ScriptToString(Script, rmUser)]));
            Exit;
          finally
            Script := nil;
          end;
        end;
    end;
  FillChar(Result, SizeOf(TError), 0);
end;

function TCustomParser.Check(var Syntax: TSyntax; const Kind: TOperatorKind; const Text: string;
  const SA: TScriptArray; const Handle: NativeInt): TError;
var
  AFunction, PriorFunction: PFunction;
  Parameter, PriorParameter: PFunctionParameter;
begin
  if GetFunction(Handle, AFunction) then
    Parameter := @AFunction.Method.Parameter
  else
    Parameter := nil;
  if GetFunction(Syntax.PriorHandle, PriorFunction) then
    PriorParameter := @PriorFunction.Method.Parameter
  else
    PriorParameter := nil;
  try
    case Kind of
      okEof:
        case Syntax.PriorKind of
          okFunction:
            if Assigned(PriorFunction) and Assigned(PriorParameter) then
            begin
              if PriorParameter.Count > 0 then
              begin
                Result := MakeError(etAParamExpectError,
                  EText(RestoreText(Self, Text, SA), AParamExpectError, [PriorFunction.Name]));
                Exit;
              end;
              if PriorParameter.R then
              begin
                Result := MakeError(etRTextExpectError,
                  EText(RestoreText(Self, Text, SA), RTextExpectError, [PriorFunction.Name]));
                Exit;
              end;
            end;
        end;
      okNumber, okScript:
        case Syntax.PriorKind of
          okNumber, okScript, okParameter:
            begin
              Result := MakeError(etFunctionExpectError,
                EText(FunctionExpectError, [RestoreText(Self, Text, SA)]));
              Exit;
            end;
          okFunction:
            if Assigned(PriorFunction) and Assigned(PriorParameter) and ((PriorParameter.Count > 0) or
              not PriorParameter.R) then
              begin
                Result := MakeError(etRTextExcessError,
                  EText(RestoreText(Self, Text, SA), RTextExcessError, [PriorFunction.Name]));
                Exit;
              end;
        end;
      okFunction:
        begin
          case Syntax.PriorKind of
            okBof:
              if Assigned(AFunction) and Assigned(Parameter) and Parameter.L then
              begin
                Result := MakeError(etLTextExpectError,
                  EText(LTextExpectError, [RestoreText(Self, Text, SA)]));
                Exit;
              end;
            okNumber, okScript, okParameter:
              if Assigned(AFunction) and Assigned(Parameter) and ((Parameter.Count > 0) or
                not Parameter.L) then
                begin
                  Result := MakeError(etLTextExcessError,
                    EText(RestoreText(Self, Text, SA), LTextExcessError, [AFunction.Name]));
                  Exit;
                end;
            okFunction:
              if Assigned(AFunction) and Assigned(PriorFunction) and Assigned(Parameter) and
                Assigned(PriorParameter) then
                begin
                  if PriorParameter.R and Parameter.L then
                  begin
                    Result := MakeError(etAMutualExcessError,
                      EText(RestoreText(Self, Text, SA), AMutualExcessError, [PriorFunction.Name, AFunction.Name]));
                    Exit;
                  end;
                  if not PriorParameter.R and not Parameter.L then
                  begin
                    Result := MakeError(etBMutualExcessError,
                      EText(RestoreText(Self, Text, SA), BMutualExcessError, [PriorFunction.Name, AFunction.Name]));
                    Exit;
                  end;
                end;
          end;
          Syntax.PriorHandle := Handle;
        end;
      okParameter:
        case Syntax.PriorKind of
          okBof, okNumber, okScript, okParameter:
            begin
              Result := MakeError(etFunctionExpectError,
                EText(FunctionExpectError, [RestoreText(Self, Text, SA)]));
              Exit;
            end;
          okFunction:
            if Assigned(PriorFunction) and (PriorParameter.Count = 0) then
            begin
              Result := MakeError(etAParamExcessError,
                EText(RestoreText(Self, Text, SA), AParamExcessError, [PriorFunction.Name]));
              Exit;
            end;
        end;
    end;
  finally
    Syntax.PriorKind := Kind;
  end;
  FillChar(Result, SizeOf(TError), 0);
end;

function TCustomParser.CheckFHandle(const Handle: NativeInt): Boolean;
begin
  Result := ParseUtils.CheckFHandle(FFData, Handle);
end;

function TCustomParser.CheckTHandle(const Handle: NativeInt): Boolean;
begin
  Result := ParseUtils.CheckTHandle(FTData, Handle);
end;
{$WARNINGS ON}

function TCustomParser.Connect(const ABeforeFunction: TFunctionEvent;
  const AAddressee: TCustomAddressee): TFunctionEvent;
begin
  Result := FBeforeFunction;
  FBeforeFunction := ABeforeFunction;
  FAddressee := AAddressee;
end;

constructor TCustomParser.Create(AOwner: TComponent);

  function MakeData(const Value: array of string): PFunctionData;
  var
    AFunction: TFunction;
    I: Integer;
  begin
    New(Result);
    ZeroMemory(Result, SizeOf(TFunctionData));
    FillChar(AFunction, SizeOf(TFunction), 0);
    for I := Low(Value) to High(Value) do
    begin
      StrLCopy(AFunction.Name, PChar(Value[I]), High(TString));
      ParseUtils.AddFunction(Result^, AFunction);
    end;
    MemoryUtils.Add(Result.FOrder, 0, Length(Result.FA));
  end;

var
  I: TTextOperator;
begin
  inherited;
  FMethod := TMethod.Create(Self);
  {$IFNDEF FPC}
  FWindowHandle := AllocateHWnd(WindowMethod);
  {$ENDIF}
  New(FFData);
  ZeroMemory(FFData, SizeOf(TFunctionData));
  New(FTData);
  ZeroMemory(FTData, SizeOf(TTypeData));
  FPData := MakeData(POperatorArray);
  FExceptionMask := [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision];
  FConstantList := TFlexibleList.Create(Self);
  BeginUpdate;
  try
    InternalAddFunction(InternalFunctionName, FInternalHandle, fkHandle,
      MakeFunctionMethod(False, False, 0), False);
    SetLength(FOArray, Length(TOperatorArray));
    for I := Low(TOperatorArray) to High(TOperatorArray) do
      InternalAddFunction(TOperatorArray[I], FOArray[Ord(I)], fkHandle,
        MakeFunctionMethod(True, True, 0), False);
    FNegativeHandle := @FOArray[NativeInt(toNegative)];
    FPositiveHandle := @FOArray[NativeInt(toPositive)];
    InternalAddFunction(VoidFunctionName, FVoidHandle, fkMethod,
      MakeFunctionMethod(FMethod.VoidMethod), True);
    InternalAddFunction(NewFunctionName, FNewHandle, fkMethod,
      MakeFunctionMethod(FMethod.NewMethod, NewParameterMinCount, pkReference), False);
    InternalAddFunction(DeleteFunctionName, FDeleteHandle, fkMethod,
      MakeFunctionMethod(FMethod.DeleteMethod, DeleteParameterCount, pkReference), False);
    InternalAddFunction(FindFunctionName, FFindHandle, fkMethod,
      MakeFunctionMethod(FMethod.FindMethod, FindParameterCount, pkReference), False);
    InternalAddFunction(GetFunctionName, FGetHandle, fkMethod,
      MakeFunctionMethod(FMethod.GetMethod, GetParameterCount, pkReference), False);
    InternalAddFunction(SetFunctionName, FSetHandle, fkMethod,
      MakeFunctionMethod(FMethod.SetMethod, SetParameterCount, pkReference), False);
    InternalAddFunction(ScriptFunctionName, FScriptHandle, fkMethod,
      MakeFunctionMethod(FMethod.ScriptMethod, ScriptParameterMinCount, pkReference), False);
    InternalAddFunction(ExecuteFunctionName, FExecuteHandle, fkMethod,
      MakeFunctionMethod(FMethod.ExecuteMethod, ExecuteParameterCount, pkReference), False);
    InternalAddFunction(ForFunctionName, FForHandle, fkMethod,
      MakeFunctionMethod(FMethod.ForMethod, ForParameterCount, pkReference), False);
    InternalAddFunction(RepeatFunctionName, FRepeatHandle, fkMethod,
      MakeFunctionMethod(FMethod.RepeatMethod, RepeatParameterCount, pkReference), False);
    InternalAddFunction(WhileFunctionName, FWhileHandle, fkMethod,
      MakeFunctionMethod(FMethod.WhileMethod, WhileParameterCount, pkReference), False);
    AddType(StringTypeName, FStringHandle, vtUnknown);
  finally
    EndUpdate;
  end;
  FBracket := BracketArray[bkParenthesis];
  FPrioritize := True;
  FExecuteKindSet := [ekSubsequent];
  FBooleanMode := bmShortCircuit;
  FDefaultValueType := vtInteger;
  AssignInteger(FNegativeValue, 0);
  AssignInteger(FPositiveValue, -1);
  FParameterBracket := BracketArray[bkBracket];
end;

function TCustomParser.DeleteConstant(const AName: string): Boolean;
var
  I: Integer;
  Value: PValue;
begin
  Result := Find(FConstantList.List, AName, False, I);
  if Result then
  begin
    Value := PValue(FConstantList.List.Objects[I]);
    DeleteVariable(Value^);
    FConstantList.List.Delete(I);
    Dispose(Value);
  end;
end;

function TCustomParser.DefaultFunction(const Header: PScriptHeader; const AFunction: PFunction;
  out Value: TValue; const LValue, RValue: TValue; const PA: TParameterArray): Boolean;
begin
  Result := False;
end;

function TCustomParser.DeleteFunction(const Handle: NativeInt): Boolean;
var
  I: NativeInt;
begin
  Result := CheckFHandle(Handle);
  if Result then
  begin
    try
      Notify(ntBFD, Self);
      I := Length(FFData.FA);
      Result := MemoryUtils.Delete(FFData.FA, Handle * SizeOf(TFunction), SizeOf(TFunction),
        I * SizeOf(TFunction));
      if Result then
      begin
        SetLength(FFData.FA, I - 1);
        FFData.Prepared := False;
      end;
      Notify(ntAFD, Self);
      Notify(ntCompile, Self);
    finally
    end;
  end;
end;

function TCustomParser.DeleteFunction(const HandleArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}): NativeInt;
var
  Handle: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};
  I: Integer;
begin
  Result := 0;
  Handle := Copy(HandleArray);
  try
    Sort(Handle);
    for I := High(Handle) downto Low(Handle) do if DeleteFunction(Handle[I]) then Inc(Result);
  finally
    Handle := nil;
  end;
end;

function TCustomParser.DeleteType(const HandleArray: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF}): NativeInt;
var
  Handle: {$IFDEF DELPHI_10.2}TArray<NativeInt>{$ELSE}TNativeIntDynArray{$ENDIF};
  I: Integer;
begin
  Result := 0;
  Handle := Copy(HandleArray);
  try
    Sort(Handle);
    for I := High(Handle) downto Low(Handle) do if DeleteType(Handle[I]) then Inc(Result);
  finally
    Handle := nil;
  end;
end;

function TCustomParser.DeleteType(const Handle: NativeInt): Boolean;
var
  I: NativeInt;
begin
  Result := CheckTHandle(Handle);
  if Result then
  begin
    Notify(ntBTD, Self);
    I := Length(FTData.TA);
    Result := MemoryUtils.Delete(FTData.TA, Handle * SizeOf(TType), SizeOf(TType), I * SizeOf(TType));
    if Result then
    begin
      SetLength(FTData.TA, I - 1);
      FTData.Prepared := False;
    end;
    Notify(ntATD, Self);
    Notify(ntCompile, Self);
  end;
end;

function TCustomParser.DeleteVariable(var Variable: TValue): Boolean;
var
  I: Integer;
  AVariable: PFunctionVariable;
begin
  for I := Low(FFData.FA) to High(FFData.FA) do
  begin
    AVariable := @FFData.FA[I].Method.Variable;
    if (AVariable.VariableType = vtValue) and (AVariable.Variable = @Variable) then
    begin
      Result := DeleteFunction(I);
      Exit;
    end;
  end;
  Result := False;
end;

destructor TCustomParser.Destroy;
var
  I: Integer;
  Item: PValue;
begin
  Notify(ntDisconnect, Self);
  with FFData^ do
  begin
    FA := nil;
    FOrder := nil;
    NameList.Free;
  end;
  with FTData^ do
  begin
    TA := nil;
    TOrder := nil;
    NameList.Free;
  end;
  with FPData^ do
  begin
    FA := nil;
    FOrder := nil;
    NameList.Free;
  end;
  FOArray := nil;
  FNotifyArray := nil;
  {$IFNDEF FPC}
  DeallocateHWnd(FWindowHandle);
  {$ENDIF}
  Dispose(FFData);
  Dispose(FTData);
  for I := 0 to FConstantList.List.Count - 1 do
  begin
    Item := PValue(FConstantList.List.Objects[I]);
    if Assigned(Item) then Dispose(Item);
  end;
  inherited;
end;

function TCustomParser.DoEvent(const Event: TFunctionEvent; const Header: PScriptHeader;
  const AFunction: PFunction; const AType: PType; out Value: TValue; const LValue, RValue: TValue;
  const PA: TParameterArray): Boolean;
begin
  Result := Assigned(Event) and Event(Header, AFunction, AType, Value, LValue, RValue, PA);
end;

procedure TCustomParser.EndUpdate;
begin
  InterlockedDecrement(FUpdateCount);
end;

function TCustomParser.FindConstant(const AName: string): PValue;
var
  I: NativeInt;
begin
  I := ParseCommon.IndexOf(FConstantList.List, AName, False);
  if I < 0 then
    Result := nil
  else
    Result := Pointer(FConstantList.List.Objects[I]);
end;

function TCustomParser.FindConstant(const AName: string; out Value: PValue): Boolean;
begin
  Value := FindConstant(AName);
  Result := Assigned(Value);
end;

function TCustomParser.FindFunction(const AName: string): PFunction;
var
  I: Integer;
begin
  if FFData.Prepared then
    if Assigned(FFData.NameList) then
    begin
      I := FFData.NameList.List.IndexOf(AName);
      if I < 0 then
        Result := nil
      else
        GetFunction(NativeInt(FFData.NameList.List.Objects[I]), Result);
    end
    else
      Result := nil
  else begin
    for I := Low(FFData.FA) to High(FFData.FA) do
      if Same(FFData.FA[I].Name, AName) then
      begin
        Result := @FFData.FA[I];
        Exit;
      end;
    Result := nil;
  end;
end;

function TCustomParser.FindType(const AName: string): PType;
var
  I: Integer;
begin
  if FTData.Prepared then
    if Assigned(FTData.NameList) then
    begin
      I := FTData.NameList.List.IndexOf(AName);
      if I < 0 then
        Result := nil
      else
        GetType(NativeInt(FTData.NameList.List.Objects[I]), Result);
    end
    else
      Result := nil
  else begin
    for I := Low(FTData.TA) to High(FTData.TA) do
      if Same(FTData.TA[I].Name, AName) then
      begin
        Result := @FTData.TA[I];
        Exit;
      end;
    Result := nil;
  end;
end;

function TCustomParser.GetFunction(const Handle: NativeInt; var AFunction: PFunction): Boolean;
begin
  Result := CheckFHandle(Handle);
  if Result then AFunction := @FFData.FA[Handle];
end;

function TCustomParser.GetFunction(const Handle: NativeInt): PFunction;
begin
  if not GetFunction(Handle, Result) then Result := nil;
end;

function TCustomParser.GetBoolean32(const Index: Boolean): NativeInt;
begin
  if Index then
    Result := FPositiveValue.Signed32
  else
    Result := FNegativeValue.Signed32;
end;

function TCustomParser.GetFInternal: PFunction;
begin
  Result := @FFData.FA[FInternalHandle];
end;

function TCustomParser.GetFunction(const Variable: PValue): PFunction;
var
  I: Integer;
begin
  for I := Low(FFData.FA) to High(FFData.FA) do
  begin
    Result := @FFData.FA[I];
    if (Result.Kind = fkMethod) and (Result.Method.MethodType = mtVariable) and
      (Result.Method.Variable.Variable = Variable) then
        Exit;
  end;
  Result := nil;
end;

function TCustomParser.GetIgnoreType(const ItemCode: TItemCode): Boolean;
begin
  Result := FIgnoreType[ItemCode];
end;

function TCustomParser.GetTextData(const Text: string): TTextData;
var
  AFunction: PFunction;
begin
  FillChar(Result, SizeOf(TTextData), 0);
  if InBrace(Text, FBracket) then
    Result.TextType := ttScript
  else if Quoted(Text) then
  begin
    Result.TextType := ttString;
    StrLCopy(Result.Text, PChar(Dequote(Text)), High(TString));
  end
  else begin
    Result.Value := TextToValue(Text);
    case Result.Value.ValueType of
      vtUnknown:
        begin
          AFunction := FindFunction(Text);
          if Assigned(AFunction) then
          begin
            Result.Handle := AFunction.Handle^;
            Result.TextType := ttFunction;
          end
          else
            Result.TextType := ttUnknown;
        end;
    else
      Result.TextType := ttNumber;
    end;
  end;
end;

function TCustomParser.GetType(const Handle: NativeInt; var AType: PType): Boolean;
begin
  Result := CheckTHandle(Handle);
  if Result then AType := @FTData.TA[Handle];
end;

function TCustomParser.GetType(const Handle: NativeInt): PType;
begin
  if not GetType(Handle, Result) then Result := nil;
end;

function TCustomParser.Notifiable(const NotifyType: TNotifyType): Boolean;
begin
  Result := NotifyAttribute[NotifyType].Permanent and (NotifyAttribute[NotifyType].Reliable or
    Available(Self)) or (FUpdateCount = 0) and (NotifyAttribute[NotifyType].Reliable or
    Available(Self));
end;

procedure TCustomParser.Notification(Component: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (Component = FAddressee) then FAddressee := nil;
end;

{$WARNINGS OFF}
procedure TCustomParser.Notify;
var
  ANotifyArray: TNotifyArray;
  I: Integer;
begin
  if Assigned(FNotifyArray) then
  begin
    {$IFDEF FPC}
    Pointer(ANotifyArray) := System.InterlockedExchange(Pointer(FNotifyArray), Pointer(ANotifyArray));
    {$ELSE}
    {$IFDEF WIN32}
    Integer(ANotifyArray) := InterlockedExchange(Integer(FNotifyArray), Integer(ANotifyArray));
    {$ELSE}
    NativeInt(ANotifyArray) := AtomicExchange(NativeInt(FNotifyArray), NativeInt(ANotifyArray));
    {$ENDIF}
    {$ENDIF}
    try
      for I := Low(ANotifyArray) to High(ANotifyArray) do
        Notify(ANotifyArray[I].NotifyType, ANotifyArray[I].Component);
    finally
      ANotifyArray := nil;
    end;
  end;
end;
{$WARNINGS ON}

procedure TCustomParser.Notify(const NotifyType: TNotifyType; const Sender: TComponent);
begin
  if Notifiable(NotifyType) and Available(FAddressee) then
    TCustomAddressee(FAddressee).Notify(NotifyType, Sender);
end;

procedure TCustomParser.Prepare;
begin
  ParseUtils.Prepare(FFData);
  if ParseUtils.Prepare(FTData) then
    FDefaultTypeHandle := MakeTypeHandle(FTData^, FDefaultValueType, -1);
  Notify;
end;

procedure TCustomParser.SetBoolean32(const Index: Boolean; const Value: NativeInt);
begin
  if Index then
    FPositiveValue.Signed32 := Value
  else
    FNegativeValue.Signed32 := Value;
end;

procedure TCustomParser.SetIgnoreType(const ItemCode: TItemCode; const Value: Boolean);
begin
  FIgnoreType[ItemCode] := Value;
end;

procedure TCustomParser.WindowMethod(var Message: TMessage);
var
  Data: PVariableData;
begin
  case Message.Msg of
    WM_NOTIFY:
      Put(FNotifyArray, MakeNotify(TNotifyType(Message.WParam), TComponent(Message.LParam)));
    WM_ADDFUNCTION: Message.Result := NativeInt(InternalAddFunction(PFunction(Message.WParam)^));
    WM_ADDVARIABLE:
      begin
        Data := PVariableData(Message.WParam);
        Message.Result := NativeInt(InternalAddVariable(Data.Name, PValue(Message.LParam)^,
          Data.Optimizable, Data.ReturnType));
      end;
  else
    {$IFNDEF FPC}
    Message.Result := DefWindowProc(FWindowHandle, Message.Msg, Message.WParam, Message.LParam);
    {$ENDIF}
  end
end;

function TParser.Connect(const ABeforeFunction: TFunctionEvent;
  const AAddressee: TCustomAddressee): TFunctionEvent;
begin
  if AAddressee <> FConnector then TCustomConnector(FConnector).Parser := nil;
  Result := inherited Connect(ABeforeFunction, AAddressee);
end;

constructor TParser.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited;
  FRedirectList := TList.Create;
  FConnector := TConnector.Create(Self);
  TConnector(FConnector).Parser := Self;
  TConnector(FConnector).Name := InternalConnectorName;
  FParseManager := TParseManager.Create(Self);
  TParseManager(FParseManager).Connector := TCustomConnector(FConnector);
  TParseManager(FParseManager).Name := InternalParseManagerName;
  TParseManager(FParseManager).SetSubComponent(True);
  FCache := TCache.Create(Self, TCustomAddressee(FConnector));
  FCache.Name := InternalCacheName;
  FCache.SetSubComponent(True);
  FFData.FlagCache := TFlagCache.Create(Self);
  TFlagCache(FFData.FlagCache).Connector := TCustomConnector(FConnector);
  TFlagCache(FFData.FlagCache).Name := InternalFlagCacheName;
  TFlagCache(FFData.FlagCache).SetSubComponent(True);
  FFData.ItemCache := TItemCache.Create(Self);
  TItemCache(FFData.ItemCache).Connector := TCustomConnector(FConnector);
  TItemCache(FFData.ItemCache).Name := InternalItemCacheName;
  TItemCache(FFData.ItemCache).SetSubComponent(True);
  FPData.FlagCache := TFlagCache.Create(Self);
  TFlagCache(FPData.FlagCache).Connector := TCustomConnector(FConnector);
  TFlagCache(FPData.FlagCache).Name := InternalPOperatorFlagCacheName;
  TFlagCache(FPData.FlagCache).SetSubComponent(True);
  FPData.ItemCache := TItemCache.Create(Self);
  TItemCache(FPData.ItemCache).Connector := TCustomConnector(FConnector);
  TItemCache(FPData.ItemCache).Name := InternalPOperatorItemCacheName;
  TItemCache(FPData.ItemCache).SetSubComponent(True);
  BeginUpdate;
  try
    InternalAddFunction(MultiplyFunctionName, FMultiplyHandle, fkMethod,
      MakeFunctionMethod(FMethod.MultiplyMethod), True);
    InternalAddFunction(DivideFunctionName, FDivideHandle, fkMethod,
      MakeFunctionMethod(FMethod.DivideMethod), True);
    InternalAddFunction(SuccFunctionName, FSuccHandle, fkMethod,
      MakeFunctionMethod(FMethod.SuccMethod, False, True), True);
    InternalAddFunction(PredFunctionName, FPredHandle, fkMethod,
      MakeFunctionMethod(FMethod.PredMethod, False, True), True);
    for I := Low(NotFunctionName) to High(NotFunctionName) do
      InternalAddFunction(NotFunctionName[I], FNotHandle[I], fkMethod,
        MakeFunctionMethod(FMethod.NotMethod, False, True), True);
    for I := Low(AndFunctionName) to High(AndFunctionName) do
      InternalAddFunction(AndFunctionName[I], FAndHandle[I], fkMethod,
        MakeFunctionMethod(FMethod.AndMethod), True);
    for I := Low(OrFunctionName) to High(OrFunctionName) do
      InternalAddFunction(OrFunctionName[I], FOrHandle[I], fkMethod,
        MakeFunctionMethod(FMethod.OrMethod), True, OrReturnType[I], OrPriority[I], OrCoverage[I]);
    for I := Low(XorFunctionName) to High(XorFunctionName) do
      InternalAddFunction(XorFunctionName[I], FXorHandle[I], fkMethod,
        MakeFunctionMethod(FMethod.XorMethod), True);
    for I := Low(ShiftLeftFunctionName) to High(ShiftLeftFunctionName) do
      InternalAddFunction(ShiftLeftFunctionName[I], FShlHandle[I], fkMethod,
        MakeFunctionMethod(FMethod.ShlMethod), True);
    for I := Low(ShiftRightFunctionName) to High(ShiftRightFunctionName) do
      InternalAddFunction(ShiftRightFunctionName[I], FShrHandle[I], fkMethod,
        MakeFunctionMethod(FMethod.ShrMethod), True);
    InternalAddFunction(BitwiseNotFunctionName, FBitwiseNotHandle, fkMethod,
      MakeFunctionMethod(FMethod.NotMethod, False, True), True);
    InternalAddFunction(BitwiseAndFunctionName, FBitwiseAndHandle, fkMethod,
      MakeFunctionMethod(FMethod.AndMethod), True);
    InternalAddFunction(BitwiseOrFunctionName, FBitwiseOrHandle, fkMethod,
      MakeFunctionMethod(FMethod.OrMethod), True);
    InternalAddFunction(BitwiseXorFunctionName, FBitwiseXorHandle, fkMethod,
      MakeFunctionMethod(FMethod.XorMethod), True);
    InternalAddFunction(TryExceptFunctionName, FTryExceptHandle, fkMethod,
      MakeFunctionMethod(FMethod.TryExceptMethod, TryExceptParameterCount, pkReference), True);
    InternalAddFunction(TryFinallyFunctionName, FTryFinallyHandle, fkMethod,
      MakeFunctionMethod(FMethod.TryFinallyMethod, TryFinallyParameterCount, pkReference), True);
    InternalAddFunction(SameValueFunctionName, FSameValueHandle, fkMethod,
      MakeFunctionMethod(FMethod.SameValueMethod, SameValueParameterMaxCount), True);
    InternalAddFunction(IsZeroFunctionName, FIsZeroHandle, fkMethod,
      MakeFunctionMethod(FMethod.IsZeroMethod, IsZeroParameterMaxCount), True);
    InternalAddFunction(IfFunctionName, FIfHandle, fkMethod,
      MakeFunctionMethod(FMethod.IfMethod, IfParameterMaxCount, pkReference), True);
    InternalAddFunction(ExitFunctionName, FExitHandle, fkMethod,
      MakeFunctionMethod(FMethod.ExitMethod, 1, pkValue), False);
    InternalAddFunction(IfThenFunctionName, FIfThenHandle, fkMethod,
      MakeFunctionMethod(FMethod.IfThenMethod, IfThenParameterCount), True);
    InternalAddFunction(EnsureRangeFunctionName, FEnsureRangeHandle, fkMethod,
      MakeFunctionMethod(FMethod.EnsureRangeMethod, EnsureRangeParameterCount), True);
    InternalAddFunction(StrToIntFunctionName, FStrToIntHandle, fkMethod,
      MakeFunctionMethod(FMethod.StrToIntMethod, StrToIntParameterCount), True);
    InternalAddFunction(StrToIntDefFunctionName, FStrToIntDefHandle, fkMethod,
      MakeFunctionMethod(FMethod.StrToIntDefMethod, StrToIntDefParameterCount), True);
    InternalAddFunction(StrToFloatFunctionName, FStrToFloatHandle, fkMethod,
      MakeFunctionMethod(FMethod.StrToFloatMethod, StrToFloatParameterCount), True);
    InternalAddFunction(StrToFloatDefFunctionName, FStrToFloatDefHandle, fkMethod,
      MakeFunctionMethod(FMethod.StrToFloatDefMethod, StrToFloatDefParameterCount), True);
    InternalAddFunction(ParseFunctionName, FParseHandle, fkMethod,
      MakeFunctionMethod(FMethod.ParseMethod, ParseParameterCount), False);
    InternalAddFunction(DerivFunctionName, FDerivHandle, fkMethod,
      MakeFunctionMethod(FMethod.DerivMethod, DerivParameterMaxCount), False);
    InternalAddFunction(FalseFunctionName, FFalseHandle, fkMethod,
      MakeFunctionMethod(FMethod.FalseMethod), True);
    InternalAddFunction(TrueFunctionName, FTrueHandle, fkMethod,
      MakeFunctionMethod(FMethod.TrueMethod), True);
    InternalAddFunction(EqualFunctionName, FEqualHandle, fkMethod,
      MakeFunctionMethod(FMethod.EqualMethod), True, vtUnknown, fpLower, pcTotal);
    InternalAddFunction(NotEqualFunctionName, FNotEqualHandle, fkMethod,
      MakeFunctionMethod(FMethod.NotEqualMethod), True, vtUnknown, fpLower, pcTotal);
    InternalAddFunction(AboveFunctionName, FAboveHandle, fkMethod,
      MakeFunctionMethod(FMethod.AboveMethod), True, vtUnknown, fpLower, pcTotal);
    InternalAddFunction(BelowFunctionName, FBelowHandle, fkMethod,
      MakeFunctionMethod(FMethod.BelowMethod), True, vtUnknown, fpLower, pcTotal);
    InternalAddFunction(AboveOrEqualFunctionName, FAboveOrEqualHandle, fkMethod,
      MakeFunctionMethod(FMethod.AboveOrEqualMethod), True, vtUnknown, fpLower, pcTotal);
    InternalAddFunction(BelowOrEqualFunctionName, FBelowOrEqualHandle, fkMethod,
      MakeFunctionMethod(FMethod.BelowOrEqualMethod), True, vtUnknown, fpLower, pcTotal);
    InternalAddFunction(GetEpsilonFunctionName, FGetEpsilonHandle, fkMethod,
      MakeFunctionMethod(FMethod.GetEpsilonMethod), False);
    InternalAddFunction(SetEpsilonFunctionName, FSetEpsilonHandle, fkMethod,
      MakeFunctionMethod(FMethod.SetEpsilonMethod, SetEpsilonParameterCount), False);
    InternalAddFunction(SetDecimalSeparatorFunctionName, FSetDecimalSeparatorHandle, fkMethod,
      MakeFunctionMethod(FMethod.SetDecimalSeparatorMethod, SetDecimalSeparatorParameterCount), False);
    AddType(ShortintTypeName, FShortintHandle, vtShortint);
    AddType(ByteTypeName, FByteHandle, vtByte);
    AddType(SmallintTypeName, FSmallintHandle, vtSmallint);
    AddType(WordTypeName, FWordHandle, vtWord);
    AddType(IntegerTypeName, FIntegerHandle, vtInteger);
    AddType(LongWordTypeName, FLongWordHandle, vtLongWord);
    AddType(NativeIntTypeName, FNativeIntHandle, vtNativeInt);
    AddType(NativeUIntTypeName, FNativeUIntHandle, vtNativeUInt);
    AddType(Int64TypeName, FInt64Handle, vtInt64);
    AddType(SingleTypeName, FSingleHandle, vtSingle);
    AddType(DoubleTypeName, FDoubleHandle, vtDouble);
    AddType(ExtendedTypeName, FExtendedHandle, vtExtended);
  finally
    EndUpdate;
  end;
  FExceptionTypeSet := [etZeroDivide];
  FCached := True;
end;

function TParser.CreateRedirect: Integer;
var
  P: PRedirect;
  I: Integer;
begin
  New(P);
  try
    FillChar(P^, SizeOf(TRedirect), 0);
    P.Index := 0;
    for I := 0 to FRedirectList.Count - 1 do
      if PRedirect(FRedirectList[I]).Index = P.Index then Inc(P.Index);
    FRedirectList.Add(P);
    Result := P.Index;
  except
    Dispose(P);
    raise;
  end;
end;

function TParser.DeleteRedirect(const Index: Integer): Boolean;
var
  I: Integer;
  P: PRedirect;
begin
  for I := 0 to FRedirectList.Count - 1 do
  begin
    P := PRedirect(FRedirectList[I]);
    Result := P.Index = Index;
    if Result then
    begin
      Dispose(P);
      FRedirectList.Delete(I);
      Exit;
    end;
  end;
  Result := False;
end;

destructor TParser.Destroy;
var
  I: Integer;
  P: Pointer;
begin
  for I := FRedirectList.Count - 1 downto 0 do
  begin
    P := FRedirectList[I];
    Dispose(P);
  end;
  FRedirectList.Free;
  FMethod.Free;
  FScript := nil;
  FCache.Clear;
  inherited;
end;

function TParser.DSMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
var
  S: string;
  Data: PDSData;
  Start: NativeInt;
  AType: PType;
begin
  Data := P;
  Start := NativeInt(ItemHeader);
  case Item.Code of
    NumberCode:
      begin
        S := ValueToText(Item.ScriptNumber.Value);
        if not Data.Parameter and LessZero(Item.ScriptNumber.Value) then
          Data.ItemText.Append(Embrace(S, FBracket), Data.Delimiter)
        else
          Data.ItemText.Append(S, Data.Delimiter);
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
        Data.AFunction := nil;
      end;
    FunctionCode:
      begin
        Read(Self, Index, Data.AFunction);
        Data.ItemText.Append(Data.AFunction.Name, Data.Delimiter);
      end;
    StringCode:
      begin
        Data.ItemText.Append(LockText, Data.Delimiter);
        Data.ItemText.Append(PAnsiChar(Index) + SizeOf(TCode) + SizeOf(TScriptString),
          Item.ScriptString.Size div SizeOf(Char));
        Data.ItemText.Append(LockText);
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
        Data.AFunction := nil;
      end;
    ScriptCode:
      begin
        S := InternalDecompile(Index + SizeOf(TCode), Data.Delimiter, False, Data.ParameterBracket,
          Data.TypeMode);
        if Data.Parameter then
          Data.ItemText.Append(S, Data.Delimiter)
        else
          Data.ItemText.Append(Embrace(S, FBracket), Data.Delimiter);
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
        Data.AFunction := nil;
      end;
    ParameterCode:
      begin
        S := InternalDecompile(Index + SizeOf(TCode), Data.Delimiter, True, Data.ParameterBracket,
          Data.TypeMode);
        Data.ItemText.Append(Embrace(S, Data.ParameterBracket), Data.Delimiter);
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
        Data.AFunction := nil;
      end;
  else
    raise Error(ScriptError);
  end;
  if Index - Start >= ItemHeader.Size then
  begin
    if ((Data.TypeMode = rmUser) and ItemHeader.UserType.Active or (Data.TypeMode = rmFull)) and
      GetType(ItemHeader.UserType.Handle, AType) then
        Data.ItemText.Insert(string(AType.Name) + Space);
    if not Data.Parameter and Boolean(ItemHeader.Sign) then
      Data.ItemText.Insert(TOperatorArray[toNegative] + Space);
    if Data.Text.Size > 0 then
      if Data.Parameter then
        Data.ItemText.Insert(POperatorArray[poComma] + Space)
      else
        if not Boolean(ItemHeader.Sign) then
          Data.ItemText.Insert(TOperatorArray[toPositive] + Space);
    if Data.Parameter then
      Data.Text.Append(Data.ItemText.Text)
    else
      if Data.ItemText.Size > 0 then Data.Text.Append(Data.ItemText.Text, Data.Delimiter);
    Data.ItemText.Clear;
  end;
  Result := True;
end;

function TParser.ExecuteScript(const Index: NativeInt): PValue;
var
  Header: PScriptHeader;
  Value: TValue;
  Frame: TExecuteFrame;
  Mask: TFPUExceptionMask;
  Root: Boolean;
begin
  Notify;
  Header := PScriptHeader(Index);
  Result := @Header.Value;
  Frame.Previous := CurrentExecuteFrame;
  Frame.Parser := Self;
  Mask := GetExceptionMask;
  Root := Mask <> FExceptionMask;
  if Root then SetExceptionMask(FExceptionMask);
  CurrentExecuteFrame := @Frame;
  try
    try
      if not (ekSubsequent in FExecuteKindSet) and (Header.ScriptCount > 0) then
        ExecuteInternalScript(Index);
      Header.Value := EmptyValue;
      Value := EmptyValue;
      ParseScript(Index, ESMethod, @Value);
    except
      on E: EParserExit do
      begin
        if (E.OwnerParser <> Self) or HasExecuteFrame(Self, Frame.Previous) then raise;
        Header.Value := E.Value;
      end;
    end;
  finally
    CurrentExecuteFrame := Frame.Previous;
    if Root then SetExceptionMask(Mask);
  end;
end;

function TParser.ExecuteScript(const Script: TScript): PValue;
begin
  Result := ExecuteScript(NativeInt(Script));
end;

function TParser.ExecuteScript: PValue;
begin
  Result := ExecuteScript(FScript);
end;

function TParser.ExecuteFunction(var Index: NativeInt; const Header: PScriptHeader;
  const ItemHeader: PItemHeader; const LValue: TValue; const Idle: Boolean): TValue;
var
  AFunction, BFunction: PFunction;
  Handle: NativeInt;
  PA: TParameterArray;
  RValue: TValue;
  Jump: Boolean;
  Item: ^PScriptItem;
  AType: PType;
  ValueType: TValueType;
begin
  Item := @Index;
  Read(Self, Index, AFunction);
  Handle := AFunction.Handle^;
  try
    while GetRedirect(Header.RedirectCategory, AFunction.Handle^, Handle) do
    begin
      BFunction := GetFunction(Handle);
      if not Assigned(BFunction) then Break;
      AFunction := BFunction;
    end;
    if AFunction.Method.Parameter.Count > 0 then
    begin
      Inc(Index, SizeOf(TCode));
      ReadParameterArray(Index, PA, TParameterType(AFunction.Method.Parameter.Kind = pkReference));
      RValue := EmptyValue;
    end
    else begin
      RValue := EmptyValue;
      if AFunction.Method.Parameter.R then
      begin
        case FBooleanMode of
          bmShortCircuit:
            Jump := (AFunction.Handle^ = FAndHandle[0]) and not GetBoolean(LValue) or
              (AFunction.Handle^ = FOrHandle[0]) and GetBoolean(LValue);
        else
          Jump := False;
        end;
        case Item^.Code of
          NumberCode:
            begin
              if not Idle and not Jump then RValue := Item^.ScriptNumber.Value;
              Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
            end;
          FunctionCode:
            RValue := ExecuteFunction(Index, Header, ItemHeader, EmptyValue, Idle or Jump);
          ScriptCode:
            begin
              if not Idle and not Jump then
                if ekSubsequent in FExecuteKindSet then
                  RValue := ExecuteScript(NativeInt(@Item^.Script.Header))^
                else
                  RValue := Item^.Script.Header.Value;
              Inc(Index, SizeOf(TCode) + Item^.Script.Header.ScriptSize);
            end;
        else
          raise Error(ScriptError);
        end;
      end;
    end;
    if Idle then
      Result := EmptyValue
    else begin
      AType := ParseUtils.GetType(Self, ItemHeader);
      case AFunction.Kind of
        fkHandle:
          if not DoEvent(FBeforeFunction, Header, AFunction, AType, Result, LValue, RValue, PA) and
            not DefaultFunction(Header, AFunction, Result, LValue, RValue, PA) and not DoEvent(FOnFunction, Header, AFunction, AType, Result, LValue, RValue, PA) then
              raise Error(FunctionHandleError, [AFunction.Name]);
        fkMethod:
          case AFunction.Method.MethodType of
            mtMethod0: Result := AFunction.Method.Method0(Header, AFunction, AType);
            mtMethod1:
              if AFunction.Method.Parameter.L then
                Result := AFunction.Method.Method1(Header, AFunction, AType, LValue)
              else
                Result := AFunction.Method.Method1(Header, AFunction, AType, RValue);
            mtMethod2: Result := AFunction.Method.Method2(Header, AFunction, AType, LValue, RValue);
            mtMethod3: Result := AFunction.Method.Method3(Header, AFunction, AType, PA);
            mtVariable:
              case AFunction.Method.Variable.VariableType of
                vtValue: Result := AFunction.Method.Variable.Variable^;
                vtValueRef: Result := MakeValue(AFunction.Method.Variable.VariableRef);
              else
                Result := EmptyValue;
              end;
          else
            Result := EmptyValue;
          end;
      else
        Result := EmptyValue;
      end;
    end;
    AFunction := GetFunction(Handle);
    if (Result.ValueType <> vtUnknown) and Assigned(AFunction) and
      (AFunction.ReturnType <> vtUnknown) then
      begin
        if ItemHeader.UserType.Active and GetType(ItemHeader.UserType.Handle, AType) then
          ValueType := AType.ValueType
        else
          if FIgnoreType[icFunction] then
            ValueType := vtUnknown
          else
            ValueType := AFunction.ReturnType;
        if ValueType <> vtUnknown then Result := Convert(Result, ValueType);
      end;
  finally
    PA := nil;
  end;
end;

procedure TParser.ExecuteInternalScript(Index: NativeInt);
var
  Header: ^PScriptHeader;
  I, J, K: NativeInt;
begin
  Header := @Index;
  if Header^.ScriptCount > 0 then
  begin
    I := Index + SizeOf(TScriptHeader);
    J := I + Header^.ScriptCount * SizeOf(NativeInt);
    while I < J do
    begin
      K := Index + PNativeInt(I)^;
      ExecuteScript(K);
      Inc(I, SizeOf(NativeInt));
    end;
  end;
end;

function TParser.ESMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
var
  Value: PValue;
  Start: NativeInt;
  AType: PType;
begin
  Value := PValue(P);
  Start := NativeInt(ItemHeader);
  case Item.Code of
    NumberCode:
      begin
        Value^ := Item.ScriptNumber.Value;
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
      end;
    FunctionCode: Value^ := ExecuteFunction(Index, Header, ItemHeader, Value^, False);
    ScriptCode:
      begin
        if ekSubsequent in FExecuteKindSet then
          Value^ := ExecuteScript(NativeInt(@Item.Script.Header))^
        else
          Value^ := Item.Script.Header.Value;
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
    ParameterCode: Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
  else
    raise Error(ScriptError);
  end;
  if Index - Start >= ItemHeader.Size then
  begin
    if not FIgnoreType[icScript] and ItemHeader.UserType.Active and GetType(ItemHeader.UserType.Handle, AType) then
      Value^ := Convert(Value^, AType.ValueType);
    Header.Value := Operation(Header.Value, Value^, TOperationType(Ord(otAdd) + ItemHeader.Sign));
  end;
  Result := True;
end;

function TParser.GetRedirect(const Category, Source: NativeInt; var Target: NativeInt): Boolean;
var
  I, J, K: Integer;
  P: PRedirect;
begin
  Result := Category > 0;
  if Result then
  begin
    I := 0;
    J := FRedirectList.Count - 1;
    while (I < J) and (PRedirect(FRedirectList[I]).Category <> Category) do Inc(I);
    while (J > 0) and (PRedirect(FRedirectList[J]).Category <> Category) do Dec(J);
    while I <= J do
    begin
      K := (I + J) div 2;
      P := FRedirectList[K];
      case CompareValue(Source, P.Source) of
        LessThanValue: J := K - 1;
        GreaterThanValue: I := K + 1;
      else
        Result := P.Category = Category;
        if Result then Target := P.Target;
        Exit;
      end;
    end;
    Result := False;
  end;
end;

function TCustomParser.InternalAddConstant(const AName: string; const Value: TValue): Boolean;
var
  Item: PValue;
begin
  Result := not Assigned(FindFunction(AName));
  if Result then
  begin
    New(Item);
    try
      Item^ := Value;
      Result := InternalAddVariable(AName, Item^, True, Value.ValueType);
      if Result then
        FConstantList.List.AddObject(AName, Pointer(Item))
      else
        Dispose(Item);
    except
      Dispose(Item);
      raise;
    end;
  end;
end;

function TCustomParser.InternalAddFunction(const AFunction: TFunction): Boolean;
var
  Error: TError;
  I: Integer;
begin
  Result := (AFunction.Name <> '') and not Assigned(FindFunction(AFunction.Name));
  if Result then
  begin
    Notify(ntBFA, Self);
    repeat
      if AFunction.Handle = @FInternalHandle then Break;
      I := 0;
      while I < Length(FOArray) do
      begin
        if AFunction.Handle = @FOArray[I] then
        begin
          I := -1;
          Break;
        end;
        Inc(I);
      end;
      if I < 0 then Break;
      Error := Validator.Check(AFunction.Name, rtName);
      if Error.ErrorType <> etOK then raise ParseErrors.Error(Error.ErrorText);
    until True;
    AFunction.Handle^ := ParseUtils.AddFunction(FFData^, AFunction);
    Notify(ntAFA, Self);
  end
  else
    AFunction.Handle^ := -1;
end;

function TCustomParser.InternalAddFunction(const AName: string; var Handle: NativeInt;
  const Kind: TFunctionKind; const Method: TFunctionMethod; const Optimizable: Boolean;
  const ReturnType: TValueType; const Priority: TFunctionPriority;
  const Coverage: TPriorityCoverage): Boolean;
begin
  Result := InternalAddFunction(MakeFunction(AName, Handle, ReturnType, Kind, Method, Optimizable,
    MakePriority(Priority, Coverage)));
end;

function TCustomParser.InternalAddVariable(const AName: string; var Variable: TValue;
  const Optimizable: Boolean; const ReturnType: TValueType): Boolean;
var
  AFunction: TFunction;
begin
  AFunction := MakeFunction(AName, AFunction.Method.Variable.Handle, ReturnType, fkMethod,
    MakeFunctionMethod(@Variable), Optimizable, MakePriority(fpNormal, pcLocal));
  Result := InternalAddFunction(AFunction);
end;

function TCustomParser.InternalAddVariable(const AName: string; const Variable: TValueRef;
  const Optimizable: Boolean; const ReturnType: TValueType): Boolean;
var
  AFunction: TFunction;
begin
  AFunction := MakeFunction(AName, AFunction.Method.Variable.Handle, ReturnType, fkMethod,
    MakeFunctionMethod(Variable), Optimizable, MakePriority(fpNormal, pcLocal));
  Result := AddFunction(AFunction);
end;

function TParser.InternalCompile(const Text: string; var SA: TScriptArray; const Parameter: Boolean;
  var Idle: PFunction; out Error: TError): TScript;
var
  AText, S: string;
  AFlag, BFlag, CFlag, DFlag, Sign: Boolean;
  ACache, BCache: TParseCache;
  AArray, BArray: TTextItemArray1;
  Script: TScript;
  I, J, K: Integer;
  ItemIndex: NativeInt;
  ItemArray2: TTextItemArray2;
  AItem, BItem: PTextItem;
  IHType: TValueType;
  Syntax: TSyntax;
  Data: TTextData;
  Header: ^PScriptHeader;

  procedure WriteItem(const Item: PTextItem);
  const
    Size = 1;
  begin
    if I > High(ItemArray2) then SetLength(ItemArray2, I + 1);
    SetLength(ItemArray2[I], Size);
    ItemArray2[I, 0] := Item^;
  end;

  procedure WriteType(const Code: TItemCode; const ItemType: TValueType);
  var
    UserType: PType;
  begin
    if ItemType <> vtUnknown then
    begin
      if not GetType(AItem.THandle, UserType) then UserType := nil;
      if Assigned(UserType) then
        if Assignable(UserType.ValueType, ItemType) then
          IHType := UserType.ValueType
        else
          IHType := ItemType
      else
        IHType := ItemType;
      AssignUserType(Self, @Result[ItemIndex], Assigned(UserType), IHType);
    end;
  end;

  procedure Write(const Code: TItemCode);
  var
    AType: PType;
  begin
    case Code of
      icNumber:
        begin
          if not FIgnoreType[icNumber] and GetType(AItem.THandle, AType) then
            Data.Value := Convert(Data.Value, AType.ValueType);
          WriteType(Code, Data.Value.ValueType);
          WriteNumber(Result, Data.Value);
        end;
      icFunction:
        begin
          if GetType(AItem.THandle, AType) then WriteType(Code, AType.ValueType);
          WriteFunction(Result, BItem.FHandle);
        end;
      icString:
        begin
          PItemHeader(@Result[ItemIndex]).UserType.Active := GetType(AItem.THandle, AType);
          PItemHeader(@Result[ItemIndex]).UserType.Handle := FStringHandle;
          WriteString(Result, Data.Text);
        end;
      icScript, icParameter:
        begin
          if GetType(AItem.THandle, AType) then WriteType(Code, AType.ValueType);
          WriteScript(Result, Script, Code = icParameter, @ItemIndex);
        end;
    end;
  end;

begin
  FillChar(Error, SizeOf(TError), 0);
  Result := nil;
  AText := Text;
  if AText = '' then
  begin
    Error := MakeError(etEmptyTextError, EmptyTextError);
    Exit;
  end;
  if Assigned(FCache) then
    if Parameter then
      ACache := FCache.CacheArray[ctParameter]
    else
      ACache := FCache.CacheArray[ctScript]
  else
    ACache := nil;
  AFlag := Pos(FInternal.Name, AText) = 0;
  if FCached and Assigned(ACache) and AFlag then
  begin
    Enter(ACache.Lock^);
    try
      Result := ACache.Find(AText);
    finally
      Leave(ACache.Lock^);
    end;
  end;
  if not Assigned(Result) then
  begin
    Parse(AText, SA, Idle, Error);
    if Error.ErrorType <> etOK then Exit;
    CFlag := FPrioritize and not Parameter;
    try
      if Parameter then
        GetTIArray(AText, FPData, FTData, AArray)
      else
        GetTIArray(AText, FFData, FTData, AArray, FInternalHandle);
      try
        if CFlag then Order(pcTotal, AArray, SA, Idle);
        if not Parameter then Morph(AArray, ItemArray2);
        if Assigned(FCache) then
          if Parameter then
            BCache := FCache.CacheArray[ctSubparameter]
          else
            BCache := FCache.CacheArray[ctSubscript]
        else
          BCache := nil;
        Resize(Result, SizeOf(TScriptHeader));
        for I := Low(AArray) to High(AArray) do
        begin
          AItem := @AArray[I];
          if Parameter then
          begin
            TrimPOperator(AItem.Text);
            Sign := False;
          end
          else
            Sign := GetSign(AItem^, FOArray);
          try
            BFlag := Pos(FInternal.Name, AItem.Text) = 0;
            if FCached and Assigned(BCache) and BFlag then
            begin
              Enter(BCache.Lock^);
              try
                if Sign then
                  Script := BCache.Find(TOperatorArray[toNegative] + AItem.Text)
                else
                  Script := BCache.Find(AItem.Text);
              finally
                Leave(BCache.Lock^);
              end;
            end
            else
              Script := nil;
            if Assigned(Script) then
              AddScript(Result, Script)
            else begin
              ItemIndex := Length(Result);
              Resize(Result, ItemIndex + SizeOf(TItemHeader));
              WriteItemHeader(PItemHeader(@Result[ItemIndex]), Sign, AItem.THandle, FDefaultTypeHandle);
              IHType := FDefaultValueType;
              FillChar(Syntax, SizeOf(TSyntax), 0);
              Syntax.PriorHandle := -1;
              Data := TextData[AItem.Text];
              if Data.TextType = ttNumber then
                Write(icNumber)
              else begin
                if AItem.Text = '' then
                begin
                  Error := MakeError(etTextError, Format(TextError, [AText]));
                  Exit;
                end;
                if Parameter then
                begin
                  AItem.Text := SetSign(AItem.Text);
                  AItem.FHandle := -1;
                  case Data.TextType of
                    ttUnknown:
                      begin
                        try
                          if FCached and Assigned(ACache) and (Pos(FInternal.Name, AItem.Text) = 0) then
                          begin
                            Enter(ACache.Lock^);
                            try
                              Script := ACache.Find(AItem.Text);
                              if not Assigned(Script) then
                              begin
                                Script := InternalCompile(AItem.Text, SA, False, Idle, Error);
                                if Error.ErrorType <> etOK then Exit;
                                ACache.Add(AItem.Text, Script);
                              end;
                            finally
                              Leave(ACache.Lock^);
                            end;
                          end
                          else begin
                            Script := InternalCompile(AItem.Text, SA, False, Idle, Error);
                            if Error.ErrorType <> etOK then Exit;
                          end;
                          AItem^ := MakeTextItem(Embrace(IntToStr(AddScript(SA, Script)), BracketArray[bkBrace]),
                            FInternal.Handle^, -1);
                        finally
                          Script := nil;
                        end;
                      end;
                    ttFunction: AItem^ := MakeTextItem(AItem.Text, Data.Handle, -1);
                  end;
                  WriteItem(AItem);
                end;
                if (I < Length(ItemArray2)) and Assigned(ItemArray2[I]) then
                  BArray := ItemArray2[I]
                else begin
                  Error := MakeError(etScriptError, ScriptError);
                  Exit;
                end;
                try
                  if CFlag then Order(pcLocal, BArray, SA, Idle);
                  for J := Low(BArray) to High(BArray) do
                  begin
                    BItem := @BArray[J];
                    if BItem.FHandle < 0 then
                    begin
                      Data := TextData[BItem.Text];
                      case Data.TextType of
                        ttNumber:
                          begin
                            Error := Check(Syntax, okNumber, AText, SA, -1);
                            if Error.ErrorType <> etOK then Exit;
                            Error := Check(BArray, J, MakeItemData(Data.Value), SA, Parameter);
                            if Error.ErrorType <> etOK then Exit;
                            Write(icNumber);
                          end;
                        ttString:
                          if Parameter then
                            Write(icString)
                          else begin
                            Error := MakeError(etStringError, Format(StringError, [BItem.Text]));
                            Exit;
                          end;
                      else
                        if BItem.Text <> '' then
                        begin
                          Error := MakeError(etElementError, Format(ElementError, [BItem.Text]));
                          Exit;
                        end;
                      end;
                    end
                    else if BItem.FHandle = FInternalHandle then
                    begin
                      Script := GetIS(BItem.Text, SA, DFlag);
                      if Assigned(Script) then
                      begin
                        if DFlag then
                        begin
                          Error := Check(Syntax, okParameter, AText, SA, -1);
                          if Error.ErrorType <> etOK then Exit;
                        end
                        else begin
                          Error := Check(Syntax, okScript, AText, SA, -1);
                          if Error.ErrorType <> etOK then Exit;
                        end;
                        Error := Check(BArray, J, MakeItemData(Script, DFlag), SA, Parameter);
                        if Error.ErrorType <> etOK then Exit;
                        if DFlag then
                          Write(icParameter)
                        else
                          Write(icScript);
                      end
                      else begin
                        Error := MakeError(etScriptError, ScriptError);
                        Exit;
                      end;
                      K := NextBracket(BItem.Text, BracketArray[bkBrace], 1);
                      if K > 0 then
                      begin
                        S := Trim(Copy(BItem.Text, K + 1, MaxInt));
                        if S <> '' then
                        begin
                          Error := MakeError(etElementError, Format(ElementError, [S]));
                          Exit;
                        end;
                      end;
                    end
                    else begin
                      Error := Check(Syntax, okFunction, AText, SA, BItem.FHandle);
                      if Error.ErrorType <> etOK then Exit;
                      Error := Check(BArray, J, MakeItemData(BItem.FHandle), SA, Parameter);
                      if Error.ErrorType <> etOK then Exit;
                      Write(icFunction);
                    end;
                  end;
                finally
                  BArray := nil;
                end;
                Error := Check(Syntax, okEof, AText, SA, -1);
                if Error.ErrorType <> etOK then Exit;
              end;
              PItemHeader(@Result[ItemIndex]).Size := Length(Result) - ItemIndex;
              if FCached and Assigned(BCache) and BFlag then
              begin
                Enter(BCache.Lock^);
                try
                  Script := Segment(Result, ItemIndex, Length(Result) - ItemIndex);
                  try
                    if Sign then
                      BCache.Add(TOperatorArray[toNegative] + AItem.Text, Script)
                    else
                      BCache.Add(AItem.Text, Script);
                  finally
                    Script := nil;
                  end;
                finally
                  Leave(BCache.Lock^);
                end;
              end;
            end;
          finally
            Script := nil;
          end;
        end;
      finally
        for I := Low(ItemArray2) to High(ItemArray2) do ItemArray2[I] := nil;
        ItemArray2 := nil;
      end;
    finally
      AArray := nil;
    end;
    Header := @Result;
    Header^.ScriptSize := Length(Result);
    Header^.HeaderSize := SizeOf(TScriptHeader) + Header^.ScriptCount * SizeOf(NativeInt);
    if FCached and Assigned(ACache) and AFlag then
    begin
      Enter(ACache.Lock^);
      try
        ACache.Add(Text, Result);
      finally
        Leave(ACache.Lock^);
      end;
    end;
  end;
end;

function TParser.InternalCompile(const Text: string; var SA: TScriptArray; const Parameter: Boolean;
  var Idle: PFunction): TScript;
var
  Error: TError;
begin
  Result := InternalCompile(Text, SA, Parameter, Idle, Error);
  if Error.ErrorType <> etOK then raise ParseErrors.Error(Error.ErrorText);
end;

function TParser.InternalDecompile(const Index: NativeInt; const Delimiter: string; const Parameter: Boolean;
  const ParameterBracket: TBracket; const TypeMode: TRetrieveMode): string;
var
  Data: TDSData;
begin
  Data := MakeDSData(Delimiter, Parameter, ParameterBracket, TypeMode);
  Data.Text := TTextBuilder.Create;
  try
    Data.ItemText := TTextBuilder.Create;
    try
      ParseScript(Index, DSMethod, @Data);
      Result := Data.Text.Text;
    finally
      Data.ItemText.Free;
    end;
  finally
    Data.Text.Free;
  end;
end;

procedure TParser.InternalOptimizeScript(const Index: NativeInt; out Script: TScript);
var
  Data: TOSData;
begin
  FillChar(Data, SizeOf(TOSData), 0);
  try
    ParseScript(Index, OSMethod, @Data);
    BuildScript(Self, Data.ItemArray, Script, True);
  finally
    Delete(Data.ItemArray);
  end;
end;

function TParser.Morph(var ItemArray1: TTextItemArray1; out ItemArray2: TTextItemArray2): Boolean;

  function New: Integer;
  begin
    Result := Length(ItemArray2);
    SetLength(ItemArray2, Result + 1);
  end;

type
  TArray = record
    ItemArray1: TTextItemArray1;
    Data: TArrayData;
  end;
var
  A: TArray;
  I, J, K, L: Integer;
  Item: PTextItem;
begin
  Result := Length(ItemArray1) > 0;
  if Result then
  begin
    FillChar(A, SizeOf(TArray), 0);
    Reset(A.ItemArray1, A.Data);
    try
      ItemArray2 := nil;
      J := -1;
      K := -1;
      L := -1;
      for I := Low(ItemArray1) to High(ItemArray1) do
      begin
        Item := @ItemArray1[I];
        if (Item.FHandle < 0) or (MemoryUtils.IndexOf(FOArray, Item.FHandle) < 0) then
          if J < 0 then
          begin
            if K < 0 then K := New;
            AddItem(ItemArray2[K], Item^);
            if L < 0 then
              L := AddItem(A.ItemArray1, A.Data, Item.Text, Item.FHandle, Item.THandle)
            else
              A.ItemArray1[L].Text := A.ItemArray1[L].Text + Space + Item.Text;
          end
          else begin
            K := New;
            AddItem(ItemArray2[K], Item^);
            if Item.THandle < 0 then
              L := AddItem(A.ItemArray1, A.Data, Item.Text, ItemArray1[J].FHandle, ItemArray1[J].THandle)
            else
              L := AddItem(A.ItemArray1, A.Data, Item.Text, ItemArray1[J].FHandle, Item.THandle);
            J := -1;
          end
        else begin
          if (J >= 0) and (ItemArray1[J].FHandle = FNegativeHandle^) then
            if ItemArray1[I].FHandle = FNegativeHandle^ then
              ItemArray1[I].FHandle := FPositiveHandle^
            else
              ItemArray1[I].FHandle := FNegativeHandle^;
          J := I
        end;
      end;
    finally
      Apply(A.ItemArray1, A.Data);
    end;
    ItemArray1 := A.ItemArray1;
  end;
end;

function TParser.Optimizable(var Index: NativeInt; const Number: Boolean; out Offset: NativeInt;
  out Parameter: Boolean; out Script: TScript): Boolean;
var
  AFunction: PFunction;
  Item: ^PScriptItem;
begin
  Item := @Index;
  Read(Self, Index, AFunction);
  Parameter := AFunction.Method.Parameter.Count > 0;
  if Parameter then
    if Item^.Code = ParameterCode then
    begin
      Result := OptimizeParameterArray(Index + SizeOf(TCode), Script) and AFunction.Optimizable;
      Offset := SizeOf(TCode) + Item^.Script.Header.ScriptSize;
      if Result then
      begin
        Script := nil;
        Inc(Index, Offset);
      end;
    end
    else
      raise Error(ScriptError)
  else begin
    Result := (AFunction.Method.Parameter.L xor not Number) and AFunction.Optimizable;
    if Result and AFunction.Method.Parameter.R then
      case Item^.Code of
        NumberCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
        FunctionCode: Result := Optimizable(Index, False, Offset, Parameter, Script);
        ScriptCode:
          begin
            InternalOptimizeScript(NativeInt(@Item^.Script.Header), Script);
            Result := Optimal(Script, stScript);
            Offset := SizeOf(TCode) + Item^.Script.Header.ScriptSize;
            if Result then
            begin
              Item^.Script.Header.Value := ExecuteScript(Script)^;
              Script := nil;
              Inc(Index, Offset);
            end;
          end;
      else
        raise Error(ScriptError);
      end;
  end;
end;

procedure TParser.OptimizeScript(const Source: TScript; out Target: TScript);
begin
  InternalOptimizeScript(NativeInt(Source), Target);
end;

procedure TParser.OptimizeScript;
begin
  OptimizeScript(FScript);
end;

procedure TParser.OptimizeScript(var Script: TScript);
var
  Target: TScript;
begin
  OptimizeScript(Script, Target);
  Script := Target;
end;

function TParser.OptimizeParameterArray(Index: NativeInt; out Script: TScript): Boolean;
var
  Data: TPOData;
begin
  FillChar(Data, SizeOf(TPOData), 0);
  Data.Optimal := True;
  try
    ParseScript(Index, POMethod, @Data);
    Result := Data.Optimal;
    BuildScript(Self, Data.ItemArray, Script, False);
  finally
    Delete(Data.ItemArray);
  end;
end;

function TParser.Order(const Coverage: TPriorityCoverage; var ItemArray: TTextItemArray1;
  var SA: TScriptArray; var Idle: PFunction): Boolean;

  function Peek(const FHandle: NativeInt; const IgnorePriority: Boolean; out AFunction: PFunction): Boolean;
  begin
    if FHandle < 0 then
      AFunction := nil
    else
      AFunction := GetFunction(FHandle);
    Result := Assigned(AFunction) and (IgnorePriority or (AFunction.Priority.Priority <> fpNormal) and
      (AFunction.Priority.Coverage = Coverage) and (not Assigned(Idle) or (Idle <> AFunction))) and
      (AFunction.Method.Parameter.L or AFunction.Method.Parameter.R);
  end;

  function Prefix(const ItemArray: TTextItemArray1; const Index: Integer): Boolean;
  var
    AFunction: PFunction;
  begin
    Result := (Index >= Low(ItemArray)) and (Index <= High(ItemArray)) and
      GetFunction(ItemArray[Index].FHandle, AFunction) and AFunction.Method.Parameter.R and
      not AFunction.Method.Parameter.L;
  end;

  function Match(const AArray, BArray: TTextItemArray1): Boolean;
  var
    I: Integer;
  begin
    Result := (Length(AArray) = Length(BArray));
    if Result then
      for I := Low(AArray) to High(AArray) do
      begin
        Result := Same(AArray[I].Text, BArray[I].Text) and (AArray[I].FHandle = BArray[I].FHandle);
        if not Result then Break;
      end;
  end;

  function ItemText(const Item: PTextItem): string;
  var
    AType: PType;
  begin
    if GetType(Item.THandle, AType) then
      Result := string(AType.Name) + Space + Item.Text
    else
      Result := Item.Text;
  end;

type
  TArray1 = record
    A, B: TTextItemArray1;
    Data: TArrayData;
  end;
var
  I, J, K, Index: Integer;
  L: array[Boolean] of Integer;
  Flag: Boolean;
  AFunction, BFunction: PFunction;
  S, AItem, BItem: string;
  Array1: TArray1;
begin
  Result := Assigned(ItemArray);
  if Result then
  begin
    FillChar(L, SizeOf(L), 0);
    for I := Low(ItemArray) to High(ItemArray) do
      if ItemArray[I].FHandle >= 0 then
      begin
        for Flag := False to True do if Peek(ItemArray[I].FHandle, Flag, AFunction) then
        begin
          Inc(L[Flag]);
          Break;
        end;
        if (L[False] > 0) and (L[True] > 0) or (L[False] > 1) then Break;
      end;
    Result := (L[False] > 0) and (L[True] > 0) or (L[False] > 1);
    if Result then
    begin
      FillChar(Array1, SizeOf(TArray1), 0);
      I := 0;
      while I < Length(ItemArray) do
      begin
        if Peek(ItemArray[I].FHandle, False, AFunction) then
        begin
          Array1.A := nil;
          case AFunction.Priority.Priority of
            fpLower:
              begin
                if AFunction.Method.Parameter.L then
                  if (I - 1 = Low(ItemArray)) and ((ItemArray[I - 1].FHandle < 0) or
                    (ItemArray[I - 1].FHandle = FInternalHandle)) then
                      AddItem(Array1.A, ItemArray[I - 1])
                  else begin
                    S := '';
                    for J := Low(ItemArray) to I - 1 do
                      if J = Low(ItemArray) then
                        S := ItemText(@ItemArray[J])
                      else
                        S := S + Space + ItemText(@ItemArray[J]);
                    J := AFunction.Handle^;
                    S := Embrace(IntToStr(AddScript(SA, InternalCompile(Trim(S), SA, False, Idle))),
                      BracketArray[bkBrace]);
                    if not GetFunction(J, AFunction) then raise Error(ScriptError);
                    AddItem(Array1.A, S, FInternalHandle, -1);
                  end
                else begin
                  Reset(Array1.A, Array1.Data);
                  try
                    for J := Low(ItemArray) to I - 1 do
                      AddItem(Array1.A, Array1.Data, ItemArray[J]);
                  finally
                    Apply(Array1.A, Array1.Data);
                  end;
                end;
                Index := AddItem(Array1.A, ItemArray[I]);
                if AFunction.Method.Parameter.R then
                begin
                  if (I + 1 = High(ItemArray)) and ((ItemArray[I + 1].FHandle < 0) or
                    (ItemArray[I + 1].FHandle = FInternalHandle)) then
                      AddItem(Array1.A, ItemArray[I + 1])
                  else begin
                    S := '';
                    for J := I + 1 to High(ItemArray) do
                      if J = I + 1 then
                        S := ItemText(@ItemArray[J])
                      else
                        S := S + Space + ItemText(@ItemArray[J]);
                    J := AFunction.Handle^;
                    S := Embrace(IntToStr(AddScript(SA, InternalCompile(Trim(S), SA, False, Idle))),
                      BracketArray[bkBrace]);
                    if not GetFunction(J, AFunction) then raise Error(ScriptError);
                    AddItem(Array1.A, S, FInternalHandle, -1);
                  end;
                  ItemArray := Array1.A;
                  Break;
                end
                else begin
                  Reset(Array1.A, Array1.Data);
                  try
                    for J := I + 1 to High(ItemArray) do
                      AddItem(Array1.A, Array1.Data, ItemArray[J]);
                  finally
                    Apply(Array1.A, Array1.Data);
                  end;
                end;
                I := Index + 1;
              end;
          else
            AItem := '';
            BItem := '';
            try
              if AFunction.Method.Parameter.L then
              begin
                for J := I - 1 downto Low(ItemArray) do
                begin
                  if J = I - 1 then
                    AItem := ItemText(@ItemArray[J])
                  else
                    AItem := ItemText(@ItemArray[J]) + Space + AItem;
                  AddItem(Array1.B, ItemArray[J]);
                  if (not GetFunction(ItemArray[J].FHandle, BFunction) or
                    not BFunction.Method.Parameter.L) and not Prefix(ItemArray, J - 1) then
                    begin
                      Reset(Array1.A, Array1.Data);
                      try
                        for K := Low(ItemArray) to J - 1 do
                          AddItem(Array1.A, Array1.Data, ItemArray[K]);
                      finally
                        Apply(Array1.A, Array1.Data);
                      end;
                      Break;
                    end;
                end;
                AItem := Trim(AItem);
              end
              else begin
                Reset(Array1.A, Array1.Data);
                try
                  for J := Low(ItemArray) to I - 1 do AddItem(Array1.A, Array1.Data, ItemArray[J]);
                finally
                  Apply(Array1.A, Array1.Data);
                end;
              end;
              Index := AddItem(Array1.A, '', -1, -1);
              AddItem(Array1.B, ItemArray[I]);
              if AFunction.Method.Parameter.R then
              begin
                for J := I + 1 to High(ItemArray) do
                begin
                  if J = I + 1 then
                    BItem := ItemText(@ItemArray[J])
                  else
                    BItem := BItem + Space + ItemText(@ItemArray[J]);
                  AddItem(Array1.B, ItemArray[J]);
                  if not GetFunction(ItemArray[J].FHandle, BFunction) or
                    not BFunction.Method.Parameter.R then
                    begin
                      Reset(Array1.A, Array1.Data);
                      try
                        for K := J + 1 to High(ItemArray) do
                          AddItem(Array1.A, Array1.Data, ItemArray[K]);
                      finally
                        Apply(Array1.A, Array1.Data);
                      end;
                      Break;
                    end;
                end;
                BItem := Trim(BItem);
              end
              else begin
                Reset(Array1.A, Array1.Data);
                try
                  for J := I + 1 to High(ItemArray) do AddItem(Array1.A, Array1.Data, ItemArray[J]);
                finally
                  Apply(Array1.A, Array1.Data);
                end;
              end;
              S := AFunction.Name;
              if AItem <> '' then S := AItem + Space + S;
              if BItem <> '' then S := S + Space + BItem;
              if Match(ItemArray, Array1.B) then
                Break
              else begin
                S := Embrace(IntToStr(AddScript(SA, InternalCompile(S, SA, False, AFunction))),
                  BracketArray[bkBrace]);
                Array1.A[Index] := MakeTextItem(S, FInternalHandle, -1);
              end;
            finally
              Array1.B := nil;
            end;
          end;
          ItemArray := Array1.A;
        end
        else
          Inc(I);
      end;
    end;
  end;
end;

function TParser.OSMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
var
  Data: POSData;
  Start, I, J, Offset: NativeInt;
  Parameter: Boolean;
  Script: TScript;
begin
  Data := P;
  Start := NativeInt(ItemHeader);
  if (Index - Start = SizeOf(TItemHeader)) or not Assigned(Data.ItemArray) then
  begin
    I := AddScript(Data.ItemArray, nil);
    Resize(Data.ItemArray[I], SizeOf(TItemHeader));
  end
  else
    I := High(Data.ItemArray);
  case Item.Code of
    NumberCode:
      begin
        Data.Number := MakeNumber(Item.ScriptNumber.Value, True);
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
      end;
    FunctionCode:
      begin
        J := Index;
        try
          if Optimizable(Index, Data.Number.Valid, Offset, Parameter, Script) then
          begin
            Data.Number.Value := ExecuteFunction(J, Header, ItemHeader, Data.Number.Value);
            Data.Number.Valid := True;
          end
          else begin
            if Data.Number.Valid then
            begin
              WriteNumber(Data.ItemArray[I], Data.Number.Value);
              Data.Number.Valid := False;
            end;
            AddMemory(Data.ItemArray[I], PAnsiChar(J), Index - J);
            if Assigned(Script) then
            begin
              WriteScript(Data.ItemArray[I], Script, Parameter);
              Inc(Index, Offset);
            end;
          end;
        finally
          Script := nil;
        end;
      end;
    ScriptCode:
      begin
        InternalOptimizeScript(NativeInt(@Item.Script.Header), Script);
        try
          Data.Number.Valid := Optimal(Script, stScript);
          if Data.Number.Valid then
            Data.Number.Value := ExecuteScript(Script)^
          else
            WriteScript(Data.ItemArray[I], Script, False);
        finally
          Script := nil;
        end;
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
  else
    raise Error(ScriptError);
  end;
  if Index - Start >= ItemHeader.Size then
  begin
    if Data.Number.Valid then
    begin
      WriteNumber(Data.ItemArray[I], Data.Number.Value);
      Data.Number.Valid := False;
    end;
    PItemHeader(Data.ItemArray[I])^ := ItemHeader^;
    PItemHeader(Data.ItemArray[I]).Size := Length(Data.ItemArray[I]);
  end;
  Result := True;
end;

function TParser.PAMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
var
  Data: PPAData;
  I, J, Start: NativeInt;
begin
  Data := P;
  Start := NativeInt(ItemHeader);
  I := -1;
  case Item.Code of
    NumberCode:
      begin
        if not Data.Idle then
          I := AddParameter(Data.PA^, Data.AD, ItemHeader.UserType.Handle, Item.ScriptNumber.Value);
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
      end;
    FunctionCode:
      begin
        if Data.Idle then
          ExecuteFunction(Index, Header, ItemHeader, EmptyValue, Data.Idle)
        else
          I := AddParameter(Data.PA^, Data.AD, ItemHeader.UserType.Handle,
            ExecuteFunction(Index, Header, ItemHeader, EmptyValue));
      end;
    StringCode:
      begin
        if not Data.Idle then
        begin
          I := AddParameter(Data.PA^, Data.AD, ItemHeader.UserType.Handle, '');
          J := Item.ScriptString.Size;
          if J > SizeOf(TString) - SizeOf(Char) then J := SizeOf(TString) - SizeOf(Char);
          ZeroMemory(@Data.PA^[I].Text, SizeOf(TString));
          CopyMemory(@Data.PA^[I].Text, PAnsiChar(Index) + SizeOf(TCode) + SizeOf(TScriptString), J);
        end;
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
      end;
    ScriptCode:
      begin
        if not Data.Idle then
          I := AddParameter(Data.PA^, Data.AD, ItemHeader.UserType.Handle,
            ExecuteScript(NativeInt(@Item.Script.Header))^);
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
  else
    raise Error(ScriptError);
  end;
  if Index - Start >= ItemHeader.Size then
  begin
    if (I >= 0) and Boolean(ItemHeader.Sign) then Data.PA^[I].Value := Negative(Data.PA^[I].Value);
    Data.Index^ := Index;
  end;
  Result := True;
end;

procedure TParser.Parse(var Text: string; var SA: TScriptArray; var Idle: PFunction; out Error: TError);
var
  Data: TBracketData;
  I: Boolean;
begin
  FillChar(Error, SizeOf(TError), 0);
  Data := MakeBracketData(@SA, False, Idle);
  Data.Text := TTextBuilder.Create;
  try
    for I := Low(Boolean) to High(Boolean) do
    begin
      Data.Parameter := I;
      if Data.Parameter then
        ParseBracket(Text, FParameterBracket, ParseMethod, @Data, Error)
      else
        ParseBracket(Text, FBracket, ParseMethod, @Data, Error);
      if Error.ErrorType <> etOK then Break;
    end;
  finally
    Data.Text.Free;
  end;
end;

procedure TParser.Parse(var Text: string; var SA: TScriptArray; var Idle: PFunction);
var
  Error: TError;
begin
  Parse(Text, SA, Idle, Error);
  if Error.ErrorType <> etOK then raise ParseErrors.Error(Error.ErrorText);
end;

function TParser.ParseMethod(var Text: string; const FromIndex, TillIndex: NativeInt;
  const P: Pointer): TError;
var
  S: string;
  Data: PBracketData;
  I: NativeInt;
begin
  S := Trim(Copy(Text, FromIndex + 1, TillIndex - FromIndex - 1));
  if S <> '' then
  begin
    Data := P;
    I := AddScript(Data.SA^, InternalCompile(S, Data.SA^, Data.Parameter, Data.Idle, Result));
    if Result.ErrorType <> etOK then Exit;
    if Data.Parameter then
      S := ParameterPrefix
    else
      S := '';
    try
      Data.Text.Append(Copy(Text, 1, FromIndex - 1));
      Data.Text.Append(Embrace(S + IntToStr(I), BracketArray[bkBrace]));
      Data.Text.Append(Copy(Text, TillIndex + 1, MaxInt));
      Text := Data.Text.Text;
    finally
      Data.Text.Clear;
    end;
  end
  else begin
    Result := MakeError(etTextError, EText(TextError, [Text]));
    Exit;
  end;
  FillChar(Result, SizeOf(TError), 0);
end;

function TParser.POMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
var
  Data: PPOData;
  Start, I, J, Offset: NativeInt;
  Parameter: Boolean;
  Script: TScript;
begin
  Data := P;
  Start := NativeInt(ItemHeader);
  if (Index - Start = SizeOf(TItemHeader)) or not Assigned(Data.ItemArray) then
  begin
    I := AddScript(Data.ItemArray, nil);
    Resize(Data.ItemArray[I], SizeOf(TItemHeader));
  end
  else
    I := High(Data.ItemArray);
  case Item.Code of
    NumberCode:
      begin
        WriteNumber(Data.ItemArray[I], Item.ScriptNumber.Value);
        Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
      end;
    FunctionCode:
      begin
        J := Index;
        try
          if Optimizable(Index, False, Offset, Parameter, Script) then
            WriteNumber(Data.ItemArray[I], ExecuteFunction(J, Header, ItemHeader, EmptyValue))
          else begin
            AddMemory(Data.ItemArray[I], PAnsiChar(J), Index - J);
            if Assigned(Script) then
            begin
              WriteScript(Data.ItemArray[I], Script, Parameter);
              Inc(Index, Offset);
            end;
            Data.Optimal := False;
          end;
        finally
          Script := nil;
        end;
      end;
    StringCode:
      begin
        J := SizeOf(TCode) + SizeOf(TScriptString);
        WriteString(Data.ItemArray[I], PAnsiChar(Index) + J, Item.ScriptString.Size);
        Inc(Index, J + Item.ScriptString.Size);
      end;
    ScriptCode:
      begin
        InternalOptimizeScript(NativeInt(@Item.Script.Header), Script);
        try
          if Optimal(Script, stScript) then
            WriteNumber(Data.ItemArray[I], ExecuteScript(Script)^)
          else begin
            WriteScript(Data.ItemArray[I], Script, False);
            Data.Optimal := False;
          end;
        finally
          Script := nil;
        end;
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
  else
    raise Error(ScriptError);
  end;
  if Index - NativeInt(ItemHeader) >= ItemHeader.Size then
  begin
    PItemHeader(Data.ItemArray[I])^ := ItemHeader^;
    PItemHeader(Data.ItemArray[I]).Size := Length(Data.ItemArray[I]);
  end;
  Result := True;
end;

procedure TParser.ReadParameterArray(var Index: NativeInt; out PA: TParameterArray;
  const ParameterType: TParameterType; const Idle: Boolean);
var
  Data: TPAData;
begin
  Data := MakePAData(Idle, @PA, @Index);
  case ParameterType of
    ptParameter:
      begin
        Reset(Data.PA^, Data.AD);
        try
          ParseScript(Index, PAMethod, @Data);
        finally
          Apply(Data.PA^, Data.AD);
        end;
      end;
    ptScript:
      begin
        Reset(Data.PA^, Data.AD);
        try
          ParseScript(Index, SAMethod, @Data);
        finally
          Apply(Data.PA^, Data.AD);
        end;
      end;
  end;
end;

function TParser.SAMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
var
  Data: PPAData;
  Start: NativeInt;
  Value: TValue;
begin
  Data := P;
  Start := NativeInt(ItemHeader);
  if not Data.Idle then
  begin
    with Value do
    begin
      NativeIntRec.Lo := System.NativeInt(Item);
      NativeIntRec.Hi := System.NativeInt(ItemHeader);
      ValueType := vtInt64;
    end;
    AddParameter(Data.PA^, Data.AD, ItemHeader.UserType.Handle, Value);
  end;
  case Item.Code of
    NumberCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
    FunctionCode: ExecuteFunction(Index, Header, ItemHeader, EmptyValue, True);
    StringCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
    ScriptCode: Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
  else
    raise Error(ScriptError);
  end;
  if Index - Start >= ItemHeader.Size then Data.Index^ := Index;
  Result := True;
end;

function TParser.SCMethod(var Index: NativeInt; const Header: PScriptHeader; const ItemHeader: PItemHeader;
  const Item: PScriptItem; const P: Pointer): Boolean;
begin
  case Item.Code of
    NumberCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptNumber));
    FunctionCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptFunction));
    StringCode: Inc(Index, SizeOf(TCode) + SizeOf(TScriptString) + Item.ScriptString.Size);
    ScriptCode, ParameterCode:
      begin
        PScriptHeader(Index + SizeOf(TCode)).RedirectCategory := Header.RedirectCategory;
        ParseScript(Index + SizeOf(TCode), SCMethod, P);
        Inc(Index, SizeOf(TCode) + Item.Script.Header.ScriptSize);
      end;
  else
    raise Error(ScriptError);
  end;
  Result := True;
end;

function RedirectCompare(Item1, Item2: Pointer): Integer;
var
  Redirect1: PRedirect absolute Item1;
  Redirect2: PRedirect absolute Item2;
begin
  Result := CompareValue(Redirect1.Category, Redirect2.Category);
  if Result = EqualsValue then Result := CompareValue(Redirect1.Source, Redirect2.Source);
end;

function TParser.SetRedirect(const Index: Integer; const Category, Source, Target: NativeInt): Boolean;
var
  I: Integer;
  P: PRedirect;
begin
  for I := 0 to FRedirectList.Count - 1 do
  begin
    P := PRedirect(FRedirectList[I]);
    Result := P.Index = Index;
    if Result then
    begin
      P.Category := Category;
      P.Source := Source;
      P.Target := Target;
      FRedirectList.Sort(RedirectCompare);
      Exit;
    end;
  end;
  Result := False;
end;

procedure TParser.SetRedirectCategory(const Script: TScript; const RedirectCategory: NativeInt);
begin
  PScriptHeader(Script).RedirectCategory := RedirectCategory;
  ParseScript(NativeInt(Script), SCMethod, nil);
end;

function TParser.ScriptToString(const Script: TScript; const Delimiter: string;
  const TypeMode: TRetrieveMode): string;
begin
  Result := ScriptToString(Script, Delimiter, FBracket, TypeMode);
end;

function TParser.ScriptToString(const Script: TScript; const TypeMode: TRetrieveMode): string;
begin
  Result := ScriptToString(Script, Space, FBracket, TypeMode);
end;

function TParser.ScriptToString(const TypeMode: TRetrieveMode): string;
begin
  Result := ScriptToString(FScript, TypeMode);
end;

function TParser.ScriptToString(const Script: TScript; const Delimiter: string; const ABracket: TBracket;
  const TypeMode: TRetrieveMode): string;
begin
  Result := InternalDecompile(NativeInt(Script), Delimiter, False, ABracket, TypeMode);
end;

procedure TParser.StringToScriptInto(const Text: string; var Script: TScript);
var
  Fresh: TScript;
begin
  if FCached and Assigned(FCache.Rawscript) then
  begin
    Enter(FCache.Rawscript.Lock^);
    try
      if FCache.Rawscript.FindInto(Text, Script) then Exit;
    finally
      Leave(FCache.Rawscript.Lock^);
    end;
  end;
  Fresh := nil;
  StringToScript(Text, Fresh);
  Script := Fresh;
end;

procedure TParser.StringToScript(const Text: string; out Script: TScript);
var
  Error: TError;
begin
  StringToScript(Text, Script, Error);
  if Error.ErrorType <> etOK then raise ParseErrors.Error(Error.ErrorText);
end;

procedure TParser.StringToScript(const Text: string; out Script: TScript; out Error: TError);
const
  ScriptSize = SizeOf(TScriptHeader) + SizeOf(TItemHeader) + SizeOf(TCode);
var
  AText: string;
  Idle: PFunction;
  SA: TScriptArray;
begin
  Script := nil;
  if FCached and Assigned(FCache.Rawscript) then
  begin
    Enter(FCache.Rawscript.Lock^);
    try
      Script := FCache.Rawscript.Find(Text);
    finally
      Leave(FCache.Rawscript.Lock^);
    end;
  end;
  if not Assigned(Script) then
  begin
    AText := Trim(Text);
    Error := Validator.Check(AText, rtText);
    if Error.ErrorType <> etOK then Exit;
    ParseUtils.Prepare(FFData);
    if ParseUtils.Prepare(FTData) then
      FDefaultTypeHandle := MakeTypeHandle(FTData^, FDefaultValueType, -1);
    Error := Check(AText);
    if Error.ErrorType <> etOK then Exit;
    ChangeBracket(AText, FFData, FBracket, FParameterBracket);
    Idle := nil;
    try
      try
        Script := InternalCompile(AText, SA, False, Idle, Error);
      except
        on E: Exception do Error := MakeError(etUnknown, E.Message);
      end;
      if Error.ErrorType <> etOK then Exit;
    finally
      Delete(SA);
    end;
    if Length(Script) < ScriptSize then
    begin
      Error := MakeError(etSizeError, SizeError);
      Exit;
    end;
    if FCached and Assigned(FCache.Rawscript) then
    begin
      Enter(FCache.Rawscript.Lock^);
      try
        FCache.Rawscript.Add(Text, Script);
      finally
        Leave(FCache.Rawscript.Lock^);
      end;
    end;
  end;
  FillChar(Error, SizeOf(TError), 0);
end;

procedure TParser.StringToScript;
begin
  StringToScript(FText, FScript);
end;

procedure TParser.StringToScript(const Text: string);
begin
  StringToScript(Text, FScript);
end;

constructor TMathParser.Create(AOwner: TComponent);
begin
  inherited;
  FMathMethod := TMathMethod.Create(Self);
  BeginUpdate;
  try
    InternalAddFunction(IntegerDivideFunctionName, FDivHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DivMethod), True);
    InternalAddFunction(ReminderFunctionName, FModHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ModMethod), True);
    InternalAddFunction(DegreeFunctionName, FDegreeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DegreeMethod), True, vtUnknown, fpHigher, pcLocal);
    InternalAddFunction(FactorialFunctionName, FFactorialHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.FactorialMethod, FactorialParameterCount), True);
    InternalAddFunction(SqrFunctionName, FSqrHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SqrMethod, False, True), True);
    InternalAddFunction(SqrtFunctionName, FSqrtHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SqrtMethod, False, True), True);
    InternalAddFunction(IntFunctionName, FIntHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.IntMethod, False, True), True);
    InternalAddFunction(RoundFunctionName, FRoundHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RoundMethod, False, True), True);
    InternalAddFunction(RoundToFunctionName, FRoundToHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RoundToMethod, RoundToParameterCount), True);
    InternalAddFunction(TruncFunctionName, FTruncHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.TruncMethod, False, True), True);
    InternalAddFunction(AbsFunctionName, FAbsHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.AbsMethod, False, True), True);
    InternalAddFunction(FracFunctionName, FFracHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.FracMethod, False, True), True);
    InternalAddFunction(LnFunctionName, FLnHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.LnMethod, False, True), True);
    InternalAddFunction(LgFunctionName, FLgHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.LgMethod, False, True), True);
    InternalAddFunction(LogFunctionName, FLogHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.LogMethod), True);
    InternalAddFunction(ExpFunctionName, FExpHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ExpMethod, False, True), True);
    InternalAddFunction(RandomFunctionName, FRandomHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RandomMethod, False, True), False);
    InternalAddFunction(SinFunctionName, FSinHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SinMethod, False, True), True);
    InternalAddFunction(ArcSinFunctionName, FArcSinHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcSinMethod, False, True), True);
    InternalAddFunction(SinHFunctionName, FSinHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SinHMethod, False, True), True);
    InternalAddFunction(ArcSinHFunctionName, FArcSinHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcSinHMethod, False, True), True);
    InternalAddFunction(CosFunctionName, FCosHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CosMethod, False, True), True);
    InternalAddFunction(ArcCosFunctionName, FArcCosHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcCosMethod, False, True), True);
    InternalAddFunction(CosHFunctionName, FCosHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CosHMethod, False, True), True);
    InternalAddFunction(ArcCosHFunctionName, FArcCosHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcCosHMethod, False, True), True);
    InternalAddFunction(TanFunctionName, FTanHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.TanMethod, False, True), True);
    InternalAddFunction(ArcTanFunctionName, FArcTanHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcTanMethod, False, True), True);
    InternalAddFunction(TanHFunctionName, FTanHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.TanHMethod, False, True), True);
    InternalAddFunction(ArcTanHFunctionName, FArcTanHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcTanHMethod, False, True), True);
    InternalAddFunction(CoTanFunctionName, FCoTanHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CoTanMethod, False, True), True);
    InternalAddFunction(ArcCotanFunctionName, FArcCoTanHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcCoTanMethod, False, True), True);
    InternalAddFunction(CotanHFunctionName, FCoTanHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CoTanHMethod, False, True), True);
    InternalAddFunction(ArcCotanHFunctionName, FArcCoTanHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcCoTanHMethod, False, True), True);
    InternalAddFunction(SecFunctionName, FSecHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecMethod, False, True), True);
    InternalAddFunction(ArcSecFunctionName, FArcSecHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcSecMethod, False, True), True);
    InternalAddFunction(SecHFunctionName, FSecHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecHMethod, False, True), True);
    InternalAddFunction(ArcSecHFunctionName, FArcSecHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcSecHMethod, False, True), True);
    InternalAddFunction(CscFunctionName, FCscHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CscMethod, False, True), True);
    InternalAddFunction(ArcCscFunctionName, FArcCscHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcCscMethod, False, True), True);
    InternalAddFunction(CscHFunctionName, FCscHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CscHMethod, False, True), True);
    InternalAddFunction(ArcCscHFunctionName, FArcCscHHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcCscHMethod, False, True), True);
    InternalAddFunction(ArcTan2FunctionName, FArcTan2Handle, fkMethod,
      MakeFunctionMethod(FMathMethod.ArcTan2Method, ArcTan2ParameterCount), True);
    InternalAddFunction(HypotFunctionName, FHypotHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HypotMethod, HypotParameterCount), True);
    InternalAddFunction(RadToDegFunctionName, FRadToDegHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RadToDegMethod, False, True), True);
    InternalAddFunction(RadToGradFunctionName, FRadToGradHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RadToGradMethod, False, True), True);
    InternalAddFunction(RadToCycleFunctionName, FRadToCycleHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RadToCycleMethod, False, True), True);
    InternalAddFunction(DegToRadFunctionName, FDegToRadHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DegToRadMethod, False, True), True);
    InternalAddFunction(DegToGradFunctionName, FDegToGradHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DegToGradMethod, False, True), True);
    InternalAddFunction(DegToCycleFunctionName, FDegToCycleHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DegToCycleMethod, False, True), True);
    InternalAddFunction(GradToRadFunctionName, FGradToRadHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GradToRadMethod, False, True), True);
    InternalAddFunction(GradToDegFunctionName, FGradToDegHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GradToDegMethod, False, True), True);
    InternalAddFunction(GradToCycleFunctionName, FGradToCycleHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GradToCycleMethod, False, True), True);
    InternalAddFunction(CycleToRadFunctionName, FCycleToRadHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CycleToRadMethod, False, True), True);
    InternalAddFunction(CycleToDegFunctionName, FCycleToDegHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CycleToDegMethod, False, True), True);
    InternalAddFunction(CycleToGradFunctionName, FCycleToGradHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CycleToGradMethod, False, True), True);
    InternalAddFunction(LnXP1FunctionName, FLnXP1Handle, fkMethod,
      MakeFunctionMethod(FMathMethod.LnXP1Method, False, True), True);
    InternalAddFunction(Log10FunctionName, FLog10Handle, fkMethod,
      MakeFunctionMethod(FMathMethod.Log10Method, False, True), True);
    InternalAddFunction(Log2FunctionName, FLog2Handle, fkMethod,
      MakeFunctionMethod(FMathMethod.Log2Method, False, True), True);
    InternalAddFunction(IntPowerFunctionName, FIntPowerHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.IntPowerMethod, IntPowerParameterCount), True);
    InternalAddFunction(PowerFunctionName, FPowerHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.PowerMethod), True, vtUnknown, fpHigher, pcLocal);
    InternalAddFunction(RootFunctionName, FRootHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RootMethod), True, vtUnknown, fpHigher, pcLocal);
    InternalAddFunction(LdexpFunctionName, FLdexpHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.LdexpMethod, LdexpParameterCount), True);
    InternalAddFunction(CeilFunctionName, FCeilHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CeilMethod, False, True), True);
    InternalAddFunction(FloorFunctionName, FFloorHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.FloorMethod, False, True), True);
    InternalAddFunction(PolyFunctionName, FPolyHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.PolyMethod, PolyParameterCount), True);
    InternalAddFunction(MeanFunctionName, FMeanHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MeanMethod, MeanParameterCount), True);
    InternalAddFunction(SumFunctionName, FSumHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SumMethod, SumParameterCount), True);
    InternalAddFunction(SumIntFunctionName, FSumIntHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SumIntMethod, SumIntParameterCount), True);
    InternalAddFunction(SumOfSquaresFunctionName, FSumOfSquaresHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SumOfSquaresMethod, SumOfSquaresParameterCount), True);
    InternalAddFunction(MinValueFunctionName, FMinValueHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinValueMethod, MinValueParameterCount), True);
    InternalAddFunction(MinIntValueFunctionName, FMinIntValueHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinIntValueMethod, MinIntValueParameterCount), True);
    InternalAddFunction(MinFunctionName, FMinHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinMethod, ParameterMinCount), True);
    InternalAddFunction(MaxValueFunctionName, FMaxValueHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MaxValueMethod, MaxValueParameterCount), True);
    InternalAddFunction(MaxIntValueFunctionName, FMaxIntValueHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MaxIntValueMethod, MaxIntValueParameterCount), True);
    InternalAddFunction(MaxFunctionName, FMaxHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MaxMethod, ParameterMaxCount), True);
    InternalAddFunction(StdDevFunctionName, FStdDevHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.StdDevMethod, StdDevParameterCount), True);
    InternalAddFunction(PopnStdDevFunctionName, FPopnStdDevHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.PopnStdDevMethod, PopnStdDevParameterCount), True);
    InternalAddFunction(VarianceFunctionName, FVarianceHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.VarianceMethod, VarianceParameterCount), True);
    InternalAddFunction(PopnVarianceFunctionName, FPopnVarianceHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.PopnVarianceMethod, PopnVarianceParameterCount), True);
    InternalAddFunction(TotalVarianceFunctionName, FTotalVarianceHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.TotalVarianceMethod, TotalVarianceParameterCount), True);
    InternalAddFunction(NormFunctionName, FNormHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.NormMethod, NormParameterCount), True);
    InternalAddFunction(RandGFunctionName, FRandGHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RandGMethod, RandGParameterCount), True);
    InternalAddFunction(RandomRangeFunctionName, FRandomRangeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RandomRangeMethod, RandomRangeParameterCount), False);
    InternalAddFunction(RandomFromFunctionName, FRandomFromHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.RandomFromMethod, RandomFromParameterCount), False);
    InternalAddFunction(DateTimeFunctionName, FDateTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DateTimeMethod), False, vtDouble);
    InternalAddFunction(DateFunctionName, FDateHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DateMethod), False, vtDouble);
    InternalAddFunction(TimeFunctionName, FTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.TimeMethod), False, vtDouble);
    InternalAddFunction(YearFunctionName, FYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.YearMethod), False, vtWord);
    InternalAddFunction(MonthFunctionName, FMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MonthMethod), False, vtWord);
    InternalAddFunction(DayFunctionName, FDayHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DayMethod), False, vtWord);
    InternalAddFunction(DayOfWeekFunctionName, FDayOfWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DayOfWeekMethod), False, vtWord);
    InternalAddFunction(HourFunctionName, FHourHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HourMethod), False, vtWord);
    InternalAddFunction(MinuteFunctionName, FMinuteHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteMethod), False, vtWord);
    InternalAddFunction(SecondFunctionName, FSecondHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondMethod), False, vtWord);
    InternalAddFunction(MilliSecondFunctionName, FMilliSecondHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondMethod), False, vtWord);
    InternalAddFunction(GetYearFunctionName, FGetYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetYearMethod, GetYearParameterCount), True, vtWord);
    InternalAddFunction(GetMonthFunctionName, FGetMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetMonthMethod, GetMonthParameterCount), True, vtWord);
    InternalAddFunction(GetDayFunctionName, FGetDayHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetDayMethod, GetDayParameterCount), True, vtWord);
    InternalAddFunction(GetDayOfWeekFunctionName, FGetDayOfWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetDayOfWeekMethod, GetDayOfWeekParameterCount), True, vtWord);
    InternalAddFunction(GetHourFunctionName, FGetHourHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetHourMethod, GetHourParameterCount), True, vtWord);
    InternalAddFunction(GetMinuteFunctionName, FGetMinuteHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetMinuteMethod, GetMinuteParameterCount), True, vtWord);
    InternalAddFunction(GetSecondFunctionName, FGetSecondHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetSecondMethod, GetSecondParameterCount), True, vtWord);
    InternalAddFunction(GetMilliSecondFunctionName, FGetMilliSecondHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetMilliSecondMethod, GetMilliSecondParameterCount), True, vtWord);
    InternalAddFunction(EncodeDateTimeFunctionName, FEncodeDateTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.EncodeDateTimeMethod, EncodeDateTimeParameterCount), True, vtDouble);
    InternalAddFunction(EncodeDateFunctionName, FEncodeDateHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.EncodeDateMethod, EncodeDateParameterCount), True, vtDouble);
    InternalAddFunction(EncodeTimeFunctionName, FEncodeTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.EncodeTimeMethod, EncodeTimeParameterCount), True, vtDouble);
    InternalAddFunction(StrToDateTimeFunctionName, FStrToDateTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.StrToDateTimeMethod, StrToDateTimeParameterCount), False, vtDouble);
    InternalAddFunction(StrToDateFunctionName, FStrToDateHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.StrToDateMethod, StrToDateParameterCount), False, vtDouble);
    InternalAddFunction(StrToTimeFunctionName, FStrToTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.StrToTimeMethod, StrToTimeParameterCount), False, vtDouble);
    InternalAddFunction(DateOfFunctionName, FDateOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DateOfMethod, False, True), True, vtDouble);
    InternalAddFunction(TimeOfFunctionName, FTimeOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.TimeOfMethod, False, True), True, vtDouble);
    InternalAddFunction(YearOfFunctionName, FYearOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.YearOfMethod, False, True), True, vtWord);
    InternalAddFunction(MonthOfFunctionName, FMonthOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MonthOfMethod, False, True), True, vtWord);
    InternalAddFunction(WeekOfFunctionName, FWeekOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.WeekOfMethod, False, True), True, vtWord);
    InternalAddFunction(DayOfFunctionName, FDayOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DayOfMethod, False, True), True, vtWord);
    InternalAddFunction(HourOfFunctionName, FHourOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HourOfMethod, False, True), True, vtWord);
    InternalAddFunction(MinuteOfFunctionName, FMinuteOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteOfMethod, False, True), True, vtWord);
    InternalAddFunction(SecondOfFunctionName, FSecondOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfMethod, False, True), True, vtWord);
    InternalAddFunction(MilliSecondOfFunctionName, FMilliSecondOfHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfMethod, False, True), True, vtWord);
    InternalAddFunction(YearsBetweenFunctionName, FYearsBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.YearsBetweenMethod, YearsBetweenParameterCount), True, vtInteger);
    InternalAddFunction(MonthsBetweenFunctionName, FMonthsBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MonthsBetweenMethod, MonthsBetweenParameterCount), True, vtInteger);
    InternalAddFunction(WeeksBetweenFunctionName, FWeeksBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.WeeksBetweenMethod, WeeksBetweenParameterCount), True, vtInteger);
    InternalAddFunction(DaysBetweenFunctionName, FDaysBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DaysBetweenMethod, DaysBetweenParameterCount), True, vtInteger);
    InternalAddFunction(HoursBetweenFunctionName, FHoursBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HoursBetweenMethod, HoursBetweenParameterCount), True, vtInt64);
    InternalAddFunction(MinutesBetweenFunctionName, FMinutesBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinutesBetweenMethod, MinutesBetweenParameterCount), True, vtInt64);
    InternalAddFunction(SecondsBetweenFunctionName, FSecondsBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondsBetweenMethod, SecondsBetweenParameterCount), True, vtInt64);
    InternalAddFunction(MilliSecondsBetweenFunctionName, FMilliSecondsBetweenHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondsBetweenMethod, MilliSecondsBetweenParameterCount),
      True, vtInt64);
    InternalAddFunction(MonthOfTheYearFunctionName, FMonthOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MonthOfTheYearMethod, False, True), True, vtWord);
    InternalAddFunction(WeekOfTheYearFunctionName, FWeekOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.WeekOfTheYearMethod, False, True), True, vtWord);
    InternalAddFunction(DayOfTheYearFunctionName, FDayOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DayOfTheYearMethod, False, True), True, vtWord);
    InternalAddFunction(HourOfTheYearFunctionName, FHourOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HourOfTheYearMethod, False, True), True, vtWord);
    InternalAddFunction(MinuteOfTheYearFunctionName, FMinuteOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteOfTheYearMethod, False, True), True, vtLongWord);
    InternalAddFunction(SecondOfTheYearFunctionName, FSecondOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfTheYearMethod, False, True), True, vtLongWord);
    InternalAddFunction(MilliSecondOfTheYearFunctionName, FMilliSecondOfTheYearHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheYearMethod, False, True), True, vtInt64);
    InternalAddFunction(WeekOfTheMonthFunctionName, FWeekOfTheMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.WeekOfTheMonthMethod, False, True), True, vtWord);
    InternalAddFunction(DayOfTheMonthFunctionName, FDayOfTheMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DayOfTheMonthMethod, False, True), True, vtWord);
    InternalAddFunction(HourOfTheMonthFunctionName, FHourOfTheMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HourOfTheMonthMethod, False, True), True, vtWord);
    InternalAddFunction(MinuteOfTheMonthFunctionName, FMinuteOfTheMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteOfTheMonthMethod, False, True), True, vtWord);
    InternalAddFunction(SecondOfTheMonthFunctionName, FSecondOfTheMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfTheMonthMethod, False, True), True, vtLongWord);
    InternalAddFunction(MilliSecondOfTheMonthFunctionName, FMilliSecondOfTheMonthHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheMonthMethod, False, True), True, vtLongWord);
    InternalAddFunction(DayOfTheWeekFunctionName, FDayOfTheWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.DayOfTheWeekMethod, False, True), True, vtWord);
    InternalAddFunction(HourOfTheWeekFunctionName, FHourOfTheWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HourOfTheWeekMethod, False, True), True, vtWord);
    InternalAddFunction(MinuteOfTheWeekFunctionName, FMinuteOfTheWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteOfTheWeekMethod, False, True), True, vtWord);
    InternalAddFunction(SecondOfTheWeekFunctionName, FSecondOfTheWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfTheWeekMethod, False, True), True, vtLongWord);
    InternalAddFunction(MilliSecondOfTheWeekFunctionName, FMilliSecondOfTheWeekHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheWeekMethod, False, True), True, vtLongWord);
    InternalAddFunction(HourOfTheDayFunctionName, FHourOfTheDayHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.HourOfTheDayMethod, False, True), True, vtWord);
    InternalAddFunction(MinuteOfTheDayFunctionName, FMinuteOfTheDayHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteOfTheDayMethod, False, True), True, vtWord);
    InternalAddFunction(SecondOfTheDayFunctionName, FSecondOfTheDayHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfTheDayMethod, False, True), True, vtLongWord);
    InternalAddFunction(MilliSecondOfTheDayFunctionName, FMilliSecondOfTheDayHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheDayMethod, False, True), True, vtLongWord);
    InternalAddFunction(MinuteOfTheHourFunctionName, FMinuteOfTheHourHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MinuteOfTheHourMethod, False, True), True, vtWord);
    InternalAddFunction(SecondOfTheHourFunctionName, FSecondOfTheHourHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfTheHourMethod, False, True), True, vtWord);
    InternalAddFunction(MilliSecondOfTheHourFunctionName, FMilliSecondOfTheHourHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheHourMethod, False, True), True, vtLongWord);
    InternalAddFunction(SecondOfTheMinuteFunctionName, FSecondOfTheMinuteHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SecondOfTheMinuteMethod, False, True), True, vtWord);
    InternalAddFunction(MilliSecondOfTheMinuteFunctionName, FMilliSecondOfTheMinuteHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheMinuteMethod, False, True), True, vtLongWord);
    InternalAddFunction(MilliSecondOfTheSecondFunctionName, FMilliSecondOfTheSecondHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.MilliSecondOfTheSecondMethod, False, True), True, vtWord);
    InternalAddFunction(CompareDateTimeFunctionName, FCompareDateTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CompareDateTimeMethod, CompareDateTimeParameterCount), True, vtShortint);
    InternalAddFunction(SameDateTimeFunctionName, FSameDateTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SameDateTimeMethod, SameDateTimeParameterCount), True, vtShortint);
    InternalAddFunction(CompareDateFunctionName, FCompareDateHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CompareDateMethod, CompareDateParameterCount), True, vtShortint);
    InternalAddFunction(SameDateFunctionName, FSameDateHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SameDateMethod, SameDateParameterCount), True, vtShortint);
    InternalAddFunction(CompareTimeFunctionName, FCompareTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.CompareTimeMethod, CompareTimeParameterCount), True, vtShortint);
    InternalAddFunction(SameTimeFunctionName, FSameTimeHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.SameTimeMethod, SameTimeParameterCount), True, vtShortint);
    InternalAddFunction(GetTickCountFunctionName, FGetTickCountHandle, fkMethod,
      MakeFunctionMethod(FMathMethod.GetTickCount), False, vtLongWord);
    InternalAddConstant(MondayConstantName, MakeByte(DayMonday));
    InternalAddConstant(TuesdayConstantName, MakeByte(DayTuesday));
    InternalAddConstant(WednesdayConstantName, MakeByte(DayWednesday));
    InternalAddConstant(ThursdayConstantName, MakeByte(DayThursday));
    InternalAddConstant(FridayConstantName, MakeByte(DayFriday));
    InternalAddConstant(SaturdayConstantName, MakeByte(DaySaturday));
    InternalAddConstant(SundayConstantName, MakeByte(DaySunday));
    {$IFDEF DELPHI_XE7}
    InternalAddConstant(JanuaryConstantName, MakeByte(MonthJanuary));
    InternalAddConstant(FebruaryConstantName, MakeByte(MonthFebruary));
    InternalAddConstant(MarchConstantName, MakeByte(MonthMarch));
    InternalAddConstant(AprilConstantName, MakeByte(MonthApril));
    InternalAddConstant(MayConstantName, MakeByte(MonthMay));
    InternalAddConstant(JuneConstantName, MakeByte(MonthJune));
    InternalAddConstant(JulyConstantName, MakeByte(MonthJuly));
    InternalAddConstant(AugustConstantName, MakeByte(MonthAugust));
    InternalAddConstant(SeptemberConstantName, MakeByte(MonthSeptember));
    InternalAddConstant(OctoberConstantName, MakeByte(MonthOctober));
    InternalAddConstant(NovemberConstantName, MakeByte(MonthNovember));
    InternalAddConstant(DecemberConstantName, MakeByte(MonthDecember));
    {$ENDIF}
    InternalAddConstant(LessThanValueConstantName, MakeShortint(LessThanValue));
    InternalAddConstant(EqualsValueConstantName, MakeShortint(EqualsValue));
    InternalAddConstant(GreaterThanValueConstantName, MakeShortint(GreaterThanValue));
    InternalAddConstant(PiConstantName, MakeExtended(Pi));
    InternalAddConstant(KilobyteConstantName, MakeInt64(Kilobyte));
    InternalAddConstant(MegabyteConstantName, MakeInt64(Megabyte));
    InternalAddConstant(GigabyteConstantName, MakeInt64(Gigabyte));
    InternalAddConstant(TerabyteConstantName, MakeInt64(Terabyte));
    InternalAddConstant(PetabyteConstantName, MakeInt64(Petabyte));
    InternalAddConstant(MinShortintConstantName, MakeInt64(-High(Shortint) - 1));
    InternalAddConstant(MaxShortintConstantName, MakeInt64(High(Shortint)));
    InternalAddConstant(MinByteConstantName, MakeInt64(Byte(0)));
    InternalAddConstant(MaxByteConstantName, MakeInt64(High(Byte)));
    InternalAddConstant(MinSmallintConstantName, MakeInt64(-High(Smallint) - 1));
    InternalAddConstant(MaxSmallintConstantName, MakeInt64(High(Smallint)));
    InternalAddConstant(MinWordConstantName, MakeInt64(Byte(0)));
    InternalAddConstant(MaxWordConstantName, MakeInt64(High(Word)));
    InternalAddConstant(MinIntegerConstantName, MakeInt64(-High(Integer) - 1));
    InternalAddConstant(MaxIntegerConstantName, MakeInt64(High(Integer)));
    InternalAddConstant(MinNativeIntConstantName, MakeInt64(-High(NativeInt) - 1));
    InternalAddConstant(MaxNativeIntConstantName, MakeInt64(High(NativeInt)));
    InternalAddConstant(MinLongWordConstantName, MakeInt64(Byte(0)));
    InternalAddConstant(MaxLongWordConstantName, MakeInt64(High(LongWord)));
    InternalAddConstant(MinInt64ConstantName, MakeInt64(-High(Int64) - 1));
    InternalAddConstant(MaxInt64ConstantName, MakeInt64(High(Int64)));
    InternalAddConstant(MinSingleConstantName, MakeExtended(MinSingle));
    InternalAddConstant(MaxSingleConstantName, MakeExtended(MaxSingle));
    InternalAddConstant(MinDoubleConstantName, MakeExtended(MinDouble));
    InternalAddConstant(MaxDoubleConstantName, MakeExtended(MaxDouble));
    InternalAddConstant(TinyConstantName, MakeExtended(1E-16));
    InternalAddConstant(HugeConstantName, MakeExtended(1 / 1E-16));
  finally
    EndUpdate;
  end;
end;

destructor TMathParser.Destroy;
begin
  FMathMethod.Free;
  inherited;
end;

procedure ApplyDecimalSeparator;
begin
  ParseFormat.DecimalSeparator := Dot;
end;

procedure RestoreDecimalSeparator;
begin
  ParseFormat.DecimalSeparator := PreviousDecimalSeparator;
end;

initialization
  {$IFDEF FPC}
  InitCriticalSection(RedirectCategorySync);
  {$ELSE}
  InitializeCriticalSection(RedirectCategorySync);
  {$ENDIF}
  PreviousDecimalSeparator := ParseFormat.DecimalSeparator;

finalization
  {$IFDEF FPC}
  DoneCriticalSection(RedirectCategorySync);
  {$ELSE}
  DeleteCriticalSection(RedirectCategorySync);
  {$ENDIF}

end.
