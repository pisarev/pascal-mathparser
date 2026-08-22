{ ************************************************************************** }
{                                                                            }
{ JitBench                                                                   }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program JitBench;

{$APPTYPE CONSOLE}
{$B-}

uses
  { The thread driver comes FIRST: units are initialised in the order they
    are listed, and Classes standing ahead of it gets to touch threading
    before the driver is up. }
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  Classes, SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Decoder,
  ParseJit.Executor, ParseJit.CodeGen, TestKit in 'TestKit.pas';

var
  P: TMathParser;
  XVar, YVar: Double;

{ difference check: the JIT executor must agree with the interpreter }
procedure DiffCase(const Formula: string);
var
  Script: TScript;
  Executor: TJitExecutor;
  A, B: Double;
begin
  Executor := TJitExecutor.Create(P);
  try
   try
    P.StringToScript(Formula, Script);
    if not Executor.Prepare(Script) then
    begin
      Writeln('  tier-down: ', Formula, '  [', Executor.Reason, ']');
      Flush(Output);
      Exit;
    end;
    A := GetDouble(P.ExecuteScript(Script)^);
    B := GetDouble(Executor.Execute);
    CheckDouble('diff: ' + Formula, B, A, 1E-9);
    Script := nil;
   except
     on E: Exception do Fail('diff: ' + Formula, E.ClassName + ': ' + E.Message);
   end;
  finally
    Executor.Free;
  end;
end;

procedure DumpCase(const Formula: string);
var
  Script: TScript;
  Executor: TJitExecutor;
begin
  Executor := TJitExecutor.Create(P);
  try
    P.StringToScript(Formula, Script);
    if Executor.Prepare(Script) then
    begin
      Writeln('steps for ', Formula, ':');
      Write(Executor.DumpSteps);
      Flush(Output);
    end
    else
      Writeln('prepare failed: ', Executor.Reason);
    Script := nil;
  finally
    Executor.Free;
  end;
end;

{
  A machine-readable report.

  The benchmark numbers are wanted in three places at once - the parser README,
  the accelerator README and the showcase page - and while each carried its own
  copy, all three showed a different run as the current one. Now the run writes
  a file and the texts take their numbers from it.

  The format is deliberately plain: name, nanoseconds before and after, number
  of repeats. The repeat count is in the report because it DIFFERS from row to
  row - the heavy chain runs half a million times, not a million - and a page
  promising "averaged over a million" was promising that on its behalf too.
}
var
  Rows: TStringList;

procedure Report(const Name: string; const Base, Fast: Double; const Count: Integer);
var
  Plain: TFormatSettings;
begin
  { TFormatSettings.Invariant arrived in Free Pascal only in 3.3.1. For an
    older compiler the same set is put together by hand: the one thing that
    matters here is a dot as the decimal separator. }
  {$IF Defined(FPC) and (FPC_FULLVERSION < 30301)}
  Plain := DefaultFormatSettings;
  Plain.DecimalSeparator := '.';
  Plain.ThousandSeparator := #0;
  {$ELSE}
  Plain := TFormatSettings.Invariant;
  {$IFEND}
  Rows.Add(Format('%s'#9'%.1f'#9'%.1f'#9'%d', [Name, Base, Fast, Count], Plain));
end;

procedure BenchCase(const Name, Formula: string; const Count: Integer);
var
  Script: TScript;
  Executor: TJitExecutor;
  I: Integer;
  T0: Int64;
  TInterp, TJit: Double;
begin
  Executor := TJitExecutor.Create(P);
  try
    P.StringToScript(Formula, Script);
    if not Executor.Prepare(Script) then
    begin
      Writeln(Format('%-26s tier-down [%s]', [Name, Executor.Reason]));
      Exit;
    end;
    P.ExecuteScript(Script);
    Executor.Execute;
    T0 := Now64;
    for I := 1 to Count do
    begin
      XVar := I * 0.001;
      P.ExecuteScript(Script);
    end;
    TInterp := Elapsed(T0);
    T0 := Now64;
    for I := 1 to Count do
    begin
      XVar := I * 0.001;
      Executor.Execute;
    end;
    TJit := Elapsed(T0);
    Writeln(Format('%-26s interp %8.1f ns   ir %8.1f ns   speedup %5.2fx',
      [Name, TInterp / Count * 1E9, TJit / Count * 1E9, TInterp / TJit]));
    Report('ir/' + Name, TInterp / Count * 1E9, TJit / Count * 1E9, Count);
    Flush(Output);
    Script := nil;
  finally
    Executor.Free;
  end;
end;

procedure NativeCase(const Formula: string);
var
  Script: TScript;
  Code: TJitCode;
  A, B: Double;
begin
  Code := TJitCode.Create(P);
  try
   try
    P.StringToScript(Formula, Script);
    if not Code.Compile(Script) then
    begin
      Writeln('  tier-down: ', Formula, '  [', Code.Reason, ']');
      Flush(Output);
      Exit;
    end;
    A := GetDouble(P.ExecuteScript(Script)^);
    B := Code.Execute;
    CheckDouble('native: ' + Formula + Format('  (%d bytes)', [Code.CodeSize]), B, A, 1E-9);
    Script := nil;
   except
     on E: Exception do Fail('native: ' + Formula, E.ClassName + ': ' + E.Message);
   end;
  finally
    Code.Free;
  end;
end;

procedure NativeBench(const Name, Formula: string; const Count: Integer);
var
  Script: TScript;
  Executor: TJitExecutor;
  Code: TJitCode;
  I: Integer;
  T0: Int64;
  TInterp, TIr, TNative: Double;
begin
  Executor := TJitExecutor.Create(P);
  Code := TJitCode.Create(P);
  try
    P.StringToScript(Formula, Script);
    if not Code.Compile(Script) then
    begin
      Writeln(Format('%-22s tier-down [%s]', [Name, Code.Reason]));
      Exit;
    end;
    Executor.Prepare(Script);
    P.ExecuteScript(Script);
    Code.Execute;
    T0 := Now64;
    for I := 1 to Count do
    begin
      XVar := I * 0.001;
      P.ExecuteScript(Script);
    end;
    TInterp := Elapsed(T0);
    T0 := Now64;
    for I := 1 to Count do
    begin
      XVar := I * 0.001;
      Executor.Execute;
    end;
    TIr := Elapsed(T0);
    T0 := Now64;
    for I := 1 to Count do
    begin
      XVar := I * 0.001;
      Code.Execute;
    end;
    TNative := Elapsed(T0);
    Writeln(Format('%-22s interp %7.1f   ir %7.1f   native %6.1f ns   speedup %5.2fx / %5.2fx',
      [Name, TInterp / Count * 1E9, TIr / Count * 1E9, TNative / Count * 1E9, TInterp / TNative, TIr / TNative]));
    Report('native/' + Name, TInterp / Count * 1E9, TNative / Count * 1E9, Count);
    Flush(Output);
    Script := nil;
  finally
    Code.Free;
    Executor.Free;
  end;
end;

var
  Failed: Integer;

begin
  Rows := TStringList.Create;
  P := TMathParser.Create(nil);
  try
    XVar := 2.5;
    YVar := 4;
    P.AddVariable('x', XVar);
    P.AddVariable('y', YVar);
    BeginSection('J2 diff: IR executor vs interpreter');
    DumpCase('2 + 2 * 2');
    DiffCase('2 + 2 * 2');
    DiffCase('x * 2 + 1');
    DiffCase('x * x * x * 3 + x * x * 2 + x * 7 + 11');
    DiffCase('sin(x) + sqrt(y)');
    DiffCase('sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)');
    DiffCase('(1 + 2) * (3 + 4)');
    DiffCase('10 - 2 - 3');
    DiffCase('x / 4 + y / 8');
    DiffCase('1 + 2 > 2');
    DiffCase('2 ** 3');
    DiffCase('8 // 3');
    DiffCase('x * 2 - 5');
    DiffCase('sqrt(sqrt(x))');
    DiffCase('42');
    DiffCase('-42');
    DiffCase('pi * 2');
    DiffCase('abs(0 - x) + frac(x) + int(x)');
    DiffCase('mean(1, 2, 3)');
    DiffCase('if(1, 2, 3)');
    DiffCase('Integer x + 1');
    Writeln;
    Writeln('--- J2 benchmark (ExecuteScript vs IR executor) ---');
    BenchCase('const 42', '42', 2000000);
    BenchCase('x * 2 + 1', 'x * 2 + 1', 2000000);
    BenchCase('polynomial deg3', 'x * x * x * 3 + x * x * 2 + x * 7 + 11', 1000000);
    BenchCase('heavy math chain', 'sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)', 500000);
    BenchCase('nested parentheses', '(x + 1) * (x + 2) * (x + 3)', 1000000);
    BeginSection('J3 diff: native code vs interpreter');
    NativeCase('2 + 2 * 2');
    NativeCase('x * 2 + 1');
    NativeCase('x * x * x * 3 + x * x * 2 + x * 7 + 11');
    NativeCase('(x + 1) * (x + 2) * (x + 3)');
    NativeCase('x / 4 + y / 8');
    NativeCase('10 - 2 - 3');
    NativeCase('x * 2 - 5');
    NativeCase('42');
    NativeCase('-42');
    NativeCase('(1 + 2) * (3 + 4)');
    NativeCase('x * y / 2 + x / y - 1');
    NativeCase('sin(x) + 1');
    NativeCase('sqrt(x) * 2');
    NativeCase('sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)');
    NativeCase('sqrt(sqrt(x))');
    NativeCase('abs(0 - x) + sqr(x)');
    NativeCase('sin(x * y) / cos(x + y)');
    NativeCase('mean(1, 2, 3)');
    Writeln;
    Writeln('--- J3 benchmark (interpreter vs IR executor vs native code) ---');
    NativeBench('x * 2 + 1', 'x * 2 + 1', 2000000);
    NativeBench('polynomial deg3', 'x * x * x * 3 + x * x * 2 + x * 7 + 11', 1000000);
    NativeBench('nested parentheses', '(x + 1) * (x + 2) * (x + 3)', 1000000);
    NativeBench('divisions', 'x / 4 + y / 8 + x / 2', 1000000);
    NativeBench('heavy math chain', 'sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)', 500000);
    NativeBench('sqrt nest', 'sqrt(sqrt(x))', 1000000);
    Failed := TestSummary;
  finally
    P.Free;
  end;
  if Failed > 0 then System.ExitCode := 1;
  {
    The report is written next to the executable: the showcase page and the
    README consistency check both take their numbers from here. One run, one
    source.
  }
  try
    Rows.SaveToFile(ChangeFileExt(ParamStr(0), '.tsv'));
  except
    on E: Exception do Writeln('the report was not written: ' + E.Message);
  end;
  Rows.Free;
end.
