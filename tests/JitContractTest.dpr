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
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils,
  Parser,
  ParseTypes,
  ParseJit.Parser,
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
  KnownReasons: array[0..39] of string = (
    '', 'parser changed', 'ir executor', 'no code', 'not decoded: ',
    'x86-64 only', 'no script or parser', 'empty script',
    'unsupported element', 'unsupported method kind ',
    'parametric ', 'parametric function ',
    'unbound variable ', 'unknown variable ', 'variable type of ',
    'unresolved call', 'unknown function handle ', 'unknown element code ',
    'explicit item type', 'broken item header', 'item size mismatch',
    'script size mismatch', 'unexpected element in term',
    'code generation failed', 'code layout is broken', 'code buffer overflow',
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
    Check('nothing was handed back to the interpreter', P.MissCount = 0, Format('  misses=%d', [P.MissCount]));
    Check('a compiled formula reports no reason', P.CodeReason('x * x * 3 + 1') = '',
      Format('  reason="%s"', [P.CodeReason('x * x * 3 + 1')]));
    {$ELSE}
    Check('off x86-64 the interpreter answers', P.MissCount > 0);
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
    Check('all five calls used the compiled code', P.HitCount = 5, Format('  hits=%d misses=%d', [P.HitCount, P.MissCount]));
    {$ELSE}
    Check('off x86-64 every call goes to the interpreter', P.MissCount = 5);
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
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    Check('bulk evaluation was accepted', Ok);
    CheckDouble('the last output was written', Outputs[2], 49);
    CheckDouble('the first output was written', Outputs[0], 4);
    {$ELSE}
    Check('off x86-64 bulk evaluation declines', not Ok);
    {$ENDIF}
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
    Check('the reason is a word the code can produce', ReasonIsKnown(Reason), Format('  reason="%s" is outside the vocabulary', [Reason]));
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
      Check('reason for ' + Probes[I] + ' is known', ReasonIsKnown(Reason), Format('  reason="%s"', [Reason]));
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
    Check('the generation moved on', P.Generation <> Before, Format('  before=%d after=%d', [Before, P.Generation]));

    CheckDouble('the old formula still answers', P.AsDouble('x * 2 + 1'), 5);
    CheckDouble('the new variable is visible', P.AsDouble('x + y'), 5);
    {$IFDEF COMPILES_TO_MACHINE_CODE}
    Check('both formulas run as machine code again', P.CodeReason('x * 2 + 1') = '', Format('  reason="%s"', [P.CodeReason('x * 2 + 1')]));
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

begin
  Writeln('=== JIT contract: machine code really runs ===');
  FirstFormulaOnAFreshParser;
  RepeatingItKeepsTheCode;
  BulkAsTheVeryFirstCall;
  ADeclinedFormulaSaysWhy;
  EveryReasonComesFromTheVocabulary;
  RegisteringSomethingNewRebuildsTheCode;
  TurningTheAcceleratorOff;
  ExitCode := TestSummary;
end.
