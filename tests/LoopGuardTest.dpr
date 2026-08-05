{ ************************************************************************** }
{                                                                            }
{ LoopGuardTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program LoopGuardTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils,
  Parser,
  ParseTypes,
  ValueTypes,
  ValueUtils,
  Thread,
  TestKit in 'TestKit.pas';

{
  What this file guards.

  The language has three looping constructs - While, Repeat and For - and all
  three spin on a user-written condition. Nothing said the condition must ever
  become false, and nothing in the parser could interrupt one that never did.
  A search for Terminated, Stopped, Aborted, Cancel or Interrupt across the
  whole parser found not a single hit: once a calculation began there was no
  way to stop it.

  That was not theoretical. It hung two things in two different ways.

  The browser demo runs the parser as a single-threaded WebAssembly module.
  JavaScript cannot preempt it, so one runaway formula froze the tab dead - no
  error, no repaint, nothing but a killed page.

  The plotting component polls its Stopped flag BETWEEN points, never inside a
  single evaluation. A formula that looped forever never reached the next point,
  so Stop went unheard, the wait expired, and TerminateThread killed the worker
  wherever it happened to be - possibly inside the memory manager, which leaves
  the heap broken and the crash surfacing later somewhere unrelated. Waiting
  longer cannot help with that one: the thread is never going to answer.

  The guard is two optional stops, both off by default so that existing users of
  loops see no change. ParseBreak points at somebody else's "stop now" flag; a
  worker points it at its own Stopped. ParseLoopLeft counts down the turns one
  entry into the calculation may take, which is the only protection available
  where nobody can interrupt from outside.

  WHY EVERY FORMULA HERE RUNS IN A THREAD.

  The first version of this file ran them in-process, and it was wrong. Any
  mutation that disables the guard - which is exactly what a mutation must be
  able to do - turned the run into a hang instead of a failure. A test that
  hangs on a broken product is not a test: nothing is reported, the run has to
  be killed by hand, and "red" becomes indistinguishable from "still going".

  So each formula runs in a worker with a deadline of its own, and a worker that
  overstays it is killed outright. A hang is then an ordinary failed check with
  a name that says so. That the killing tool is TerminateThread - the very thing
  this guard exists to avoid - is deliberate: here the process is about to exit
  anyway, and it is the only way to end a calculation that answers to nothing.

  These checks assert what the guard must do AND what it must not: an unarmed
  guard may not shorten a loop that ends on its own, and a stopped loop must
  raise, not return a quietly wrong number.

  They are also the only exercise the three loop constructs get anywhere in the
  tree. Before this file, While, Repeat and For appeared in exactly one test -
  the list of names a fresh parser registers - and never once ran.
}

const
  { How long a formula that has to stop on its own is given }
  Deadline = 10000;
  { How long a thread is given after Stop before it is killed }
  KillAfter = 1500;

  { The counter reaches ten and stops by itself }
  TenWhile = 'While(cnt < 10, Set("cnt", cnt + 1))';
  TenRepeat = 'Repeat(Set("cnt", cnt + 1), cnt >= 10)';
  TenFor = 'For("cnt", 0, cnt < 10, Set("cnt", cnt + 1))';
  { The same, but the condition never becomes false }
  EndlessWhile = 'While(1 = 1, Set("cnt", cnt + 1))';
  EndlessRepeat = 'Repeat(Set("cnt", cnt + 1), 1 = 0)';
  EndlessFor = 'For("cnt", 0, 1 = 1, Set("cnt", cnt + 1))';

type
  {
    One formula computed in a thread of its own. The budget and the flag are
    armed INSIDE Work: the storage is per thread, and arming them outside would
    arm them for us. The plotting worker does exactly the same.
  }
  TFormulaThread = class(TThread)
  private
    FText: string;
    FNote: string;
    FBudget: NativeInt;
    FWatched: Boolean;
    FTwice: Boolean;
    FStarted: Boolean;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  public
    property Text: string read FText write FText;
    property Note: string read FNote;
    property Budget: NativeInt read FBudget write FBudget;
    { Whether to watch this thread's own stop flag }
    property Watched: Boolean read FWatched write FWatched;
    {
      Compute the formula TWICE on one arming. That is how a curve is sampled in
      the browser: the limit is set for the whole entry and there are hundreds
      of points inside it. The answer is taken from the second run.
    }
    property Twice: Boolean read FTwice write FTwice;
    property Begun: Boolean read FStarted;
    {
      An end marker of our own. WaitFor will not do: under Delphi it begins by
      asking whether the thread is still running, and a thread that finished
      before the wait was reached does not pass that test - so an instant answer
      becomes indistinguishable from a hang. This test was burned by exactly
      that: two ten-turn formulas were declared hung.
    }
    property Ended: Boolean read FEnded;
  end;

var
  P: TMathParser;
  Cnt: TValue;
  Killed: Boolean;
  {
    The threads live to the end of the run and are freed together. Freeing one
    right after its calculation is not safe: Done has already run, but the
    thread is still writing its own fields on the way out, and the object would
    be pulled from under it.
  }
  Threads: array [0 .. 63] of TFormulaThread;
  ThreadCount: Integer;

procedure TFormulaThread.Work;
var
  Script: TScript;
begin
  ParseLoopLeft := FBudget;
  if FWatched then ParseBreak := StopFlag else ParseBreak := nil;
  FStarted := True;
  Script := nil;
  try
    P.StringToScript(FText, Script);
    if FTwice then
      try
        P.ExecuteScript(Script);
      except
        { the first run may be cut short - the second one is what matters }
      end;
    P.ExecuteScript(Script);
  except
    on E: Exception do FNote := E.Message;
  end;
end;

procedure TFormulaThread.Done;
begin
  FEnded := True;
end;

function Waiting(const T: TFormulaThread; const Time: LongWord): Boolean;
var
  Spent: LongWord;
begin
  Spent := 0;
  while not T.Ended and (Spent < Time) do
  begin
    Sleep(5);
    Inc(Spent, 5);
  end;
  Result := T.Ended;
end;

{
  One formula, computed from scratch and with an eye on the clock.

  Returns: empty - it finished; an error text - it was stopped; the word "hung"
  - the thread had to be killed. That last one is the reason this test lives in
  a thread at all: it has to be a visible failure, not a stalled run.
}
function Run(const AText: string; const Budget: NativeInt; const Watched: Boolean;
  const RaiseAfter: LongWord = 0; const Twice: Boolean = False): string;
var
  T: TFormulaThread;
  Waited: LongWord;
begin
  AssignDouble(Cnt, 0);
  T := TFormulaThread.Create(nil);
  Threads[ThreadCount] := T;
  Inc(ThreadCount);
  T.AbortTime := KillAfter;
  T.Text := AText;
  T.Budget := Budget;
  T.Watched := Watched;
  T.Twice := Twice;
  T.Start;
  if RaiseAfter > 0 then
  begin
    { the flag is raised in flight, once the calculation is already running }
    Waited := 0;
    while not T.Begun and (Waited < RaiseAfter) do
    begin
      Sleep(5);
      Inc(Waited, 5);
    end;
    Sleep(RaiseAfter);
    T.Stop;
  end;
  if Waiting(T, Deadline) then Result := T.Note
  else begin
    { the deadline passed. Ask nicely first, then kill }
    T.Stop;
    if not Waiting(T, KillAfter) then
    begin
      T.Abort;
      Killed := True;
    end;
    Result := 'hung';
  end;
end;

function Turns: Double;
begin
  Result := GetDouble(Cnt);
end;

procedure UnarmedGuardChangesNothing;
var
  Note: string;
begin
  BeginSection('an unarmed guard changes nothing');
  Note := Run(TenWhile, 0, False);
  Check('While finishes on its own', Note = '', Note);
  CheckDouble('While: ten turns', Turns, 10);
  Note := Run(TenRepeat, 0, False);
  Check('Repeat finishes on its own', Note = '', Note);
  CheckDouble('Repeat: ten turns', Turns, 10);
  Note := Run(TenFor, 0, False);
  Check('For finishes on its own', Note = '', Note);
  CheckDouble('For: ten turns', Turns, 10);
end;

procedure BudgetStopsEndlessLoop;
var
  Note: string;
begin
  BeginSection('a turn budget stops an endless loop');
  Note := Run(EndlessWhile, 10000, False);
  Check('While: the limit is named', Pos('Loop limit', Note) > 0, Note);
  Note := Run(EndlessRepeat, 10000, False);
  Check('Repeat: the limit is named', Pos('Loop limit', Note) > 0, Note);
  Note := Run(EndlessFor, 10000, False);
  Check('For: the limit is named', Pos('Loop limit', Note) > 0, Note);
end;

procedure BudgetCountsTurns;
var
  Note: string;
begin
  BeginSection('the budget counts turns and nothing else');
  { eleven is enough for ten turns }
  Note := Run(TenWhile, 11, False);
  Check('a budget of 11 covers 10 turns', Note = '', Note);
  CheckDouble('the counter reached the end', Turns, 10);
  { five is not, and it stops exactly where it ran out }
  Note := Run(TenWhile, 5, False);
  Check('a budget of 5 is not enough', Pos('Loop limit', Note) > 0, Note);
  CheckDouble('the counter stopped on the fourth turn', Turns, 4);
  {
    A spent budget must not turn into no limit at all.

    It did: both states were written as zero, so the first calculation that was
    cut short lifted the limit for every one after it in the same entry. In the
    browser that looked like this: one point of the curve honestly stopped on
    the limit, and the next one span forever and killed the tab - the very thing
    the guard was written for.
  }
  Note := Run(EndlessWhile, 10000, False, 0, True);
  Check('after a spent budget the second run is refused too', Pos('Loop limit', Note) > 0, Note);
  { zero means "no limit", not "no turns" }
  Note := Run(TenWhile, 0, False);
  Check('zero means no limit', Note = '', Note);
  CheckDouble('the counter reached the end', Turns, 10);
end;

procedure BreakFlagStopsLoop;
var
  Note: string;
begin
  BeginSection('somebody else''s flag stops the loop');
  {
    The budget is armed here ON PURPOSE, and generously: it insures against a
    hang if the flag breaks, but it cannot fire before the flag does. Which of
    the two fired is visible in the text - the guard names the reason.
  }
  Note := Run(EndlessWhile, 100000000, True, 150);
  Check('an endless While is stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Note := Run(EndlessRepeat, 100000000, True, 150);
  Check('an endless Repeat is stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Note := Run(EndlessFor, 100000000, True, 150);
  Check('an endless For is stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  { a lowered flag forbids nothing: the guard is armed but silent }
  Note := Run(TenWhile, 0, True);
  Check('with the flag down the loop runs', Note = '', Note);
  CheckDouble('and reaches the end', Turns, 10);
end;

procedure MeasureTurnRate;
var
  Note: string;
  Started: Int64;
  Spent: Double;
begin
  BeginSection('turn rate: so that a limit is set by measurement, not by eye');
  Started := Now64;
  Note := Run('While(cnt < 100000, Set("cnt", cnt + 1))', 0, False);
  Spent := Elapsed(Started);
  Check('a hundred thousand turns are counted', Note = '', Note);
  CheckDouble('the counter got there', Turns, 100000);
  if (Spent > 0) and (Note = '') then
    WriteLn(Format('    turns per second: %.0f (a hundred thousand in %.3f s)', [100000 / Spent, Spent]));
end;

begin
  try
    P := TMathParser.Create(nil);
    try
      AssignDouble(Cnt, 0);
      P.AddVariable('cnt', Cnt);
      UnarmedGuardChangesNothing;
      BudgetStopsEndlessLoop;
      BudgetCountsTurns;
      BreakFlagStopsLoop;
      MeasureTurnRate;
      if not Killed then
        for ThreadCount := ThreadCount - 1 downto 0 do Threads[ThreadCount].Free;
      if Killed then
        Fail('a thread had to be killed', 'a formula did not stop in time - the loop guard is not working');
    finally
      {
        After a thread was killed the heap may be broken: taking the parser
        apart here can fail on its own and take the report down with it.
      }
      if not Killed then P.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
