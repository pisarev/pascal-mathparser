{ ************************************************************************** }
{                                                                            }
{ ThreadSafetyTest                                                           }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ThreadSafetyTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, Thread, TestKit in 'TestKit.pas';

{
  What this file guards: which evaluation owns an Exit.

  The plotting component hands every worker the SAME parser object and lets four
  of them sample a curve at once. Evaluation itself survives that - a separate
  test drives 24 000 concurrent evaluations and every answer comes back right.
  What does not survive is Exit.

  ExecuteScript used to decide "am I the outermost evaluation?" by a nesting
  counter kept in a FIELD OF THE PARSER, shared by every thread using it. Two
  threads evaluating at the same time read 2 there, and the one whose formula
  hits Exit concludes it is nested and re-raises instead of taking the value.
  Whether it does depends on which thread got to its Dec first, so the meaning
  of Exit came out of the thread scheduler.

  The counter also drifted. Inc and Dec are read-modify-write on a machine word,
  and a lost update leaves the field at -1 after the storm; a later single
  evaluation then reads 0 where it needs 1, and Exit stays broken for that
  parser until another race happens to undo the damage.

  The fix keeps the depth where it belongs: a frame on the stack of the call, a
  thread-local pointer to the innermost one, and a link to the nearest frame of
  THE SAME parser. Then "outermost" means "no parent frame of my parser in my
  thread" - true for parallel roots, true for two parsers nested in one thread,
  and false only for genuine recursion into the same parser.

  R1..R4 must FAIL before that fix - a test that cannot go red on the broken
  code proves nothing. G1..G5 must pass both before and after: they guard the
  behaviour that was already correct.
}

const
  Workers = 4;
  StormRounds = 6000;

type
  { Releases a thread on a flag. Busy waiting is the right tool here: what these
    tests measure is the order of events, not speed. }
  TGate = record
    Open: Boolean;
  end;

  { A formula function that parks a thread INSIDE ExecuteScript. Without it two
    evaluations cannot be brought to the same instant on purpose: the race would
    be caught by luck, and a test has to go red every single time. }
  THolder = class
  private
    FInside: Boolean;
    FRelease: TGate;
    FParser: TMathParser;
    FNested: TScript;
    FNestedResult: Double;
    FNestedNote: string;
  public
    function Hold(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function CallNested(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function CallOther(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function Boom(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

  ETestBoom = class(Exception);

  { A parser whose notification starts an evaluation of its own. The frame is
    pushed AFTER the notification, so that evaluation has to count as a separate
    root - exactly as it did before the fix. }
  TNotifyProbe = class(TMathParser)
  private
    FBusy: Boolean;
    FInnerNote: string;
    FInnerValue: Double;
  protected
    procedure Notify; overload; override;
  end;

  { One evaluation in a thread of its own. The thread has to be real: the race
    R1 and R2 look for lives between threads, not inside one. }
  TRunner = class(TThread)
  private
    FParser: TMathParser;
    FScript: TScript;
    FValue: Double;
    FNote: string;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  end;

var
  Holder: THolder;
  MainParser, OtherParser: TMathParser;
  { Deliberately oversized: a run starts many threads, and writing past the end
    of an array corrupts memory so that the crash lands nowhere near its cause -
    learned the hard way }
  Runners: array [0 .. 255] of TRunner;
  RunnerCount: Integer;

function THolder.Hold(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  FInside := True;
  while not FRelease.Open do Sleep(2);
  Result := MakeDouble(1);
end;

function THolder.CallNested(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  {
    A nested call into THE SAME parser is real recursion. An Exit out of it has
    to reach the ROOT of this thread, so the exception is NOT caught here:
    catching it ourselves would leave the check empty - it would then watch our
    own handling instead of the parser. Control comes back here only when the
    nested call finishes without an Exit.
  }
  FNestedNote := '';
  FNestedResult := GetDouble(FParser.ExecuteScript(FNested)^);
  FNestedNote := 'the nested call caught its own Exit';
  Result := MakeDouble(FNestedResult);
end;

function THolder.CallOther(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  { A nested call into ANOTHER parser is an evaluation of its own: its Exit has
    to stay inside it and leave the outer one alone. }
  FNestedNote := '';
  FNestedResult := 0;
  try
    FNestedResult := GetDouble(OtherParser.ExecuteScript(FNested)^);
  except
    on E: Exception do FNestedNote := E.ClassName;
  end;
  Result := MakeDouble(FNestedResult);
end;

function THolder.Boom(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  raise ETestBoom.Create('probe');
end;

procedure TNotifyProbe.Notify;
var
  Inner: TScript;
begin
  inherited Notify;
  if FBusy then Exit;
  FBusy := True;
  Inner := nil;
  try
    try
      StringToScript('Script(1, Exit(42))', Inner);
      FInnerValue := GetDouble(ExecuteScript(Inner)^);
    except
      on E: Exception do FInnerNote := E.ClassName + ': ' + E.Message;
    end;
  finally
    FBusy := False;
  end;
end;

procedure TRunner.Work;
begin
  try
    FValue := GetDouble(FParser.ExecuteScript(FScript)^);
  except
    on E: Exception do FNote := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TRunner.Done;
begin
  FEnded := True;
end;

{ Starts an evaluation in a thread of its own. The thread is not freed at
  once: Done has already run, but the thread is still writing its own fields
  before it leaves. }
function Launch(const AParser: TMathParser; const Script: TScript): TRunner;
begin
  Result := TRunner.Create(nil);
  Runners[RunnerCount] := Result;
  Inc(RunnerCount);
  Result.FParser := AParser;
  Result.FScript := Script;
  Result.Start;
end;

function Waiting(const R: TRunner; const Time: LongWord): Boolean;
var
  Spent: LongWord;
begin
  Spent := 0;
  while not R.FEnded and (Spent < Time) do
  begin
    Sleep(5);
    Inc(Spent, 5);
  end;
  Result := R.FEnded;
end;

{ R1 }

{
  Two ROOT evaluations of one parser run at the same time. One of them reaches
  an Exit. It is the root in its own thread, so the value has to come back to it
  instead of flying out as an exception.

  On the old code the shared counter reads 2, the handler takes the root for a
  nested call and lets EParserExit out. The check is deterministic: the second
  thread is held INSIDE ExecuteScript until the first one has finished.
}
procedure R1_ParallelRootExitIsIndependent;
var
  Held, Exiting: TScript;
  B, A: TRunner;
  Spent: LongWord;
begin
  BeginSection('R1: a parallel root owns its own Exit');
  Held := nil;
  Exiting := nil;
  MainParser.StringToScript('hold(0)', Held);
  MainParser.StringToScript('Script(hold(0), Exit(42))', Exiting);
  Holder.FInside := False;
  Holder.FRelease.Open := False;
  B := Launch(MainParser, Held);
  Spent := 0;
  while not Holder.FInside and (Spent < 5000) do
  begin
    Sleep(5);
    Inc(Spent, 5);
  end;
  Check('the second thread got inside an evaluation', Holder.FInside, Format('waited %d ms, the thread said: %s', [Spent, B.FNote]));
  { The first thread evaluates its formula while the second one stands inside }
  A := Launch(MainParser, Exiting);
  Check('the thread with the Exit finished', Waiting(A, 10000), 'never finished');
  Holder.FRelease.Open := True;
  Waiting(B, 10000);
  Check('the Exit did not escape as an exception', A.FNote = '', A.FNote);
  CheckDouble('the root call got its own value', A.FValue, 42);
end;

{ R2 }

{
  Real recursion in one thread, with a neighbour alive. The nested call does the
  Exit; the value has to rise to the root OF THIS THREAD and not to anybody
  else's.

  On the old code the depth adds up with the other root and the handler is wrong
  again.
}
procedure R2_RecursiveExitBelongsToItsThreadRoot;
var
  Held, Root: TScript;
  B, A: TRunner;
  Spent: LongWord;
begin
  BeginSection('R2: a recursive Exit belongs to its own root');
  Held := nil;
  Root := nil;
  Holder.FNested := nil;
  MainParser.StringToScript('hold(0)', Held);
  MainParser.StringToScript('Exit(55)', Holder.FNested);
  MainParser.StringToScript('nested(0)', Root);
  Holder.FInside := False;
  Holder.FRelease.Open := False;
  B := Launch(MainParser, Held);
  Spent := 0;
  while not Holder.FInside and (Spent < 5000) do
  begin
    Sleep(5);
    Inc(Spent, 5);
  end;
  Check('the neighbour stands inside an evaluation', Holder.FInside, B.FNote);
  A := Launch(MainParser, Root);
  Check('the thread with the recursion finished', Waiting(A, 10000), 'never finished');
  Holder.FRelease.Open := True;
  Waiting(B, 10000);
  Check('nothing escaped', A.FNote = '', A.FNote);
  Check('the nested Exit did not stay inside the nested call', Holder.FNestedNote = '', Holder.FNestedNote);
  CheckDouble('the root got the value of the nested Exit', A.FValue, 55);
end;

{ R3 }

{
  Stress: a storm of parallel evaluations, then an Exit in the main thread. This
  is what catches LEFTOVER damage to the counter - the thing the whole enquiry
  started from. It depends on scheduling, so R1 and R2 carry the proof and this
  one guards against regression.
}
procedure R3_StormLeavesExitWorking;
var
  Scripts: array [0 .. Workers - 1] of TScript;
  Values: array [0 .. Workers - 1] of TValue;
  Probe: TScript;
  I, R: Integer;
  Alive: Boolean;
  Spent: LongWord;
  Note: string;
  Got: Double;
  Pack: array [0 .. Workers - 1] of TRunner;
begin
  BeginSection('R3: after the storm, Exit still works in the main thread');
  for I := 0 to Workers - 1 do
  begin
    AssignDouble(Values[I], 1);
    MainParser.AddVariable('s' + IntToStr(I), Values[I]);
    Scripts[I] := nil;
    MainParser.StringToScript(Format('Sin(s%d) * s%d + 1', [I, I]), Scripts[I]);
  end;
  for R := 1 to StormRounds div 500 do
  begin
    for I := 0 to Workers - 1 do
    begin
      Pack[I] := TRunner.Create(nil);
      Runners[RunnerCount] := Pack[I];
      Inc(RunnerCount);
      Pack[I].FParser := MainParser;
      Pack[I].FScript := Scripts[I];
      Pack[I].Start;
    end;
    Spent := 0;
    repeat
      Sleep(2);
      Inc(Spent, 2);
      Alive := False;
      for I := 0 to Workers - 1 do if not Pack[I].FEnded then Alive := True;
    until (not Alive) or (Spent > 20000);
  end;
  Probe := nil;
  Note := '';
  Got := 0;
  try
    MainParser.StringToScript('Script(1, Exit(42))', Probe);
    Got := GetDouble(MainParser.ExecuteScript(Probe)^);
  except
    on E: Exception do Note := E.ClassName + ': ' + E.Message;
  end;
  Check('Exit after the storm raised nothing', Note = '', Note);
  CheckDouble('and returned its value', Got, 42);
end;

{ R4 }

{
  Brackets in a formula are an internal script. The evaluation mode decides WHEN
  it is evaluated: on demand, once the brackets are reached, or up front, before
  the main script runs.

  Evaluating up front used to happen OUTSIDE the handler, and every internal
  script ended up a root of its own: its Exit stayed inside the brackets, the
  value went back into the expression, and 99 + (Exit(42)) came out as 141. The
  scope of Exit thus followed the evaluation mode instead of the nesting.

  One public call now means one scope for Exit, and both modes answer 42. This
  is the only change of behaviour in the whole fix, and it is declared in the
  release notes.
}
procedure R4_InternalExitEndsThePublicCall;
var
  P: TMathParser;
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('R4: an Exit in an internal script ends the whole public call');
  P := TMathParser.Create(nil);
  try
    P.ExecuteKindSet := [];
    Root := nil;
    Note := '';
    Got := 0;
    try
      P.StringToScript('99 + (Exit(42))', Root);
      Got := GetDouble(P.ExecuteScript(Root)^);
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('nothing escaped', Note = '', Note);
    CheckDouble('the value of the Exit came back, not the sum', Got, 42);
  finally
    P.Free;
  end;
end;

{ G1, G2, G3, G4, G5 }

{
  Guards: this behaviour is ALREADY right, and the fix has no business breaking
  it. G1 is the main insurance against a naive thread-wide counter, which would
  mix the nesting of different parsers in one thread.
}
procedure G1_DifferentParsersAreIndependent;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('G1: different parsers in one thread are independent');
  Holder.FNested := nil;
  OtherParser.StringToScript('Exit(77)', Holder.FNested);
  Root := nil;
  Note := '';
  Got := 0;
  try
    { Script evaluates its parameters from the second one on and returns the
      FIRST: getting 11 back after a call into the other parser needs exactly
      this order }
    MainParser.StringToScript('Script(11, other(0))', Root);
    Got := GetDouble(MainParser.ExecuteScript(Root)^);
  except
    on E: Exception do Note := E.ClassName + ': ' + E.Message;
  end;
  Check('the outer parser did not get somebody else''s Exit', Note = '', Note);
  Check('the nested parser caught its own Exit itself', Holder.FNestedNote = '', Holder.FNestedNote);
  CheckDouble('the nested one returned its value', Holder.FNestedResult, 77);
  CheckDouble('the outer one finished its own sum', Got, 11);
end;

procedure G2_RecursiveExitReachesOuterRoot;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('G2: recursion into one parser, no threads');
  Holder.FNested := nil;
  MainParser.StringToScript('Exit(55)', Holder.FNested);
  Root := nil;
  Note := '';
  Got := 0;
  try
    MainParser.StringToScript('nested(0)', Root);
    Got := GetDouble(MainParser.ExecuteScript(Root)^);
  except
    on E: Exception do Note := E.ClassName + ': ' + E.Message;
  end;
  Check('nothing escaped', Note = '', Note);
  Check('the nested call passed the Exit on', Holder.FNestedNote = '', Holder.FNestedNote);
  CheckDouble('the root got the value', Got, 55);
end;

{
  G3 is about recovering from somebody else's exception. The pointer to the
  frame lives in thread-local memory and the frame itself on the stack: if the
  unwinding exception does not put the pointer back, the next evaluation walks
  into a dead address.
}
procedure G3_ForeignExceptionRestoresState;
var
  Bad, Good: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('G3: somebody else''s exception does not break the next evaluation');
  Bad := nil;
  Good := nil;
  Note := '';
  try
    MainParser.StringToScript('boom(0)', Bad);
    MainParser.ExecuteScript(Bad);
  except
    on E: Exception do Note := E.ClassName;
  end;
  Check('the user''s exception came out', Note = 'ETestBoom', Note);
  Note := '';
  Got := 0;
  try
    MainParser.StringToScript('Script(1, Exit(42))', Good);
    Got := GetDouble(MainParser.ExecuteScript(Good)^);
  except
    on E: Exception do Note := E.ClassName + ': ' + E.Message;
  end;
  Check('the next Exit works', Note = '', Note);
  CheckDouble('and returns the value', Got, 42);
end;

{
  G4 is the same case as R4, in the default mode. There the internal script was
  already evaluated from the depth of the main one, so the answer did not
  change: 42 before the fix and 42 after. The R4/G4 pair is what shows the edge
  of the change - it touched exactly one mode.
}
procedure G4_OnDemandInternalExitUnchanged;
var
  P: TMathParser;
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('G4: in the default mode the answer is unchanged');
  P := TMathParser.Create(nil);
  try
    P.ExecuteKindSet := [ekSubsequent];
    Root := nil;
    Note := '';
    Got := 0;
    try
      P.StringToScript('99 + (Exit(42))', Root);
      Got := GetDouble(P.ExecuteScript(Root)^);
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('nothing escaped', Note = '', Note);
    CheckDouble('the answer is the one it was before the fix', Got, 42);
  finally
    P.Free;
  end;
end;

{
  G5 is about the top edge of the frame. A notification counts as preparation
  and not as evaluating a formula, so an evaluation started from a notification
  handler has to stay a root of its own. Push the frame before the notification
  and such an evaluation would become nested, and its Exit would fly into the
  outer call.
}
procedure G5_NotifyStaysOutsideTheFrame;
var
  P: TNotifyProbe;
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('G5: an evaluation started from a notification is a root of its own');
  P := TNotifyProbe.Create(nil);
  try
    Root := nil;
    Note := '';
    Got := 0;
    try
      P.StringToScript('7', Root);
      Got := GetDouble(P.ExecuteScript(Root)^);
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('the outer evaluation is untouched', Note = '', Note);
    CheckDouble('and finished its own sum', Got, 7);
    Check('the evaluation from the notification caught its own Exit', P.FInnerNote = '', P.FInnerNote);
    CheckDouble('and got its value', P.FInnerValue, 42);
  finally
    P.Free;
  end;
end;

var
  {
    EVERY function gets its own handle variable. The parser remembers the
    ADDRESS of that variable rather than its value, so with one shared variable
    the last registration overwrites all the earlier ones and the formula
    hold(0) starts calling boom. Found the hard way.
  }
  HoldHandle, NestedHandle, OtherHandle, BoomHandle: TFunctionHandle;
  I: Integer;

begin
  try
    MainParser := TMathParser.Create(nil);
    OtherParser := TMathParser.Create(nil);
    Holder := THolder.Create;
    try
      Holder.FParser := MainParser;
      { Registration is over before the first evaluation - that is the contract }
      MainParser.AddFunction('hold', HoldHandle, fkMethod, MakeFunctionMethod(Holder.Hold, 1, pkValue), False);
      MainParser.AddFunction('nested', NestedHandle, fkMethod, MakeFunctionMethod(Holder.CallNested, 1, pkValue), False);
      MainParser.AddFunction('other', OtherHandle, fkMethod, MakeFunctionMethod(Holder.CallOther, 1, pkValue), False);
      MainParser.AddFunction('boom', BoomHandle, fkMethod, MakeFunctionMethod(Holder.Boom, 1, pkValue), False);
      R1_ParallelRootExitIsIndependent;
      R2_RecursiveExitBelongsToItsThreadRoot;
      R3_StormLeavesExitWorking;
      R4_InternalExitEndsThePublicCall;
      G1_DifferentParsersAreIndependent;
      G2_RecursiveExitReachesOuterRoot;
      G3_ForeignExceptionRestoresState;
      G4_OnDemandInternalExitUnchanged;
      G5_NotifyStaysOutsideTheFrame;
      for I := RunnerCount - 1 downto 0 do Runners[I].Free;
    finally
      Holder.Free;
      MainParser.Free;
      OtherParser.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
