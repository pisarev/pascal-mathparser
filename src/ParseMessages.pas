{ ************************************************************************** }
{                                                                            }
{ ParseMessages                                                              }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseMessages;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  {$IFNDEF NOFORMS}LMessages,{$ENDIF} ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Messages, ValueTypes;
  {$ELSE}
  Messages, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  TVariableData = record
    Name: string;
    Optimizable: Boolean;
    ReturnType: TValueType;
  end;
  PVariableData = ^TVariableData;

const
  {$IF Defined(FPC) and Defined(NOFORMS)}
  WM_USER = $0400;
  {$IFEND}
  WM_NOTIFY = WM_USER;
  WM_ADDFUNCTION = WM_USER + 1;
  WM_ADDVARIABLE = WM_USER + 2;

function VariableData(const AName: string; const AOptimizable: Boolean;
  const AReturnType: TValueType): TVariableData;

implementation

function VariableData(const AName: string; const AOptimizable: Boolean;
  const AReturnType: TValueType): TVariableData;
begin
  with Result do
  begin
    Name := AName;
    Optimizable := AOptimizable;
    ReturnType := AReturnType;
  end;
end;

end.
