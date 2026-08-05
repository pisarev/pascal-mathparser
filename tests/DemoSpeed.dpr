{ ************************************************************************** }
{                                                                            }
{ DemoSpeed                                                                  }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program DemoSpeed;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils,
  Parser,
  ParseTypes,
  ValueTypes,
  ValueUtils,
  ParseJit.Parser,
  TestKit in 'TestKit.pas';

{ repeats the demo scenario: integer variables, compile, optimise, run in a loop }
procedure DemoCase(const Formula: string; const Count: Integer);
var
  P: TJitParser;
  Script: TScript;
  Compiled: TJitScript;
  XVariable, YVariable: Integer;
  I: Integer;
  T0: Int64;
  TInterp, TNative, A, B: Double;
begin
  P := TJitParser.Create(nil);
  try
    XVariable := 3;
    YVariable := 7;
    P.AddVariable('X', XVariable);
    P.AddVariable('Y', YVariable);
    P.StringToScript(Formula, Script);
    P.OptimizeScript(Script);
    Compiled := P.CompileScript(Script);
    try
      if not Compiled.Ready then
      begin
        Writeln(Format('%-28s tier-down [%s]', [Formula, Compiled.Reason]));
        Exit;
      end;
      A := GetDouble(P.ExecuteScript(Script)^);
      B := Compiled.Execute;
      CheckDouble('demo: ' + Formula, B, A, 1E-9);
      T0 := Now64;
      for I := 1 to Count do P.ExecuteScript(Script);
      TInterp := Elapsed(T0);
      T0 := Now64;
      for I := 1 to Count do Compiled.Execute;
      TNative := Elapsed(T0);
      Writeln(Format('%-28s interp %8.1f ns   native %6.1f ns   speedup %6.2fx',
        [Formula, TInterp / Count * 1E9, TNative / Count * 1E9, TInterp / TNative]));
      Flush(Output);
    finally
      Compiled.Free;
    end;
    Script := nil;
  finally
    P.Free;
  end;
end;

var
  Failed: Integer;

begin
  BeginSection('Demo scenario: integer variables, compiled script in a loop');
  DemoCase('X + Y', 2000000);
  DemoCase('X * 2 + Y * 3', 2000000);
  DemoCase('(X + Y) * (X - Y) / 2', 1000000);
  DemoCase('sin(X) * cos(Y) + sqrt(X * X + Y * Y)', 500000);
  DemoCase('X * X * X * 3 + X * X * 2 + X * 7 + 11', 1000000);
  DemoCase('if(X > Y, X * 2, Y * 2)', 1000000);
  Failed := TestSummary;
  if Failed > 0 then System.ExitCode := 1;
end.
