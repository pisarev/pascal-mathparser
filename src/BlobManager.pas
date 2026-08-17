{ ************************************************************************** }
{                                                                            }
{ BlobManager                                                                }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit BlobManager;

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Classes, {$IFNDEF NOGRAPHICS}Graphics,{$ENDIF}ZStream, Types, FastList,
  MemoryUtils, NumberConsts, TextTypes;
  {$ELSE}
  {$IFDEF DELPHI_10.2}
  Winapi.Windows, System.SysUtils, System.Classes, {$IFNDEF NOGRAPHICS}Vcl.Graphics,{$ENDIF}
  System.ZLib, FastList, NumberConsts, TextTypes;
  {$ELSE}
  Windows, SysUtils, Classes, {$IFNDEF NOGRAPHICS}Graphics,{$ENDIF}Types, ZLib, FastList,
  NumberConsts, TextTypes;
  {$ENDIF}
  {$ENDIF}

type
  TDataKind = (dkData, dkText, dkGraphic);

  THeader = record
    Count: Integer;
    Kind: array of TDataKind;
    Name: array of TString;
    From: array of Int64;
    Size: array of Int64;
  end;
  PHeader = ^THeader;

  PItem = ^TItem;
  TItem = record
    Kind: TDataKind;
    Stream: TMemoryStream;
  end;

  TItemKind = (ikCommon, ikHidden);

  TBlobNotifyEvent = procedure(const Sender: TObject; const Stream: TStream) of object;
  TBlobDeleteEvent = procedure(const Sender: TObject; const ItemKind: TItemKind;
    const ItemIndex: Integer) of object;

  TCustomBlobManager = class(TComponent)
  protected
    function GetAutoFree: Boolean; virtual; abstract;
    function GetAutoLoad: Boolean; virtual; abstract;
    function GetCommonHeader: THeader; virtual; abstract;
    function GetCommonNameList: TFastList; virtual; abstract;
    function GetHiddenHeader: THeader; virtual; abstract;
    function GetHiddenNameList: TFastList; virtual; abstract;
    function GetIdent: string; virtual; abstract;
    function GetItem(const NameList: TFastList; const Index: Integer): PItem; virtual; abstract;
    function GetItemText(const ItemKind: TItemKind; const Index: Integer): string; virtual; abstract;
    function GetText(const AItem: TItem): string; virtual; abstract;
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetAutoFree(const Value: Boolean); virtual; abstract;
    procedure SetAutoLoad(const Value: Boolean); virtual; abstract;
    procedure SetCommonHeader(const Value: THeader); virtual; abstract;
    procedure SetCommonNameList(const Value: TFastList); virtual; abstract;
    procedure SetHiddenHeader(const Value: THeader); virtual; abstract;
    procedure SetHiddenNameList(const Value: TFastList); virtual; abstract;
    procedure SetIdent(const Value: string); virtual; abstract;
    procedure SetItem(const NameList: TFastList; const Index: Integer; const Value: PItem); virtual; abstract;
    procedure SetItemText(const ItemKind: TItemKind; const Index: Integer;
      const Value: string); virtual; abstract;
    procedure SetText(const AItem: TItem; const Value: string); virtual; abstract;
  public
    function Open(const Source: TStream): Boolean; overload; virtual; abstract;
    function Open(const Source: TStrings): Boolean; overload; virtual; abstract;
    procedure Save(const Target: TMemoryStream); overload; virtual; abstract;
    procedure Save(const Target: TStrings); overload; virtual; abstract;
    procedure BeginUpdate;
    procedure EndUpdate;
    function CheckIndex(const Index: Integer; const NameList: TFastList): Boolean; virtual;
    function Import(const ItemKind: TItemKind; const AName: string;
      const AItem: TItem): Integer; overload; virtual; abstract;
    function Import(const ItemKind: TItemKind; const DataKind: TDataKind; const AName: string;
      const Data: Pointer; const Size: Int64): Integer; overload; virtual; abstract;
    function Import(const ItemKind: TItemKind; const DataKind: TDataKind; const AName: string;
      const Stream: TMemoryStream): Integer; overload; virtual; abstract;
    function Import(const DataKind: TDataKind; const AName: string; const Data: Pointer;
      const Size: Int64): Integer; overload; virtual; abstract;
    function Import(const DataKind: TDataKind; const AName: string;
      const Stream: TMemoryStream): Integer; overload; virtual; abstract;
    {$IFNDEF NOGRAPHICS}
    function ImportGraphic(const AName: string; const Graphic: TGraphic): Integer; virtual; abstract;
    {$ENDIF}
    function ImportText(const AName, Text: string): Integer; virtual; abstract;
    function Export(const Item: PItem; const Data: Pointer): Boolean; overload; virtual; abstract;
    function Export(const ItemKind: TItemKind; const Index: Integer;
      const Data: Pointer): Boolean; overload; virtual; abstract;
    function Export(const Index: Integer; const Data: Pointer): Boolean; overload; virtual; abstract;
    {$IFNDEF NOGRAPHICS}
    function ExportGraphic(const Item: PItem; const Graphic: TGraphic): Boolean; overload; virtual; abstract;
    {$ENDIF}
    {$IFNDEF NOGRAPHICS}
    function ExportGraphic(const Index: Integer;
      const Graphic: TGraphic): Boolean; overload; virtual; abstract;
    {$ENDIF}
    function ExportText(const Item: PItem; out Text: string): Boolean; overload; virtual; abstract;
    function ExportText(const Index: Integer; out Text: string): Boolean; overload; virtual; abstract;
    function Replace(const ItemKind: TItemKind; const Index: Integer; const AName: string;
      const Data: Pointer = nil; const Size: Int64 = 0): Boolean; overload; virtual; abstract;
    function Replace(const ItemKind: TItemKind; const Index: Integer; const AName: string;
      const Stream: TMemoryStream): Boolean; overload; virtual; abstract;
    function Replace(const Index: Integer; const AName: string; const Data: Pointer = nil;
      const Size: Int64 = 0): Boolean; overload; virtual; abstract;
    function Replace(const Index: Integer; const AName: string;
      const Stream: TMemoryStream): Boolean; overload; virtual; abstract;
    {$IFNDEF NOGRAPHICS}
    function ReplaceGraphic(const Index: Integer; const AName: string;
      const Graphic: TGraphic): Boolean; virtual; abstract;
    {$ENDIF}
    function ReplaceText(const Index: Integer; const AName, Text: string): Boolean; virtual; abstract;
    procedure Clear; virtual;
    procedure DeleteHeader(const ItemKind: TItemKind); overload; virtual; abstract;
    procedure DeleteHeader; overload; virtual; abstract;
    function DeleteItem(const Item: PItem): Boolean; overload; virtual; abstract;
    function DeleteItem(const ItemKind: TItemKind;
      const Index: Integer): Boolean; overload; virtual; abstract;
    function DeleteItem(const Index: Integer): Boolean; overload; virtual; abstract;
    function DeleteNameList(const ItemKind: TItemKind): TFastList; overload; virtual; abstract;
    function DeleteNameList: TFastList; overload; virtual; abstract;
    function IndexOf(const ItemKind: TItemKind; const AName: string): Integer; overload; virtual; abstract;
    function IndexOf(const AName: string): Integer; overload; virtual; abstract;
    function Find(const ItemKind: TItemKind; const AName: string): PItem; overload; virtual; abstract;
    function Find(const AName: string): PItem; overload; virtual; abstract;
    function Find(const ItemKind: TItemKind; const AName: string;
      out Index: Integer): Boolean; overload; virtual; abstract;
    function Find(const AName: string; out Index: Integer): Boolean; overload; virtual; abstract;
    function Find(const ItemKind: TItemKind; const AName: string;
      out Item: PItem): Boolean; overload; virtual; abstract;
    function Find(const AName: string; out Item: PItem): Boolean; overload; virtual; abstract;
    function Read(const ItemKind: TItemKind; const AName: string; var Value;
      const Size: Int64): Boolean; overload; virtual; abstract;
    function Read(const AName: string; var Value; const Size: Int64): Boolean; overload; virtual; abstract;
    function ReadByte(const AName: string; var Value: Byte;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadShortint(const AName: string; var Value: Shortint;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadWord(const AName: string; var Value: Word;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadSmallint(const AName: string; var Value: Smallint;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadLongWord(const AName: string; var Value: LongWord;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadInteger(const AName: string; var Value: Integer;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadInt64(const AName: string; var Value: Int64;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadSingle(const AName: string; var Value: Single;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadDouble(const AName: string; var Value: Double;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadExtended(const AName: string; var Value: Extended;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadBoolean(const AName: string; var Value: Boolean;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    function ReadString(const AName: string; var Value: string;
      const ItemKind: TItemKind = ikCommon): Boolean; virtual; abstract;
    procedure Write(const ItemKind: TItemKind; const AName: string; const Value;
      const Size: Int64); overload; virtual; abstract;
    procedure Write(const AName: string; const Value; const Size: Int64); overload; virtual; abstract;
    procedure WriteByte(const AName: string; const Value: Byte;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteShortint(const AName: string; const Value: Shortint;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteWord(const AName: string; const Value: Word;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteSmallint(const AName: string; const Value: Smallint;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteLongWord(const AName: string; const Value: LongWord;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteInteger(const AName: string; const Value: Integer;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteInt64(const AName: string; const Value: Int64;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteSingle(const AName: string; const Value: Single;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteDouble(const AName: string; const Value: Double;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteExtended(const AName: string; const Value: Extended;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteBoolean(const AName: string; const Value: Boolean;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    procedure WriteString(const AName: string; const Value: string;
      const ItemKind: TItemKind = ikCommon); virtual; abstract;
    property CommonHeader: THeader read GetCommonHeader write SetCommonHeader;
    property HiddenHeader: THeader read GetHiddenHeader write SetHiddenHeader;
    property CommonNameList: TFastList read GetCommonNameList write SetCommonNameList;
    property HiddenNameList: TFastList read GetHiddenNameList write SetHiddenNameList;
    property Item[const NameList: TFastList; const Index: Integer]: PItem read GetItem write SetItem;
    property Text[const AItem: TItem]: string read GetText write SetText;
    property ItemText[const ItemKind: TItemKind; const Index: Integer]: string read GetItemText write SetItemText;
  published
    property Ident: string read GetIdent write SetIdent;
    property AutoLoad: Boolean read GetAutoLoad write SetAutoLoad default True;
    property AutoFree: Boolean read GetAutoFree write SetAutoFree default False;
  end;

  TBlobManager = class(TCustomBlobManager)
  private
    FAfterClear: TNotifyEvent;
    FAfterDelete: TBlobDeleteEvent;
    FAfterOpen: TBlobNotifyEvent;
    FAfterSave: TBlobNotifyEvent;
    FAutoFree: Boolean;
    FAutoLoad: Boolean;
    FBeforeClear: TNotifyEvent;
    FBeforeDelete: TBlobDeleteEvent;
    FBeforeOpen: TBlobNotifyEvent;
    FBeforeSave: TBlobNotifyEvent;
    FCommonHeader: THeader;
    FCommonNameList: TFastList;
    FCompression: Boolean;
    FCompressionLevel: TCompressionLevel;
    FHiddenHeader: THeader;
    FHiddenNameList: TFastList;
    FIdent: string;
  protected
    function GetAutoFree: Boolean; override;
    function GetAutoLoad: Boolean; override;
    function GetCommonHeader: THeader; override;
    function GetCommonNameList: TFastList; override;
    function GetFastList(const ItemKind: TItemKind): TFastList; virtual;
    function GetHeader(const ItemKind: TItemKind): PHeader; virtual;
    function GetHiddenHeader: THeader; override;
    function GetHiddenNameList: TFastList; override;
    function GetIdent: string; override;
    function GetItem(const NameList: TFastList; const Index: Integer): PItem; override;
    function GetItemText(const ItemKind: TItemKind; const Index: Integer): string; override;
    function GetText(const AItem: TItem): string; override;
    procedure SetAutoFree(const Value: Boolean); override;
    procedure SetAutoLoad(const Value: Boolean); override;
    procedure SetCommonHeader(const Value: THeader); override;
    procedure SetCommonNameList(const Value: TFastList); override;
    procedure SetHiddenHeader(const Value: THeader); override;
    procedure SetHiddenNameList(const Value: TFastList); override;
    procedure SetIdent(const Value: string); override;
    procedure SetItem(const NameList: TFastList; const Index: Integer; const Value: PItem); override;
    procedure SetItemText(const ItemKind: TItemKind; const Index: Integer; const Value: string); override;
    procedure SetText(const AItem: TItem; const Value: string); override;
    procedure DoAfterOpen(const Stream: TStream); virtual;
    procedure DoBeforeOpen(const Stream: TStream); virtual;
    procedure DoAfterSave(const Stream: TStream); virtual;
    procedure DoBeforeSave(const Stream: TStream); virtual;
    procedure DoAfterDelete(const ItemKind: TItemKind; const ItemIndex: Integer); virtual;
    procedure DoBeforeDelete(const ItemKind: TItemKind; const ItemIndex: Integer); virtual;
    procedure DoAfterClear; virtual;
    procedure DoBeforeClear; virtual;
    function CheckItem(const Stream: TStream; const ItemKind: TItemKind;
      const Index: Integer): Boolean; virtual;
    function MakeHeader(const ItemKind: TItemKind; const Count: Integer): PHeader; virtual;
    function ReadHeader(const Stream: TStream; const ItemKind: TItemKind): Boolean; virtual;
    function ReadNameList(const Stream: TStream; const ItemKind: TItemKind): Boolean; virtual;
    procedure WriteHeader(const Stream: TStream; const ItemKind: TItemKind;
      var Reference: TArray<Int64>); virtual;
    procedure WriteNameList(const Stream: TMemoryStream; const ItemKind: TItemKind;
      const Reference: TArray<Int64>); virtual;
    property Header[const ItemKind: TItemKind]: PHeader read GetHeader;
    property NameList[const ItemKind: TItemKind]: TFastList read GetFastList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Open(const Source: TStream): Boolean; overload; override;
    function Open(const Source: TStrings): Boolean; overload; override;
    procedure Save(const Target: TMemoryStream); overload; override;
    procedure Save(const Target: TStrings); overload; override;
    function LoadFromFile(const FileName: string): Boolean; virtual;
    procedure SaveToFile(const FileName: string); virtual;
    function ReadItem(const Stream: TStream; const ItemKind: TItemKind; const Index: Integer;
      out AName: string; out Item: TItem): Boolean; overload; virtual;
    function Import(const ItemKind: TItemKind; const AName: string;
      const AItem: TItem): Integer; overload; override;
    function Import(const ItemKind: TItemKind; const DataKind: TDataKind; const AName: string;
      const Data: Pointer; const Size: Int64): Integer; overload; override;
    function Import(const ItemKind: TItemKind; const DataKind: TDataKind; const AName: string;
      const Stream: TMemoryStream): Integer; overload; override;
    function Import(const DataKind: TDataKind; const AName: string; const Data: Pointer;
      const Size: Int64): Integer; overload; override;
    function Import(const DataKind: TDataKind; const AName: string;
      const Stream: TMemoryStream): Integer; overload; override;
    {$IFNDEF NOGRAPHICS}
    function ImportGraphic(const AName: string; const Graphic: TGraphic): Integer; override;
    {$ENDIF}
    function ImportText(const AName, Text: string): Integer; override;
    function Export(const Item: PItem; const Data: Pointer): Boolean; overload; override;
    function Export(const ItemKind: TItemKind; const Index: Integer;
      const Data: Pointer): Boolean; overload; override;
    function Export(const Index: Integer; const Data: Pointer): Boolean; overload; override;
    {$IFNDEF NOGRAPHICS}
    function ExportGraphic(const Item: PItem; const Graphic: TGraphic): Boolean; overload; override;
    {$ENDIF}
    {$IFNDEF NOGRAPHICS}
    function ExportGraphic(const Index: Integer; const Graphic: TGraphic): Boolean; overload; override;
    {$ENDIF}
    function ExportText(const Item: PItem; out Text: string): Boolean; overload; override;
    function ExportText(const Index: Integer; out Text: string): Boolean; overload; override;
    function Replace(const ItemKind: TItemKind; const Index: Integer; const AName: string;
      const Data: Pointer = nil; const Size: Int64 = 0): Boolean; overload; override;
    function Replace(const ItemKind: TItemKind; const Index: Integer; const AName: string;
      const Stream: TMemoryStream): Boolean; overload; override;
    function Replace(const Index: Integer; const AName: string; const Data: Pointer = nil;
      const Size: Int64 = 0): Boolean; overload; override;
    function Replace(const Index: Integer; const AName: string;
      const Stream: TMemoryStream): Boolean; overload; override;
    {$IFNDEF NOGRAPHICS}
    function ReplaceGraphic(const Index: Integer; const AName: string;
      const Graphic: TGraphic): Boolean; override;
    {$ENDIF}
    function ReplaceText(const Index: Integer; const AName, Text: string): Boolean; override;
    procedure DeleteHeader(const ItemKind: TItemKind); overload; override;
    procedure DeleteHeader; overload; override;
    function DeleteItem(const Item: PItem): Boolean; overload; override;
    function DeleteItem(const ItemKind: TItemKind; const Index: Integer): Boolean; overload; override;
    function DeleteItem(const Index: Integer): Boolean; overload; override;
    function DeleteNameList(const ItemKind: TItemKind): TFastList; overload; override;
    function DeleteNameList: TFastList; overload; override;
    function IndexOf(const ItemKind: TItemKind; const AName: string): Integer; overload; override;
    function IndexOf(const AName: string): Integer; overload; override;
    function Find(const ItemKind: TItemKind; const AName: string): PItem; overload; override;
    function Find(const AName: string): PItem; overload; override;
    function Find(const ItemKind: TItemKind; const AName: string;
      out Index: Integer): Boolean; overload; override;
    function Find(const AName: string; out Index: Integer): Boolean; overload; override;
    function Find(const ItemKind: TItemKind; const AName: string;
      out AItem: PItem): Boolean; overload; override;
    function Find(const AName: string; out AItem: PItem): Boolean; overload; override;
    function Read(const ItemKind: TItemKind; const AName: string; var Value;
      const Size: Int64): Boolean; overload; override;
    function Read(const AName: string; var Value; const Size: Int64): Boolean; overload; override;
    function ReadByte(const AName: string; var Value: Byte;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadShortint(const AName: string; var Value: Shortint;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadWord(const AName: string; var Value: Word;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadSmallint(const AName: string; var Value: Smallint;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadLongWord(const AName: string; var Value: LongWord;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadInteger(const AName: string; var Value: Integer;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadInt64(const AName: string; var Value: Int64;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadSingle(const AName: string; var Value: Single;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadDouble(const AName: string; var Value: Double;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadExtended(const AName: string; var Value: Extended;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadBoolean(const AName: string; var Value: Boolean;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    function ReadString(const AName: string; var Value: string;
      const ItemKind: TItemKind = ikCommon): Boolean; override;
    procedure Write(const ItemKind: TItemKind; const AName: string; const Value;
      const Size: Int64); overload; override;
    procedure Write(const AName: string; const Value; const Size: Int64); overload; override;
    procedure WriteByte(const AName: string; const Value: Byte;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteShortint(const AName: string; const Value: Shortint;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteWord(const AName: string; const Value: Word;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteSmallint(const AName: string; const Value: Smallint;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteLongWord(const AName: string; const Value: LongWord;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteInteger(const AName: string; const Value: Integer;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteInt64(const AName: string; const Value: Int64;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteSingle(const AName: string; const Value: Single;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteDouble(const AName: string; const Value: Double;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteExtended(const AName: string; const Value: Extended;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteBoolean(const AName: string; const Value: Boolean;
      const ItemKind: TItemKind = ikCommon); override;
    procedure WriteString(const AName: string; const Value: string;
      const ItemKind: TItemKind = ikCommon); override;
  published
    property Compression: Boolean read FCompression write FCompression default False;
    property CompressionLevel: TCompressionLevel read FCompressionLevel write FCompressionLevel default clDefault;
    property AfterOpen: TBlobNotifyEvent read FAfterOpen write FAfterOpen;
    property BeforeOpen: TBlobNotifyEvent read FBeforeOpen write FBeforeOpen;
    property AfterSave: TBlobNotifyEvent read FAfterSave write FAfterSave;
    property BeforeSave: TBlobNotifyEvent read FBeforeSave write FBeforeSave;
    property AfterDelete: TBlobDeleteEvent read FAfterDelete write FAfterDelete;
    property BeforeDelete: TBlobDeleteEvent read FBeforeDelete write FBeforeDelete;
    property AfterClear: TNotifyEvent read FAfterClear write FAfterClear;
    property BeforeClear: TNotifyEvent read FBeforeClear write FBeforeClear;
  end;

const
  DefaultIdent = 'D4C97794B7EC';
  DefaultCharCount = 32;
  NumberLength = 2;

function MakeItem(const AKind: TDataKind; const AStream: TMemoryStream): TItem;

function Eof(const Stream: TStream; const Count: Int64; const Position: Int64 = -1): Boolean;
function ReadValue(const Stream: TStream; var Value; const Count: Int64): Boolean;

function ReadIdent(const Ident: string; const Stream: TStream): Boolean;
procedure WriteIdent(const Ident: string; Stream: TStream);

function Parse(const Source: TMemoryStream; const Target: TStrings;
  const CharCount: Integer): Boolean; overload;
function Parse(const Source: TStrings; const Target: TMemoryStream): Boolean; overload;

function Put(var Target: TMemoryStream; const Source: TMemoryStream): Boolean;

procedure Register;

implementation

uses ZUtils, TextConsts, TextUtils;

procedure Register;
begin
  RegisterComponents('Samples', [TBlobManager]);
end;

function MakeItem(const AKind: TDataKind; const AStream: TMemoryStream): TItem;
begin
  FillChar(Result, SizeOf(TItem), 0);
  with Result do
  begin
    Kind := AKind;
    Stream := AStream;
  end;
end;

function Eof(const Stream: TStream; const Count, Position: Int64): Boolean;
var
  Index: Int64;
begin
  if Position < 0 then
    Index := Stream.Position
  else
    Index := Position;
  Result := Index + Count > Stream.Size;
end;

function ReadValue(const Stream: TStream; var Value; const Count: Int64): Boolean;
begin
  Result := not Eof(Stream, Count);
  if Result then Stream.Read(Value, Count);
end;

function ReadIdent(const Ident: string; const Stream: TStream): Boolean;
var
  I: Integer;
  S: string;
begin
  Stream.Position := 0;
  I := Length(Ident);
  Result := not Eof(Stream, I * SizeOf(Char));
  if Result then
  begin
    SetLength(S, I);
    ReadValue(Stream, Pointer(S)^, I * SizeOf(Char));
    Result := Same(Ident, S);
  end;
end;

procedure WriteIdent(const Ident: string; Stream: TStream);
begin
  Stream.Size := 0;
  Stream.Write(Pointer(Ident)^, Length(Ident) * SizeOf(Char));
end;

function Parse(const Source: TMemoryStream; const Target: TStrings; const CharCount: Integer): Boolean;

  procedure Move(var Target: string; const Source: string; const Index: NativeInt; var Size: NativeInt);
  var
    I, J: NativeInt;
  begin
    I := Length(Source) * SizeOf(Char);
    J := (Index + I - SizeOf(Char)) div SizeOf(Char);
    if J > Size then
    begin
      Size := J;
      SetLength(Target, Size);
    end;
    CopyMemory(Pointer(NativeInt(Target) + Index - 1), Pointer(Source), I);
  end;

var
  I, J, K, Size: NativeInt;
  S, Number: string;
begin
  Target.Clear;
  Result := Source.Size > 0;
  if Result then
  begin
    J := NativeInt(Source.Memory);
    K := 1;
    I := Source.Size * NumberLength;
    Size := I + (I div CharCount - 1) * Length(LB);
    SetLength(S, Size);
    ZeroMemory(Pointer(S), Size * SizeOf(Char));
    for I := 0 to Source.Size - 1 do
    begin
      if (I > 0) and (I mod CharCount = 0) then
        Number := LB + IntToHex(PByte(J)^, NumberLength)
      else
        Number := IntToHex(PByte(J)^, NumberLength);
      Move(S, Number, K, Size);
      Inc(K, Length(Number));
      Inc(J);
    end;
    Target.Text := S;
  end;
end;

function Parse(const Source: TStrings; const Target: TMemoryStream): Boolean;
var
  I, J, K: Integer;
  S, Number: string;
begin
  Target.Clear;
  Result := Source.Count > 0;
  if Result then
    for I := 0 to Source.Count - 1 do
    begin
      S := Trim(Source[I]);
      J := 1;
      Number := Copy(S, J, NumberLength);
      while Number <> '' do
      begin
        Result := TryStrToInt(Dollar + Number, K);
        if Result then
        begin
          Target.Write(K, SizeOf(Byte));
          Inc(J, NumberLength);
          Number := Copy(S, J, NumberLength);
        end
        else
          Break;
      end;
    end;
end;

function Put(var Target: TMemoryStream; const Source: TMemoryStream): Boolean;
var
  Backup: TStream;
begin
  Backup := Target;
  Target := Source;
  if Assigned(Backup) then Backup.Free;
  Result := Assigned(Target);
end;

procedure TCustomBlobManager.AssignTo(Dest: TPersistent);
var
  Stream: TMemoryStream;
begin
  if Dest is TCustomBlobManager then
  begin
    Stream := TMemoryStream.Create;
    try
      Save(Stream);
      Stream.Position := 0;
      TCustomBlobManager(Dest).Open(Stream);
    finally
      Stream.Free;
    end;
  end
  else
    inherited AssignTo(Dest);
end;

procedure TCustomBlobManager.BeginUpdate;
begin
  CommonNameList.BeginUpdate;
  HiddenNameList.BeginUpdate;
end;

function TCustomBlobManager.CheckIndex(const Index: Integer; const NameList: TFastList): Boolean;
begin
  Result := (Index >= 0) and (Index < NameList.Count);
end;

procedure TCustomBlobManager.Clear;
var
  K: TItemKind;
begin
  for K := Low(TItemKind) to High(TItemKind) do
  begin
    DeleteNameList(K);
    DeleteHeader(K);
  end;
end;

procedure TCustomBlobManager.EndUpdate;
begin
  CommonNameList.EndUpdate;
  HiddenNameList.EndUpdate;
end;

function TBlobManager.CheckItem(const Stream: TStream; const ItemKind: TItemKind;
  const Index: Integer): Boolean;
var
  H: PHeader;
begin
  H := Header[ItemKind];
  Result := (Index >= 0) and (Index < H.Count) and
    not Eof(Stream, H.From[Index] + H.Size[Index], 0);
end;

constructor TBlobManager.Create(AOwner: TComponent);
begin
  inherited;
  FCommonNameList := TFastList.Create;
  FCommonNameList.IndexTypes := [ttNameValue, ttName];
  FHiddenNameList := TFastList.Create;
  FHiddenNameList.IndexTypes := [ttNameValue, ttName];
  FIdent := DefaultIdent;
  FAutoLoad := True;
  FCompressionLevel := clDefault;
end;

procedure TBlobManager.DeleteHeader(const ItemKind: TItemKind);
var
  H: PHeader;
begin
  H := Header[ItemKind];
  H.Kind := nil;
  H.Name := nil;
  H.From := nil;
  H.Size := nil;
  FillChar(H^, SizeOf(THeader), 0);
end;

procedure TBlobManager.DeleteHeader;
begin
  DeleteHeader(ikCommon);
end;

function TBlobManager.DeleteItem(const ItemKind: TItemKind; const Index: Integer): Boolean;
var
  L: TFastList;
begin
  DoBeforeDelete(ItemKind, Index);
  L := NameList[ItemKind];
  Result := CheckIndex(Index, L) and DeleteItem(Item[L, Index]);
  if Result then
  begin
    L.Delete(Index);
    DoAfterDelete(ItemKind, Index);
  end;
end;

function TBlobManager.DeleteItem(const Index: Integer): Boolean;
begin
  Result := DeleteItem(ikCommon, Index);
end;

function TBlobManager.DeleteItem(const Item: PItem): Boolean;
begin
  Result := Assigned(Item);
  if Result then
  begin
    Item.Stream.Free;
    Dispose(Item);
  end;
end;

function TBlobManager.DeleteNameList: TFastList;
begin
  Result := DeleteNameList(ikCommon);
end;

function TBlobManager.DeleteNameList(const ItemKind: TItemKind): TFastList;
var
  I: Integer;
begin
  DoBeforeClear;
  Result := NameList[ItemKind];
  for I := 0 to Result.Count - 1 do DeleteItem(Item[Result, I]);
  Result.Clear;
  DoAfterClear;
end;

destructor TBlobManager.Destroy;
var
  K: TItemKind;
begin
  for K := Low(TItemKind) to High(TItemKind) do
  begin
    DeleteHeader(K);
    DeleteNameList(K);
  end;
  FCommonNameList.Free;
  FHiddenNameList.Free;
  inherited;
end;

procedure TBlobManager.DoAfterClear;
begin
  if Assigned(FAfterClear) then FAfterClear(Self);
end;

procedure TBlobManager.DoAfterDelete(const ItemKind: TItemKind; const ItemIndex: Integer);
begin
  if Assigned(FAfterDelete) then FAfterDelete(Self, ItemKind, ItemIndex);
end;

procedure TBlobManager.DoAfterOpen(const Stream: TStream);
begin
  if Assigned(FAfterOpen) then FAfterOpen(Self, Stream);
end;

procedure TBlobManager.DoAfterSave(const Stream: TStream);
begin
  if Assigned(FAfterSave) then FAfterSave(Self, Stream);
end;

procedure TBlobManager.DoBeforeClear;
begin
  if Assigned(FBeforeClear) then FBeforeClear(Self);
end;

procedure TBlobManager.DoBeforeDelete(const ItemKind: TItemKind; const ItemIndex: Integer);
begin
  if Assigned(FBeforeDelete) then FBeforeDelete(Self, ItemKind, ItemIndex);
end;

procedure TBlobManager.DoBeforeOpen(const Stream: TStream);
begin
  if Assigned(FBeforeOpen) then FBeforeOpen(Self, Stream);
end;

procedure TBlobManager.DoBeforeSave(const Stream: TStream);
begin
  if Assigned(FBeforeSave) then FBeforeSave(Self, Stream);
end;

function TBlobManager.Export(const Index: Integer; const Data: Pointer): Boolean;
begin
  Result := Export(ikCommon, Index, Data);
end;

function TBlobManager.Export(const Item: PItem; const Data: Pointer): Boolean;
begin
  Result := Assigned(Item);
  if Result then
  begin
    Item.Stream.Position := 0;
    Item.Stream.Read(Data^, Item.Stream.Size);
  end;
end;

function TBlobManager.Export(const ItemKind: TItemKind; const Index: Integer; const Data: Pointer): Boolean;
var
  L: TFastList;
begin
  L := NameList[ItemKind];
  Result := CheckIndex(Index, L) and Export(Item[L, Index], Data);
end;

{$IFNDEF NOGRAPHICS}
function TBlobManager.ExportGraphic(const Index: Integer; const Graphic: TGraphic): Boolean;
begin
  Result := CheckIndex(Index, FCommonNameList) and Export(Item[FCommonNameList, Index], Graphic);
end;
{$ENDIF}

{$IFNDEF NOGRAPHICS}
function TBlobManager.ExportGraphic(const Item: PItem; const Graphic: TGraphic): Boolean;
begin
  Result := Assigned(Item);
  if Result then
  begin
    Item.Stream.Position := 0;
    Graphic.LoadFromStream(Item.Stream);
  end;
end;
{$ENDIF}

function TBlobManager.ExportText(const Index: Integer; out Text: string): Boolean;
begin
  Result := CheckIndex(Index, FCommonNameList) and ExportText(Item[FCommonNameList, Index], Text);
end;

function TBlobManager.ExportText(const Item: PItem; out Text: string): Boolean;
var
  I: Int64;
begin
  Result := Assigned(Item);
  if Result then
  begin
    I := Item.Stream.Size;
    SetLength(Text, I div SizeOf(Char));
    Item.Stream.Position := 0;
    Item.Stream.Read(Pointer(Text)^, I);
  end;
end;

function TBlobManager.Find(const ItemKind: TItemKind; const AName: string; out Index: Integer): Boolean;
begin
  Result := NameList[ItemKind].Find(ttNameValue, AName, Index);
end;

function TBlobManager.Find(const AName: string): PItem;
begin
  Result := Find(ikCommon, AName);
end;

function TBlobManager.Find(const ItemKind: TItemKind; const AName: string): PItem;
var
  L: TFastList;
  I: Integer;
begin
  L := NameList[ItemKind];
  if L.Find(ttNameValue, AName, I) then
    Result := Item[L, I]
  else
    Result := nil;
end;

function TBlobManager.Find(const AName: string; out AItem: PItem): Boolean;
begin
  Result := Find(ikCommon, AName, AItem);
end;

function TBlobManager.Find(const ItemKind: TItemKind; const AName: string; out AItem: PItem): Boolean;
var
  L: TFastList;
  I: Integer;
begin
  L := NameList[ItemKind];
  Result := L.Find(ttNameValue, AName, I);
  if Result then
    AItem := Item[L, I]
  else
    AItem := nil;
end;

function TBlobManager.Find(const AName: string; out Index: Integer): Boolean;
begin
  Result := Find(ikCommon, AName, Index);
end;

function TBlobManager.GetAutoFree: Boolean;
begin
  Result := FAutoFree;
end;

function TBlobManager.GetAutoLoad: Boolean;
begin
  Result := FAutoLoad;
end;

function TBlobManager.GetCommonHeader: THeader;
begin
  Result := FCommonHeader;
end;

function TBlobManager.GetCommonNameList: TFastList;
begin
  Result := FCommonNameList;
end;

function TBlobManager.GetFastList(const ItemKind: TItemKind): TFastList;
begin
  if ItemKind = ikCommon then
    Result := FCommonNameList
  else
    Result := FHiddenNameList;
end;

function TBlobManager.GetHeader(const ItemKind: TItemKind): PHeader;
begin
  case ItemKind of
    ikCommon: Result := @FCommonHeader;
    ikHidden: Result := @FHiddenHeader;
  else
    Result := nil;
  end;
end;

function TBlobManager.GetHiddenHeader: THeader;
begin
  Result := FHiddenHeader;
end;

function TBlobManager.GetHiddenNameList: TFastList;
begin
  Result := FHiddenNameList;
end;

function TBlobManager.GetIdent: string;
begin
  Result := FIdent;
end;

function TBlobManager.GetItem(const NameList: TFastList; const Index: Integer): PItem;
begin
  Result := PItem(NameList.Objects[Index]);
end;

function TBlobManager.GetItemText(const ItemKind: TItemKind; const Index: Integer): string;
var
  L: TFastList;
begin
  L := NameList[ItemKind];
  if CheckIndex(Index, L) and (Item[L, Index].Kind = dkText) then
    Result := GetText(Item[L, Index]^)
  else
    Result := '';
end;

function TBlobManager.GetText(const AItem: TItem): string;
var
  I: Int64;
begin
  I := AItem.Stream.Size;
  SetLength(Result, I div SizeOf(Char));
  AItem.Stream.Position := 0;
  AItem.Stream.Read(Pointer(Result)^, I);
end;

function TBlobManager.Import(const DataKind: TDataKind; const AName: string; const Data: Pointer;
  const Size: Int64): Integer;
begin
  Result := Import(ikCommon, DataKind, AName, Data, Size);
end;

function TBlobManager.Import(const ItemKind: TItemKind; const DataKind: TDataKind; const AName: string;
  const Stream: TMemoryStream): Integer;
begin
  Result := Import(ItemKind, AName, MakeItem(DataKind, Stream));
end;

function TBlobManager.Import(const ItemKind: TItemKind; const DataKind: TDataKind; const AName: string;
  const Data: Pointer; const Size: Int64): Integer;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  Stream.Size := Size;
  Stream.Write(Data^, Size);
  Result := Import(ItemKind, AName, MakeItem(DataKind, Stream));
end;

function TBlobManager.Import(const DataKind: TDataKind; const AName: string;
  const Stream: TMemoryStream): Integer;
begin
  Result := Import(ikCommon, DataKind, AName, Stream);
end;

function TBlobManager.Import(const ItemKind: TItemKind; const AName: string; const AItem: TItem): Integer;
var
  L: TFastList;
  P: PItem;
begin
  L := NameList[ItemKind];
  Result := L.Add(AName);
  New(P);
  Item[L, Result] := P;
  P^ := AItem;
end;

{$IFNDEF NOGRAPHICS}
function TBlobManager.ImportGraphic(const AName: string; const Graphic: TGraphic): Integer;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  Graphic.SaveToStream(Stream);
  Result := Import(ikCommon, AName, MakeItem(dkGraphic, Stream));
end;
{$ENDIF}

function TBlobManager.ImportText(const AName, Text: string): Integer;
begin
  Result := Import(dkText, AName, Pointer(Text), Length(Text) * SizeOf(Char));
end;

function TBlobManager.IndexOf(const AName: string): Integer;
begin
  Result := IndexOf(ikCommon, AName);
end;

function TBlobManager.LoadFromFile(const FileName: string): Boolean;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    Stream.Position := 0;
    Result := Open(Stream);
  finally
    Stream.Free;
  end;
end;

function TBlobManager.IndexOf(const ItemKind: TItemKind; const AName: string): Integer;
begin
  if not Find(ItemKind, AName, Result) then Result := -1;
end;

function TBlobManager.MakeHeader(const ItemKind: TItemKind; const Count: Integer): PHeader;
begin
  Result := Header[ItemKind];
  Result.Count := Count;
  SetLength(Result.Kind, Count);
  SetLength(Result.Name, Count);
  SetLength(Result.From, Count);
  SetLength(Result.Size, Count);
end;

function TBlobManager.Open(const Source: TStream): Boolean;
begin
  DoBeforeOpen(Source);
  if FCompression then Decompress(Source);
  Result := ReadIdent(FIdent, Source);
  if Result then
  begin
    Result := ReadHeader(Source, ikCommon) and ReadHeader(Source, ikHidden);
    if Result and FAutoLoad then
    begin
      ReadNameList(Source, ikCommon);
      ReadNameList(Source, ikHidden);
    end
    else begin
      DeleteNameList(ikCommon);
      DeleteNameList(ikHidden);
    end;
  end;
  DoAfterOpen(Source);
end;

function TBlobManager.Open(const Source: TStrings): Boolean;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    Parse(Source, Stream);
    Result := Open(Stream);
  finally
    Stream.Free;
  end;
end;

function TBlobManager.Replace(const ItemKind: TItemKind; const Index: Integer; const AName: string;
  const Stream: TMemoryStream): Boolean;
var
  L: TFastList;
begin
  L := NameList[ItemKind];
  Result := CheckIndex(Index, L);
  if Result then
  begin
    Put(Item[L, Index].Stream, Stream);
    L[Index] := AName;
  end;
end;

function TBlobManager.Replace(const ItemKind: TItemKind; const Index: Integer; const AName: string;
  const Data: Pointer; const Size: Int64): Boolean;
var
  L: TFastList;
begin
  L := NameList[ItemKind];
  Result := CheckIndex(Index, L);
  if Result then
  begin
    Item[L, Index].Stream.Size := Size;
    Item[L, Index].Stream.Position := 0;
    Item[L, Index].Stream.Write(Data^, Size);
    L[Index] := AName;
  end;
end;

function TBlobManager.Replace(const Index: Integer; const AName: string; const Data: Pointer;
  const Size: Int64): Boolean;
begin
  Result := Replace(ikCommon, Index, AName, Data, Size);
end;

function TBlobManager.Read(const ItemKind: TItemKind; const AName: string; var Value;
  const Size: Int64): Boolean;
var
  P: PItem;
begin
  P := Find(ItemKind, AName);
  Result := Assigned(P) and (Size = P.Stream.Size);
  if Result then Export(P, @Value);
end;

function TBlobManager.Read(const AName: string; var Value; const Size: Int64): Boolean;
begin
  Result := Read(ikCommon, AName, Value, Size);
end;

function TBlobManager.ReadBoolean(const AName: string; var Value: Boolean;
  const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadByte(const AName: string; var Value: Byte; const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadDouble(const AName: string; var Value: Double; const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadExtended(const AName: string; var Value: Extended;
  const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadHeader(const Stream: TStream; const ItemKind: TItemKind): Boolean;
var
  I: NativeInt;
  J, K: Int64;
  H: PHeader;
begin
  Result := ReadValue(Stream, J, SizeOf(J)) and (J >= 0) and (J <= Stream.Size);
  if Result then
  begin
    H := MakeHeader(ItemKind, J);
    for I := 0 to J - 1 do
    begin
      Result := ReadValue(Stream, H.Kind[I], SizeOf(H.Kind[I])) and ReadValue(Stream, K, SizeOf(K)) and
        not Eof(Stream, K) and (K >= 0) and (K <= SizeOf(H.Name[I]));
      if not Result then Break;
      FillChar(H.Name[I], SizeOf(H.Name[I]), 0);
      Stream.Read(H.Name[I], K);
      Result := ReadValue(Stream, H.From[I], SizeOf(H.From[I])) and
        ReadValue(Stream, H.Size[I], SizeOf(H.Size[I])) and
        not Eof(Stream, H.From[I] + H.Size[I], 0);
      if not Result then Break;
    end;
  end;
  if not Result then DeleteHeader(ItemKind);
end;

function TBlobManager.ReadInt64(const AName: string; var Value: Int64; const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadInteger(const AName: string; var Value: Integer;
  const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadItem(const Stream: TStream; const ItemKind: TItemKind; const Index: Integer;
  out AName: string; out Item: TItem): Boolean;
var
  H: PHeader;
begin
  Result := CheckItem(Stream, ItemKind, Index);
  if Result then
  begin
    H := Header[ItemKind];
    AName := H.Name[Index];
    Stream.Position := H.From[Index];
    Result := not Eof(Stream, H.Size[Index]);
    if Result then
    begin
      Item.Kind := H.Kind[Index];
      Item.Stream := TMemoryStream.Create;
      try
        Item.Stream.Size := H.Size[Index];
        Result := ReadValue(Stream, Item.Stream.Memory^, H.Size[Index]);
      except
        Item.Stream.Free;
        raise;
      end;
      if not Result then Item.Stream.Free;
    end;
  end;
end;

function TBlobManager.ReadLongWord(const AName: string; var Value: LongWord;
  const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadNameList(const Stream: TStream; const ItemKind: TItemKind): Boolean;
var
  H: PHeader;
  L: TFastList;
  I: Integer;
  P: PItem;
  S: string;
begin
  H := Header[ItemKind];
  L := DeleteNameList(ItemKind);
  Result := H.Count > 0;
  if Result then
  begin
    L.BeginUpdate;
    try
      L.Capacity := H.Count;
      for I := 0 to H.Count - 1 do
      begin
        New(P);
        try
          Result := ReadItem(Stream, ItemKind, I, S, P^);
        except
          Dispose(P);
          raise;
        end;
        if not Result then
        begin
          Dispose(P);
          Break;
        end;
        L.AddObject(S, Pointer(P));
      end;
      if not Result then DeleteNameList(ItemKind);
    finally
      L.EndUpdate;
    end;
  end;
end;

function TBlobManager.ReadShortint(const AName: string; var Value: Shortint;
  const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadSingle(const AName: string; var Value: Single; const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadSmallint(const AName: string; var Value: Smallint;
  const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.ReadString(const AName: string; var Value: string; const ItemKind: TItemKind): Boolean;
var
  P: PItem;
begin
  Result := Find(ItemKind, AName, P);
  if Result then
  begin
    SetLength(Value, P.Stream.Size div SizeOf(Char));
    Export(P, Pointer(Value));
  end;
end;

function TBlobManager.ReadWord(const AName: string; var Value: Word; const ItemKind: TItemKind): Boolean;
begin
  Result := Read(ItemKind, AName, Value, SizeOf(Value));
end;

function TBlobManager.Replace(const Index: Integer; const AName: string;
  const Stream: TMemoryStream): Boolean;
begin
  Result := Replace(ikCommon, Index, AName, Stream);
end;

{$IFNDEF NOGRAPHICS}
function TBlobManager.ReplaceGraphic(const Index: Integer; const AName: string;
  const Graphic: TGraphic): Boolean;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  Graphic.SaveToStream(Stream);
  Result := Replace(Index, AName, Stream);
end;
{$ENDIF}

function TBlobManager.ReplaceText(const Index: Integer; const AName, Text: string): Boolean;
begin
  Result := Replace(Index, AName, Pointer(Text), Length(Text) * SizeOf(Char));
end;

procedure TBlobManager.Save(const Target: TMemoryStream);
var
  K: TItemKind;
  Reference: array[TItemKind] of TArray<Int64>;
begin
  DoBeforeSave(Target);
  Target.Clear;
  WriteIdent(FIdent, Target);
  try
    for K := Low(TItemKind) to High(TItemKind) do
    begin
      WriteHeader(Target, K, Reference[K]);
      if FAutoFree then
        DeleteHeader(K);
    end;
    for K := Low(TItemKind) to High(TItemKind) do WriteNameList(Target, K, Reference[K]);
  finally
    for K := Low(TItemKind) to High(TItemKind) do Reference[K] := nil;
  end;
  if FCompression then Compress(Target, FCompressionLevel);
  DoAfterSave(Target);
end;

procedure TBlobManager.Save(const Target: TStrings);
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    Save(Stream);
    Parse(Stream, Target, DefaultCharCount);
  finally
    Stream.Free;
  end;
end;

procedure TBlobManager.SaveToFile(const FileName: string);
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    Save(Stream);
    Stream.SaveToFile(FileName);
  finally
    Stream.Free;
  end;
end;

procedure TBlobManager.SetAutoFree(const Value: Boolean);
begin
  FAutoFree := Value;
end;

procedure TBlobManager.SetAutoLoad(const Value: Boolean);
begin
  FAutoLoad := Value;
end;

procedure TBlobManager.SetCommonHeader(const Value: THeader);
begin
  FCommonHeader := Value;
end;

procedure TBlobManager.SetCommonNameList(const Value: TFastList);
begin
  FCommonNameList := Value;
end;

procedure TBlobManager.SetHiddenHeader(const Value: THeader);
begin
  FHiddenHeader := Value;
end;

procedure TBlobManager.SetHiddenNameList(const Value: TFastList);
begin
  FHiddenNameList := Value;
end;

procedure TBlobManager.SetIdent(const Value: string);
begin
  FIdent := Value;
end;

procedure TBlobManager.SetItem(const NameList: TFastList; const Index: Integer; const Value: PItem);
begin
  NameList.Objects[Index] := Pointer(Value);
end;

procedure TBlobManager.SetItemText(const ItemKind: TItemKind; const Index: Integer; const Value: string);
var
  L: TFastList;
begin
  L := NameList[ItemKind];
  if CheckIndex(Index, L) then SetText(Item[L, Index]^, Value);
end;

procedure TBlobManager.SetText(const AItem: TItem; const Value: string);
begin
  AItem.Stream.Size := Length(Value) * SizeOf(Char);
  AItem.Stream.Position := 0;
  AItem.Stream.Write(Pointer(Value)^, AItem.Stream.Size);
end;

procedure TBlobManager.Write(const ItemKind: TItemKind; const AName: string; const Value; const Size: Int64);
var
  P: PItem;
begin
  P := Find(ItemKind, AName);
  if Assigned(P) then
  begin
    P.Stream.Clear;
    P.Stream.Size := Size;
    P.Stream.Write(Value, Size);
  end
  else
    Import(ItemKind, dkData, AName, @Value, Size);
end;

procedure TBlobManager.Write(const AName: string; const Value; const Size: Int64);
begin
  Write(ikCommon, AName, Value, Size);
end;

procedure TBlobManager.WriteBoolean(const AName: string; const Value: Boolean; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteByte(const AName: string; const Value: Byte; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteDouble(const AName: string; const Value: Double; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteExtended(const AName: string; const Value: Extended; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteHeader(const Stream: TStream; const ItemKind: TItemKind;
  var Reference: TArray<Int64>);
var
  L: TFastList;
  I: NativeInt;
  J, Count: Int64;
begin
  L := NameList[ItemKind];
  Count := L.Count;
  Stream.Write(Count, SizeOf(Count));
  SetLength(Reference, Count);
  for I := 0 to L.Count - 1 do
  begin
    Stream.Write(Item[L, I].Kind, SizeOf(Item[L, I].Kind));
    J := Length(L[I]) * SizeOf(Char);
    Stream.Write(J, SizeOf(J));
    Stream.Write(Pointer(L[I])^, J);
    Reference[I] := Stream.Position;
    J := 0;
    Stream.Write(J, SizeOf(J));
    Stream.Write(J, SizeOf(J));
  end;
end;

procedure TBlobManager.WriteInt64(const AName: string; const Value: Int64; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteInteger(const AName: string; const Value: Integer; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteLongWord(const AName: string; const Value: LongWord; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteNameList(const Stream: TMemoryStream; const ItemKind: TItemKind;
  const Reference: TArray<Int64>);
var
  L: TFastList;
  I: NativeInt;
  J, K: Int64;
begin
  L := NameList[ItemKind];
  J := Stream.Size;
  if not FAutoFree then
  begin
    K := 0;
    for I := 0 to L.Count - 1 do Inc(K, Item[L, I].Stream.Size);
    Stream.Size := J + K;
  end;
  for I := 0 to L.Count - 1 do
  begin
    PInt64(NativeInt(Stream.Memory) + Reference[I])^ := J;
    K := Item[L, I].Stream.Size;
    PInt64(NativeInt(Stream.Memory) + Reference[I] + SizeOf(K))^ := K;
    if FAutoFree then
      Stream.Size := Stream.Size + K;
    CopyMemory(Pointer(NativeInt(Stream.Memory) + J), Item[L, I].Stream.Memory, Item[L, I].Stream.Size);
    if FAutoFree then
      DeleteItem(Item[L, I]);
    Inc(J, K);
  end;
  if FAutoFree then L.Clear;
end;

procedure TBlobManager.WriteShortint(const AName: string; const Value: Shortint; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteSingle(const AName: string; const Value: Single; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteSmallint(const AName: string; const Value: Smallint; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

procedure TBlobManager.WriteString(const AName, Value: string; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Pointer(Value)^, Length(Value) * SizeOf(Char));
end;

procedure TBlobManager.WriteWord(const AName: string; const Value: Word; const ItemKind: TItemKind);
begin
  Write(ItemKind, AName, Value, SizeOf(Value));
end;

end.
