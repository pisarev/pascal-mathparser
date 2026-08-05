{ ************************************************************************** }
{                                                                            }
{ SyncThread                                                                 }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit SyncThread;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, ExactTimer, Thread;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, WinApi.Messages, System.Classes, Vcl.Forms, Thread;
  {$ELSE}
  Windows, Messages, Classes, Forms, Thread;
  {$ENDIF}
  {$ENDIF}

const
  SyncTime = 10;

type
  { TSyncTimer }

  {$IFDEF FPC}
  TSyncTimer = class(TComponent)
  private
    FElapse: Integer;
    FLock: TRTLCriticalSection;
    FTimer: TExactTimer;
    FUpdateCount: Integer;
  protected
    procedure Timer(Sender: TObject); virtual;
    property Lock: TRTLCriticalSection read FLock write FLock;
    property UpdateCount: Integer read FUpdateCount write FUpdateCount;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetTimer; virtual;
    procedure StopTimer; virtual;
  published
    property Elapse: Integer read FElapse write FElapse default SyncTime;
  end;
  {$ELSE}
  TSyncTimer = class(TComponent)
  private
    FUpdateCount: Integer;
    FHandle: THandle;
    FLock: TRTLCriticalSection;
    FElapse: Integer;
  protected
    procedure WindowMethod(var Message: TMessage); virtual;
    property Handle: THandle read FHandle write FHandle;
    property UpdateCount: Integer read FUpdateCount write FUpdateCount;
    property Lock: TRTLCriticalSection read FLock write FLock;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetTimer; virtual;
    procedure StopTimer; virtual;
  published
    property Elapse: Integer read FElapse write FElapse default SyncTime;
  end;
  {$ENDIF}

  TSyncThread = class;

  TSyncMethod = procedure(Thread: TSyncThread) of object;

  TSyncThread = class(TThread)
  private
    FTimer: TSyncTimer;
    FOnDone: TSyncMethod;
    FOnWork: TSyncMethod;
  protected
    {$IFNDEF FPC}
    procedure Notification(Component: TComponent; Operation: TOperation); override;
    {$ENDIF}
    procedure Work; override;
    procedure Done; override;
    procedure DoWork; virtual;
    procedure DoDone; virtual;
  public
    procedure Synchronize(const AMethod: TThreadMethod); override;
    function Start: Boolean; override;
  published
    property Timer: TSyncTimer read FTimer write FTimer;
    property OnWork: TSyncMethod read FOnWork write FOnWork;
    property OnDone: TSyncMethod read FOnDone write FOnDone;
  end;

const
  TimerEvent = MaxInt;

procedure Register;

implementation

uses
  {$IFDEF FPC}
  SysUtils;
  {$ELSE}
  SysUtils, ThreadUtils;
  {$ENDIF}

procedure Register;
begin
  RegisterComponents('Samples', [TSyncTimer, TSyncThread]);
end;

{ TSyncTimer }

{$IFDEF FPC}
procedure TSyncTimer.Timer(Sender: TObject);
begin
  try
    CheckSynchronize;
  except
    on E: Exception do Writeln(ErrOutput, 'synchronized method raised: ', E.Message);
  end
end;

constructor TSyncTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FElapse := SyncTime;
  FTimer := TExactTimer.Create(Self);
  FTimer.Elapse := FElapse;
  FTimer.TimerType := ttPeriodic;
  FTimer.OnTimer := Timer;
  InitCriticalSection(FLock);
end;

destructor TSyncTimer.Destroy;
begin
  StopTimer;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TSyncTimer.SetTimer;
begin
  EnterCriticalSection(FLock);
  try
    if FUpdateCount = 0 then
      if (FElapse > 0) and ([csLoading, csDestroying] * ComponentState = []) then
      begin
        FTimer.Elapse := FElapse;
        FTimer.SetTimer;
      end;
    Inc(FUpdateCount);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TSyncTimer.StopTimer;
begin
  EnterCriticalSection(FLock);
  try
    if FUpdateCount > 0 then Dec(FUpdateCount);
    if FUpdateCount = 0 then FTimer.StopTimer;
  finally
    LeaveCriticalSection(FLock);
  end;
end;
{$ELSE}
constructor TSyncTimer.Create(AOwner: TComponent);
begin
  inherited;
  FElapse := SyncTime;
  FHandle := AllocateHWnd(WindowMethod);
  InitializeCriticalSection(FLock);
end;

procedure TSyncTimer.StopTimer;
begin
  Enter(FLock);
  try
    Dec(FUpdateCount);
    if FUpdateCount = 0 then KillTimer(FHandle, TimerEvent);
  finally
    Leave(FLock);
  end;
end;

destructor TSyncTimer.Destroy;
begin
  StopTimer;
  DeallocateHWnd(FHandle);
  DeleteCriticalSection(FLock);
  inherited;
end;

procedure TSyncTimer.SetTimer;
begin
  Enter(FLock);
  try
    if FUpdateCount = 0 then
      if {$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.SetTimer(FHandle, TimerEvent, FElapse, nil) = 0 then
        RaiseLastOSError;
    Inc(FUpdateCount);
  finally
    Leave(FLock);
  end;
end;

procedure TSyncTimer.WindowMethod(var Message: TMessage);
begin
  if Message.Msg = WM_TIMER then
    try
      CheckSynchronize;
    except
      Application.HandleException(Self);
    end
    else
      Message.Result := DefWindowProc(FHandle, Message.Msg, Message.WParam, Message.LParam);
end;
{$ENDIF}

{ TSyncThread }

procedure TSyncThread.DoDone;
begin
  if Assigned(FOnDone) then
    if MainThread then FOnDone(Self)
    {$IFDEF FPC}
    else
      Classes.TThread.Synchronize(nil, DoDone);
    {$ELSE}
    else
      Synchronize(DoDone);
    {$ENDIF}
end;

procedure TSyncThread.Done;
begin
  DoDone;
  if Assigned(FTimer) then FTimer.StopTimer;
end;

procedure TSyncThread.DoWork;
begin
  if Assigned(FOnWork) then FOnWork(Self);
end;

{$IFNDEF FPC}
procedure TSyncThread.Notification(Component: TComponent; Operation: TOperation);
begin
  inherited;
  if (Component = FTimer) and (Operation = opRemove) then FTimer := nil;
end;
{$ENDIF}

function TSyncThread.Start: Boolean;
begin
  if Assigned(FTimer) then FTimer.SetTimer;
  Result := inherited Start;
end;

procedure TSyncThread.Synchronize(const AMethod: TThreadMethod);
begin
  if Assigned(FTimer) then inherited Synchronize(AMethod);
end;

procedure TSyncThread.Work;
begin
  DoWork;
end;
end.
