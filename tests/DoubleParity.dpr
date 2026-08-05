{ ************************************************************************** }
{                                                                            }
{ DoubleParity                                                               }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
{ Bit-for-bit comparison of results across platforms.

  The fuzzer in JitParserTest compares machine code against the interpreter
  WITHIN one machine and says nothing about the difference between machines.
  Here a fixed set of expressions is evaluated, and what gets printed is not a
  rounded number but the exact bit pattern of the Double. The output of two
  platforms must match character for character.

  How to use it: build and run on both machines, put the output into files and
    compare them with an ordinary diff. A difference in the last bit means that
  somewhere the expression is computed through a different library, or with a
  different precision for intermediate values. }
program DoubleParity;

{$APPTYPE CONSOLE}
{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Parser;

const
  Formula: array[0..29] of string = (
    '2 + 2 * 2',
    '1 / 3',
    '2 / 3',
    '10 / 7',
    'sqrt(2)',
    'sqrt(3)',
    'sin(1)',
    'cos(1)',
    'tan(1)',
    'ln(2)',
    'exp(1)',
    'arctan(1)',
    'pi',
    'pi * 2',
    '2 ** 10',
    '2 ** 0.5',
    '3 ** 3.7',
    '1e300 * 1e-300',
    '0.1 + 0.2',
    '1 - 0.9',
    'x * x + 1',
    'x * x * x * 3 + x * x * 2 + x * 7 + 11',
    'sin(x) * cos(x) + sqrt(abs(x)) + ln(x + 10)',
    '1 / x',
    'x / 3',
    'exp(x) / (1 + exp(x))',
    'arctan(x) * 4',
    'sqr(x) - 2 * x + 1',
    '(x + 1) / (x - 3)',
    'x ** 0.5 + x ** 1.5'
  );

var
  XVar: Double = 2.5;

{ Prints a number as the exact 16 hexadecimal digits of its representation.
  Rounded decimal output would hide a difference in the last bit. }
function Bits(const Value: Double): string;
var
  Raw: Int64 absolute Value;
begin
  Result := IntToHex(Raw, 16);
end;

var
  Base: TMathParser;
  Jit: TJitParser;
  I: Integer;
  ValueBase, ValueJit: Double;
  Mark: string;
  Diff: Integer;
begin
  Diff := 0;
  Base := TMathParser.Create(nil);
  Jit := TJitParser.Create(nil);
  try
    Base.AddVariable('x', XVar);
    Jit.AddVariable('x', XVar);
    Writeln('# platform: ', {$IFDEF MSWINDOWS}'windows'{$ELSE}'unix'{$ENDIF}, ', compiler: ', {$IFDEF FPC}'fpc'{$ELSE}'delphi'{$ENDIF},
      ', x = ', Bits(XVar));
    Writeln('# base             accelerator      expression');
    for I := Low(Formula) to High(Formula) do
    begin
      try
        ValueBase := Base.AsDouble(Formula[I]);
      except
        on E: Exception do
        begin
          Writeln('BASE ERROR: ', Formula[I], ' - ', E.Message);
          Continue;
        end;
      end;
      try
        ValueJit := Jit.AsDouble(Formula[I]);
      except
        on E: Exception do
        begin
          Writeln('ACCELERATOR ERROR: ', Formula[I], ' - ', E.Message);
          Continue;
        end;
      end;
      if Bits(ValueBase) = Bits(ValueJit) then
        Mark := ' '
      else begin
        Mark := '!';
        Inc(Diff);
      end;
      Writeln(Mark, ' ', Bits(ValueBase), ' ', Bits(ValueJit), ' ', Formula[I]);
    end;
    Writeln('# base-accelerator differences: ', Diff);
  finally
    Jit.Free;
    Base.Free;
  end;
  ExitCode := Diff;
end.
