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
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ParseJit.Parser, ValueTypes, ValueUtils, Thread,
  TestKit in 'TestKit.pas';

const
  Deadline = 10000;
  KillAfter = 1500;
  TenWhile = 'While(cnt < 10, Set("cnt", cnt + 1))';
  TenRepeat = 'Repeat(Set("cnt", cnt + 1), cnt >= 10)';
  TenFor = 'For("cnt", 0, cnt < 10, Set("cnt", cnt + 1))';
  EndlessWhile = 'While(1 = 1, Set("cnt", cnt + 1))';
  EndlessRepeat = 'Repeat(Set("cnt", cnt + 1), 1 = 0)';
  EndlessFor = 'For("cnt", 0, 1 = 1, Set("cnt", cnt + 1))';
  OuterSet = 'Set("mark", While(1 = 1, 1))';
  LoopInSum = 'Set("cnt", 0) + While(cnt < 10, Set("cnt", cnt + 1)) + cnt';

type
  TFormulaThread = class(TThread)
  private
    FText: string;
    FNote: string;
    FBudget: NativeInt;
    FWatched: Boolean;
    FTwice: Boolean;
    FJit: Boolean;
    FMachine: Boolean;
    FValue: Double;
    FHasValue: Boolean;
    FStarted: Boolean;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  public
    property Text: string read FText write FText;
    property Note: string read FNote;
    property Budget: NativeInt read FBudget write FBudget;
    property Watched: Boolean read FWatched write FWatched;
    property Twice: Boolean read FTwice write FTwice;
    property Jit: Boolean read FJit write FJit;
    property Machine: Boolean read FMachine;
    property Value: Double read FValue;
    property HasValue: Boolean read FHasValue;
    property Begun: Boolean read FStarted;
    property Ended: Boolean read FEnded;
  end;

var
  P: TMathParser;
  J: TJitParser;
  Mark: TValue;
  Last: TFormulaThread;
  Cnt: TValue;
  Killed: Boolean;
  Threads: array [0 .. 63] of TFormulaThread;
  ThreadCount: Integer;

const
  MachineCodeExists = {$IFDEF CPUX64}True{$ELSE}False{$ENDIF};

procedure TFormulaThread.Work;
var
  Script: TScript;
  Compiled: TJitScript;
  Answer: PValue;

  procedure Plain;
  begin
    if FTwice then
      try
        P.ExecuteScript(Script);
      except
      end;
    Answer := P.ExecuteScript(Script);
    if Assigned(Answer) then
    begin
      FValue := GetDouble(Answer^);
      FHasValue := True;
    end;
  end;

  procedure Accelerated;
  begin
    Compiled := J.CompileScript(Script);
    try
      FMachine := Compiled.Ready;
      if FMachine then
      begin
        if FTwice then
          try
            Compiled.Execute;
          except
          end;
        FValue := Compiled.Execute;
        FHasValue := True;
      end
      else begin
        if FTwice then
          try
            J.ExecuteScript(Script);
          except
          end;
        Answer := J.ExecuteScript(Script);
        if Assigned(Answer) then
        begin
          FValue := GetDouble(Answer^);
          FHasValue := True;
        end;
      end;
    finally
      Compiled.Free;
    end;
  end;

begin
  ParseLoopLeft := FBudget;
  if FWatched then
    ParseBreak := StopFlag
  else
    ParseBreak := nil;
  FStarted := True;
  Script := nil;
  try
    if FJit then
    begin
      J.StringToScript(FText, Script);
      Accelerated;
    end
    else begin
      P.StringToScript(FText, Script);
      Plain;
    end;
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

function Run(const AText: string; const Budget: NativeInt; const Watched: Boolean;
  const RaiseAfter: LongWord = 0; const Twice: Boolean = False; const Jit: Boolean = False): string;
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
  T.Jit := Jit;
  Last := T;
  T.Start;
  if RaiseAfter > 0 then
  begin
    Waited := 0;
    while not T.Begun and (Waited < RaiseAfter) do
    begin
      Sleep(5);
      Inc(Waited, 5);
    end;
    Sleep(RaiseAfter);
    T.Stop;
  end;
  if Waiting(T, Deadline) then
    Result := T.Note
  else begin
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

function MarkValue: Double;
begin
  Result := GetDouble(Mark);
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
  Note := Run(TenWhile, 11, False);
  Check('a budget of 11 covers 10 turns', Note = '', Note);
  CheckDouble('the counter reached the end', Turns, 10);
  Note := Run(TenWhile, 5, False);
  Check('a budget of 5 is not enough', Pos('Loop limit', Note) > 0, Note);
  CheckDouble('the counter stopped on the fourth turn', Turns, 4);
  Note := Run(EndlessWhile, 10000, False, 0, True);
  Check('after a spent budget the second run is refused too', Pos('Loop limit', Note) > 0, Note);
  Note := Run(TenWhile, 0, False);
  Check('zero means no limit', Note = '', Note);
  CheckDouble('the counter reached the end', Turns, 10);
end;

procedure BreakFlagStopsLoop;
var
  Note: string;
begin
  BeginSection('somebody else''s flag stops the loop');
  Note := Run(EndlessWhile, 100000000, True, 150);
  Check('an endless While is stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Note := Run(EndlessRepeat, 100000000, True, 150);
  Check('an endless Repeat is stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Note := Run(EndlessFor, 100000000, True, 150);
  Check('an endless For is stopped by the flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Note := Run(TenWhile, 0, True);
  Check('with the flag down the loop runs', Note = '', Note);
  CheckDouble('and reaches the end', Turns, 10);
end;

procedure AcceleratorHonoursTheGuard;
var
  Note: string;
begin
  BeginSection('the accelerator obeys the same guard');
  Note := Run(EndlessWhile, 10000, False, 0, False, True);
  Check('the endless While went as machine code where the emitter exists',
    Last.Machine or not MachineCodeExists,
    'the accelerator declined the loop, so nothing here was measured: ' + Note);
  Check('While: the turn limit is named', Pos('Loop limit', Note) > 0, Note);
  Note := Run(EndlessRepeat, 10000, False, 0, False, True);
  Check('the endless Repeat went as machine code where the emitter exists',
    Last.Machine or not MachineCodeExists,
    'the accelerator declined the loop, so nothing here was measured: ' + Note);
  Check('Repeat: the turn limit is named', Pos('Loop limit', Note) > 0, Note);
  Note := Run(TenWhile, 11, False, 0, False, True);
  Check('eleven turns of budget are enough for ten', Note = '', Note);
  CheckDouble('the counter reached the end', Turns, 10);
  Note := Run(TenWhile, 5, False, 0, False, True);
  Check('five turns of budget are not enough', Pos('Loop limit', Note) > 0, Note);
  CheckDouble('the counter stopped on the fourth turn', Turns, 4);
  Note := Run(EndlessWhile, 10000, False, 0, True, True);
  Check('after a spent budget the second run refuses too', Pos('Loop limit', Note) > 0, Note);
  Note := Run(EndlessWhile, 100000000, True, 150, False, True);
  Check('the accelerator hears the cancellation flag', Pos('stopped', LowerCase(Note)) > 0, Note);
  Note := Run(TenWhile, 0, False, 0, False, True);
  Check('with no guard the accelerator counts to the end', Note = '', Note);
  CheckDouble('ten turns', Turns, 10);
  Note := Run(EndlessFor, 10000, False, 0, False, True);
  Check('For: the turn limit is named', Pos('Loop limit', Note) > 0, Note);
end;

procedure AbortStopsTheWholeEvaluation;
var
  Note: string;
begin
  BeginSection('a refusal stops the whole evaluation');
  AssignDouble(Mark, 123);
  Note := Run(OuterSet, 1, False);
  Check('interpreter: the turn limit is named', Pos('Loop limit', Note) > 0, Note);
  CheckDouble('interpreter: mark was not written after the refusal', MarkValue, 123);
  AssignDouble(Mark, 123);
  Note := Run(OuterSet, 1, False, 0, False, True);
  Check('accelerator: the loop went as machine code where the emitter exists',
    Last.Machine or not MachineCodeExists,
    'the accelerator declined the loop, so nothing here was measured: ' + Note);
  Check('accelerator: the turn limit is named', Pos('Loop limit', Note) > 0, Note);
  CheckDouble('accelerator: mark was not written after the refusal', MarkValue, 123);
end;

procedure SameValueFromBothExecutors(const Formula: string; const Budget: NativeInt);
var
  Note: string;
  SlowValue, FastValue: Double;
  HadSlow, HadFast: Boolean;
begin
  Note := Run(Formula, Budget, False);
  Check('interpreter: counted to the end', Note = '', Note);
  HadSlow := Last.HasValue;
  SlowValue := Last.Value;
  Note := Run(Formula, Budget, False, 0, False, True);
  Check('accelerator: counted to the end', Note = '', Note);
  HadFast := Last.HasValue;
  FastValue := Last.Value;
  Check('both executors returned a value', HadSlow and HadFast,
    Format('interpreter %d, accelerator %d', [Ord(HadSlow), Ord(HadFast)]));
  Check('accelerator: the value is the interpreter''s value',
    (not (HadSlow and HadFast)) or (Abs(FastValue - SlowValue) < 1E-9),
    Format('interpreter %.6f, accelerator %.6f', [SlowValue, FastValue]));
end;

procedure ArmedGuardChangesNothing;
begin
  BeginSection('an armed guard leaves an honest count alone');
  SameValueFromBothExecutors(TenWhile, 1000);
  SameValueFromBothExecutors(TenRepeat, 1000);
  SameValueFromBothExecutors(LoopInSum, 1000);
  SameValueFromBothExecutors(LoopInSum, 0);
end;

procedure GuardCapacityBoundary;
var
  N, Shape, Mode, Path, I: Integer;
  Formula, LabelText, SlowError, ActualError: string;
  Script: TScript;
  Compiled: TJitScript;
  Stopped: Boolean;
  SlowCount, SlowMark, SlowValue, ActualValue, Dummy: Double;
  Inputs, Outputs: array[0..0] of Double;
begin
  BeginSection('guard capacity: scalar, compiled and bulk evaluation');
  Compiled := nil;
  Inputs[0] := 0;
  Dummy := 0;
  try
    for N := 63 to 65 do
      for Shape := 0 to 1 do
      begin
        Formula := '';
        for I := 1 to N - 1 - 2 * Shape do
          Formula := Formula + 'While(cnt < 0, Set("cnt", cnt + 1)) + ';
        if Shape = 1 then
          Formula := Formula + 'While(cnt < 0, While(cnt < 0, 1)) + ';
        Formula := 'Set("mark", ' + Formula + 'Repeat(Set("cnt", cnt + 1), cnt >= 5))';
        Script := nil;
        J.StringToScript(Formula, Script);
        Compiled := J.CompileScript(Script);
        {$IFDEF CPUX64}
        if N <= 64 then
          Check('within guard capacity uses machine code',
            Assigned(Compiled.Code) and Compiled.Code.Ready, Compiled.Reason)
        else
          Check('over guard capacity refuses incomplete machine code',
            Assigned(Compiled.Code) and not Compiled.Code.Ready and
            (Pos('too many loop guards in one script', Compiled.Reason) > 0),
            Compiled.Reason);
        {$ENDIF}
        for Mode := 0 to 2 do
        begin
          SlowError := '';
          SlowValue := 0;
          for Path := 0 to 3 do
          begin
            AssignDouble(Cnt, 0);
            AssignDouble(Mark, 123);
            Stopped := Mode = 2;
            ParseBreak := @Stopped;
            if Mode = 1 then
              ParseLoopLeft := 2
            else
              ParseLoopLeft := 0;
            ActualError := '';
            ActualValue := 0;
            try
              case Path of
                0: ActualValue := P.AsDouble(Formula);
                1: if Compiled.Ready then ActualValue := Compiled.Execute
                   else
                     ActualValue := GetDouble(J.ExecuteScript(Script)^);
                2: ActualValue := J.AsDouble(Formula);
                3:
                begin
                  Check('bulk boundary formula accepted',
                    J.ExecuteMany(Formula, Dummy, Inputs, Outputs), '');
                  ActualValue := Outputs[0];
                end;
              end;
            except
              on E: Exception do ActualError := E.ClassName + ': ' + E.Message;
            end;
            LabelText := Format('guards=%d nested=%d mode=%d path=%d', [N, Shape, Mode, Path]);
            if Path = 0 then
            begin
              SlowError := ActualError;
              SlowCount := GetDouble(Cnt);
              SlowMark := GetDouble(Mark);
              SlowValue := ActualValue;
              Check(LabelText + ' interpreter guard', (Mode = 0) = (SlowError = ''), SlowError);
              if Mode = 0 then
                CheckDouble(LabelText + ' finite count', SlowCount, 5)
              else
                CheckDouble(LabelText + ' outer assignment not executed', SlowMark, 123);
            end
            else begin
              Check(LabelText + ' exception matches', ActualError = SlowError,
                ActualError + ' / ' + SlowError);
              CheckDouble(LabelText + ' counter matches', GetDouble(Cnt), SlowCount);
              CheckDouble(LabelText + ' outer assignment matches', GetDouble(Mark), SlowMark);
              if SlowError = '' then
                CheckDouble(LabelText + ' result matches', ActualValue, SlowValue);
            end;
          end;
        end;
        FreeAndNil(Compiled);
      end;
  finally
    Compiled.Free;
    ParseBreak := nil;
    ParseLoopLeft := 0;
  end;
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
    J := TJitParser.Create(nil);
    try
      AssignDouble(Cnt, 0);
      P.AddVariable('cnt', Cnt);
      J.AddVariable('cnt', Cnt);
      AssignDouble(Mark, 123);
      P.AddVariable('mark', Mark);
      J.AddVariable('mark', Mark);
      UnarmedGuardChangesNothing;
      BudgetStopsEndlessLoop;
      BudgetCountsTurns;
      BreakFlagStopsLoop;
      AcceleratorHonoursTheGuard;
      AbortStopsTheWholeEvaluation;
      ArmedGuardChangesNothing;
      GuardCapacityBoundary;
      MeasureTurnRate;
      if not Killed then
        for ThreadCount := ThreadCount - 1 downto 0 do Threads[ThreadCount].Free;
      if Killed then
        Fail('a thread had to be killed', 'a formula did not stop in time - the loop guard is not working');
    finally
      if not Killed then P.Free;
      if not Killed then J.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
