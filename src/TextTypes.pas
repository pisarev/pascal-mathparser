{ ************************************************************************** }
{                                                                            }
{ TextTypes                                                                  }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit TextTypes;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Types;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.Types;
  {$ELSE}
  Types;
  {$ENDIF}
  {$ENDIF}

const
  StringLength = 4096;

type
  TString = array[0..StringLength - 1] of Char;

  TTextAlign = (taLeft, taCenter, taRight);

  TLockType = (ltBracket, ltChar);
  TLock = record
    FromIndex, TillIndex: NativeInt;
  end;
  TLockArray = {$IFDEF DELPHI_10.2}TArray<TLock>{$ELSE}array of TLock{$ENDIF};

  TFlagArray = {$IFDEF DELPHI_10.2}TArray<Byte>{$ELSE}TByteDynArray{$ENDIF};

  TBracketType = (btL, btR);
  PBracket = ^TBracket;
  TBracket = array[TBracketType] of Char;

function MakeString(const S: string): TString;

implementation

uses
  {$IFDEF FPC}
  SysUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils;
  {$ELSE}
  SysUtils;
  {$ENDIF}
  {$ENDIF}

function MakeString(const S: string): TString;
begin
  FillChar(Result, SizeOf(TString), 0);
  StrLCopy(Result, PChar(S), High(TString));
end;
end.
