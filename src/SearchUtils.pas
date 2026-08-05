{ ************************************************************************** }
{                                                                            }
{ SearchUtils                                                                }
{                                                                            }
{ Copyright © 2003-2004 Yuriy Pisarev (ypisareff@outlook.com)                }
{                                                                            }
{ ************************************************************************** }

unit SearchUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, SysUtils, MemoryUtils, Types, TextConsts, ThreadUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.Classes, System.SysUtils, MemoryUtils, Types, TextConsts, ThreadUtils;
  {$ELSE}
  Windows, Classes, SysUtils, MemoryUtils, Types, TextConsts, ThreadUtils;
  {$ENDIF}
  {$ENDIF}

type
  TDriveType = (dtUnknown, dtNoDrive, dtFloppy, dtFixed, dtNetwork, dtCDROM, dtRAM);
  TDriveTypes = set of TDriveType;

  TSearchOption = (soFile, soPath);
  TSearchOptions = set of TSearchOption;

  {$IFDEF FPC}
  TStringArray = TArray<TStringItem>;
  TStringArrayHelper = record helper for TStringItem
  public
    class function Make(const AString: string; const AObject: Pointer): TStringItem; overload; static;
    class function Make(const AString: string; const AObject: Double): TStringItem; overload; static;
  end;
  {$ELSE}
  {$IFDEF DELPHI_10.2}
  TStringArray = TArray<TStringItem>;
  TStringArrayHelper = record helper for TStringItem
  public
    class function Make(const AString: string; const AObject: Pointer): TStringItem; overload; static;
    class function Make(const AString: string; const AObject: Double): TStringItem; overload; static;
  end;
  {$ELSE}
  TStringArray = array of TStringItem;
  {$ENDIF}
  {$ENDIF}
  TSearchEvent = function(const FileName: string; const Attr, Depth: Integer; const P: Pointer;
    var Skip, Stop: Boolean): Boolean;

const
  {$IFDEF UNIX}
  AnyFile = '*';
  {$ELSE}
  AnyFile = '*.*';
  {$ENDIF}

var
  MaskDelimiter: string = Semicolon;

{$IFNDEF FPC}
function GetDriveArray(const DriveTypes: TDriveTypes): {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
{$ENDIF}

function Search(const Target: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  var FileArray, PathArray: TStringArray; const Recurse: Boolean = False; const MaxDepth: Integer = -1;
  const FileLock: PRTLCriticalSection = nil; const PathLock: PRTLCriticalSection = nil;
  const Event: TSearchEvent = nil; const P: Pointer = nil; const Depth: Integer = -1): Boolean; overload;

function Search(const Target: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const FileList: TStrings; const PathList: TStrings = nil; const Recurse: Boolean = False;
  const MaxDepth: Integer = -1; const ModuleName: Boolean = False; const FileOrderByDepth: Boolean = False;
  const PathOrderByDepth: Boolean = False; const FileLock: PRTLCriticalSection = nil;
  const PathLock: PRTLCriticalSection = nil; const Event: TSearchEvent = nil;
  const P: Pointer = nil): Boolean; overload;

function Find(const Target: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const List: TStrings; const Recurse: Boolean = False; const MaxDepth: Integer = -1;
  const FileOrderByDepth: Boolean = False; const PathOrderByDepth: Boolean = False;
  const Options: TSearchOptions = [soFile]): Integer;

implementation

uses
  {$IFDEF FPC}
  FastList, Math, NumberUtils, TextUtils;
  {$ELSE}
  FastList, Math, NumberUtils, TextUtils;
  {$ENDIF}

const
  ArrayIncrement = 1024;

{$IFDEF FPC}
{ TStringArrayHelper }

class function TStringArrayHelper.Make(const AString: string; const AObject: Double): TStringItem;
begin
  with Result do
  begin
    FString := AString;
    FObject := Pointer((@AObject)^);
  end;
end;

class function TStringArrayHelper.Make(const AString: string; const AObject: Pointer): TStringItem;
begin
  with Result do
  begin
    FString := AString;
    FObject := AObject;
  end;
end;
{$ELSE}
{$IFDEF DELPHI_10.2}
{ TStringArrayHelper }

class function TStringArrayHelper.Make(const AString: string; const AObject: Double): TStringItem;
begin
  with Result do
  begin
    FString := AString;
    FObject := Pointer((@AObject)^);
  end;
end;

class function TStringArrayHelper.Make(const AString: string; const AObject: Pointer): TStringItem;
begin
  with Result do
  begin
    FString := AString;
    FObject := AObject;
  end;
end;
{$ENDIF}
{$ENDIF}

{$IFNDEF FPC}
function GetDriveArray(const DriveTypes: TDriveTypes): {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
const
  DriveCount = 26;
  CharOffset = Ord('a');
  NameSuffix = ':\';
var
  Drives: set of 0..DriveCount - 1;
  Drive: Integer;
  DriveName: string;
begin
  Integer(Drives) := GetLogicalDrives;
  for Drive := 0 to DriveCount - 1 do
    if Drive in Drives then
    begin
      DriveName := Char(Drive + CharOffset) + NameSuffix;
      if TDriveType(GetDriveType(PChar(DriveName))) in DriveTypes then
        MemoryUtils.Add(Result, DriveName);
    end;
end;
{$ENDIF}

function MakeStringItem(const AString: string; const AObject: TObject): TStringItem;
begin
  with Result do
  begin
    FString := AString;
    FObject := AObject;
  end;
end;

procedure Reset(var StringArray: TStringArray; var Data: TArrayData);
begin
  FillChar(Data, SizeOf(TArrayData), 0);
  Data.Index := Length(StringArray);
end;

procedure Apply(var StringArray: TStringArray; const Data: TArrayData);
begin
  SetLength(StringArray, Data.Index);
end;

function Add(var StringArray: TStringArray; var Data: TArrayData; const S: string; const P: Pointer): Integer;
begin
  Data.Count := Length(StringArray);
  if Data.Index >= Data.Count then
  begin
    Data.Count := Data.Count + ArrayIncrement;
    SetLength(StringArray, Data.Count);
  end;
  StringArray[Data.Index] := MakeStringItem(S, P);
  Result := Data.Index;
  Inc(Data.Index);
end;

function Search(const Target: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  var FileArray, PathArray: TStringArray; const Recurse: Boolean; const MaxDepth: Integer;
  const FileLock, PathLock: PRTLCriticalSection; const Event: TSearchEvent; const P: Pointer;
  const Depth: Integer): Boolean;
const
  CFolder = '.';
  PFolder = '..';
var
  FileData, PathData: TArrayData;
  I, J, K: Integer;
  Path, Name, S: string;
  R: TSearchRec;
  Skip, Stop: Boolean;
begin
  Result := (MaxDepth < 0) or (Positive(Depth) - 1 <= MaxDepth);
  if Result then
  begin
    Result := Length(Target) > 0;
    if Result then
    begin
      for I := Low(Target) to High(Target) do
      begin
        Enter(PathLock);
        try
          Reset(PathArray, PathData);
          try
            Path := Trim(ExtractFilePath(Target[I]));
            Name := Trim(ExtractFileName(Target[I]));
            if Name = '' then Name := AnyFile;
            J := Add(PathArray, PathData, Path, Pointer(Depth));
            K := PathData.Index;
            if FindFirst(Path + AnyFile, faAnyFile, R) = 0 then
              try
                repeat
                  if (R.Attr and faDirectory = faDirectory) and not Same(R.Name, CFolder) and
                    not Same(R.Name, PFolder) then
                    begin
                      S := IncludeTrailingPathDelimiter(Path + R.Name);
                      Skip := False;
                      Stop := False;
                      if not Assigned(Event) or Event(S, R.Attr, Depth, P, Skip, Stop) then
                      begin
                        if not Skip then
                          Add(PathArray, PathData, S, Pointer(Depth - 1));
                        if Stop then Exit;
                      end;
                    end;
                until FindNext(R) <> 0;
              finally
                FindClose(R);
              end;
          finally
            Apply(PathArray, PathData);
          end;
        finally
          Leave(PathLock);
        end;
        Enter(FileLock);
        try
          Reset(FileArray, FileData);
          try
            if FindFirst(Path + Name, faAnyFile, R) = 0 then
              try
                repeat
                  if R.Attr and faDirectory = 0 then
                  begin
                    S := Path + R.Name;
                    Skip := False;
                    Stop := False;
                    if not Assigned(Event) or Event(S, R.Attr, Depth, P, Skip, Stop) then
                    begin
                      if not Skip then Add(FileArray, FileData, S, Pointer(J));
                      if Stop then Exit;
                    end;
                  end;
                until FindNext(R) <> 0;
              finally
                FindClose(R);
              end;
          finally
            Apply(FileArray, FileData);
          end;
        finally
          Leave(FileLock);
        end;
        if Recurse then
        begin
          J := Length(PathArray);
          while K < J do
          begin
            Search([PathArray[K].FString + Name], FileArray, PathArray, Recurse, MaxDepth, FileLock,
              PathLock, Event, P, Depth - 1);
            Inc(K);
          end;
        end;
        Result := Assigned(FileArray) or Assigned(PathArray);
      end;
    end;
  end;
end;

procedure Reorder(const FileList: TStrings; const AIndex, BIndex: Pointer);
var
  I: Integer;
begin
  for I := 0 to FileList.Count - 1 do
    if FileList.Objects[I] = AIndex then
      FileList.Objects[I] := BIndex
    else if FileList.Objects[I] = BIndex then
      FileList.Objects[I] := AIndex;
end;

function FileCompare(const AIndex, BIndex: Integer; const Target, Data: Pointer): TValueRelationship;
const
  Min: Integer = -High(Integer) - 1;
var
  FileList: TStrings absolute Target;
  PathList: TStrings absolute Data;
  I, J: Integer;
begin
  I := Integer(FileList.Objects[BIndex]);
  J := Integer(FileList.Objects[AIndex]);
  if (I >= 0) and (I < PathList.Count) then
    I := Integer(PathList.Objects[I])
  else
    I := Min;
  if (J >= 0) and (J < PathList.Count) then
    J := Integer(PathList.Objects[J])
  else
    J := Min;
  Result := CompareValue(-J, -I);
end;

function PathCompare(const AIndex, BIndex: Integer; const Target, Data: Pointer): TValueRelationship;
var
  PathList: TStrings absolute Target;
  I, J: Integer;
begin
  I := Integer(PathList.Objects[BIndex]);
  J := Integer(PathList.Objects[AIndex]);
  Result := CompareValue(-I, -J);
end;

procedure FileExchange(const AIndex, BIndex: Integer; const Target, Data: Pointer);
var
  FileList: TStrings absolute Target;
  S: string;
  AObject: TObject;
begin
  S := FileList[AIndex];
  AObject := FileList.Objects[AIndex];
  FileList[AIndex] := FileList[BIndex];
  FileList.Objects[AIndex] := FileList.Objects[BIndex];
  FileList[BIndex] := S;
  FileList.Objects[BIndex] := AObject;
end;

procedure PathExchange(const AIndex, BIndex: Integer; const Target, Data: Pointer);
var
  PathList: TStrings absolute Target;
  FileList: TStrings absolute Data;
  S: string;
  AObject: TObject;
begin
  S := PathList[AIndex];
  AObject := PathList.Objects[AIndex];
  PathList[AIndex] := PathList[BIndex];
  PathList.Objects[AIndex] := PathList.Objects[BIndex];
  PathList[BIndex] := S;
  PathList.Objects[BIndex] := AObject;
  Reorder(FileList, Pointer(AIndex), Pointer(BIndex));
end;

function Search(const Target: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const FileList, PathList: TStrings; const Recurse: Boolean; const MaxDepth: Integer;
  const ModuleName, FileOrderByDepth, PathOrderByDepth: Boolean;
  const FileLock, PathLock: PRTLCriticalSection; const Event: TSearchEvent; const P: Pointer): Boolean;

  function Put(const Target: TFastList; const Source: TStringArray): string;
  var
    I: Integer;
  begin
    Target.BeginUpdate;
    try
      Target.Capacity := Target.Count + Length(Source);
      for I := Low(Source) to High(Source) do
        Target.AddObject(Source[I].FString, Source[I].FObject);
    finally
      Target.EndUpdate;
    end;
  end;

var
  FileArray, PathArray: TStringArray;
  List: TFastList;
  I: Integer;
begin
  FileArray := nil;
  try
    PathArray := nil;
    try
      Result := Search(Target, FileArray, PathArray, Recurse, MaxDepth, nil, nil, Event, P, -1);
      if Result then
      begin
        List := TFastList.Create;
        try
          if Assigned(FileList) then
          begin
            Put(List, FileArray);
            if not ModuleName and List.Find(ttNameValue, ParamStr(0), I) then
              List.Delete(I);
            if FileOrderByDepth then
            begin
              List.BeginUpdate;
              try
                QSort(List, 0, List.Count - 1, {$IFDEF FPC}@{$ENDIF}FileCompare, {$IFDEF FPC}@{$ENDIF}FileExchange, List);
              finally
                List.EndUpdate;
              end;
            end;
            Enter(FileLock);
            try
              if FileList.Count = 0 then
                FileList.Assign(List)
              else
                FileList.AddStrings(List);
            finally
              Leave(FileLock);
            end;
            List.Clear;
          end;
          if Assigned(PathList) then
          begin
            Put(List, PathArray);
            if PathOrderByDepth then
            begin
              List.BeginUpdate;
              try
                QSort(List, 0, List.Count - 1, {$IFDEF FPC}@{$ENDIF}PathCompare, {$IFDEF FPC}@{$ENDIF}PathExchange, List);
              finally
                List.EndUpdate;
              end;
            end;
            Enter(PathLock);
            try
              if PathList.Count = 0 then
                PathList.Assign(List)
              else
                PathList.AddStrings(List);
            finally
              Leave(PathLock);
            end;
          end;
          Result := Assigned(FileList) and (FileList.Count > 0) or Assigned(PathList) and
            (PathList.Count > 0);
        finally
          List.Free;
        end;
      end;
    finally
      PathArray := nil;
    end;
  finally
    FileArray := nil;
  end;
end;

function Find(const Target: {$IFDEF DELPHI_10.2}TArray<string>{$ELSE}TStringDynArray{$ENDIF};
  const List: TStrings; const Recurse: Boolean; const MaxDepth: Integer;
  const FileOrderByDepth, PathOrderByDepth: Boolean; const Options: TSearchOptions): Integer;
var
  FileList, PathList: TStringList;
  I, J: Integer;
begin
  if soFile in Options then
    FileList := TStringList.Create
  else
    FileList := nil;
  try
    if soPath in Options then
      PathList := TStringList.Create
    else
      PathList := nil;
    try
      Search(Target, FileList, PathList, Recurse, MaxDepth, True, FileOrderByDepth, PathOrderByDepth);
      Result := 0;
      J := List.Count;
      if Assigned(PathList) then
        for I := 0 to PathList.Count - 1 do
        begin
          List.AddObject(PathList[I], PathList.Objects[I]);
          Inc(Result);
        end;
      if Assigned(FileList) then
        for I := 0 to FileList.Count - 1 do
        begin
          List.AddObject(FileList[I], Pointer(J + Integer(FileList.Objects[I])));
          Inc(Result);
        end;
    finally
      PathList.Free;
    end;
  finally
    FileList.Free;
  end;
end;

end.
