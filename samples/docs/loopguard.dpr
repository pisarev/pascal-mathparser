{ ************************************************************************** }
{                                                                            }
{ LoopGuard                                                                  }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program LoopGuard;

{ expect: Loop limit stopped it, cnt reached 999 }
{$APPTYPE CONSOLE}

uses SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils;

var
  P: TMathParser;
  Cnt: TValue;
  Note: string;
begin
  P := TMathParser.Create(nil);
  try
    AssignDouble(Cnt, 0);
    P.AddVariable('cnt', Cnt);
    { show }
    ParseLoopLeft := 1000;
    Note := '';
    try
      P.AsDouble('While(1 = 1, Set("cnt", cnt + 1))');
    except
      on E: Exception do Note := E.Message;
    end;
    Writeln(Format('%s stopped it, cnt reached %.0f', [Copy(Note, 1, 10), GetDouble(Cnt)]));
    { show done }
  finally
    P.Free;
  end;
end.
