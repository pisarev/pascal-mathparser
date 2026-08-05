{ ************************************************************************** }
{                                                                            }
{ ExactTimer                                                                 }
{                                                                            }
{ Copyright © 2015 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ExactTimer;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Classes, Thread;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Forms;
  {$ELSE}
  Windows, Messages, SysUtils, Classes, Forms;
  {$ENDIF}
  {$ENDIF}

type
  TTimerType = (ttOneShot, ttPeriodic);

const
  TimerElapse = 1000;
  TimerEvent = 1;

type
  {$IFDEF FPC}
  TExactTimer = class;

  { TTimerThread }

  TTimerThread = class(TThread)
  private
    FExactTimer: TExactTimer;
  protected
    const
      WaitTime = 100;
      StopTime = 1000;
    procedure Work; override;
    procedure Done; override;
    property ExactTimer: TExactTimer read FExactTimer;
  public
    constructor Create(AOwner: TComponent); override;
  end;
  {$ENDIF}

  { TExactTimer }

  TExactTimer = class(TComponent)
  private
    FElapse: LongWord;
    {$IFNDEF FPC}
    FHandle: THandle;
    {$ENDIF}
    FOnTimer: TNotifyEvent;
    {$IFDEF FPC}
    FThread: TTimerThread;
    {$ENDIF}
    FTimerType: TTimerType;
  protected
    {$IFDEF FPC}
    property Thread: TTimerThread read FThread write FThread;
    {$ELSE}
    procedure WindowMethod(var Message: TMessage); virtual;
    property Handle: THandle read FHandle write FHandle;
    {$ENDIF}
    procedure DoTimer; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function SetTimer: Boolean; virtual;
    function StopTimer: Boolean; virtual;
  published
    property Elapse: LongWord read FElapse write FElapse default TimerElapse;
    property TimerType: TTimerType read FTimerType write FTimerType default ttPeriodic;
    property OnTimer: TNotifyEvent read FOnTimer write FOnTimer;
  end;

procedure Register;

implementation

{$IFDEF FPC}
uses
  Math;
{$ENDIF}

procedure Register;
begin
  RegisterComponents('Samples', [TExactTimer]);
end;

{$IFDEF FPC}
{ TTimerThread }

procedure TTimerThread.Work;
var
  TickCount, IdleTime: Int64;
begin
  if Assigned(FExactTimer) then
    repeat
      TickCount := GetTickCount64;
      repeat
        IdleTime := FExactTimer.Elapse - GetTickCount64 + TickCount;
        if IdleTime < 0 then Break;
        if IdleTime > WaitTime then
          Sleep(WaitTime)
        else
          Sleep(IdleTime);
      until Stopped or (IdleTime < WaitTime);
      if Stopped then Break;
      FExactTimer.DoTimer;
    until FExactTimer.TimerType = ttOneShot;
end;

procedure TTimerThread.Done;
begin
end;

constructor TTimerThread.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if AOwner is TExactTimer then FExactTimer := TExactTimer(AOwner);
end;
{$ENDIF}

{ TExactTimer }

procedure TExactTimer.DoTimer;
begin
  if Assigned(FOnTimer) then FOnTimer(Self);
end;

constructor TExactTimer.Create(AOwner: TComponent);
begin
  inherited;
  {$IFDEF FPC}
  FThread := TTimerThread.Create(Self);
  {$ELSE}
  FHandle := {$IFDEF DELPHI_XE7}System.Classes{$ELSE}Classes{$ENDIF}.AllocateHWnd(WindowMethod);
  {$ENDIF}
  FTimerType := ttPeriodic;
  FElapse := TimerElapse;
end;

destructor TExactTimer.Destroy;
begin
  StopTimer;
  {$IFNDEF FPC}
  {$IFDEF DELPHI_XE7}System.Classes{$ELSE}Classes{$ENDIF}.DeallocateHWnd(FHandle);
  {$ENDIF}
  inherited;
end;

function TExactTimer.SetTimer: Boolean;
begin
  {$IFDEF FPC}
  Result := (FElapse > 0) and Assigned(FOnTimer);
  if Result then
  begin
    if FThread.Active then
    begin
      FThread.Stop;
      if not FThread.WaitFor(TTimerThread.StopTime) then Exit(False);
    end;
    Result := FThread.Start;
  end;
  {$ELSE}
  Result := (FElapse > 0) and Assigned(FOnTimer) and
    ({$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.SetTimer(FHandle, TimerEvent, FElapse, nil) <> 0);
  {$ENDIF}
end;

function TExactTimer.StopTimer: Boolean;
begin
  {$IFDEF FPC}
  FThread.Stop;
  Result := True;
  {$ELSE}
  Result := KillTimer(FHandle, TimerEvent);
  {$ENDIF}
end;

{$IFNDEF FPC}
procedure TExactTimer.WindowMethod(var Message: TMessage);
begin
  case Message.Msg of
    WM_TIMER:
      begin
        KillTimer(FHandle, TimerEvent);
        try
          DoTimer;
        finally
          if FTimerType = ttPeriodic then SetTimer;
        end;
      end
  else
    Message.Result := DefWindowProc(FHandle, Message.Msg, Message.wParam, Message.lParam);
  end;
end;
{$ENDIF}

end.
