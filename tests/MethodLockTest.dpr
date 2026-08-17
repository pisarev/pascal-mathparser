{ ************************************************************************** }
{                                                                            }
{ MethodLockTest                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program MethodLockTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, Thread, TestKit in 'TestKit.pas';

{
  What the lock around Deriv and Parse actually guards.

  There used to be one lock for the whole unit, that is, one shared by ALL
  parsers at once. It is at the same time too wide and not enough:

  - too wide: four threads with their OWN, entirely unrelated parsers on a
    formula with Deriv queued up and computed one at a time;
  - too wide twice over: arbitrary user code ran under it - a function handler,
    an OnFunction event - and somebody else's code under your own lock is a
    ready recipe for a deadlock;
  - not enough: it does not protect against a plain ExecuteScript in a
    neighbouring thread at all, so "Deriv against a read of the same variable"
    was never covered by it.

  The lock now belongs to its own parser, and in Parse only the compilation of
  the text into a script is left under it - the one thing that really touches
  shared tables. The evaluation has been moved out.

  Both checks below are deterministic: they stop a thread INSIDE an evaluation
  and see whether the neighbour gets through. There is deliberately no timing
  here - the second one says why.
}

const
  Workers = 4;

type
  TGate = record
    Open: Boolean;
  end;

  { A formula function that stands inside the evaluation until it is released. }
  THolder = class
  private
    FInside: Boolean;
    FRelease: TGate;
  public
    function Hold(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

  { Evaluates its own formula on ITS OWN parser. }
  TWorker = class(TThread)
  private
    FParser: TMathParser;
    FValue: TValue;
    FText: string;
    FRounds: Integer;
    FNote: string;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  end;

var
  Holder: THolder;
  Shared: TMathParser;
  SharedValue: TValue;
  HoldHandle: TFunctionHandle;
  Parsers: array [0 .. Workers - 1] of TMathParser;
  Values: array [0 .. Workers - 1] of TValue;
  I: Integer;

function THolder.Hold(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  FInside := True;
  while not FRelease.Open do Sleep(2);
  Result := MakeDouble(1);
end;

procedure TWorker.Work;
var
  Script: TScript;
  R: Integer;
begin
  Script := nil;
  try
    FParser.StringToScript(FText, Script);
    for R := 1 to FRounds do FParser.ExecuteScript(Script);
  except
    on E: Exception do FNote := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TWorker.Done;
begin
  FEnded := True;
end;

function Waiting(const Ended: PBoolean; const Time: LongWord): Boolean;
var
  Spent: LongWord;
begin
  Spent := 0;
  while not Ended^ and (Spent < Time) do
  begin
    Sleep(2);
    Inc(Spent, 2);
  end;
  Result := Ended^;
end;

{ 1 }

{
  While one thread stands INSIDE an evaluation started through Parse, the
  neighbour has to get through its own Parse. On a lock shared by the unit it
  would wait for the first one to release it, that is, forever: the lock was
  held until the evaluation finished.

  The check is deterministic: the neighbouring thread does not "happen to be
  quicker", it walks over a place that is known to be occupied.
}
procedure ParseDoesNotHoldTheLockWhileRunning;
var
  Held, Quick: TWorker;
  Spent: LongWord;
begin
  BeginSection('Parse does not hold the lock while it runs');
  Holder.FInside := False;
  Holder.FRelease.Open := False;
  Held := TWorker.Create(nil);
  Held.FParser := Shared;
  Held.FText := 'Parse("hold(0)")';
  Held.FRounds := 1;
  Held.Start;
  Spent := 0;
  while not Holder.FInside and (Spent < 10000) do
  begin
    Sleep(2);
    Inc(Spent, 2);
  end;
  Check('the first thread reached the middle of its evaluation', Holder.FInside, 'never got there');
  Quick := TWorker.Create(nil);
  Quick.FParser := Shared;
  Quick.FText := 'Parse("1 + 1")';
  Quick.FRounds := 1;
  Quick.Start;
  Check('the second thread went through its own Parse while the first was busy',
    Waiting(@Quick.FEnded, 5000), 'never arrived within 5 s');
  Check('and without a refusal', Quick.FNote = '', Quick.FNote);
  Holder.FRelease.Open := True;
  Check('the first thread finished once released', Waiting(@Held.FEnded, 5000), 'never arrived');
  Held.Free;
  Quick.Free;
end;

{ 2 }

{
  Two INDEPENDENT parsers. The first is held inside Deriv - the derivative is
  evaluating an expression, and in that expression stands a function that never
  returns. The lock of its parser is occupied at that moment. The second parser
  has nothing to do with the first and must take its derivative without waiting.

  On a lock shared by the unit the second one would wait for the first.

  WHY THERE IS NO TIMING HERE. The first version of this check compared the time
  of one thread against the time of four and required the four to fit into about
  the same. It does not pass even on the fixed lock - but not because of the
  lock. Measured: plain arithmetic on four threads takes 1.4 of the time of one,
  Deriv takes 4.1. The difference is not the lock but the fact that both Deriv
  and Parse COMPILE the text into a script on every call, and compilation runs
  into the memory manager, which is shared by the whole program. A check written
  on time would declare somebody else's trouble a defect of the lock - and would
  never pass.
}
procedure IndependentParsersDoNotQueue;
var
  Held, Other: TWorker;
  Spent: LongWord;
begin
  BeginSection('independent parsers do not wait for one another');
  Holder.FInside := False;
  Holder.FRelease.Open := False;
  Held := TWorker.Create(nil);
  Held.FParser := Shared;
  Held.FText := 'Deriv("hold(0) * x", "x")';
  Held.FRounds := 1;
  Held.Start;
  Spent := 0;
  while not Holder.FInside and (Spent < 10000) do
  begin
    Sleep(2);
    Inc(Spent, 2);
  end;
  Check('the first parser is held inside Deriv', Holder.FInside, 'never got there');
  Other := TWorker.Create(nil);
  Other.FParser := Parsers[0];
  Other.FText := 'Deriv("x * x", "x")';
  Other.FRounds := 1;
  Other.Start;
  Check('the second parser took its derivative without waiting for the first',
    Waiting(@Other.FEnded, 5000), 'never arrived within 5 s');
  Check('and without a refusal', Other.FNote = '', Other.FNote);
  Holder.FRelease.Open := True;
  Check('the first one finished once released', Waiting(@Held.FEnded, 5000), 'never arrived');
  Held.Free;
  Other.Free;
end;

{ 3 }

{
  PINNING A KNOWN LIMITATION, not a check that something works.

  Deriv takes a derivative by shifting: it saves the variable, writes x-eps into
  it, evaluates, writes x+eps, evaluates, and puts the old value back. While
  that exchange is going on the variable is SHARED, and a neighbouring thread
  reading it with an ordinary ExecuteScript sees the shifted value. The lock
  around Deriv does not protect against that and never did: it is taken by the
  Deriv and Parse methods only, and a plain evaluation does not ask for it.

  The check below holds the first thread INSIDE the derivative and shows that
  the second one reads x-eps instead of x. It is green on correct code because
  it records what is, and it will go red if the behaviour changes - at which
  point the contract in the README has to be corrected too, rather than the
  change quietly celebrated.

  The arrangement under which this does not happen is documented: every thread
  gets its OWN variable through redirection. That is checked separately, in
  ThreadShareTest: four threads, six thousand evaluations each, one parser, all
  answers right.

  The real cure is to stop moving the shared variable and give the two
  evaluations of the derivative their own x-eps and x+eps. That changes the
  algorithm of Deriv itself and so belongs to a separate piece of work.
}
procedure DerivPublishesItsShiftedVariable;
var
  Held: TWorker;
  Spent: LongWord;
  Seen: Double;
begin
  BeginSection('a known limitation: Deriv shows the variable while it is shifted');
  Holder.FInside := False;
  Holder.FRelease.Open := False;
  AssignDouble(SharedValue, 5);
  Held := TWorker.Create(nil);
  Held.FParser := Shared;
  Held.FText := 'Deriv("hold(0) * x", "x")';
  Held.FRounds := 1;
  Held.Start;
  Spent := 0;
  while not Holder.FInside and (Spent < 10000) do
  begin
    Sleep(2);
    Inc(Spent, 2);
  end;
  Check('the derivative is held in the middle', Holder.FInside, 'never got there');
  Seen := GetDouble(SharedValue);
  Check('the neighbouring thread sees NOT the original 5 but the shifted value',
    Abs(Seen - 5) > 1E-9, Format('%g', [Seen]));
  Check('the shift is exactly eps, not garbage', Abs(Abs(Seen - 5) - 0.001) < 1E-9,
    Format('shift %g', [Abs(Seen - 5)]));
  Holder.FRelease.Open := True;
  Check('the derivative finished once released', Waiting(@Held.FEnded, 5000), 'never arrived');
  Check('and put the variable back', Abs(GetDouble(SharedValue) - 5) < 1E-9,
    Format('%g', [GetDouble(SharedValue)]));
  Held.Free;
end;

begin
  try
    Holder := THolder.Create;
    Shared := TMathParser.Create(nil);
    try
      Shared.AddFunction('hold', HoldHandle, fkMethod, MakeFunctionMethod(Holder.Hold, 1, pkValue), False);
      { Deriv differentiates BY A VARIABLE: without one it returns at once having
        computed nothing, and there would be nowhere to stop inside. }
      AssignDouble(SharedValue, 1.3);
      Shared.AddVariable('x', SharedValue);
      for I := 0 to Workers - 1 do
      begin
        Parsers[I] := TMathParser.Create(nil);
        AssignDouble(Values[I], 0.7 + I);
        Parsers[I].AddVariable('x', Values[I]);
      end;
      try
        ParseDoesNotHoldTheLockWhileRunning;
        IndependentParsersDoNotQueue;
        DerivPublishesItsShiftedVariable;
      finally
        for I := 0 to Workers - 1 do Parsers[I].Free;
      end;
    finally
      Shared.Free;
      Holder.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
