{ ************************************************************************** }
{                                                                            }
{ ThreadWaitTest                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
{ The contract of TThread.WaitFor.

  In Delphi it is one line:

    Result := FStarted and (WaitForSingleObject(FHandle, Time) <> WAIT_TIMEOUT);

  that is, True only when the thread was started AND finished within the time
  given. FPC has a Sleep loop instead of a kernel wait, and nothing ever checked
  that its behaviour matches Delphi.

  This bench sets up three states and compares the answer against that contract.
  It builds and runs the same way on Delphi, FPC/Windows and FPC/Linux. }
program ThreadWaitTest;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  {$IFDEF FPC}Interfaces,{$ENDIF}
  SysUtils, DateUtils, Classes, Forms, Thread, TestKit in 'TestKit.pas';

type
  { A thread that just sleeps for a given time. }
  TSleeper = class(TThread)
  private
    FLifeTime: LongWord;
  protected
    procedure Work; override;
    procedure Done; override;
  public
    property LifeTime: LongWord read FLifeTime write FLifeTime;
  end;

procedure TSleeper.Work;
begin
  Sleep(FLifeTime);
end;

procedure TSleeper.Done;
begin
end;

{ Waits until the thread has really taken off: Start only asks the system to
  create it, and without this pause the measurement lands in the gap where the
  flag is already set but the thread has not begun. }
procedure Settle;
begin
  Sleep(50);
end;

procedure TestNotStarted;
var
  T: TSleeper;
begin
  BeginSection('WaitFor: the thread was never started');
  T := TSleeper.Create(nil);
  try
    T.LifeTime := 100;
    Check('a thread that was not started gives False', not T.WaitFor(200));
  finally
    T.Free;
  end;
end;

procedure TestTimeout;
var
  T: TSleeper;
  Started: TDateTime;
  Res: Boolean;
  Spent: Int64;
begin
  BeginSection('WaitFor: the time ran out');
  T := TSleeper.Create(nil);
  try
    T.LifeTime := 3000;
    T.Start;
    Settle;
    Started := Now;
    Res := T.WaitFor(300);
    Spent := MilliSecondsBetween(Now, Started);
    Check('gives False when the time runs out', not Res, BoolToStr(Res, True));
    { the upper bound is generous: the FPC loop steps in 100 ms, plus the scheduler }
    Check('waits about the time given, not longer', (Spent >= 200) and (Spent < 1500),
      IntToStr(Spent) + ' ms');
    T.Abort;
  finally
    T.Free;
  end;
end;

procedure TestCompleted;
var
  T: TSleeper;
  Res: Boolean;
begin
  BeginSection('WaitFor: the thread finished in time');
  T := TSleeper.Create(nil);
  try
    T.LifeTime := 200;
    T.Start;
    Settle;
    Res := T.WaitFor(3000);
    Check('gives True when it finishes in time', Res, BoolToStr(Res, True));
    Check('the thread is no longer active', not T.Active);
  finally
    T.Free;
  end;
end;

procedure TestZeroTime;
var
  T: TSleeper;
begin
  BeginSection('WaitFor: zero time');
  T := TSleeper.Create(nil);
  try
    T.LifeTime := 1000;
    T.Start;
    Settle;
    { Delphi: WaitForSingleObject(H, 0) on a live thread gives WAIT_TIMEOUT }
    Check('zero time on a live thread gives False', not T.WaitFor(0));
    T.Abort;
  finally
    T.Free;
  end;
end;

var
  Failed: Integer;
begin
  {$IFDEF FPC}
  Application.Initialize;
  {$ENDIF}
  TestNotStarted;
  TestZeroTime;
  TestTimeout;
  TestCompleted;
  Failed := TestSummary;
  ExitCode := Failed;
end.
