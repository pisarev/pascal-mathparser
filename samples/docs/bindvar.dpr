{ ************************************************************************** }
{                                                                            }
{ bindvar                                                                    }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program BindVar;

{ expect: 6.0 }
{$APPTYPE CONSOLE}

uses
  Parser;

var
  P: TMathParser;
  X: Double;
begin
  P := TMathParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2.5;
    Writeln(P.AsDouble('x * 2 + 1'):0:1);
  finally
    P.Free;
  end;
end.
