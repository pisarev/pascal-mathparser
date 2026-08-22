{ ************************************************************************** }
{                                                                            }
{ ParseValidator                                                             }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseValidator;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Types, ParseErrors, ParseTypes, TextConsts;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils, System.Types, ParseErrors, ParseTypes, TextConsts;
  {$ELSE}
  SysUtils, Types, ParseErrors, ParseTypes, TextConsts;
  {$ENDIF}
  {$ENDIF}

type
  TReserveType = (rtName, rtText);

  EValidatorError = class(Exception);

  TValidator = class
  protected
    function Error(const Message: string): Exception; overload; virtual;
    function Error(const Message: string; const Arguments: array of const): Exception; overload; virtual;
  public
    function Check(const AText: string; const AType: TReserveType): TError; virtual;
  end;

var
  Validator: TValidator;
  Reserve: array[TReserveType] of string;

implementation

uses
  {$IFDEF FPC}
  MemoryUtils, NumberUtils, ParseConsts, ParseUtils, TextTypes, TextUtils;
  {$ELSE}
  MemoryUtils, NumberUtils, ParseConsts, ParseUtils, TextTypes, TextUtils;
  {$ENDIF}

function NumberName(const AText: string): Boolean;
var
  I: Integer;
  Digits: TSysCharSet;
begin
  if Length(AText) < 2 then Exit(False);
  case AText[1] of
    'E', 'e': Digits := ['0'..'9'];
    'X', 'x', '$': Digits := ['0'..'9', 'A'..'F', 'a'..'f'];
    '&': Digits := ['0'..'7'];
    '%': Digits := ['0'..'1'];
  else
    Exit(False);
  end;
  for I := 2 to Length(AText) do
    if not CharInSet(AText[I], Digits) then Exit(False);
  Result := True;
end;

{$WARNINGS OFF}
function TValidator.Check(const AText: string; const AType: TReserveType): TError;
var
  LockArray: TLockArray;
  I: Integer;
begin
  if AType = rtText then LockArray := GetLockArray(AText, LockText);
  try
    for I := 1 to Length(AText) do
      if ((AType <> rtText) or not Locked(I, LockArray)) and Contains(Reserve[AType], AText[I]) then
      begin
        Result := MakeError(etReserveError, EText(ReserveError, [AText, AText[I]]));
        Exit;
      end;
  finally
    LockArray := nil;
  end;
  if (AType = rtName) and (Length(AText) > 0) and IsNumber(AText[1]) then
    Result := MakeError(etDefinitionError, EText(DefinitionError, [AText]))
  else if (AType = rtName) and NumberName(AText) then
    Result := MakeError(etNumberNameError, EText(NumberNameError, [AText]))
  else
    FillChar(Result, SizeOf(TError), 0);
end;
{$WARNINGS ON}

function TValidator.Error(const Message: string): Exception;
begin
  Result := Error(Message, []);
end;

function TValidator.Error(const Message: string; const Arguments: array of const): Exception;
begin
  Result := EValidatorError.CreateFmt(Message, Arguments);
end;

initialization
  Validator := TValidator.Create;
  Reserve[rtName] := LBrace + RBrace + LParenthesis + RParenthesis + LBracket + RBracket + Comma +
    {$IFDEF DELPHI_XE}FormatSettings.DecimalSeparator{$ELSE}DecimalSeparator{$ENDIF} + DoubleQuote +
    Minus + Plus + TextConsts.Quote + Semicolon + Space;
  Reserve[rtText] := LBrace + RBrace + TextConsts.Quote;

finalization
  Validator.Free;

end.
