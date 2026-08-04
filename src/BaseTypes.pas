{ ************************************************************************** }
{                                                                            }
{ BaseTypes                                                                  }
{                                                                            }
{ Copyright © 2024 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit BaseTypes;

{$B-}
{$I Directives.inc}

interface

{$IFDEF DELPHI_12}
type
  {$IFDEF X32}
  NativeInt = type Integer;
  NativeUInt = type LongWord;
  {$ELSE}
  NativeInt = type Int64;
  NativeUInt = type UInt64;
  {$ENDIF}
{$ENDIF}

implementation

end.
