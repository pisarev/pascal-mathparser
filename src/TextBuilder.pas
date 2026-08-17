{ ************************************************************************** }
{                                                                            }
{ TextBuilder                                                                }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit TextBuilder;

interface

{$B-}
{$I Directives.inc}
{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

uses
  {$IFDEF FPC}
  SysUtils, Types, MemoryUtils, NumberConsts;
  {$ELSE}
  {$IFDEF DELPHI_10.2}
  WinApi.Windows, System.SysUtils, System.Types, MemoryUtils, NumberConsts;
  {$ELSE}
  Windows, SysUtils, Types, MemoryUtils, NumberConsts;
  {$ENDIF}
  {$ENDIF}

type
  ETextBuilderError = class(Exception);

  TTextBuilder = class
  private
    FIncreaseFactor: Extended;
    FDecreaseFactor: Extended;
    FIndex: Integer;
    {$IFDEF FPC}
    FCharArray: TArray<Char>;
    {$ELSE}
    FCharArray: {$IFDEF DELPHI_10.2}TArray<Char>{$ELSE}TCharDynArray{$ENDIF};
    {$ENDIF}
    function GetCapacity: Integer;
    function GetData: PChar;
    function GetSize: Integer;
    function GetText: string;
    procedure SetCapacity(const Value: Integer);
  protected
    procedure Error(const Message: string); overload; virtual;
    procedure Error(const Message: string; const Arguments: array of const); overload; virtual;
    procedure FindIndex; virtual;
    procedure MoveIndex(const Value: Integer); virtual;
    procedure Resize(const Count: Integer); virtual;
    {$IFDEF FPC}
    property CharArray: TArray<Char> read FCharArray write FCharArray;
    {$ELSE}
    property CharArray: {$IFDEF DELPHI_10.2}TArray<Char>{$ELSE}TCharDynArray{$ENDIF} read FCharArray write FCharArray;
    {$ENDIF}
    property Index: Integer read FIndex write FIndex;
  public
    constructor Create(const ACapacity: Integer); overload; virtual;
    constructor Create(const AText: string); overload; virtual;
    constructor Create; overload; virtual;
    destructor Destroy; override;
    procedure IncreaseCapacity(const Value: Integer); virtual;
    procedure Clear; virtual;
    procedure Reset; virtual;
    function Delete(const AIndex, Count: Integer): Boolean; virtual;
    procedure Append(const P: Pointer; const Count: Integer); overload; virtual;
    procedure Append(const S: string); overload; virtual;
    procedure Append(const S, Delimiter: string); overload; virtual;
    function Insert(const P: Pointer; const Count: Integer;
      const AIndex: Integer = 0): Boolean; overload; virtual;
    function Insert(const S: string; const AIndex: Integer = 0): Boolean; overload; virtual;
    function Insert(const S, Delimiter: string; const AIndex: Integer = 0): Boolean; overload; virtual;
    property Data: PChar read GetData;
    property Text: string read GetText;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Size: Integer read GetSize;
    property IncreaseFactor: Extended read FIncreaseFactor write FIncreaseFactor;
    property DecreaseFactor: Extended read FDecreaseFactor write FDecreaseFactor;
  end;

const
  MinCapacity = 1024;
  DefaultIncreaseFactor = 2;
  DefaultDecreaseFactor = 0.75;

implementation

uses
  {$IFDEF FPC}
  Math, TextConsts;
  {$ELSE}
  {$IFDEF DELPHI_10.2}
  System.Math, TextConsts;
  {$ELSE}
  Math, TextConsts;
  {$ENDIF}
  {$ENDIF}

{ TTextBuilder }

procedure TTextBuilder.Append(const P: Pointer; const Count: Integer);
begin
  if Count > 0 then
  begin
    IncreaseCapacity(Count);
    CopyMemory(@FCharArray[Size], P, Count * SizeOf(Char));
    MoveIndex(Count);
  end;
end;

procedure TTextBuilder.Append(const S: string);
begin
  Append(Pointer(S), Length(S));
end;

procedure TTextBuilder.Append(const S, Delimiter: string);
begin
  if Size > 0 then
    Append(Delimiter + S)
  else
    Append(S);
end;

procedure TTextBuilder.Clear;
var
  Count: Integer;
begin
  Count := Round(Length(FCharArray) * FDecreaseFactor);
  FCharArray := nil;
  Resize(Count);
  FIndex := -1;
end;

constructor TTextBuilder.Create(const ACapacity: Integer);
begin
  FIncreaseFactor := DefaultIncreaseFactor;
  FDecreaseFactor := DefaultDecreaseFactor;
  FIndex := -1;
  Capacity := ACapacity;
end;

constructor TTextBuilder.Create(const AText: string);
begin
  Create;
  Append(AText);
end;

constructor TTextBuilder.Create;
begin
  Create(MinCapacity);
end;

function TTextBuilder.Delete(const AIndex, Count: Integer): Boolean;
begin
  Result := MemoryUtils.Delete(FCharArray, AIndex * SizeOf(Char), Count * SizeOf(Char), Size * SizeOf(Char));
  if Result then
  begin
    ZeroMemory(PAnsiChar(FCharArray) + (Size - Count) * SizeOf(Char), Count * SizeOf(Char));
    MoveIndex(-Count);
  end;
end;

destructor TTextBuilder.Destroy;
begin
  FCharArray := nil;
  inherited;
end;

procedure TTextBuilder.Error(const Message: string; const Arguments: array of const);
begin
  raise ETextBuilderError.CreateFmt(Message, Arguments);
end;

procedure TTextBuilder.Error(const Message: string);
begin
  Error(Message, []);
end;

procedure TTextBuilder.FindIndex;
begin
  if FIndex < 0 then
  begin
    FIndex := High(FCharArray);
    while (FIndex > -1) and (FCharArray[FIndex] = #0) do Dec(FIndex);
  end;
end;

function TTextBuilder.GetCapacity: Integer;
begin
  Result := Length(FCharArray);
end;

function TTextBuilder.GetData: PChar;
begin
  Result := PChar(FCharArray);
end;

function TTextBuilder.GetSize: Integer;
begin
  FindIndex;
  Result := FIndex + 1;
end;

function TTextBuilder.GetText: string;
begin
  if Size > 0 then
    SetString(Result, PChar(FCharArray), Size)
  else
    Result := '';
end;

procedure TTextBuilder.IncreaseCapacity(const Value: Integer);
var
  Count: Integer;
begin
  Count := Size + Value;
  if Count > Length(FCharArray) then Capacity := Round(Count * FIncreaseFactor);
end;

function TTextBuilder.Insert(const S, Delimiter: string; const AIndex: Integer): Boolean;
begin
  if Size > 0 then
    Result := Insert(S + Delimiter, AIndex)
  else
    Result := Insert(S, AIndex);
end;

function TTextBuilder.Insert(const P: Pointer; const Count, AIndex: Integer): Boolean;
begin
  IncreaseCapacity(Count);
  Result := MemoryUtils.Insert(FCharArray, P, AIndex * SizeOf(Char), Size * SizeOf(Char),
    Count * SizeOf(Char));
  MoveIndex(Count);
end;

function TTextBuilder.Insert(const S: string; const AIndex: Integer): Boolean;
begin
  Result := Insert(Pointer(S), Length(S), AIndex);
end;

procedure TTextBuilder.MoveIndex(const Value: Integer);
begin
  Inc(FIndex, Value);
  if FIndex > High(FCharArray) then FIndex := -1;
end;

procedure TTextBuilder.Reset;
begin
  ZeroMemory(PAnsiChar(FCharArray), Length(FCharArray) * SizeOf(Char));
  FIndex := -1;
end;

procedure TTextBuilder.Resize(const Count: Integer);
begin
  SetLength(FCharArray, IfThen(Count < MinCapacity, MinCapacity, Count));
end;

procedure TTextBuilder.SetCapacity(const Value: Integer);
begin
  if Value <> Length(FCharArray) then
  begin
    if Value < Size then MoveIndex(Value - Size);
    Resize(Value);
  end;
end;

end.
