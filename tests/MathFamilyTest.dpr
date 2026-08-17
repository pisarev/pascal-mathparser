{ ************************************************************************** }
{                                                                            }
{ MathFamilyTest                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program MathFamilyTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, TestKit in 'TestKit.pas';

{
  What this file guards.

  The functions of the secant family - Cotan, Sec, Csc, their hyperbolic and
  inverse relatives - come from the Math unit. Free Pascal 3.2.2 has nine of
  them missing: ArcCot, ArcCotH, ArcCsc, ArcCscH, ArcSec, ArcSecH, CotH, CscH
  and SecH arrived in 3.3.1. The library carries them under conditional
  compilation so that the older compiler can build it too.

  A hand-written formula risks disagreeing with the real one, and disagreeing
  quietly: ArcCotan(2) is about 0.46 either way, and the difference shows at
  zero and on a negative argument, where the branches part. Until this check
  there was not a single test for those nine functions - not one.

  So what is checked is not a table of values but the CONTRACT: a reciprocal
  multiplied by its base is one, an inverse returns the argument of the direct
  function. Such statements hold on any compiler and catch a substituted
  formula.
}

var
  P: TMathParser;

// A reciprocal: multiplied by its base it gives one.
procedure Reciprocal(const Name, Base, Arg: string);
begin
  CheckDouble(Format('%s(%s) * %s(%s) = 1', [Name, Arg, Base, Arg]),
    P.AsDouble(Format('%s(%s) * %s(%s)', [Name, Arg, Base, Arg])), 1);
end;

{
  An inverse returns the argument of the direct function.

  The argument arrives twice - as a string for the formula and as a number for
  the comparison. Parsing the string back would be tempting, but StrToFloat
  reads the separator from the system settings while a formula always uses a
  dot: under a comma locale the check would compare against a different number.
}
procedure RoundTrip(const Inverse, Direct, Arg: string; const Value: Double);
begin
  CheckDouble(Format('%s(%s(%s)) = %s', [Inverse, Direct, Arg, Arg]),
    P.AsDouble(Format('%s(%s(%s))', [Inverse, Direct, Arg])), Value);
end;

begin
  Writeln('=== the secant family: the contract, not a table of values ===');
  P := TMathParser.Create(nil);
  try
    {
      Reciprocals. The argument is taken where neither of the pair turns to
      zero: otherwise the check would be about infinity rather than about the
      formula.
    }
    Reciprocal('Cotan', 'Tan', '0.7');
    Reciprocal('Cotan', 'Tan', '-1.3');
    Reciprocal('Sec', 'Cos', '0.7');
    Reciprocal('Sec', 'Cos', '-1.3');
    Reciprocal('Csc', 'Sin', '0.7');
    Reciprocal('Csc', 'Sin', '-1.3');
    Reciprocal('Cotanh', 'Tanh', '0.7');
    Reciprocal('Cotanh', 'Tanh', '-1.3');
    Reciprocal('Sech', 'Cosh', '0.7');
    Reciprocal('Sech', 'Cosh', '-1.3');
    Reciprocal('Csch', 'Sinh', '0.7');
    Reciprocal('Csch', 'Sinh', '-1.3');
    {
      Inverses. The arguments sit inside the range where the direct function is
      invertible.
    }
    RoundTrip('ArcCotan', 'Cotan', '0.7', 0.7);
    {
      The branch convention, and it is the point here. ArcCotan answers within
      (-pi/2, pi/2) - that is, ArcTan(1/x) - and not within (0, pi), which some
      libraries choose. The difference shows only outside the first branch:
      from an argument of 2.4 the way back lands on 2.4 - pi. A hand-written
      formula easily picks the other convention, and without this check the
      substitution would pass unnoticed: inside the first branch the two
      versions agree.
    }
    RoundTrip('ArcCotan', 'Cotan', '2.4', 2.4 - Pi);
    RoundTrip('ArcSec', 'Sec', '0.7', 0.7);
    RoundTrip('ArcCsc', 'Csc', '0.7', 0.7);
    RoundTrip('ArcCotanh', 'Cotanh', '0.7', 0.7);
    RoundTrip('ArcCotanh', 'Cotanh', '-1.3', -1.3);
    RoundTrip('ArcSech', 'Sech', '0.7', 0.7);
    RoundTrip('ArcCsch', 'Csch', '0.7', 0.7);
    RoundTrip('ArcCsch', 'Csch', '-1.3', -1.3);
    {
      The special points where the formulas part by branch. The cotangent has a
      pole at zero, and a naive ArcTan(1/x) divides by zero there; the real
      function answers with half of pi. Cotanh on large arguments must approach
      one rather than blow up on a subtraction of close numbers.
    }
    CheckDouble('ArcCotan(0) = pi/2', P.AsDouble('ArcCotan(0)'), Pi / 2);
    CheckDouble('Cotanh(20) = 1', P.AsDouble('Cotanh(20)'), 1, 1E-15);
    CheckDouble('Cotanh(-20) = -1', P.AsDouble('Cotanh(-20)'), -1, 1E-15);
  finally
    P.Free;
  end;
  ExitCode := TestSummary;
end.
