{ ************************************************************************** }
{                                                                            }
{ ExtendedProbe                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
{ What Extended actually is on each build.

  The type is declared everywhere, but its size and precision depend on the
  target. That is what makes both the TValue layout and the last bit of a
  result differ between builds. }
program ExtendedProbe;

{$APPTYPE CONSOLE}
{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  SysUtils;

var
  A, B, S: Extended;
  D: Double;
  Bits: Int64 absolute D;
begin
  Write('compiler ', {$IFDEF FPC}'fpc'{$ELSE}'delphi'{$ENDIF}, ', target ',
    {$IFDEF WIN64}'win64'{$ELSE}{$IFDEF WIN32}'win32'{$ELSE}'linux64'{$ENDIF}{$ENDIF});
  Write(': SizeOf(Extended)=', SizeOf(Extended));
  Write(' SizeOf(Double)=', SizeOf(Double));
  {$IFDEF FPC}
  Write(' FPC_HAS_TYPE_EXTENDED=', {$IFDEF FPC_HAS_TYPE_EXTENDED}'yes'{$ELSE}'no'{$ENDIF});
  {$ENDIF}
  Writeln(' Extended digits=', Length(FloatToStr(Extended(1) / 3)) - 2);

  { the same addition that diverges: through Extended first, then straight in Double }
  A := 0.1;
  B := 0.2;
  S := A + B;
  D := S;
  Write('  0.1+0.2 through Extended: ', IntToHex(Bits, 16));
  D := Double(0.1) + Double(0.2);
  Writeln('   straight in Double: ', IntToHex(Bits, 16));
end.
