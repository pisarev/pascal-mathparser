{ ************************************************************************** }
{                                                                            }
{ JitParserTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program JitParserTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  { The thread driver comes FIRST: units start up in the order they are declared, and
    Classes, standing earlier, gets to touch threads before it. }
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  Classes, SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Decoder,
  ParseJit.CodeGen, ParseJit.Parser, TestKit in 'TestKit.pas';

var
  Base: TMathParser;
  Jit: TJitParser;
  XBase, XJit: Double;
  UBase, UJit: LongWord;

procedure SameCase(const Formula: string);
var
  A, B: Double;
begin
  try
    XBase := 2.5;
    XJit := 2.5;
    A := Base.AsDouble(Formula);
    B := Jit.AsDouble(Formula);
    CheckDouble('asdouble: ' + Formula, B, A, 1E-9);
  except
    on E: Exception do Fail('asdouble: ' + Formula, E.ClassName + ': ' + E.Message);
  end;
end;

procedure BenchAsDouble(const Name, Formula: string; const Count: Integer);
var
  I: Integer;
  T0: Int64;
  TBase, TJit: Double;
begin
  Base.AsDouble(Formula);
  Jit.AsDouble(Formula);
  T0 := Now64;
  for I := 1 to Count do
  begin
    XBase := I * 0.001;
    Base.AsDouble(Formula);
  end;
  TBase := Elapsed(T0);
  T0 := Now64;
  for I := 1 to Count do
  begin
    XJit := I * 0.001;
    Jit.AsDouble(Formula);
  end;
  TJit := Elapsed(T0);
  Writeln(Format('%-24s base %8.1f ns   jit %7.1f ns   speedup %6.2fx',
    [Name, TBase / Count * 1E9, TJit / Count * 1E9, TBase / TJit]));
  Flush(Output);
end;

{
  A machine-readable report in the same format as JitBench: name, nanoseconds before
  and after, number of repeats. The showcase page takes the numbers from here rather
  than keeping a copy of its own: three copies from different runs once diverged,
  and all three were served as the current ones.
}
var
  Rows: TStringList;

procedure Report(const Name: string; const Base, Fast: Double; const Count: Integer);
var
  Plain: TFormatSettings;
begin
  if not Assigned(Rows) then Exit;
  {
    TFormatSettings.Invariant appeared in Free Pascal only in 3.3.1. For an older
    compiler the same set is built by hand: what matters here is a single property,
    the dot as the separator of the fractional part.

  }
  {$IF Defined(FPC) and (FPC_FULLVERSION < 30301)}
  Plain := DefaultFormatSettings;
  Plain.DecimalSeparator := '.';
  Plain.ThousandSeparator := #0;
  {$ELSE}
  Plain := TFormatSettings.Invariant;
  {$IFEND}
  Rows.Add(Format('%s'#9'%.1f'#9'%.1f'#9'%d', [Name, Base, Fast, Count], Plain));
end;

procedure BenchLoop(const Formula: string; const Repeats, Iterations: Integer);
var
  I: Integer;
  T0: Int64;
  TBase, TJit: Double;
begin
  Base.AsDouble(Formula);
  Jit.AsDouble(Formula);
  T0 := Now64;
  for I := 1 to Repeats do Base.AsDouble(Formula);
  TBase := Elapsed(T0);
  T0 := Now64;
  for I := 1 to Repeats do Jit.AsDouble(Formula);
  TJit := Elapsed(T0);
  Writeln(Format('loop iteration           base %8.1f ns   jit %7.1f ns   speedup %6.2fx',
    [TBase / Repeats / Iterations * 1E9, TJit / Repeats / Iterations * 1E9, TBase / TJit]));
  Report(Format('native/loop, %d iterations', [Iterations]), TBase / Repeats * 1E9,
    TJit / Repeats * 1E9, Repeats);
  Flush(Output);
end;

procedure BenchBulk(const Formula: string; const Count: Integer);
var
  Inputs, Outputs: array of Double;
  I: Integer;
  T0: Int64;
  TBase, TBulk: Double;
  OK: Boolean;
begin
  SetLength(Inputs, Count);
  SetLength(Outputs, Count);
  for I := 0 to Count - 1 do Inputs[I] := (I + 1) * 0.001;
  T0 := Now64;
  for I := 0 to Count - 1 do
  begin
    XBase := Inputs[I];
    Outputs[I] := Base.AsDouble(Formula);
  end;
  TBase := Elapsed(T0);
  T0 := Now64;
  OK := Jit.ExecuteMany(Formula, XJit, Inputs, Outputs);
  TBulk := Elapsed(T0);
  Check('bulk executed', OK);
  Writeln(Format('%-24s base %8.1f ns   bulk %7.1f ns   speedup %6.2fx',
    ['bulk: ' + Formula, TBase / Count * 1E9, TBulk / Count * 1E9, TBase / TBulk]));
  Report('bulk/' + Formula, TBase / Count * 1E9, TBulk / Count * 1E9, Count);
  Flush(Output);
end;

{ a generator of random arithmetic formulas for mass comparison }
function RandomFormula(const Depth: Integer): string;
var
  Kind: Integer;
const
  Ops: array[0..3] of string = (' + ', ' - ', ' * ', ' / ');
  Funcs: array[0..4] of string = ('sin', 'cos', 'sqrt', 'abs', 'sqr');
begin
  if Depth <= 0 then
    Kind := Random(3)
  else
    Kind := Random(6);
  case Kind of
    0: Result := IntToStr(Random(20) + 1);
    1: Result := 'x';
    2: Result := 'y';
    3: Result := '(' + RandomFormula(Depth - 1) + Ops[Random(4)] + RandomFormula(Depth - 1) + ')';
    4: Result := Funcs[Random(5)] + '(' + RandomFormula(Depth - 1) + ')';
  else
    Result := RandomFormula(Depth - 1) + Ops[Random(4)] + RandomFormula(Depth - 1);
  end;
end;

procedure FuzzDiff(const Count: Integer);
var
  I, Compiled, Declined, Raised, Errors: Integer;
  Formula: string;
  A, B: Double;
  {$IFNDEF CPUX64}
  Taken: Int64;
  {$ENDIF}
begin
  RandSeed := 20260720;
  Compiled := 0;
  Declined := 0;
  Raised := 0;
  Errors := 0;
  for I := 1 to Count do
  begin
    Formula := RandomFormula(3);
    try
      XBase := 1.5 + I * 0.01;
      XJit := XBase;
      A := Base.AsDouble(Formula);
      {$IFDEF CPUX64}
      if Jit.CodeReason(Formula) <> '' then
      begin
        { a refusal from the accelerator is ordinary and not an error: it does not take everything }
        Inc(Declined);
        Continue;
      end;
      B := Jit.AsDouble(Formula);
      Inc(Compiled);
      {$ELSE}
      { Outside x86-64 CodeReason is NEVER empty: there is no machine code here at all.
        Filtering by it is not allowed, the comparison would not happen once, and a set of
        three thousand formulas would keep quiet and report green.

        The level is taken from the counter of the interpreter rather than the executor:
        the set of formulas is small and repeats are frequent, while ExecutorCount grows
        only on the first compilation, and on repeats that is a cache hit. By it the
        accelerator appeared to have taken 1426 out of 3000, while the ones it did not
        take were only 31. }
      Taken := Jit.MissCount;
      B := Jit.AsDouble(Formula);
      if Jit.MissCount > Taken then
      begin
        Inc(Declined);
        Continue;
      end;
      Inc(Compiled);
      {$ENDIF}
      if IsNaN(A) and IsNaN(B) then Continue;
      if IsInfinite(A) and IsInfinite(B) then Continue;
      if not SameValue(A, B, Max(Abs(A), 1) * 1E-12) then
      begin
        Inc(Errors);
        if Errors <= 5 then
          Writeln(Format('  MISMATCH %s: base=%.17g jit=%.17g', [Formula, A, B]));
      end;
    except
      {
        A throw is NOT a skip. It used to be counted together with refusals from the
        accelerator, and in the common heap it meant nothing: a formula the interpreter
        answers and the accelerator falls over on is a discrepancy, not a "did not take".

      }
      on E: Exception do
      begin
        Inc(Raised);
        if Raised <= 5 then
          Writeln(Format('  RAISED %s: %s', [Formula, E.Message]));
      end;
    end;
  end;
  Check(Format('fuzz diff: %d compiled, %d declined, %d raised, %d mismatches', [Compiled, Declined, Raised, Errors]), Errors = 0);
  {
    A floor under the number compiled. Without it the set is worth nothing: if the
    accelerator stops taking formulas at all, Compiled becomes zero, there will be no
    discrepancies at all, and the check will stay green, reporting success where
    nothing has been checked.

    Half, with a wide margin downwards: today's run takes all three thousand out of
    three thousand. The floor guards against a collapse, not against fluctuation.

  }
  {$IFDEF CPUX64}
  Check(Format('at least half of the formulas reached machine code (%d of %d)', [Compiled, Count]),
    Compiled * 2 >= Count);
  {$ELSE}
  Check(Format('at least half of the formulas were answered by the accelerator (%d of %d)', [Compiled, Count]),
    Compiled * 2 >= Count);
  {$ENDIF}
  Check(Format('nothing raised where the interpreter answered (%d)', [Raised]), Raised = 0);
end;

var
  Failed: Integer;
  Inputs, Outputs: array of Double;
  I: Integer;

begin
  Rows := TStringList.Create;
  Base := TMathParser.Create(nil);
  Jit := TJitParser.Create(nil);
  try
    XBase := 2.5;
    XJit := 2.5;
    Base.AddVariable('x', XBase);
    Jit.AddVariable('x', XJit);
    BeginSection('J4: TJitParser gives the same answers');
    SameCase('x * 2 + 1');
    SameCase('x * x * x * 3 + x * x * 2 + x * 7 + 11');
    SameCase('sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)');
    SameCase('(x + 1) * (x + 2) * (x + 3)');
    SameCase('42');
    SameCase('x / 4');
    SameCase('mean(1, 2, 3)');
    SameCase('if(x > 0, x * 2, 0 - x)');
    SameCase('1 + 2 > 2');
    SameCase('2 ** 3');
    BeginSection('J4: bulk mode correctness');
    SetLength(Inputs, 5);
    SetLength(Outputs, 5);
    for I := 0 to 4 do Inputs[I] := I + 1;
    Check('bulk supported', Jit.ExecuteMany('x * 10 + 1', XJit, Inputs, Outputs));
    Check('bulk values', (Abs(Outputs[0] - 11) < 1E-9) and (Abs(Outputs[4] - 51) < 1E-9),
      Format('%.1f..%.1f', [Outputs[0], Outputs[4]]));
    {
      What used to stand here was "if you cannot do it, do not compute": a formula the
      accelerator refuses was not computed at all. That turned out to be harmful, the
      ordinary parse computes it perfectly well, and the caller got a "no" about a
      formula the same parser answers a line below.

      The new contract: True means "the answers are filled in", by whatever they were
      computed. Both that and the match with the ordinary parse are checked: a departure
      that gives a DIFFERENT answer is worse than no departure.

    }
    Check('the accelerator does decline this one', Jit.CodeReason('mean(1, 2, x)') <> '',
      Jit.CodeReason('mean(1, 2, x)'));
    Check('bulk computes it anyway', Jit.ExecuteMany('mean(1, 2, x)', XJit, Inputs, Outputs));
    for I := 0 to 4 do
    begin
      XBase := Inputs[I];
      Check(Format('bulk answer %d matches the ordinary parser', [I]),
        Abs(Outputs[I] - Base.AsDouble('mean(1, 2, x)')) < 1E-9, Format('%.6f', [Outputs[I]]));
    end;
    {
      A formula that does not parse at all, however, has to be rejected, and it has to
      LEAVE NO earlier numbers in the answers: a computation that did not happen, with
      somebody else's numbers, looks like one that did.

    }
    Check('bulk refuses a formula that does not parse',
      not Jit.ExecuteMany('mean(1, 2, ', XJit, Inputs, Outputs));
    for I := 0 to 4 do
      Check(Format('answer %d is not left over from before', [I]), IsNaN(Outputs[I]),
        Format('%.6f', [Outputs[I]]));
    BeginSection('J5: control flow and script variables');
    Base.AsDouble('new("k", 0)');
    Jit.AsDouble('new("k", 0)');
    XBase := 3;
    XJit := 3;
    SameCase('if(x > 2, 10, 20)');
    SameCase('if(x > 5, 10, 20)');
    SameCase('if(x > 2, x * 2, 0 - x)');
    SameCase('set("k", 7) + get("k")');
    SameCase('set("k", 0) + while(get("k") < 5, set("k", get("k") + 1)) + get("k")');
    SameCase('set("k", 0) + while(get("k") < 100, set("k", get("k") + 2)) + get("k")');
    SameCase('set("k", 0) + repeat(set("k", get("k") + 1), get("k") >= 4) + get("k")');
    SameCase('MaxInt64 - 1');
    SameCase('x >= 3');
    SameCase('x <= 2');
    SameCase('x <> 3');
    Writeln('  reasons: if -> "', Jit.CodeReason('if(x > 2, 10, 20)'), '"; while -> "',
      Jit.CodeReason('set("k", 0) + while(get("k") < 5, set("k", get("k") + 1)) + get("k")'),
      '"; get -> "', Jit.CodeReason('get("k")'), '"');
    BeginSection('J5: unsigned and typed variables');
    Base.AddVariable('uw', UBase);
    Jit.AddVariable('uw', UJit);
    UBase := 4000000000;
    UJit := UBase;
    SameCase('uw / 2');
    SameCase('uw + 1');
    UBase := 7;
    UJit := 7;
    SameCase('uw * 3');
    BeginSection('J4: fuzz diff on generated formulas');
    Jit.AddVariable('y', XJit);
    Base.AddVariable('y', XBase);
    FuzzDiff(3000);
    BeginSection('J4: cache invalidation on registry change');
    XJit := 3;
    CheckDouble('before registry change', Jit.AsDouble('x * 2'), 6);
    Jit.AddConstant('jitconst', 7);
    { 'stale' is a word the engine never says, so the old form of this check
      could not fail. The contract is that the code is rebuilt after the
      registry changes, which means no reason at all on x86-64. }
    {$IFDEF CPUX64}
    Check('code rebuilt after notification', Jit.CodeReason('x * 2') = '',
      Format('  reason="%s"', [Jit.CodeReason('x * 2')]));
    {$ELSE}
    Check('reason is reported off x86-64', Jit.CodeReason('x * 2') <> '');
    {$ENDIF}
    CheckDouble('after registry change', Jit.AsDouble('x * 2 + jitconst'), 13);
    CheckDouble('old formula still fine', Jit.AsDouble('x * 2'), 6);
    Writeln;
    Writeln('--- J4 benchmark: full AsDouble path ---');
    BenchAsDouble('x * 2 + 1', 'x * 2 + 1', 500000);
    BenchAsDouble('polynomial deg3', 'x * x * x * 3 + x * x * 2 + x * 7 + 11', 500000);
    BenchAsDouble('heavy math chain', 'sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)', 300000);
    Writeln;
    Writeln('--- J5 benchmark: script loop (10000 iterations per call) ---');
    BenchLoop('set("k", 0) + while(get("k") < 10000, set("k", get("k") + 1))', 20, 10000);
    Writeln;
    Writeln('--- J4 benchmark: bulk mode ---');
    BenchBulk('x * 2 + 1', 500000);
    BenchBulk('x * x * x * 3 + x * x * 2 + x * 7 + 11', 500000);
    Writeln;
    Writeln(Format('jit stats: compiles=%d hits=%d misses=%d inline=%d lookups=%d',
      [Jit.CompileCount, Jit.HitCount, Jit.MissCount, Jit.InlineCount, Jit.LookupCount]));
    Writeln('tier-down reasons: mean -> ', Jit.CodeReason('mean(1, 2, 3)'), '; if -> ',
      Jit.CodeReason('if(x > 0, x * 2, 0 - x)'));
    Failed := TestSummary;
  finally
    Jit.Free;
    Base.Free;
  end;
  if Failed > 0 then System.ExitCode := 1;
  try
    if Assigned(Rows) then
      Rows.SaveToFile(ChangeFileExt(ParamStr(0), '.tsv'));
  except
    on E: Exception do Writeln('the report was not written: ' + E.Message);
  end;
  Rows.Free;
end.
