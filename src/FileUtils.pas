{ ************************************************************************** }
{                                                                            }
{ FileUtils                                                                  }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit FileUtils;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Classes, Types;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  WinApi.Windows, System.SysUtils, System.Classes, System.Types;
  {$ELSE}
  Windows, SysUtils, Classes, Types;
  {$ENDIF}
  {$ENDIF}

type
  TOpenType = (otOpenOrMake, otOpen, otMake);
  TFileArray = array of ^TextFile;

function CheckFileIndex(const Index: Integer): Boolean;
function CreateFile: Integer;
function DisposeFile(const Index: Integer): Boolean; overload;
function RemoveFile(const Index: Integer): Boolean;

function DeleteFile(const FileName: string): Boolean; overload;
function DeletePath(const Path: string; const Recurse: Boolean = False): Boolean;
function OpenFile(const FileName: string; const OpenType: TOpenType): Boolean;
function SaveFile: Boolean;
function CloseFile: Boolean;
function EmptyFile: Boolean;
{$IFNDEF FPC}
function FileSize: Int64;
{$ENDIF}
function GetFileSize(const FileName: string): Int64;
function Write(const S: string; const Eol: string = #10#13): Boolean; overload;
function Write(const StringArray: TStringDynArray; const Eol: string = #10#13): Boolean; overload;
function WriteFile(const FileName: string): Boolean;

function GetBackPath(const Path: string; const Step: Integer = 1): string;
function GetTempPath: string;
function GetTempFileName(const FilePath: string; const FileName: string = '';
  const Extension: string = ''): string;
{$IFNDEF FPC}
function GetPath(const Identifier: Integer; out Path: string): Boolean;
function GetUserPath: string;
function ExpandEnvStr(const Path: string): string;
{$ENDIF}

var
  FileArray: TFileArray;

threadvar
  FileIndex: Integer;

implementation

uses
  {$IFDEF FPC}
  {$IFDEF UNIX}baseunix,{$ENDIF}MemoryUtils, SearchUtils, TextBuilder,
  TextUtils;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.StrUtils, Winapi.SHFolder, MemoryUtils, SearchUtils, TextBuilder,
  TextUtils;
  {$ELSE}
  StrUtils, SHFolder, MemoryUtils, SearchUtils, TextBuilder, TextUtils;
  {$ENDIF}
  {$ENDIF}

{$IFDEF FPC}
function GetFileAttributes(const FileName: string;
  out Attr: {$ifdef unix}stat{$else}longint{$endif}): Boolean; forward;
function SetFileAttributes(const FileName: string;
  const Attr: {$ifdef unix}stat{$else}longint{$endif}): Boolean; forward;
{$ENDIF}
procedure Clear; forward;

{$IFDEF FPC}
function GetFileAttributes(const FileName: string;
  out Attr: {$ifdef unix}stat{$else}longint{$endif}): Boolean;
begin
  {$ifdef unix}
  Result := fpstat(FileName, Attr) = 0;
  {$endif}
  {$ifdef windows}
  Attr := filegetattr(FileName);
  Result := Attr >= 0;
  {$endif}
  {$if not defined(unix) and not defined(windows)}
  Attr := -1;
  Result := False;
  {$endif}
end;

function SetFileAttributes(const FileName: string;
  const Attr: {$ifdef unix}stat{$else}longint{$endif}): Boolean;
begin
  {$ifdef unix}
  Result := fpchmod(FileName, Attr.st_mode) = 0;
  {$endif}
  {$ifdef windows}
  Result := filesetattr(FileName, Attr) = 0;
  {$endif}
  {$if not defined(unix) and not defined(windows)}
  Result := False;
  {$endif}
end;
{$ENDIF}

procedure Clear;
var
  I: Integer;
begin
  for I := Low(FileArray) to High(FileArray) do DisposeFile(I);
  FileArray := nil;
end;

function CheckFileIndex(const Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < Length(FileArray));
end;

function CreateFile: Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(FileArray) to High(FileArray) do
    if not Assigned(FileArray[I]) then
    begin
      Result := I;
      Break;
    end;
  if Result < 0 then
  begin
    Result := Length(FileArray);
    SetLength(FileArray, Result + 1);
  end;
  New(FileArray[Result]);
end;

function DisposeFile(const Index: Integer): Boolean;
begin
  Result := CheckFileIndex(Index) and Assigned(FileArray[Index]);
  if Result then
  begin
    {$I-}
    {$IFDEF FPC}
    System.Close(FileArray[Index]^);
    {$ELSE}
    System.CloseFile(FileArray[Index]^);
    {$ENDIF}
    {$I+}
    Result := IOResult = 0;
    if Result then
    begin
      Dispose(FileArray[Index]);
      FileArray[Index] := nil;
    end;
  end;
end;

function RemoveFile(const Index: Integer): Boolean;
var
  I: Integer;
begin
  Result := CheckFileIndex(Index);
  if Result then
  begin
    DisposeFile(Index);
    I := Length(FileArray);
    Result := Delete(FileArray, Index * SizeOf(Pointer), SizeOf(Pointer), I * SizeOf(Pointer));
    if Result then
      SetLength(FileArray, I - 1);
  end;
end;

function DeleteFile(const FileName: string): Boolean;
begin
  {$IFDEF FPC}
  Result := SysUtils.DeleteFile(PChar(FileName));
  {$ELSE}
  SetFileAttributes(PChar(FileName), 0);
  Result := {$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.DeleteFile(PChar(FileName));
  {$ENDIF}
end;

function DeletePath(const Path: string; const Recurse: Boolean): Boolean;
var
  FileList, PathList: TStringList;
  I: Integer;
begin
  if Recurse then
  begin
    FileList := TStringList.Create;
    try
      PathList := TStringList.Create;
      try
        Search([IncludeTrailingPathDelimiter(Path) + AnyFile], FileList, PathList, True, -1, False,
          False, True);
        Result := (FileList.Count > 0) or (PathList.Count > 0);
        if Result then
        begin
          for I := 0 to FileList.Count - 1 do
          begin
            Result := DeleteFile(FileList[I]);
            if not Result then Exit;
          end;
          for I := 0 to PathList.Count - 1 do
          begin
            Result := DeletePath(PathList[I], False);
            if not Result then Exit;
          end;
        end;
      finally
        PathList.Free;
      end;
    finally
      FileList.Free;
    end;
    Result := not DirectoryExists(Path);
  end
  else begin
    FileSetAttr(Path, 0);
    Result := RemoveDir(Path);
  end;
end;

function OpenFile(const FileName: string; const OpenType: TOpenType): Boolean;
var
  S: string;
begin
  case OpenType of
    otOpenOrMake, otMake:
    begin
      S := Trim(ExtractFilePath(FileName));
      if (S <> '') and not DirectoryExists(S) then
        ForceDirectories(S);
    end;
  end;
  AssignFile(FileArray[FileIndex]^, FileName);
  {$I-}
  case OpenType of
    otOpenOrMake:
      begin
        Append(FileArray[FileIndex]^);
        if IOResult <> 0 then Rewrite(FileArray[FileIndex]^);
      end;
    otMake: Rewrite(FileArray[FileIndex]^);
  else
    Append(FileArray[FileIndex]^);
  end;
  {$I+}
  Result := IOResult = 0;
end;

function SaveFile: Boolean;
begin
  {$I-}
  Flush(FileArray[FileIndex]^);
  {$I+}
  Result := IOResult = 0;
end;

function CloseFile: Boolean;
begin
  {$I-}
  {$IFDEF FPC}
  System.Close(FileArray[FileIndex]^);
  {$ELSE}
  System.CloseFile(FileArray[FileIndex]^);
  {$ENDIF}
  {$I+}
  Result := IOResult = 0;
end;

function EmptyFile: Boolean;
begin
  {$I-}
  Rewrite(FileArray[FileIndex]^);
  {$I+}
  Result := IOResult = 0;
end;

{$IFNDEF FPC}
function FileSize: Int64;
begin
  {$I-}
  Result := System.FileSize(FileArray[FileIndex]^);
  {$I+}
  if IOResult <> 0 then Result := -1;
end;
{$ENDIF}

function GetFileSize(const FileName: string): Int64;
{$IFNDEF FPC}
var
  Handle: THandle;
{$ENDIF}
{$IFDEF FPC}
var
  Search: TSearchRec;
{$ENDIF}
begin
  {$IFDEF FPC}
  if FindFirst(FileName, faAnyFile, Search) = 0 then
  begin
    Result := Search.Size;
    FindClose(Search);
  end
  else
    Result := -1;
  {$ELSE}
  Handle := {$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.CreateFile(
    PChar(FileName),
    GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );
  if Handle = INVALID_HANDLE_VALUE then
    Result := -1
  else
    try
      Int64Rec(Result).Lo := {$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.GetFileSize(Handle, @Int64Rec(Result).Hi);
    finally
      FileClose(Handle);
    end;
  {$ENDIF}
end;

function Write(const S, Eol: string): Boolean;
begin
  {$I-}
  System.Write(FileArray[FileIndex]^, S + Eol);
  {$I+}
  Result := IOResult = 0;
end;

function Write(const StringArray: TStringDynArray; const Eol: string): Boolean;
var
  I: Integer;
begin
  for I := Low(StringArray) to High(StringArray) do
  begin
    Result := Write(StringArray[I], Eol);
    if not Result then Exit;
  end;
  Result := True;
end;

function WriteFile(const FileName: string): Boolean;
var
  F: TextFile;
  S: string;
begin
  AssignFile(F, FileName);
  {$I-}
  System.Reset(F);
  {$I+}
  Result := IOResult = 0;
  if Result then
    try
      while not Eof(F) do
      begin
        ReadLn(F, S);
        WriteLn(FileArray[FileIndex]^, S);
      end;
    finally
      {$IFDEF FPC}
      System.Close(F);
      {$ELSE}
      System.CloseFile(F);
      {$ENDIF}
    end;
end;

function GetBackPath(const Path: string; const Step: Integer = 1): string;
var
  I, J, K: Integer;
begin
  Result := Path;
  for I := 0 to Step - 1 do
  begin
    K := Length(Result);
    if Result[K] = PathDelim then Dec(K);
    J := K;
    while (J > 1) and (Result[J] <> PathDelim) do Dec(J);
    Result := Copy(Result, 1, J - 1);
    if Result = '' then Exit;
  end;
  Result := IncludeTrailingPathDelimiter(Result);
end;

function GetTempPath: string;
{$IFNDEF FPC}
var
  P: PChar;
{$ENDIF}
begin
  {$IFDEF FPC}
  Result := IncludeTrailingPathDelimiter(SysUtils.GetTempDir);
  {$ELSE}
  P := StrAlloc({$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.GetTempPath(0, nil));
  try
    {$IFDEF DELPHI_XE7}WinApi.Windows{$ELSE}Windows{$ENDIF}.GetTempPath(StrBufSize(P), P);
    if not DirectoryExists(P) then RaiseLastOSError;
    Result := IncludeTrailingPathDelimiter(P);
  finally
    StrDispose(P);
  end;
  {$ENDIF}
end;

function GetTempFileName(const FilePath, FileName, Extension: string): string;
const
  PostfixText = '%.2x%.2x%.2x%.2x';
  PostfixSize = 8;
  Delimiter = '-';
  DateTimeFormat = 'yyyy' + Delimiter + 'mm' + Delimiter + 'dd' + Delimiter + 'hh' + Delimiter + 'mm' + Delimiter + 'ss' + Delimiter + 'zzz';
var
  Path, S: string;
  B: TTextBuilder;
  Guid: TGuid;
begin
  Path := IncludeTrailingPathDelimiter(FilePath);
  B := TTextBuilder.Create;
  try
    repeat
      B.Clear;
      B.Append(FormatDateTime(DateTimeFormat, Now), Delimiter);
      {$IFDEF DELPHI_XE7}
      S := System.SysUtils.Trim(FileName);
      {$ELSE}
      S := SysUtils.Trim(FileName);
      {$ENDIF}
      if S <> '' then
        B.Append(ChangeFileExt(ExtractFileName(S), ''), Delimiter);
      {$IFDEF DELPHI_XE7}
      if System.SysUtils.CreateGuid(Guid) = S_OK then
      {$ELSE}
        if SysUtils.CreateGuid(Guid) = S_OK then
      {$ENDIF}
        begin
          SetLength(S, PostfixSize);
          StrLFmt(PChar(S), PostfixSize, PostfixText, [Guid.D4[0], Guid.D4[1], Guid.D4[2], Guid.D4[3]]);
          B.Append(AnsiLowerCase(S), Delimiter);
        end;
      Result := ChangeFileExt(B.Text, Extension);
    until not FileExists(Path + Result);
  finally
    B.Free;
  end;
end;

{$IFNDEF FPC}
function GetPath(const Identifier: Integer; out Path: string): Boolean;
var
  P: PChar;
begin
  P := AllocMem(MAX_PATH);
  try
    Result := SHGetFolderPath(0, Identifier, 0, 0, P) = S_OK;
    if Result then Path := P;
  finally
    FreeMem(P);
  end;
end;

function GetUserPath: string;
begin
  if not GetPath(CSIDL_LOCAL_APPDATA, Result) then
    Result := GetTempPath;
end;

function ExpandEnvStr(const Path: string): string;
const
  MaxSize = 32768;
begin
  SetLength(Result, MaxSize);
  SetLength(Result, ExpandEnvironmentStrings(PChar(Path), PChar(Result), Length(Result)) - 1);
end;

{$ENDIF}

initialization

finalization
  Clear;
end.
