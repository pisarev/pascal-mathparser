{ ************************************************************************** }
{                                                                            }
{ BenchParser                                                                }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program BenchParser;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils;

var
  P: TMathParser;
  XVar, YVar: Double;

procedure Report(const Name: string; const Ops: Int64; const Seconds: Double);
var
  PerOp: Double;
begin
  PerOp := Seconds / Ops * 1E9;
  Writeln(Format('%-34s %10.0f op/s  %10.1f ns/op  (%d ops, %.3f s)', [Name, Ops / Seconds, PerOp, Ops, Seconds]));
  Flush(Output);
end;

{ 1. Compilation: the full path from text to script (the parser caches are live) }
procedure BenchCompileCached(const Name, Formula: string; const Count: Integer);
var
  I: Integer;
  T0: Int64;
  Script: TScript;
begin
  P.StringToScript(Formula, Script);
  Script := nil;
  T0 := Now64;
  for I := 1 to Count do
  begin
    P.StringToScript(Formula, Script);
    Script := nil;
  end;
  Report(Name, Count, Elapsed(T0));
end;

{ 2. Compilation past the cache: new text every time (the template cache still catches some) }
procedure BenchCompileCold(const Name: string; const Count: Integer);
var
  I: Integer;
  T0: Int64;
  Script: TScript;
begin
  T0 := Now64;
  for I := 1 to Count do
  begin
    P.StringToScript(Format('%d + %d * x', [I, I + 1]), Script);
    Script := nil;
  end;
  Report(Name, Count, Elapsed(T0));
end;

{ 3. Running a prepared script - the main reference point for the JIT }
procedure BenchExecute(const Name, Formula: string; const Count: Integer);
var
  I: Integer;
  T0: Int64;
  Script: TScript;
  V: PValue;
begin
  P.StringToScript(Formula, Script);
  V := P.ExecuteScript(Script);
  T0 := Now64;
  for I := 1 to Count do
  begin
    XVar := I * 0.001;
    V := P.ExecuteScript(Script);
  end;
  Report(Name, Count, Elapsed(T0));
  if IsNaN(GetDouble(V^)) then Writeln('  (NaN guard)');
  Script := nil;
end;

{ 4. The full AsValue path: cached compilation, execution and a copy of the value }
procedure BenchAsValue(const Name, Formula: string; const Count: Integer);
var
  I: Integer;
  T0: Int64;
begin
  P.AsDouble(Formula);
  T0 := Now64;
  for I := 1 to Count do
  begin
    XVar := I * 0.001;
    P.AsDouble(Formula);
  end;
  Report(Name, Count, Elapsed(T0));
end;

{ 5. A script loop: one call is N turns inside the interpreter }
procedure BenchLoop(const Name: string; const Iterations, Repeats: Integer);
var
  I: Integer;
  T0: Int64;
  Script: TScript;
  Formula: string;
begin
  { the variable is created once, the counter is reset at the start of every run }
  P.AsDouble('new("bi", 0)');
  Formula := Format('set("bi", 0) + while(get("bi") < %d, set("bi", get("bi") + 1)) + get("bi")', [Iterations]);
  P.StringToScript(Formula, Script);
  if Round(GetDouble(P.ExecuteScript(Script)^)) < Iterations then
    Writeln('  WARNING: loop did not run to the end');
  T0 := Now64;
  for I := 1 to Repeats do P.ExecuteScript(Script);
  Report(Name, Int64(Iterations) * Repeats, Elapsed(T0));
  Script := nil;
end;

{ 6. Native Pascal - the ceiling the JIT is aiming at }
procedure BenchNative(const Count: Integer);
var
  I: Integer;
  T0: Int64;
  Acc, X: Double;
begin
  Acc := 0;
  T0 := Now64;
  for I := 1 to Count do
  begin
    X := I * 0.001;
    Acc := Acc + X * 2 + 1;
  end;
  Report('native: x * 2 + 1', Count, Elapsed(T0));
  if Acc = -1 then Writeln('  (guard)');
end;

procedure BenchNativeHeavy(const Count: Integer);
var
  I: Integer;
  T0: Int64;
  Acc, X: Double;
begin
  Acc := 0;
  T0 := Now64;
  for I := 1 to Count do
  begin
    X := I * 0.001;
    Acc := Acc + Sin(X) * Cos(X) + Sqrt(X) + Exp(X * 0.001) + Ln(X + 1);
  end;
  Report('native: heavy math chain', Count, Elapsed(T0));
  if Acc = -1 then Writeln('  (guard)');
end;

const
  HeavyFormula = 'sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)';
  PolyFormula  = 'x * x * x * 3 + x * x * 2 + x * 7 + 11';

begin
  P := TMathParser.Create(nil);
  try
    XVar := 1;
    YVar := 2;
    P.AddVariable('x', XVar);
    P.AddVariable('y', YVar);
    Writeln('=== BASELINE: MathParser interpreter (', {$IFDEF CPUX64}'x64'{$ELSE}'x86'{$ENDIF}, ') ===');
    Writeln;
    Writeln('-- Running a prepared script (ExecuteScript) --');
    BenchExecute('exec: x * 2 + 1', 'x * 2 + 1', 2000000);
    BenchExecute('exec: polynomial deg3', PolyFormula, 1000000);
    BenchExecute('exec: heavy math chain', HeavyFormula, 500000);
    BenchExecute('exec: constant 42', '42', 3000000);
    Writeln;
    Writeln('-- The full path (AsDouble: cache and execution) --');
    BenchAsValue('asval: x * 2 + 1', 'x * 2 + 1', 500000);
    BenchAsValue('asval: heavy math chain', HeavyFormula, 200000);
    Writeln;
    Writeln('-- Compilation --');
    BenchCompileCached('compile: cached x * 2 + 1', 'x * 2 + 1', 500000);
    BenchCompileCached('compile: cached heavy', HeavyFormula, 200000);
    BenchCompileCold('compile: template-cache miss', 50000);
    Writeln;
    Writeln('-- Script loops (turns per second) --');
    BenchLoop('loop: while counter', 10000, 20);
    Writeln;
    Writeln('-- Native Pascal (the JIT ceiling) --');
    BenchNative(20000000);
    BenchNativeHeavy(2000000);
  finally
    P.Free;
  end;
end.
