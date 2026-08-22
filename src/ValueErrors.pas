{ ************************************************************************** }
{                                                                            }
{ ValueErrors                                                                }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ValueErrors;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils;

type
  EValueError = class(Exception);

const
  UnknownTypeError = 'Unknown value type';

function Error(const Message: string): Exception; overload;
function Error(const Message: string; const Arguments: array of const): Exception; overload;

implementation

function Error(const Message: string): Exception;
begin
  Result := Error(Message, []);
end;

function Error(const Message: string; const Arguments: array of const): Exception;
begin
  Result := EValueError.CreateFmt(Message, Arguments);
end;

end.
