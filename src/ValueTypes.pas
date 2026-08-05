{ ************************************************************************** }
{                                                                            }
{ ValueTypes                                                                 }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ValueTypes;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, MemoryUtils;
  {$ELSE}
  SysUtils, MemoryUtils;
  {$ENDIF}

type
  PValueType = ^TValueType;
  TValueType = (
    vtUnknown,
    vtByte,
    vtShortint,
    vtWord,
    vtSmallint,
    vtLongWord,
    vtInteger,
    vtNativeInt,
    vtNativeUInt,
    vtInt64,
    vtSingle,
    vtDouble,
    vtExtended);

  PValue = ^TValue;
  {$IFDEF FPC}{$PACKRECORDS 8}{$ENDIF}
  TValue = record
    ValueType: TValueType;
    case Byte of
      0: (ByteArray: array[0..9] of Byte);
      1: (Unsigned8: Byte);
      2: (Signed8: Shortint);
      3: (Boolean8: Boolean);
      4: (Unsigned16: Word);
      5: (Signed16: Smallint);
      6: (Boolean16: WordBool);
      7: (Unsigned32: LongWord);
      8: (Signed32: Integer);
      9: (NativeInt: NativeInt);
      10: (NativeUInt: NativeUInt);
      11: (Boolean32: LongBool);
      12: (Signed64: Int64);
      13: (Float32: Single);
      14: (Float64: Double);
      15: (Float80: Extended);
      16: (WordRec: WordRec);
      17: (LongRec: LongRec);
      18: (Int64Rec: Int64Rec);
      19: (NativeIntRec: NativeIntRec);
  end;

  PValueArray = ^TValueArray;
  TValueArray = array of TValue;

  {$IFNDEF FPC}
  {$IFNDEF DELPHI_2010}
  PLongBool = ^LongBool;
  {$ENDIF}
  {$ENDIF}

  PValueRef = ^TValueRef;
  TValueRef = record
    ValueType: TValueType;
    case Byte of
      0: (Unsigned8: PByte);
      1: (Signed8: PShortint);
      2: (Boolean8: PBoolean);
      3: (Unsigned16: PWord);
      4: (Signed16: PSmallint);
      5: (Boolean16: PWordBool);
      6: (Unsigned32: PLongWord);
      7: (Signed32: PInteger);
      8: (NativeInt: PNativeInt);
      9: (NativeUInt: PNativeUInt);
      10: (Boolean32: PLongBool);
      11: (Signed64: PInt64);
      12: (Float32: PSingle);
      13: (Float64: PDouble);
      14: (Float80: PExtended);
  end;

const
  ValidTypeSet = [
    vtByte,
    vtShortint,
    vtWord,
    vtSmallint,
    vtLongWord,
    vtInteger,
    vtNativeInt,
    vtNativeUInt,
    vtInt64,
    vtSingle,
    vtDouble,
    vtExtended];
  FloatTypeSet = [
    vtSingle,
    vtDouble,
    vtExtended];
  IntegerTypeSet = [
    vtByte,
    vtShortint,
    vtWord,
    vtSmallint,
    vtLongWord,
    vtInteger,
    vtNativeInt,
    vtNativeUInt,
    vtInt64];
  SignedTypeSet = [
    vtShortint,
    vtSmallint,
    vtInteger,
    vtNativeInt,
    vtInt64,
    vtSingle,
    vtDouble,
    vtExtended];
  UnsignedTypeSet = [
    vtByte,
    vtWord,
    vtLongWord,
    vtNativeUInt];

function AddValue(var Target: TValueArray; const Value: TValue): Integer;
function DeleteValue(var Target: TValueArray; const Index: Integer): Boolean;
function NextValueType(const ValueType: TValueType): TValueType;
function Assignable(const Source, Target: TValueType): Boolean;

implementation

function AddValue(var Target: TValueArray; const Value: TValue): Integer;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  MemoryUtils.Add(Target, @Value, Result * SizeOf(TValue), SizeOf(TValue));
end;

function DeleteValue(var Target: TValueArray; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Target);
  Result := MemoryUtils.Delete(Target, Index * SizeOf(TValue), SizeOf(TValue), Size * SizeOf(TValue));
  if Result then SetLength(Target, Size - 1);
end;

function NextValueType(const ValueType: TValueType): TValueType;
begin
  case ValueType of
    vtByte: Result := vtWord;
    vtShortint: Result := vtSmallint;
    vtWord: Result := vtLongWord;
    vtSmallint: Result := vtInteger;
    vtLongWord, vtInteger, vtNativeInt, vtNativeUInt, vtInt64: Result := vtInt64;
    vtSingle: Result := vtDouble;
    vtDouble: Result := vtExtended;
  else
    Result := ValueType;
  end;
end;

function Assignable(const Source, Target: TValueType): Boolean;
begin
  Result := Source in [Target..High(TValueType)];
end;

end.
