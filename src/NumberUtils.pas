{ ************************************************************************** }
{                                                                            }
{ NumberUtils                                                                }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit NumberUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, SysUtils, SysConst, Types, MemoryUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils, System.Classes, System.StrUtils, System.SysConst, MemoryUtils;
  {$ELSE}
  SysUtils, Classes, StrUtils, SysConst, MemoryUtils;
  {$ENDIF}
  {$ENDIF}

type
  {$IFDEF FPC}
  TBits = class(Classes.TBits)
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  TBits = class(System.Classes.TBits)
  {$ELSE}
  TBits = class(Classes.TBits)
  {$ENDIF}
  {$ENDIF}
  public
    procedure Open(const Value: Int64); overload; virtual;
    procedure Open(const Value: Integer); overload; virtual;
    procedure Open(const Value: Byte); overload; virtual;
    procedure Save(out Value: Int64); overload; virtual;
    procedure Save(out Value: Integer); overload; virtual;
    procedure Save(out Value: Byte); overload; virtual;
  end;
{$IFDEF FPC}
function NumberSwap<T>(var A, B: T): Boolean;
function Swap(var A, B: NativeInt): Boolean; overload;
function Swap(var A, B: Int64): Boolean; overload;
function Swap(var A, B: Integer): Boolean; overload;
function Swap(var A, B: Word): Boolean; overload;
function Swap(var A, B: Byte): Boolean; overload;
function Swap(var A, B: Single): Boolean; overload;
function Swap(var A, B: Extended): Boolean; overload;
{$ENDIF}
type
  {$IFNDEF FPC}
  TNumber = record
    class function Swap<T>(var A, B: T): Boolean; static;
  end;
  {$ENDIF}
  TFloatFormat = record
  public
    class function Get(const Precision: Integer): string; static;
  end;
  TRange = record
    MinValue: Integer;
    MaxValue: Integer;
  end;
  TRangeArray = array of TRange;
function GetHashCode(const Memory: Pointer; const Size: Integer): Integer; overload;
function GetHashCode(const Value: string): Integer; overload;
function Equal(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function Equal(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function Above(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function Above(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function AboveOrEqual(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function AboveOrEqual(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function AOE(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function AOE(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function Below(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function Below(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function BelowOrEqual(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function BelowOrEqual(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function BOE(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean; overload;
function BOE(const AValue, BValue: Integer; const AEpsilon: Integer): Boolean; overload;
function Within(const Value, Min, Max: Integer): Boolean; overload;
function Within(const Value, Min, Max: Extended; const AEpsilon: Extended = 0): Boolean; overload;
function RandomValue(const Min, Max: Extended): Extended; overload;
function RandomValue(const Probability: Extended): Integer; overload;
function NextStep(const Value, Distance: Extended; const Index: Integer;
  const Epsilon: Extended = 0): Extended;
function Positive(const Value: Integer): Integer;
function FracSize(const Value: Extended): Integer;
function CleanFloat(const Source: string; const Separator: Char): string; overload;
function CleanFloat(const Source: string): string; overload;
function FitInto(const Value, MaxValue: Extended): Extended; overload;
function FitInto(const Value, MaxValue: Integer): Integer; overload;
function Interpolate(const A: TExtendedDynArray; const Size: Integer): TExtendedDynArray;
function LInterpolate(const A, B: Extended; const Factor: Extended): Extended;
function LExtrapolate(const MinRatio, MaxRatio: Extended; const Value, MaxValue: Integer;
  const Invert: Boolean): Extended;
function SExtrapolate(const MinRatio, MaxRatio: Extended; const Value, MaxValue: Integer;
  const Invert: Boolean): Extended;
function RandomDeviation(const MaxDeviation: Extended): Extended;
function SmoothArray(const Target: TExtendedDynArray; const WindowSize: Integer;
  const MinLimit: Boolean = False; const MaxLimit: Boolean = False; const MinValue: Extended = 0;
  const MaxValue: Extended = 0): TExtendedDynArray;
function CalcTrend(const Target: TExtendedDynArray; const WindowSize: Integer;
  out ExpandChange, NarrowChange: Extended): Integer;
function ProductOfArray(const A: array of Single): Extended; overload;
{$IFNDEF FPC}
function ProductOfArray(const A: array of Double): Extended; overload;
{$ENDIF}
function ProductOfArray(const A: array of Extended): Extended; overload;
function GeometricMean(const A: array of Single): Extended; overload;
{$IFNDEF FPC}
function GeometricMean(const A: array of Double): Extended; overload;
{$ENDIF}
function GeometricMean(const A: array of Extended): Extended; overload;
function HarmonicMean(const A: array of Single): Extended; overload;
{$IFNDEF FPC}
function HarmonicMean(const A: array of Double): Extended; overload;
{$ENDIF}
function HarmonicMean(const A: array of Extended): Extended; overload;
function IsNumber(const Text: string): Boolean;
function IsFloatNumber(const Text: string): Boolean;
function MakeRange(const MinValue, MaxValue: Integer): TRange;
function SplitRange(const Min, Max, Count: Integer): TRangeArray;
function GetRangeIndex(const Value: Integer; const Ranges: TRangeArray): Integer;
procedure InvertRanges(var Ranges: TRangeArray);
var
  Bits: TBits;
  Epsilon: Extended = 0;
implementation
uses
  {$IFDEF FPC}
  Math, StrUtils, TextUtils, ScriptFormat;
  {$ELSE}
  Math, {$IFNDEF UNICODE}TextUtils,{$ENDIF}Types, ScriptFormat;
  {$ENDIF}
{ TBits }
procedure TBits.Open(const Value: Int64);
var
  I: Integer;
begin
  Size := SizeOf(Value) * 8;
  for I := 0 to Size - 1 do Bits[I] := (Value and Round(IntPower(2, I))) > 0;
end;
procedure TBits.Open(const Value: Integer);
var
  I: Integer;
begin
  Size := SizeOf(Value) * 8;
  for I := 0 to Size - 1 do Bits[I] := (Value and Round(IntPower(2, I))) > 0;
end;
procedure TBits.Open(const Value: Byte);
var
  I: Integer;
begin
  Size := SizeOf(Value) * 8;
  for I := 0 to Size - 1 do Bits[I] := (Value and Round(IntPower(2, I))) > 0;
end;
procedure TBits.Save(out Value: Int64);
var
  I: Integer;
begin
  Value := 0;
  for I := 0 to Size - 1 do
    if Bits[I] then Value := Value or Round(IntPower(2, I));
end;
procedure TBits.Save(out Value: Integer);
var
  I: Integer;
begin
  Value := 0;
  for I := 0 to Size - 1 do
    if Bits[I] then Value := Value or Round(IntPower(2, I));
end;
procedure TBits.Save(out Value: Byte);
var
  I: Integer;
begin
  Value := 0;
  for I := 0 to Size - 1 do
    if Bits[I] then Value := Value or Round(IntPower(2, I));
end;
function Bit(const Value: Int64; const Index: Integer): Boolean;
begin
  Bits.Open(Value);
  Result := Bits.Bits[Index];
end;
function GetHashCode(const Memory: Pointer; const Size: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  {$IFDEF FPC}
  for I := 0 to Size - 1 do
    Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor (PByte(Memory) + I)^;
  {$ELSE}
  for I := 0 to Size - 1 do
    Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor
      {$IFDEF DELPHI_10.2}(PByte(Memory) + I)^{$ELSE}PByte(Integer(Memory) + I)^{$ENDIF};
  {$ENDIF}
end;
function GetHashCode(const Value: string): Integer;
begin
  Result := GetHashCode(Pointer(Value), Length(Value) * SizeOf(Char));
end;
function Equal(const AValue, BValue: Extended; AEpsilon: Extended): Boolean;
begin
  if AEpsilon = 0 then AEpsilon := Epsilon;
  Result := SameValue(AValue, BValue, AEpsilon);
end;
function Equal(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := Abs(AValue - BValue) <= AEpsilon;
end;
function Above(const AValue, BValue: Extended; AEpsilon: Extended): Boolean;
begin
  if AEpsilon = 0 then AEpsilon := Epsilon;
  Result := CompareValue(AValue, BValue, AEpsilon) = GreaterThanValue;
end;
function Above(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := not Equal(AValue, BValue, AEpsilon) and (AValue > BValue);
end;
function AboveOrEqual(const AValue, BValue: Extended; AEpsilon: Extended): Boolean;
begin
  if AEpsilon = 0 then AEpsilon := Epsilon;
  Result := CompareValue(AValue, BValue, AEpsilon) <> LessThanValue;
end;
function AboveOrEqual(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := Equal(AValue, BValue, AEpsilon) or (AValue > BValue);
end;
function AOE(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean;
begin
  Result := AboveOrEqual(AValue, BValue, AEpsilon);
end;
function AOE(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := AboveOrEqual(AValue, BValue, AEpsilon);
end;
function Below(const AValue, BValue: Extended; AEpsilon: Extended): Boolean;
begin
  if AEpsilon = 0 then AEpsilon := Epsilon;
  Result := CompareValue(AValue, BValue, AEpsilon) = LessThanValue;
end;
function Below(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := not Equal(AValue, BValue, AEpsilon) and (AValue < BValue);
end;
function BelowOrEqual(const AValue, BValue: Extended; AEpsilon: Extended): Boolean;
begin
  if AEpsilon = 0 then AEpsilon := Epsilon;
  Result := CompareValue(AValue, BValue, AEpsilon) <> GreaterThanValue;
end;
function BelowOrEqual(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := Equal(AValue, BValue, AEpsilon) or (AValue < BValue);
end;
function BOE(const AValue, BValue: Extended; AEpsilon: Extended = 0): Boolean;
begin
  Result := BelowOrEqual(AValue, BValue, AEpsilon);
end;
function BOE(const AValue, BValue, AEpsilon: Integer): Boolean;
begin
  Result := BelowOrEqual(AValue, BValue, AEpsilon);
end;
function Within(const Value, Min, Max: Integer): Boolean;
begin
  Result := (Value >= Min) and (Value <= Max);
end;
function Within(const Value, Min, Max, AEpsilon: Extended): Boolean;
begin
  Result := AOE(Value, Min, AEpsilon) and BOE(Value, Max, AEpsilon);
end;
function RandomValue(const Min, Max: Extended): Extended;
begin
  Result := Min + (Max - Min) * Random;
end;
function RandomValue(const Probability: Extended): Integer;
begin
  if (Probability <= 0) or (Probability > 1) then
    Result := 0
  else
    if Random <= Probability then
      Result := 1
    else
      Result := 0;
end;
function NextStep(const Value, Distance: Extended; const Index: Integer; const Epsilon: Extended): Extended;
var
  A: Extended;
begin
  A := Value / Distance;
  if (Index = 0) and Equal(Frac(A), 0, Epsilon) then
    Result := Value
  else
    Result := (Int(A) + Index) * Distance;
end;
function Positive(const Value: Integer): Integer;
begin
  if Value < 0 then
    Result := -Value
  else
    Result := Value;
end;
function FracSize(const Value: Extended): Integer;
begin
  if Value > 0 then
  begin
    Result := Round(Log10(1 / Value));
    if Result < 0 then Result := 0;
  end
  else
    Result := 0;
end;
function Swap(var A, B): Boolean;
var
  Size: Integer;
  Temp: Pointer;
begin
  Size := SizeOf(A);
  Result := Size = SizeOf(B);
  if Result then
  begin
    GetMem(Temp, Size);
    try
      Move(A, Temp^, Size);
      Move(A, B, Size);
      Move(B, Temp^, Size);
    finally
      FreeMem(Temp);
    end;
  end;
end;
{$IFDEF FPC}
function NumberSwap<T>(var A, B: T): Boolean;
var
  C: T;
begin
  C := A;
  A := B;
  B := C;
  Result := True;
end;
function Swap(var A, B: NativeInt): Boolean;
begin
  Result := NumberSwap<NativeInt>(A, B);
end;
function Swap(var A, B: Int64): Boolean;
begin
  Result := NumberSwap<Int64>(A, B);
end;
function Swap(var A, B: Integer): Boolean;
begin
  Result := NumberSwap<Integer>(A, B);
end;
function Swap(var A, B: Word): Boolean;
begin
  Result := NumberSwap<Word>(A, B);
end;
function Swap(var A, B: Byte): Boolean;
begin
  Result := NumberSwap<Byte>(A, B);
end;
function Swap(var A, B: Single): Boolean;
begin
  Result := NumberSwap<Single>(A, B);
end;
function Swap(var A, B: Extended): Boolean;
begin
  Result := NumberSwap<Extended>(A, B);
end;
{$ENDIF}
{$IFNDEF FPC}
{ TNumber }
class function TNumber.Swap<T>(var A, B: T): Boolean;
var
  C: T;
begin
  C := A;
  A := B;
  B := C;
  Result := True;
end;
{$ENDIF}
{ TFloatFormat }
class function TFloatFormat.Get(const Precision: Integer): string;
const
  Template = '0.';
begin
  Result := Template + DupeString('#', Precision);
end;
function CleanFloat(const Source: string; const Separator: Char): string; overload;
  procedure Put(var S: string; const C: Char; var Index: Integer);
  begin
    S[Index] := C;
    Inc(Index);
  end;
var
  I, J, K: Integer;
  C: Char;
begin
  K := Length(Source);
  SetLength(Result, K);
  J := 1;
  for I := 1 to K do
  begin
    C := Source[I];
    case C of
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': Put(Result, C, J);
      ',', '.': Put(Result, Separator, J);
    end;
  end;
  SetLength(Result, J - 1);
end;
function CleanFloat(const Source: string): string; overload;
begin
  Result := CleanFloat(Source, ParseFormat.DecimalSeparator);
end;
function FitInto(const Value, MaxValue: Extended): Extended;
begin
  if IsNan(Value) or IsInfinite(Value) or IsNan(MaxValue) or IsInfinite(MaxValue) or (MaxValue = 0) then
  begin
    Result := 0;
    Exit;
  end;
  Result := Value - MaxValue * Floor((Value + MaxValue) / MaxValue);
  if Result < 0 then
    Result := Result + MaxValue;
  if Result >= MaxValue then
    Result := Result - MaxValue;
end;
function FitInto(const Value, MaxValue: Integer): Integer;
begin
  if MaxValue = 0 then
  begin
    Result := 0;
    Exit;
  end;
  Result := Value mod MaxValue;
  if Result < 0 then
    Inc(Result, MaxValue);
  if Result >= MaxValue then
    Dec(Result, MaxValue);
end;
function Interpolate(const A: TExtendedDynArray; const Size: Integer): TExtendedDynArray;
var
  I, J: Integer;
  T: Extended;
begin
  J := Length(A);
  if (Size < 1) or (J = 0) then
  begin
    Result := nil;
    Exit;
  end;
  if (Size = J) or (Size = 1) then
  begin
    Result := System.Copy(A);
    Exit;
  end;
  SetLength(Result, Size);
  for I := 0 to Size - 1 do
  begin
    T := I / (Size - 1) * (J - 1);
    if Floor(T) = Ceil(T) then
      Result[I] := A[Round(T)]
    else
      Result[I] := LInterpolate(A[Floor(T)], A[Ceil(T)], Frac(T));
  end;
end;
function LInterpolate(const A, B, Factor: Extended): Extended;
begin
  Result := A + (B - A) * Factor;
end;
function LExtrapolate(const MinRatio, MaxRatio: Extended; const Value, MaxValue: Integer;
  const Invert: Boolean): Extended;
begin
  if Invert then
    Result := MaxRatio - ((Value / MaxValue) * (MaxRatio - MinRatio))
  else
    Result := MinRatio + ((Value / MaxValue) * (MaxRatio - MinRatio));
end;
function SExtrapolate(const MinRatio, MaxRatio: Extended; const Value, MaxValue: Integer;
  const Invert: Boolean): Extended;
begin
  if Invert then
    Result := MaxRatio - MaxRatio * Sin(ArcSin(((Value * (MaxRatio - MinRatio)) / MaxValue) / MaxRatio))
  else
    Result := MinRatio + MaxRatio * Sin(ArcSin(((Value * (MaxRatio - MinRatio)) / MaxValue) / MaxRatio));
end;
function RandomDeviation(const MaxDeviation: Extended): Extended;
begin
  Result := (Random * 2 - 1) * MaxDeviation;
end;
function ProductOfArray(const A: array of Single): Extended;
var
  I: Integer;
begin
  Result := 1;
  for I := Low(A) to High(A) do Result := Result * A[I];
end;
{$IFNDEF FPC}
function ProductOfArray(const A: array of Double): Extended;
var
  I: Integer;
begin
  Result := 1;
  for I := Low(A) to High(A) do Result := Result * A[I];
end;
{$ENDIF}
function ProductOfArray(const A: array of Extended): Extended;
var
  I: Integer;
begin
  Result := 1;
  for I := Low(A) to High(A) do Result := Result * A[I];
end;
function GeometricMean(const A: array of Single): Extended;
begin
  if Length(A) > 0 then
    Result := Power(ProductOfArray(A), 1 / Length(A))
  else
    Result := 0;
end;
{$IFNDEF FPC}
function GeometricMean(const A: array of Double): Extended;
begin
  if Length(A) > 0 then
    Result := Power(ProductOfArray(A), 1 / Length(A))
  else
    Result := 0;
end;
{$ENDIF}
function GeometricMean(const A: array of Extended): Extended;
begin
  if Length(A) > 0 then
    Result := Power(ProductOfArray(A), 1 / Length(A))
  else
    Result := 0;
end;
function HarmonicMean(const A: array of Single): Extended;
var
  I, J: Integer;
begin
  Result := 0;
  if Length(A) > 0 then
  begin
    J := 0;
    for I := Low(A) to High(A) do
      if A[I] > 0 then
      begin
        Result := Result + 1 / A[I];
        Inc(J);
      end;
    if J > 0 then
      Result := J / Result
    else
      Result := 0;
  end;
end;
{$IFNDEF FPC}
function HarmonicMean(const A: array of Double): Extended;
var
  I, J: Integer;
begin
  Result := 0;
  if Length(A) > 0 then
  begin
    J := 0;
    for I := Low(A) to High(A) do
      if A[I] > 0 then
      begin
        Result := Result + 1 / A[I];
        Inc(J);
      end;
    if J > 0 then
      Result := J / Result
    else
      Result := 0;
  end;
end;
{$ENDIF}
function HarmonicMean(const A: array of Extended): Extended;
var
  I, J: Integer;
begin
  Result := 0;
  if Length(A) > 0 then
  begin
    J := 0;
    for I := Low(A) to High(A) do
      if A[I] > 0 then
      begin
        Result := Result + 1 / A[I];
        Inc(J);
      end;
    if J > 0 then
      Result := J / Result
    else
      Result := 0;
  end;
end;
function SmoothArray(const Target: TExtendedDynArray; const WindowSize: Integer;
  const MinLimit, MaxLimit: Boolean; const MinValue, MaxValue: Extended): TExtendedDynArray;
var
  I, J: Integer;
  Sum: Extended;
begin
  SetLength(Result, Length(Target));
  for I := Low(Target) to High(Target) do
  begin
    Sum := 0;
    for J := Max(0, I - WindowSize) to Min(High(Target), I + WindowSize) do
      Sum := Sum + Target[J];
    Result[I] := Sum / (Min(High(Target), I + WindowSize) - Max(0, I - WindowSize) + 1);
    if MinLimit and (Result[I] < MinValue) then Result[I] := MinValue;
    if MaxLimit and (Result[I] > MaxValue) then Result[I] := MaxValue;
  end;
end;
function CalcTrend(const Target: TExtendedDynArray; const WindowSize: Integer;
  out ExpandChange, NarrowChange: Extended): Integer;
type
  TTotal = record
    Narrow: Extended;
    Expand: Extended;
  end;
  TCount = record
    Narrow: Integer;
    Expand: Integer;
  end;
  TAvg = record
    A, B: Extended;
  end;
var
  I, J, A, B, C: Integer;
  Sum: TExtendedDynArray;
  Total: TTotal;
  Count: TCount;
  Avg: TAvg;
  Diff: Extended;
begin
  ExpandChange := 0;
  NarrowChange := 0;
  if (Length(Target) = 0) or (WindowSize <= 0) or (WindowSize >= Length(Target)) then
  begin
    Result := 0;
    Exit;
  end;
  SetLength(Sum, Length(Target));
  try
    A := 0;
    B := Length(Target) - 1;
    C := WindowSize * 2;
    Sum[0] := Target[0];
    for I := 1 to B do Sum[I] := Sum[I - 1] + Target[I];
    FillChar(Total, SizeOf(TTotal), 0);
    FillChar(Count, SizeOf(TCount), 0);
    I := A;
    while I <= B - WindowSize do
    begin
      if I > 0 then
        Avg.A := (Sum[I + WindowSize - 1] - Sum[I - 1]) / WindowSize
      else
        Avg.A := (Sum[I + WindowSize - 1]) / WindowSize;
      J := Min(WindowSize, B - (I + WindowSize) + 1);
      Avg.B := (Sum[I + WindowSize + J - 1] - Sum[I + WindowSize - 1]) / J;
      Diff := Avg.B - Avg.A;
      if Diff > 0 then
      begin
        Total.Expand := Total.Expand + Diff;
        Inc(Count.Expand);
      end
      else if Diff < 0 then
      begin
        Total.Narrow := Total.Narrow - Diff;
        Inc(Count.Narrow);
      end;
      Inc(I, C);
    end;
    if Count.Narrow > 0 then
      Total.Narrow := Total.Narrow / Count.Narrow;
    if Count.Expand > 0 then
      Total.Expand := Total.Expand / Count.Expand;
    if Total.Expand > Total.Narrow then
      Result := -1
    else
      if Total.Expand < Total.Narrow then
        Result := 1
      else
        Result := 0;
    case Result of
      -1: ExpandChange := Total.Expand;
      1: NarrowChange := Total.Narrow;
    end;
  finally
    Sum := nil;
  end;
end;

function IsNumber(const Text: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(Text) do
  begin
    case Text[I] of
      '0'..'9': Continue;
    end;
    Result := False;
    Exit;
  end;
  Result := Text <> '';
end;

function IsFloatNumber(const Text: string): Boolean;
var
  I, J: Integer;
begin
  J := 0;
  for I := 1 to Length(Text) do
  begin
    case Text[I] of
      '0'..'9': Continue;
    else
      if (Text[I] = ParseFormat.DecimalSeparator) and (J = 0) then
      begin
        Inc(J);
        Continue;
      end;
    end;
    Result := False;
    Exit;
  end;
  Result := Text <> '';
end;

function MakeRange(const MinValue, MaxValue: Integer): TRange;
begin
  FillChar(Result, SizeOf(TRange), 0);
  Result.MinValue := MinValue;
  Result.MaxValue := MaxValue;
end;

function SplitRange(const Min, Max, Count: Integer): TRangeArray;
var
  I, SpanSize, BaseSize, Leftover, CurrentMin: Integer;
begin
  Result := nil;
  if (Min > Max) or (Count < 1) then Exit;
  SpanSize := Max - Min + 1;
  BaseSize := SpanSize div Count;
  Leftover := SpanSize mod Count;
  SetLength(Result, Count);
  CurrentMin := Min;
  for I := 0 to Count - 1 do
  begin
    Result[I].MinValue := CurrentMin;
    Result[I].MaxValue := CurrentMin + BaseSize - 1;
    if Leftover > 0 then
    begin
      Inc(Result[I].MaxValue);
      Dec(Leftover);
    end;
    CurrentMin := Result[I].MaxValue + 1;
  end;
end;

function GetRangeIndex(const Value: Integer; const Ranges: TRangeArray): Integer;
var
  I: Integer;
begin
  for I := Low(Ranges) to High(Ranges) do
    if (Value >= Ranges[I].MinValue) and (Value <= Ranges[I].MaxValue) then
    begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

procedure InvertRanges(var Ranges: TRangeArray);
var
  I, J: Integer;
begin
  J := Length(Ranges) - 1;
  for I := 0 to Floor(Length(Ranges) / 2) - 1 do
    {$IFDEF FPC}NumberSwap{$ELSE}TNumber.Swap{$ENDIF}<TRange>(Ranges[I], Ranges[J - I]);
end;

initialization
  Randomize;
  Bits := TBits.Create;

finalization
  Bits.Free;

end.
