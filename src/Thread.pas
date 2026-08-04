{ ************************************************************************** }
{                                                                            }
{ Thread                                                                     }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit Thread;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Classes{$IFNDEF NOFORMS}, Forms{$ENDIF};
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms;
  {$ELSE}
  Windows, SysUtils, Classes, Forms;
  {$ENDIF}
  {$ENDIF}

const
  {$IFDEF FPC}
  DefaultStackSize = 4194304;
  {$ELSE}
  DefaultStackSize = 0;
  {$ENDIF}
  DefaultSuspended = False;
  DefaultPriority = tpNormal;
  DefaultAbortTime = 100;

type
  PSynchronizeData = ^TSynchronizeData;
  TSynchronizeData = record
    Thread: TObject;
    Method: TThreadMethod;
    {$IFDEF FPC}
    Processed: Boolean;
    {$ELSE}
    Event: THandle;
    {$ENDIF}
  end;
  { TThread }

  TThread = class(TComponent)
  private
    FAborted: Boolean;
    FAbortTime: Integer;
    FFatalException: TObject;
    {$IFNDEF FPC}
    FHandle: THandle;
    {$ENDIF}
    FPriority: TThreadPriority;
    FReturn: Integer;
    FStackSize: Integer;
    FStarted: Boolean;
    FStopped: Boolean;
    FSuspended: Boolean;
    FThreadId: {$IFDEF FPC}TThreadID{$ELSE}LongWord{$ENDIF};
    function GetActive: Boolean;
    function GetFinished: Boolean;
    procedure SetPriority(const Value: TThreadPriority);
    procedure SetSuspended(const Value: Boolean);
  protected
    {$IFNDEF FPC}
    procedure CheckThreadError(const ErrorCode: Integer); overload; virtual;
    procedure CheckThreadError(const Success: Boolean); overload; virtual;
    {$ENDIF}
    procedure Synchronize(const Data: PSynchronizeData); overload; virtual;
    procedure Work; virtual; abstract;
    procedure Done; virtual; abstract;
    property Return: Integer read FReturn write FReturn;
    property Started: Boolean read FStarted write FStarted;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Synchronize(const Method: TThreadMethod); overload; virtual;
    function Resume: Integer; virtual;
    function Start: Boolean; virtual;
    function Suspend: Integer; virtual;
    procedure Stop; virtual;
    function Abort: Boolean; virtual;
    function WaitFor(const Time: LongWord = 0): Boolean; virtual;
    procedure RaiseFatalException; virtual;
    property Active: Boolean read GetActive;
    property Aborted: Boolean read FAborted;
    property Stopped: Boolean read FStopped write FStopped;
    {$IFNDEF FPC}
    property Handle: THandle read FHandle;
    {$ENDIF}
    property ThreadId: {$IFDEF FPC}TThreadID{$ELSE}LongWord{$ENDIF} read FThreadId;
    property Finished: Boolean read GetFinished;
    property FatalException: TObject read FFatalException write FFatalException;
  published
    property StackSize: Integer read FStackSize write FStackSize default DefaultStackSize;
    property Suspended: Boolean read FSuspended write SetSuspended default DefaultSuspended;
    property Priority: TThreadPriority read FPriority write SetPriority default DefaultPriority;
    property AbortTime: Integer read FAbortTime write FAbortTime default DefaultAbortTime;
  end;

const
  {$IFDEF FPC}
  SCheckSynchronizeError = 'CheckSynchronize called from thread $%x, which is NOT the main thread';
  Priorities: array[TThreadPriority] of Integer = (-15, -10, -5, 0, 5, 10, 15);
  {$ELSE}
  ThreadCreateError = 'Thread creation error: %s';
  ThreadError = 'Thread error: %s (%d)';
  STACK_SIZE_PARAM_IS_A_RESERVATION = $00010000;
  Priorities: array [TThreadPriority] of Integer = (
    THREAD_PRIORITY_IDLE, THREAD_PRIORITY_LOWEST, THREAD_PRIORITY_BELOW_NORMAL, THREAD_PRIORITY_NORMAL,
    THREAD_PRIORITY_ABOVE_NORMAL, THREAD_PRIORITY_HIGHEST, THREAD_PRIORITY_TIME_CRITICAL);
  {$ENDIF}

var
  SyncList: TList = nil;
  ThreadSync: TRTLCriticalSection;

function MainThread: Boolean;
function CheckSynchronize: Boolean;
function ClearSyncList(const Thread: TObject = nil): Integer;

implementation

{$IFNDEF FPC}
uses
  {$IFDEF DELPHI_XE7}
  System.RTLConsts;
  {$ELSE}
  RTLConsts;
  {$ENDIF}
{$ENDIF}

function MainThread: Boolean;
begin
  Result := GetCurrentThreadId = MainThreadId;
end;

{$IFDEF FPC}
function ThreadMethod(P: Pointer): Integer;
var
  Thread: TThread absolute P;
begin
  FreeAndNil(Thread.FFatalException);
  try
    if not Thread.Stopped then
      try
        Thread.Work;
      except
        if Assigned(Thread.FFatalException) then Thread.FFatalException.Free;
        Thread.FFatalException := AcquireExceptionObject;
      end;
  finally
    try
      Thread.Done;
    finally
      Result := Thread.FReturn;
      Thread.FStarted := False;
      Thread.FStopped := True;
      EndThread(Result);
    end;
  end;
end;
{$ELSE}
function ThreadMethod(Thread: TThread): Integer;
begin
  FreeAndNil(Thread.FFatalException);
  try
    if not Thread.Stopped then
      try
        Thread.Work;
      except
        if Assigned(Thread.FFatalException) then Thread.FFatalException.Free;
        Thread.FFatalException := AcquireExceptionObject;
      end;
  finally
    try
      Thread.Done;
    finally
      Result := Thread.FReturn;
      Thread.FStarted := False;
      Thread.FStopped := True;
      EndThread(Result);
      CloseHandle(Thread.Handle);
    end;
  end;
end;
{$ENDIF}

function CheckSynchronize: Boolean;
{$IFDEF FPC}
begin
  Result := Classes.CheckSynchronize;
end;
{$ELSE}
var
  List: TList;
  I: Integer;
  Data: PSynchronizeData;
begin
  if GetCurrentThreadID <> MainThreadID then
    {$IFDEF FPC}
    raise EThread.CreateFmt(SCheckSynchronizeError, [GetCurrentThreadID]);
    {$ELSE}
    raise EThread.CreateResFmt(@SCheckSynchronizeError, [GetCurrentThreadID]);
    {$ENDIF}
  List := nil;
  EnterCriticalSection(ThreadSync);
  try
    List := SyncList;
    SyncList := nil;
    try
      Result := Assigned(List) and (List.Count > 0);
      if Result then
      begin
        for I := 0 to List.Count - 1 do
        begin
          Data := List[I];
          LeaveCriticalSection(ThreadSync);
          try
            try
              Data.Method;
            except
              {$IF Defined(FPC) and Defined(NOFORMS)}
              on E: Exception do Writeln(ErrOutput, 'synchronized method raised: ', E.Message);
              {$ELSE}
              Application.HandleException(Data.Thread);
              {$IFEND}
            end;
          finally
            EnterCriticalSection(ThreadSync);
          end;
          {$IFDEF FPC}
          Data.Processed := True;
          {$ELSE}
          SetEvent(Data.Event);
          {$ENDIF}
        end;
      end;
    finally
      List.Free;
    end;
  finally
    LeaveCriticalSection(ThreadSync);
  end;
end;
{$ENDIF}

function ClearSyncList(const Thread: TObject): Integer;
var
  I: Integer;
  Data: PSynchronizeData;
begin
  Result := 0;
  EnterCriticalSection(ThreadSync);
  try
    if Assigned(SyncList) then
      for I := SyncList.Count - 1 downto 0 do
      begin
        Data := SyncList[I];
        if (Thread = nil) or (Data.Thread = Thread) then
        begin
          SyncList.Delete(I);
          {$IFNDEF FPC}
          CloseHandle(Data.Event);
          {$ENDIF}
          Inc(Result);
        end;
      end;
  finally
    LeaveCriticalSection(ThreadSync);
  end;
end;

{ TThread }

function TThread.Abort: Boolean;
begin
  Result := FStarted;
  if Result then
  begin
    Stop;
    {$IFDEF FPC}
    Result := not WaitFor(FAbortTime) and (KillThread(FThreadID) = 0);
    {$ELSE}
    Result := (WaitForSingleObject(FHandle, FAbortTime) = WAIT_TIMEOUT) and TerminateThread(FHandle, 0);
    {$ENDIF}
    if Result then
    begin
      FStarted := False;
      FAborted := True;
      FStopped := True;
      Done;
    end;
  end;
end;

{$IFNDEF FPC}
procedure TThread.CheckThreadError(const ErrorCode: Integer);
begin
  if ErrorCode <> 0 then
    raise EThread.CreateFmt(ThreadError, [SysErrorMessage(ErrorCode), ErrorCode]);
end;

procedure TThread.CheckThreadError(const Success: Boolean);
begin
  if not Success then CheckThreadError(GetLastError);
end;
{$ENDIF}

constructor TThread.Create(AOwner: TComponent);
begin
  inherited;
  FStopped := True;
  FStackSize := DefaultStackSize;
  FSuspended := DefaultSuspended;
  FPriority := DefaultPriority;
  FAbortTime := DefaultAbortTime;
end;

destructor TThread.Destroy;
begin
  if FStarted then
  begin
    if FSuspended then Resume;
    Abort;
  end;
  {$IFNDEF FPC}
  if FHandle <> 0 then CloseHandle(FHandle);
  {$ENDIF}
  FFatalException.Free;
  inherited;
end;

function TThread.GetActive: Boolean;
begin
  Result := FStarted;
end;

function TThread.GetFinished: Boolean;
begin
  Result := not FStarted;
end;

procedure TThread.RaiseFatalException;
begin
  if Assigned(FFatalException) then
    try
      raise FFatalException;
    finally
      FFatalException := nil;
    end;
end;

function TThread.Resume: Integer;
begin
  {$IFDEF FPC}
  Result := ResumeThread(FThreadID);
  FSuspended := Result = 0;
  {$ELSE}
  if FSuspended then
  begin
    Result := ResumeThread(FHandle);
    FSuspended := False;
  end
  else
    Result := 0
  {$ENDIF}
end;

procedure TThread.SetPriority(const Value: TThreadPriority);
begin
  if Value <> FPriority then
  begin
    FPriority := Value;
    if FStarted then
      {$IFDEF FPC}
      ThreadSetPriority(FThreadID, Priorities[Value]);
      {$ELSE}
      CheckThreadError(SetThreadPriority(FHandle, Priorities[Value]));
      {$ENDIF}
  end;
end;

procedure TThread.SetSuspended(const Value: Boolean);
begin
  if Value <> FSuspended then
    if not FStarted then
      FSuspended := Value
    else
      if Value then Suspend
      else
        Resume;
end;

function TThread.Start: Boolean;
{$IFDEF FPC}
var
  Dummy: TThreadID;
{$ENDIF}
begin
  {$IFDEF FPC}
  Result := not FStarted;
  if Result then
  begin
    FStarted := True;
    FStopped := False;
    FThreadID := BeginThread(nil, FStackSize, @ThreadMethod, Pointer(Self), 0, Dummy);
    ThreadSetPriority(FThreadID, Priorities[FPriority]);
  end;
  {$ELSE}
  Result := not FStarted;
  if Result then
  begin
    FStarted := True;
    FAborted := False;
    FStopped := False;
    if FHandle <> 0 then CloseHandle(FHandle);
    repeat
      if FSuspended then
      begin
        if FStackSize > 0 then
          FHandle := BeginThread(nil, FStackSize, @ThreadMethod, Pointer(Self), CREATE_SUSPENDED or STACK_SIZE_PARAM_IS_A_RESERVATION, FThreadId)
        else
          FHandle := BeginThread(nil, 0, @ThreadMethod, Pointer(Self), CREATE_SUSPENDED, FThreadId);
        Break;
      end;
      if FStackSize > 0 then
        FHandle := BeginThread(nil, FStackSize, @ThreadMethod, Pointer(Self), STACK_SIZE_PARAM_IS_A_RESERVATION, FThreadId)
      else
        FHandle := BeginThread(nil, 0, @ThreadMethod, Pointer(Self), 0, FThreadId);
    until True;
    if FHandle = 0 then
      raise Exception.CreateFmt(ThreadCreateError, [SysErrorMessage(GetLastError)]);
    CheckThreadError(SetThreadPriority(FHandle, Priorities[FPriority]));
  end;
  {$ENDIF}
end;

procedure TThread.Stop;
begin
  FStopped := True;
end;

function TThread.Suspend: Integer;
begin
  {$IFDEF FPC}
  Result := SuspendThread(FThreadID);
  FSuspended := Result = 0;
  {$ELSE}
  if FSuspended then Result := 0
  else begin
    Result := SuspendThread(FHandle);
    FSuspended := True;
  end;
  {$ENDIF}
end;

procedure TThread.Synchronize(const Data: PSynchronizeData);
begin
  if GetCurrentThreadId = MainThreadId then Data.Method
  {$IFDEF FPC}
  else
    Classes.TThread.Synchronize(nil, Data.Method);
  {$ELSE}
  else begin
    Data.Event := CreateEvent(nil, True, False, nil);
    try
      EnterCriticalSection(ThreadSync);
      try
        if not Assigned(SyncList) then SyncList := TList.Create;
        SyncList.Add(Data);
      finally
        LeaveCriticalSection(ThreadSync);
      end;
      WaitForSingleObject(Data.Event, INFINITE);
    finally
      CloseHandle(Data.Event);
    end;
  end;
  {$ENDIF}
end;

procedure TThread.Synchronize(const Method: TThreadMethod);
var
  Data: TSynchronizeData;
begin
  FillChar(Data, SizeOf(TSynchronizeData), 0);
  Data.Thread := Self;
  Data.Method := Method;
  Synchronize(@Data);
end;

function TThread.WaitFor(const Time: LongWord): Boolean;
{$IFDEF FPC}
const
  WaitTime = 100;
var
  TickCount, IdleTime: Int64;
{$ENDIF}
begin
  {$IFDEF FPC}
  Result := FStarted;
  if Result then
  begin
    TickCount := GetTickCount64;
    repeat
      IdleTime := Time - GetTickCount64 + TickCount;
      if IdleTime < 0 then Break;
      if IdleTime > WaitTime then
        Sleep(WaitTime)
      else
        Sleep(IdleTime);
      if not FStarted then Exit(True);
    until IdleTime < WaitTime;
    Result := not FStarted;
  end;
  {$ELSE}
  Result := FStarted and (WaitForSingleObject(FHandle, Time) <> WAIT_TIMEOUT);
  {$ENDIF}
end;

initialization
  {$IFDEF FPC}
  InitCriticalSection(ThreadSync);
  {$ELSE}
  InitializeCriticalSection(ThreadSync);
  {$ENDIF}

finalization
  {$IFDEF FPC}
  DoneCriticalSection(ThreadSync);
  {$ELSE}
  DeleteCriticalSection(ThreadSync);
  {$ENDIF}
  FreeAndNil(SyncList);

end.
