{ ************************************************************************** }
{                                                                            }
{ ScriptFormat                                                               }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ScriptFormat;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils;

var
  ParseFormat: TFormatSettings;

implementation

initialization
  ParseFormat := FormatSettings;
  ParseFormat.DecimalSeparator := '.';
  ParseFormat.ThousandSeparator := #0;
end.
