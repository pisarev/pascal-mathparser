{ ************************************************************************** }
{                                                                            }
{ DemoGuiCheck                                                               }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program DemoGuiCheck;

{$APPTYPE CONSOLE}
{$B-}

uses
  SysUtils, Windows, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Parser;

{ repeats the bExecuteClick handler of the corrected demo line for line }
var
  FParser: TJitParser;
  FXVariable, FYVariable: Integer;
  FRepeatCount: Integer;
  Script: TScript;
  Compiled: TJitScript;
  I: Integer;
  TickCount: Double;
  Formula: string;
begin
  FParser := TJitParser.Create(nil);
  try
    FParser.Cached := False;
    FParser.AddVariable('X', FXVariable);
    FParser.AddVariable('Y', FYVariable);
    FParser.StringToScript('1 + 2');
    FXVariable := Convert(FParser.ExecuteScript^, vtInteger).Signed32;
    FParser.StringToScript('3 + 4');
    FYVariable := Convert(FParser.ExecuteScript^, vtInteger).Signed32;
    Writeln('X = ', FXVariable, ', Y = ', FYVariable);
    Formula := 'X * (2 + 2)';
    FRepeatCount := 10000000;
    FParser.StringToScript(Formula, Script);
    Writeln('Formula: "', FParser.ScriptToString(Script), '"');
    FParser.OptimizeScript(Script);
    Writeln('Optimal formula: "', FParser.ScriptToString(Script), '"');
    Compiled := FParser.CompileScript(Script);
    try
      TickCount := GetTickCount;
      if Compiled.Ready then
        for I := 1 to FRepeatCount do Compiled.Execute
      else
        for I := 1 to FRepeatCount do FParser.ExecuteScript(Script);
      TickCount := GetTickCount - TickCount;
      if Compiled.Ready then
        Writeln('Execution mode: native machine code')
      else
        Writeln('Execution mode: interpreter (', Compiled.Reason, ')');
      Writeln('Repeat count: ', FRepeatCount);
      Writeln('Result: ', ValueToText(FParser.ExecuteScript(Script)^));
      Writeln('Execution time: ', Trunc(TickCount / 1000), ' seconds ', Round(Frac(TickCount / 1000) * 1000),
        ' milliseconds');
      { for comparison: the same count through the interpreter }
      TickCount := GetTickCount;
      for I := 1 to FRepeatCount do FParser.ExecuteScript(Script);
      TickCount := GetTickCount - TickCount;
      Writeln('Same loop through the interpreter: ', Trunc(TickCount / 1000), ' seconds ', Round(Frac(TickCount / 1000) * 1000),
        ' milliseconds');
    finally
      Compiled.Free;
    end;
    Script := nil;
  finally
    FParser.Free;
  end;
end.
