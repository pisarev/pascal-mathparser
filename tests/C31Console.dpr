{ ************************************************************************** }
{                                                                            }
{ C31Console                                                                 }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
{ C31: TCalculator in a CONSOLE application.

  The C31 report read "TCalculator crashes when created in a console
  application" - STATUS_FATAL_USER_CALLBACK_EXCEPTION. What actually crashed was
    not the constructor but the first parallel compilation: two workers were
  building the parser's lazy structures at the same time (the registry Prepare,
  the name hash index, the lexer caches). The worker's exception surfaced
  through RaiseFatalException in a window callback and took the process down.

  The cure is a warm-up: Execute compiles the first item on the main thread
  before the pool starts, so the lazy structures are ready by the time the
  workers run.

  ParserBugTests checks this through a Vcl.Forms Application. Here it is a PURE
  CONSOLE, with no Forms and no Application, exactly as the report described it: create the calculator, run a parallel pool of heavy formulas, wait, compare.
  If C31 is closed there is no crash and every item is computed. }
program C31Console;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  { On Delphi this is a pure console. On FPC, Calculator pulls in SyncThread and
    that pulls in the LCL widgetset, so FPC needs Interfaces or the linker fails
    on the WSRegister* symbols. The widgetset is never started: the pool runs on
    Synchronize and Sleep, and no display is needed. }
  SysUtils,
  Calculator,
  ParseTypes,
  ValueTypes,
  ValueUtils;

var
  Failed: Integer = 0;

procedure Check(const Name: string; const Ok: Boolean; const Details: string = '');
begin
  if Ok then Writeln('PASS  ', Name)
  else begin
    Inc(Failed);
    Write('FAIL  ', Name);
    if Details <> '' then Write('  [', Details, ']');
    Writeln;
  end;
  Flush(Output);
end;

procedure Run;
var
  Calc: TCalculator;
  Heavy: string;
  I: Integer;
begin
  { the constructor itself in a console - the report blamed exactly this }
  Calc := TCalculator.Create(nil);
  Check('C31 Create in a console app does not crash', True);
  try
    Heavy := '1';
    for I := 1 to 400 do Heavy := Heavy + ' + sin(1)';
    for I := 1 to 200 do Calc.Thread.AddText(Heavy);
    Calc.Thread.ThreadCount := 4;

    { the first parallel compilation - this is what took the process down
      before the warm-up }
    Check('C31 parallel pool starts', Calc.Thread.Execute);
    Calc.Thread.WaitFor;
    Check('C31 all 200 items computed without a crash', Calc.Thread.ItemCount = 200, IntToStr(Calc.Thread.ItemCount));
    Calc.Thread.Clear;

    { the parser is alive after the pool }
    Check('C31 calculator still works after the pool', GetDouble(Calc.AsValue('2 + 2')) = 4);
  finally
    Calc.Free;
  end;
  Check('C31 Free in a console app does not crash', True);
end;

begin
  try
    Run;
  except
    on E: Exception do
    begin
      Inc(Failed);
      Writeln('FAIL  C31 unhandled exception: ', E.ClassName, ': ', E.Message);
    end;
  end;
  Writeln('TOTAL: failed ', Failed);
  ExitCode := Failed;
end.
