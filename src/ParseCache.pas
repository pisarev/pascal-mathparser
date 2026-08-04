{ ************************************************************************** }
{                                                                            }
{ ParseCache                                                                 }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseCache;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, Cache, Notifier, ParseTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.Classes, BaseTypes, Cache, Notifier, ParseTypes;
  {$ELSE}
  Windows, Classes, Cache, Notifier, ParseTypes;
  {$ENDIF}
  {$ENDIF}

type
  PCacheData = ^TCacheData;
  TCacheData = record
    Script: TScript;
  end;

  TCache1 = class(TCache)
  private
    function GetCacheData(const Index: NativeInt): PCacheData;
  public
    procedure Notify(const NotifyType: TNotifyType; const Sender: TComponent); override;
    procedure AssignData(const Index: NativeInt; const Value: TCacheData); virtual;
    procedure Add(const Text: string; const Script: TScript); virtual;
    procedure Clear; override;
    function Find(const Text: string): TScript; virtual;
    property Data[const Index: NativeInt]: PCacheData read GetCacheData;
  end;

const
  Cache2MinCountToCache = 10;
  Cache2MaxCountToCache = 100000;

type
  TCache2 = class(TCache1)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Add(const Text: string; const Script: TScript); override;
    function Find(const Text: string): TScript; override;
  published
    property MinCountToCache default Cache2MinCountToCache;
    property MaxCountToCache default Cache2MaxCountToCache;
  end;

const
  DefaultScriptType = stScript;

type
  TParseCache = class(TComponent)
  private
    FCache2: TCache2;
    FCache1: TCache1;
    FScriptType: TScriptType;
    FLock: PRTLCriticalSection;
    procedure SetScriptType(const Value: TScriptType);
  protected
    procedure SetName(const NewName: TComponentName); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const Text: string; const Script: TScript); virtual;
    procedure Clear; virtual;
    procedure WriteScriptType; virtual;
    function Find(const Text: string): TScript; virtual;
    property Lock: PRTLCriticalSection read FLock write FLock;
  published
    property ScriptType: TScriptType read FScriptType write SetScriptType default DefaultScriptType;
    property Cache1: TCache1 read FCache1;
    property Cache2: TCache2 read FCache2;
  end;

const
  InternalCache1Name = 'Cache1';
  InternalCache2Name = 'Cache2';

function MakeData(const Script: TScript): TCacheData;

implementation

uses
  {$IFDEF FPC}
  Types, MemoryUtils, Parser, ParseUtils, ValueTypes, ValueUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.Types, MemoryUtils, Parser, ParseUtils, ValueTypes, ValueUtils;
  {$ELSE}
  Types, MemoryUtils, Parser, ParseUtils, ValueTypes, ValueUtils;
  {$ENDIF}
  {$ENDIF}

function MakeData(const Script: TScript): TCacheData;
begin
  Result.Script := Copy(Script);
end;

{ TCache1 }

procedure TCache1.Add(const Text: string; const Script: TScript);
var
  Data: PCacheData;
  I: NativeInt;
begin
  if Enabled and FindParser and (TParser(Parser).UpdateCount = 0) and (List.List.IndexOf(Text) < 0) then
  begin
    List.List.BeginUpdate;
    try
      New(Data);
      if List.List.Count < CountToCache then
      begin
        Data^ := MakeData(Script);
        List.List.AddObject(Text, TObject(Data));
      end
      else begin
        I := Next;
        AssignData(I, MakeData(Script));
        List.List[I] := Text;
      end;
    finally
      List.List.EndUpdate;
    end;
  end;
end;

procedure TCache1.AssignData(const Index: NativeInt; const Value: TCacheData);
begin
  PCacheData(List.List.Objects[Index])^ := Value;
end;

procedure TCache1.Clear;
var
  I: Integer;
begin
  inherited;
  for I := 0 to List.List.Count - 1 do if Assigned(List.List.Objects[I]) then
  begin
    Data[I].Script := nil;
    Dispose(PCacheData(List.List.Objects[I]));
  end;
  List.List.Clear;
end;

function TCache1.Find(const Text: string): TScript;
var
  I: NativeInt;
  CD: PCacheData;
begin
  if Enabled then
  begin
    I := List.List.IndexOf(Text);
    if I < 0 then Result := nil
    else begin
      CD := Data[I];
      if Assigned(CD) then
        Result := Copy(CD.Script)
      else
        Result := nil;
      if SmartCache then MatchCount := MakeInteger(MatchCount.Signed32 + 1);
    end;
    Setup;
  end
  else
    Result := nil;
end;

function TCache1.GetCacheData(const Index: NativeInt): PCacheData;
begin
  Result := PCacheData(List.List.Objects[Index]);
end;

procedure TCache1.Notify(const NotifyType: TNotifyType; const Sender: TComponent);
begin
  inherited;
  case NotifyType of
    ntBFD, ntBTD:
      begin
        CapacityScript := nil;
        RestrictScript := nil;
        Clear;
      end;
  end;
end;

{ TCache2 }

procedure TCache2.Add(const Text: string; const Script: TScript);
begin
  if Enabled and FindParser and (TParser(Parser).UpdateCount = 0) then
    inherited Add(MakeTemplate(TParser(Parser), Text, nil), Script);
end;

constructor TCache2.Create(AOwner: TComponent);
begin
  inherited;
  MinCountToCache := Cache2MinCountToCache;
  MaxCountToCache := Cache2MaxCountToCache;
end;

function TCache2.Find(const Text: string): TScript;
var
  S: string;
  ValueArray: TValueArray;
  ValueIndex: NativeInt;
begin
  if not Enabled then
    Result := nil
  else
    if FindParser then
    begin
      ValueArray := nil;
      try
        S := MakeTemplate(TParser(Parser), Text, @ValueArray);
        Result := inherited Find(S);
        if Assigned(Result) then
        begin
          ValueIndex := 0;
          WriteValue(NativeInt(Result), ValueIndex, ValueArray, ScriptType);
        end;
      finally
        ValueArray := nil;
      end;
    end;
end;

{ TParseCache }

procedure TParseCache.Add(const Text: string; const Script: TScript);
begin
  inherited;
  FCache1.Add(Text, Script);
  FCache2.Add(Text, Script);
end;

procedure TParseCache.Clear;
begin
  FCache1.Clear;
  FCache2.Clear;
end;

constructor TParseCache.Create(AOwner: TComponent);
begin
  inherited;
  New(FLock);
  {$IFDEF FPC}
  InitCriticalSection(FLock^);
  {$ELSE}
  InitializeCriticalSection(FLock^);
  {$ENDIF}
  FCache1 := TCache1.Create(Self);
  FCache2 := TCache2.Create(Self);
  FScriptType := DefaultScriptType;
  WriteScriptType;
end;

destructor TParseCache.Destroy;
begin
  {$IFDEF FPC}
  DoneCriticalSection(FLock^);
  {$ELSE}
  DeleteCriticalSection(FLock^);
  {$ENDIF}
  Dispose(FLock);
  inherited;
end;

function TParseCache.Find(const Text: string): TScript;
begin
  Result := FCache1.Find(Text);
  if not Assigned(Result) then Result := FCache2.Find(Text);
end;

procedure TParseCache.SetName(const NewName: TComponentName);
begin
  inherited;
  with FCache1 do
  begin
    Name := InternalCache1Name;
    SetSubComponent(True);
  end;
  with FCache2 do
  begin
    Name := InternalCache2Name;
    SetSubComponent(True);
  end;
end;

procedure TParseCache.SetScriptType(const Value: TScriptType);
begin
  if FScriptType <> Value then
  begin
    FScriptType := Value;
    WriteScriptType;
  end;
end;

procedure TParseCache.WriteScriptType;
begin
  FCache1.ScriptType := FScriptType;
  FCache2.ScriptType := FScriptType;
end;

end.
