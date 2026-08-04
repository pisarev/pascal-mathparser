{ ************************************************************************** }
{                                                                            }
{ quickstart                                                                 }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program QuickStart;

{ expect: 21.0000 }
{$APPTYPE CONSOLE}

uses
  CalcUtils, Parser, ParseJit.Parser;

var
  P: TMathParser;
  Jit: TJitParser;
  X, Y: Double;
  I: Integer;
begin
  { show }
  Y := AsDouble('sin(1) + sqrt(2)');
  Writeln(Y:0:4);

  P := TMathParser.Create(nil);
  try
    P.AddVariable('x', X);
    for I := 0 to 100 do
    begin
      X := I / 10;
      Writeln(X:6:2, P.AsDouble('x*x - 2*x + 1'):12:4);
    end;
  finally
    P.Free;
  end;

  Jit := TJitParser.Create(nil);
  try
    Jit.AddVariable('x', X);
    Writeln(Jit.AsDouble('x*2 + 1'):0:4);
  finally
    Jit.Free;
  end;
  { show done }
end.
