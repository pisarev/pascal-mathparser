{ ************************************************************************** }
{                                                                            }
{ bulk                                                                       }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program Bulk;

{ expect: 30000.40 }
{$APPTYPE CONSOLE}

uses
  ParseJit.Parser;

var
  P: TJitParser;
  X: Double;
  Inputs, Outputs: array of Double;
  I: Integer;
begin
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    SetLength(Inputs, 100000);
    SetLength(Outputs, 100000);
    for I := 0 to High(Inputs) do
      Inputs[I] := I / 1000;
    P.ExecuteMany('x * x * 3 + 1', X, Inputs, Outputs);
    Writeln(Outputs[High(Outputs)]:0:2);
  finally
    P.Free;
  end;
end.
