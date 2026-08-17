{ ************************************************************************** }
{                                                                            }
{ LoopScopeTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program LoopScopeTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils, TestKit in 'TestKit.pas';

{
  Who the loop guard belongs to.

  ParseBreak and ParseLoopLeft are declared as thread variables, so they belong
  to the PHYSICAL THREAD. They are armed by whoever started an evaluation: the
  plotting component before it sweeps a curve, the WebAssembly host before a
  run, an application before a long formula. Those are two different scopes, and
  where they part the guard fires on the wrong code.

  They part in two places, both reproducible in a single thread, with no races:

  1. A spent budget stays spent. That is DELIBERATE - the limit is set for a
     whole run and a run has hundreds of points in it, so the first aborted
     count has to abort the rest (LoopGuardTest, the section on a spent budget).
     But the refusal is written as -1 in a thread variable, so it is also seen
     by code that never armed a guard and knows nothing about anybody's run:
     another parser, another part of the program, the next button press. A
     refusal for nothing.

  2. A nested evaluation spends the outer budget. A formula may call another
     parser - through a user function, through Parse, through Deriv. The turns
     of the nested count are taken off the outer budget.

  The tests RECORD the behaviour rather than being fitted to it: where the
  behaviour is right - cancellation is inherited by a nested count, because the
  owner said stop and that means everything - the check states it and says why.

  WHAT IS NOT HERE: threads. All three cases live in a single thread, and that
  is not a simplification. Between threads a thread variable is divided exactly
  right. The mistake is that inside ONE thread there is more than one scope of
  evaluation.
}

const
  { Ten turns and an endless loop. The counter is on the outside: it shows where
    the count stopped, not merely that it stopped. }
  TenTurns = 'While(turns < 10, Set("turns", turns + 1))';
  Endless = 'While(1 = 1, Set("turns", turns + 1))';
  { A formula that calls the neighbouring parser mid-count. }
  NestedTen = 'While(turns < 10, Set("turns", turns + call(0)))';
  { Ten turns for the neighbour, on its own counter }
  InnerTen = 'While(inner < 10, Set("inner", inner + 1))';

type
  { Holder of the user function - the function is the nested call. }
  THolder = class
  private
    FInner: TMathParser;
    FScript: TScript;
    FCounter: PValue;
    FNote: string;
    FSpent: NativeInt;
    FLeftInside: NativeInt;
  public
    function Call(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

var
  Outer, Other: TMathParser;
  Holder: THolder;
  Turns, InnerTurns: TValue;
  Stop: Boolean;
  CallHandle: TFunctionHandle;

{
  The nested call. It returns one so that the outer loop counts turns as usual,
  and on the way it runs ten turns of its own on ITS OWN parser.
}
function THolder.Call(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  FNote := '';
  {
    The neighbour's counter is cleared on EVERY call. Without that the second
    call would make no turns at all - its condition is already false - and the
    nested count would come out ten times cheaper than intended. This test was
    fooled by exactly that once: it showed green where the shared budget simply
    did not have time to run out.
  }
  AssignDouble(FCounter^, 0);
  try
    FInner.ExecuteScript(FScript);
  except
    on E: Exception do FNote := E.Message;
  end;
  Inc(FSpent, Round(GetDouble(FCounter^)));
  FLeftInside := ParseLoopLeft;
  Result := MakeDouble(1);
end;

{ One evaluation from scratch. Returns empty when it finished, the text of the
  refusal otherwise. Both counters are cleared here: the checks read them as
  numbers. }
function Run(const P: TMathParser; const Text: string): string;
var
  Script: TScript;
begin
  AssignDouble(Turns, 0);
  AssignDouble(InnerTurns, 0);
  Script := nil;
  Result := '';
  try
    P.StringToScript(Text, Script);
    P.ExecuteScript(Script);
  except
    on E: Exception do Result := E.Message;
  end;
end;

{ 1 }

{
  A spent budget is seen by somebody who never armed a guard.

  The outer parser gets a budget and spends it on an endless loop - that is by
  the book. Then ANOTHER parser evaluates, one that knows nothing about the run
  and never touched the guard: for it ParseLoopLeft must mean "no limit", as in
  the "zero means no limit" section of LoopGuardTest.

  Before the pair it was refused by the limit: the thread variable held -1, left
  behind by somebody else's run.
}
procedure BurnedBudgetLeaksToStranger;
var
  Note: string;
  Guard: TLoopGuard;
begin
  BeginSection('a spent budget does not carry over to somebody else');
  ArmLoopGuard(Guard, 50);
  try
    Note := Run(Outer, Endless);
    Check('the endless loop was stopped by the limit', Pos('Loop limit', Note) > 0, Note);
    CheckDouble('the count stopped where the budget ran out', GetDouble(Turns), 49);
  finally
    DisarmLoopGuard(Guard);
  end;
  {
    The run is over, so the thread has to be left as it was found. Before the
    pair, -1 stayed there - "budget spent", written as a negative number. And it
    went to whoever came next in that thread, who never armed a guard and knows
    nothing about the run that did.
  }
  Check('after disarming there is no limit', ParseLoopLeft = 0, Format('%d', [ParseLoopLeft]));
  Check('after disarming there is no flag', ParseBreak = nil);
  Note := Run(Other, TenTurns);
  Check('another parser finishes its own ten turns', Note = '', Note);
  CheckDouble('and reaches the end', GetDouble(Turns), 10);
end;

{ 1a }

{
  A run inside a run. A formula calls Parse, that one computes its own curve
  with its own limit - and when it is done it must hand the outer limit back
  rather than clear the guard for the whole thread.
}
procedure NestedArmingRestoresTheOuterOne;
var
  Note: string;
  Outer1, Inner1: TLoopGuard;
  Left: NativeInt;
begin
  BeginSection('a run inside a run hands the outer limit back');
  ArmLoopGuard(Outer1, 50);
  try
    ArmLoopGuard(Inner1, 5);
    try
      Note := Run(Outer, TenTurns);
      Check('a budget of 5 was not enough for the inner one', Pos('Loop limit', Note) > 0, Note);
    finally
      DisarmLoopGuard(Inner1);
    end;
    Left := ParseLoopLeft;
    Check('the outer limit came back rather than being cleared', Left = 50, Format('%d', [Left]));
    Note := Run(Outer, TenTurns);
    Check('a budget of 50 is enough for the outer one', Note = '', Note);
    CheckDouble('and it finishes its own ten turns', GetDouble(Turns), 10);
  finally
    DisarmLoopGuard(Outer1);
  end;
  Check('after both disarms there is no limit', ParseLoopLeft = 0, Format('%d', [ParseLoopLeft]));
end;

{ 1b }

{
  A run inside a run does not silence the cancellation of the outer one.

  A nested ArmLoopGuard with a budget of its own but WITHOUT a flag of its own
  used to write nil into ParseBreak - and the owner who had asked the work to
  stop went unheard for the whole of the inner run. An inner run may replace the
  budget; it may not replace the cancellation, which is about all of the work
  rather than about a measure.

  This check differs from its neighbour in exactly one thing: there the nested
  count runs WITHOUT a guard of its own, here it runs with one. That is why the
  first version of the neighbouring check let this defect through.
}
procedure NestedArmingKeepsTheOuterCancel;
var
  Note: string;
  Outer2, Inner2: TLoopGuard;
begin
  BeginSection('a nested run does not silence the cancellation of the outer one');
  Stop := False;
  ArmLoopGuard(Outer2, 0, @Stop);
  try
    ArmLoopGuard(Inner2, 100000);
    try
      Check('the inner run did not lose somebody else''s flag', ParseBreak = @Stop);
      Stop := True;
      Note := Run(Outer, Endless);
      Check('the endless loop was stopped by the outer run''s flag',
        Pos('stopped', LowerCase(Note)) > 0, Note);
    finally
      DisarmLoopGuard(Inner2);
    end;
  finally
    DisarmLoopGuard(Outer2);
  end;
  Stop := False;
  Check('after both are disarmed there is no flag', ParseBreak = nil);
end;

{ 2 }

{
  One budget for the whole run, nested evaluations included. That is DELIBERATE.

  The temptation to give every evaluation a budget of its own does not survive
  scrutiny: a budget exists so that a page does not hang, and a nested loop can
  hang it exactly as well as an outer one. A measure each means no shared limit
  for anyone.

  The check exists so that this stays a decision rather than a coincidence: if
  the guard ever moves into the frame of an evaluation, the budget will have to
  be handed down explicitly.

  The numbers speak for themselves: a budget of 40 would have been four times
  what the outer loop needs for its ten turns, and the nested ones eat it by the
  fourth.
}
procedure BudgetIsSharedWithNestedOnPurpose;
var
  Note: string;
begin
  BeginSection('one budget for the whole run, nested evaluations spend it too');
  ParseLoopLeft := 40;
  ParseBreak := nil;
  Holder.FSpent := 0;
  Note := Run(Outer, NestedTen);
  Check('the count was stopped by the shared limit', Pos('Loop limit', Note) > 0, Note);
  Check('the outer loop stopped short of its ten turns', GetDouble(Turns) < 10,
    Format('%g turns out of 10', [GetDouble(Turns)]));
  Check('the turns of the nested count came out of the same budget', Holder.FSpent > 0,
    Format('%d nested turns', [Holder.FSpent]));
  Check('the turns together add up to about the budget',
    Round(GetDouble(Turns)) + Holder.FSpent >= 39,
    Format('%d against a budget of 40', [Round(GetDouble(Turns)) + Holder.FSpent]));
end;

{ 3 }

{
  Cancellation is inherited - and that is RIGHT.

  The cancellation flag means "the owner asks you to stop": a tab is closing, a
  window is going down, a job is being cancelled. A nested evaluation is part of
  the same work and there is no point continuing it. The difference from the
  budget is a matter of principle: a budget measures ITS OWN count, cancellation
  stops ALL the work.

  The check is here so that the inheritance stays a decision rather than a
  coincidence: if the guard moves into the frame of an evaluation, cancellation
  will have to be passed down explicitly, and without this check it would simply
  be forgotten.
}
procedure CancelIsInheritedOnPurpose;
var
  Note: string;
begin
  BeginSection('cancellation is inherited by the nested count');
  ParseLoopLeft := 0;
  Stop := True;
  ParseBreak := @Stop;
  Note := Run(Outer, NestedTen);
  Check('the outer count was stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Stop := False;
  ParseBreak := nil;
end;

begin
  try
    Outer := TMathParser.Create(nil);
    Other := TMathParser.Create(nil);
    Holder := THolder.Create;
    try
      Holder.FInner := TMathParser.Create(nil);
      try
        AssignDouble(Turns, 0);
        AssignDouble(InnerTurns, 0);
        Outer.AddVariable('turns', Turns);
        Other.AddVariable('turns', Turns);
        Holder.FInner.AddVariable('inner', InnerTurns);
        Holder.FCounter := @InnerTurns;
        Outer.AddFunction('call', CallHandle, fkMethod, MakeFunctionMethod(Holder.Call, 1, pkValue), False);
        Holder.FScript := nil;
        Holder.FInner.StringToScript(InnerTen, Holder.FScript);
        BurnedBudgetLeaksToStranger;
        NestedArmingRestoresTheOuterOne;
        NestedArmingKeepsTheOuterCancel;
        BudgetIsSharedWithNestedOnPurpose;
        CancelIsInheritedOnPurpose;
      finally
        Holder.FInner.Free;
      end;
    finally
      Holder.Free;
      Other.Free;
      Outer.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
