{ ************************************************************************** }
{                                                                            }
{ ThreadUtils                                                                }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ThreadUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}Thread;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, Thread;
  {$ELSE}
  Windows, Thread;
  {$ENDIF}
  {$ENDIF}

procedure Enter(var Lock: TRTLCriticalSection); overload;
procedure Enter(const Lock: PRTLCriticalSection); overload;
function TryEnter(var Lock: TRTLCriticalSection): Boolean; overload;
function TryEnter(const Lock: PRTLCriticalSection): Boolean; overload;
procedure Leave(var Lock: TRTLCriticalSection); overload;
procedure Leave(const Lock: PRTLCriticalSection); overload;

implementation

procedure Enter(var Lock: TRTLCriticalSection);
begin
  EnterCriticalSection(Lock);
end;

procedure Enter(const Lock: PRTLCriticalSection);
begin
  if Assigned(Lock) then EnterCriticalSection(Lock^);
end;

function TryEnter(var Lock: TRTLCriticalSection): Boolean;
begin
  {$IF Defined(FPC) AND NOT Defined(MSWINDOWS)}
  Result := TryEnterCriticalSection(Lock) <> 0;
  {$ELSE}
  Result := TryEnterCriticalSection(Lock);
  {$ENDIF}
end;

function TryEnter(const Lock: PRTLCriticalSection): Boolean;
begin
  {$IF Defined(FPC) AND NOT Defined(MSWINDOWS)}
  Result := Assigned(Lock) and (TryEnterCriticalSection(Lock^) <> 0);
  {$ELSE}
  Result := Assigned(Lock) and TryEnterCriticalSection(Lock^);
  {$ENDIF}
end;

procedure Leave(var Lock: TRTLCriticalSection);
begin
  LeaveCriticalSection(Lock);
end;

procedure Leave(const Lock: PRTLCriticalSection);
begin
  if Assigned(Lock) then LeaveCriticalSection(Lock^);
end;

end.
