{ ************************************************************************** }
{                                                                            }
{ ParserBugTests                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program ParserBugTests;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  {$IFDEF FPC}Interfaces,{$ENDIF}
  SysUtils,
  Classes,
  Math,
  BaseTypes,
  Parser,
  ParseTypes,
  TextTypes,
  ValueTypes,
  ValueConsts,
  ValueUtils,
  Calculator,
  BlobManager,
  FastList,
  ParseManager,
  EventUtils,
  Forms,
  TestKit in 'TestKit.pas';

type
  TExceptionSpy = class
    procedure Handle(Sender: TObject; E: Exception);
  end;

procedure TExceptionSpy.Handle(Sender: TObject; E: Exception);
begin
  Writeln('[worker exception] ', E.ClassName, ': ', E.Message);
  Flush(Output);
end;

var
  Spy: TExceptionSpy;

var
  MathParser: TMathParser;
  DoubleVar: Double;
  StackWaste: NativeInt;

procedure CheckFormula(const Name, Formula: string; const Expected: Double; const Epsilon: Double = 1E-9);
begin
  try
    CheckDouble(Name, MathParser.AsDouble(Formula), Expected, Epsilon);
  except
    on E: Exception do Fail(Name, E.ClassName + ': ' + E.Message);
  end;
end;

procedure CheckFormulaFails(const Name, Formula: string);
begin
  try
    MathParser.AsDouble(Formula);
    Fail(Name, 'no exception raised');
  except
    Check(Name, True);
  end;
end;

procedure DirtyStack;
var
  Buffer: array[0..255] of NativeInt;
  I: Integer;
begin
  for I := Low(Buffer) to High(Buffer) do Buffer[I] := NativeInt($55AA55AA);
  StackWaste := Buffer[High(Buffer)];
end;

procedure TestSmoke;
begin
  BeginSection('Smoke (must stay green)');
  CheckFormula('smoke: 2 + 2 * 2', '2 + 2 * 2', 6);
  CheckFormula('smoke: sum of terms with signs', '10 - 2 - 3', 5);
  CheckFormula('smoke: sin(0)', 'sin(0)', 0);
  CheckFormula('smoke: 2 ** 10', '2 ** 10', 1024);
  CheckFormula('smoke: lazy if takes one branch', 'if(1, 2 + 3, 9)', 5);
  CheckFormula('smoke: comparison is -1/0', '1 + 2 > 2', -1);
  CheckFormula('smoke: parentheses', '(2 + 4) / 3', 2);
  CheckFormula('smoke: degree binds tighter', '2 * 3 degree 2', 18);
end;

procedure TestWaveA;
var
  Value, ResultValue: TValue;
begin
  BeginSection('Wave A: math correctness');
  DoubleVar := 5.7;
  CheckFormula('A#1 bitwise and, Double lhs', 'dv && 7', 6);
  MathParser.BooleanMode := bmComplete;
  try
    CheckFormula('A#1 bitwise or, Double lhs (bmComplete)', 'dv or 0', 6);
  finally
    MathParser.BooleanMode := bmShortCircuit;
  end;
  CheckFormula('A#1 bitwise xor, Double lhs', 'dv xor 0', 6);
  CheckFormula('A#1 bitwise shl, Double lhs', 'dv shl 0', 6);
  CheckFormula('A#1 bitwise shr, Double lhs', 'dv shr 0', 6);
  CheckFormula('A#2 root: 8 // 3 is cube root', '8 // 3', 2);
  CheckFormula('A#2 root: 16 // 4', '16 // 4', 2);
  CheckFormula('A#3 poly(2, 1, 2, 3) = 1+2*2+3*4', 'poly(2, 1, 2, 3)', 17);
  CheckFormula('A#4 sqrt keeps fractional argument', 'sqrt(2.25)', 1.5);
  CheckFormula('A#4 sqr keeps fractional argument', 'sqr(1.5)', 2.25);
  Value := EmptyValue;
  Value.ValueType := vtUnknown;
  DirtyStack;
  ResultValue := Negative(Value);
  Check('A#7 Negative(vtUnknown) is EmptyValue, not stack garbage', CompareMem(@ResultValue, @EmptyValue, SizeOf(TValue)));
  DirtyStack;
  ResultValue := Positive(Value);
  Check('A#7 Positive(vtUnknown) is EmptyValue, not stack garbage', CompareMem(@ResultValue, @EmptyValue, SizeOf(TValue)));
  CheckFormula('A#28 strtodatetime with date and time', 'hourof(strtodatetime("01.02.2020 10:30"))', 10);
  { the reference comes from the formula: the library ArcSecH on FPC is
    noticeably less precise }
  CheckFormula('A#25 arcsech works under correct name', 'arcsech(0.5)', Ln((1 + Sqrt(1 - 0.25)) / 0.5), 1E-9);
  CheckFormulaFails('A#25 misspelled srcsech is gone', 'srcsech(0.5)');
end;

procedure TestWaveB;
var
  Value: TValue;
  P: Pointer;
begin
  BeginSection('Wave B: x64 correctness');
  DirtyStack;
  AssignInt64(Value, -5);
  Check('B#5 GetNativeInt(-5) = -5', GetNativeInt(Value) = -5, IntToStr(GetNativeInt(Value)));
  DirtyStack;
  AssignInt64(Value, -1);
  Check('B#5 GetNativeUInt(-1) wraps to all ones', GetNativeUInt(Value) = NativeUInt(-1), UIntToStr(GetNativeUInt(Value)));
  {$IFDEF CPUX64}
  P := Pointer($100000001);
  {$ELSE}
  P := Pointer($F0000001);
  {$ENDIF}
  DirtyStack;
  AssignPointer(Value, P);
  Check('B#6 AssignPointer keeps full pointer width', Pointer(GetNativeUInt(Value)) = P, UIntToStr(GetNativeUInt(Value)));
  CheckFormula('B#20 MaxInteger is Int32 bound', 'MaxInteger', 2147483647);
  CheckFormula('B#20 MinInteger is Int32 bound', 'MinInteger', -2147483648);
  CheckFormula('B#20 MaxNativeInt is platform bound', 'MaxNativeInt', Double(High(NativeInt)));
  CheckFormula('B#20 MinNativeInt is platform bound', 'MinNativeInt', Double(Low(NativeInt)));
end;

procedure TestWaveC;
var
  Calc: TCalculator;
  Caught: Boolean;
  BM, BM2: TBlobManager;
  P: BlobManager.PItem;
  MS: TMemoryStream;
  SIn, SOut: string;
  FL: TFastList;
  I, L, Hits: Integer;
  GuardS: record S: TString; Pad: array[0..511] of Char;
end;
  GuardT: record T: TType; Pad: array[0..511] of Char;
end;
  Handle: NativeInt;
  B: PByte;
  Off: NativeInt;
begin
  BeginSection('Wave C: silent data loss');
  { the C#9 runtime test lives in TestPoolEarly: WaitFor fails while pumping
    messages AFTER the whole wave of tests has run (C31, still open), and works
    in a clean context }
  Check('C#26 TString capacity raised to 4096', StringLength = 4096, IntToStr(StringLength));
  SIn := StringOfChar('m', StringLength + 50);
  FillChar(GuardS, SizeOf(GuardS), 0);
  GuardS.S := MakeString(SIn);
  Check('C#13 MakeString truncates at capacity', StrLen(PChar(@GuardS.S)) = StringLength - 1, IntToStr(StrLen(PChar(@GuardS.S))));
  Check('C#13 MakeString does not overflow', GuardS.Pad[0] = #0);
  FillChar(GuardT, SizeOf(GuardT), 0);
  GuardT.T := MakeType(SIn, Handle, vtInteger);
  Check('C#13 MakeType truncates at capacity', StrLen(PChar(@GuardT.T.Name)) = StringLength - 1, IntToStr(StrLen(PChar(@GuardT.T.Name))));
  Check('C#13 MakeType does not overflow', GuardT.Pad[0] = #0);
  FL := TFastList.Create;
  try
    FL.CaseSensitive := True;
    for I := 0 to 4999 do FL.Add('probe' + IntToStr(I) + 'x');
    Hits := 0;
    for I := 0 to 4999 do
      if FL.IndexOf('PROBE' + IntToStr(I) + 'X') >= 0 then Inc(Hits);
    Check('C#23 case-sensitive lookup rejects case variants', Hits = 0, IntToStr(Hits) + ' false hits');
  finally
    FL.Free;
  end;
  BM := TBlobManager.Create(nil);
  MS := TMemoryStream.Create;
  try
    SIn := 'blob' + Chr($0416) + Chr($4E2D) + StringOfChar('x', 3000);
    Check('C#22 ImportText returns index', BM.ImportText('cordata', SIn) >= 0);
    P := BM.Find('cordata');
    Check('C#22 Find locates item', Assigned(P));
    if Assigned(P) then
    begin
      SOut := BM.Text[P^];
      Check('C#22 GetText round-trip', SOut = SIn, 'len=' + IntToStr(Length(SOut)));
      BM.Text[P^] := SIn + 'tail';
      Check('C#22 SetText/GetText round-trip', BM.Text[P^] = SIn + 'tail');
    end;
    BM.Save(MS);
    MS.Position := 0;
    BM2 := TBlobManager.Create(nil);
    try
      Check('C#22 blob reopen', BM2.Open(MS));
      P := BM2.Find('cordata');
      Check('C#22 text survives save/open', Assigned(P) and (BM2.Text[P^] = SIn + 'tail'));
    finally
      BM2.Free;
    end;
    Off := -1;
    B := MS.Memory;
    for I := 0 to MS.Size - 15 do
      if (PChar(B + I)^ = 'c') and (PChar(B + I + SizeOf(Char))^ = 'o') and (PChar(B + I + 2 * SizeOf(Char))^ = 'r') and
        (PChar(B + I + 3 * SizeOf(Char))^ = 'd') and (PChar(B + I + 4 * SizeOf(Char))^ = 'a') then
        begin
          Off := I;
          Break;
        end;
    Check('C#22 corrupt test found name offset', Off >= 8, IntToStr(Off));
    if Off >= 8 then
    begin
      PInt64(B + Off - 8)^ := SizeOf(TString) + 64;
      MS.Position := 0;
      BM2 := TBlobManager.Create(nil);
      try
        try
          Caught := not BM2.Open(MS);
        except
          Caught := True;
        end;
        Check('C#22 oversized name length is rejected', Caught);
      finally
        BM2.Free;
      end;
    end;
  finally
    MS.Free;
    BM.Free;
  end;
end;

var
  XVar: Double;

procedure TestWaveD;
var
  M, M2: TParseManager;
  FN: string;
begin
  BeginSection('Wave D: manager and files');
  MathParser.AddVariable('xv', XVar);
  XVar := 4;
  M := TParseManager.Create(nil);
  M2 := TParseManager.Create(nil);
  try
    M.Parser := MathParser;
    M2.Parser := MathParser;
    try
      M.AssignValue('xv + 1', 'zzz');
      Check('D#10 AssignValue keeps expression text', (M.Count = 1) and (M.List[0] = 'xv + 1'), '"' + M.List[0] + '"');
      CheckDouble('D#10 stored expression computes', GetDouble(M.AsValue(0)), 5);
      FN := ExtractFilePath(ParamStr(0)) + 'd10.tmp';
      M.SaveToFile(FN);
      try
        XVar := 40;
        Check('D#11 LoadFromFile succeeds', M2.LoadFromFile(FN));
        Check('D#10 expression text survives round-trip', (M2.Count = 1) and (M2.List[0] = 'xv + 1'),
          '"' + M2.List[0] + '"');
        CheckDouble('D#10 loaded value is the saved constant', GetDouble(M2.AsValue(0)), 5);
      finally
        XVar := 4;
        DeleteFile(FN);
      end;
    except
      on E: Exception do Fail('D#10 AssignValue scenario', E.ClassName + ': ' + E.Message);
    end;
  finally
    M2.Free;
    M.Free;
  end;
end;

procedure TestWaveF;
var
  RI: Integer;
  Target: NativeInt;
  ED: TEventData;
  Ev: TEvent;
  H1, H2: NativeInt;
begin
  BeginSection('Wave F: core details');
  RI := MathParser.CreateRedirect;
  try
    Check('F#8 SetRedirect', MathParser.SetRedirect(RI, 7, 12345, 777));
    Target := 0;
    Check('F#8 wrong category is not matched', not MathParser.GetRedirect(3, 12345, Target), 'target=' + IntToStr(Target));
    Check('F#8 right category is matched', MathParser.GetRedirect(7, 12345, Target) and (Target = 777),
      'target=' + IntToStr(Target));
  finally
    MathParser.DeleteRedirect(RI);
  end;
  ED := Default(TEventData);
  Ev := MakeEvent(H1, 'e1', 1, nil);
  AddEvent(ED, Ev);
  Ev := MakeEvent(H2, 'e2', 2, nil);
  AddEvent(ED, Ev);
  ED.Flag := False;
  Check('F#17 DeleteEvent raises dirty flag', DeleteEvent(ED, 0) and ED.Flag);
end;

procedure TestWaveG;
var
  SavedGlobal: Char;
begin
  BeginSection('Wave G: decisions');
  { G#29, the new contract: the library has no business changing the decimal
    separator of the whole process. Set the global one to a comma (as a locale
    would) and make sure the parser still reads a dot while the global stays
    untouched. The parser used to force a dot process-wide, which was the defect. }
  SavedGlobal := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := ',';
    CheckFormula('G#29 parser reads dot under a comma-locale process', '1.5 + 1.5', 3);
    Check('G#29 parser leaves the process separator alone', FormatSettings.DecimalSeparator = ',');
  finally
    FormatSettings.DecimalSeparator := SavedGlobal;
  end;
  CheckFormula('G#29 parser still reads dot literals', '1.5 + 1.5', 3);
  CheckFormula('G#18 registry alive without license unit', 'sin(0) + 2', 2);
end;

procedure TestWaveGSpecs;
begin
  BeginSection('Wave G: revived entities and priorities');
  CheckFormula('G-C1 exit terminates whole script', 'exit(99) + 200', 99);
  CheckFormula('G-C1 exit breaks while', 'while(1, exit(7))', 7);
  CheckFormula('G-C1 exit inside if branch', 'if(1, exit(3), 0) + 100', 3);
  CheckFormula('G-C1 tryexcept does not swallow exit', 'tryexcept(exit(7), 555)', 7);
  { C32: a short-circuit or in While/Repeat/For skipped the body after the first true }
  { new = -1 (true), the loop returns the OR of the bodies = 1 (Boolean8),
    get = the counter }
  CheckFormula('C32 while counter advances', 'new("wc", 0) + while(get("wc") < 5, set("wc", get("wc") + 1)) + get("wc")', 5);
  CheckFormula('C32 repeat counter advances', 'new("rc", 0) + repeat(set("rc", get("rc") + 1), get("rc") >= 3) + get("rc")', 3);
  CheckFormula('G-C1 exit breaks counting while',
    'new("ec", 0) + while(get("ec") < 100000, if(get("ec") > 4, exit(get("ec")), set("ec", get("ec") + 1)))', 5);
  Check('G-C2 BitwiseXorHandle is live', MathParser.BitwiseXorHandle >= 0, IntToStr(MathParser.BitwiseXorHandle));
  CheckFormula('G-C2 bxor works', 'dv bxor 0', 6);
  CheckFormula('G-C3 || synonym works', 'dv || 0', 6);
  CheckFormula('G-C4 power binds tighter than mul', '2 * 3 ** 2', 18);
  CheckFormula('G-C4 root binds tighter than mul', '2 * 8 // 3', 4);
  try
    Writeln('INFO chain: 2 degree 3 degree 2 = ', MathParser.AsDouble('2 degree 3 degree 2'):0:0, '; 2 ** 3 ** 2 = ',
      MathParser.AsDouble('2 ** 3 ** 2'):0:0);
  except
    on E: Exception do Writeln('INFO chain measure failed: ', E.Message);
  end;
end;

procedure TestLayout;
begin
  BeginSection('Layout: binary script format');
  { The script lives in one continuous byte array, and a value is written into
    it at an offset that is a multiple of 8. If TValue were aligned to 16 the
    compiler would use an aligned SSE move for the copy and fault at such an
    offset - which is exactly what happened on FPC/Linux, where Extended is 10
    bytes. The cure is the PACKRECORDS 8 directive in ValueTypes.pas.

    The size is pinned here because it also defines the format of a saved
    script: losing the directive has to fail a test rather than corrupt memory. }
  Check('layout SizeOf(TValue) = 24', SizeOf(TValue) = 24, IntToStr(SizeOf(TValue)));
  Check('layout SizeOf(TScriptNumber) = 24', SizeOf(TScriptNumber) = 24, IntToStr(SizeOf(TScriptNumber)));
  Check('layout TValue fits TScriptNumber', SizeOf(TScriptNumber) >= SizeOf(TValue),
    IntToStr(SizeOf(TScriptNumber)) + ' vs ' + IntToStr(SizeOf(TValue)));
end;

procedure TestPoolEarly;
var
  Calc: TCalculator;
  Caught: Boolean;
  SIn: string;
  I: Integer;
begin
  BeginSection('Pool (early, clean context)');
  Spy := TExceptionSpy.Create;
  Application.OnException := Spy.Handle;
  Calc := TCalculator.Create(nil);
  try
    SIn := '1';
    for I := 1 to 400 do SIn := SIn + ' + sin(1)';
    { no warm-up: this checks that the race in Prepare is closed by the lock (C31) }
    for I := 1 to 200 do Calc.Thread.AddText(SIn);
    Calc.Thread.ThreadCount := 2;
    if Calc.Thread.Execute then
    begin
      Caught := False;
      try
        Calc.AsValue('2 + 2');
      except
        on ECalculatorError do Caught := True;
      end;
      Check('C#9 AsValue raises while pool is busy', Caught);
      Calc.Thread.WaitFor;
      Check('C#9 pool completed all items', Calc.Thread.ItemCount = 200, IntToStr(Calc.Thread.ItemCount));
      Calc.Thread.Clear;
    end
    else
      Fail('C#9 AsValue raises while pool is busy', 'pool did not start');
    CheckDouble('C#9 AsValue works after pool finish', GetDouble(Calc.AsValue('2 + 2')), 4);
  finally
    Calc.Free;
  end;
end;

var
  Failed: Integer;

begin
  {$IFDEF FPC}
  { on FPC the Synchronize queue is pumped by the widgetset: without initialising
    it the pool threads never report that they are done }
  Application.Initialize;
  {$ENDIF}
  { the layout is checked first: with TValue misaligned, parsing faults outright
    and a check at the end of the list would never reach the output }
  TestLayout;
  MathParser := TMathParser.Create(nil);
  try
    MathParser.AddVariable('dv', DoubleVar);
    TestPoolEarly;
    TestSmoke;
    TestWaveA;
    TestWaveB;
    TestWaveC;
    TestWaveD;
    TestWaveF;
    TestWaveG;
    TestWaveGSpecs;
    Writeln;
    Writeln('INFO SizeOf(TFunction)=', SizeOf(TFunction), ' bytes; ~220 registrations = ', 220 * SizeOf(TFunction) div 1024,
      ' KB per TMathParser');
    Failed := TestSummary;
  finally
    MathParser.Free;
  end;
  if Failed > 0 then
    System.ExitCode := 1;
end.
