{ ************************************************************************** }
{                                                                            }
{ PlatformTextTest                                                           }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program PlatformTextTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, TestKit in 'TestKit.pas';

{
  What this file guards.

  Two traps that are visible only on a second platform. Both were measured on
  21.08.2026, on the first run under Linux, and both went red where there was
  nothing wrong with the thing under test.

  THE FIRST: a string is not equal to itself. The files of this tree carry a
  UTF-8 BOM, so FPC gives literals code page 65001. On Unix
  DefaultSystemCodePage stays zero until the uses clause names cwstring, and
  then one and the same string compares unequal to itself:

    Note := 'caught outside';
    Length(Note)              = 29    UTF-8 bytes
    Length('caught outside')  = 15    the same literal
    Note = 'caught outside'   = FALSE

  ExitRoutingTest failed on that in its E6 section - while the routing of Exit
  had nothing to do with it. With cwstring in the uses clause: TRUE.

  THE SECOND: Double(X) where X is Extended is a hard cast rather than a
  conversion of the value. On Win64 it passes, because there Extended is
  Double. On Linux x86-64 Extended is eighty bits and the compiler refuses:
  Illegal type conversion. ConstantsTest would not build at all because of it,
  and so checked nothing.

  Both traps are pinned here by checks that go red on the platform where the
  trap lives, and green once the cure is in place. On Windows they are always
  green: the condition does not arise there, and that is said out loud rather
  than passed off as a check.
}

const
  Sample = 'caught outside';

{ A literal arriving as an argument: one more way it reaches a comparison. }
function Same(const Text: string): Boolean;
begin
  Result := Text = 'caught outside';
end;

{ A conversion of the value rather than a replay of the bits. A hard cast here
  would refuse to build on Linux, so the check lives in the code itself rather
  than in a comment. }
function AsDoubleValue(const Value: Extended): Double;
begin
  Result := Value;
end;

var
  Note, Copy1: string;
  Wide: Extended;
  Narrow: Double;
begin
  BeginSection('a string equals itself');
  {
    The lengths are deliberately NOT compared with each other: Length of a
    variable counts bytes, while Length of a literal is taken by the compiler at
    build time and counts characters. They differ on Windows too, where nothing
    is wrong. The subject of the check is the comparison; the numbers go with it
    as an explanation, so that a refusal shows its cause.
  }
  Note := Sample;
  Check('a variable equals a literal', Note = 'caught outside',
    Format('length of the variable %d, length of the literal %d',
      [Length(Note), Length('caught outside')]));
  Check('a variable equals a named constant', Note = Sample, '');
  Check('a literal equals a named constant', 'caught outside' = Sample, '');
  Check('a comparison inside a call', Same(Note), '');
  Check('a literal compared inside a call', Same('caught outside'), '');
  Copy1 := Copy(Note, 1, Length(Note));
  Check('a copy equals the original', Copy1 = Note, '');
  Check('a substring search finds it', Pos('outside', Note) > 0,
    Format('position %d', [Pos('outside', Note)]));
  BeginSection('converting Extended to Double');
  {
    The number is chosen so that the difference between platforms shows: on
    Linux Extended has more digits than Double, and the conversion is obliged to
    ROUND rather than replay the bits. A hard cast would give either rubbish or
    a refusal to build.
  }
  Wide := 1 / 3;
  Narrow := AsDoubleValue(Wide);
  CheckDouble('the value survived', Narrow, 1 / 3, 1E-15);
  Narrow := Wide;
  CheckDouble('and with a plain assignment too', Narrow, 1 / 3, 1E-15);
  Check('Format receives a number, not rubbish',
    Pos('0,333', Format('%.3f', [Narrow])) + Pos('0.333', Format('%.3f', [Narrow])) > 0,
    Format('%.3f', [Narrow]));
  Halt(TestSummary);
end.
