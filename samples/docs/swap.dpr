{ ************************************************************************** }
{                                                                            }
{ swap                                                                       }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program Swap;

{ expect: 5.00 5.00 }
{$APPTYPE CONSOLE}

uses
  Parser, ParseJit.Parser;

var
  P: TMathParser;
  X: Double;

function Answer(const Engine: TMathParser): Double;
begin
  Engine.AddVariable('x', X);
  X := 2;
  Result := Engine.AsDouble('x * 2 + 1');
end;

begin
  { show }
  P := TMathParser.Create(nil);
  try
    Write(Answer(P):0:2, ' ');
  finally
    P.Free;
  end;

  P := TJitParser.Create(nil);
  try
    Writeln(Answer(P):0:2);
  finally
    P.Free;
  end;
  { show done }
end.
