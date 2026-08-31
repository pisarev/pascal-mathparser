{ ************************************************************************** }
{                                                                            }
{ TextUtils                                                                  }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit TextUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Classes, Math, Types, MemoryUtils, TextConsts, TextTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.SysUtils, System.Classes, System.Math, System.Types, MemoryUtils,
  TextConsts, TextTypes;
  {$ELSE}
  Windows, SysUtils, Classes, Math, Types, MemoryUtils, TextConsts, TextTypes;
  {$ENDIF}
  {$ENDIF}

type
  TTrimKind = (tkL, tkR, tkLR);
  TKMPEvent = function(const Index: Integer; const P: Pointer): Boolean;

function GetValueFromIndex(const Strings: TStrings; const Index: Integer): string;
procedure SetValueFromIndex(const Strings: TStrings; Index: Integer; const Value: string);

{$IFNDEF FPC}
function WideToAnsi(const Text: WideString; Index, Count: Integer): WideString; overload;
function AnsiToWide(const Text: AnsiString; Index, Count: Integer): AnsiString; overload;
function WideToAnsi(const Source: WideString; out Target: AnsiString): Boolean; overload;
function WideToAnsi(const Text: WideString): AnsiString; overload;
function AnsiToWide(const Source: AnsiString; out Target: WideString): Boolean; overload;
function AnsiToWide(const Text: AnsiString): WideString; overload;
function WideCharToAnsiChar(const Source: WideChar; out Target: AnsiChar): Boolean; overload;
function AnsiCharToWideChar(const Source: AnsiChar; out Target: WideChar): Boolean; overload;
function WideCharToAnsiChar(const C: WideChar): AnsiChar; overload;
function AnsiCharToWideChar(const C: AnsiChar): WideChar; overload;
function OemToString(const Text: AnsiString): string;
function StringToOem(const Text: string): AnsiString;
function Utf8ToAnsi(const Source: UTF8String): AnsiString;
{$IFDEF UNICODE}
function CharInSet(C: WideChar; const CharSet: TSysCharSet): Boolean;
{$ELSE}
function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
{$ENDIF}
{$ENDIF}

{$IFDEF DELPHI_10.2}
function ToUTF8(const S: string): string;
function ToANSI(const S: string): string;
{$ENDIF}

function NextBracket(const Text: string; const Bracket: TBracket; Index: NativeInt): NativeInt; overload;
function NextBracket(const Text: string; const FlagArray: TFlagArray; const Bracket: TBracket;
  Index: NativeInt): NativeInt; overload;
function PrevBracket(const Text: string; const Bracket: TBracket; Index: NativeInt): NativeInt; overload;
function PrevBracket(const Text: string; const FlagArray: TFlagArray; const Bracket: TBracket;
  Index: NativeInt): NativeInt; overload;
function GetLockArray(const Text: string; const LockBracket: TBracket): TLockArray; overload;
function GetLockArray(const Text: string; const FlagArray: TFlagArray;
  const BracketArray: {$IFDEF DELPHI_10.2}TArray<TBracket>{$ELSE}array of TBracket{$ENDIF}): TLockArray; overload;
function GetLockArray(const Text: string; const Lock: string): TLockArray; overload;
function GetFlagArray(const Text: string; const LockBracket: TBracket): TFlagArray; overload;
function GetFlagArray(const Text: string; const Lock: string): TFlagArray; overload;
function GetFlagArray(const Text: string; const LockArray: TLockArray): TFlagArray; overload;
function GetFlagArray(const Text: string; const LockType: TLockType): TFlagArray; overload;
function UnionFlagArray(const FlagArray: {$IFDEF DELPHI_10.2}TArray<TFlagArray>{$ELSE}array of TFlagArray{$ENDIF}): TFlagArray;
function LockCompare(const Target, Value: Pointer; const Index: Integer;
  const Data: Pointer = nil): TValueRelationship;
function LockSearch(const Target: TLockArray; const Index: Integer): Integer;
function Locked(const Index: NativeInt; const LockArray: TLockArray; const FromIndex: PNativeInt = nil;
  const TillIndex: PNativeInt = nil): Boolean; overload;
function Locked(const Index: NativeInt; const FlagArray: TFlagArray): Boolean; overload;

function TextCopy(const Target: PChar; const Size: Integer; const Source: string): Integer; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function CompareText(const AText, BText: PChar; const ASize, BSize: Integer; const IgnoreCase: Boolean = True): Integer; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function SameText(const AText, BText: PChar; const Size: Integer = 0;
  const IgnoreCase: Boolean = True): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF} overload;
function Same(const AText, BText: PChar; const Size: Integer = 0;
  const IgnoreCase: Boolean = True): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF} overload;
function SameText(const AText, BText: string;
  const IgnoreCase: Boolean = True): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF} overload;
function Same(const AText, BText: string;
  const IgnoreCase: Boolean = True): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF} overload;
function Consists(const Text: string; const CharSet: TSysCharSet): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}
function Contains(const Text, SubStr: string; const Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF} = nil; const IgnoreCase: Boolean = True;
  const Direction: Integer = 1): Boolean; {$IFDEF DELPHI_10.2}inline;{$ENDIF}

function TrimText(var Text: string; const Count: Integer; const Kind: TTrimKind;
  const Trim: Boolean = True): Boolean; overload;
function TrimText(const Text: string; const Kind: TTrimKind;
  const CharSet: TSysCharSet = [Space]): string; overload;
function DeletePrefix(var Text: string; const Prefix: string; const Trim: Boolean = True;
  const IgnoreCase: Boolean = True): Boolean; overload;

function GetPrefix(const Text: string; const IgnoreCase: Boolean = True;
  const Direction: Integer = 1): {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
function KMPSearch(const Text, SubStr: string;
  const Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF}; const Offset: Integer;
  const Event: TKMPEvent; const P: Pointer; const IgnoreCase: Boolean = True;
  const Direction: Integer = 1): Integer;
function IndexOf(const Text, SubStr: string;
  const Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF}; const IgnoreCase: Boolean;
  const Offset: Integer = 1; const Direction: Integer = 1;
  const FlagArray: TFlagArray = nil): Integer; overload;
function IndexOf(const Text, SubStr: string; const IgnoreCase: Boolean; const Offset: Integer = 1;
  const Direction: Integer = 1; const FlagArray: TFlagArray = nil): Integer; overload;
function IndexOf(const Text, Delimiter, SubStr: string; const IgnoreCase: Boolean;
  const Direction: Integer = 1): Integer; overload;

function Extract(const Text, Delimiter: string; const Index: Integer; const IgnoreCase: Boolean): string;
function FindSubStr(const Text, Delimiter: string; const Index: Integer; const IgnoreCase: Boolean;
  out FromIndex, TillIndex: Integer): Boolean;
function SubStr(const Text, Delimiter: string; const Index: Integer;
  const IgnoreCase: Boolean): string; overload;
function SubStr(const Text, Delimiter: string; const FromIndex, TillIndex: Integer;
  const IgnoreCase: Boolean): string; overload;
function SubStrCnt(const Text, SubStr: string; const IgnoreCase: Boolean): Integer;
function Split(const Text, Delimiter: string;
  var SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF}; const IgnoreCase: Boolean;
  const MaxCount: Integer = 0; const FlagArray: TFlagArray = nil): Boolean;

function Duplicated(const Text: string; Index: Integer): Boolean;

function EmptyArray(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF}): Boolean;
function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const TrimText: Boolean = True): string; overload;
function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const Default: Integer; const TrimText: Boolean = True): Integer; overload;
function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const Default: Single; const TrimText: Boolean = True): Single; overload;
function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const Default: Double; const TrimText: Boolean = True): Double; overload;

function Encode(const Text: string; const MultiLine: Boolean = False;
  const CharSet: TSysCharSet = []): string;
function Decode(const Text: string; const CharSet: TSysCharSet = []): string;

function CreateGuid(Guid: {$IFDEF FPC}System.{$ENDIF}PGuid = nil): string;
function UniqueName: string;

{$IFNDEF FPC}
function GetTextHeight(const Text: string; Rect: TRect; const FontHandle: THandle): Integer;
function GetTextSize(const Text: string; const FontHandle: THandle): TSize;
{$ENDIF}

function CreateString(const S: string): PChar;
procedure DeleteString(var S: PChar);
function CreateAnsiString(const S: AnsiString): PAnsiChar;
procedure DeleteAnsiString(var S: PAnsiChar);

const
  CP1251 = 1251;
  {$IFDEF UNICODE}
  DigitCount = 4;
  {$ELSE}
  DigitCount = 2;
  {$ENDIF}

var
  LockBracket: TBracket;
  LockString: string;

implementation

uses
  {$IFDEF FPC}
  StrUtils, TextBuilder;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.StrUtils, System.AnsiStrings, TextBuilder;
  {$ELSE}
  StrUtils, AnsiStrings, TextBuilder;
  {$ENDIF}
  {$ENDIF}

const
  ArrayIncrement: Integer = 64;

{$IFNDEF FPC}
const
  AnsiFlags = WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR;
  WideFlags = MB_PRECOMPOSED;

{$ENDIF}

procedure Reset(var Target: TLockArray; var Data: TArrayData); forward;
procedure Apply(var Target: TLockArray; const Data: TArrayData); forward;
function AddLock(var Target: TLockArray; var Data: TArrayData;
  const FromIndex, TillIndex: NativeInt): Integer; forward; overload;
function AddLock(var Target: TLockArray; const FromIndex, TillIndex: NativeInt): Integer; forward; overload;

function GetValueFromIndex(const Strings: TStrings; const Index: Integer): string;
begin
  if Index < 0 then
    Result := ''
  else
    Result := SubStr(Strings[Index],
      {$IFDEF DELPHI_7}Strings.NameValueSeparator{$ELSE}Equal{$ENDIF}, 1, False);
end;

procedure SetValueFromIndex(const Strings: TStrings; Index: Integer; const Value: string);
begin
  if Value <> '' then
  begin
    if Index < 0 then Index := Strings.Add('');
    Strings[Index] := Strings.Names[Index] +
      {$IFDEF DELPHI_7}Strings.NameValueSeparator{$ELSE}Equal{$ENDIF} + Value;
  end
  else if Index >= 0 then
    Strings.Delete(Index);
end;

{$IFNDEF FPC}
function WideToAnsi(const Text: WideString; Index, Count: Integer): WideString;
var
  I, J: Integer;
begin
  I := Length(Text);
  if Index < 1 then
    Index := 0
  else begin
    Dec(Index);
    if Index > I then
      Index := I;
  end;
  if Count < 0 then
    J := 0
  else begin
    J := I - Index;
    if J > Count then
      J := Count;
  end;
  SetLength(Result, J);
  if J > 0 then
    CopyMemory(Pointer(Result), PWideChar(Text) + Index, J * SizeOf(WideChar));
end;

function AnsiToWide(const Text: AnsiString; Index, Count: Integer): AnsiString;
var
  I, J: Integer;
begin
  I := Length(Text);
  if Index < 1 then
    Index := 0
  else begin
    Dec(Index);
    if Index > I then
      Index := I;
  end;
  if Count < 0 then
    J := 0
  else begin
    J := I - Index;
    if J > Count then
      J := Count;
  end;
  SetLength(Result, J);
  if J > 0 then
    CopyMemory(Pointer(Result), PAnsiChar(Text) + Index, J * SizeOf(AnsiChar));
end;

function WideToAnsi(const Source: WideString; out Target: AnsiString): Boolean;
var
  I: Integer;
begin
  I := WideCharToMultiByte(CP1251, AnsiFlags, PWideChar(Source), -1, nil, 0, nil, nil) - 1;
  Result := I > 0;
  if Result then
  begin
    SetLength(Target, I);
    WideCharToMultiByte(CP1251, AnsiFlags, PWideChar(Source), -1, PAnsiChar(Target), I, nil, nil);
  end;
end;

function WideToAnsi(const Text: WideString): AnsiString;
begin
  if not WideToAnsi(Text, Result) then Result := '';
end;

function AnsiToWide(const Source: AnsiString; out Target: WideString): Boolean;
var
  I: Integer;
begin
  I := MultiByteToWideChar(CP1251, WideFlags, PAnsiChar(Source), -1, nil, 0) - 1;
  Result := I > 0;
  if Result then
  begin
    SetLength(Target, I);
    MultiByteToWideChar(CP1251, WideFlags, PAnsiChar(Source), -1, PWideChar(Target), I);
  end;
end;

function AnsiToWide(const Text: AnsiString): WideString;
begin
  if not AnsiToWide(Text, Result) then Result := '';
end;

function WideCharToAnsiChar(const Source: WideChar; out Target: AnsiChar): Boolean;
begin
  Result := WideCharToMultiByte(CP1251, AnsiFlags, @Source, 1, @Target, SizeOf(AnsiChar), nil, nil) <> 0;
end;

function AnsiCharToWideChar(const Source: AnsiChar; out Target: WideChar): Boolean;
begin
  Result := MultiByteToWideChar(CP1251, WideFlags, @Source, SizeOf(AnsiChar), @Target, 1) <> 0;
end;

function WideCharToAnsiChar(const C: WideChar): AnsiChar;
begin
  if not WideCharToAnsiChar(C, Result) then Result := #0;
end;

function AnsiCharToWideChar(const C: AnsiChar): WideChar;
begin
  if not AnsiCharToWideChar(C, Result) then Result := #0;
end;

function OemToString(const Text: AnsiString): string;
var
  I : Integer;
begin
  I := Length(Text);
  SetLength(Result, I);
  {$IFDEF DELPHI_XE7}
  OemToCharBuffW(PAnsiChar(Text), PWideChar(Result), I);
  {$ELSE}
  OemToCharBuffA(PAnsiChar(Text), PAnsiChar(Result), I);
  {$ENDIF}
end;

function StringToOem(const Text: string): AnsiString;
var
  I: Integer;
begin
  I := Length(Text);
  SetLength(Result, I);
  {$IFDEF DELPHI_XE7}
  CharToOemBuffW(PWideChar(Text), PAnsiChar(Result), I);
  {$ELSE}
  CharToOemBuffA(PAnsiChar(Text), PAnsiChar(Result), I);
  {$ENDIF}
end;

function Utf8ToAnsi(const Source: UTF8String): AnsiString;
var
  W: WideString;
  I: Integer;
begin
  I := MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(Source), Length(Source), nil, 0);
  SetLength(W, I);
  MultiByteToWideChar(CP_UTF8, 0, PAnsiChar(Source), Length(Source), PWideChar(W), I);
  I := WideCharToMultiByte(28591, 0, PWideChar(W), Length(W), nil, 0, nil, nil);
  SetLength(Result, I);
  WideCharToMultiByte(28591, 0, PWideChar(W), Length(W), PAnsiChar(Result), I, nil, nil);
end;

{$IFDEF UNICODE}
function CharInSet(C: WideChar; const CharSet: TSysCharSet): Boolean;
var
  A: AnsiChar;
begin
  Result := (WideCharToMultiByte(CP1251, AnsiFlags, @C, 1, @A, SizeOf(AnsiChar), nil, nil) <> 0) and
    (A in CharSet);
end;
{$ELSE}
function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean;
begin
  Result := C in CharSet;
end;
{$ENDIF}

{$ENDIF}

{$IFDEF DELPHI_10.2}
function ToUTF8(const S: string): string;
begin
  Result := StringOf(TEncoding.Convert(TEncoding.ANSI, TEncoding.UTF8, BytesOf(S)));
end;

function ToANSI(const S: string): string;
begin
  Result := StringOf(TEncoding.Convert(TEncoding.UTF8, TEncoding.ANSI, BytesOf(S)));
end;
{$ENDIF}

procedure Reset(var Target: TLockArray; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(Target);
end;

procedure Apply(var Target: TLockArray; const Data: TArrayData);
begin
  SetLength(Target, Data.Index);
end;

function AddLock(var Target: TLockArray; var Data: TArrayData;
  const FromIndex, TillIndex: NativeInt): Integer; overload;
begin
  Data.Count := Length(Target);
  if Data.Index >= Data.Count then
  begin
    Data.Count := Data.Count + ArrayIncrement;
    SetLength(Target, Data.Count);
  end;
  Target[Data.Index].FromIndex := FromIndex;
  Target[Data.Index].TillIndex := TillIndex;
  Result := Data.Index;
  Inc(Data.Index);
end;

function AddLock(var Target: TLockArray; const FromIndex, TillIndex: NativeInt): Integer; overload;
begin
  Result := Length(Target);
  SetLength(Target, Result + 1);
  Target[Result].FromIndex := FromIndex;
  Target[Result].TillIndex := TillIndex;
end;

function NextBracket(const Text: string; const Bracket: TBracket; Index: NativeInt): NativeInt;
var
  I, J, K: Integer;
begin
  Result := 0;
  I := 0;
  J := 0;
  K := Length(Text);
  while Index <= K do
  begin
    if Text[Index] = Bracket[btL] then
      Inc(I)
    else
      if Text[Index] = Bracket[btR] then Inc(J);
    if (I > 0) and (I = J) then
    begin
      Result := Index;
      Break;
    end
    else
      Inc(Index);
  end;
end;

function NextBracket(const Text: string; const FlagArray: TFlagArray; const Bracket: TBracket;
  Index: NativeInt): NativeInt;
var
  I, J, K: Integer;
begin
  Result := 0;
  I := 0;
  J := 0;
  K := Length(Text);
  while Index <= K do
    if Locked(Index, FlagArray) then
      Inc(Index)
    else begin
      if Text[Index] = Bracket[btL] then
        Inc(I)
      else
        if Text[Index] = Bracket[btR] then Inc(J);
      if (I > 0) and (I = J) then
      begin
        Result := Index;
        Break;
      end
      else
        Inc(Index);
    end;
end;

function PrevBracket(const Text: string; const Bracket: TBracket; Index: NativeInt): NativeInt;
var
  I, J: Integer;
begin
  Result := 0;
  I := 0;
  J := 0;
  while Index > 0 do
  begin
    if Text[Index] = Bracket[btL] then
      Inc(I)
    else
      if Text[Index] = Bracket[btR] then Inc(J);
    if (I > 0) and (I = J) then
    begin
      Result := Index;
      Break;
    end
    else
      Dec(Index);
  end;
end;

function PrevBracket(const Text: string; const FlagArray: TFlagArray; const Bracket: TBracket;
  Index: NativeInt): NativeInt;
var
  I, J: Integer;
begin
  Result := 0;
  I := 0;
  J := 0;
  while Index > 0 do
    if Locked(Index, FlagArray) then
      Dec(Index)
    else begin
      if Text[Index] = Bracket[btL] then
        Inc(I)
      else
        if Text[Index] = Bracket[btR] then Inc(J);
      if (I > 0) and (I = J) then
      begin
        Result := Index;
        Break;
      end
      else
        Dec(Index);
    end;
end;

function GetLockArray(const Text: string; const LockBracket: TBracket): TLockArray;
var
  Data: TArrayData;
  I, J: NativeInt;
begin
  Result := nil;
  Reset(Result, Data);
  try
    I := 1;
    while I < Length(Text) do
      if Text[I] = LockBracket[btL] then
      begin
        J := NextBracket(Text, LockBracket, I);
        if J > 0 then
        begin
          AddLock(Result, Data, I, J);
          I := J;
        end
        else
          Inc(I);
      end
      else
        Inc(I);
  finally
    Apply(Result, Data);
  end;
end;

function GetLockArray(const Text: string; const FlagArray: TFlagArray;
  const BracketArray: {$IFDEF DELPHI_10.2}TArray<TBracket>{$ELSE}array of TBracket{$ENDIF}): TLockArray;
var
  Data: TArrayData;
  I, J, K: NativeInt;
  Bracket: PBracket;
begin
  Result := nil;
  Reset(Result, Data);
  try
    I := 1;
    while I < Length(Text) do
      if Assigned(FlagArray) and Locked(I, FlagArray) then
        Inc(I)
      else begin
        Bracket := nil;
        for K := Low(BracketArray) to High(BracketArray) do
          if Text[I] = BracketArray[K, btL] then
          begin
            Bracket := @BracketArray[K];
            Break;
          end;
        if Assigned(Bracket) then
        begin
          J := NextBracket(Text, Bracket^, I);
          if J > 0 then
          begin
            AddLock(Result, Data, I, J);
            I := J;
          end
          else
            Inc(I);
        end
        else
          Inc(I);
      end;
  finally
    Apply(Result, Data);
  end;
end;

function GetLockArray(const Text, Lock: string): TLockArray;
var
  I, J, K: Integer;
  Array1: TLockArray;
begin
  Result := nil;
  Array1 := nil;
  K := -1;
  for I := 1 to Length(Lock) do for J := 1 to Length(Text) do
    if (Text[J] = Lock[I]) and ((J = 1) or (Text[J - 1] <> Lock[I])) and ((J = Length(Text)) or
      (Text[J + 1] <> Lock[I])) then
        if K < 0 then
          K := J
        else begin
          AddLock(Array1, K, J);
          K := -1;
        end;
  for I := Low(Array1) to High(Array1) do
    if (Array1[I].FromIndex >= 0) and (Array1[I].TillIndex >= 0) then
      for J := I + 1 to High(Array1) do
        if (Array1[J].FromIndex >= 0) and (Array1[J].TillIndex >= 0) then
          if (Array1[I].FromIndex >= Array1[J].FromIndex) and
            (Array1[I].TillIndex <= Array1[J].TillIndex) then
            begin
              Array1[I].FromIndex := -1;
              Array1[I].TillIndex := -1;
            end
            else
              if (Array1[J].FromIndex >= Array1[I].FromIndex) and
                (Array1[J].TillIndex <= Array1[I].TillIndex) then
                begin
                  Array1[J].FromIndex := -1;
                  Array1[J].TillIndex := -1;
                end;
  SetLength(Result, Length(Array1));
  J := 0;
  for I := Low(Array1) to High(Array1) do
    if (Array1[I].FromIndex >= 0) and (Array1[I].TillIndex >= 0) then
    begin
      Result[J] := Array1[I];
      Inc(J);
    end;
  SetLength(Result, J);
end;

function GetFlagArray(const Text: string; const LockBracket: TBracket): TFlagArray;
var
  LockArray: TLockArray;
begin
  LockArray := GetLockArray(Text, LockBracket);
  try
    Result := GetFlagArray(Text, LockArray);
  finally
    LockArray := nil;
  end;
end;

function GetFlagArray(const Text, Lock: string): TFlagArray;
var
  LockArray: TLockArray;
begin
  LockArray := GetLockArray(Text, Lock);
  try
    Result := GetFlagArray(Text, LockArray);
  finally
    LockArray := nil;
  end;
end;

function GetFlagArray(const Text: string; const LockArray: TLockArray): TFlagArray;
var
  I, J: Integer;
begin
  Resize(Result, Length(Text));
  for I := Low(LockArray) to High(LockArray) do
    for J := LockArray[I].FromIndex to LockArray[I].TillIndex do Result[J - 1] := Ord(True);
end;

function GetFlagArray(const Text: string; const LockType: TLockType): TFlagArray;
begin
  case LockType of
    ltBracket: Result := GetFlagArray(Text, LockBracket);
    ltChar: Result := GetFlagArray(Text, LockString);
  end;
end;

function UnionFlagArray(const FlagArray: {$IFDEF DELPHI_10.2}TArray<TFlagArray>{$ELSE}array of TFlagArray{$ENDIF}): TFlagArray;
var
  I, J, K: Integer;
begin
  J := 0;
  for I := Low(FlagArray) to High(FlagArray) do
  begin
    K := Length(FlagArray[I]);
    if J < K then J := K;
  end;
  SetLength(Result, J);
  for I := Low(Result) to High(Result) do for J := Low(FlagArray) to High(FlagArray) do
  begin
    K := Length(FlagArray[J]);
    if (I < K) and Boolean(FlagArray[J, I]) then Result[I] := Ord(True);
  end;
end;

function LockCompare(const Target, Value: Pointer; const Index: Integer;
  const Data: Pointer): TValueRelationship;
var
  LockArray: TLockArray absolute Target;
  Lock: TLock;
begin
  Lock := LockArray[Index];
  if (PInteger(Value)^ >= Lock.FromIndex) and (PInteger(Value)^ <= Lock.TillIndex) then
    Result := EqualsValue
  else
    if PInteger(Value)^ < Lock.FromIndex then
      Result := LessThanValue
    else
      Result := GreaterThanValue;
end;

function LockSearch(const Target: TLockArray; const Index: Integer): Integer;
begin
  Result := BSearch(Target, Low(Target), High(Target), LockCompare, @Index);
end;

function Locked(const Index: NativeInt; const LockArray: TLockArray;
  const FromIndex, TillIndex: PNativeInt): Boolean;
var
  I: Integer;
begin
  I := LockSearch(LockArray, Index);
  Result := I >= 0;
  if Result then
  begin
    if Assigned(FromIndex) then
      FromIndex^ := LockArray[I].FromIndex - 1;
    if Assigned(TillIndex) then
      TillIndex^ := LockArray[I].TillIndex + 1;
  end;
end;

function Locked(const Index: NativeInt; const FlagArray: TFlagArray): Boolean;
begin
  Result := (Index < 1) or (Index > Length(FlagArray)) or Boolean(FlagArray[Index - 1]);
end;

function TextCopy(const Target: PChar; const Size: Integer; const Source: string): Integer;
begin
  Result := Length(Source);
  if Result > Size - 1 then Result := Size - 1;
  StrLCopy(Target, PChar(Source), Result);
end;

function CompareText(const AText, BText: PChar; const ASize, BSize: Integer;
  const IgnoreCase: Boolean): Integer;
begin
  if IgnoreCase then
    if ASize < BSize then
      Result := AnsiStrLIComp(AText, BText, ASize)
    else
      Result := AnsiStrLIComp(AText, BText, BSize)
  else
    if ASize < BSize then
      Result := AnsiStrLComp(AText, BText, ASize)
    else
      Result := AnsiStrLComp(AText, BText, BSize);
end;

function SameText(const AText, BText: PChar; const Size: Integer; const IgnoreCase: Boolean): Boolean;
var
  I, J: Integer;
begin
  if Size > 0 then
    I := Size
  else begin
    I := StrLen(AText);
    J := StrLen(BText);
    if I > J then I := J;
  end;
  Result := CompareText(AText, BText, I, I, IgnoreCase) = 0;
end;

function Same(const AText, BText: PChar; const Size: Integer; const IgnoreCase: Boolean): Boolean;
begin
  Result := SameText(AText, BText, Size, IgnoreCase);
end;

function SameText(const AText, BText: string; const IgnoreCase: Boolean): Boolean;
var
  I, J: Integer;
begin
  I := Length(AText);
  J := Length(BText);
  Result := (I = J) and (SameText(PChar(AText), PChar(BText), I, IgnoreCase));
end;

function Same(const AText, BText: string; const IgnoreCase: Boolean): Boolean;
begin
  Result := SameText(AText, BText, IgnoreCase);
end;

function Consists(const Text: string; const CharSet: TSysCharSet): Boolean;
var
  I: Integer;
begin
  Result := Text <> '';
  if Result then
  begin
    for I := 1 to Length(Text) do
      if not CharInSet(Text[I], CharSet) then
      begin
        Result := False;
        Exit;
      end;
    Result := True;
  end;
end;

function Contains(const Text, SubStr: string;
  const Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF}; const IgnoreCase: Boolean;
  const Direction: Integer): Boolean;
var
  P: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
begin
  if Assigned(Prefix) then
    P := Prefix
  else
    P := GetPrefix(SubStr, IgnoreCase, Direction);
  try
    Result := IndexOf(Text, SubStr, P, IgnoreCase, 1, Direction) <> 0;
  finally
    P := nil;
  end;
end;

function TrimText(var Text: string; const Count: Integer; const Kind: TTrimKind;
  const Trim: Boolean): Boolean;
begin
  Result := Count <= Length(Text);
  if Result then
    case Kind of
      tkL:
        if Trim then
          Text := TrimText(Copy(Text, Count + 1, Length(Text) - Count), Kind)
        else
          Text := Copy(Text, Count + 1, Length(Text) - Count);
      tkR:
        if Trim then
          Text := TrimText(Copy(Text, 1, Length(Text) - Count), Kind)
        else
          Text := Copy(Text, 1, Length(Text) - Count);
      tkLR:
        begin
          if Trim then
            Text := TrimText(Copy(Text, Count + 1, Length(Text) - Count), Kind)
          else
            Text := Copy(Text, Count + 1, Length(Text) - Count);
        end;
    end;
end;

function TrimText(const Text: string; const Kind: TTrimKind; const CharSet: TSysCharSet): string;
var
  I, J: Integer;
begin
  case Kind of
    tkL:
      begin
        I := 1;
        J := Length(Text);
        while (I <= J) and CharInSet(Text[I], CharSet) do Inc(I);
        Result := Copy(Text, I, MaxInt);
      end;
    tkR:
      begin
        I := Length(Text);
        while (I > 0) and CharInSet(Text[I], CharSet) do Dec(I);
        Result := Copy(Text, 1, I);
      end;
    tkLR:
      begin
        I := 1;
        J := Length(Text);
        while (I <= J) and CharInSet(Text[I], CharSet) do Inc(I);
        if I > J then
          Result := ''
        else begin
          while (J > 0) and CharInSet(Text[J], CharSet) do Dec(J);
          Result := Copy(Text, I, J - I + 1);
        end;
      end;
  end;
end;

function DeletePrefix(var Text: string; const Prefix: string; const Trim, IgnoreCase: Boolean): Boolean;
var
  I: Integer;
begin
  I := Length(Prefix);
  Result := (I <= Length(Text)) and (CompareText(PChar(Text), PChar(Prefix), I, I, IgnoreCase) = 0) and
    TrimText(Text, I, tkL, Trim);
end;

function GetPrefix(const Text: string; const IgnoreCase: Boolean;
  const Direction: Integer): {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
var
  A, B, I, J: Integer;
begin
  A := Length(Text);
  Resize(Result, A);
  if Direction < 0 then
    B := A - 1
  else
    B := 0;
  for I := 1 to A - 1 do
  begin
    J := Result[I - 1];
    while (J > 0) and (CompareText(PChar(Text) + Abs(I - B), PChar(Text) + Abs(J - B), 1, 1, IgnoreCase) <> 0) do
      J := Result[J - 1];
    if CompareText(PChar(Text) + Abs(I - B), PChar(Text) + Abs(J - B), 1, 1, IgnoreCase) = 0 then
      Inc(J);
    Result[I] := J;
  end;
end;

function KMPSearch(const Text, SubStr: string;
  const Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF}; const Offset: Integer;
  const Event: TKMPEvent; const P: Pointer; const IgnoreCase: Boolean; const Direction: Integer): Integer;
var
  A, B, C, D, I, J, K: Integer;
begin
  Result := 0;
  A := Length(Text);
  B := Length(SubStr);
  if B = 0 then Exit;
  if A < B then Exit;
  if Direction < 0 then
  begin
    C := A - 1;
    D := B - 1;
  end
  else begin
    C := 0;
    D := 0;
  end;
  I := Offset - 1;
  J := 0;
  while I < A do
    case CompareText(PChar(Text) + Abs(I - C), PChar(SubStr) + Abs(J - D), 1, 1, IgnoreCase) of
      0:
        begin
          Inc(I);
          Inc(J);
          if J = B then
          begin
            if Direction < 0 then
              K := Abs(I - C - 1) + 1
            else
              K := Abs(I - J + 1);
            if not Assigned(Event) or not Event(K, P) then
            begin
              Result := K;
              Exit;
            end;
            J := Prefix[J - 1];
          end
        end;
    else
      if J = 0 then
        Inc(I)
      else
        J := Prefix[J - 1];
    end;
end;

function IndexOf(const Text, SubStr: string;
  const Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF}; const IgnoreCase: Boolean;
  const Offset, Direction: Integer; const FlagArray: TFlagArray): Integer;
var
  A, B: Integer;
begin
  A := Offset;
  B := Length(SubStr);
  while True do
  begin
    Result := KMPSearch(Text, SubStr, Prefix, A, nil, nil, IgnoreCase, Direction);
    if (FlagArray = nil) or (Result = 0) or not Locked(Result, FlagArray) then Break;
    if Direction < 0 then
      A := Result - B
    else
      A := Result + B;
  end;
end;

function IndexOf(const Text, SubStr: string; const IgnoreCase: Boolean; const Offset, Direction: Integer;
  const FlagArray: TFlagArray): Integer;
var
  Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
begin
  Prefix := GetPrefix(Text, IgnoreCase, Direction);
  try
    Result := IndexOf(Text, SubStr, Prefix, IgnoreCase, Offset, Direction, FlagArray);
  finally
    Prefix := nil;
  end;
end;

function IndexOf(const Text, Delimiter, SubStr: string; const IgnoreCase: Boolean;
  const Direction: Integer): Integer;
var
  I, J, K, L: Integer;
begin
  if SubStr <> '' then
  begin
    if Direction < 0 then
    begin
      I := -1;
      L := -1;
    end
    else begin
      I := 0;
      L := 1;
    end;
    while FindSubStr(Text, Delimiter, I, IgnoreCase, J, K) do
    begin
      if SameText(Copy(Text, J, K - J), SubStr, IgnoreCase) then
      begin
        Result := I;
        Exit;
      end;
      Inc(I, L);
    end;
  end;
  Result := -1;
end;

function Extract(const Text, Delimiter: string; const Index: Integer; const IgnoreCase: Boolean): string;
begin
  Result := SubStr(Text, Delimiter, Index, IgnoreCase);
  if (Result = '') and ((Index = 0) and not AnsiStartsText(Delimiter, Text) or (Index = -1) and
    not AnsiEndsText(Delimiter, Text)) then
      Result := Text;
end;

function FindSubStr(const Text, Delimiter: string; const Index: Integer; const IgnoreCase: Boolean;
  out FromIndex, TillIndex: Integer): Boolean;
var
  A, B, I, J, K: Integer;
  Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
begin
  A := Length(Text);
  B := Length(Delimiter);
  J := 0;
  K := 0;
  Prefix := GetPrefix(Delimiter, IgnoreCase);
  try
    if Index < 0 then
      for I := 0 to Abs(Index + 1) do
      begin
        J := K;
        if I > 0 then
        begin
          if K = 0 then Break;
          K := IndexOf(Text, Delimiter, Prefix, IgnoreCase, A + B - K + 1, -1)
        end
        else
          K := IndexOf(Text, Delimiter, Prefix, IgnoreCase, 1, -1);
      end
    else
      for I := 0 to Index do
      begin
        K := J;
        if I > 0 then
        begin
          if J = 0 then Break;
          J := IndexOf(Text, Delimiter, Prefix, IgnoreCase, J + B)
        end
        else
          J := IndexOf(Text, Delimiter, Prefix, IgnoreCase);
      end;
  finally
    Prefix := nil;
  end;
  Result := (J > 0) or (K > 0);
  if Result then
  begin
    if K > 0 then
      FromIndex := K + B
    else
      FromIndex := 1;
    if J = 0 then
      TillIndex := A + 1
    else
      TillIndex := J;
  end;
end;

function SubStr(const Text, Delimiter: string; const Index: Integer; const IgnoreCase: Boolean): string;
var
  I, J: Integer;
begin
  if FindSubStr(Text, Delimiter, Index, IgnoreCase, I, J) then
    Result := Copy(Text, I, J - I)
  else
    Result := '';
end;

function SubStr(const Text, Delimiter: string; const FromIndex, TillIndex: Integer;
  const IgnoreCase: Boolean): string;
var
  A, B, C, D: Integer;
begin
  if FindSubStr(Text, Delimiter, FromIndex, IgnoreCase, A, B) and FindSubStr(Text, Delimiter, TillIndex, IgnoreCase, C, D) then
    if A < D then
      Result := Copy(Text, A, D - A)
    else
      Result := Copy(Text, C, B - C)
  else
    Result := '';
end;

function SubStrCnt(const Text, SubStr: string; const IgnoreCase: Boolean): Integer;
var
  A, I: Integer;
  Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
begin
  Result := 0;
  if SubStr <> '' then
  begin
    A := Length(SubStr);
    Prefix := GetPrefix(SubStr, IgnoreCase);
    try
      I := IndexOf(Text, SubStr, Prefix, IgnoreCase);
      while I > 0 do
      begin
        Inc(Result);
        I := IndexOf(Text, SubStr, Prefix, IgnoreCase, I + A);
      end;
    finally
      Prefix := nil;
    end;
  end;
end;

function Split(const Text, Delimiter: string;
  var SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF}; const IgnoreCase: Boolean;
  const MaxCount: Integer; const FlagArray: TFlagArray): Boolean;
var
  A, I, J: Integer;
  Prefix: {$IFDEF DELPHI_10.2}TArray<Integer>{$ELSE}TIntegerDynArray{$ENDIF};
  S: string;
begin
  Result := (MaxCount <= 0) or (Length(SArray) < MaxCount);
  if Result then
  begin
    J := 1;
    A := Length(Delimiter);
    Prefix := GetPrefix(Delimiter, IgnoreCase);
    try
      repeat
        I := IndexOf(Text, Delimiter, Prefix, True, J, 1, FlagArray);
        if I > 0 then
        begin
          S := Copy(Text, J, I - J);
          J := I + A;
        end
        else
          S := Copy(Text, J, MaxInt);
        Add(SArray, S);
        if (MaxCount > 0) and (Length(SArray) >= MaxCount) then Break;
      until I = 0;
    finally
      Prefix := nil;
    end;
  end;
end;

function Duplicated(const Text: string; Index: Integer): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(Text) do
    if (I <> Index) and (Text[I] = Text[Index]) then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

function EmptyArray(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF}): Boolean;
var
  I: Integer;
begin
  for I := Low(SArray) to High(SArray) do
    if Trim(SArray[I]) <> '' then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const TrimText: Boolean): string;
begin
  if Index < Length(SArray) then
    if TrimText then
      Result := Trim(SArray[Index])
    else
      Result := SArray[Index]
  else
    Result := '';
end;

function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index, Default: Integer; const TrimText: Boolean): Integer;
begin
  Result := StrToIntDef(ArrayValue(SArray, Index, TrimText), Default);
end;

function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const Default: Single; const TrimText: Boolean): Single;
begin
  Result := StrToFloatDef(ArrayValue(SArray, Index, TrimText), Default);
end;

function ArrayValue(const SArray: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const Index: Integer; const Default: Double; const TrimText: Boolean): Double;
begin
  Result := StrToFloatDef(ArrayValue(SArray, Index, TrimText), Default);
end;

function Encode(const Text: string; const MultiLine: Boolean; const CharSet: TSysCharSet): string;
var
  B: TTextBuilder;
  I: Integer;
begin
  B := TTextBuilder.Create;
  try
    for I := 1 to Length(Text) do
      if MultiLine and CharInSet(Text[I], Breaks) or (CharSet <> []) and not CharInSet(Text[I], CharSet) then
        B.Append(Text[I])
      else
        B.Append(Percent + IntToHex(Ord(Text[I]), DigitCount));
    Result := B.Text;
  finally
    B.Free;
  end;
end;

function Decode(const Text: string; const CharSet: TSysCharSet): string;
var
  B: TTextBuilder;
  I, J: Integer;
begin
  B := TTextBuilder.Create;
  try
    I := 1;
    while I <= Length(Text) do
    begin
      if (Text[I] = Percent) and TryStrToInt(Dollar + Copy(Text, I + 1, DigitCount), J) and
        ((CharSet = []) or CharInSet(Chr(J), CharSet)) then
        begin
          B.Append(Chr(J));
          Inc(I, DigitCount + 1);
        end
        else begin
          B.Append(Text[I]);
          Inc(I);
        end;
    end;
    Result := B.Text;
  finally
    B.Free;
  end;
end;

function CreateGuid(Guid: {$IFDEF FPC}System.{$ENDIF}PGuid): string;
var
  G: TGuid;
begin
  if not Assigned(Guid) then Guid := @G;
  if {$IFDEF DELPHI_XE7}System.SysUtils.CreateGuid(Guid^){$ELSE}SysUtils.CreateGuid(Guid^){$ENDIF} = S_OK then
    Result := GuidToString(Guid^)
  else
    Result := '';
end;

function UniqueName: string;
const
  Template = '%.8x%.4x%.4x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x';
  Size = 32;
var
  G: TGuid;
begin
  if {$IFDEF DELPHI_XE7}System.SysUtils.CreateGuid(G){$ELSE}SysUtils.CreateGuid(G){$ENDIF} = S_OK then
  begin
    SetLength(Result, Size);
    StrLFmt(PChar(Result), Size, Template,
      [G.D1, G.D2, G.D3, G.D4[0], G.D4[1], G.D4[2], G.D4[3], G.D4[4], G.D4[5], G.D4[6], G.D4[7]]);
  end
  else
    raise Exception.Create('Cannot create unique name');
end;

{$IFNDEF FPC}
function GetTextHeight(const Text: string; Rect: TRect; const FontHandle: THandle): Integer;
var
  Handle: THandle;
  DC: HDC;
begin
  DC := GetDC(0);
  try
    Handle := SelectObject(DC, FontHandle);
    try
      Result := DrawText(DC, PChar(Text), Length(Text), Rect,
        DT_LEFT or DT_WORDBREAK or DT_EXPANDTABS or DT_NOPREFIX or DT_CALCRECT);
    finally
      SelectObject(DC, Handle);
    end;
  finally
    ReleaseDC(0, DC);
  end;
end;

function GetTextSize(const Text: string; const FontHandle: THandle): TSize;
var
  Handle: THandle;
  DC: HDC;
begin
  DC := GetDC(0);
  try
    Handle := SelectObject(DC, FontHandle);
    try
      GetTextExtentPoint(DC, PChar(Text), Length(Text), Result);
    finally
      SelectObject(DC, Handle);
    end;
  finally
    ReleaseDC(0, DC);
  end;
end;
{$ENDIF}

function CreateString(const S: string): PChar;
begin
  Result := StrNew(PChar(S));
end;

procedure DeleteString(var S: PChar);
begin
  StrDispose(S);
end;

function CreateAnsiString(const S: AnsiString): PAnsiChar;
begin
  {$IFDEF DELPHI_XE7}
  Result := System.AnsiStrings.StrNew(PAnsiChar(S));
  {$ELSE}
  Result := StrNew(PAnsiChar(S));
  {$ENDIF}
end;

procedure DeleteAnsiString(var S: PAnsiChar);
begin
  {$IFDEF DELPHI_XE7}
  System.AnsiStrings.StrDispose(S);
  {$ELSE}
  StrDispose(S);
  {$ENDIF}
end;

initialization
  LockBracket := LParenthesis + RParenthesis;
  LockString := DoubleQuote;

end.
