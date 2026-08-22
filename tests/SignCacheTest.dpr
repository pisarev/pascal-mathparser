{ ************************************************************************** }
{                                                                            }
{ SignCacheTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program SignCacheTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseUtils, ValueTypes, ValueUtils, TextConsts,
  TestKit in 'TestKit.pas';

{
  What this file guards.

  The sign of a number and the template cache. The key of the cache is a
  template - the expression with the numbers taken out and replaced by a
  placeholder. If the sign of a number does not reach the key, two different
  expressions get one key, and the second is evaluated by the script of the
  first. A person sees the right number once, and somebody else's after that.

  That is how it was: X - 400 and X + 400 shared the key X+?, and the sign went
  off into the value. After X - 400 the expression X + 400 answered -398.5
  instead of 401.5.

  The opposite trouble lives next door. The sign of a number that is an argument
  of a call is kept NOT where it is kept for every other number: an ordinary
  number keeps it in the Sign field of the header, an argument keeps it in the
  value itself. Substitution restores the sign from the value, so values are
  obliged to arrive signed. Take the sign out of the value and after
  Min(-500, 2) the expression Min(-400, 2) answers 2 instead of -400.

  Hence the contract checked here - BOTH ends at once:

    1. the sign stands in the key: expressions of different sign get different
       keys;
    2. the sign stands in the value as well: it agrees with the key;
    3. the answer does not depend on what the parser evaluated before.

  Both ends have to be held. A check that looks only at the first goes green on
  code where the second is broken - and that is what happened: a battery of
  seventeen sets missed the argument defect, because its generator never once
  put a sign in front of a number inside a call.

  The run is a cheap one: the numbers come from a table, and the generated part
  is capped at three hundred expressions. A long search is a separate run; what
  stands here is a guard against the return of a known trouble.
}

var
  XVar, YVar, ZVar: Double;

function Alone(const Text: string): Double;
var
  P: TMathParser;
begin
  P := TMathParser.Create(nil);
  try
    P.AddVariable('X', XVar);
    P.AddVariable('Y', YVar);
    P.AddVariable('Z', ZVar);
    Result := P.AsDouble(Text);
  finally
    P.Free;
  end;
end;

{ The second expression after the first, and then the same one on its own. The
  numbers are obliged to match. }
procedure Pair(const First, Second: string);
var
  P: TMathParser;
  Want, Got: Double;
begin
  Want := Alone(Second);
  P := TMathParser.Create(nil);
  try
    P.AddVariable('X', XVar);
    P.AddVariable('Y', YVar);
    P.AddVariable('Z', ZVar);
    P.AsDouble(First);
    Got := P.AsDouble(Second);
  finally
    P.Free;
  end;
  CheckDouble(Format('%s after %s', [Second, First]), Got, Want, 1E-9);
end;

{
  Two records of one and the same thing. A refusal is a lawful outcome and is
  compared on equal terms with a number: if one record is rejected, the other is
  obliged to be rejected too. Otherwise the check would fail on parsing instead
  of naming the divergence.
}
procedure Same(const First, Second: string);
var
  A, B: Double;
  OkA, OkB: Boolean;
begin
  A := 0;
  B := 0;
  OkA := True;
  OkB := True;
  try
    A := Alone(First);
  except
    OkA := False;
  end;
  try
    B := Alone(Second);
  except
    OkB := False;
  end;
  if OkA <> OkB then
    Fail(Format('%s = %s', [First, Second]), 'one record accepted, the other rejected')
  else if not OkA then
    Check(Format('%s = %s', [First, Second]), True, 'both rejected')
  else
    CheckDouble(Format('%s = %s', [First, Second]), A, B, 1E-12);
end;

{
  Three expressions to one parser in a row: the second and the third are obliged
  to match what a fresh parser gives. The order here is the subject of the
  check, not a detail of it.
}
procedure Chain(const A, B, C: string);
var
  P: TMathParser;
  GotB, GotC: Double;
begin
  P := TMathParser.Create(nil);
  try
    P.AddVariable('X', XVar);
    P.AddVariable('Y', YVar);
    P.AddVariable('Z', ZVar);
    P.AsDouble(A);
    GotB := P.AsDouble(B);
    GotC := P.AsDouble(C);
  finally
    P.Free;
  end;
  CheckDouble(Format('%s after %s', [B, A]), GotB, Alone(B), 1E-9);
  CheckDouble(Format('%s after %s and %s', [C, A, B]), GotC, Alone(C), 1E-9);
end;

var
  Templater: TMathParser;

{
  How the key is built. Two statements about one parse:
    - there are as many placeholders as there are values;
    - a minus in front of a placeholder goes with a non-positive value, a
      placeholder without a minus with a non-negative one.
  The second is the agreement of key and value that all of this was for.
}
procedure Shape(const Text: string);
var
  Tpl: string;
  VA: TValueArray;
  I, Marks, K: Integer;
  D: Double;
  Minus, Clash: Boolean;
begin
  VA := nil;
  try
    Tpl := MakeTemplate(Templater, Text, @VA);
    Marks := 0;
    for I := 1 to Length(Tpl) do
      if Tpl[I] = Inquiry then Inc(Marks);
    Check(Format('%s: as many placeholders as values', [Text]),
      Marks = Length(VA), Format('template %s: placeholders %d, values %d',
      [Tpl, Marks, Length(VA)]));
    if Marks <> Length(VA) then Exit;
    Clash := False;
    K := 0;
    for I := 1 to Length(Tpl) do
      if Tpl[I] = Inquiry then
      begin
        Minus := (I > 1) and (Tpl[I - 1] = TextConsts.Minus);
        D := GetDouble(VA[K]);
        if (Minus and (D > 0)) or (not Minus and (D < 0)) then Clash := True;
        Inc(K);
      end;
    Check(Format('%s: the sign in the key and the sign of the value agree', [Text]),
      not Clash, 'template ' + Tpl);
  finally
    VA := nil;
  end;
end;

{ Two expressions of different sign are obliged to get DIFFERENT keys. }
procedure Apart(const A, B: string);
var
  TA, TB: string;
begin
  TA := MakeTemplate(Templater, A, nil);
  TB := MakeTemplate(Templater, B, nil);
  Check(Format('%s and %s - the keys differ', [A, B]), TA <> TB, Format('%s against %s', [TA, TB]));
end;

{ The generated part: a source of randomness of its own, so that a run can be
  repeated. }
var
  Seed: LongWord;

function Next(const Limit: Integer): Integer;
begin
  Seed := Seed * 1103515245 + 12345;
  Result := Integer((Seed shr 16) mod LongWord(Limit));
end;

function SignRun: string;
begin
  case Next(6) of
    0: Result := '-';
    1: Result := '--';
    2: Result := '+-';
  else
    Result := '';
  end;
end;

function Build(const Level: Integer): string;
var
  A, B, Op: string;
begin
  if Level <= 0 then
    case Next(2) of
      0: Result := SignRun + IntToStr((Next(9) + 1) * Round(IntPower(10, Next(3))));
    else
      case Next(3) of
        0: Result := 'X';
        1: Result := 'Y';
      else
        Result := 'Z';
      end;
    end
  else
    case Next(4) of
      0: Result := SignRun + IntToStr((Next(9) + 1) * Round(IntPower(10, Next(3))));
      1:
        begin
          A := Build(Level - 1);
          B := Build(Level - 1);
          if Next(2) = 0 then
            Op := '+'
          else
            Op := '-';
          Result := A + Op + '(' + B + ')';
        end;
      2: Result := 'Min(' + Build(Level - 1) + ', 2)';
    else
      Result := 'Abs(' + Build(Level - 1) + ')';
    end;
end;

const
  Sweep = 300;

var
  I, Bad: Integer;
  Text: string;
  P: TMathParser;
  Want, Got: Double;
  Blank: TMathParser;
begin
  XVar := 1.5;
  YVar := 2.25;
  ZVar := 0.75;
  Templater := TMathParser.Create(nil);
  try
    Templater.AddVariable('X', XVar);
    Templater.AddVariable('Y', YVar);
    Templater.AddVariable('Z', ZVar);
    BeginSection('the sign stands in the key: different signs, different keys');
    Apart('X + 400', 'X - 400');
    Apart('Min(400, 2)', 'Min(-400, 2)');
    Apart('400', '-400');
    Apart('X + 1.5', 'X - 1.5');
    Apart('Min(2, 400)', 'Min(2, -400)');
    BeginSection('how the key and the value array are built');
    Shape('X + 400');
    Shape('X - 400');
    Shape('-400');
    Shape('(-400)');
    Shape('X - -400');
    Shape('X + -400');
    Shape('X--400');
    Shape('Min(-400, 2)');
    Shape('Min(2, -400)');
    Shape('Min(-(30 + X + 7000), 2)');
    Shape('X - 1.5');
    BeginSection('the sign of a term: the history does not change the answer');
    Pair('X - 400', 'X + 400');
    Pair('X + 400', 'X - 400');
    Pair('X - 10', 'X + 20');
    Pair('X - 1.5', 'X + 1.5');
    Pair('X + 1.5', 'X - 1.5');
    Pair('X - 400', 'X + 500');
    Pair('X - -400', 'X - 400');
    Pair('-400 + X', '400 + X');
    BeginSection('the sign of a call argument: the history does not change the answer');
    Pair('Min(-500, 2)', 'Min(-400, 2)');
    Pair('Min(-400, 2)', 'Min(-500, 2)');
    Pair('Min(2, -500)', 'Min(2, -400)');
    Pair('Min(-500.5, 2)', 'Min(-400.5, 2)');
    Pair('Min(500, 2)', 'Min(-400, 2)');
    Pair('Min(-400, 2)', 'Min(400, 2)');
    Pair('Min(X - 400, 9999)', 'Min(X + 400, 9999)');
    Pair('Abs(-500) + 0', 'Abs(-400) + 1');
    {
      The sign in front of the base of a power. MakeTemplate reads a minus
      between terms as the sign of a number: 1-2**X/2**X gives the key ?-?**X/?**X
      with the value -2. For 1-2 the two readings come to the same thing, here
      they do not: the minus is obliged to apply after the power. While the text
      is parsed on its own the answer is right; the trouble came out on
      substitution into a ready script, where the sign was counted twice.
    }
    BeginSection('the sign before a power: the history does not change the answer');
    Pair('1-2**X/2**X', '5-3**X/4**X');
    Pair('5-3**X/4**X', '1-2**X/2**X');
    Pair('1+2**X/2**X', '5+3**X/4**X');
    Pair('0-2**X/2**X', '9-4**X/5**X');
    Pair('1-2//X/2//X', '5-3//X/4//X');
    Pair('3000-2**X/(Abs(Exp(Frac(8000))) + 1)**X', '4000-3**X/(Abs(Exp(Frac(9000))) + 1)**X');
    Pair('1-2**X/2', '5-3**X/4');
    Pair('7-(Min(-20, 2))', '8-(Min(-30, 2))');
    Pair('7-(Min(+-20, 2))', '8-(Min(+-30, 2))');
    {
      Zero has no sign, and a slot filled with a zero could lose the mark that
      says "the sign lives in the number itself here" - and then the next
      negative number went in without its minus. The header settles it now: if
      there is no sign either in it or in the number, then the number is the one
      to carry it. The order of presentation is itself the subject of the check
      here, which is why every chain goes in three steps.
    }
    BeginSection('a zero between signed ones: the mark is not lost');
    Chain('Min(-0, 2)', 'Min(-500, 2)', 'Min(-400, 2)');
    Chain('Min(-0.0, 2)', 'Min(-500.5, 2)', 'Min(-400.5, 2)');
    Chain('Min(-500, 2)', 'Min(-0, 2)', 'Min(-400, 2)');
    Chain('Min(2, -0)', 'Min(2, -500)', 'Min(2, -400)');
    Chain('X-0', 'X-500', 'X-400');
    Chain('X+0', 'X+500', 'X+400');
    Chain('-0', '-500', '-400');
    { A zero in a signed slot next to a power. 0 ** X itself is left out: a zero to
      a fractional power is a lawful refusal from the coprocessor, not a subject
      for a check. }
    Chain('1-0*2**X', '1-2*2**X', '5-3*4**X');
    {
      A call without brackets. At the reordering stage the parser does not tell a
      bracket from the absence of one, so Sin 2 ** 3 and Sin(2) ** 3 are obliged
      to mean the same thing. The coverage here is thin - the generator hardly
      ever builds that form - and it is exactly the form that changes the
      meaning, so the cases are written out by hand.
    }
    BeginSection('a call without brackets: the same shape as with them');
    Same('Sin 2 ** 3', 'Sin(2) ** 3');
    Same('Sin 2 ** 3', '(Sin(2)) ** 3');
    Same('Cos 2 * 3', 'Cos(2) * 3');
    Same('Abs 2 // 2', 'Abs(2) // 2');
    Same('Sin X ** 2', 'Sin(X) ** 2');
    Same('Sin (X) ** 2', 'Sin(X) ** 2');
    Same('Abs 2 ** 2', 'Abs(2) ** 2');
    Same('Sqrt 4 degree 2', 'Sqrt(4) degree 2');
    Same('Sin Cos 2 ** 2', 'Sin(Cos(2)) ** 2');
    Same('Ln 100 / 2', 'Ln(100) / 2');
    Same('Sin 2 + 3', 'Sin(2) + 3');
    BeginSection(Format('the generated part: %d expressions with signs', [Sweep]));
    Seed := 20260820;
    Bad := 0;
    P := TMathParser.Create(nil);
    try
      P.AddVariable('X', XVar);
      P.AddVariable('Y', YVar);
      P.AddVariable('Z', ZVar);
      for I := 1 to Sweep do
      begin
        Text := Build(3);
        Blank := TMathParser.Create(nil);
        try
          Blank.AddVariable('X', XVar);
          Blank.AddVariable('Y', YVar);
          Blank.AddVariable('Z', ZVar);
          Want := Blank.AsDouble(Text);
        finally
          Blank.Free;
        end;
        Got := P.AsDouble(Text);
        if Abs(Got - Want) > 1E-9 * Max(1, Max(Abs(Got), Abs(Want))) then
        begin
          Inc(Bad);
          if Bad <= 3 then
            Fail('the history changes the answer',
              Format('%s: shared %s, fresh %s', [Text,
                FormatFloat('0.######', Got), FormatFloat('0.######', Want)]));
        end;
      end;
    finally
      P.Free;
    end;
    Check(Format('all %d expressions evaluate the same on a fresh and a shared parser', [Sweep]),
      Bad = 0, Format('diverged: %d', [Bad]));
  finally
    Templater.Free;
  end;
  Halt(TestSummary);
end.
