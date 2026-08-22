{ ************************************************************************** }
{                                                                            }
{ JitContractTest                                                            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program JitContractTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueUtils, ParseJit.Parser, ParseJit.CodeGen,
  TestKit in 'TestKit.pas';

{
  What this file guards, and why it exists.

  Every other JIT test compares the answer of the accelerator against the answer
  of the interpreter. That is a weak contract: when the accelerator silently
  declines a formula, the interpreter answers instead, the value is still right,
  and the test stays green. A whole class of defects hides in that gap, and one
  of them lived there for years: the cache entry recorded the parser generation
  before the script was compiled, the first compilation raised the generation,
  and so the first formula of every parser was stuck on the interpreter forever.

  These checks assert the contract itself: that machine code really ran, that a
  declined formula says why in a word the code actually produces, and that
  invalidation still rebuilds. They must be the first thing a fresh parser does,
  because that is the only state in which the defect above was visible.
}

const
  { The whole vocabulary the JIT layer can produce, taken from every Reject and
    Reason assignment in it. A check written against a word outside this list is
    vacuous: it can never fail, however broken the engine is. One such check did
    exist here, comparing against 'stale', a word the code never says.

    Entries ending in a space are prefixes: the engine appends a name to them. }
  KnownReasons: array[0..41] of string = (
    '', 'parser changed', 'ir executor', 'ir executor: ', 'no code', 'not decoded: ',
    'x86-64 only', 'no script or parser', 'empty script',
    'unsupported element', 'unsupported method kind ',
    'parametric ', 'parametric function ',
    'unbound variable ', 'unknown variable ', 'variable type of ',
    'unresolved call', 'unknown function handle ', 'unknown element code ',
    'explicit item type', 'broken item header', 'item size mismatch',
    'script size mismatch', 'unexpected element in term',
    'code generation failed', 'code layout is broken', 'code buffer overflow', 'cannot describe stack frame',
    'no executable memory', 'cannot protect code', 'stack frame is too deep',
    'binary call ', 'call ', 'operand kind', 'parameter block expected',
    'parameter shape', 'redirect loop', 'string constant',
    'integer constant out of exact range', 'if arity',
    'get needs a literal name', 'set needs a literal name');

function ReasonIsKnown(const Reason: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(KnownReasons) to High(KnownReasons) do
    if (Reason = KnownReasons[I]) or ((KnownReasons[I] <> '') and (Pos(KnownReasons[I], Reason) = 1)) then
      Exit(True);
end;

{$IFDEF CPUX64}
  {$DEFINE COMPILES_TO_MACHINE_CODE}
{$ENDIF}

procedure FirstFormulaOnAFreshParser;
var
  P: TJitParser;
  X, Value: Double;
begin
  BeginSection('a formula on a parser that has done nothing else');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    Value := P.AsDouble('x * x * 3 + 1');
    CheckDouble('the answer is right', Value, 13);
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    Check('the very first formula ran as machine code', P.HitCount = 1,
      Format('  hits=%d misses=%d reason="%s"', [P.HitCount, P.MissCount, P.CodeReason('x * x * 3 + 1')]));
    Check('nothing was handed back to the interpreter', P.MissCount = 0,
      Format('  misses=%d', [P.MissCount]));
    Check('a compiled formula reports no reason', P.CodeReason('x * x * 3 + 1') = '',
      Format('  reason="%s"', [P.CodeReason('x * x * 3 + 1')]));
    {$ELSE}
    { Not the interpreter: the IR executor. This branch said "interpreter" from
      the days before that tier existed, and nothing re-ran it - there was no
      32-bit matrix. The demand here is stronger than the old one, not weaker:
      the call is accelerated, and not one of them falls back. }
    Check('off x86-64 the IR executor answers, and nothing falls back',
      (P.HitCount = 1) and (P.MissCount = 0) and (P.MachineCount = 0) and (P.ExecutorCount = 1),
      Format('  hits=%d misses=%d machine=%d executor=%d', [P.HitCount, P.MissCount, P.MachineCount, P.ExecutorCount]));
    {$ENDIF}
  finally
    P.Free;
  end;
end;

procedure RepeatingItKeepsTheCode;
var
  P: TJitParser;
  X: Double;
  I: Integer;
begin
  BeginSection('repeating the same formula');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    for I := 1 to 5 do P.AsDouble('x * 2 + 1');
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    { A cache entry that was written off once is never retried, so a single
      early decline would show up here as five misses rather than one. }
    Check('all five calls used the compiled code', P.HitCount = 5,
      Format('  hits=%d misses=%d', [P.HitCount, P.MissCount]));
    {$ELSE}
    Check(
      'off x86-64 all five calls went to the IR executor',
      (P.HitCount = 5) and (P.MissCount = 0) and (P.MachineCount = 0),
      Format(
        '  hits=%d misses=%d machine=%d executor=%d',
        [
          P.HitCount,
          P.MissCount,
          P.MachineCount,
          P.ExecutorCount
        ]
      )
    );
    {$ENDIF}
  finally
    P.Free;
  end;
end;

procedure BulkAsTheVeryFirstCall;
var
  P: TJitParser;
  X: Double;
  Inputs, Outputs: array of Double;
  Ok: Boolean;
begin
  BeginSection('bulk evaluation as the first thing asked of the parser');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    SetLength(Inputs, 3);
    SetLength(Outputs, 3);
    Inputs[0] := 1;
    Inputs[1] := 2;
    Inputs[2] := 4;
    { ExecuteMany is the only entry point that reports a decline to the caller.
      When it returns False it leaves the output array untouched, so a caller
      who trusts it gets zeros rather than numbers. }
    Ok := P.ExecuteMany('x * x * 3 + 1', X, Inputs, Outputs);
    { Bulk once declined where there was no emitter, and this check demanded the
      decline. The IR executor took bulk over since, so the demand is now the
      same on every target: accepted, and the outputs written. }
    Check('bulk evaluation was accepted', Ok);
    CheckDouble('the last output was written', Outputs[2], 49);
    CheckDouble('the first output was written', Outputs[0], 4);
  finally
    P.Free;
  end;
end;

procedure ADeclinedFormulaSaysWhy;
var
  P: TJitParser;
  X, Value: Double;
  Reason: string;
begin
  BeginSection('a formula the accelerator does not take');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    Reason := P.CodeReason('mean(1, 2, x)');
    Value := P.AsDouble('mean(1, 2, x)');
    CheckDouble('the interpreter still answers', Value, 5 / 3);
    Check('the decline is reported', Reason <> '', Format('  reason="%s"', [Reason]));
    Check('the reason is a word the code can produce', ReasonIsKnown(Reason),
      Format('  reason="%s" is outside the vocabulary', [Reason]));
    Check('the decline was counted', P.MissCount > 0, Format('  misses=%d', [P.MissCount]));
  finally
    P.Free;
  end;
end;

procedure EveryReasonComesFromTheVocabulary;
const
  Probes: array[0..5] of string = (
    'x * 2 + 1', 'mean(1, 2, 3)', 'if(x > 0, x, 0 - x)',
    'get("k")', 'parse("2 + 2")', 'sin(x) + sqrt(2)');
var
  P: TJitParser;
  X: Double;
  I: Integer;
  Reason: string;
begin
  BeginSection('the reason vocabulary is closed');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    for I := Low(Probes) to High(Probes) do
    begin
      Reason := P.CodeReason(Probes[I]);
      Check('reason for ' + Probes[I] + ' is known', ReasonIsKnown(Reason),
        Format('  reason="%s"', [Reason]));
    end;
  finally
    P.Free;
  end;
end;

procedure RegisteringSomethingNewRebuildsTheCode;
var
  P: TJitParser;
  X, Y: Double;
  Before: Int64;
begin
  BeginSection('registering a variable after the first evaluation');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    P.AsDouble('x * 2 + 1');
    Before := P.Generation;
    { Registration invalidates the cache on purpose. The point of this check is
      that the code comes back afterwards: an entry must not be left in the list
      with a generation that can never match again. }
    P.AddVariable('y', Y);
    Y := 3;
    Check('the generation moved on', P.Generation <> Before,
      Format('  before=%d after=%d', [Before, P.Generation]));
    CheckDouble('the old formula still answers', P.AsDouble('x * 2 + 1'), 5);
    CheckDouble('the new variable is visible', P.AsDouble('x + y'), 5);
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    Check('both formulas run as machine code again', P.CodeReason('x * 2 + 1') = '',
      Format('  reason="%s"', [P.CodeReason('x * 2 + 1')]));
    {$ENDIF}
  finally
    P.Free;
  end;
end;

procedure TurningTheAcceleratorOff;
var
  P: TJitParser;
  X: Double;
begin
  BeginSection('the accelerator switched off');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    P.JitEnabled := False;
    CheckDouble('the answer is unchanged', P.AsDouble('x * 2 + 1'), 5);
    Check('nothing was compiled while off', P.HitCount = 0, Format('  hits=%d', [P.HitCount]));
    P.JitEnabled := True;
    CheckDouble('and again with it on', P.AsDouble('x * 2 + 1'), 5);
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    Check('the code is used once it is back on', P.HitCount > 0, Format('  hits=%d', [P.HitCount]));
    {$ENDIF}
  finally
    P.Free;
  end;
end;

procedure ACrampedBufferIsRefused;
var
  P: TJitParser;
  X: Double;
  Answer: Double;
  Limit: NativeInt;
  Slipped: NativeInt;
  Wrong: NativeInt;
  Reason: string;
begin
  BeginSection('a cramped code buffer');
  {
    The emitters used to give up in silence when the buffer ran out: a byte
    array was written half way, an eight byte constant not at all, and the size
    stopped moving. The verdict was then taken from the room that was left -
    "size below capacity" - which is a different question from "did everything
    fit". A run that stops two bytes short of an instruction passes the first
    question and fails the second, and the truncated code was marked ready and
    called.

    One cramped size proves nothing: most of them end exactly at the brim and
    the old test caught those by luck. So every size in a range is tried, and
    the demand is the same for all of them - no size may end with the formula
    running as machine code. Under the old verdict some of them do.
  }
  Slipped := 0;
  Wrong := 0;
  for Limit := 8 to 400 do
  begin
    P := TJitParser.Create(nil);
    try
      P.AddVariable('x', X);
      X := 3;
      TJitCode.TestCapacity := Limit;
      try
        Answer := P.AsDouble('x * 2 + 1');
        Reason := P.CodeReason('x * 2 + 1');
      finally
        TJitCode.TestCapacity := 0;
      end;
      if Abs(Answer - 7) > 1E-9 then Inc(Wrong);
      if Reason = '' then Inc(Slipped);
    finally
      P.Free;
    end;
  end;
  {
    Two demands, and neither is "it must decline". Sizes above the length of
    this formula hold the whole of it, and declining there would be a defect of
    its own; the range deliberately spans both sides of that boundary.

    What must hold everywhere: the answer is right, and the process is still
    alive to report it. Under the old verdict this loop does not reach its end
    at all - it dies on an access violation, because a formula whose code was
    cut short mid instruction was called anyway. That is the whole finding,
    and the run completing is what proves it fixed.

    The third demand keeps the check honest: at least one size must decline,
    otherwise the limit did nothing and the loop measured nothing.
  }
  Check('every size answers correctly', Wrong = 0, Format('  wrong answers=%d', [Wrong]));
  Check('cramped sizes are refused rather than run', Slipped < 393,
    Format('  sizes that compiled=%d of 393', [Slipped]));
  {$IFDEF COMPILES_TO_MACHINE_CODE}
  Check('the limit was actually reached', Slipped > 0, Format('  sizes that compiled=%d', [Slipped]));
  {$ELSE}
  { Where there is no emitter the limit has nothing to cut, so the third demand
    turns into its opposite - and stays a demand: not one size may claim machine
    code. The first two hold unchanged. }
  Check('off x86-64 no size reaches machine code', Slipped = 0,
    Format('  sizes that compiled=%d', [Slipped]));
  {$ENDIF}
end;

procedure AVariableWiderThanDouble;
var
  P: TJitParser;
  Wide: Extended;
  Reason: string;
begin
  BeginSection('a variable of type Extended');
  {
    Extended is not the same width everywhere. On Win64 it is eight bytes and
    identical to Double; a 32-bit Free Pascal build gives the eighty bit type of
    the x87 unit and occupies ten - on Linux and on Windows alike. The emitter
    used to load such a variable with
    movsd - eight bytes - in both cases. Where the type is wider that reads the
    mantissa alone and calls it a number: not a rounding difference, a different
    value entirely.

    The IR executor never had the problem: it reads the variable as PExtended.
    So the contract is per platform, and the check asks for the platform it is
    running on rather than for one answer that would be wrong somewhere.
  }
  P := TJitParser.Create(nil);
  try
    P.AddVariable('w', Wide);
    Wide := 0.1;
    CheckDouble('a tenth comes back as a tenth', P.AsDouble('w * 10'), 1);
    Wide := 3.14159265358979;
    CheckDouble('and pi comes back as pi', P.AsDouble('w + 0'), 3.14159265358979);
    Reason := P.CodeReason('w * 10');
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    if SizeOf(Extended) = SizeOf(Double) then
      Check('where Extended is eight bytes machine code takes it', Reason = '',
        '  reason=' + Reason)
    else
      Check('where Extended is wider machine code declines it', Pos('variable type', Reason) > 0,
        Format('  SizeOf(Extended)=%d reason=%s', [SizeOf(Extended), Reason]));
    {$ELSE}
    { Where there is no emitter at all the decline is reported a level higher and
      the width of the variable never comes up. Both answers above were still
      right, and on this platform that is the whole of the contract. }
    Check('off x86-64 the reason names the missing emitter, not the variable',
      (Reason <> '') and (Pos('variable type', Reason) = 0),
      Format('  SizeOf(Extended)=%d reason=%s', [SizeOf(Extended), Reason]));
    {$ENDIF}
  finally
    P.Free;
  end;
end;

procedure NoSpareExecutorBesideWorkingCode;
var
  P: TJitParser;
  X: Double;
  I: Integer;
begin
  BeginSection('one tier per formula');
  {
    A formula that compiled to machine code has no use for the IR executor, and
    building one costs a second decode and a second object on every formula the
    parser ever sees.

    It was built all the same. The cache entry took the parser generation AFTER
    the question "is this ready", and Ready compares generations: the entry
    still carried zero, the parser was past one, so the answer was "stale" and
    the fall back was prepared for a formula that needed nothing. Measured on a
    fresh parser and five formulas: five machine codes and five executors.

    CompileScript, the other way into the same work, took the generation first
    and was right the whole time. Two paths, two lines apart.

    The counters this check reads exist because HitCount cannot answer the
    question: an entry that fell back to the executor counts as a hit exactly
    like one that runs machine code.
  }
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2;
    for I := 1 to 5 do P.AsDouble(Format('x * %d + 1', [I]));
    Check('every formula was compiled once', P.CompileCount = 5, Format('  compiled=%d', [P.CompileCount]));
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    Check('all five reached machine code', P.MachineCount = 5, Format('  machine=%d', [P.MachineCount]));
    Check('and none of them got a spare executor', P.ExecutorCount = 0,
      Format('  executors=%d', [P.ExecutorCount]));
    {$ELSE}
    Check('without machine code every formula gets the executor', P.ExecutorCount = 5,
      Format('  executors=%d', [P.ExecutorCount]));
    {$ENDIF}
  finally
    P.Free;
  end;
end;

{
  Bulk evaluation must answer or say it did not.

  Two things were wrong with it, and the second is the dangerous one.

  It computed nothing at all for a formula the accelerator declines - and it
  declines a whole family of them, the parametric ones like Max and Sum, which
  the ordinary parser evaluates without trouble. The caller was told "no" about
  a formula the very same parser answers on the next line.

  And on that "no" it left the output array exactly as the previous call had
  filled it. A caller who does not check the result reads the previous
  formula's numbers, and they look entirely plausible: in the probe that found
  this, Max(x, 2) "answered" with a 20 left over from an If.
}
procedure BulkAnswersOrSaysItDidNot;
var
  P: TJitParser;
  X: Double;
  Inputs: array[0..2] of Double;
  Outputs: array[0..2] of Double;
  Plain: array[0..2] of Double;
  Short: array[0..1] of Double;
  Long: array[0..4] of Double;
  Script: TScript;
  Hits: Int64;
  I: Integer;
  Ok: Boolean;
begin
  BeginSection('bulk evaluation');
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);
    for I := 0 to 2 do Inputs[I] := I + 1;
    { First a formula the accelerator takes: the array is filled with numbers }
    Check('an accepted formula is computed', P.ExecuteMany('x * 10', X, Inputs, Outputs));
    CheckDouble('and the first answer is right', Outputs[0], 10);
    {
      Now the one it refuses. What is checked is not only that it computed, but also
      that the result matches the ordinary parse: a departure that gives a different
      answer is worse than no departure.

    }
    Hits := P.HitCount;
    Ok := P.ExecuteMany('Max(x, 2)', X, Inputs, Outputs);
    Check('a formula the accelerator declines is computed anyway', Ok);
    Check('the accelerator did decline it', Pos('parametric', P.CodeReason('Max(x, 2)')) > 0,
      P.CodeReason('Max(x, 2)'));
    Script := nil;
    P.StringToScript('Max(x, 2)', Script);
    for I := 0 to 2 do
    begin
      X := Inputs[I];
      Plain[I] := GetDouble(P.ExecuteScript(Script)^);
    end;
    for I := 0 to 2 do
      CheckDouble(Format('bulk answer %d matches the ordinary one', [I]), Outputs[I], Plain[I]);
    Check('the fallback is not counted as an accelerator hit', P.HitCount = Hits,
      Format('  hits %d -> %d', [Hits, P.HitCount]));
    {
      And the point of it all: a computation that did not happen must leave no numbers
      of somebody else. The formula is deliberately unusable, so the answers have to
      keep "not a number" rather than the tens from the first formula.

    }
    Ok := P.ExecuteMany('Max(x, ', X, Inputs, Outputs);
    Check('a formula that does not parse is refused', not Ok);
    for I := 0 to 2 do
      Check(Format('answer %d is not left over from before', [I]), IsNan(Outputs[I]),
        Format('  %g', [Outputs[I]]));
    {
      Next come two kinds of output that do not match the size of the input. Up to this
      point only the refusal on equal lengths was checked, and the contract "a refusal
      means one and the same thing" rested on reading the code rather than on a run.

      A short output: all of it is filled in. A caller who did not look at the result
      has to see "not a number" rather than the tens from the previous formula.

    }
    for I := 0 to 1 do Short[I] := 777;
    Ok := P.ExecuteMany('x * 10', X, Inputs, Short);
    Check('a short output is refused', not Ok);
    for I := 0 to 1 do
      Check(Format('short answer %d is not left over', [I]), IsNan(Short[I]), Format('  %g', [Short[I]]));
    {
      A long output: the area of the input is filled in, while the tail beyond it is
      somebody else's memory and is not touched, neither on a refusal nor on success.

    }
    for I := 0 to 4 do Long[I] := 777;
    Ok := P.ExecuteMany('Max(x, ', X, Inputs, Long);
    Check('a long output does not rescue a formula that does not parse', not Ok);
    for I := 0 to 2 do
      Check(Format('long answer %d is not left over', [I]), IsNan(Long[I]), Format('  %g', [Long[I]]));
    for I := 3 to 4 do
      CheckDouble(Format('the tail past the inputs survives a refusal, %d', [I]), Long[I], 777);
    for I := 0 to 4 do Long[I] := 777;
    Ok := P.ExecuteMany('x * 10', X, Inputs, Long);
    Check('a long output is computed', Ok);
    for I := 0 to 2 do
      CheckDouble(Format('long answer %d is right', [I]), Long[I], (I + 1) * 10);
    for I := 3 to 4 do
      CheckDouble(Format('the tail past the inputs survives a success, %d', [I]), Long[I], 777);
  finally
    P.Free;
  end;
end;

{
  Compiled code runs under the parser's exception mask.

  This is the THIRD way into an evaluation, and it is not an internal one:
  jit/USAGE.md recommends compiling with CompileScript and then running the
  compiled object from as many threads as you like. Neither the machine code nor
  the interpreter of the intermediate form touches the mask, so on a thread with
  a narrowed mask division by zero raised where the library promises infinity -
  on the very path the documentation recommends.

  The mask is narrowed here on purpose. A console program of this studio starts
  with everything masked, so a check written "as it comes" would be green on any
  code at all.
}
procedure CompiledCodeRunsUnderTheParserMask;
var
  P: TJitParser;
  X: Double;
  Script: TScript;
  Compiled: TJitScript;
  Was, Host: TFPUExceptionMask;
  Value: Double;
  Note: string;
begin
  BeginSection('compiled code runs under the parser mask');
  Was := GetExceptionMask;
  Host := [exDenormalized, exUnderflow, exPrecision];
  P := TJitParser.Create(nil);
  Script := nil;
  Compiled := nil;
  try
    P.AddVariable('x', X);
    X := 0;
    P.StringToScript('1 / x', Script);
    Compiled := P.CompileScript(Script);
    Check('the formula reached a compiled form', Compiled.Ready, Compiled.Reason);
    SetExceptionMask(Host);
    Note := '';
    Value := 0;
    try
      Value := Compiled.Execute;
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('nothing was raised', Note = '', Note);
    Check('the answer is infinity', IsInfinite(Value), Format('%g', [Value]));
    Check('the host mask came back', GetExceptionMask = Host, 'mask changed');
  finally
    SetExceptionMask(Was);
    Compiled.Free;
    Script := nil;
    P.Free;
  end;
end;

{
  The parser has to outlive the script it produced, and that is a CONTRACT rather
  than a wish.

  The earlier version of this check claimed the opposite, as if the script were
  self-contained, and it went green because it took the formula x * 2: that one goes
  into machine code and holds no assumptions about redirection. The script has
  several references to the parser, and clearing Owner is not enough:

    TJitDecoder.FParser  Valid asks the parser about functions and redirections
                         for every assumption, and Fresh goes exactly there;
    TJitExecutor         copies Method0/Method1/Method2 into its own steps, that is
                         pointers to METHODS OF OBJECTS of the parser, and calls them;
    TJitExecutor.FHeader looks into the original script and makes no copy.

  So the check takes TWO formulas: one for the machine and one the emitter does not
  take, which goes to the executor. On the second one the earlier code read freed
  memory. There is one expectation now: after the death of the parser the script
  REFUSES rather than computes.
}
procedure CompiledScriptRefusesWithoutItsParser;

  procedure OneScript(const Text: string; const Machine: Boolean);
  var
    P: TJitParser;
    Compiled: TJitScript;
    Script: TScript;
    X: Double;
    Note: string;
    Value: Double;
  begin
    X := 3;
    P := TJitParser.Create(nil);
    Compiled := nil;
    Script := nil;
    try
      P.AddVariable('x', X);
      P.StringToScript(Text, Script);
      Compiled := P.CompileScript(Script);
      Check('compiled: ' + Text, Assigned(Compiled) and Compiled.Ready, Compiled.Reason);
      {$IFDEF COMPILES_TO_MACHINE_CODE}
      Check('the level is the one the check needs', (P.MachineCount > 0) = Machine,
        Format('machine %d, executor %d', [P.MachineCount, P.ExecutorCount]));
      {$ELSE}
      { Outside x86-64 there is no machine code generator at all, and the requested level
        is out of reach by construction rather than by the properties of the script. The
        requirement does not disappear because of that: there must be no machine code, and
        the executor has to take the script for itself. }
      Check('the level is the one the check needs', (P.MachineCount = 0) and (P.ExecutorCount > 0),
        Format('machine %d, executor %d', [P.MachineCount, P.ExecutorCount]));
      {$ENDIF}
      Value := Compiled.Execute;
      Check('computes while the parser is alive', not IsNan(Value), Format('%g', [Value]));
    finally
      Script := nil;
      P.Free;
    end;
    { The parser is gone. From here on only a refusal, and no reading of the dead. }
    Check('owner cleared: ' + Text, not Assigned(Compiled.Owner), 'the pointer is still there');
    Note := '';
    try
      Check('does not consider itself ready', not Compiled.Ready, 'considers itself ready without a parser');
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('Ready did not throw', Note = '', Note);
    Note := '';
    Value := 0;
    try
      Value := Compiled.Execute;
    except
      on E: EJitOrphan do Note := 'orphan';
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('Execute refused with the named exception: ' + Text, Note = 'orphan',
      Format('%s, returned %g', [Note, Value]));
    Compiled.Free;
  end;

begin
  BeginSection('without its parser the script refuses rather than computes');
  { The machine path: arithmetic the emitter takes. }
  OneScript('x * 2', True);
  {
    The executor path: the emitter does not take round, while the intermediate stage
    does, and that is the one holding the pointers to the methods of the parser.

  }
  OneScript('round(x)', False);
end;

begin
  Writeln('=== JIT contract: machine code really runs ===');
  FirstFormulaOnAFreshParser;
  RepeatingItKeepsTheCode;
  BulkAsTheVeryFirstCall;
  ADeclinedFormulaSaysWhy;
  EveryReasonComesFromTheVocabulary;
  RegisteringSomethingNewRebuildsTheCode;
  TurningTheAcceleratorOff;
  ACrampedBufferIsRefused;
  AVariableWiderThanDouble;
  CompiledCodeRunsUnderTheParserMask;
  NoSpareExecutorBesideWorkingCode;
  BulkAnswersOrSaysItDidNot;
  CompiledScriptRefusesWithoutItsParser;
  ExitCode := TestSummary;
end.
