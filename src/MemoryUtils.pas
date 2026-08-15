{ ************************************************************************** }
{                                                                            }
{ MemoryUtils                                                                }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit MemoryUtils;

{$H+}
{$B-}
{$I Directives.inc}
{$IFDEF FPC}
{$MODE Delphi}
{$IFDEF VER3_0}{$DEFINE NOCLOSURES}{$ENDIF}
{$IFDEF VER3_2}{$DEFINE NOCLOSURES}{$ENDIF}
{$ELSE}
{$IFNDEF DELPHI_12}{$DEFINE NOCLOSURES}{$ENDIF}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Types;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.SysUtils, System.Types, BaseTypes;
  {$ELSE}
  Windows, SysUtils, Types;
  {$ENDIF}
  {$ENDIF}

type
  PPByte = ^PByte;

  PU16 = ^TU16;
  TU16 = packed record
    case Integer of
      0: (Lo, Hi: Byte);
  end;
  PU32 = ^TU32;
  TU32 = packed record
    case Integer of
      0: (Lo, Hi: Word);
  end;
  PU64 = ^TU64;
  TU64 = packed record
    case Integer of
      0: (Lo, Hi: LongWord);
  end;
  P16 = ^T16;
  T16 = packed record
    case Integer of
      0: (A, B: Byte);
  end;
  P24 = ^T24;
  T24 = packed record
    case Integer of
      0: (A, B, C: Byte);
  end;
  P32 = ^T32;
  T32 = packed record
    case Integer of
      0: (A, B, C, D: Byte);
  end;
  P64 = ^T64;
  T64 = packed record
    case Integer of
      0: (A, B, C, D, E, F, G, H: Byte);
  end;
  P128 = ^T128;
  T128 = packed record
    case Integer of
      0: (A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P: Byte);
  end;

  PShortIntDynArray = ^TShortIntDynArray;
  PByteDynArray = ^TByteDynArray;
  PSmallIntDynArray = ^TSmallIntDynArray;
  PWordDynArray = ^TWordDynArray;
  PIntegerDynArray = ^TIntegerDynArray;
  PInt64DynArray = ^TInt64DynArray;
  PLongWordDynArray = ^TLongWordDynArray;
  PSingleDynArray = ^TSingleDynArray;
  PDoubleDynArray = ^TDoubleDynArray;
  PBooleanDynArray = ^TBooleanDynArray;
  PExtendedDynArray = ^TExtendedDynArray;

  {$IFDEF DELPHI_XE7}
  TExtendedDynArray = TArray<Extended>;
  {$ELSE}
  TExtendedDynArray = array of Extended;
  {$ENDIF}
  {$IFNDEF DELPHI_XE7}
  PNativeInt = ^NativeInt;
  PNativeUInt = ^NativeUInt;
  {$ENDIF}
  PNativeIntDynArray = ^TNativeIntDynArray;
  {$IFDEF DELPHI_XE7}
  TNativeIntDynArray = TArray<NativeInt>;
  {$ELSE}
  TNativeIntDynArray = array of NativeInt;
  {$ENDIF}
  PNativeUIntDynArray = ^TNativeUIntDynArray;
  {$IFDEF DELPHI_XE7}
  TNativeUIntDynArray = TArray<NativeUInt>;
  {$ELSE}
  TNativeUIntDynArray = array of NativeUInt;
  {$ENDIF}
  PStringDynArray = ^TStringDynArray;
  PCharDynArray = ^TCharDynArray;
  {$IFDEF DELPHI_XE7}
  TCharDynArray = TArray<Char>;
  {$ELSE}
  TCharDynArray = array of Char;
  {$ENDIF}

  NativeIntRec = packed record
    case Integer of
      0: (Lo, Hi: NativeInt);
  end;

  PArrayData = ^TArrayData;
  TArrayData = record
    Index: Integer;
    Count: Integer;
  end;

  TNext = function(var Index: Integer; const Count: Integer; const Value: Pointer;
    const P: Pointer = nil): Boolean;
  TSearchCompare = function(const Target, Value: Pointer; const Index: Integer;
    const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
  TSortCompare = function(const AIndex, BIndex: Integer; const Target: Pointer;
    const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
  TSortExchange = procedure(const AIndex, BIndex: Integer; const Target: Pointer; const P: Pointer = nil);

  TFloat16 = record
  private
    const
      Float16SignMask = $8000;
      Float16ExponentMask = $7C00;
      Float16FractionMask = $03FF;
      Float16Bias = 15;
      SingleBias = 127;
      Float16MantissaBits = 10;
      SingleMantissaBits = 23;
      MantissaShift = SingleMantissaBits - Float16MantissaBits;
      RoundingGuardBit = Cardinal(1) shl (MantissaShift - 1);
      RoundingStickyMask = RoundingGuardBit - 1;
  public
    var
      Value: Word;
    class function FromSingle(const Float32: Single): TFloat16; static;
    function ToSingle: Single;
  end;

  TArrayRec = record
  public
    const
      Increment = 1024;
    type
      {$IFDEF FPC}
      TArray2<T> = array of array of T;
      {$ENDIF}
      TIterator = record
      public
        type
          {$IFDEF NOCLOSURES}
          TEmpty<T> = function(const Value: T; const P: Pointer = nil): Boolean of object;
          {$ELSE}
          TEmpty<T> = reference to function(const Value: T; const P: Pointer = nil): Boolean;
          {$ENDIF}
          {$IFDEF NOCLOSURES}
          TAlter<T> = function(var AValue, BValue: T; const P: Pointer = nil): Boolean of object;
          {$ELSE}
          TAlter<T> = reference to function(var AValue, BValue: T; const P: Pointer = nil): Boolean;
          {$ENDIF}
          {$IFDEF NOCLOSURES}
          TCycle<T> = function(var Value: T; const Index: Integer; const P: Pointer = nil): Boolean of object;
          {$ELSE}
          TCycle<T> = reference to function(var Value: T; const Index: Integer;
            const P: Pointer = nil): Boolean;
          {$ENDIF}
        class function ForEach<T>(const Target: TArray<T>; const Empty: TEmpty<T>; const Alter: TAlter<T>;
          const P: Pointer = nil): Integer; overload; static;
        class function ForEach<T>(const Target: TArray<T>; const Cycle: TCycle<T>;
          const P: Pointer = nil): Boolean; overload; static;
        class function Iterate<T>(const Target: TArray<T>; const Empty: TEmpty<T>; const Alter: TAlter<T>;
          const P: Pointer = nil): TArray<T>; overload; static;
        class function Iterate<T>(const Target: TArray<T>; const Cycle: TCycle<T>;
          const P: Pointer = nil): TArray<T>; overload; static;
      end;
    class procedure Reset<T>(var Target: TArray<T>; var Data: TArrayData); static;
    class procedure Apply<T>(var Target: TArray<T>; const Data: TArrayData); static;
    class function Add<T>(var Target: TArray<T>; const Value: T): Integer; overload; static;
    class function Add<T>(var Target: TArray<T>; var Data: TArrayData;
      const Value: T): Integer; overload; static;
    class procedure Delete<T>(var Target: {$IFDEF FPC}TArray2<T>{$ELSE}TArray<TArray<T>>{$ENDIF}); overload; static;
    class function Delete<T>(var Target: TArray<T>; const Index: Integer): Boolean; overload; static;
    class function Pack<T>(const Target: TArray<T>; const Empty: TIterator.TEmpty<T>;
      const P: Pointer = nil): TArray<T>; static;
    class function Union<T>(const Target: TArray<T>; const Empty: TIterator.TEmpty<T>;
      const Alter: TIterator.TAlter<T>; const P: Pointer = nil): TArray<T>; static;
    class function New<T>(var Target: {$IFDEF FPC}TArray2<T>{$ELSE}TArray<TArray<T>>{$ENDIF}): Integer; static;
  end;

  TVector<T> = record
  private
    function GetSize: Integer;
    procedure SetSize(const Value: Integer);
  public
    const
      Increment = 1024;
    var
      A: TArray<T>;
      D: TArrayData;
    type
      P = ^T;
      {$IFDEF NOCLOSURES}
      TCompare = function(const AValue, BValue: P): Boolean of object;
      {$ELSE}
      TCompare = reference to function(const AValue, BValue: P): Boolean;
      {$ENDIF}
    function Lo: Integer;
    function Hi: Integer;
    function At(const Index: Integer): P;
    procedure Reset;
    procedure Apply;
    function Add(const Value: T): Integer;
    function Put(const Value: T): Integer;
    function Delete(const Index: Integer): Boolean;
    procedure Clear; overload;
    function Empty: Boolean;
    function Find(const Compare: TCompare): P; overload;
    function Find(const Value: T; const Compare: TCompare): Integer; overload;
    function ForEach(const Empty: TArrayRec.TIterator.TEmpty<T>; const Alter: TArrayRec.TIterator.TAlter<T>;
      const P: Pointer = nil): Integer; overload;
    function ForEach(const Cycle: TArrayRec.TIterator.TCycle<T>; const P: Pointer = nil): Boolean; overload;
    function Iterate(const Empty: TArrayRec.TIterator.TEmpty<T>; const Alter: TArrayRec.TIterator.TAlter<T>;
      const P: Pointer = nil): TArray<T>; overload;
    function Iterate(const Cycle: TArrayRec.TIterator.TCycle<T>; const P: Pointer = nil): TArray<T>; overload;
    procedure Pack(const Empty: TArrayRec.TIterator.TEmpty<T>; const P: Pointer = nil);
    procedure Union(const Empty: TArrayRec.TIterator.TEmpty<T>; const Alter: TArrayRec.TIterator.TAlter<T>;
      const P: Pointer = nil);
    procedure Sort(const Compare: TSortCompare; const Exchange: TSortExchange; const P: Pointer = nil);
    function BinarySearch(const Compare: TSearchCompare; const Value: Pointer;
      const P: Pointer = nil): Integer;
    property Size: Integer read GetSize write SetSize;
  end;

  PMatrix = ^TMatrix;

  TMatrix = record
  private
    type
      {$IFDEF FPC}
      TBitWord = QWord;
      {$ELSE}
      TBitWord = UInt64;
      {$ENDIF}
    var
      {$IFDEF FPC}
      RawData: array of array of Pointer;
      RowBits: array of array of TBitWord;
      ColBits: array of array of TBitWord;
      {$ELSE}
      RawData: TArray<TArray<Pointer>>;
      RowBits: TArray<TArray<TBitWord>>;
      ColBits: TArray<TArray<TBitWord>>;
      {$ENDIF}
      BitsDirty: Boolean;
      UpdateCount: Integer;
    function BitWordCount(const N: Integer): Integer; inline;
    function BitFirstSet(const W: TBitWord): Integer; inline;
    procedure BitsInit;
    procedure BitsClear;
    procedure BitsFillAll;
    procedure BitsRebuild;
    procedure BitsEnsure; inline;
    procedure BitsAssign(const X, Y: Integer; const Value: Pointer); inline;
    function RowNextSet(const Y, XMin, XMax: Integer; var XFound: Integer): Boolean;
    function ColNextSet(const X, YMin, YMax: Integer; var YFound: Integer): Boolean;
    function GetData(const X, Y: Integer): Pointer;
    function GetEmpty: Boolean;
    function GetFlag(const X, Y: Integer): Boolean;
    function GetHSize: Integer;
    function GetVSize: Integer;
    procedure SetData(const X, Y: Integer; Value: Pointer);
    procedure SetFlag(const X, Y: Integer; Value: Boolean);
  public
    type
      {$IFDEF NOCLOSURES}
      TCycle = function(const X, Y: Integer; const Step: Integer; const P: Pointer): Boolean of object;
      {$ELSE}
      TCycle = reference to function(const X, Y: Integer; const Step: Integer; const P: Pointer): Boolean;
      {$ENDIF}
      {$IFDEF NOCLOSURES}
      TCompare = function(const X, Y: Integer; const Value: Pointer; const Step: Integer; var Stop: Boolean;
        const P: Pointer): Boolean of object;
      {$ELSE}
      TCompare = reference to function(const X, Y: Integer; const Value: Pointer; const Step: Integer;
        var Stop: Boolean; const P: Pointer): Boolean;
      {$ENDIF}
      {$IFDEF NOCLOSURES}
      TStop = function(const Step: Integer; const P: Pointer): Boolean of object;
      {$ELSE}
      TStop = reference to function(const Step: Integer; const P: Pointer): Boolean;
      {$ENDIF}
    var
      CustomData: Pointer;
    class function Make(const Size: TSize): TMatrix; overload; static;
    class function Make(const HSize, VSize: Integer): TMatrix; overload; static;
    class function Copy(const Matrix: TMatrix): TMatrix; static;
    procedure Reset;
    procedure Free;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure InvalidateBits;
    function Check: Boolean; overload;
    function Check(const X, Y: Integer): Boolean; overload;
    function Check(const Point: TPoint): Boolean; overload;
    class function Expand(const X, Y: Integer; const Size: TSize; const Cycle: TCycle; const Stop: TStop;
      const P: Pointer = nil): Integer; overload; static;
    class function Expand(const Point: TPoint; const Size: TSize; const Cycle: TCycle; const Stop: TStop;
      const P: Pointer = nil): Integer; overload; static;
    function Search(const X, Y: Integer; const Compare: TCompare; const Stop: TStop;
      const P: Pointer = nil): Pointer; overload;
    function Search(const Point: TPoint; const Compare: TCompare; const Stop: TStop;
      const P: Pointer = nil): Pointer; overload;
    function Segment(const Rect: TRect): TMatrix;
    procedure Write(const A: TArray<TPoint>; const Value: Pointer); overload;
    procedure Write(const A: TArray<TArray<TPoint>>; const Value: Pointer); overload;
    procedure Fill(const Value: Pointer);
    class function GenerateRandomAngles(const NumSegments: Integer;
      const MinAngle: Extended): TArray<Extended>; static;
    class function GenerateAngles(const NumSegments: Integer;
      const MinAngle: Extended): TArray<Extended>; static;
    function DivideIntoSegments(const Center: TPoint; const Angles: TArray<Extended>): Boolean;
    property Empty: Boolean read GetEmpty;
    property Data[const X, Y: Integer]: Pointer read GetData write SetData;
    property Flag[const X, Y: Integer]: Boolean read GetFlag write SetFlag;
    property HSize: Integer read GetHSize;
    property VSize: Integer read GetVSize;
  end;

{$IFDEF FPC}
procedure MoveMemory(Destination: Pointer; Source: Pointer; Length: NativeUInt);
procedure CopyMemory(Destination: Pointer; Source: Pointer; Length: NativeUInt);
procedure FillMemory(Destination: Pointer; Length: NativeUInt; Fill: Byte);
procedure ZeroMemory(Destination: Pointer; Length: NativeUInt);

function MakeWord(A, B: Byte): Word;
function MakeLong(A, B: Word): Longint;
function HiWord(L: DWORD): Word;
function HiByte(W: Word): Byte;
{$ENDIF}

function MakeU16(const Lo, Hi: Byte): Word;
function MakeU32(const Lo, Hi: Word): LongWord;
function MakeU64(const Lo, Hi: LongWord): UInt64;

function Make16(const A, B: Byte): T16;
function Make24(const A, B, C: Byte): T24;
function Make32(const A, B, C, D: Byte): T32;
function Make64(const A, B, C, D, E, F, G, H: Byte): T64;

function MakeArray(const Value: array of NativeInt): TArray<NativeInt>; overload;
function MakeArray(const Value: array of NativeUInt): TArray<NativeUInt>; overload;
function MakeArray(const Value: array of Int64): TArray<Int64>; overload;
function MakeArray(const Value: array of Integer): TArray<Integer>; overload;
function MakeArray(const Value: array of Word): TArray<Word>; overload;
function MakeArray(const Value: array of Byte): TArray<Byte>; overload;
function MakeArray(const Value: array of Single): TArray<Single>; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function MakeArray(const Value: array of Double): TArray<Double>; overload;
{$ENDIF}
function MakeArray(const Value: array of Extended): TArray<Extended>; overload;
function MakeArray(const Value: array of Char): TArray<Char>; overload;
function MakeArray(const Value: array of string): TArray<string>; overload;

function UnionArray(const Target: array of TNativeIntDynArray): TArray<NativeInt>; overload;
function UnionArray(const Target: array of TNativeUIntDynArray): TArray<NativeUInt>; overload;
function UnionArray(const Target: array of TInt64DynArray): TArray<Int64>; overload;
function UnionArray(const Target: array of TIntegerDynArray): TArray<Integer>; overload;
function UnionArray(const Target: array of TWordDynArray): TArray<Word>; overload;
function UnionArray(const Target: array of TByteDynArray): TArray<Byte>; overload;
function UnionArray(const Target: array of TSingleDynArray): TArray<Single>; overload;
function UnionArray(const Target: array of TDoubleDynArray): TArray<Double>; overload;
function UnionArray(const Target: array of TExtendedDynArray): TArray<Extended>; overload;
function UnionArray(const Target: array of TCharDynArray): TArray<Char>; overload;
function UnionArray(const Target: array of TStringDynArray): TArray<string>; overload;

procedure Reset(var Target: TArray<NativeInt>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<NativeUInt>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<Int64>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<Integer>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<Word>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<Byte>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<Single>; var Data: TArrayData); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Reset(var Target: TArray<Double>; var Data: TArrayData); overload;
{$ENDIF}
procedure Reset(var Target: TArray<Extended>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<Char>; var Data: TArrayData); overload;
procedure Reset(var Target: TArray<string>; var Data: TArrayData); overload;

procedure Apply(var Target: TArray<NativeInt>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<NativeUInt>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<Int64>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<Integer>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<Word>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<Byte>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<Single>; const Data: TArrayData); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Apply(var Target: TArray<Double>; const Data: TArrayData); overload;
{$ENDIF}
procedure Apply(var Target: TArray<Extended>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<Char>; const Data: TArrayData); overload;
procedure Apply(var Target: TArray<string>; const Data: TArrayData); overload;

procedure Add(const Target, Source: Pointer; const TargetSize, SourceSize: Integer); overload;
function Add(var Target: TArray<NativeInt>; const Value: NativeInt;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<NativeInt>; var Data: TArrayData; const Value: NativeInt;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<NativeInt>; const Value: NativeInt;
  const Unique: Boolean = False); overload;
function Add(var Target: TArray<NativeUInt>; const Value: NativeUInt;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<NativeUInt>; var Data: TArrayData; const Value: NativeUInt;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<NativeUInt>; const Value: NativeUInt;
  const Unique: Boolean = False); overload;
function Add(var Target: TArray<Int64>; const Value: Int64; const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Int64>; var Data: TArrayData; const Value: Int64;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Int64>; const Value: Int64; const Unique: Boolean = False); overload;
function Add(var Target: TArray<Integer>; const Value: Integer;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Integer>; var Data: TArrayData; const Value: Integer;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Integer>; const Value: Integer; const Unique: Boolean = False); overload;
function Add(var Target: TArray<Word>; const Value: Word; const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Word>; var Data: TArrayData; const Value: Word;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Word>; const Value: Word; const Unique: Boolean = False); overload;
function Add(var Target: TArray<Byte>; const Value: Byte; const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Byte>; var Data: TArrayData; const Value: Byte;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Byte>; const Value: Byte; const Unique: Boolean = False); overload;
function Add(var Target: TArray<Single>; const Value: Single;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Single>; var Data: TArrayData; const Value: Single;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Single>; const Value: Single; const Unique: Boolean = False); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Add(var Target: TArray<Double>; const Value: Double;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Double>; var Data: TArrayData; const Value: Double;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Double>; const Value: Double; const Unique: Boolean = False); overload;
{$ENDIF}
function Add(var Target: TArray<Extended>; const Value: Extended;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Extended>; var Data: TArrayData; const Value: Extended;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Extended>; const Value: Extended; const Unique: Boolean = False); overload;
function Add(var Target: TArray<Char>; const Value: Char; const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<Char>; var Data: TArrayData; const Value: Char;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<Char>; const Value: Char; const Unique: Boolean = False); overload;
function Add(var Target: TArray<string>; const Value: string;
  const Unique: Boolean = False): Integer; overload;
function Add(var Target: TArray<string>; var Data: TArrayData; const Value: string;
  const Unique: Boolean = False): Integer; overload;
procedure Push(var Target: TArray<string>; const Value: string; const Unique: Boolean = False); overload;

procedure Add(var Target: TArray<NativeInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<NativeInt>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<NativeInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<NativeUInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<NativeUInt>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<NativeUInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Int64>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Int64>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Int64>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Integer>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Integer>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Integer>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Word>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Word>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Word>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Byte>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Byte>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Byte>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Single>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Single>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Single>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Add(var Target: TArray<Double>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Double>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Double>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
{$ENDIF}
procedure Add(var Target: TArray<Extended>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Extended>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Extended>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Char>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Char>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Char>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean = False); overload;

function NativeIntNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<NativeInt>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<NativeInt>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<NativeInt>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function NativeUIntNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<NativeUInt>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<NativeUInt>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<NativeUInt>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function Int64Next(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Int64>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Int64>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Int64>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function IntegerNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Integer>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Integer>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Integer>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function WordNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Word>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Word>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Word>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function ByteNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Byte>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Byte>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Byte>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function SingleNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Single>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Single>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Single>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function DoubleNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Double>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Double>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Double>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function ExtendedNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
{$ENDIF}
procedure Add(var Target: TArray<Extended>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Extended>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Extended>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
function CharNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
procedure Add(var Target: TArray<Char>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Add(var Target: TArray<Char>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;
procedure Push(var Target: TArray<Char>; const FromIndex, Count: Integer;
  const Unique: Boolean = False); overload;

function Delete(const Target: Pointer; const Index, Count, TargetSize: Integer): Boolean; overload;
function Delete(var Target: TArray<NativeInt>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<NativeUInt>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<Int64>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<Integer>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<Word>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<Byte>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<Single>; const Index: Integer): Boolean; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Delete(var Target: TArray<Double>; const Index: Integer): Boolean; overload;
{$ENDIF}
function Delete(var Target: TArray<Extended>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<Char>; const Index: Integer): Boolean; overload;
function Delete(var Target: TArray<string>; const Index: Integer): Boolean; overload;

function IndexOf(const Target, Source: Pointer; const Count, SourceSize: Integer): Integer; overload;
function IndexOf(const Target: TArray<NativeInt>; const Value: NativeInt): Integer; overload;
function IndexOf(const Target: TArray<NativeUInt>; const Value: NativeUInt): Integer; overload;
function IndexOf(const Target: TArray<Int64>; const Value: Int64): Integer; overload;
function IndexOf(const Target: TArray<Integer>; const Value: Integer): Integer; overload;
function IndexOf(const Target: TArray<Word>; const Value: Word): Integer; overload;
function IndexOf(const Target: TArray<Byte>; const Value: Byte): Integer; overload;
function IndexOf(const Target: TArray<Single>; const Value: Single): Integer; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function IndexOf(const Target: TArray<Double>; const Value: Double): Integer; overload;
{$ENDIF}
function IndexOf(const Target: TArray<Extended>; const Value: Extended): Integer; overload;
function IndexOf(const Target: TArray<Char>; const Value: Char): Integer; overload;
function IndexOf(const Target: TArray<string>; const Value: string): Integer; overload;

function Insert(const Target, Source: Pointer;
  const Index, TargetSize, SourceSize: Integer): Boolean; overload;
function Insert(var Target: TArray<NativeInt>; const Value: NativeInt;
  const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<NativeUInt>; const Value: NativeUInt;
  const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<Int64>; const Value: Int64; const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<Integer>; const Value: Integer; const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<Word>; const Value: Word; const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<Byte>; const Value: Byte; const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<Single>; const Value: Single; const Index: Integer): Boolean; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Insert(var Target: TArray<Double>; const Value: Double; const Index: Integer): Boolean; overload;
{$ENDIF}
function Insert(var Target: TArray<Extended>; const Value: Extended; const Index: Integer): Boolean; overload;
function Insert(var Target: TArray<Char>; const Value: Char; const Index: Integer): Boolean; overload;

function BSearch(const Target: Pointer; Min, Max: Integer; const Compare: TSearchCompare;
  const Value: Pointer; const P: Pointer = nil): Integer; overload;
function BSearch(const Target: Pointer; const Min, Max: Integer; const Compare: TSearchCompare;
  const Value: Pointer; const P: Pointer; const Index: PInteger): Boolean; overload;
function NativeIntSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<NativeInt>; const Value: NativeInt): Integer; overload;
function Find(const Target: TArray<NativeInt>; const Value: NativeInt; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
function NativeUIntSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<NativeUInt>; const Value: NativeUInt): Integer; overload;
function Find(const Target: TArray<NativeUInt>; const Value: NativeUInt; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
function Int64SearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Int64>; const Value: Int64): Integer; overload;
function Find(const Target: TArray<Int64>; const Value: Int64; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
function IntegerSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Integer>; const Value: Integer): Integer; overload;
function Find(const Target: TArray<Integer>; const Value: Integer; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
function WordSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Word>; const Value: Word): Integer; overload;
function Find(const Target: TArray<Word>; const Value: Word; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
function ByteSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Byte>; const Value: Byte): Integer; overload;
function Find(const Target: TArray<Byte>; const Value: Byte; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
function SingleSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Single>; const Value: Single): Integer; overload;
function Find(const Target: TArray<Single>; const Value: Single; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function DoubleSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Double>; const Value: Double): Integer; overload;
function Find(const Target: TArray<Double>; const Value: Double; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;
{$ENDIF}
function ExtendedSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer = nil): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
function Search(const Target: TArray<Extended>; const Value: Extended): Integer; overload;
function Find(const Target: TArray<Extended>; const Value: Extended; const P: Pointer;
  const Index: PInteger = nil): Boolean; overload;

procedure HSort(const Target: Pointer; Min, Max: Integer; const Compare: TSortCompare;
  const Exchange: TSortExchange; const P: Pointer = nil);
procedure QSort(const Target: Pointer; Min, Max: Integer; const Compare: TSortCompare;
  const Exchange: TSortExchange; const P: Pointer = nil);
function NativeIntSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure NativeIntExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<NativeInt>); overload;
function NativeUIntSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure NativeUIntExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<NativeUInt>); overload;
function Int64SortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure Int64Exchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Int64>); overload;
function IntegerSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure IntegerExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Integer>); overload;
function WordSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure WordExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Word>); overload;
function ByteSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure ByteExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Byte>); overload;
function SingleSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure SingleExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Single>); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function DoubleSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure DoubleExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Double>); overload;
{$ENDIF}
function ExtendedSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure ExtendedExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Extended>); overload;
function CharSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure CharExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<Char>); overload;
function StringSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
procedure StringExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
procedure Sort(var Target: TArray<string>); overload;

procedure Resize(const Target: Pointer; const PriorSize, Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<NativeInt>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<NativeUInt>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<Int64>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<Integer>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<Word>; const Size: Integer; const Fill: Word = 0); overload;
procedure Resize(var Target: TArray<Byte>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<Single>; const Size: Integer; const Fill: Byte = 0); overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Resize(var Target: TArray<Double>; const Size: Integer; const Fill: Byte = 0); overload;
{$ENDIF}
procedure Resize(var Target: TArray<Extended>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<Char>; const Size: Integer; const Fill: Byte = 0); overload;
procedure Resize(var Target: TArray<string>; const Size: Integer); overload;

procedure Segment(const Source, Target: Pointer; const Index, Size: Integer); overload;
function Segment(const Target: TArray<NativeInt>; const Index, Size: Integer): TArray<NativeInt>; overload;
function Segment(const Target: TArray<NativeUInt>; const Index, Size: Integer): TArray<NativeUInt>; overload;
function Segment(const Target: TArray<Int64>; const Index, Size: Integer): TArray<Int64>; overload;
function Segment(const Target: TArray<Integer>; const Index, Size: Integer): TArray<Integer>; overload;
function Segment(const Target: TArray<Word>; const Index, Size: Integer): TArray<Word>; overload;
function Segment(const Target: TArray<Byte>; const Index, Size: Integer): TArray<Byte>; overload;
function Segment(const Target: TArray<Single>; const Index, Size: Integer): TArray<Single>; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Segment(const Target: TArray<Double>; const Index, Size: Integer): TArray<Double>; overload;
{$ENDIF}
function Segment(const Target: TArray<Extended>; const Index, Size: Integer): TArray<Extended>; overload;
function Segment(const Target: TArray<Char>; const Index, Size: Integer): TArray<Char>; overload;

procedure SetRandom(var Target: TArray<Integer>);

implementation

uses
  {$IFDEF FPC}
  Math;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.Math;
  {$ELSE}
  Math;
  {$ENDIF}
  {$ENDIF}

const
  ArrayIncrement = 128;

class function TFloat16.FromSingle(const Float32: Single): TFloat16;
var
  Bits, Sign, Mantissa, HalfExponent, HalfMantissa, GuardMask, StickyMask: LongWord;
  Exponent, TotalShift, Diff: Integer;
  GuardBitIsOne, StickyBitsAreSet, LSBIsOne, RoundUp: Boolean;
begin
  Bits := PCardinal(@Float32)^;
  Sign := (Bits shr 31) and $1;
  Exponent := (Bits shr 23) and $FF;
  Mantissa := Bits and $7FFFFF;
  if Exponent = $FF then
  begin
    if Mantissa <> 0 then
    begin
      HalfMantissa := Mantissa shr MantissaShift;
      if HalfMantissa = 0 then HalfMantissa := 1;
      Result.Value := Word((Sign shl 15) or Float16ExponentMask or HalfMantissa);
    end
    else
      Result.Value := Word((Sign shl 15) or Float16ExponentMask);
    Exit;
  end;
  Result.Value := Word(Sign shl 15);
  if Exponent > 142 then
  begin
    Result.Value := Result.Value or Float16ExponentMask;
    Exit;
  end;
  if Exponent < 113 then
  begin
    Mantissa := Mantissa or (1 shl SingleMantissaBits);
    Diff := 113 - Exponent;
    TotalShift := Diff + MantissaShift;
    if TotalShift >= 24 then
      Exit;
    GuardMask := Cardinal(1) shl (TotalShift - 1);
    StickyMask := GuardMask - 1;
    GuardBitIsOne := (Mantissa and GuardMask) <> 0;
    StickyBitsAreSet := (Mantissa and StickyMask) <> 0;
    HalfMantissa := Mantissa shr TotalShift;
    LSBIsOne := (HalfMantissa and 1) <> 0;
    RoundUp := GuardBitIsOne and (StickyBitsAreSet or LSBIsOne);
    if RoundUp then HalfMantissa := HalfMantissa + 1;
    if HalfMantissa = (1 shl Float16MantissaBits) then
      Result.Value := Result.Value or (1 shl Float16MantissaBits)
    else
      Result.Value := Result.Value or Word(HalfMantissa);
    Exit;
  end;
  HalfExponent := (Exponent - SingleBias + Float16Bias);
  GuardBitIsOne := (Mantissa and RoundingGuardBit) <> 0;
  StickyBitsAreSet := (Mantissa and RoundingStickyMask) <> 0;
  HalfMantissa := Mantissa shr MantissaShift;
  LSBIsOne := (HalfMantissa and 1) <> 0;
  RoundUp := GuardBitIsOne and (StickyBitsAreSet or LSBIsOne);
  if RoundUp then
  begin
    HalfMantissa := HalfMantissa + 1;
    if HalfMantissa = (1 shl Float16MantissaBits) then
    begin
      HalfMantissa := 0;
      HalfExponent := HalfExponent + 1;
      if HalfExponent = (Float16ExponentMask shr Float16MantissaBits) then
      begin
        Result.Value := Result.Value or Float16ExponentMask;
        Exit;
      end;
    end;
  end;
  Result.Value := Result.Value or Word(HalfExponent shl Float16MantissaBits) or Word(HalfMantissa);
end;

function TFloat16.ToSingle: Single;
type
  TFloatUnion = record
    case Integer of
      0: (Float32: Single);
      1: (Int32: Cardinal);
  end;
var
  Sign, Mantissa: LongWord;
  Exponent: Integer;
  FloatUnion: TFloatUnion;
begin
  Sign := (Value shr 15) and $1;
  Exponent  := (Value shr 10) and $1F;
  Mantissa := Value and $3FF;
  if Exponent = 0 then
  begin
    if Mantissa = 0 then
      FloatUnion.Int32 := Sign shl 31
    else begin
      Exponent := 1;
      while (Mantissa and $400) = 0 do
      begin
        Mantissa := Mantissa shl 1;
        Dec(Exponent);
      end;
      Mantissa := Mantissa and $3FF;
      Exponent := Exponent + (127 - 15);
      FloatUnion.Int32 := (Sign shl 31) or (LongWord(Exponent) shl 23) or (Mantissa shl 13);
    end;
  end
  else if Exponent = 31 then
    FloatUnion.Int32 := (Sign shl 31) or ($FF shl 23) or (Mantissa shl 13)
  else begin
    Exponent := Exponent + (127 - 15);
    FloatUnion.Int32 := (Sign shl 31) or (LongWord(Exponent) shl 23) or (Mantissa shl 13);
  end;
  Result := FloatUnion.Float32;
end;

class function TArrayRec.TIterator.ForEach<T>(const Target: TArray<T>; const Cycle: TCycle<T>;
  const P: Pointer): Boolean;
var
  I: Integer;
  A: ^T;
begin
  for I := Low(Target) to High(Target) do
  begin
    A := @Target[I];
    if not Cycle(A^, I, P) then Exit(False);
  end;
  Result := True;
end;

class function TArrayRec.TIterator.ForEach<T>(const Target: TArray<T>; const Empty: TEmpty<T>;
  const Alter: TAlter<T>; const P: Pointer): Integer;
var
  I, J: Integer;
  A, B: ^T;
begin
  Result := 0;
  for I := Low(Target) to High(Target) do
  begin
    A := @Target[I];
    if not Empty(A^, P) then
    begin
      J := Low(Target);
      while J < Length(Target) do
      begin
        B := @Target[J];
        if (I <> J) and not Empty(B^, P) and Alter(A^, B^, P) then
        begin
          Inc(Result);
          if Empty(A^, P) then Break;
          J := Low(Target);
        end
        else
          Inc(J);
      end;
    end;
  end;
end;

class function TArrayRec.TIterator.Iterate<T>(const Target: TArray<T>; const Cycle: TCycle<T>;
  const P: Pointer): TArray<T>;
begin
  ForEach<T>(Target, Cycle, P);
  Result := Target;
end;

class function TArrayRec.TIterator.Iterate<T>(const Target: TArray<T>; const Empty: TEmpty<T>;
  const Alter: TAlter<T>; const P: Pointer): TArray<T>;
begin
  ForEach<T>(Target, Empty, Alter, P);
  Result := Target;
end;

class function TArrayRec.Add<T>(var Target: TArray<T>; const Value: T): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  MemoryUtils.Add(Pointer(Target), @Value, Result * SizeOf(T), SizeOf(T));
end;

class function TArrayRec.Add<T>(var Target: TArray<T>; var Data: TArrayData; const Value: T): Integer;
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

class procedure TArrayRec.Apply<T>(var Target: TArray<T>; const Data: TArrayData);
begin
  SetLength(Target, Data.Index);
end;

class function TArrayRec.Delete<T>(var Target: TArray<T>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := (Index >= 0) and (Index < Size);
  if Result then
  begin
    if Index < Size - 1 then
      System.Move(Target[Index + 1], Target[Index], (Size - 1 - Index) * SizeOf(T));
    SetLength(Target, Size - 1);
  end;
end;

class procedure TArrayRec.Delete<T>(var Target: {$IFDEF FPC}TArray2<T>{$ELSE}TArray<TArray<T>>{$ENDIF});
var
  I: Integer;
begin
  for I := Low(Target) to High(Target) do Finalize(Target[I]);
  Target := nil;
end;

class function TArrayRec.New<T>(var Target: {$IFDEF FPC}TArray2<T>{$ELSE}TArray<TArray<T>>{$ENDIF}): Integer;
begin
  Result := High(Target);
  if (Result < 0) or (Length(Target[Result]) > 0) then
  begin
    Inc(Result);
    SetLength(Target, Result + 1);
  end;
end;

class function TArrayRec.Pack<T>(const Target: TArray<T>; const Empty: TIterator.TEmpty<T>;
  const P: Pointer): TArray<T>;
var
  I, J: Integer;
  Value: T;
begin
  Result := Copy(Target);
  J := 0;
  for I := Low(Result) to High(Result) do
    if not Empty(Result[J], P) then
      Inc(J)
    else
      if not Empty(Result[I], P) then
      begin
        Value := Result[J];
        Result[J] := Result[I];
        Result[I] := Value;
        Inc(J);
      end;
  SetLength(Result, J);
end;

class procedure TArrayRec.Reset<T>(var Target: TArray<T>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

class function TArrayRec.Union<T>(const Target: TArray<T>; const Empty: TIterator.TEmpty<T>;
  const Alter: TIterator.TAlter<T>; const P: Pointer): TArray<T>;
begin
  Result := Pack<T>(TIterator.Iterate<T>(Copy(Target), Empty, Alter, P), Empty, P);
end;

function TVector<T>.Add(const Value: T): Integer;
begin
  D.Count := Length(A);
  if D.Index >= D.Count then
  begin
    D.Count := D.Count + Increment;
    SetLength(A, D.Count);
  end;
  A[D.Index] := Value;
  Result := D.Index;
  Inc(D.Index);
end;

procedure TVector<T>.Apply;
begin
  SetLength(A, D.Index);
end;

function TVector<T>.At(const Index: Integer): P;
begin
  Result := @A[Index];
end;

function TVector<T>.BinarySearch(const Compare: TSearchCompare; const Value, P: Pointer): Integer;
begin
  Result := BSearch(A, Lo, Hi, Compare, Value, P);
end;

procedure TVector<T>.Clear;
begin
  Finalize(A);
  FillChar(D, SizeOf(TArrayData), 0);
end;

function TVector<T>.Delete(const Index: Integer): Boolean;
begin
  Result := TArrayRec.Delete<T>(A, Index);
  if Result then
  begin
    Dec(D.Count);
    if D.Index >= D.Count then D.Index := D.Count - 1;
  end;
end;

function TVector<T>.Empty: Boolean;
begin
  Result := not Assigned(A);
end;

{$IFDEF NOCLOSURES}
function TVector<T>.Find(const Compare: TCompare): P;
var
  I: Integer;
  Item: P;
begin
  Result := nil;
  for I := Lo to Hi do
  begin
    Item := At(I);
    if not Assigned(Result) or Compare(Item, Result) then Result := Item;
  end;
end;
{$ELSE}
function TVector<T>.Find(const Compare: TCompare): P;
begin
  Result := nil;
  ForEach(
    function(var Value: T; const Index: Integer; const P: Pointer): Boolean
    var
      Target: ^TVector<T>.P absolute P;
    begin
      if not Assigned(Target^) or Compare(@Value, Target^) then Target^ := @Value;
      Result := True;
    end,
    @Result);
end;
{$ENDIF}

function TVector<T>.Find(const Value: T; const Compare: TCompare): Integer;
var
  I: Integer;
begin
  for I := Lo to Hi do if Compare(At(I), @Value) then Exit(I);
  Result := -1;
end;

function TVector<T>.ForEach(const Cycle: TArrayRec.TIterator.TCycle<T>; const P: Pointer): Boolean;
begin
  Result := TArrayRec.TIterator.ForEach<T>(A, Cycle, P);
end;

function TVector<T>.ForEach(const Empty: TArrayRec.TIterator.TEmpty<T>;
  const Alter: TArrayRec.TIterator.TAlter<T>; const P: Pointer): Integer;
begin
  Result := TArrayRec.TIterator.ForEach<T>(A, Empty, Alter, P);
end;

function TVector<T>.GetSize: Integer;
begin
  Result := Length(A);
end;

function TVector<T>.Hi: Integer;
begin
  Result := High(A);
end;

function TVector<T>.Iterate(const Cycle: TArrayRec.TIterator.TCycle<T>; const P: Pointer): TArray<T>;
begin
  Result := TArrayRec.TIterator.Iterate<T>(A, Cycle, P);
end;

function TVector<T>.Iterate(const Empty: TArrayRec.TIterator.TEmpty<T>;
  const Alter: TArrayRec.TIterator.TAlter<T>; const P: Pointer): TArray<T>;
begin
  Result := TArrayRec.TIterator.Iterate<T>(A, Empty, Alter, P);
end;

function TVector<T>.Lo: Integer;
begin
  Result := Low(A);
end;

procedure TVector<T>.Pack(const Empty: TArrayRec.TIterator.TEmpty<T>; const P: Pointer);
begin
  A := TArrayRec.Pack<T>(A, Empty, P);
end;

function TVector<T>.Put(const Value: T): Integer;
begin
  Result := Length(A);
  SetLength(A, Result + 1);
  A[Result] := Value;
end;

procedure TVector<T>.Reset;
begin
  FillChar(D, SizeOf(TArrayData), 0);
  D.Index := Length(A);
end;

procedure TVector<T>.SetSize(const Value: Integer);
begin
  SetLength(A, Value);
end;

procedure TVector<T>.Sort(const Compare: TSortCompare; const Exchange: TSortExchange; const P: Pointer);
begin
  QSort(A, Lo, Hi, Compare, Exchange, P);
end;

procedure TVector<T>.Union(const Empty: TArrayRec.TIterator.TEmpty<T>;
  const Alter: TArrayRec.TIterator.TAlter<T>; const P: Pointer);
begin
  A := TArrayRec.Union<T>(A, Empty, Alter, P);
end;

function TMatrix.Check: Boolean;
var
  I, J: Integer;
begin
  if Length(RawData) = 0 then Exit(False);
  J := Length(RawData[0]);
  for I := 1 to Length(RawData) - 1 do if Length(RawData[I]) <> J then Exit(False);
  Result := True;
end;

procedure TMatrix.BeginUpdate;
begin
  Inc(UpdateCount);
end;

function TMatrix.BitFirstSet(const W: TBitWord): Integer;
{$IFDEF FPC}
begin
  Result := BsfQWord(W);
end;
{$ELSE}
var
  V: UInt64;
begin
  V := UInt64(W);
  Result := 0;
  if (V and $FFFFFFFF) = 0 then
  begin
    Inc(Result, 32);
    V := V shr 32;
  end;
  if (V and $FFFF) = 0 then
  begin
    Inc(Result, 16);
    V := V shr 16;
  end;
  if (V and $FF) = 0 then
  begin
    Inc(Result, 8);
    V := V shr 8;
  end;
  if (V and $F) = 0 then
  begin
    Inc(Result, 4);
    V := V shr 4;
  end;
  if (V and $3) = 0 then
  begin
    Inc(Result, 2);
    V := V shr 2;
  end;
  if (V and $1) = 0 then Inc(Result);
end;
{$ENDIF}

procedure TMatrix.BitsClear;
var
  Y, X: Integer;
begin
  for Y := 0 to Length(RowBits) - 1 do
    if Length(RowBits[Y]) > 0 then
      FillChar(RowBits[Y, 0], Length(RowBits[Y]) * SizeOf(TBitWord), 0);
  for X := 0 to Length(ColBits) - 1 do
    if Length(ColBits[X]) > 0 then
      FillChar(ColBits[X, 0], Length(ColBits[X]) * SizeOf(TBitWord), 0);
end;

procedure TMatrix.BitsEnsure;
var
  RowWords, ColWords: Integer;
begin
  if BitsDirty then
  begin
    if Check then
    begin
      BitsRebuild;
      BitsDirty := False;
    end;
    Exit;
  end;
  if (Length(RawData) = 0) or (Length(RawData[0]) = 0) then Exit;
  RowWords := BitWordCount(HSize);
  ColWords := BitWordCount(VSize);
  if (Length(RowBits) <> VSize) or (Length(ColBits) <> HSize) then
  begin
    BitsRebuild;
    Exit;
  end;
  if (VSize > 0) and (Length(RowBits[0]) <> RowWords) then
  begin
    BitsRebuild;
    Exit;
  end;
  if (HSize > 0) and (Length(ColBits[0]) <> ColWords) then
  begin
    BitsRebuild;
    Exit;
  end;
end;

procedure TMatrix.BitsFillAll;
var
  Y, X, I: Integer;
  RowWords, ColWords: Integer;
  LastBits: Integer;
  Mask: TBitWord;
begin
  BitsInit;
  RowWords := BitWordCount(HSize);
  ColWords := BitWordCount(VSize);
  for Y := 0 to VSize - 1 do for I := 0 to RowWords - 1 do
    RowBits[Y, I] := High(TBitWord);
  LastBits := HSize and 63;
  if (RowWords > 0) and (LastBits <> 0) then
  begin
    Mask := (TBitWord(1) shl LastBits) - 1;
    for Y := 0 to VSize - 1 do
      RowBits[Y, RowWords - 1] := RowBits[Y, RowWords - 1] and Mask;
  end;
  for X := 0 to HSize - 1 do for I := 0 to ColWords - 1 do
    ColBits[X, I] := High(TBitWord);
  LastBits := VSize and 63;
  if (ColWords > 0) and (LastBits <> 0) then
  begin
    Mask := (TBitWord(1) shl LastBits) - 1;
    for X := 0 to HSize - 1 do
      ColBits[X, ColWords - 1] := ColBits[X, ColWords - 1] and Mask;
  end;
end;

procedure TMatrix.BitsInit;
var
  Y, X: Integer;
  RowWords, ColWords: Integer;
begin
  RowWords := BitWordCount(HSize);
  ColWords := BitWordCount(VSize);
  if (Length(RowBits) <> VSize) or (VSize > 0) and (Length(RowBits[0]) <> RowWords) then
  begin
    SetLength(RowBits, VSize);
    for Y := 0 to VSize - 1 do SetLength(RowBits[Y], RowWords);
  end;
  if (Length(ColBits) <> HSize) or (HSize > 0) and (Length(ColBits[0]) <> ColWords) then
  begin
    SetLength(ColBits, HSize);
    for X := 0 to HSize - 1 do SetLength(ColBits[X], ColWords);
  end;
end;

procedure TMatrix.BitsRebuild;
var
  X, Y, Idx, Bit: Integer;
  Mask: TBitWord;
begin
  BitsInit;
  BitsClear;
  for Y := 0 to VSize - 1 do for X := 0 to HSize - 1 do
    if Assigned(RawData[Y, X]) then
    begin
      Idx := X shr 6;
      Bit := X and 63;
      Mask := TBitWord(1) shl Bit;
      RowBits[Y, Idx] := RowBits[Y, Idx] or Mask;
      Idx := Y shr 6;
      Bit := Y and 63;
      Mask := TBitWord(1) shl Bit;
      ColBits[X, Idx] := ColBits[X, Idx] or Mask;
    end;
  BitsDirty := False;
end;

procedure TMatrix.BitsAssign(const X, Y: Integer; const Value: Pointer);
var
  Idx, Bit: Integer;
  Mask: TBitWord;
begin
  Idx := X shr 6;
  Bit := X and 63;
  Mask := TBitWord(1) shl Bit;
  if Value = nil then
    RowBits[Y, Idx] := RowBits[Y, Idx] and (not Mask)
  else
    RowBits[Y, Idx] := RowBits[Y, Idx] or Mask;
  Idx := Y shr 6;
  Bit := Y and 63;
  Mask := TBitWord(1) shl Bit;
  if Value = nil then
    ColBits[X, Idx] := ColBits[X, Idx] and (not Mask)
  else
    ColBits[X, Idx] := ColBits[X, Idx] or Mask;
end;

function TMatrix.BitWordCount(const N: Integer): Integer;
begin
  Result := (N + 63) shr 6;
end;

function TMatrix.Check(const Point: TPoint): Boolean;
begin
  Result := Check(Point.X, Point.Y);
end;

function TMatrix.Check(const X, Y: Integer): Boolean;
begin
  Result := (Y >= 0) and (Y < Length(RawData)) and (X >= 0) and (X < Length(RawData[Y]));
end;

function TMatrix.ColNextSet(const X, YMin, YMax: Integer; var YFound: Integer): Boolean;
var
  Idx, IdxLast, Bit, BitLast: Integer;
  W, Mask: TBitWord;
begin
  Result := False;
  if YMin > YMax then Exit;
  Idx := YMin shr 6;
  IdxLast := YMax shr 6;
  Bit := YMin and 63;
  while Idx <= IdxLast do
  begin
    W := ColBits[X, Idx];
    if Bit <> 0 then
    begin
      Mask := (TBitWord(1) shl Bit) - 1;
      W := W and (not Mask);
    end;
    if Idx = IdxLast then
    begin
      BitLast := YMax and 63;
      if BitLast <> 63 then
      begin
        Mask := (TBitWord(1) shl (BitLast + 1)) - 1;
        W := W and Mask;
      end;
    end;
    if W <> 0 then
    begin
      YFound := (Idx shl 6) + BitFirstSet(W);
      Exit(True);
    end;
    Inc(Idx);
    Bit := 0;
  end;
end;

class function TMatrix.Copy(const Matrix: TMatrix): TMatrix;
var
  I: Integer;
begin
  Result.Reset;
  if not Matrix.Check then Exit;
  Result.RawData := System.Copy(Matrix.RawData);
  for I := 0 to Length(Matrix.RawData) - 1 do Result.RawData[I] := System.Copy(Matrix.RawData[I]);
  Result.BitsRebuild;
end;

function TMatrix.DivideIntoSegments(const Center: TPoint; const Angles: TArray<Extended>): Boolean;

  function GetSegmentIndex(const PointAngle: Extended; const Angles: TArray<Extended>): Integer;
  var
    L, H, M: Integer;
  begin
    L := 0;
    H := Length(Angles) - 1;
    while L <= H do
    begin
      M := (L + H) div 2;
      if PointAngle < Angles[M] then
        H := M - 1
      else
        L := M + 1;
    end;
    Result := H;
    if Result < 0 then Result := Length(Angles) - 1;
  end;

var
  Size: TSize;
  I, J, Index: Integer;
  Point: TPoint;
  Angle: Extended;
begin
  Size := TSize.Create(HSize, VSize);
  if (Size.cx < 2) or (Size.cy < 2) then Exit(False);
  if (Center.X < 1) or (Center.X >= Size.cx - 1) or (Center.Y < 1) or (Center.Y >= Size.cy - 1) then
    Exit(False);
  case Length(Angles) of
    0..1: Fill(Pointer(1));
  else
    for I := 0 to Size.cy - 1 do for J := 0 to Size.cx - 1 do
    begin
      Point := TPoint.Create(J, I);
      Angle := ArcTan2(Point.Y - Center.Y, Point.X - Center.X);
      if Angle < 0 then Angle := Angle + 2 * Pi;
      Index := GetSegmentIndex(Angle, Angles);
      RawData[I, J] := Pointer(Index + 1);
    end;
    BitsFillAll;
  end;
  Result := True;
end;

procedure TMatrix.EndUpdate;
begin
  if UpdateCount > 0 then Dec(UpdateCount);
  if (UpdateCount = 0) and BitsDirty and Check then
  begin
    BitsRebuild;
    BitsDirty := False;
  end;
end;

class function TMatrix.Expand(const Point: TPoint; const Size: TSize; const Cycle: TCycle; const Stop: TStop;
  const P: Pointer): Integer;
begin
  Result := Expand(Point.X, Point.Y, Size, Cycle, Stop, P);
end;

class function TMatrix.Expand(const X, Y: Integer; const Size: TSize; const Cycle: TCycle; const Stop: TStop;
  const P: Pointer): Integer;
type
  TPrev = record
    A: TPoint;
    B: TPoint;
    Flag: Boolean;
  end;
var
  Prev: TPrev;
  Step: Integer;
  A, B: TPoint;
  I: Integer;
begin
  Result := 0;
  FillChar(Prev, SizeOf(TPrev), 0);
  Step := 0;
  Inc(Result);
  if not Cycle(X, Y, Step, P) then Exit;
  for Step := 1 to Max(Size.cx, Size.cy) - 1 do
  begin
    if Stop(Step, P) then Exit;
    A.X := Max(0, X - Step);
    A.Y := Max(0, Y - Step);
    B.X := Min(Size.cx - 1, X + Step);
    B.Y := Min(Size.cy - 1, Y + Step);
    repeat
      if Prev.Flag and (A.Y = Prev.A.Y) then
      begin
        for I := A.X to Prev.A.X - 1 do
        begin
          Inc(Result);
          if not Cycle(I, A.Y, Step, P) then Exit;
        end;
        for I := Prev.B.X + 1 to B.X do
        begin
          Inc(Result);
          if not Cycle(I, A.Y, Step, P) then Exit;
        end;
        Break;
      end;
      for I := A.X to B.X do
      begin
        if (I = X) and (A.Y = Y) then Continue;
        Inc(Result);
        if not Cycle(I, A.Y, Step, P) then Exit;
      end;
    until True;
    repeat
      if Prev.Flag and (B.Y = Prev.B.Y) then
      begin
        for I := A.X to Prev.A.X - 1 do
        begin
          Inc(Result);
          if not Cycle(I, B.Y, Step, P) then Exit;
        end;
        for I := Prev.B.X + 1 to B.X do
        begin
          Inc(Result);
          if not Cycle(I, B.Y, Step, P) then Exit;
        end;
        Break;
      end;
      for I := A.X to B.X do
      begin
        if (I = X) and (B.Y = Y) then Continue;
        Inc(Result);
        if not Cycle(I, B.Y, Step, P) then Exit;
      end;
    until True;
    repeat
      if Prev.Flag and (A.X = Prev.A.X) then
      begin
        for I := A.Y + 1 to Prev.A.Y - 1 do
        begin
          Inc(Result);
          if not Cycle(A.X, I, Step, P) then Exit;
        end;
        for I := Prev.B.Y + 1 to B.Y - 1 do
        begin
          Inc(Result);
          if not Cycle(A.X, I, Step, P) then Exit;
        end;
        Break;
      end;
      for I := A.Y + 1 to B.Y - 1 do
      begin
        if (A.X = X) and (I = Y) then Continue;
        Inc(Result);
        if not Cycle(A.X, I, Step, P) then Exit;
      end;
    until True;
    repeat
      if Prev.Flag and (B.X = Prev.B.X) then
      begin
        for I := A.Y + 1 to Prev.A.Y - 1 do
        begin
          Inc(Result);
          if not Cycle(B.X, I, Step, P) then Exit;
        end;
        for I := Prev.B.Y + 1 to B.Y - 1 do
        begin
          Inc(Result);
          if not Cycle(B.X, I, Step, P) then Exit;
        end;
        Break;
      end;
      for I := A.Y + 1 to B.Y - 1 do
      begin
        if (B.X = X) and (I = Y) then Continue;
        Inc(Result);
        if not Cycle(B.X, I, Step, P) then Exit;
      end;
    until True;
    Prev.A := A;
    Prev.B := B;
    Prev.Flag := True;
  end;
end;

procedure TMatrix.Fill(const Value: Pointer);
var
  I, J: Integer;
begin
  for I := 0 to Length(RawData) - 1 do for J := 0 to Length(RawData[I]) - 1 do
    RawData[I, J] := Value;
  if Check then
    if Value = nil then
    begin
      BitsInit;
      BitsClear;
    end
    else
      BitsFillAll;
  BitsDirty := False;
end;

procedure TMatrix.Free;
var
  I: Integer;
begin
  for I := Low(RawData) to High(RawData) do RawData[I] := nil;
  RawData := nil;
  RowBits := nil;
  ColBits := nil;
end;

class function TMatrix.GenerateAngles(const NumSegments: Integer; const MinAngle: Extended): TArray<Extended>;
var
  TotalAvailableAngle, AngleStep: Extended;
  I: Integer;
begin
  if NumSegments = 0 then Exit(nil);
  TotalAvailableAngle := 2 * Pi;
  AngleStep := TotalAvailableAngle / NumSegments;
  if AngleStep < MinAngle then Exit(nil);
  SetLength(Result, NumSegments);
  for I := 0 to NumSegments - 1 do Result[I] := I * AngleStep;
  Sort(Result);
end;

class function TMatrix.GenerateRandomAngles(const NumSegments: Integer;
  const MinAngle: Extended): TArray<Extended>;
var
  TotalAvailableAngle, RemainingAngle: Extended;
  I: Integer;
begin
  if NumSegments = 0 then Exit(nil);
  TotalAvailableAngle := 2 * Pi;
  if NumSegments * MinAngle > TotalAvailableAngle then Exit(nil);
  RemainingAngle := TotalAvailableAngle - NumSegments * MinAngle;
  SetLength(Result, NumSegments);
  Result[0] := Random * TotalAvailableAngle;
  for I := 1 to NumSegments - 1 do
  begin
    Result[I] := Result[I - 1] + MinAngle + Random * (RemainingAngle / (NumSegments - I));
    RemainingAngle := RemainingAngle - (Result[I] - Result[I - 1] - MinAngle);
  end;
  for I := 0 to NumSegments - 1 do
    if Result[I] >= 2 * Pi then Result[I] := Result[I] - 2 * Pi;
  Sort(Result);
end;

function TMatrix.GetEmpty: Boolean;
var
  I: Integer;
begin
  if VSize = 0 then Exit(True);
  for I := 0 to VSize - 1 do if Length(RawData[I]) = 0 then Exit(True);
  Result := False;
end;

function TMatrix.GetFlag(const X, Y: Integer): Boolean;
begin
  if not Check(X, Y) then Exit(False);
  Result := RawData[Y, X] <> nil;
end;

function TMatrix.GetHSize: Integer;
begin
  if Length(RawData) = 0 then
    Result := 0
  else
    Result := Length(RawData[0]);
end;

function TMatrix.GetVSize: Integer;
begin
  Result := Length(RawData);
end;

function TMatrix.GetData(const X, Y: Integer): Pointer;
begin
  if Check(X, Y) then
    Result := RawData[Y, X]
  else
    Result := nil;
end;

procedure TMatrix.InvalidateBits;
begin
  BitsDirty := True;
  if (UpdateCount = 0) and Check then
  begin
    BitsRebuild;
    BitsDirty := False;
  end;
end;

class function TMatrix.Make(const HSize, VSize: Integer): TMatrix;
var
  I: Integer;
begin
  Result.Reset;
  SetLength(Result.RawData, VSize);
  for I := Low(Result.RawData) to High(Result.RawData) do
    SetLength(Result.RawData[I], HSize);
  Result.BitsInit;
  Result.BitsClear;
end;

class function TMatrix.Make(const Size: TSize): TMatrix;
begin
  Result := Make(Size.cx, Size.cy);
end;

procedure TMatrix.Reset;
begin
  FillChar(Self, SizeOf(TMatrix), 0);
end;

function TMatrix.RowNextSet(const Y, XMin, XMax: Integer; var XFound: Integer): Boolean;
var
  Idx, IdxLast, Bit, BitLast: Integer;
  W, Mask: TBitWord;
begin
  Result := False;
  if XMin > XMax then Exit;
  Idx := XMin shr 6;
  IdxLast := XMax shr 6;
  Bit := XMin and 63;
  while Idx <= IdxLast do
  begin
    W := RowBits[Y, Idx];
    if Bit <> 0 then
    begin
      Mask := (TBitWord(1) shl Bit) - 1;
      W := W and (not Mask);
    end;
    if Idx = IdxLast then
    begin
      BitLast := XMax and 63;
      if BitLast <> 63 then
      begin
        Mask := (TBitWord(1) shl (BitLast + 1)) - 1;
        W := W and Mask;
      end;
    end;
    if W <> 0 then
    begin
      XFound := (Idx shl 6) + BitFirstSet(W);
      Exit(True);
    end;
    Inc(Idx);
    Bit := 0;
  end;
end;

function TMatrix.Search(const Point: TPoint; const Compare: TCompare; const Stop: TStop;
  const P: Pointer): Pointer;
begin
  Result := Search(Point.X, Point.Y, Compare, Stop, P);
end;

function TMatrix.Search(const X, Y: Integer; const Compare: TCompare; const Stop: TStop;
  const P: Pointer): Pointer;
type
  TPrev = record
    A: TPoint;
    B: TPoint;
  end;
  TFlag = record
    Stop: Boolean;
    Prev: Boolean;
  end;
var
  Flag: TFlag;
  Step: Integer;
  Size: TSize;
  Prev: TPrev;
  A, B: TPoint;
  I: Integer;
begin
  if not Check(X, Y) then Exit(nil);
  FillChar(Flag, SizeOf(TFlag), 0);
  BitsEnsure;
  Step := 0;
  if Assigned(RawData[Y, X]) and Compare(X, Y, RawData[Y, X], Step, Flag.Stop, P) then
    Exit(RawData[Y, X]);
  if Flag.Stop then Exit(nil);
  Size.cx := Length(RawData[0]);
  Size.cy := Length(RawData);
  for Step := 1 to Max(Size.cx, Size.cy) - 1 do
  begin
    if Stop(Step, P) then Exit(nil);
    A.X := Max(0, X - Step);
    A.Y := Max(0, Y - Step);
    B.X := Min(Size.cx - 1, X + Step);
    B.Y := Min(Size.cy - 1, Y + Step);
    repeat
      if Flag.Prev and (A.Y = Prev.A.Y) then
      begin
        if A.X <= Prev.A.X - 1 then
        begin
          I := A.X;
          while RowNextSet(A.Y, I, Prev.A.X - 1, I) do
          begin
            if Assigned(RawData[A.Y, I]) and Compare(I, A.Y, RawData[A.Y, I], Step, Flag.Stop, P) then
              Exit(RawData[A.Y, I]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        if Prev.B.X + 1 <= B.X then
        begin
          I := Prev.B.X + 1;
          while RowNextSet(A.Y, I, B.X, I) do
          begin
            if Assigned(RawData[A.Y, I]) and Compare(I, A.Y, RawData[A.Y, I], Step, Flag.Stop, P) then
              Exit(RawData[A.Y, I]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        Break;
      end;
      I := A.X;
      while RowNextSet(A.Y, I, B.X, I) do
      begin
        if (I = X) and (A.Y = Y) then
        begin
          Inc(I);
          Continue;
        end;
        if Assigned(RawData[A.Y, I]) and Compare(I, A.Y, RawData[A.Y, I], Step, Flag.Stop, P) then
          Exit(RawData[A.Y, I]);
        if Flag.Stop then Exit(nil);
        Inc(I);
      end;
    until True;
    repeat
      if Flag.Prev and (B.Y = Prev.B.Y) then
      begin
        if A.X <= Prev.A.X - 1 then
        begin
          I := A.X;
          while RowNextSet(B.Y, I, Prev.A.X - 1, I) do
          begin
            if Assigned(RawData[B.Y, I]) and Compare(I, B.Y, RawData[B.Y, I], Step, Flag.Stop, P) then
              Exit(RawData[B.Y, I]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        if Prev.B.X + 1 <= B.X then
        begin
          I := Prev.B.X + 1;
          while RowNextSet(B.Y, I, B.X, I) do
          begin
            if Assigned(RawData[B.Y, I]) and Compare(I, B.Y, RawData[B.Y, I], Step, Flag.Stop, P) then
              Exit(RawData[B.Y, I]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        Break;
      end;
      I := A.X;
      while RowNextSet(B.Y, I, B.X, I) do
      begin
        if (I = X) and (B.Y = Y) then
        begin
          Inc(I);
          Continue;
        end;
        if Assigned(RawData[B.Y, I]) and Compare(I, B.Y, RawData[B.Y, I], Step, Flag.Stop, P) then
          Exit(RawData[B.Y, I]);
        if Flag.Stop then Exit(nil);
        Inc(I);
      end;
    until True;
    repeat
      if Flag.Prev and (A.X = Prev.A.X) then
      begin
        if (A.Y + 1 <= Prev.A.Y - 1) then
        begin
          I := A.Y + 1;
          while ColNextSet(A.X, I, Prev.A.Y - 1, I) do
          begin
            if Assigned(RawData[I, A.X]) and Compare(A.X, I, RawData[I, A.X], Step, Flag.Stop, P) then
              Exit(RawData[I, A.X]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        if (Prev.B.Y + 1 <= B.Y - 1) then
        begin
          I := Prev.B.Y + 1;
          while ColNextSet(A.X, I, B.Y - 1, I) do
          begin
            if Assigned(RawData[I, A.X]) and Compare(A.X, I, RawData[I, A.X], Step, Flag.Stop, P) then
              Exit(RawData[I, A.X]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        Break;
      end;
      if (A.Y + 1 <= B.Y - 1) then
      begin
        I := A.Y + 1;
        while ColNextSet(A.X, I, B.Y - 1, I) do
        begin
          if (A.X = X) and (I = Y) then
          begin
            Inc(I);
            Continue;
          end;
          if Assigned(RawData[I, A.X]) and Compare(A.X, I, RawData[I, A.X], Step, Flag.Stop, P) then
            Exit(RawData[I, A.X]);
          if Flag.Stop then Exit(nil);
          Inc(I);
        end;
      end;
    until True;
    repeat
      if Flag.Prev and (B.X = Prev.B.X) then
      begin
        if (A.Y + 1 <= Prev.A.Y - 1) then
        begin
          I := A.Y + 1;
          while ColNextSet(B.X, I, Prev.A.Y - 1, I) do
          begin
            if Assigned(RawData[I, B.X]) and Compare(B.X, I, RawData[I, B.X], Step, Flag.Stop, P) then
              Exit(RawData[I, B.X]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        if (Prev.B.Y + 1 <= B.Y - 1) then
        begin
          I := Prev.B.Y + 1;
          while ColNextSet(B.X, I, B.Y - 1, I) do
          begin
            if Assigned(RawData[I, B.X]) and Compare(B.X, I, RawData[I, B.X], Step, Flag.Stop, P) then
              Exit(RawData[I, B.X]);
            if Flag.Stop then Exit(nil);
            Inc(I);
          end;
        end;
        Break;
      end;
      if (A.Y + 1 <= B.Y - 1) then
      begin
        I := A.Y + 1;
        while ColNextSet(B.X, I, B.Y - 1, I) do
        begin
          if (B.X = X) and (I = Y) then
          begin
            Inc(I);
            Continue;
          end;
          if Assigned(RawData[I, B.X]) and Compare(B.X, I, RawData[I, B.X], Step, Flag.Stop, P) then
            Exit(RawData[I, B.X]);
          if Flag.Stop then Exit(nil);
          Inc(I);
        end;
      end;
    until True;
    Prev.A := A;
    Prev.B := B;
    Flag.Prev := True;
  end;
  Result := nil;
end;

function TMatrix.Segment(const Rect: TRect): TMatrix;
var
  I, J, RowCount, ColCount, RowIndex: Integer;
  V: Pointer;
begin
  Result.Reset;
  if Empty then Exit;
  if (Rect.Left < 0) or (Rect.Top < 0) or (Rect.Right <= Rect.Left) or (Rect.Bottom <= Rect.Top) then
    Exit;
  if Rect.Bottom > VSize then Exit;
  for I := Rect.Top to Rect.Bottom - 1 do if Rect.Right > Length(RawData[I]) then Exit;
  RowCount := Rect.Bottom - Rect.Top;
  ColCount := Rect.Right - Rect.Left;
  Result := TMatrix.Make(ColCount, RowCount);
  for I := 0 to RowCount - 1 do
  begin
    RowIndex := Rect.Top + I;
    for J := 0 to ColCount - 1 do
    begin
      V := RawData[RowIndex, Rect.Left + J];
      Result.RawData[I, J] := V;
      Result.BitsAssign(J, I, V);
    end;
  end;
end;

procedure TMatrix.SetFlag(const X, Y: Integer; Value: Boolean);
begin
  if not Check(X, Y) then Exit;
  RawData[Y, X] := Pointer(Value);
  if UpdateCount <> 0 then
  begin
    BitsDirty := True;
    Exit;
  end;
  BitsEnsure;
  BitsAssign(X, Y, RawData[Y, X]);
end;

procedure TMatrix.SetData(const X, Y: Integer; Value: Pointer);
begin
  if not Check(X, Y) then Exit;
  RawData[Y, X] := Value;
  if UpdateCount <> 0 then
  begin
    BitsDirty := True;
    Exit;
  end;
  BitsEnsure;
  BitsAssign(X, Y, Value);
end;

procedure TMatrix.Write(const A: TArray<TArray<TPoint>>; const Value: Pointer);
var
  I: Integer;
begin
  for I := Low(A) to High(A) do Write(A[I], Value);
end;

procedure TMatrix.Write(const A: TArray<TPoint>; const Value: Pointer);
var
  I: Integer;
begin
  if UpdateCount <> 0 then
  begin
    BitsDirty := True;
    for I := Low(A) to High(A) do
      if Check(A[I]) then
        RawData[A[I].Y, A[I].X] := Value;
    Exit;
  end;
  BitsEnsure;
  for I := Low(A) to High(A) do
    if Check(A[I]) then
    begin
      RawData[A[I].Y, A[I].X] := Value;
      BitsAssign(A[I].X, A[I].Y, Value);
    end;
end;

{$IFDEF FPC}
procedure MoveMemory(Destination, Source: Pointer; Length: NativeUInt);
begin
  Move(Source^, Destination^, Length);
end;

procedure CopyMemory(Destination, Source: Pointer; Length: NativeUInt);
begin
  Move(Source^, Destination^, Length);
end;

procedure FillMemory(Destination: Pointer; Length: NativeUInt; Fill: Byte);
begin
  FillChar(Destination^, Length, Fill);
end;

procedure ZeroMemory(Destination: Pointer; Length: NativeUInt);
begin
  FillChar(Destination^, Length, 0);
end;

function MakeWord(A, B: Byte): Word;
begin
  Result := A or B shl 8;
end;

function MakeLong(A, B: Word): Longint;
begin
  Result := A or B shl 16;
end;

function HiWord(L: DWORD): Word;
begin
  Result := L shr 16;
end;

function HiByte(W: Word): Byte;
begin
  Result := W shr 8;
end;
{$ENDIF}

function MakeU16(const Lo, Hi: Byte): Word;
begin
  TU16(Result).Lo := Lo;
  TU16(Result).Hi := Hi;
end;

function MakeU32(const Lo, Hi: Word): LongWord;
begin
  TU32(Result).Lo := Lo;
  TU32(Result).Hi := Hi;
end;

function MakeU64(const Lo, Hi: LongWord): UInt64;
begin
  TU64(Result).Lo := Lo;
  TU64(Result).Hi := Hi;
end;

function Make16(const A, B: Byte): T16;
begin
  Result.A := A;
  Result.B := B;
end;

function Make24(const A, B, C: Byte): T24;
begin
  Result.A := A;
  Result.B := B;
  Result.C := C;
end;

function Make32(const A, B, C, D: Byte): T32;
begin
  Result.A := A;
  Result.B := B;
  Result.C := C;
  Result.D := D;
end;

function Make64(const A, B, C, D, E, F, G, H: Byte): T64;
begin
  Result.A := A;
  Result.B := B;
  Result.C := C;
  Result.D := D;
  Result.E := E;
  Result.F := F;
  Result.G := G;
  Result.H := H;
end;

function MakeArray(const Value: array of NativeInt): TArray<NativeInt>;
var
  I: NativeInt;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(NativeInt));
end;

function MakeArray(const Value: array of NativeUInt): TArray<NativeUInt>;
var
  I: NativeUInt;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(NativeUInt));
end;

function MakeArray(const Value: array of Int64): TArray<Int64>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Int64));
end;

function MakeArray(const Value: array of Integer): TArray<Integer>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Integer));
end;

function MakeArray(const Value: array of Word): TArray<Word>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Word));
end;

function MakeArray(const Value: array of Byte): TArray<Byte>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Byte));
end;

function MakeArray(const Value: array of Single): TArray<Single>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Single));
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function MakeArray(const Value: array of Double): TArray<Double>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Double));
end;
{$ENDIF}

function MakeArray(const Value: array of Extended): TArray<Extended>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Extended));
end;

function MakeArray(const Value: array of Char): TArray<Char>;
var
  I: Integer;
begin
  I := Length(Value);
  SetLength(Result, I);
  CopyMemory(Pointer(Result), @Value, I * SizeOf(Char));
end;

function MakeArray(const Value: array of string): TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, Length(Value));
  for I := Low(Value) to High(Value) do Result[I] := Value[I];
end;

function UnionArray(const Target: array of TNativeIntDynArray): TArray<NativeInt>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TNativeUIntDynArray): TArray<NativeUInt>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TInt64DynArray): TArray<Int64>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TIntegerDynArray): TArray<Integer>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TWordDynArray): TArray<Word>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TByteDynArray): TArray<Byte>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TSingleDynArray): TArray<Single>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TDoubleDynArray): TArray<Double>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TExtendedDynArray): TArray<Extended>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TCharDynArray): TArray<Char>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

function UnionArray(const Target: array of TStringDynArray): TArray<string>;
var
  I, J, K: Integer;
begin
  K := 0;
  for I := Low(Target) to High(Target) do Inc(K, Length(Target[I]));
  SetLength(Result, K);
  K := 0;
  for I := Low(Target) to High(Target) do for J := Low(Target[I]) to High(Target[I]) do
  begin
    Result[K] := Target[I, J];
    Inc(K);
  end;
  SetLength(Result, K);
end;

procedure Reset(var Target: TArray<NativeInt>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<NativeUInt>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<Int64>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<Integer>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<Word>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<Byte>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<Single>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Reset(var Target: TArray<Double>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;
{$ENDIF}

procedure Reset(var Target: TArray<Extended>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<Char>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Reset(var Target: TArray<string>; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Apply(var Target: TArray<NativeInt>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<NativeUInt>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<Int64>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<Integer>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<Word>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<Byte>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<Single>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Apply(var Target: TArray<Double>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;
{$ENDIF}

procedure Apply(var Target: TArray<Extended>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<Char>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Apply(var Target: TArray<string>; const Data: TArrayData);
begin
  Resize(Target, Data.Index);
end;

procedure Add(const Target, Source: Pointer; const TargetSize, SourceSize: Integer);
begin
  CopyMemory(PAnsiChar(Target) + TargetSize, Source, SourceSize);
end;

function Add(var Target: TArray<NativeInt>; const Value: NativeInt; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(NativeInt), SizeOf(NativeInt));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<NativeInt>; var Data: TArrayData; const Value: NativeInt;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<NativeInt>; const Value: NativeInt; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<NativeUInt>; const Value: NativeUInt; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(NativeUInt), SizeOf(NativeUInt));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<NativeUInt>; var Data: TArrayData; const Value: NativeUInt;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<NativeUInt>; const Value: NativeUInt; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<Int64>; const Value: Int64; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Int64), SizeOf(Int64));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Int64>; var Data: TArrayData; const Value: Int64;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Int64>; const Value: Int64; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<Integer>; const Value: Integer; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Integer), SizeOf(Integer));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Integer>; var Data: TArrayData; const Value: Integer;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Integer>; const Value: Integer; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<Word>; const Value: Word; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Word), SizeOf(Word));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Word>; var Data: TArrayData; const Value: Word;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Word>; const Value: Word; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<Byte>; const Value: Byte; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Byte), SizeOf(Byte));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Byte>; var Data: TArrayData; const Value: Byte;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Byte>; const Value: Byte; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<Single>; const Value: Single; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Single), SizeOf(Single));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Single>; var Data: TArrayData; const Value: Single;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Single>; const Value: Single; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Add(var Target: TArray<Double>; const Value: Double; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Double), SizeOf(Double));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Double>; var Data: TArrayData; const Value: Double;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Double>; const Value: Double; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;
{$ENDIF}

function Add(var Target: TArray<Extended>; const Value: Extended; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Extended), SizeOf(Extended));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Extended>; var Data: TArrayData; const Value: Extended;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Extended>; const Value: Extended; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<Char>; const Value: Char; const Unique: Boolean = False): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Add(Pointer(Target), @Value, Result * SizeOf(Char), SizeOf(Char));
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<Char>; var Data: TArrayData; const Value: Char;
  const Unique: Boolean = False): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<Char>; const Value: Char; const Unique: Boolean = False);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

function Add(var Target: TArray<string>; const Value: string; const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
  begin
    Result := Length(Target);
    SetLength(Target, Result + 1);
    Target[Result] := Value;
  end
  else
    Result := -1;
end;

function Add(var Target: TArray<string>; var Data: TArrayData; const Value: string;
  const Unique: Boolean): Integer;
begin
  if not Unique or Unique and (IndexOf(Target, Value) < 0) then
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
  end
  else
    Result := -1;
end;

procedure Push(var Target: TArray<string>; const Value: string; const Unique: Boolean);
begin
  Add(Target, Value, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<NativeInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: NativeInt;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<NativeInt>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: NativeInt;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<NativeInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<NativeUInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: NativeUInt;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<NativeUInt>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: NativeUInt;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<NativeUInt>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<Int64>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Int64;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Int64>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Int64;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Int64>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<Integer>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Integer;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Integer>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Integer;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Integer>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<Word>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Word;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Word>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Word;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Word>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<Byte>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Byte;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Byte>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Byte;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Byte>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<Single>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Single;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Single>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Single;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Single>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Add(var Target: TArray<Double>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Double;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Double>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Double;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Double>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;
{$ENDIF}

procedure Add(var Target: TArray<Extended>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Extended;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Extended>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Extended;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Extended>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

procedure Add(var Target: TArray<Char>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
var
  Data: TArrayData;
  I: Integer;
  Value: Char;
begin
  Reset(Target, Data);
  try
    I := 0;
    while I < Count do
      if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
  finally
    Apply(Target, Data);
  end;
end;

procedure Add(var Target: TArray<Char>; var Data: TArrayData; const Count: Integer; const Next: TNext;
  const P: Pointer; const Unique: Boolean);
var
  I: Integer;
  Value: Char;
begin
  I := 0;
  while I < Count do
    if Next(I, Count, @Value, P) then Add(Target, Data, Value, Unique);
end;

procedure Push(var Target: TArray<Char>; const Count: Integer; const Next: TNext; const P: Pointer;
  const Unique: Boolean);
begin
  Add(Target, Count, Next, P, Unique);
  Sort(Target);
end;

function NativeIntNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PNativeInt(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<NativeInt>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}NativeIntNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<NativeInt>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}NativeIntNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<NativeInt>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function NativeUIntNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PNativeUInt(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<NativeUInt>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}NativeUIntNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<NativeUInt>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}NativeUIntNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<NativeUInt>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function Int64Next(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PInt64(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Int64>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}Int64Next, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Int64>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}Int64Next, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Int64>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function IntegerNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PInteger(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Integer>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}IntegerNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Integer>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}IntegerNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Integer>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function WordNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PWord(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Word>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}WordNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Word>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}WordNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Word>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function ByteNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PByte(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Byte>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}ByteNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Byte>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}ByteNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Byte>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function SingleNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PSingle(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Single>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}SingleNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Single>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}SingleNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Single>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function DoubleNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PDouble(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Double>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}DoubleNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Double>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}DoubleNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Double>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;
{$ENDIF}

function ExtendedNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PExtended(Value)^ := PInteger(P)^ + Index;
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Extended>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}ExtendedNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Extended>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}ExtendedNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Extended>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function CharNext(var Index: Integer; const Count: Integer; const Value, P: Pointer): Boolean;
begin
  PChar(Value)^ := Chr(PInteger(P)^ + Index);
  Inc(Index);
  Result := True;
end;

procedure Add(var Target: TArray<Char>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, Count, {$IFDEF FPC}@{$ENDIF}CharNext, @FromIndex, Unique);
end;

procedure Add(var Target: TArray<Char>; var Data: TArrayData; const FromIndex, Count: Integer;
  const Unique: Boolean);
begin
  Add(Target, Data, Count, {$IFDEF FPC}@{$ENDIF}CharNext, @FromIndex, Unique);
end;

procedure Push(var Target: TArray<Char>; const FromIndex, Count: Integer; const Unique: Boolean);
begin
  Add(Target, FromIndex, Count, Unique);
  Sort(Target);
end;

function Delete(const Target: Pointer; const Index, Count, TargetSize: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index + Count <= TargetSize);
  if Result and (Index + Count < TargetSize) then
    MoveMemory(PAnsiChar(Target) + Index, PAnsiChar(Target) + Index + Count, TargetSize - Index - Count);
end;

function Delete(var Target: TArray<NativeInt>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(NativeInt), SizeOf(NativeInt), Size * SizeOf(NativeInt));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<NativeUInt>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(NativeUInt), SizeOf(NativeUInt), Size * SizeOf(NativeUInt));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<Int64>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Int64), SizeOf(Int64), Size * SizeOf(Int64));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<Integer>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Integer), SizeOf(Integer), Size * SizeOf(Integer));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<Word>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Word), SizeOf(Word), Size * SizeOf(Word));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<Byte>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Byte), SizeOf(Byte), Size * SizeOf(Byte));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<Single>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Single), SizeOf(Single), Size * SizeOf(Single));
  if Result then SetLength(Target, Size - 1);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Delete(var Target: TArray<Double>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Double), SizeOf(Double), Size * SizeOf(Double));
  if Result then SetLength(Target, Size - 1);
end;
{$ENDIF}

function Delete(var Target: TArray<Extended>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Extended), SizeOf(Extended), Size * SizeOf(Extended));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<Char>; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := Delete(Pointer(Target), Index * SizeOf(Char), SizeOf(Char), Size * SizeOf(Char));
  if Result then SetLength(Target, Size - 1);
end;

function Delete(var Target: TArray<string>; const Index: Integer): Boolean;
var
  I, J: Integer;
  ATarget: TArray<string>;
begin
  I := Length(Target);
  Result := (Index >= 0) and (Index < I);
  if Result then
  begin
    SetLength(ATarget, I - 1);
    J := 0;
    for I := Low(Target) to High(Target) do
      if I = Index then
        Inc(J)
      else
        ATarget[I - J] := Target[I];
    Target := ATarget;
  end;
end;

function IndexOf(const Target, Source: Pointer; const Count, SourceSize: Integer): Integer;
var
  I, J: Integer;
begin
  I := 0;
  J := 0;
  while I < Count do
  begin
    if CompareMem(Source, PAnsiChar(Target) + J, SourceSize) then
    begin
      Result := I;
      Exit;
    end;
    Inc(I);
    Inc(J, SourceSize);
  end;
  Result := -1;
end;

function IndexOf(const Target: TArray<NativeInt>; const Value: NativeInt): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(NativeInt));
end;

function IndexOf(const Target: TArray<NativeUInt>; const Value: NativeUInt): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(NativeUInt));
end;

function IndexOf(const Target: TArray<Int64>; const Value: Int64): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Int64));
end;

function IndexOf(const Target: TArray<Integer>; const Value: Integer): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Integer));
end;

function IndexOf(const Target: TArray<Word>; const Value: Word): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Word));
end;

function IndexOf(const Target: TArray<Byte>; const Value: Byte): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Byte));
end;

function IndexOf(const Target: TArray<Single>; const Value: Single): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Single));
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function IndexOf(const Target: TArray<Double>; const Value: Double): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Double));
end;
{$ENDIF}

function IndexOf(const Target: TArray<Extended>; const Value: Extended): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Extended));
end;

function IndexOf(const Target: TArray<Char>; const Value: Char): Integer;
begin
  Result := IndexOf(Pointer(Target), @Value, Length(Target), SizeOf(Char));
end;

function IndexOf(const Target: TArray<string>; const Value: string): Integer;
var
  I: Integer;
begin
  for I := Low(Target) to High(Target) do
    if SameText(Target[I], Value) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

function Insert(const Target, Source: Pointer; const Index, TargetSize, SourceSize: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index <= TargetSize);
  if Result then
  begin
    if Index < TargetSize then
      MoveMemory(PAnsiChar(Target) + Index + SourceSize, PAnsiChar(Target) + Index, TargetSize - Index);
    CopyMemory(PAnsiChar(Target) + Index, Source, SourceSize);
  end;
end;

function Insert(var Target: TArray<NativeInt>; const Value: NativeInt; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(NativeInt), Size * SizeOf(NativeInt), SizeOf(NativeInt));
end;

function Insert(var Target: TArray<NativeUInt>; const Value: NativeUInt; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(NativeUInt), Size * SizeOf(NativeUInt), SizeOf(NativeUInt));
end;

function Insert(var Target: TArray<Int64>; const Value: Int64; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Int64), Size * SizeOf(Int64), SizeOf(Int64));
end;

function Insert(var Target: TArray<Integer>; const Value, Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Integer), Size * SizeOf(Integer), SizeOf(Integer));
end;

function Insert(var Target: TArray<Word>; const Value: Word; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Word), Size * SizeOf(Word), SizeOf(Word));
end;

function Insert(var Target: TArray<Byte>; const Value: Byte; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Byte), Size * SizeOf(Byte), SizeOf(Byte));
end;

function Insert(var Target: TArray<Single>; const Value: Single; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Single), Size * SizeOf(Single), SizeOf(Single));
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Insert(var Target: TArray<Double>; const Value: Double; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Double), Size * SizeOf(Double), SizeOf(Double));
end;
{$ENDIF}

function Insert(var Target: TArray<Extended>; const Value: Extended; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Extended), Size * SizeOf(Extended), SizeOf(Extended));
end;

function Insert(var Target: TArray<Char>; const Value: Char; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  SetLength(Target, Size + 1);
  Result := Insert(Pointer(Target), @Value, Index * SizeOf(Char), Size * SizeOf(Char), SizeOf(Char));
end;

function BSearch(const Target: Pointer; Min, Max: Integer; const Compare: TSearchCompare;
  const Value, P: Pointer): Integer;
begin
  while Min <= Max do
  begin
    Result := (Min + Max) div 2;
    case Compare(Target, Value, Result, P) of
      LessThanValue: Max := Result - 1;
      GreaterThanValue: Min := Result + 1;
    else
      Exit;
    end;
  end;
  Result := -1;
end;

function BSearch(const Target: Pointer; const Min, Max: Integer; const Compare: TSearchCompare;
  const Value, P: Pointer; const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Target, Min, Max, {$IFDEF FPC}@{$ENDIF}Compare, Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function NativeIntSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  NativeIntArray: TArray<NativeInt> absolute Target;
begin
  Result := CompareValue(PNativeInt(Value)^, NativeIntArray[Index]);
end;

function Search(const Target: TArray<NativeInt>; const Value: NativeInt): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}NativeIntSearchCompare, @Value);
end;

function Find(const Target: TArray<NativeInt>; const Value: NativeInt; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}NativeIntSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function NativeUIntSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  NativeUIntArray: TArray<NativeUInt> absolute Target;
begin
  Result := CompareValue(PNativeUInt(Value)^, NativeUIntArray[Index]);
end;

function Search(const Target: TArray<NativeUInt>; const Value: NativeUInt): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}NativeUIntSearchCompare, @Value);
end;

function Find(const Target: TArray<NativeUInt>; const Value: NativeUInt; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}NativeUIntSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function Int64SearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  Int64Array: TArray<Int64> absolute Target;
begin
  Result := CompareValue(PInt64(Value)^, Int64Array[Index]);
end;

function Search(const Target: TArray<Int64>; const Value: Int64): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}Int64SearchCompare, @Value);
end;

function Find(const Target: TArray<Int64>; const Value: Int64; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}Int64SearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function IntegerSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  IntegerArray: TArray<Integer> absolute Target;
begin
  Result := CompareValue(PInteger(Value)^, IntegerArray[Index]);
end;

function Search(const Target: TArray<Integer>; const Value: Integer): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}IntegerSearchCompare, @Value);
end;

function Find(const Target: TArray<Integer>; const Value: Integer; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}IntegerSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function WordSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  WordArray: TArray<Word> absolute Target;
begin
  Result := CompareValue(PWord(Value)^, WordArray[Index]);
end;

function Search(const Target: TArray<Word>; const Value: Word): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}WordSearchCompare, @Value);
end;

function Find(const Target: TArray<Word>; const Value: Word; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}WordSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function ByteSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  ByteArray: TArray<Byte> absolute Target;
begin
  Result := CompareValue(PByte(Value)^, ByteArray[Index]);
end;

function Search(const Target: TArray<Byte>; const Value: Byte): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}ByteSearchCompare, @Value);
end;

function Find(const Target: TArray<Byte>; const Value: Byte; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}ByteSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

function SingleSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  SingleArray: TArray<Single> absolute Target;
begin
  Result := CompareValue(PSingle(Value)^, SingleArray[Index]);
end;

function Search(const Target: TArray<Single>; const Value: Single): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}SingleSearchCompare, @Value);
end;

function Find(const Target: TArray<Single>; const Value: Single; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}SingleSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function DoubleSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  DoubleArray: TArray<Double> absolute Target;
begin
  Result := CompareValue(PDouble(Value)^, DoubleArray[Index]);
end;

function Search(const Target: TArray<Double>; const Value: Double): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}DoubleSearchCompare, @Value);
end;

function Find(const Target: TArray<Double>; const Value: Double; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}DoubleSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;
{$ENDIF}

function ExtendedSearchCompare(const Target, Value: Pointer; const Index: Integer;
  const P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  ExtendedArray: TArray<Extended> absolute Target;
begin
  Result := CompareValue(PExtended(Value)^, ExtendedArray[Index]);
end;

function Search(const Target: TArray<Extended>; const Value: Extended): Integer;
begin
  Result := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}ExtendedSearchCompare, @Value);
end;

function Find(const Target: TArray<Extended>; const Value: Extended; const P: Pointer;
  const Index: PInteger): Boolean;
var
  I: Integer;
begin
  I := BSearch(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}ExtendedSearchCompare, @Value, P);
  Result := I >= 0;
  if Result and Assigned(Index) then Index^ := I;
end;

procedure HSort(const Target: Pointer; Min, Max: Integer; const Compare: TSortCompare;
  const Exchange: TSortExchange; const P: Pointer);

  procedure SiftDown(Root, Bottom: Integer);
  var
    Child: Integer;
  begin
    Root := Root - Min;
    Bottom := Bottom - Min;
    while Root * 2 + 1 <= Bottom do
    begin
      Child := Root * 2 + 1;
      if (Child + 1 <= Bottom) and (Compare(Min + Child, Min + Child + 1, Target, P) < 0) then
        Inc(Child);
      if Compare(Min + Root, Min + Child, Target, P) < 0 then
      begin
        Exchange(Min + Root, Min + Child, Target, P);
        Root := Child;
      end
      else
        Exit;
    end;
  end;

var
  I: Integer;
begin
  if Assigned(Compare) and Assigned(Exchange) and (Min < Max) then
  begin
    for I := ((Max - Min + 1) div 2) - 1 downto 0 do SiftDown(Min + I, Max);
    for I := Max downto Min + 1 do
    begin
      Exchange(Min, I, Target, P);
      SiftDown(Min, I - 1);
    end;
  end;
end;

procedure QSort(const Target: Pointer; Min, Max: Integer; const Compare: TSortCompare;
  const Exchange: TSortExchange; const P: Pointer);

  procedure Sort(Min, Max: Integer);
  var
    I, J, Mid: Integer;
  begin
    while Min < Max do
    begin
      Mid := (Min + Max) shr 1;
      if Compare(Min, Mid, Target, P) > 0 then Exchange(Min, Mid, Target, P);
      if Compare(Min, Max, Target, P) > 0 then Exchange(Min, Max, Target, P);
      if Compare(Mid, Max, Target, P) > 0 then Exchange(Mid, Max, Target, P);
      I := Min;
      J := Max;
      repeat
        while Compare(I, Mid, Target, P) < 0 do Inc(I);
        while Compare(J, Mid, Target, P) > 0 do Dec(J);
        if I <= J then
        begin
          if I < J then
          begin
            if Mid = I then
              Mid := J
            else if Mid = J then
              Mid := I;
            Exchange(I, J, Target, P);
          end;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if J - Min < Max - I then
      begin
        if Min < J then Sort(Min, J);
        Min := I;
      end
      else begin
        if I < Max then Sort(I, Max);
        Max := J;
      end;
    end;
  end;

begin
  if Assigned(Compare) and Assigned(Exchange) and (Min < Max) then Sort(Min, Max);
end;

function NativeIntSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  NativeIntArray: TArray<NativeInt> absolute Target;
begin
  Result := CompareValue(NativeIntArray[AIndex], NativeIntArray[BIndex]);
end;

procedure NativeIntExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: NativeInt;
  NativeIntArray: TArray<NativeInt> absolute Target;
begin
  Value := NativeIntArray[AIndex];
  NativeIntArray[AIndex] := NativeIntArray[BIndex];
  NativeIntArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<NativeInt>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}NativeIntSortCompare, {$IFDEF FPC}@{$ENDIF}NativeIntExchange);
end;

function NativeUIntSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  NativeUIntArray: TArray<NativeUInt> absolute Target;
begin
  Result := CompareValue(NativeUIntArray[AIndex], NativeUIntArray[BIndex]);
end;

procedure NativeUIntExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: NativeUInt;
  NativeUIntArray: TArray<NativeUInt> absolute Target;
begin
  Value := NativeUIntArray[AIndex];
  NativeUIntArray[AIndex] := NativeUIntArray[BIndex];
  NativeUIntArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<NativeUInt>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}NativeUIntSortCompare, {$IFDEF FPC}@{$ENDIF}NativeUIntExchange);
end;

function Int64SortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  Int64Array: TArray<Int64> absolute Target;
begin
  Result := CompareValue(Int64Array[AIndex], Int64Array[BIndex]);
end;

procedure Int64Exchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Int64;
  Int64Array: TArray<Int64> absolute Target;
begin
  Value := Int64Array[AIndex];
  Int64Array[AIndex] := Int64Array[BIndex];
  Int64Array[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Int64>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}Int64SortCompare, {$IFDEF FPC}@{$ENDIF}Int64Exchange);
end;

function IntegerSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  IntegerArray: TArray<Integer> absolute Target;
begin
  Result := CompareValue(IntegerArray[AIndex], IntegerArray[BIndex]);
end;

procedure IntegerExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Integer;
  IntegerArray: TArray<Integer> absolute Target;
begin
  Value := IntegerArray[AIndex];
  IntegerArray[AIndex] := IntegerArray[BIndex];
  IntegerArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Integer>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}IntegerSortCompare, {$IFDEF FPC}@{$ENDIF}IntegerExchange);
end;

function WordSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  WordArray: TArray<Word> absolute Target;
begin
  Result := CompareValue(WordArray[AIndex], WordArray[BIndex]);
end;

procedure WordExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Word;
  WordArray: TArray<Word> absolute Target;
begin
  Value := WordArray[AIndex];
  WordArray[AIndex] := WordArray[BIndex];
  WordArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Word>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}WordSortCompare, {$IFDEF FPC}@{$ENDIF}WordExchange);
end;

function ByteSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  ByteArray: TArray<Byte> absolute Target;
begin
  Result := CompareValue(ByteArray[AIndex], ByteArray[BIndex]);
end;

procedure ByteExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Byte;
  ByteArray: TArray<Byte> absolute Target;
begin
  Value := ByteArray[AIndex];
  ByteArray[AIndex] := ByteArray[BIndex];
  ByteArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Byte>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}ByteSortCompare, {$IFDEF FPC}@{$ENDIF}ByteExchange);
end;

function SingleSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  SingleArray: TArray<Single> absolute Target;
begin
  Result := CompareValue(SingleArray[AIndex], SingleArray[BIndex]);
end;

procedure SingleExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Single;
  SingleArray: TArray<Single> absolute Target;
begin
  Value := SingleArray[AIndex];
  SingleArray[AIndex] := SingleArray[BIndex];
  SingleArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Single>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}SingleSortCompare, {$IFDEF FPC}@{$ENDIF}SingleExchange);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function DoubleSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  DoubleArray: TArray<Double> absolute Target;
begin
  Result := CompareValue(DoubleArray[AIndex], DoubleArray[BIndex]);
end;

procedure DoubleExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Double;
  DoubleArray: TArray<Double> absolute Target;
begin
  Value := DoubleArray[AIndex];
  DoubleArray[AIndex] := DoubleArray[BIndex];
  DoubleArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Double>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}DoubleSortCompare, {$IFDEF FPC}@{$ENDIF}DoubleExchange);
end;
{$ENDIF}

function ExtendedSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  ExtendedArray: TArray<Extended> absolute Target;
begin
  Result := CompareValue(ExtendedArray[AIndex], ExtendedArray[BIndex]);
end;

procedure ExtendedExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Extended;
  ExtendedArray: TArray<Extended> absolute Target;
begin
  Value := ExtendedArray[AIndex];
  ExtendedArray[AIndex] := ExtendedArray[BIndex];
  ExtendedArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Extended>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}ExtendedSortCompare, {$IFDEF FPC}@{$ENDIF}ExtendedExchange);
end;

function CharSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  CharArray: TArray<Char> absolute Target;
begin
  Result := AnsiCompareStr(CharArray[AIndex], CharArray[BIndex]);
end;

procedure CharExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: Char;
  CharArray: TArray<Char> absolute Target;
begin
  Value := CharArray[AIndex];
  CharArray[AIndex] := CharArray[BIndex];
  CharArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<Char>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}CharSortCompare, {$IFDEF FPC}@{$ENDIF}CharExchange);
end;

function StringSortCompare(const AIndex, BIndex: Integer;
  const Target, P: Pointer): {$IFDEF FPC}Types.{$ENDIF}TValueRelationship;
var
  StringArray: TArray<string> absolute Target;
begin
  Result := CompareValue(Length(StringArray[AIndex]), Length(StringArray[BIndex]));
end;

procedure StringExchange(const AIndex, BIndex: Integer; const Target, P: Pointer);
var
  Value: string;
  StringArray: TArray<string> absolute Target;
begin
  Value := StringArray[AIndex];
  StringArray[AIndex] := StringArray[BIndex];
  StringArray[BIndex] := Value;
end;

procedure Sort(var Target: TArray<string>);
begin
  QSort(Pointer(Target), Low(Target), High(Target), {$IFDEF FPC}@{$ENDIF}StringSortCompare, {$IFDEF FPC}@{$ENDIF}StringExchange);
end;

procedure Resize(const Target: Pointer; const PriorSize, Size: Integer; const Fill: Byte);
begin
  if (Size > PriorSize) and (Fill <> 0) then
    FillMemory(PAnsiChar(Target) + PriorSize, Size - PriorSize, Fill);
end;

procedure Resize(var Target: TArray<NativeInt>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(NativeInt), Size * SizeOf(NativeInt), Fill);
end;

procedure Resize(var Target: TArray<NativeUInt>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(NativeUInt), Size * SizeOf(NativeUInt), Fill);
end;

procedure Resize(var Target: TArray<Int64>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Int64), Size * SizeOf(Int64), Fill);
end;

procedure Resize(var Target: TArray<Integer>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Integer), Size * SizeOf(Integer), Fill);
end;

procedure Resize(var Target: TArray<Word>; const Size: Integer; const Fill: Word);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Word), Size * SizeOf(Word), Fill);
end;

procedure Resize(var Target: TArray<Byte>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Byte), Size * SizeOf(Byte), Fill);
end;

procedure Resize(var Target: TArray<Single>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Single), Size * SizeOf(Single), Fill);
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
procedure Resize(var Target: TArray<Double>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Double), Size * SizeOf(Double), Fill);
end;
{$ENDIF}

procedure Resize(var Target: TArray<Extended>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Extended), Size * SizeOf(Extended), Fill);
end;

procedure Resize(var Target: TArray<Char>; const Size: Integer; const Fill: Byte);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(Char), Size * SizeOf(Char), Fill);
end;

procedure Resize(var Target: TArray<string>; const Size: Integer);
var
  Prior: Integer;
begin
  Prior := Length(Target);
  SetLength(Target, Size);
  Resize(Pointer(Target), Prior * SizeOf(string), Size * SizeOf(string), 0);
end;

procedure Segment(const Source, Target: Pointer; const Index, Size: Integer);
begin
  CopyMemory(Target, PAnsiChar(Source) + Index, Size);
end;

function Segment(const Target: TArray<NativeInt>; const Index, Size: Integer): TArray<NativeInt>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(NativeInt), Size * SizeOf(NativeInt));
end;

function Segment(const Target: TArray<NativeUInt>; const Index, Size: Integer): TArray<NativeUInt>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(NativeUInt), Size * SizeOf(NativeUInt));
end;

function Segment(const Target: TArray<Int64>; const Index, Size: Integer): TArray<Int64>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Int64), Size * SizeOf(Int64));
end;

function Segment(const Target: TArray<Integer>; const Index, Size: Integer): TArray<Integer>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Integer), Size * SizeOf(Integer));
end;

function Segment(const Target: TArray<Word>; const Index, Size: Integer): TArray<Word>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Word), Size * SizeOf(Word));
end;

function Segment(const Target: TArray<Byte>; const Index, Size: Integer): TArray<Byte>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Byte), Size * SizeOf(Byte));
end;

function Segment(const Target: TArray<Single>; const Index, Size: Integer): TArray<Single>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Single), Size * SizeOf(Single));
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function Segment(const Target: TArray<Double>; const Index, Size: Integer): TArray<Double>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Double), Size * SizeOf(Double));
end;
{$ENDIF}

function Segment(const Target: TArray<Extended>; const Index, Size: Integer): TArray<Extended>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Extended), Size * SizeOf(Extended));
end;

function Segment(const Target: TArray<Char>; const Index, Size: Integer): TArray<Char>;
begin
  SetLength(Result, Size);
  Segment(Pointer(Target), Pointer(Result), Index * SizeOf(Char), Size * SizeOf(Char));
end;

procedure SetRandom(var Target: TArray<Integer>);
var
  I, J, Count: Integer;
  Order: TArray<Integer>;
begin
  Count := Length(Target);
  SetLength(Order, Count);
  try
    for I := Low(Order) to High(Order) do Order[I] := I;
    for I := Low(Target) to High(Target) do
    begin
      J := Random(Count - I);
      Target[I] := Order[J];
      Order[J] := Order[Count - I - 1];
    end;
  finally
    Order := nil;
  end;
end;

initialization
  Randomize;

end.
