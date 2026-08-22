{ ************************************************************************** }
{                                                                            }
{ ValueUtils                                                                 }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ValueUtils;

{$B-}
{$R-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  Winapi.Windows, System.SysUtils, BaseTypes, ValueTypes;
  {$ELSE}
  Windows, SysUtils, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  TOperationType = (otAdd, otSubtract, otMultiply, otModulo, otDivide);

procedure AssignByte(var Target: TValue; const Source: Byte);
procedure AssignShortint(var Target: TValue; const Source: Shortint);
procedure AssignBoolean(var Target: TValue; const Source: Boolean);
procedure AssignWord(var Target: TValue; const Source: Word);
procedure AssignSmallint(var Target: TValue; const Source: Smallint);
procedure AssignWordBool(var Target: TValue; const Source: WordBool);
procedure AssignLongWord(var Target: TValue; const Source: LongWord);
procedure AssignInteger(var Target: TValue; const Source: Integer);
procedure AssignLongBool(var Target: TValue; const Source: LongBool);
procedure AssignPointer(var Target: TValue; const Source: Pointer);
procedure AssignNativeInt(var Target: TValue; const Source: NativeInt);
procedure AssignNativeUInt(var Target: TValue; const Source: NativeUInt);
procedure AssignInt64(var Target: TValue; const Source: Int64);
procedure AssignSingle(var Target: TValue; const Source: Single);
procedure AssignDouble(var Target: TValue; const Source: Double);
procedure AssignExtended(var Target: TValue; const Source: Extended);

function AssignValue(var Target: TValueRef; const Source: TValue): Boolean;

function MakeByte(const Value: Byte): TValue;
function MakeShortint(const Value: Shortint): TValue;
function MakeBoolean(const Value: Boolean): TValue;
function MakeWord(const Value: Word): TValue;
function MakeSmallint(const Value: Smallint): TValue;
function MakeWordBool(const Value: WordBool): TValue;
function MakeLongBool(const Value: LongBool): TValue;
function MakeLongWord(const Value: LongWord): TValue;
function MakeInteger(const Value: Integer): TValue;
function MakeNativeInt(const Value: NativeInt): TValue;
function MakeNativeUInt(const Value: NativeUInt): TValue;
function MakeInt64(const Value: Int64): TValue;
function MakeSingle(const Value: Single): TValue;
function MakeDouble(const Value: Double): TValue;
function MakeExtended(const Value: Extended): TValue;
function MakeValue(const Value: TValueRef): TValue;

function GetByte(const Value: TValue): Byte;
function GetShortint(const Value: TValue): Shortint;
function GetBoolean(const Value: TValue): Boolean;
function GetWord(const Value: TValue): Word;
function GetSmallint(const Value: TValue): Smallint;
function GetWordBool(const Value: TValue): WordBool;
function GetLongWord(const Value: TValue): LongWord;
function GetInteger(const Value: TValue): Integer;
function GetLongBool(const Value: TValue): LongBool;
function GetNativeInt(const Value: TValue): NativeInt;
function GetNativeUInt(const Value: TValue): NativeUInt;
function GetInt64(const Value: TValue): Int64;
function GetSingle(const Value: TValue): Single;
function GetDouble(const Value: TValue): Double;
function GetExtended(const Value: TValue): Extended;

function MakeValueRef(var Value: Byte): TValueRef; overload;
function MakeValueRef(var Value: Shortint): TValueRef; overload;
function MakeValueRef(var Value: Boolean): TValueRef; overload;
function MakeValueRef(var Value: Word): TValueRef; overload;
function MakeValueRef(var Value: Smallint): TValueRef; overload;
function MakeValueRef(var Value: WordBool): TValueRef; overload;
function MakeValueRef(var Value: LongWord): TValueRef; overload;
function MakeValueRef(var Value: Integer): TValueRef; overload;
function MakeValueRef(var Value: LongBool): TValueRef; overload;
function MakeValueRef(var Value: NativeInt): TValueRef; overload;
function MakeValueRef(var Value: NativeUInt): TValueRef; overload;
function MakeValueRef(var Value: Int64): TValueRef; overload;
function MakeValueRef(var Value: Single): TValueRef; overload;
{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function MakeValueRef(var Value: Double): TValueRef; overload;
{$ENDIF}
function MakeValueRef(var Value: Extended): TValueRef; overload;

function GetValueType(const Value: Int64): TValueType;
function LessZero(const Value: TValue): Boolean;
function GreaterZero(const Value: TValue): Boolean;
function TextToValue(const Text: string): TValue;
function TryTextToValue(const Source: string; var Target: TValue): Boolean;
function ValueToText(const Value: TValue): string;
function Convert(const Value: TValue; ValueType: TValueType): TValue;
function Operation(const AValue, BValue: TValue; OperationType: TOperationType): TValue;
function Negative(const Value: TValue): TValue;
function Positive(const Value: TValue): TValue;

implementation

uses
  {$IFDEF FPC}
  ScriptFormat, ValueConsts;
  {$ELSE}
  ScriptFormat, ValueConsts;
  {$ENDIF}

procedure AssignByte(var Target: TValue; const Source: Byte);
begin
  Target.Unsigned8 := Source;
  Target.ValueType := vtByte;
end;

procedure AssignShortint(var Target: TValue; const Source: Shortint);
begin
  Target.Signed8 := Source;
  Target.ValueType := vtShortint;
end;

procedure AssignBoolean(var Target: TValue; const Source: Boolean);
begin
  Target.Boolean8 := Source;
  Target.ValueType := vtShortint;
end;

procedure AssignWord(var Target: TValue; const Source: Word);
begin
  Target.Unsigned16 := Source;
  Target.ValueType := vtWord;
end;

procedure AssignSmallint(var Target: TValue; const Source: Smallint);
begin
  Target.Signed16 := Source;
  Target.ValueType := vtSmallint;
end;

procedure AssignWordBool(var Target: TValue; const Source: WordBool);
begin
  Target.Boolean16 := Source;
  Target.ValueType := vtSmallint;
end;

procedure AssignLongWord(var Target: TValue; const Source: LongWord);
begin
  Target.Unsigned32 := Source;
  Target.ValueType := vtLongWord;
end;

procedure AssignInteger(var Target: TValue; const Source: Integer);
begin
  Target.Signed32 := Source;
  Target.ValueType := vtInteger;
end;

procedure AssignLongBool(var Target: TValue; const Source: LongBool);
begin
  Target.Boolean32 := Source;
  Target.ValueType := vtInteger;
end;

procedure AssignPointer(var Target: TValue; const Source: Pointer);
begin
  Target.NativeUInt := NativeUInt(Source);
  Target.ValueType := vtNativeUInt;
end;

procedure AssignNativeInt(var Target: TValue; const Source: NativeInt);
begin
  Target.NativeInt := Source;
  Target.ValueType := vtNativeInt;
end;

procedure AssignNativeUInt(var Target: TValue; const Source: NativeUInt);
begin
  Target.NativeUInt := Source;
  Target.ValueType := vtNativeUInt;
end;

procedure AssignInt64(var Target: TValue; const Source: Int64);
begin
  Target.Signed64 := Source;
  Target.ValueType := vtInt64;
end;

procedure AssignSingle(var Target: TValue; const Source: Single);
begin
  Target.Float32 := Source;
  Target.ValueType := vtSingle;
end;

procedure AssignDouble(var Target: TValue; const Source: Double);
begin
  Target.Float64 := Source;
  Target.ValueType := vtDouble;
end;

procedure AssignExtended(var Target: TValue; const Source: Extended);
begin
  Target.Float80 := Source;
  Target.ValueType := vtExtended;
end;

function AssignValue(var Target: TValueRef; const Source: TValue): Boolean;
begin
  Result := True;
  case Target.ValueType of
    vtByte: Target.Unsigned8^ := GetByte(Source);
    vtShortint: Target.Signed8^ := GetShortint(Source);
    vtWord: Target.Unsigned16^ := GetWord(Source);
    vtSmallint: Target.Signed16^ := GetSmallint(Source);
    vtLongWord: Target.Unsigned32^ := GetLongWord(Source);
    vtInteger: Target.Signed32^ := GetInteger(Source);
    vtNativeInt: Target.NativeInt^ := GetNativeInt(Source);
    vtNativeUInt: Target.NativeUInt^ := GetNativeUInt(Source);
    vtInt64: Target.Signed64^ := GetInt64(Source);
    vtSingle: Target.Float32^ := GetSingle(Source);
    vtDouble: Target.Float64^ := GetDouble(Source);
    vtExtended: Target.Float80^ := GetExtended(Source);
  else
    Result := False;
  end;
end;

function MakeByte(const Value: Byte): TValue;
begin
  AssignByte(Result, Value);
end;

function MakeShortint(const Value: Shortint): TValue;
begin
  AssignShortint(Result, Value);
end;

function MakeBoolean(const Value: Boolean): TValue;
begin
  AssignBoolean(Result, Value);
end;

function MakeWord(const Value: Word): TValue;
begin
  AssignWord(Result, Value);
end;

function MakeSmallint(const Value: Smallint): TValue;
begin
  AssignSmallint(Result, Value);
end;

function MakeWordBool(const Value: WordBool): TValue;
begin
  AssignWordBool(Result, Value);
end;

function MakeLongWord(const Value: LongWord): TValue;
begin
  AssignLongWord(Result, Value);
end;

function MakeInteger(const Value: Integer): TValue;
begin
  AssignInteger(Result, Value);
end;

function MakeNativeInt(const Value: NativeInt): TValue;
begin
  AssignNativeInt(Result, Value);
end;

function MakeNativeUInt(const Value: NativeUInt): TValue;
begin
  AssignNativeUInt(Result, Value);
end;

function MakeLongBool(const Value: LongBool): TValue;
begin
  AssignLongBool(Result, Value);
end;

function MakeInt64(const Value: Int64): TValue;
begin
  AssignInt64(Result, Value);
end;

function MakeSingle(const Value: Single): TValue;
begin
  AssignSingle(Result, Value);
end;

function MakeDouble(const Value: Double): TValue;
begin
  AssignDouble(Result, Value);
end;

function MakeExtended(const Value: Extended): TValue;
begin
  AssignExtended(Result, Value);
end;

function MakeValue(const Value: TValueRef): TValue;
begin
  case Value.ValueType of
    vtByte: AssignByte(Result, Value.Unsigned8^);
    vtShortint: AssignShortint(Result, Value.Signed8^);
    vtWord: AssignWord(Result, Value.Unsigned16^);
    vtSmallint: AssignSmallint(Result, Value.Signed16^);
    vtLongWord: AssignLongWord(Result, Value.Unsigned32^);
    vtInteger: AssignInteger(Result, Value.Signed32^);
    vtNativeInt: AssignNativeInt(Result, Value.NativeInt^);
    vtNativeUInt: AssignNativeUInt(Result, Value.NativeUInt^);
    vtInt64: AssignInt64(Result, Value.Signed64^);
    vtSingle: AssignSingle(Result, Value.Float32^);
    vtDouble: AssignDouble(Result, Value.Float64^);
    vtExtended: AssignExtended(Result, Value.Float80^);
  else
    FillChar(Result, SizeOf(TValue), 0);
  end;
end;

function GetByte(const Value: TValue): Byte;
begin
  Result := Convert(Value, vtByte).Unsigned8;
end;

function GetShortint(const Value: TValue): Shortint;
begin
  Result := Convert(Value, vtShortint).Signed8;
end;

function GetBoolean(const Value: TValue): Boolean;
begin
  Result := Convert(Value, vtShortint).Boolean8;
end;

function GetWord(const Value: TValue): Word;
begin
  Result := Convert(Value, vtWord).Unsigned16;
end;

function GetSmallint(const Value: TValue): Smallint;
begin
  Result := Convert(Value, vtSmallint).Signed16;
end;

function GetWordBool(const Value: TValue): WordBool;
begin
  Result := Convert(Value, vtSmallint).Boolean16;
end;

function GetLongWord(const Value: TValue): LongWord;
begin
  Result := Convert(Value, vtLongWord).Unsigned32;
end;

function GetInteger(const Value: TValue): Integer;
begin
  Result := Convert(Value, vtInteger).Signed32;
end;

function GetLongBool(const Value: TValue): LongBool;
begin
  Result := Convert(Value, vtInteger).Boolean32;
end;

function GetNativeInt(const Value: TValue): NativeInt;
begin
  Result := Convert(Value, vtNativeInt).NativeInt;
end;

function GetNativeUInt(const Value: TValue): NativeUInt;
begin
  Result := Convert(Value, vtNativeUInt).NativeUInt;
end;

function GetInt64(const Value: TValue): Int64;
begin
  Result := Convert(Value, vtInt64).Signed64;
end;

function GetSingle(const Value: TValue): Single;
begin
  Result := Convert(Value, vtSingle).Float32;
end;

function GetDouble(const Value: TValue): Double;
begin
  Result := Convert(Value, vtDouble).Float64;
end;

function GetExtended(const Value: TValue): Extended;
begin
  Result := Convert(Value, vtExtended).Float80;
end;

function MakeValueRef(var Value: Byte): TValueRef;
begin
  Result.Unsigned8 := @Value;
  Result.ValueType := vtByte;
end;

function MakeValueRef(var Value: Shortint): TValueRef;
begin
  Result.Signed8 := @Value;
  Result.ValueType := vtShortint;
end;

function MakeValueRef(var Value: Boolean): TValueRef;
begin
  Result.Boolean8 := @Value;
  Result.ValueType := vtShortint;
end;

function MakeValueRef(var Value: Word): TValueRef;
begin
  Result.Unsigned16 := @Value;
  Result.ValueType := vtWord;
end;

function MakeValueRef(var Value: Smallint): TValueRef;
begin
  Result.Signed16 := @Value;
  Result.ValueType := vtSmallint;
end;

function MakeValueRef(var Value: WordBool): TValueRef;
begin
  Result.Boolean16 := @Value;
  Result.ValueType := vtSmallint;
end;

function MakeValueRef(var Value: LongWord): TValueRef;
begin
  Result.Unsigned32 := @Value;
  Result.ValueType := vtLongWord;
end;

function MakeValueRef(var Value: Integer): TValueRef;
begin
  Result.Signed32 := @Value;
  Result.ValueType := vtInteger;
end;

function MakeValueRef(var Value: LongBool): TValueRef;
begin
  Result.Boolean32 := @Value;
  Result.ValueType := vtInteger;
end;

function MakeValueRef(var Value: NativeInt): TValueRef;
begin
  Result.NativeInt := @Value;
  Result.ValueType := vtNativeInt;
end;

function MakeValueRef(var Value: NativeUInt): TValueRef;
begin
  Result.NativeUInt := @Value;
  Result.ValueType := vtNativeUInt;
end;

function MakeValueRef(var Value: Int64): TValueRef;
begin
  Result.Signed64 := @Value;
  Result.ValueType := vtInt64;
end;

function MakeValueRef(var Value: Single): TValueRef;
begin
  Result.Float32 := @Value;
  Result.ValueType := vtSingle;
end;

{$IF NOT Defined(FPC) OR Defined(FPC_HAS_TYPE_EXTENDED)}
function MakeValueRef(var Value: Double): TValueRef;
begin
  Result.Float64 := @Value;
  Result.ValueType := vtDouble;
end;
{$ENDIF}

function MakeValueRef(var Value: Extended): TValueRef;
begin
  Result.Float80 := @Value;
  Result.ValueType := vtExtended;
end;

function GetValueType(const Value: Int64): TValueType;
begin
  if Value > 0 then
    if Value > High(LongWord) then
      Result := vtInt64
    else if Value > High(Word) then
      Result := vtLongWord
    else if Value > High(Byte) then
      Result := vtWord
    else
      Result := vtByte
  else
    if Value < -High(Integer) - 1 then
      Result := vtInt64
    else if Value < -High(Smallint) - 1 then
      Result := vtInteger
    else if Value < -High(Shortint) - 1 then
      Result := vtSmallint
    else
      Result := vtShortint;
end;

function LessZero(const Value: TValue): Boolean;
begin
  case Value.ValueType of
    vtByte, vtWord, vtLongWord, vtNativeUInt: Result := False;
    vtShortint: Result := Value.Signed8 < 0;
    vtSmallint: Result := Value.Signed16 < 0;
    vtInteger: Result := Value.Signed32 < 0;
    vtNativeInt: Result := Value.NativeInt < 0;
    vtInt64: Result := Value.Signed64 < 0;
    vtSingle: Result := Value.Float32 < 0;
    vtDouble: Result := Value.Float64 < 0;
    vtExtended: Result := Value.Float80 < 0;
  else
    Result := False;
  end;
end;

function GreaterZero(const Value: TValue): Boolean;
begin
  case Value.ValueType of
    vtByte: Result := Value.Unsigned8 > 0;
    vtWord: Result := Value.Unsigned16 > 0;
    vtLongWord: Result := Value.Unsigned32 > 0;
    vtNativeUInt: Result := Value.NativeUInt > 0;
    vtShortint: Result := Value.Signed8 > 0;
    vtSmallint: Result := Value.Signed16 > 0;
    vtInteger: Result := Value.Signed32 > 0;
    vtNativeInt: Result := Value.NativeInt > 0;
    vtInt64: Result := Value.Signed64 > 0;
    vtSingle: Result := Value.Float32 > 0;
    vtDouble: Result := Value.Float64 > 0;
    vtExtended: Result := Value.Float80 > 0;
  else
    Result := False;
  end;
end;
function TextToValue(const Text: string): TValue;
begin
  if TryStrToInt64(Text, Result.Signed64) then
  begin
    Result.ValueType := GetValueType(Result.Signed64);
    case Result.ValueType of
      vtByte: Result.Unsigned8 := Result.Signed64;
      vtShortint: Result.Signed8 := Result.Signed64;
      vtWord: Result.Unsigned16 := Result.Signed64;
      vtSmallint: Result.Signed16 := Result.Signed64;
      vtLongWord: Result.Unsigned32 := Result.Signed64;
      vtInteger: Result.Signed32 := Result.Signed64;
    end;
  end
  else
    if TryStrToFloat(Text, Result.Float80, ParseFormat) then
      Result.ValueType := vtExtended
    else
      Result.ValueType := vtUnknown;
end;

function TryTextToValue(const Source: string; var Target: TValue): Boolean;
var
  Value: TValue;
begin
  Value := TextToValue(Source);
  Result := Value.ValueType <> vtUnknown;
  if Result then Target := Value;
end;

function ValueToText(const Value: TValue): string;
begin
  case Value.ValueType of
    vtByte: Result := IntToStr(Value.Unsigned8);
    vtShortint: Result := IntToStr(Value.Signed8);
    vtWord: Result := IntToStr(Value.Unsigned16);
    vtSmallint: Result := IntToStr(Value.Signed16);
    vtLongWord: Result := IntToStr(Value.Unsigned32);
    vtInteger: Result := IntToStr(Value.Signed32);
    vtNativeInt: Result := IntToStr(Value.NativeInt);
    vtNativeUInt: Result := IntToStr(Value.NativeUInt);
    vtInt64: Result := IntToStr(Value.Signed64);
    vtSingle: Result := FloatToStr(Value.Float32, ParseFormat);
    vtDouble: Result := FloatToStr(Value.Float64, ParseFormat);
    vtExtended: Result := FloatToStr(Value.Float80, ParseFormat);
  end;
end;

function Convert(const Value: TValue; ValueType: TValueType): TValue;
begin
  Result := EmptyValue;
  case Value.ValueType of
    vtByte:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Unsigned8;
        vtShortint: Result.Signed8 := Value.Unsigned8;
        vtWord: Result.Unsigned16 := Value.Unsigned8;
        vtSmallint: Result.Signed16 := Value.Unsigned8;
        vtLongWord: Result.Unsigned32 := Value.Unsigned8;
        vtInteger: Result.Signed32 := Value.Unsigned8;
        vtNativeInt: Result.NativeInt := Value.Unsigned8;
        vtNativeUInt: Result.NativeUInt := Value.Unsigned8;
        vtInt64: Result.Signed64 := Value.Unsigned8;
        vtSingle: Result.Float32 := Value.Unsigned8;
        vtDouble: Result.Float64 := Value.Unsigned8;
        vtExtended: Result.Float80 := Value.Unsigned8;
      end;
    vtShortint:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Signed8;
        vtShortint: Result.Signed8 := Value.Signed8;
        vtWord: Result.Unsigned16 := Value.Signed8;
        vtSmallint: Result.Signed16 := Value.Signed8;
        vtLongWord: Result.Unsigned32 := Value.Signed8;
        vtInteger: Result.Signed32 := Value.Signed8;
        vtNativeInt: Result.NativeInt := Value.Signed8;
        vtNativeUInt: Result.NativeUInt := Value.Signed8;
        vtInt64: Result.Signed64 := Value.Signed8;
        vtSingle: Result.Float32 := Value.Signed8;
        vtDouble: Result.Float64 := Value.Signed8;
        vtExtended: Result.Float80 := Value.Signed8;
      end;
    vtWord:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Unsigned16;
        vtShortint: Result.Signed8 := Value.Unsigned16;
        vtWord: Result.Unsigned16 := Value.Unsigned16;
        vtSmallint: Result.Signed16 := Value.Unsigned16;
        vtLongWord: Result.Unsigned32 := Value.Unsigned16;
        vtInteger: Result.Signed32 := Value.Unsigned16;
        vtNativeInt: Result.NativeInt := Value.Unsigned16;
        vtNativeUInt: Result.NativeUInt := Value.Unsigned16;
        vtInt64: Result.Signed64 := Value.Unsigned16;
        vtSingle: Result.Float32 := Value.Unsigned16;
        vtDouble: Result.Float64 := Value.Unsigned16;
        vtExtended: Result.Float80 := Value.Unsigned16;
      end;
    vtSmallint:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Signed16;
        vtShortint: Result.Signed8 := Value.Signed16;
        vtWord: Result.Unsigned16 := Value.Signed16;
        vtSmallint: Result.Signed16 := Value.Signed16;
        vtLongWord: Result.Unsigned32 := Value.Signed16;
        vtInteger: Result.Signed32 := Value.Signed16;
        vtNativeInt: Result.NativeInt := Value.Signed16;
        vtNativeUInt: Result.NativeUInt := Value.Signed16;
        vtInt64: Result.Signed64 := Value.Signed16;
        vtSingle: Result.Float32 := Value.Signed16;
        vtDouble: Result.Float64 := Value.Signed16;
        vtExtended: Result.Float80 := Value.Signed16;
      end;
    vtLongWord:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Unsigned32;
        vtShortint: Result.Signed8 := Value.Unsigned32;
        vtWord: Result.Unsigned16 := Value.Unsigned32;
        vtSmallint: Result.Signed16 := Value.Unsigned32;
        vtLongWord: Result.Unsigned32 := Value.Unsigned32;
        vtInteger: Result.Signed32 := Value.Unsigned32;
        vtNativeInt: Result.NativeInt := Value.Unsigned32;
        vtNativeUInt: Result.NativeUInt := Value.Unsigned32;
        vtInt64: Result.Signed64 := Value.Unsigned32;
        vtSingle: Result.Float32 := Value.Unsigned32;
        vtDouble: Result.Float64 := Value.Unsigned32;
        vtExtended: Result.Float80 := Value.Unsigned32;
      end;
    vtInteger:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Signed32;
        vtShortint: Result.Signed8 := Value.Signed32;
        vtWord: Result.Unsigned16 := Value.Signed32;
        vtSmallint: Result.Signed16 := Value.Signed32;
        vtLongWord: Result.Unsigned32 := Value.Signed32;
        vtInteger: Result.Signed32 := Value.Signed32;
        vtNativeInt: Result.NativeInt := Value.Signed32;
        vtNativeUInt: Result.NativeUInt := Value.Signed32;
        vtInt64: Result.Signed64 := Value.Signed32;
        vtSingle: Result.Float32 := Value.Signed32;
        vtDouble: Result.Float64 := Value.Signed32;
        vtExtended: Result.Float80 := Value.Signed32;
      end;
    vtNativeInt:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.NativeInt;
        vtShortint: Result.Signed8 := Value.NativeInt;
        vtWord: Result.Unsigned16 := Value.NativeInt;
        vtSmallint: Result.Signed16 := Value.NativeInt;
        vtLongWord: Result.Unsigned32 := Value.NativeInt;
        vtInteger: Result.Signed32 := Value.NativeInt;
        vtNativeInt: Result.NativeInt := Value.NativeInt;
        vtNativeUInt: Result.NativeUInt := Value.NativeInt;
        vtInt64: Result.Signed64 := Value.NativeInt;
        vtSingle: Result.Float32 := Value.NativeInt;
        vtDouble: Result.Float64 := Value.NativeInt;
        vtExtended: Result.Float80 := Value.NativeInt;
      end;
    vtNativeUInt:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.NativeUInt;
        vtShortint: Result.Signed8 := Value.NativeUInt;
        vtWord: Result.Unsigned16 := Value.NativeUInt;
        vtSmallint: Result.Signed16 := Value.NativeUInt;
        vtLongWord: Result.Unsigned32 := Value.NativeUInt;
        vtInteger: Result.Signed32 := Value.NativeUInt;
        vtNativeInt: Result.NativeInt := Value.NativeUInt;
        vtNativeUInt: Result.NativeUInt := Value.NativeUInt;
        vtInt64: Result.Signed64 := Value.NativeUInt;
        vtSingle: Result.Float32 := Value.NativeUInt;
        vtDouble: Result.Float64 := Value.NativeUInt;
        vtExtended: Result.Float80 := Value.NativeUInt;
      end;
    vtInt64:
      case ValueType of
        vtByte: Result.Unsigned8 := Value.Signed64;
        vtShortint: Result.Signed8 := Value.Signed64;
        vtWord: Result.Unsigned16 := Value.Signed64;
        vtSmallint: Result.Signed16 := Value.Signed64;
        vtLongWord: Result.Unsigned32 := Value.Signed64;
        vtInteger: Result.Signed32 := Value.Signed64;
        vtNativeInt: Result.NativeInt := Value.Signed64;
        vtNativeUInt: Result.NativeUInt := Value.Signed64;
        vtInt64: Result.Signed64 := Value.Signed64;
        vtSingle: Result.Float32 := Value.Signed64;
        vtDouble: Result.Float64 := Value.Signed64;
        vtExtended: Result.Float80 := Value.Signed64;
      end;
    vtSingle:
      case ValueType of
        vtByte: Result.Unsigned8 := Round(Value.Float32);
        vtShortint: Result.Signed8 := Round(Value.Float32);
        vtWord: Result.Unsigned16 := Round(Value.Float32);
        vtSmallint: Result.Signed16 := Round(Value.Float32);
        vtLongWord: Result.Unsigned32 := Round(Value.Float32);
        vtInteger: Result.Signed32 := Round(Value.Float32);
        vtNativeInt: Result.NativeInt := Round(Value.Float32);
        vtNativeUInt: Result.NativeUInt := Round(Value.Float32);
        vtInt64: Result.Signed64 := Round(Value.Float32);
        vtSingle: Result.Float32 := Value.Float32;
        vtDouble: Result.Float64 := Value.Float32;
        vtExtended: Result.Float80 := Value.Float32;
      end;
    vtDouble:
      case ValueType of
        vtByte: Result.Unsigned8 := Round(Value.Float64);
        vtShortint: Result.Signed8 := Round(Value.Float64);
        vtWord: Result.Unsigned16 := Round(Value.Float64);
        vtSmallint: Result.Signed16 := Round(Value.Float64);
        vtLongWord: Result.Unsigned32 := Round(Value.Float64);
        vtInteger: Result.Signed32 := Round(Value.Float64);
        vtNativeInt: Result.NativeInt := Round(Value.Float64);
        vtNativeUInt: Result.NativeUInt := Round(Value.Float64);
        vtInt64: Result.Signed64 := Round(Value.Float64);
        vtSingle: Result.Float32 := Value.Float64;
        vtDouble: Result.Float64 := Value.Float64;
        vtExtended: Result.Float80 := Value.Float64;
      end;
    vtExtended:
      case ValueType of
        vtByte: Result.Unsigned8 := Round(Value.Float80);
        vtShortint: Result.Signed8 := Round(Value.Float80);
        vtWord: Result.Unsigned16 := Round(Value.Float80);
        vtSmallint: Result.Signed16 := Round(Value.Float80);
        vtLongWord: Result.Unsigned32 := Round(Value.Float80);
        vtInteger: Result.Signed32 := Round(Value.Float80);
        vtNativeInt: Result.NativeInt := Round(Value.Float80);
        vtNativeUInt: Result.NativeUInt := Round(Value.Float80);
        vtInt64: Result.Signed64 := Round(Value.Float80);
        vtSingle: Result.Float32 := Value.Float80;
        vtDouble: Result.Float64 := Value.Float80;
        vtExtended: Result.Float80 := Value.Float80;
      end;
  end;
  Result.ValueType := ValueType;
end;

function Operation(const AValue, BValue: TValue; OperationType: TOperationType): TValue;
begin
  Result := EmptyValue;
  case OperationType of
    otAdd:
      case AValue.ValueType of
        vtByte:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Unsigned8 + BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Unsigned8 + BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Unsigned8 + BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Unsigned8 + BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned8) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned8) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Unsigned8) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Unsigned8) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned8) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned8 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned8 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned8 + BValue.Float80);
          end;
        vtShortint:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Signed8 + BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Signed8 + BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Signed8 + BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Signed8 + BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed8) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed8) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Signed8) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Signed8) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed8) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed8 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed8 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed8 + BValue.Float80);
          end;
        vtWord:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Unsigned16 + BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Unsigned16 + BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Unsigned16 + BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Unsigned16 + BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned16) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned16) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Unsigned16) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Unsigned16) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned16) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned16 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned16 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned16 + BValue.Float80);
          end;
        vtSmallint:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Signed16 + BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Signed16 + BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Signed16 + BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Signed16 + BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed16) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed16) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Signed16) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Signed16) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed16) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed16 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed16 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed16 + BValue.Float80);
          end;
        vtLongWord:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Unsigned32) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned32) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned32 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned32 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned32 + BValue.Float80);
          end;
        vtInteger:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Signed32) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed32) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed32 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed32 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed32 + BValue.Float80);
          end;
        vtNativeInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.NativeInt) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.NativeInt) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeInt + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeInt + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeInt + BValue.Float80);
          end;
        vtNativeUInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.NativeUInt) + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.NativeUInt) + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeUInt + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeUInt + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeUInt + BValue.Float80);
          end;
        vtInt64:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Signed64 + Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, AValue.Signed64 + Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, AValue.Signed64 + Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, AValue.Signed64 + Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, AValue.Signed64 + Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.Signed64 + Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, AValue.Signed64 + Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, AValue.Signed64 + Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed64 + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed64 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed64 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed64 + BValue.Float80);
          end;
        vtSingle:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float32 + BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float32 + BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float32 + BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float32 + BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float32 + BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float32 + BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float32 + BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float32 + BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float32 + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float32 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float32 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float32 + BValue.Float80);
          end;
        vtDouble:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float64 + BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float64 + BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float64 + BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float64 + BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float64 + BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float64 + BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float64 + BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float64 + BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float64 + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float64 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float64 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float64 + BValue.Float80);
          end;
        vtExtended:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float80 + BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float80 + BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float80 + BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float80 + BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float80 + BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float80 + BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float80 + BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float80 + BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float80 + BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float80 + BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float80 + BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float80 + BValue.Float80);
          end;
      end;
    otSubtract:
      case AValue.ValueType of
        vtByte:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Unsigned8 - BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Unsigned8 - BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Unsigned8 - BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Unsigned8 - BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned8) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned8) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Unsigned8) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Unsigned8) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned8) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned8 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned8 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned8 - BValue.Float80);
          end;
        vtShortint:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Signed8 - BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Signed8 - BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Signed8 - BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Signed8 - BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed8) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed8) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Signed8) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Signed8) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed8) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed8 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed8 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed8 - BValue.Float80);
          end;
        vtWord:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Unsigned16 - BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Unsigned16 - BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Unsigned16 - BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Unsigned16 - BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned16) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned16) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Unsigned16) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Unsigned16) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned16) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned16 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned16 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned16 - BValue.Float80);
          end;
        vtSmallint:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Signed16 - BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Signed16 - BValue.Signed8);
            vtWord: AssignInteger(Result, AValue.Signed16 - BValue.Unsigned16);
            vtSmallint: AssignInteger(Result, AValue.Signed16 - BValue.Signed16);
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed16) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed16) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Signed16) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Signed16) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed16) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed16 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed16 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed16 - BValue.Float80);
          end;
        vtLongWord:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Unsigned32) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned32) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned32 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned32 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned32 - BValue.Float80);
          end;
        vtInteger:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.Signed32) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed32) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed32 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed32 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed32 - BValue.Float80);
          end;
        vtNativeInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.NativeInt) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.NativeInt) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeInt - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeInt - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeInt - BValue.Float80);
          end;
        vtNativeUInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, Int64(AValue.NativeUInt) - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.NativeUInt) - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeUInt - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeUInt - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeUInt - BValue.Float80);
          end;
        vtInt64:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Signed64 - Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, AValue.Signed64 - Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, AValue.Signed64 - Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, AValue.Signed64 - Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, AValue.Signed64 - Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.Signed64 - Int64(BValue.Signed32));
            vtNativeInt: AssignInt64(Result, AValue.Signed64 - Int64(BValue.NativeInt));
            vtNativeUInt: AssignInt64(Result, AValue.Signed64 - Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed64 - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed64 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed64 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed64 - BValue.Float80);
          end;
        vtSingle:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float32 - BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float32 - BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float32 - BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float32 - BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float32 - BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float32 - BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float32 - BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float32 - BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float32 - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float32 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float32 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float32 - BValue.Float80);
          end;
        vtDouble:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float64 - BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float64 - BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float64 - BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float64 - BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float64 - BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float64 - BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float64 - BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float64 - BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float64 - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float64 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float64 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float64 - BValue.Float80);
          end;
        vtExtended:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float80 - BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float80 - BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float80 - BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float80 - BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float80 - BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float80 - BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float80 - BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float80 - BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float80 - BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float80 - BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float80 - BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float80 - BValue.Float80);
          end;
      end;
    otMultiply:
      case AValue.ValueType of
        vtByte:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Unsigned8 * BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Unsigned8 * BValue.Signed8);
            vtWord: AssignInt64(Result, Int64(AValue.Unsigned8) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Unsigned8) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned8) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned8) * Int64(BValue.Signed32));
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.Unsigned8) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.Unsigned8) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned8) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned8 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned8 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned8 * BValue.Float80);
          end;
        vtShortint:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Signed8 * BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Signed8 * BValue.Signed8);
            vtWord: AssignInt64(Result, Int64(AValue.Signed8) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Signed8) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed8) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed8) * Int64(BValue.Signed32));
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.Signed8) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.Signed8) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed8) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed8 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed8 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed8 * BValue.Float80);
          end;
        vtWord:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Unsigned16) * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Unsigned16) * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Unsigned16) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Unsigned16) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned16) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned16) * Int64(BValue.Signed32));
            vtNativeInt:
              AssignNativeInt(Result, Int64(AValue.Unsigned16) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.Unsigned16) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned16) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned16 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned16 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned16 * BValue.Float80);
          end;
        vtSmallint:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Signed16) * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Signed16) * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Signed16) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Signed16) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed16) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed16) * Int64(BValue.Signed32));
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.Signed16) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.Signed16) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed16) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed16 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed16 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed16 * BValue.Float80);
          end;
        vtLongWord:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Unsigned32) * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Unsigned32) * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Unsigned32) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Unsigned32) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Unsigned32) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned32) * Int64(BValue.Signed32));
            vtNativeInt:
              AssignNativeInt(Result, Int64(AValue.Unsigned32) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.Unsigned32) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned32) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned32 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned32 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned32 * BValue.Float80);
          end;
        vtInteger:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.Signed32) * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.Signed32) * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.Signed32) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.Signed32) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.Signed32) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.Signed32) * Int64(BValue.Signed32));
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.Signed32) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.Signed32) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.Signed32) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed32 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed32 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed32 * BValue.Float80);
          end;
        vtNativeInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.NativeInt) * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.NativeInt) * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.NativeInt) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeInt) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.NativeInt) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.NativeInt) * Int64(BValue.Signed32));
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.NativeInt) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.NativeInt) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.NativeInt) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeInt * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeInt * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeInt * BValue.Float80);
          end;
        vtNativeUInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, Int64(AValue.NativeUInt) * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, Int64(AValue.NativeUInt) * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, Int64(AValue.NativeUInt) * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeUInt) * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, Int64(AValue.NativeUInt) * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, Int64(AValue.NativeUInt) * Int64(BValue.Signed32));
            vtNativeInt:
              AssignNativeInt(Result, Int64(AValue.NativeUInt) * Int64(BValue.NativeInt));
            vtNativeUInt:
              AssignNativeUInt(Result, Int64(AValue.NativeUInt) * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, Int64(AValue.NativeUInt) * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeUInt * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeUInt * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeUInt * BValue.Float80);
          end;
        vtInt64:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Signed64 * Int64(BValue.Unsigned8));
            vtShortint: AssignInt64(Result, AValue.Signed64 * Int64(BValue.Signed8));
            vtWord: AssignInt64(Result, AValue.Signed64 * Int64(BValue.Unsigned16));
            vtSmallint: AssignInt64(Result, AValue.Signed64 * Int64(BValue.Signed16));
            vtLongWord: AssignInt64(Result, AValue.Signed64 * Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.Signed64 * Int64(BValue.Signed32));
            vtNativeInt: AssignNativeInt(Result, AValue.Signed64 * Int64(BValue.NativeInt));
            vtNativeUInt: AssignNativeUInt(Result, AValue.Signed64 * Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed64 * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed64 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed64 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed64 * BValue.Float80);
          end;
        vtSingle:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float32 * BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float32 * BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float32 * BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float32 * BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float32 * BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float32 * BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float32 * BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float32 * BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float32 * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float32 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float32 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float32 * BValue.Float80);
          end;
        vtDouble:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float64 * BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float64 * BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float64 * BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float64 * BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float64 * BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float64 * BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float64 * BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float64 * BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float64 * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float64 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float64 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float64 * BValue.Float80);
          end;
        vtExtended:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float80 * BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float80 * BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float80 * BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float80 * BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float80 * BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float80 * BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float80 * BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float80 * BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float80 * BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float80 * BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float80 * BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float80 * BValue.Float80);
          end;
      end;
    otModulo:
      case AValue.ValueType of
        vtByte:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Unsigned8 mod BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Unsigned8 mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Unsigned8 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.Unsigned8 mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Unsigned8 mod BValue.Unsigned32);
            vtInteger: AssignInt64(Result, AValue.Unsigned8 mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.Unsigned8 mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Unsigned8 mod BValue.NativeUInt);
            vtInt64: AssignInt64(Result, AValue.Unsigned8 mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned8 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Unsigned8 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Unsigned8 mod Round(BValue.Float80));
          end;
        vtShortint:
          case BValue.ValueType of
            vtByte: AssignInteger(Result, AValue.Signed8 mod BValue.Unsigned8);
            vtShortint: AssignInteger(Result, AValue.Signed8 mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Signed8 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.Signed8 mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Signed8 mod Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.Signed8 mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.Signed8 mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Signed8 mod Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed8 mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed8 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Signed8 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Signed8 mod Round(BValue.Float80));
          end;
        vtWord:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Unsigned16 mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, AValue.Unsigned16 mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Unsigned16 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.Unsigned16 mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Unsigned16 mod BValue.Unsigned32);
            vtInteger: AssignInt64(Result, AValue.Unsigned16 mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.Unsigned16 mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Unsigned16 mod BValue.NativeUInt);
            vtInt64: AssignInt64(Result, AValue.Unsigned16 mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned16 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Unsigned16 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Unsigned16 mod Round(BValue.Float80));
          end;
        vtSmallint:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Signed16 mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, AValue.Signed16 mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Signed16 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.Signed16 mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Signed16 mod Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.Signed16 mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.Signed16 mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Signed16 mod Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed16 mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed16 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Signed16 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Signed16 mod Round(BValue.Float80));
          end;
        vtLongWord:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Unsigned32 mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, Int64(AValue.Unsigned32) mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Unsigned32 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, Int64(AValue.Unsigned32) mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Unsigned32 mod BValue.Unsigned32);
            vtInteger: AssignInt64(Result, Int64(AValue.Unsigned32) mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.Unsigned32) mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Unsigned32 mod BValue.NativeUInt);
            vtInt64: AssignInt64(Result, Int64(AValue.Unsigned32) mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned32 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Unsigned32 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Unsigned32 mod Round(BValue.Float80));
          end;
        vtInteger:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Signed32 mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, AValue.Signed32 mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Signed32 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.Signed32 mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Signed32 mod Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.Signed32 mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.Signed32 mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Signed32 mod Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed32 mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed32 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Signed32 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Signed32 mod Round(BValue.Float80));
          end;
        vtNativeInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.NativeInt mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, AValue.NativeInt mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.NativeInt mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.NativeInt mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.NativeInt mod Int64(BValue.Unsigned32));
            vtInteger: AssignInt64(Result, AValue.NativeInt mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.NativeInt mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.NativeInt mod Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.NativeInt mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeInt mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.NativeInt mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.NativeInt mod Round(BValue.Float80));
          end;
        vtNativeUInt:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.NativeUInt mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, Int64(AValue.NativeUInt) mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.NativeUInt mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, Int64(AValue.NativeUInt) mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.NativeUInt mod BValue.Unsigned32);
            vtInteger: AssignInt64(Result, Int64(AValue.NativeUInt) mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, Int64(AValue.NativeUInt) mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.NativeUInt mod BValue.NativeUInt);
            vtInt64: AssignInt64(Result, Int64(AValue.NativeUInt) mod BValue.Signed64);
            vtSingle: AssignExtended(Result, Int64(AValue.NativeUInt) mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, Int64(AValue.NativeUInt) mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, Int64(AValue.NativeUInt) mod Round(BValue.Float80));
          end;
        vtInt64:
          case BValue.ValueType of
            vtByte: AssignInt64(Result, AValue.Signed64 mod BValue.Unsigned8);
            vtShortint: AssignInt64(Result, AValue.Signed64 mod BValue.Signed8);
            vtWord: AssignInt64(Result, AValue.Signed64 mod BValue.Unsigned16);
            vtSmallint: AssignInt64(Result, AValue.Signed64 mod BValue.Signed16);
            vtLongWord: AssignInt64(Result, AValue.Signed64 mod BValue.Unsigned32);
            vtInteger: AssignInt64(Result, AValue.Signed64 mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, AValue.Signed64 mod BValue.NativeInt);
            vtNativeUInt: AssignNativeUInt(Result, AValue.Signed64 mod Int64(BValue.NativeUInt));
            vtInt64: AssignInt64(Result, AValue.Signed64 mod BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed64 mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, AValue.Signed64 mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, AValue.Signed64 mod Round(BValue.Float80));
          end;
        vtSingle:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, Round(AValue.Float32) mod BValue.Unsigned8);
            vtShortint: AssignExtended(Result, Round(AValue.Float32) mod BValue.Signed8);
            vtWord: AssignExtended(Result, Round(AValue.Float32) mod BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, Round(AValue.Float32) mod BValue.Signed16);
            vtLongWord: AssignExtended(Result, Round(AValue.Float32) mod BValue.Unsigned32);
            vtInteger: AssignExtended(Result, Round(AValue.Float32) mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, Round(AValue.Float32) mod BValue.NativeInt);
            vtNativeUInt:
              AssignNativeUInt(Result, Round(AValue.Float32) mod Int64(BValue.NativeUInt));
            vtInt64: AssignExtended(Result, Round(AValue.Float32) mod BValue.Signed64);
            vtSingle: AssignExtended(Result, Round(AValue.Float32) mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, Round(AValue.Float32) mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, Round(AValue.Float32) mod Round(BValue.Float80));
          end;
        vtDouble:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, Round(AValue.Float64) mod BValue.Unsigned8);
            vtShortint: AssignExtended(Result, Round(AValue.Float64) mod BValue.Signed8);
            vtWord: AssignExtended(Result, Round(AValue.Float64) mod BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, Round(AValue.Float64) mod BValue.Signed16);
            vtLongWord: AssignExtended(Result, Round(AValue.Float64) mod BValue.Unsigned32);
            vtInteger: AssignExtended(Result, Round(AValue.Float64) mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, Round(AValue.Float64) mod BValue.NativeInt);
            vtNativeUInt:
              AssignNativeUInt(Result, Round(AValue.Float64) mod Int64(BValue.NativeUInt));
            vtInt64: AssignExtended(Result, Round(AValue.Float64) mod BValue.Signed64);
            vtSingle: AssignExtended(Result, Round(AValue.Float64) mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, Round(AValue.Float64) mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, Round(AValue.Float64) mod Round(BValue.Float80));
          end;
        vtExtended:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, Round(AValue.Float80) mod BValue.Unsigned8);
            vtShortint: AssignExtended(Result, Round(AValue.Float80) mod BValue.Signed8);
            vtWord: AssignExtended(Result, Round(AValue.Float80) mod BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, Round(AValue.Float80) mod BValue.Signed16);
            vtLongWord: AssignExtended(Result, Round(AValue.Float80) mod BValue.Unsigned32);
            vtInteger: AssignExtended(Result, Round(AValue.Float80) mod BValue.Signed32);
            vtNativeInt: AssignNativeInt(Result, Round(AValue.Float80) mod BValue.NativeInt);
            vtNativeUInt:
              AssignNativeUInt(Result, Round(AValue.Float80) mod Int64(BValue.NativeUInt));
            vtInt64: AssignExtended(Result, Round(AValue.Float80) mod BValue.Signed64);
            vtSingle: AssignExtended(Result, Round(AValue.Float80) mod Round(BValue.Float32));
            vtDouble: AssignExtended(Result, Round(AValue.Float80) mod Round(BValue.Float64));
            vtExtended: AssignExtended(Result, Round(AValue.Float80) mod Round(BValue.Float80));
          end;
      end;
    otDivide:
      case AValue.ValueType of
        vtByte:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Unsigned8 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Unsigned8 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Unsigned8 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Unsigned8 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Unsigned8 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Unsigned8 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Unsigned8 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Unsigned8 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Unsigned8 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned8 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned8 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned8 / BValue.Float80);
          end;
        vtShortint:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Signed8 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Signed8 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Signed8 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Signed8 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Signed8 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Signed8 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Signed8 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Signed8 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Signed8 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed8 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed8 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed8 / BValue.Float80);
          end;
        vtWord:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Unsigned16 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Unsigned16 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Unsigned16 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Unsigned16 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Unsigned16 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Unsigned16 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Unsigned16 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Unsigned16 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Unsigned16 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned16 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned16 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned16 / BValue.Float80);
          end;
        vtSmallint:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Signed16 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Signed16 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Signed16 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Signed16 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Signed16 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Signed16 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Signed16 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Signed16 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Signed16 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed16 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed16 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed16 / BValue.Float80);
          end;
        vtLongWord:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Unsigned32 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Unsigned32 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Unsigned32 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Unsigned32 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Unsigned32 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Unsigned32 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Unsigned32 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Unsigned32 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Unsigned32 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Unsigned32 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Unsigned32 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Unsigned32 / BValue.Float80);
          end;
        vtInteger:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Signed32 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Signed32 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Signed32 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Signed32 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Signed32 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Signed32 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Signed32 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Signed32 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Signed32 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed32 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed32 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed32 / BValue.Float80);
          end;
        vtNativeInt:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.NativeInt / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.NativeInt / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.NativeInt / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.NativeInt / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.NativeInt / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.NativeInt / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.NativeInt / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.NativeInt / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.NativeInt / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeInt / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeInt / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeInt / BValue.Float80);
          end;
        vtNativeUInt:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.NativeUInt / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.NativeUInt / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.NativeUInt / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.NativeUInt / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.NativeUInt / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.NativeUInt / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.NativeUInt / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.NativeUInt / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.NativeUInt / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.NativeUInt / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.NativeUInt / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.NativeUInt / BValue.Float80);
          end;
        vtInt64:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Signed64 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Signed64 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Signed64 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Signed64 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Signed64 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Signed64 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Signed64 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Signed64 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Signed64 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Signed64 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Signed64 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Signed64 / BValue.Float80);
          end;
        vtSingle:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float32 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float32 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float32 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float32 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float32 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float32 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float32 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float32 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float32 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float32 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float32 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float32 / BValue.Float80);
          end;
        vtDouble:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float64 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float64 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float64 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float64 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float64 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float64 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float64 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float64 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float64 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float64 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float64 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float64 / BValue.Float80);
          end;
        vtExtended:
          case BValue.ValueType of
            vtByte: AssignExtended(Result, AValue.Float80 / BValue.Unsigned8);
            vtShortint: AssignExtended(Result, AValue.Float80 / BValue.Signed8);
            vtWord: AssignExtended(Result, AValue.Float80 / BValue.Unsigned16);
            vtSmallint: AssignExtended(Result, AValue.Float80 / BValue.Signed16);
            vtLongWord: AssignExtended(Result, AValue.Float80 / BValue.Unsigned32);
            vtInteger: AssignExtended(Result, AValue.Float80 / BValue.Signed32);
            vtNativeInt: AssignExtended(Result, AValue.Float80 / BValue.NativeInt);
            vtNativeUInt: AssignExtended(Result, AValue.Float80 / BValue.NativeUInt);
            vtInt64: AssignExtended(Result, AValue.Float80 / BValue.Signed64);
            vtSingle: AssignExtended(Result, AValue.Float80 / BValue.Float32);
            vtDouble: AssignExtended(Result, AValue.Float80 / BValue.Float64);
            vtExtended: AssignExtended(Result, AValue.Float80 / BValue.Float80);
          end;
      end;
  end;
end;

function Negative(const Value: TValue): TValue;
begin
  Result := EmptyValue;
  case Value.ValueType of
    vtByte: AssignSmallint(Result, -Value.Unsigned8);
    vtShortint: AssignSmallint(Result, -Value.Signed8);
    vtWord: AssignInteger(Result, -Value.Unsigned16);
    vtSmallint: AssignInteger(Result, -Value.Signed16);
    vtLongWord: AssignInt64(Result, -Int64(Value.Unsigned32));
    vtInteger: AssignInt64(Result, -Int64(Value.Signed32));
    vtNativeInt: AssignInt64(Result, -Int64(Value.NativeInt));
    vtNativeUInt: AssignInt64(Result, -Int64(Value.NativeUInt));
    vtInt64: AssignInt64(Result, -Value.Signed64);
    vtSingle: AssignDouble(Result, -Value.Float32);
    vtDouble: AssignDouble(Result, -Value.Float64);
    vtExtended: AssignExtended(Result, -Value.Float80);
  end;
end;

function Positive(const Value: TValue): TValue;
begin
  Result := EmptyValue;
  case Value.ValueType of
    vtByte, vtWord, vtLongWord, vtNativeUInt: Result := Value;
    vtShortint:
      if Value.Signed8 < 0 then
        AssignSmallint(Result, -Value.Signed8)
      else
        Result := Value;
    vtSmallint:
      if Value.Signed16 < 0 then
        AssignInteger(Result, -Value.Signed16)
      else
        Result := Value;
    vtInteger:
      if Value.Signed32 < 0 then
        AssignInt64(Result, -Int64(Value.Signed32))
      else
        Result := Value;
    vtNativeInt:
      if Value.NativeInt < 0 then
        AssignInt64(Result, -Int64(Value.NativeInt))
      else
        Result := Value;
    vtInt64:
      if Value.Signed64 < 0 then
        AssignInt64(Result, -Value.Signed64)
      else
        Result := Value;
    vtSingle: AssignSingle(Result, Abs(Value.Float32));
    vtDouble: AssignDouble(Result, Abs(Value.Float64));
    vtExtended: AssignExtended(Result, Abs(Value.Float80));
  end;
end;

end.
