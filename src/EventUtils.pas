{ ************************************************************************** }
{                                                                            }
{ EventUtils                                                                 }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit EventUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Types, Math, Parser, ParseTypes, TextTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils, System.Types, System.Math, BaseTypes, Parser, ParseTypes, TextTypes;
  {$ELSE}
  SysUtils, Types, Math, Parser, ParseTypes, TextTypes;
  {$ENDIF}
  {$ENDIF}

type
  TEvent = record
    Index: PNativeInt;
    Name: TString;
    Priority: Integer;
    Event: TFunctionEvent;
  end;
  TEventArray = array of TEvent;

  TEventData = record
    EventArray: TEventArray;
    Flag: Boolean;
  end;

function AddEvent(var Data: TEventData; const Event: TEvent): Integer;
function DeleteEvent(var Data: TEventData; const Index: Integer): Boolean;
function EventCompare(const AIndex, BIndex: Integer; const Target, Data: Pointer): TValueRelationship;
procedure EventExchange(const AIndex, BIndex: Integer; const Target, Data: Pointer);
procedure SortEventArray(var Data: TEventData);

function MakeEvent(var Index: NativeInt; const Name: string; const Priority: Integer;
  const Event: TFunctionEvent): TEvent;

implementation

uses
  MemoryUtils;

function AddEvent(var Data: TEventData; const Event: TEvent): Integer;
begin
  Result := Length(Data.EventArray);
  SetLength(Data.EventArray, Result + 1);
  Data.EventArray[Result] := Event;
  Data.Flag := True;
end;

function DeleteEvent(var Data: TEventData; const Index: Integer): Boolean;
var
  Size: Integer;
begin
  Size := Length(Data.EventArray);
  Result := Delete(Data.EventArray, Index * SizeOf(TEvent), SizeOf(TEvent), Size * SizeOf(TEvent));
  if Result then
  begin
    SetLength(Data.EventArray, Size - 1);
    Data.Flag := True;
  end;
end;

function EventCompare(const AIndex, BIndex: Integer; const Target, Data: Pointer): TValueRelationship;
var
  EventArray: TEventArray absolute Target;
begin
  Result := CompareValue(EventArray[BIndex].Priority, EventArray[AIndex].Priority);
end;

procedure EventExchange(const AIndex, BIndex: Integer; const Target, Data: Pointer);
var
  Event: TEvent;
  EventArray: TEventArray absolute Target;
begin
  Event := EventArray[AIndex];
  EventArray[AIndex] := EventArray[BIndex];
  EventArray[AIndex].Index^ := AIndex;
  EventArray[BIndex] := Event;
  EventArray[BIndex].Index^ := BIndex;
end;

procedure SortEventArray(var Data: TEventData);
begin
  if Data.Flag then
  begin
    QSort(Data.EventArray, Low(Data.EventArray), High(Data.EventArray), {$IFDEF FPC}@{$ENDIF}EventCompare,
      {$IFDEF FPC}@{$ENDIF}EventExchange);
    Data.Flag := False;
  end;
end;

function MakeEvent(var Index: NativeInt; const Name: string; const Priority: Integer;
  const Event: TFunctionEvent): TEvent;
begin
  Result.Index := @Index;
  Result.Event := Event;
  StrLCopy(Result.Name, PChar(Name), High(TString));
  Result.Priority := Priority;
end;
end.
