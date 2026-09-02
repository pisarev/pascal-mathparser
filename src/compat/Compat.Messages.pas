{ ************************************************************************** }
{                                                                            }
{ Compat.Messages - a stand-in for console builds outside Windows            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit Compat.Messages;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

const
  WM_USER = $0400;

type
  TMessage = record
    Msg: Cardinal;
    WParam: NativeInt;
    LParam: NativeInt;
    Result: NativeInt;
  end;

implementation

end.
