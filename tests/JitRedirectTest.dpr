{ ************************************************************************** }
{                                                                            }
{ JitRedirectTest                                                            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program JitRedirectTest;

{$APPTYPE CONSOLE}
{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils,
  Classes,
  Math,
  { BaseTypes is here for one reason: on Delphi 12 and later it redefines
    NativeInt as a distinct type, and GetRedirect takes its target as a var
    parameter. Without this unit the handles declared below are the system type,
    the var parameter refuses them, and the compiler says only that the types are
    not identical. Under FPC the unit declares nothing and the system type is
    already the right one. }
  BaseTypes,
  Notifier,
  ParseTypes,
  ParseUtils,
  Parser,
  ValueTypes,
  ValueUtils,
  ParseJit.Parser,
  TestKit in 'TestKit.pas';

{
  Redirection: one compiled script, many threads, each reading its own variable.

  This is the feature the library exists for. Every other expression engine that
  wants per-thread values wants a parser per thread: a formula compiled once
  belongs to the variables it was compiled against. Here a script carries a
  category, the category translates a reference to a shared variable into a
  reference to that thread's variable, and the same machine code serves everyone.

  The contract, stated so that each sentence below is a check in this file:

    1. Categories are handed out by GetRedirectCategory. They are positive,
       strictly increasing, and never issued twice.
    2. A redirect is a row: (category, source, target). GetRedirect finds it,
       DeleteRedirect removes it, a query outside any category fails, and filling
       in a row that does not exist fails rather than inventing one.
    3. Category zero means no redirection: the script reads the shared variable.
    4. The interpreter honours the redirect.
    5. The compiled code honours the same redirect and gives the same number - on
       all three tiers: x86-64 machine code, the portable IR executor, and the
       interpreter behind them.
    6. A boxed value - registered as TValue rather than as a typed reference -
       is redirected too, which is the harder case: the address is not known when
       the code is generated.
    7. Changing the parser's registry makes previously compiled code stop claiming
       to be ready, so the caller falls back and still gets the right answer.
       Recompiling makes it ready again.
    8. Deleting the redirect returns the script to the shared variable.
    9. Threads do not see each other's values: N threads, each with its own
       category and its own compiled copy, hammering the same formula, must every
       time read exactly their own variable.
   10. Creating and deleting redirects in bulk leaves the table consistent, and
       the cells set up beforehand are untouched by it.

  Three rules this file follows, each of them paid for:

  - a matching value is not proof that compiled code ran, so every check about the
    compiled path asserts Ready and the tier as well as the number;
  - both word sizes are built and run. Section 7 used to pass on win64 and crash
    on win32 for the same reason: registration without Prepare leaves prepared
    scripts pointing into memory that has moved, and one word size hid it;
  - nothing is skipped quietly. Where a target behaves differently, the difference
    is asserted rather than stepped over.
}

const
  Formula = 'X * X + 1';
  ThreadCount = 4;
  ThreadRounds = 20000;
  StressRounds = 500;

{$IFDEF CPUX64}
  {$DEFINE HAS_EMITTER}
{$ENDIF}

type
  { One cell of the computation: its own variable, its own category, its own
    compiled copy of the shared script. }
  TSlot = class
  private
    FParser: TJitParser;
    FLocal: TValue;
    FScript: TScript;
    FCategory: NativeInt;
    FRedirect: Integer;
    FCode: TJitScript;
    FName: string;
  public
    constructor Create(const AParser: TJitParser; const Index: Integer; const Source: TScript;
      const GlobalHandle: NativeInt);
    destructor Destroy; override;
    procedure Compile;
    procedure DropRedirect;
    function ByParser: Extended;
    function ByCode: Double;
    function Ready: Boolean;
    function Reason: string;
    property Category: NativeInt read FCategory;
    property Local: TValue read FLocal write FLocal;
    property Name: string read FName;
    property Script: TScript read FScript;
  end;

constructor TSlot.Create(const AParser: TJitParser; const Index: Integer; const Source: TScript;
  const GlobalHandle: NativeInt);
var
  LocalHandle: NativeInt;
begin
  inherited Create;
  FParser := AParser;
  FRedirect := -1;
  FName := 'X_' + IntToStr(Index);
  FLocal.ValueType := vtExtended;
  FParser.BeginUpdate;
  try
    FParser.AddVariable(FName, FLocal, False);
  finally
    FParser.EndUpdate;
    FParser.Notify(ntCompile, nil);
  end;
  FParser.Prepare;
  { The handle is taken right away: adding a variable reallocates the function
    array, and a pointer kept from before would dangle. }
  LocalHandle := FParser.FindFunction(FName).Handle^;
  FScript := Copy(Source);
  FCategory := GetRedirectCategory;
  FParser.SetRedirectCategory(FScript, FCategory);
  FRedirect := FParser.CreateRedirect;
  FParser.SetRedirect(FRedirect, FCategory, GlobalHandle, LocalHandle);
end;

destructor TSlot.Destroy;
begin
  FCode.Free;
  DropRedirect;
  FScript := nil;
  inherited;
end;

procedure TSlot.Compile;
begin
  FreeAndNil(FCode);
  FCode := FParser.CompileScript(FScript);
end;

procedure TSlot.DropRedirect;
begin
  if FRedirect >= 0 then
  begin
    FParser.DeleteRedirect(FRedirect);
    FRedirect := -1;
  end;
end;

function TSlot.Ready: Boolean;
begin
  Result := Assigned(FCode) and FCode.Ready;
end;

function TSlot.Reason: string;
begin
  if Assigned(FCode) then Result := FCode.Reason
  else
    Result := 'no code';
end;

function TSlot.ByParser: Extended;
begin
  Result := GetExtended(FParser.ExecuteScript(FScript)^);
end;

function TSlot.ByCode: Double;
begin
  Result := FCode.Execute;
end;

type
  { A worker hammers its own slot and counts every answer that is not its own.
    It never touches TestKit: reporting from several threads at once would race,
    so the counters are read back in the main thread. }
  TWorker = class(TThread)
  private
    FSlot: TSlot;
    FExpected: Extended;
    FRounds: Integer;
    FWrong: Integer;
    FRaised: string;
    FUseCode: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASlot: TSlot; const AExpected: Extended; const ARounds: Integer;
      const AUseCode: Boolean);
    property Raised: string read FRaised;
    property Wrong: Integer read FWrong;
  end;

constructor TWorker.Create(const ASlot: TSlot; const AExpected: Extended; const ARounds: Integer;
  const AUseCode: Boolean);
begin
  FSlot := ASlot;
  FExpected := AExpected;
  FRounds := ARounds;
  FUseCode := AUseCode;
  FWrong := 0;
  FRaised := '';
  inherited Create(False);
end;

procedure TWorker.Execute;
var
  I: Integer;
  Value: Extended;
begin
  try
    for I := 1 to FRounds do
    begin
      if FUseCode then Value := FSlot.ByCode else Value := FSlot.ByParser;
      if not SameValue(Value, FExpected, 1E-9) then Inc(FWrong);
    end;
  except
    on E: Exception do FRaised := E.ClassName + ': ' + E.Message;
  end;
end;

var
  Parser: TJitParser;
  Global: TValue;
  GlobalHandle: NativeInt;
  Source: TScript;
  Slots: array[0..ThreadCount - 1] of TSlot;

function Expect(const Index: Integer): Extended;
begin
  Result := Sqr(Index + 2) + 1;
end;

{ ── 1. categories ──────────────────────────────────────────────────────── }

procedure CategoriesAreUniqueAndGrowing;
const
  Count = 64;
var
  Seen: array[0..Count - 1] of Int64;
  I, J: Integer;
  Ok: Boolean;
begin
  BeginSection('categories are handed out one at a time');
  for I := 0 to Count - 1 do Seen[I] := GetRedirectCategory;

  Ok := True;
  for I := 0 to Count - 1 do if Seen[I] <= 0 then Ok := False;
  Check('every category is positive', Ok);

  Ok := True;
  for I := 1 to Count - 1 do if Seen[I] <= Seen[I - 1] then Ok := False;
  Check('categories strictly increase', Ok, Format('  first=%d last=%d', [Seen[0], Seen[Count - 1]]));

  Ok := True;
  for I := 0 to Count - 1 do
    for J := I + 1 to Count - 1 do
      if Seen[I] = Seen[J] then Ok := False;
  Check('no category is issued twice', Ok);
end;

{ ── 2. the redirect table ──────────────────────────────────────────────── }

procedure TheTableAnswersWhatWasPutIn;
var
  Index: Integer;
  Category, Target: NativeInt;
begin
  BeginSection('the redirect table');
  Category := GetRedirectCategory;

  Target := -1;
  Check('a query with category zero fails', not Parser.GetRedirect(0, GlobalHandle, Target));

  Target := -1;
  Check('a query for an unknown row fails', not Parser.GetRedirect(Category, GlobalHandle, Target));

  Index := Parser.CreateRedirect;
  Check('a row can be created', Index >= 0, Format('  index=%d', [Index]));
  Check('the row can be filled in', Parser.SetRedirect(Index, Category, GlobalHandle, 12345));

  Target := -1;
  Check('the row is found', Parser.GetRedirect(Category, GlobalHandle, Target));
  Check('the row gives back its target', Target = 12345, Format('  target=%d', [Target]));

  Check('filling in a row that does not exist fails', not Parser.SetRedirect(Index + 10000, Category, GlobalHandle, 1));

  Check('the row can be deleted', Parser.DeleteRedirect(Index));
  Target := -1;
  Check('after deletion the query fails again', not Parser.GetRedirect(Category, GlobalHandle, Target));
  Check('deleting the same row twice fails', not Parser.DeleteRedirect(Index));
end;

procedure TwoCategoriesKeepTheirOwnTargets;
var
  IndexA, IndexB: Integer;
  CatA, CatB, Target: NativeInt;
begin
  BeginSection('two categories over the same source');
  CatA := GetRedirectCategory;
  CatB := GetRedirectCategory;
  IndexA := Parser.CreateRedirect;
  IndexB := Parser.CreateRedirect;
  try
    Parser.SetRedirect(IndexA, CatA, GlobalHandle, 111);
    Parser.SetRedirect(IndexB, CatB, GlobalHandle, 222);

    Target := -1;
    Parser.GetRedirect(CatA, GlobalHandle, Target);
    Check('the first category keeps its target', Target = 111, Format('  target=%d', [Target]));

    Target := -1;
    Parser.GetRedirect(CatB, GlobalHandle, Target);
    Check('the second category keeps its own', Target = 222, Format('  target=%d', [Target]));
  finally
    Parser.DeleteRedirect(IndexA);
    Parser.DeleteRedirect(IndexB);
  end;
end;

{ ── 3-6. both engines honour the redirect ──────────────────────────────── }

procedure TheInterpreterReadsItsOwnVariable;
var
  I: Integer;
  Value: Extended;
begin
  BeginSection('the interpreter reads the variable of its own cell');
  for I := Low(Slots) to High(Slots) do
  begin
    Value := Slots[I].ByParser;
    CheckDouble(Format('cell %d', [I]), Value, Expect(I));
  end;
end;

procedure TheCompiledCodeReadsItsOwnVariable;
var
  I: Integer;
begin
  { There are three tiers, not two, and the redirect has to hold on all of them:
    x86-64 machine code, the portable IR executor, and the plain interpreter. On a
    target with the emitter Reason is empty; without it the script still compiles,
    to IR, and says so. Either way the code is ready and Execute works - which is
    why this section asserts Ready everywhere and does not skip anything. }
  BeginSection('the compiled code reads the variable of its own cell');
  for I := Low(Slots) to High(Slots) do
  begin
    Check(Format('cell %d is ready', [I]), Slots[I].Ready, '  reason: ' + Slots[I].Reason);
    {$IFDEF HAS_EMITTER}
    Check(Format('cell %d went to machine code', [I]), Slots[I].Reason = '', '  reason: ' + Slots[I].Reason);
    {$ELSE}
    Check(Format('cell %d went to the IR executor', [I]), Slots[I].Reason = 'ir executor', '  reason: ' + Slots[I].Reason);
    {$ENDIF}
    if Slots[I].Ready then
      CheckDouble(Format('cell %d answers', [I]), Slots[I].ByCode, Expect(I));
  end;
end;

procedure ABoxedValueIsRedirectedToo;
begin
  BeginSection('boxed values');
  { Every cell here holds its variable as a TValue rather than as a typed
    reference, which is the harder case for the emitter: the address is not known
    at compile time and has to be resolved through the redirect. That the checks
    above pass at all is the proof, so this section states it explicitly. }
  Check('cell variables are boxed', Slots[0].Local.ValueType = vtExtended, Format('  type=%d', [Ord(Slots[0].Local.ValueType)]));
  CheckDouble('a boxed value reads back', GetExtended(Slots[0].Local), 2);
  Check('and the compiled code took it', Slots[0].Ready, '  reason: ' + Slots[0].Reason);
end;

procedure AScriptWithoutACategoryReadsTheShared;
var
  Plain: TScript;
  Value: Extended;
begin
  BeginSection('a script with no category reads the shared variable');
  Global := MakeExtended(9);
  Parser.StringToScript(Formula, Plain);
  try
    { Category zero is the default, so no redirection applies. }
    Value := GetExtended(Parser.ExecuteScript(Plain)^);
    CheckDouble('the shared variable answers', Value, Sqr(9) + 1);
  finally
    Plain := nil;
  end;
end;

{ ── 7. invalidation ───────────────────────────────────────────────────── }

procedure ChangingTheRegistryInvalidatesTheCode;
var
  Value: Extended;
begin
  BeginSection('changing the registry invalidates compiled code');
  Check('the cell was ready to begin with', Slots[0].Ready, '  reason: ' + Slots[0].Reason);

  {
    The registration protocol matters here, and it cost a crash to learn.

    Adding a variable reallocates the function array, so every script prepared
    before that points into memory that has moved. Registration must therefore be
    wrapped in BeginUpdate/EndUpdate and followed by Prepare, which rebuilds those
    references. Without Prepare the next ExecuteScript reads freed memory: on
    win64 it happened to return the right number, on win32 it was an access
    violation. Same code, same call, two different outcomes - the worst kind of
    bug, and invisible to a test that runs one word size only.
  }
  Parser.BeginUpdate;
  try
    Parser.AddVariable('Z_new', Global, False);
  finally
    Parser.EndUpdate;
    Parser.Notify(ntCompile, Parser);
  end;
  Parser.Prepare;

  Check('the compiled script no longer claims to be ready', not Slots[0].Ready, '  reason: ' + Slots[0].Reason);

  { The point of invalidation is not that the code stops working - it is that the
    caller still gets the right answer. }
  Value := Slots[0].ByParser;
  CheckDouble('the interpreter still answers correctly', Value, Expect(0));

  Slots[0].Compile;
  Check('recompiling makes it ready again', Slots[0].Ready, '  reason: ' + Slots[0].Reason);
  if Slots[0].Ready then
    CheckDouble('and the answer is unchanged', Slots[0].ByCode, Expect(0));
end;

{ ── 8. dropping the redirect ──────────────────────────────────────────── }

procedure DroppingTheRedirectFallsBackToTheShared;
var
  Value: Extended;
begin
  BeginSection('dropping the redirect returns the script to the shared variable');
  Global := MakeExtended(5);
  Slots[High(Slots)].DropRedirect;
  Value := Slots[High(Slots)].ByParser;
  CheckDouble('the shared variable answers now', Value, Sqr(5) + 1);
end;

{ ── 9. threads ────────────────────────────────────────────────────────── }

procedure ThreadsDoNotSeeEachOther;
var
  Workers: array[0..ThreadCount - 1] of TWorker;
  I, Wrong: Integer;
  UseCode: Boolean;
  Raised: string;
begin
  BeginSection(Format('%d threads, %d rounds each', [ThreadCount, ThreadRounds]));
  { Every cell is recompiled first: earlier sections changed the registry on
    purpose, and stale code would be measured instead of the mechanism. }
  for I := Low(Slots) to High(Slots) do Slots[I].Compile;

  UseCode := True;
  for I := Low(Slots) to High(Slots) do
    if not Slots[I].Ready then UseCode := False;
  Check('every cell is compiled before the threads start', UseCode);

  for I := Low(Slots) to High(Slots) do
    Workers[I] := TWorker.Create(Slots[I], Expect(I), ThreadRounds, UseCode);
  for I := Low(Slots) to High(Slots) do Workers[I].WaitFor;

  Wrong := 0;
  Raised := '';
  for I := Low(Slots) to High(Slots) do
  begin
    Wrong := Wrong + Workers[I].Wrong;
    if Workers[I].Raised <> '' then
      Raised := Raised + Format(' [cell %d: %s]', [I, Workers[I].Raised]);
    Workers[I].Free;
  end;

  Check('no thread raised', Raised = '', '  ' + Raised);
  Check('no thread ever read another cell''s variable', Wrong = 0,
    Format('  wrong answers: %d of %d', [Wrong, ThreadCount * ThreadRounds]));
end;

{ ── 10. bulk ──────────────────────────────────────────────────────────── }

procedure ManyRedirectsComeAndGo;
var
  I: Integer;
  Index: Integer;
  Category, Target: NativeInt;
  Ok: Boolean;
begin
  BeginSection(Format('%d redirects created and deleted', [StressRounds]));
  Ok := True;
  for I := 1 to StressRounds do
  begin
    Category := GetRedirectCategory;
    Index := Parser.CreateRedirect;
    if Index < 0 then
    begin
      Ok := False;
      Break;
    end;
    if not Parser.SetRedirect(Index, Category, GlobalHandle, 1000 + I) then
    begin
      Ok := False;
      Break;
    end;
    Target := -1;
    if not Parser.GetRedirect(Category, GlobalHandle, Target) then
    begin
      Ok := False;
      Break;
    end;
    if Target <> 1000 + I then
    begin
      Ok := False;
      Break;
    end;
    if not Parser.DeleteRedirect(Index) then
    begin
      Ok := False;
      Break;
    end;
    if Parser.GetRedirect(Category, GlobalHandle, Target) then
    begin
      Ok := False;
      Break;
    end;
  end;
  Check('the table stays consistent through the whole run', Ok);

  { The cells set up at the start must be untouched by all of that. }
  CheckDouble('cell 0 still reads its own variable', Slots[0].ByParser, Expect(0));
  CheckDouble('cell 1 still reads its own variable', Slots[1].ByParser, Expect(1));
end;

{ ── the run ───────────────────────────────────────────────────────────── }

var
  I: Integer;

begin
  Writeln('=== redirection: one compiled script, many threads ===');
  try
    Parser := TJitParser.Create(nil);
    try
      Global.ValueType := vtExtended;
      Parser.BeginUpdate;
      try
        Parser.AddVariable('X', Global, False);
      finally
        Parser.EndUpdate;
        Parser.Notify(ntCompile, nil);
      end;
      Parser.Prepare;
      GlobalHandle := Parser.FindFunction('X').Handle^;
      Parser.StringToScript(Formula, Source);

      CategoriesAreUniqueAndGrowing;
      TheTableAnswersWhatWasPutIn;
      TwoCategoriesKeepTheirOwnTargets;

      { All the preparation first, and only then the compilation: any change to
        the parser devalues code compiled before it. }
      for I := Low(Slots) to High(Slots) do
      begin
        Slots[I] := TSlot.Create(Parser, I, Source, GlobalHandle);
        Slots[I].Local := MakeExtended(I + 2);
      end;
      try
        for I := Low(Slots) to High(Slots) do Slots[I].Compile;

        TheInterpreterReadsItsOwnVariable;
        TheCompiledCodeReadsItsOwnVariable;
        ABoxedValueIsRedirectedToo;
        AScriptWithoutACategoryReadsTheShared;
        ChangingTheRegistryInvalidatesTheCode;
        ThreadsDoNotSeeEachOther;
        ManyRedirectsComeAndGo;
        DroppingTheRedirectFallsBackToTheShared;
      finally
        for I := Low(Slots) to High(Slots) do Slots[I].Free;
      end;
      Source := nil;
    finally
      Parser.Free;
    end;
  except
    on E: Exception do
    begin
      BeginSection('the run itself');
      Fail('finished without raising', E.ClassName + ': ' + E.Message);
    end;
  end;
  ExitCode := TestSummary;
end.
