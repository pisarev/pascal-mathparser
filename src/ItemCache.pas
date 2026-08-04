{ ************************************************************************** }
{                                                                            }
{ ItemCache                                                                  }
{                                                                            }
{ Copyright © 2014 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ItemCache;

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
  System.Classes, Cache, Notifier, ParseTypes;
  {$ELSE}
  Classes, Cache, Notifier, ParseTypes;
  {$ENDIF}
  {$ENDIF}

type
  PCacheData = ^TCacheData;
  TCacheData = record
    ItemArray: TTextItemArray1;
  end;

  TItemCache = class(TCache)
  private
    function GetCacheData(const Index: Integer): PCacheData;
  public
    procedure Notify(const NotifyType: TNotifyType; const Sender: TComponent); override;
    procedure AssignData(const Index: Integer; const Value: TCacheData); virtual;
    procedure Add(const Text: string; const ItemArray: TTextItemArray1); virtual;
    procedure Clear; override;
    function Find(const Text: string; out ItemArray: TTextItemArray1): Boolean; virtual;
    property Data[const Index: Integer]: PCacheData read GetCacheData;
  end;

function MakeData(const ItemArray: TTextItemArray1): TCacheData;

implementation

uses
  Parser, ValueUtils;

function MakeData(const ItemArray: TTextItemArray1): TCacheData;
begin
  Result.ItemArray := Copy(ItemArray);
end;

{ TItemCache }

procedure TItemCache.Add(const Text: string; const ItemArray: TTextItemArray1);
var
  Data: PCacheData;
  I: Integer;
begin
  if FindParser and (TParser(Parser).UpdateCount = 0) and Enabled and (List.List.IndexOf(Text) < 0) then
  begin
    List.List.BeginUpdate;
    try
      New(Data);
      if List.List.Count < CountToCache then
      begin
        Data^ := MakeData(ItemArray);
        List.List.AddObject(Text, TObject(Data))
      end
      else begin
        I := Next;
        AssignData(I, MakeData(ItemArray));
        List.List[I] := Text;
      end;
    finally
      List.List.EndUpdate;
    end;
  end;
end;

procedure TItemCache.AssignData(const Index: Integer; const Value: TCacheData);
begin
  PCacheData(List.List.Objects[Index])^ := Value;
end;

procedure TItemCache.Clear;
var
  I: Integer;
begin
  inherited;
  for I := 0 to List.List.Count - 1 do if Assigned(List.List.Objects[I]) then
  begin
    Data[I].ItemArray := nil;
    Dispose(PCacheData(List.List.Objects[I]));
  end;
  List.List.Clear;
end;

function TItemCache.Find(const Text: string; out ItemArray: TTextItemArray1): Boolean;
var
  I: Integer;
  CD: PCacheData;
begin
  Result := Enabled;
  if Result then
  begin
    I := List.List.IndexOf(Text);
    Result := I >= 0;
    if Result then
    begin
      CD := Data[I];
      if Assigned(CD) then
        ItemArray := Copy(CD.ItemArray)
      else
        ItemArray := nil;
      if SmartCache then MatchCount := MakeInteger(MatchCount.Signed32 + 1);
    end
    else
      ItemArray := nil;
    Setup;
  end
  else
    ItemArray := nil;
end;

function TItemCache.GetCacheData(const Index: Integer): PCacheData;
begin
  Result := PCacheData(List.List.Objects[Index]);
end;

procedure TItemCache.Notify(const NotifyType: TNotifyType; const Sender: TComponent);
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

end.
