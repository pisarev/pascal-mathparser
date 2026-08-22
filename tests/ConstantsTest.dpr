{ ************************************************************************** }
{                                                                            }
{ ConstantsTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ConstantsTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, TestKit in 'TestKit.pas';

{
  What this file guards.

  The numbers a person would otherwise type by hand: Pi and the base of the
  natural logarithm. The occasion was issue #5 from bms-2015: a formula had
  2.718281828^(2*x) in it, because there was nowhere to take e from. A
  hand-typed number loses precision exactly where it matters most - in an
  exponent - and gives a curve that looks like the right one and is not. That
  divergence is what gets measured here.

  What is checked is a contract, not a table of values: Ln(Exp(1)) = 1,
  4*ArcTan(1) = Pi. Statements like that hold on any compiler and catch a
  substituted formula.

  WHY THERE IS NO CONSTANT E. It was added on 20.08.2026 and taken back out
  the same day: the parser stopped reading 1E3 as a thousand. The name E was
  caught before the number, and any record with an exponent broke - silently
  and everywhere. The measurement before and after stands in its own section
  below; until a number and a name are told apart inside the parser itself,
  there will be no constant E. Write e as Exp(1).
}

var
  P: TMathParser;

function Value(const Text: string): Extended;
begin
  Result := P.AsDouble(Text);
end;

{ Whether the expression parses at all. A refusal here is a lawful answer, not
  a breakage. }
function Reads(const Text: string): Boolean;
begin
  Result := True;
  try
    P.AsDouble(Text);
  except
    on E: Exception do Result := False;
  end;
end;

{
  An expression on a parser where THIS name is registered. Its own instance:
  the name the check is here for is not registered on the shared parser.
}
procedure WithName(const AName: string; const AValue: Double; const Text: string;
  const Want: Extended);
var
  Q: TMathParser;
  Variable: Double;
begin
  Variable := AValue;
  Q := TMathParser.Create(nil);
  try
    Q.AddVariable(AName, Variable);
    CheckDouble(Format('%s with %s = %s', [Text, AName, FormatFloat('0.###', AValue)]),
      Q.AsDouble(Text), Want, 1E-12);
  finally
    Q.Free;
  end;
end;

var
  Handmade, Exact, Diff: Extended;
  {
    The difference is shown through Double. The hard cast Double(Diff) passes
    on Windows - there Extended IS Double - and on Linux the eighty-bit
    Extended does not allow it, so the set would not build at all. A plain
    assignment converts the value rather than replaying the bits, and does for
    both.
  }
  Shown: Double;
begin
  P := TMathParser.Create(nil);
  try
    BeginSection('Pi: precision and contract');
    CheckDouble('4 * ArcTan(1) = Pi', Value('4 * ArcTan(1) - Pi'), 0);
    CheckDouble('Sin(Pi) = 0', Value('Sin(Pi)'), 0, 1E-15);
    CheckDouble('pi in lower case is the same number', Value('pi - Pi'), 0);
    BeginSection('The base of the natural logarithm');
    CheckDouble('Ln(Exp(1)) = 1', Value('Ln(Exp(1))'), 1);
    {
      The brackets here are NOT redundant: without them Exp(1) ** 2 is taken as
      Exp(1 ** 2). That is a defect of the parser, pinned in its own section
      below.
    }
    CheckDouble('Exp(2) = (Exp(1)) ** 2', Value('Exp(2) - (Exp(1)) ** 2'), 0, 1E-12);
    {
      What all of this was for: a nine-character record differs from the exact
      value by about 5E-10, and in an exponent that is visible to the naked eye.
    }
    Handmade := Value('2.718281828');
    Exact := Value('Exp(1)');
    Diff := Abs(Exact - Handmade);
    Shown := Diff;
    Check('Exp(1) is closer than a hand-typed record', Diff > 1E-11,
      Format('difference %.3e', [Shown]));
    Check('and that is not a slip in Exp itself', Diff < 1E-8, Format('difference %.3e', [Shown]));
    Diff := Abs(Value('Exp(20)') - Value('2.718281828 ** 20'));
    Shown := Diff;
    Check('in an exponent the difference shows', Diff > 1E-3,
      Format('e^20 differs by %.6f', [Shown]));
    BeginSection('A number with an exponent: what actually happens');
    {
      THE DEBT IS CLOSED, 21.08.2026. What used to be here.

      The parser read an exponent only without a sign:

        1E3     = 1000        read
        2.5E-2  REFUSED       "Unknown element: 2.5E"
        3E+2    REFUSED       "Unknown element: 3E"

      And the same went for the name E: the constant E was added and taken back
      out the same day, because a registered name was caught before the number
      and cut 1E3 in half.

      Both troubles were in one place, as the old debt said: GetFFArray looked
      for function names character by character and walked INSIDE the record of
      a number. It took the minus after E for subtraction, and the name E for a
      name.

      The cure: a number became indivisible. NumberSpan takes it whole - with
      the separator, the exponent and the sign of the exponent - and the parser
      no longer looks inside. The same reading is repeated in MakeTemplate,
      otherwise the cache key and the value array would drift apart.
    }
    Check('1E3 reads as a thousand', Reads('1E3'));
    CheckDouble('and equals a thousand', Value('1E3'), 1000);
    Check('1e3 in lower case as well', Reads('1e3'));
    CheckDouble('2.5E-2 reads', Value('2.5E-2'), 0.025, 1E-15);
    CheckDouble('3E+2 reads', Value('3E+2'), 300, 1E-12);
    CheckDouble('1E-3 reads', Value('1E-3'), 0.001, 1E-15);
    CheckDouble('the sign of an exponent is not subtraction', Value('2-1E-3'), 1.999, 1E-12);
    CheckDouble('and ordinary subtraction stayed itself', Value('1E3-2'), 998, 1E-12);
    Check('the stub 1E still does not read', not Reads('1E'));
    Check('nor does 1E-', not Reads('1E-'));
    {
      The name E no longer cuts a number. Its own parser: the shared one does
      not have this name, and registering it here is the subject of the check.
    }
    WithName('E', 7, 'E - 3', 4);
    WithName('E', 7, '1E3', 1000);
    WithName('E', 7, '1E-3', 0.001);
    WithName('E', 7, 'E * 1E3', 7000);
    BeginSection('Power and root after a function call');
    {
      THE DEBT IS CLOSED, 21.08.2026. What used to be here, and why it is
      different now.

      The signs ** and // after a function call went INSIDE its brackets:

        Sin(2) ** 3   was taken as Sin(2 ** 3) = Sin(8)
        Ln(100) // 2  was taken as Ln(100 // 2) = Ln(10)

      The answer was WRONG rather than refused, and that is the heavier case: a
      person sees a refusal, a wrong number they do not. Found on 20.08.2026 by
      measurement, while working on issue #5 from bms-2015 - the one where the
      person wrote "I cannot work out the syntax of formulas, the square and
      the root in particular".

      It was not about priority. TParser.Order pulls signs of a special priority
      out first and, working out what stands to the left of the sign, broke the
      walk at the very first neighbour - that is, it took the argument away from
      the function standing in front of it and left the function outside.
      Checked: none of the six combinations of priority and coverage cures this
      without losing the precedence of ** over multiplication.

      The cure is in the walk itself: it no longer breaks the pair "a function
      of one argument and its argument". Then the collected piece coincides with
      the whole expression, Order declines to reorder, and parsing goes the
      usual way - the function takes its argument, the sign applies after.

      A side effect, said out loud: Sin 2 ** 3 without brackets is now also
      (Sin 2) ** 3 rather than Sin(8). At this stage the parser does not tell a
      bracket from the absence of one, and one rule serves both records.
    }
    CheckDouble('Sin(2) ** 3 is (Sin 2) cubed',
      Value('Sin(2) ** 3'), Value('Sin(2) * Sin(2) * Sin(2)'), 1E-12);
    CheckDouble('and it is not Sin(8)', Abs(Value('Sin(2) ** 3') - Value('Sin(8)')), 0.2, 0.05);
    CheckDouble('Ln(100) // 2 is the root of Ln(100)',
      Value('Ln(100) // 2'), Value('(Ln(100)) // 2'), 1E-12);
    CheckDouble('with its own brackets it comes to the same',
      Value('(Sin(2)) ** 3'), Value('Sin(2) * Sin(2) * Sin(2)'), 1E-12);
    CheckDouble('a root after a call is no longer a refusal',
      Value('Abs(-2) // 2'), Value('2 // 2'), 1E-12);
    CheckDouble('degree after a call is right', Value('Abs(-2) degree 3'), 8, 1E-12);
    { The precedence of ** over multiplication is untouched - that is the border of
  the fix. }
    CheckDouble('power binds tighter than multiplication', Value('2 * 3 ** 2'), 18, 1E-12);
    CheckDouble('power binds tighter than addition', Value('2 + 3 ** 2'), 11, 1E-12);
    CheckDouble('root binds tighter than multiplication', Value('4 // 2 * 2'), 4, 1E-12);
    { The ordinary signs were NOT affected - that is the border of the defect, and
  it is checked. }
    CheckDouble('multiplication after a function is right',
      Value('Sin(2) * 3'), Value('(Sin(2)) * 3'), 1E-12);
    CheckDouble('addition after a function is right',
      Value('Sin(2) + 3'), Value('(Sin(2)) + 3'), 1E-12);
    CheckDouble('division after a function is right',
      Value('Ln(8) / 2'), Value('(Ln(8)) / 2'), 1E-12);
  finally
    P.Free;
  end;
  Halt(TestSummary);
end.
