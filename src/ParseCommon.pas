{ ************************************************************************** }
{                                                                            }
{ ParseCommon                                                                }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseCommon;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, ParseTypes, TextConsts, ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.Classes, ParseTypes, TextConsts, ValueTypes;
  {$ELSE}
  Classes, ParseTypes, TextConsts, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  TCommonItemType = (itUnknown, itNumber, itScript);
  PCommonItem = ^TCommonItem;
  TCommonItem = record
    ItemType: TCommonItemType;
    Value: TValue;
    Script: TScript;
  end;

const
  Lock = Exclamation;

function IndexOf(const Strings: TStrings; const Text: string; const ByName: Boolean;
  ItemName: PString = nil): Integer;
function Find(const Strings: TStrings; const Text: string; const ByName: Boolean; out Index: Integer;
  ItemName: PString = nil): Boolean;
procedure AssignValue(var Item: TCommonItem; const AValue: TValue);

implementation

uses
  {$IFDEF FPC}
  SysUtils, StrUtils, TextUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils, System.StrUtils, TextUtils;
  {$ELSE}
  SysUtils, StrUtils, TextUtils;
  {$ENDIF}
  {$ENDIF}

function IndexOf(const Strings: TStrings; const Text: string; const ByName: Boolean;
  ItemName: PString): Integer;
var
  S: string;
begin
  if not Assigned(ItemName) then ItemName := @S;
  ItemName^ := Trim(Text);
  if AnsiStartsText(Lock, ItemName^) then
    System.Delete(ItemName^, 1, Length(Lock));
  if ByName then
    Result := Strings.IndexOfName(ItemName^)
  else
    Result := Strings.IndexOf(ItemName^);
end;

function Find(const Strings: TStrings; const Text: string; const ByName: Boolean; out Index: Integer;
  ItemName: PString): Boolean;
begin
  Index := IndexOf(Strings, Text, ByName, ItemName);
  Result := Index >= 0;
end;

procedure AssignValue(var Item: TCommonItem; const AValue: TValue);
begin
  FillChar(Item, SizeOf(TCommonItem), 0);
  with Item do
  begin
    ItemType := itNumber;
    Value := AValue;
  end;
end;

end.
