{ ************************************************************************** }
{                                                                            }
{ DocumentedSyntaxTest                                                       }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program DocumentedSyntaxTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Parser, CalcUtils, TestKit in 'TestKit.pas';

{
  What this file guards.

  Everything the published documentation claims about the language is asserted
  here against the running engine. It exists because the documentation once
  stated three things that were simply false: that a quoted literal could be
  added to another, that "!" was a postfix factorial, and that names were case
  sensitive. Nothing contradicted them, because nothing ran them.

  The rule this file encodes: a sentence in the README or on a reference page is
  either checked here or it is not published.
}

const
  { Every built-in name, taken from ParseConsts. The count is the number the
    documentation is allowed to print. }
  BuiltInNames: array[0..198] of string = (
    'abs', 'and', 'arccos', 'arccosh', 'arccotan', 'arccotanh', 'arccsc',
    'arccsch', 'arcsec', 'arcsech', 'arcsin', 'arcsinh', 'arctan',
    'arctan2', 'arctanh', 'bxor', 'ceil', 'comparedate', 'comparedatetime',
    'comparetime', 'cos', 'cosh', 'cotan', 'cotanh', 'csc', 'csch',
    'cycletodeg', 'cycletograd', 'cycletorad', 'date', 'dateof',
    'datetime', 'day', 'dayof', 'dayofthemonth', 'dayoftheweek',
    'dayoftheyear', 'dayofweek', 'daysbetween', 'degree', 'degtocycle',
    'degtograd', 'degtorad', 'delete', 'deriv', 'div', 'encodedate',
    'encodedatetime', 'encodetime', 'ensurerange', 'execute', 'exit',
    'exp', 'factorial', 'false', 'find', 'floor', 'for', 'frac', 'get',
    'getday', 'getdayofweek', 'getepsilon', 'gethour', 'getmillisecond',
    'getminute', 'getmonth', 'getsecond', 'gettickcount', 'getyear',
    'gradtocycle', 'gradtodeg', 'gradtorad', 'hour', 'hourof',
    'houroftheday', 'hourofthemonth', 'houroftheweek', 'houroftheyear',
    'hoursbetween', 'hypot', 'if', 'ifthen', 'int', 'intpower', 'iszero',
    'ldexp', 'lg', 'ln', 'lnxp1', 'log', 'log10', 'log2', 'max',
    'maxintvalue', 'maxvalue', 'mean', 'millisecond', 'millisecondof',
    'millisecondoftheday', 'millisecondofthehour',
    'millisecondoftheminute', 'millisecondofthemonth',
    'millisecondofthesecond', 'millisecondoftheweek',
    'millisecondoftheyear', 'millisecondsbetween', 'min', 'minintvalue',
    'minute', 'minuteof', 'minuteoftheday', 'minuteofthehour',
    'minuteofthemonth', 'minuteoftheweek', 'minuteoftheyear',
    'minutesbetween', 'minvalue', 'mod', 'month', 'monthof',
    'monthoftheyear', 'monthsbetween', 'new', 'norm', 'not', 'or', 'parse',
    'poly', 'popnstddev', 'popnvariance', 'pred', 'radtocycle', 'radtodeg',
    'radtograd', 'randg', 'random', 'randomfrom', 'randomrange', 'repeat',
    'round', 'roundto', 'samedate', 'samedatetime', 'sametime',
    'samevalue', 'script', 'sec', 'sech', 'second', 'secondof',
    'secondoftheday', 'secondofthehour', 'secondoftheminute',
    'secondofthemonth', 'secondoftheweek', 'secondoftheyear',
    'secondsbetween', 'set', 'setdecimalseparator', 'setepsilon', 'shl',
    'shr', 'sin', 'sinh', 'sqr', 'sqrt', 'stddev', 'strtodate',
    'strtodatetime', 'strtofloat', 'strtofloatdef', 'strtoint',
    'strtointdef', 'strtotime', 'succ', 'sum', 'sumint', 'sumofsquares',
    'tan', 'tanh', 'time', 'timeof', 'totalvariance', 'true', 'trunc',
    'tryexcept', 'tryfinally', 'variance', 'void', 'weekof',
    'weekofthemonth', 'weekoftheyear', 'weeksbetween', 'while', 'xor',
    'year', 'yearof', 'yearsbetween');

var
  P: TMathParser;
  X: Double;

function Raises(const Formula: string): Boolean;
begin
  Result := False;
  try
    P.AsDouble(Formula);
  except
    on E: Exception do Result := True;
  end;
end;

function Accepts(const Name: string): Boolean;
var
  Forms: array[0..3] of string;
  I: Integer;
begin
  Forms[0] := Name + '(1)';
  Forms[1] := Name + '(1, 2)';
  Forms[2] := Name + '(1, 2, 3)';
  Forms[3] := Name;
  Result := False;
  for I := 0 to 3 do
    try
      P.AsDouble(Forms[I]);
      Exit(True);
    except
      on E: Exception do
        { An arity or type complaint still means the name is registered; only an
          unknown name means it is not. }
        if Pos('Unknown', E.Message) = 0 then Exit(True);
    end;
end;

procedure OperatorsThatSurprisePeople;
begin
  BeginSection('the operators the documentation warns about');
  CheckDouble('power is **', P.AsDouble('5 ** 3'), 125);
  CheckDouble('caret is exclusive or', P.AsDouble('5 ^ 3'), 6);
  CheckDouble('double slash is a root', P.AsDouble('8 // 3'), 2);
  CheckDouble('degree spelled out', P.AsDouble('2 degree 10'), 1024);
  CheckDouble('div', P.AsDouble('7 div 2'), 3);
  CheckDouble('mod', P.AsDouble('7 mod 2'), 1);
  CheckDouble('bitwise and', P.AsDouble('6 & 3'), 2);
  CheckDouble('bitwise or', P.AsDouble('6 | 3'), 7);
  CheckDouble('bxor', P.AsDouble('6 bxor 3'), 5);
  CheckDouble('shl', P.AsDouble('1 shl 4'), 16);
  CheckDouble('shr', P.AsDouble('16 shr 4'), 1);
  CheckDouble('a call needs no brackets', P.AsDouble('Sin 0'), 0);
end;

procedure ComparisonAnswersMinusOne;
begin
  BeginSection('true is minus one');
  CheckDouble('a comparison is -1', P.AsDouble('3 > 2'), -1);
  CheckDouble('so adding one gives zero', P.AsDouble('(3 > 2) + 1'), 0);
  Check('AsBoolean gives a Boolean', P.AsBoolean('3 > 2'));
  CheckDouble('equality compares the sum', P.AsDouble('1 + 2 = 3'), -1);
end;

procedure PrecedenceIsWhatTheDocsSay;
begin
  BeginSection('precedence');
  CheckDouble('power binds tighter than times', P.AsDouble('2 * 3 ** 2'), 18);
  CheckDouble('times and divide go left to right', P.AsDouble('12 / 3 * 2'), 8);
  CheckDouble('brackets win', P.AsDouble('(1 + 2) * (3 + 4)'), 21);
  CheckDouble('minus goes left to right', P.AsDouble('10 - 2 - 3'), 5);
end;

procedure NegationAndFactorial;
begin
  BeginSection('the exclamation mark and the factorial');
  { The documentation called "!" a postfix factorial. It is negation, and the
    factorial is a function. }
  CheckDouble('factorial is a function', P.AsDouble('factorial(5)'), 120);
  CheckDouble('the exclamation mark negates', P.AsDouble('!0'), -1);
  CheckDouble('and matches not', P.AsDouble('not 0'), -1);
end;

procedure TheLanguageIsArithmetic;
begin
  BeginSection('quoted text is not a value');
  { The documentation showed 'ab' + 'cd' giving abcd. It does not: a quoted
    literal is refused outright. }
  Check('a quoted literal is refused', Raises('''ab'' + ''cd'''));
  Check('AsString converts the answer, it does not join text', P.AsString('2 + 2') = '4', '  got "' + P.AsString('2 + 2') + '"');
end;

procedure LazinessAndSelfReference;
begin
  BeginSection('if is lazy, parse and deriv read their argument');
  CheckDouble('the dead branch is not evaluated', P.AsDouble('if(0 <> 0, 1 / 0, 7)'), 7);
  CheckDouble('parse compiles at evaluation', P.AsDouble('parse("2 + 3")'), 5);
  CheckDouble('deriv differentiates', P.AsDouble('deriv("x ** 2", "x")'), 2 * 2.5);
end;

procedure TheFreeFunctionsNeedNothingCreated;
begin
  BeginSection('CalcUtils, the one-line path shown on the front page');
  Check('AsInteger', CalcUtils.AsInteger('2 + 2') = 4);
  CheckDouble('AsDouble', CalcUtils.AsDouble('pi / 6'), 0.5235987755982988, 1E-12);
  Check('AsBoolean', CalcUtils.AsBoolean('3 > 2'));
  Check('AsString', CalcUtils.AsString('2 + 2') = '4');
end;

procedure EveryBuiltInNameIsKnown;
var
  I, Known: Integer;
  Missing: string;
begin
  BeginSection('the roster of built-in names');
  Known := 0;
  Missing := '';
  for I := Low(BuiltInNames) to High(BuiltInNames) do
    if Accepts(BuiltInNames[I]) then
      Inc(Known)
    else
      Missing := Missing + ' ' + BuiltInNames[I];
  Check('every name in the roster is registered', Missing = '', '  missing:' + Missing);
  Check('the roster has the size the documentation prints', Known = Length(BuiltInNames),
    Format('  known=%d roster=%d', [Known, Length(BuiltInNames)]));
  Writeln(Format('  built-in names verified: %d', [Known]));
end;

begin
  Writeln('=== every claim the documentation makes, run against the engine ===');
  P := TMathParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2.5;
    OperatorsThatSurprisePeople;
    ComparisonAnswersMinusOne;
    PrecedenceIsWhatTheDocsSay;
    NegationAndFactorial;
    TheLanguageIsArithmetic;
    LazinessAndSelfReference;
    TheFreeFunctionsNeedNothingCreated;
    EveryBuiltInNameIsKnown;
  finally
    P.Free;
  end;
  ExitCode := TestSummary;
end.
