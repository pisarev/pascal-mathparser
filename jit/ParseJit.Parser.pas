{ ************************************************************************** }
{                                                                            }
{ ParseJit.Parser                                                            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseJit.Parser;

{$B-}
{$O+}
{$R-}
{$Q-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Math, Classes, FastList, Notifier, ParseTypes, Parser, ThreadUtils,
  ValueTypes, ValueUtils, ParseJit.Decoder, ParseJit.CodeGen, ParseJit.Executor;
  {$ELSE}
  {$IFDEF DELPHI_XE7}WinApi.Windows,{$ELSE}Windows,{$ENDIF}
  System.SysUtils, System.Math, System.Classes, FastList, Notifier, ParseTypes,
  Parser, ThreadUtils, ValueTypes, ValueUtils, ParseJit.Decoder, ParseJit.CodeGen,
  ParseJit.Executor;
  {$ENDIF}

type
  EJitOrphan = class(Exception);

  TJitParser = class;

  TJitEntry = class
  public
    Code: TJitCode;
    Executor: TJitExecutor;
    Owner: TJitParser;
    Generation: Int64;
    destructor Destroy; override;
    function Ready: Boolean;
    function Reason: string;
    function Execute: Double;
    function Fresh: Boolean;
  end;

  TJitScript = class(TJitEntry)
  end;

  TJitParser = class(TMathParser)
  private
    FList: TFastList;
    FEnabled: Boolean;
    FHitCount: Int64;
    FMissCount: Int64;
    FCompileCount: Int64;
    FLastText: string;
    FInlineCount: Int64;
    FLookupCount: Int64;
    FLastCode: TJitEntry;
    FGeneration: Int64;
    FMachineCount: Int64;
    FExecutorCount: Int64;
    FIssued: TList;
    FIssuedLock: TRTLCriticalSection;
    procedure Issue(const Entry: TJitEntry);
    procedure Withdraw(const Entry: TJitEntry);
    function GetCode(const Text: string): TJitEntry;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Notify(const NotifyType: TNotifyType; const Sender: TComponent); override;
    function AsDouble(const Text: string): Double; override;
    function ExecuteMany(const Text: string; var Variable: Double; const Inputs: array of Double;
      var Outputs: array of Double): Boolean; virtual;
    procedure ClearCode; virtual;
    function CodeReason(const Text: string): string; virtual;
    function CompileScript(const Script: TScript): TJitScript; virtual;
    function EvaluationMask: TFPUExceptionMask;
    function ScriptReason(const Script: TScript): string; virtual;
    property JitEnabled: Boolean read FEnabled write FEnabled;
    property MachineCount: Int64 read FMachineCount;
    property ExecutorCount: Int64 read FExecutorCount;
    property Generation: Int64 read FGeneration;
    property HitCount: Int64 read FHitCount;
    property MissCount: Int64 read FMissCount;
    property CompileCount: Int64 read FCompileCount;
    property InlineCount: Int64 read FInlineCount;
    property LookupCount: Int64 read FLookupCount;
  end;

const
  JitOrphanMessage = 'the parser that compiled this script is gone';

implementation

uses
  ParseErrors;

destructor TJitEntry.Destroy;
begin
  if Assigned(Owner) then Owner.Withdraw(Self);
  Owner := nil;
  Code.Free;
  Executor.Free;
  inherited;
end;

function TJitEntry.Fresh: Boolean;
begin
  if not Assigned(Owner) then Exit(False);
  if Owner.Generation <> Generation then Exit(False);
  if Assigned(Code) and Code.Ready then Exit(Code.Decoder.Valid);
  if Assigned(Executor) and Executor.Ready then Exit(Executor.Decoder.Valid);
  Result := True;
end;

function TJitEntry.Ready: Boolean;
begin
  Result := ((Assigned(Code) and Code.Ready) or (Assigned(Executor) and Executor.Ready)) and Fresh;
end;

function TJitEntry.Reason: string;
begin
  if not Assigned(Owner) then
    Result := JitOrphanMessage
  else if not Fresh then
    Result := 'parser changed'
  else if Assigned(Code) and Code.Ready then
    Result := ''
  else if Assigned(Executor) and Executor.Ready then
  begin
    if Assigned(Code) and (Code.Reason <> '') then
      Result := 'ir executor: ' + Code.Reason
    else
      Result := 'ir executor';
  end
  else if Assigned(Code) then
    Result := Code.Reason
  else if Assigned(Executor) then
    Result := Executor.Reason
  else
    Result := 'no code';
end;

procedure ArmMask(const Want: TFPUExceptionMask; out Saved: TFPUExceptionMask; out Changed: Boolean);
begin
  Saved := GetExceptionMask;
  Changed := Saved <> Want;
  if Changed then SetExceptionMask(Want);
end;

procedure DisarmMask(const Saved: TFPUExceptionMask; const Changed: Boolean);
begin
  if Changed then SetExceptionMask(Saved);
end;

function TJitEntry.Execute: Double;
var
  Saved: TFPUExceptionMask;
  Changed: Boolean;
  Want: TFPUExceptionMask;
begin
  if not Assigned(Owner) then
    raise EJitOrphan.Create(JitOrphanMessage);
  Want := Owner.EvaluationMask;
  ArmMask(Want, Saved, Changed);
  try
    if Assigned(Code) and Code.Ready then
      Result := Code.Execute
    else
      Result := GetDouble(Executor.Execute);
  finally
    DisarmMask(Saved, Changed);
  end;
end;

constructor TJitParser.Create(AOwner: TComponent);
begin
  inherited;
  FList := TFastList.Create;
  FList.CaseSensitive := True;
  FIssued := TList.Create;
  {$IFDEF FPC}
  InitCriticalSection(FIssuedLock);
  {$ELSE}
  InitializeCriticalSection(FIssuedLock);
  {$ENDIF}
  FEnabled := True;
  FGeneration := 1;
end;

destructor TJitParser.Destroy;
var
  I: Integer;
begin
  ClearCode;
  Enter(FIssuedLock);
  try
    for I := 0 to FIssued.Count - 1 do TJitEntry(FIssued[I]).Owner := nil;
    FIssued.Clear;
  finally
    Leave(FIssuedLock);
  end;
  FIssued.Free;
  {$IFDEF FPC}
  DoneCriticalSection(FIssuedLock);
  {$ELSE}
  DeleteCriticalSection(FIssuedLock);
  {$ENDIF}
  FList.Free;
  inherited;
end;

procedure TJitParser.Issue(const Entry: TJitEntry);
begin
  Enter(FIssuedLock);
  try
    FIssued.Add(Entry);
  finally
    Leave(FIssuedLock);
  end;
end;

procedure TJitParser.Withdraw(const Entry: TJitEntry);
var
  At: Integer;
begin
  if not Assigned(FIssued) then Exit;
  Enter(FIssuedLock);
  try
    At := FIssued.IndexOf(Entry);
    if At >= 0 then FIssued.Delete(At);
  finally
    Leave(FIssuedLock);
  end;
end;

procedure TJitParser.ClearCode;
var
  I: Integer;
begin
  if not Assigned(FList) then Exit;
  for I := 0 to FList.Count - 1 do TJitEntry(FList.Objects[I]).Free;
  FList.Clear;
  FLastText := '';
  FLastCode := nil;
end;

function TJitParser.GetCode(const Text: string): TJitEntry;
var
  Index: Integer;
  Script: TScript;
  Error: TError;
begin
  if Assigned(FLastCode) and (Length(Text) = Length(FLastText)) and (Text = FLastText) then
  begin
    Result := FLastCode;
    Inc(FInlineCount);
    Exit;
  end;
  Inc(FLookupCount);
  Index := FList.IndexOf(Text);
  if Index >= 0 then
  begin
    Result := TJitEntry(FList.Objects[Index]);
    FLastText := Text;
    FLastCode := Result;
    Exit;
  end;
  Result := TJitEntry.Create;
  Result.Owner := Self;
  Inc(FCompileCount);
  try
    StringToScript(Text, Script, Error);
    if Error.ErrorType = etOK then
    begin
      Result.Generation := FGeneration;
      {$IFDEF CPUX64}
      Result.Code := TJitCode.Create(Self);
      Result.Code.Compile(Script);
      {$ENDIF}
      if Assigned(Result.Code) and Result.Code.Ready then Inc(FMachineCount);
      if not Result.Ready then
      begin
        Result.Executor := TJitExecutor.Create(Self);
        Result.Executor.Prepare(Script);
        Inc(FExecutorCount);
      end;
      Script := nil;
    end;
  except
    Result.Free;
    raise;
  end;
  if Result.Generation = 0 then Result.Generation := FGeneration;
  FList.AddObject(Text, Result);
  FLastText := Text;
  FLastCode := Result;
end;

procedure TJitParser.Notify(const NotifyType: TNotifyType; const Sender: TComponent);
const
  Invalidating = [ntCompile, ntAFA, ntAFD, ntATA, ntATD];
begin
  if NotifyType in Invalidating then
  begin
    ClearCode;
    Inc(FGeneration);
  end;
  inherited;
end;

function TJitParser.AsDouble(const Text: string): Double;
var
  Code: TJitEntry;
  Saved: TFPUExceptionMask;
  Changed: Boolean;
begin
  if FEnabled then
  begin
    Code := GetCode(Text);
    if Assigned(Code) and Code.Ready then
    begin
      Inc(FHitCount);
      ArmMask(ExceptionMask, Saved, Changed);
      try
        Result := Code.Execute;
      finally
        DisarmMask(Saved, Changed);
      end;
      Exit;
    end;
    Inc(FMissCount);
  end;
  Result := inherited AsDouble(Text);
end;

function TJitParser.CodeReason(const Text: string): string;
var
  Code: TJitEntry;
begin
  Code := GetCode(Text);
  if Assigned(Code) then
    Result := Code.Reason
  else
    Result := 'no code';
end;

function TJitParser.EvaluationMask: TFPUExceptionMask;
begin
  Result := ExceptionMask;
end;

function TJitParser.CompileScript(const Script: TScript): TJitScript;
begin
  Result := TJitScript.Create;
  try
    Result.Owner := Self;
    Result.Generation := FGeneration;
    Issue(Result);
    Inc(FCompileCount);
    {$IFDEF CPUX64}
    Result.Code := TJitCode.Create(Self);
    Result.Code.Compile(Script);
    {$ENDIF}
    if Assigned(Result.Code) and Result.Code.Ready then Inc(FMachineCount);
    if not Result.Ready then
    begin
      Result.Executor := TJitExecutor.Create(Self);
      Result.Executor.Prepare(Script);
      Inc(FExecutorCount);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TJitParser.ScriptReason(const Script: TScript): string;
var
  Compiled: TJitScript;
begin
  Compiled := CompileScript(Script);
  try
    Result := Compiled.Reason;
  finally
    Compiled.Free;
  end;
end;

function TJitParser.ExecuteMany(const Text: string; var Variable: Double; const Inputs: array of Double;
  var Outputs: array of Double): Boolean;
var
  Code: TJitEntry;
  Script: TScript;
  I: Integer;
  Saved: TFPUExceptionMask;
  Changed: Boolean;
begin
  Result := False;
  for I := Low(Outputs) to Min(High(Inputs), High(Outputs)) do Outputs[I] := NaN;
  if Length(Inputs) > Length(Outputs) then Exit;
  Code := GetCode(Text);
  if Assigned(Code) and Code.Ready then
  begin
    ArmMask(ExceptionMask, Saved, Changed);
    try
      for I := Low(Inputs) to High(Inputs) do
      begin
        Variable := Inputs[I];
        Outputs[I] := Code.Execute;
      end;
    finally
      DisarmMask(Saved, Changed);
    end;
    Inc(FHitCount, Length(Inputs));
    Exit(True);
  end;
  Script := nil;
  try
    StringToScript(Text, Script);
  except
    Exit;
  end;
  for I := Low(Inputs) to High(Inputs) do
  begin
    Variable := Inputs[I];
    Outputs[I] := GetDouble(ExecuteScript(Script)^);
  end;
  Result := True;
end;

end.
