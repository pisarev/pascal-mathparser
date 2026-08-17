{ ************************************************************************** }
{                                                                            }
{ ExitRoutingTest                                                            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ExitRoutingTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ParseErrors, ValueTypes, ValueUtils, TestKit in 'TestKit.pas';

{
  What this file guards: an Exit reaches the evaluation it belongs to, and no
  other one takes it on the way.

  A formula can call out to a second parser, and that parser's formula can call
  back into the first. The frame chain of one thread then reads A, B, A, and an
  Exit raised in the innermost A has to travel past B untouched.

  Version 1.0.2 asked one question in the handler - "is there another frame of
  MY parser below me?" - and for the middle B the answer was no. B therefore
  took itself for the root, swallowed an Exit addressed to A and returned its
  value as its own. The outer A never saw it and quietly finished a different
  sum: 49 where 42 was due.

  The exception now carries its owner, so the handler asks two questions: is
  this exception mine, and am I the outermost evaluation of my parser. The
  second alone was never enough, and the second is now asked only when an
  exception actually shows up rather than on every evaluation.

  E2, E3 and E5 must FAIL before that fix. The rest guard behaviour that was
  already right and must survive it.

  To watch them fail, build this file against a 1.0.2 checkout with the one
  line naming OwnerParser commented out - that property arrived with the fix.
  The measurement is kept as out/win64/RED-routing-on-1.0.2.log: seven
  failures of thirty-one, E2 answering 49 where 42 was due, E3 answering 1049
  and E5 answering 49.
}

type
  { Three parsers and the hops between them. The entered and returned flags
    matter as much as the number the outer formula ends with: an answer can
    come out right by luck, but a return from the middle of the chain is
    evidence that the middle parser took an exception addressed elsewhere. }
  THop = class
  private
    FA, FB, FC: TMathParser;
    FNestedA, FScriptB, FScriptC: TScript;
    FEnteredB, FReturnedB: Boolean;
    FEnteredC, FReturnedC: Boolean;
    FValueB, FValueC: Double;
    FNoteB, FNoteC: string;
    FLegacyValue: TValue;
    procedure Reset;
  public
    function ToB(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function ToC(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function BackToA(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function LegacyExit(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function RecurseA(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

  { A reentrant evaluation with SEPARATE storage: this one is allowed, and it
    is the only way back into an evaluation that is. }
  TAgain = class
  private
    FParser: TMathParser;
    FNested: TScript;
    FDepth: Integer;
    FNestedValue: Double;
  public
    function Again(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

var
  Hop: THop;
  Ag: TAgain;
  HandleToB, HandleToC, HandleBack, HandleLegacy, HandleRecurse, HandleAgain: TFunctionHandle;

procedure THop.Reset;
begin
  FEnteredB := False;
  FReturnedB := False;
  FEnteredC := False;
  FReturnedC := False;
  FValueB := 0;
  FValueC := 0;
  FNoteB := '';
  FNoteC := '';
end;

function THop.ToB(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  {
    The exception is deliberately NOT caught here. Catching it ourselves would
    leave the check watching our own handling instead of the parser. The
    returned flag is raised only on a normal finish, so its value answers the
    question of whether B took what was not its own.
  }
  FEnteredB := True;
  FValueB := GetDouble(FB.ExecuteScript(FScriptB)^);
  FReturnedB := True;
  Result := MakeDouble(FValueB);
end;

function THop.ToC(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  FEnteredC := True;
  FValueC := GetDouble(FC.ExecuteScript(FScriptC)^);
  FReturnedC := True;
  Result := MakeDouble(FValueC);
end;

function THop.BackToA(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Result := MakeDouble(GetDouble(FA.ExecuteScript(FNestedA)^));
end;

function THop.LegacyExit(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  { The legacy overload, with no owner named: it has to take one from the top
    of the frame chain by itself. }
  raise EParserExit.Create(FLegacyValue);
end;

function THop.RecurseA(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Result := MakeDouble(GetDouble(FA.ExecuteScript(FNestedA)^));
end;

function TAgain.Again(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Inc(FDepth);
  try
    if FDepth = 1 then FNestedValue := GetDouble(FParser.ExecuteScript(FNested)^);
  finally
    Dec(FDepth);
  end;
  Result := MakeDouble(1);
end;

function Run(const P: TMathParser; const S: TScript; out Note: string): Double;
begin
  Note := '';
  Result := 0;
  try
    Result := GetDouble(P.ExecuteScript(S)^);
  except
    on E: Exception do Note := E.ClassName + ': ' + E.Message;
  end;
end;

{ E1 }

{ Plain recursion into one parser with separate storage. This was already
  right before the fix: the check guards that dropping the SameParserParent
  field did not break it. }
procedure E1_PlainRecursion;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('E1: recursion into one parser');
  Hop.Reset;
  Root := nil;
  Hop.FNestedA := nil;
  Hop.FA.StringToScript('Exit(42)', Hop.FNestedA);
  Hop.FA.StringToScript('recursea(0) + 7', Root);
  Got := Run(Hop.FA, Root, Note);
  Check('nothing escaped', Note = '', Note);
  CheckDouble('the root got the value of the nested Exit', Got, 42);
end;

{ E2 }

{
  The check the fix is about: A -> B -> A. The exception raised by the inner A
  unwinds through the frame of a parser that has nothing to do with it.

  Before the fix B took itself for the root, took the value and returned
  normally, so the root A finished 42 + 7 and answered 49.
}
procedure E2_ThroughForeignParser;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('E2: the chain A - B - A');
  Hop.Reset;
  Root := nil;
  Hop.FNestedA := nil;
  Hop.FScriptB := nil;
  Hop.FA.StringToScript('Exit(42)', Hop.FNestedA);
  Hop.FB.StringToScript('backtoa(0) + 1000', Hop.FScriptB);
  Hop.FA.StringToScript('tob(0) + 7', Root);
  Got := Run(Hop.FA, Root, Note);
  Check('nothing escaped', Note = '', Note);
  Check('the parser in the middle was called', Hop.FEnteredB, 'B was never entered');
  Check('the parser in the middle did not take somebody else''s Exit', not Hop.FReturnedB,
    Format('B returned with %g', [Hop.FValueB]));
  CheckDouble('the root got the value of its own Exit', Got, 42);
end;

{ E3 }

{ The same thing with two foreign parsers between the root and the Exit.
  Shows that the fix does not depend on the length of the chain. }
procedure E3_TwoForeignParsers;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('E3: the chain A - B - C - A');
  Hop.Reset;
  Root := nil;
  Hop.FNestedA := nil;
  Hop.FScriptB := nil;
  Hop.FScriptC := nil;
  Hop.FA.StringToScript('Exit(42)', Hop.FNestedA);
  Hop.FC.StringToScript('backtoa(0) + 100', Hop.FScriptC);
  Hop.FB.StringToScript('toc(0) + 1000', Hop.FScriptB);
  Hop.FA.StringToScript('tob(0) + 7', Root);
  Got := Run(Hop.FA, Root, Note);
  Check('nothing escaped', Note = '', Note);
  Check('both parsers in the middle were called', Hop.FEnteredB and Hop.FEnteredC, 'C was never reached');
  Check('C did not take somebody else''s Exit', not Hop.FReturnedC,
    Format('C returned with %g', [Hop.FValueC]));
  Check('B did not take somebody else''s Exit', not Hop.FReturnedB,
    Format('B returned with %g', [Hop.FValueB]));
  CheckDouble('the root got the value of its own Exit', Got, 42);
end;

{ E4 }

{ The other way round: the Exit belongs to the middle B. B is the root of its
  own evaluation and has to take it, while the outer A finishes its own sum.
  This guards the owner test from the opposite side: were the filter to let
  everything through, the Exit would fly out to A. }
procedure E4_MiddleParserOwnsItsExit;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('E4: the Exit belongs to the parser in the middle');
  Hop.Reset;
  Root := nil;
  Hop.FScriptB := nil;
  Hop.FB.StringToScript('Exit(42) + 1000', Hop.FScriptB);
  Hop.FA.StringToScript('tob(0) + 7', Root);
  Got := Run(Hop.FA, Root, Note);
  Check('nothing escaped', Note = '', Note);
  Check('the middle one returned normally', Hop.FReturnedB, 'B did not return');
  CheckDouble('the middle one took ITS OWN Exit', Hop.FValueB, 42);
  CheckDouble('the outer one finished its own sum', Got, 49);
end;

{ E5 }

{ The legacy constructor in the same A - B - A chain. It takes its owner from
  the top of the frame chain, so the route has to be the one the built-in Exit
  takes. }
procedure E5_LegacyConstructorInChain;
var
  Root: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('E5: the legacy constructor inside the chain');
  Hop.Reset;
  Root := nil;
  Hop.FNestedA := nil;
  Hop.FScriptB := nil;
  AssignDouble(Hop.FLegacyValue, 42);
  Hop.FA.StringToScript('legacyexit(0)', Hop.FNestedA);
  Hop.FB.StringToScript('backtoa(0) + 1000', Hop.FScriptB);
  Hop.FA.StringToScript('tob(0) + 7', Root);
  Got := Run(Hop.FA, Root, Note);
  Check('nothing escaped', Note = '', Note);
  Check('the middle one did not take somebody else''s Exit', not Hop.FReturnedB,
    Format('B returned with %g', [Hop.FValueB]));
  CheckDouble('the root got the value', Got, 42);
end;

{ E6 }

{ The same legacy constructor, but outside any evaluation. There is no owner
  to take, and no root may swallow such an exception: a plain refusal beats a
  plausible wrong number. }
procedure E6_LegacyConstructorOutsideEvaluation;
var
  Note: string;
  Value: TValue;
  Got: Double;
begin
  BeginSection('E6: the legacy constructor outside an evaluation');
  Note := '';
  Got := 0;
  AssignDouble(Value, 42);
  try
    raise EParserExit.Create(Value);
  except
    on E: EParserExit do
    begin
      Note := 'caught outside';
      Got := GetDouble(E.Value);
      Check('no owner was assigned', not Assigned(E.OwnerParser),
        'an exception raised outside an evaluation has an owner');
    end;
  end;
  Check('the exception reached the caller', Note = 'caught outside', Note);
  CheckDouble('and carried its value', Got, 42);
end;

{ E8 }

{ The reentrancy that is allowed: one parser, one thread, but SEPARATE script
  storage. That is what the documentation prescribes, and it has to work. }
procedure E8_ReentrantWithSeparateBuffers;
var
  Outer: TScript;
  Note: string;
  Got: Double;
begin
  BeginSection('E8: a reentrant evaluation with storage of its own');
  Outer := nil;
  Ag.FNested := nil;
  Ag.FDepth := 0;
  Ag.FNestedValue := 0;
  Ag.FParser.StringToScript('100 + 100 + 100 + again(0)', Outer);
  Ag.FNested := Copy(Outer);
  Got := Run(Ag.FParser, Outer, Note);
  Check('nothing escaped', Note = '', Note);
  CheckDouble('the nested evaluation is right', Ag.FNestedValue, 301);
  CheckDouble('the outer evaluation was not spoiled by the nested one', Got, 301);
end;

{ E9 }

{ The formula-level try repeats the semantics of Pascal, and that is on
  purpose. An exception from the finaliser replaces the one being unwound; an
  ordinary finaliser does not suppress the original Exit; the formula-level
  except never reaches it. }
procedure E9_TryExceptAndTryFinally;
var
  P: TMathParser;
  S: TScript;
  Note: string;

  procedure One(const Text: string; const Want: Double; const Name: string);
  var
    Got: Double;
  begin
    S := nil;
    P.StringToScript(Text, S);
    Got := Run(P, S, Note);
    Check(Name + ': nothing escaped', Note = '', Note);
    CheckDouble(Name, Got, Want);
  end;

begin
  BeginSection('E9: Exit against the formula-level try');
  P := TMathParser.Create(nil);
  try
    One('TryFinally(Exit(42), Exit(7))', 7, 'an Exit from the finaliser replaces the one being unwound');
    One('TryFinally(Exit(42), 7)', 42, 'an ordinary finaliser does not suppress the Exit');
    One('TryExcept(Exit(42), Exit(7))', 42, 'the formula-level except never sees the Exit');
    One('TryFinally(Exit(42), Exit(7)) + 1000', 7, 'an Exit from the finaliser ends the whole evaluation');
  finally
    P.Free;
  end;
end;

begin
  try
    Hop := THop.Create;
    Ag := TAgain.Create;
    Hop.FA := TMathParser.Create(nil);
    Hop.FB := TMathParser.Create(nil);
    Hop.FC := TMathParser.Create(nil);
    Ag.FParser := TMathParser.Create(nil);
    try
      { Registration is over before the first evaluation - that is the contract }
      Hop.FA.AddFunction('tob', HandleToB, fkMethod, MakeFunctionMethod(Hop.ToB, 1, pkValue), False);
      Hop.FA.AddFunction('recursea', HandleRecurse, fkMethod,
        MakeFunctionMethod(Hop.RecurseA, 1, pkValue), False);
      Hop.FA.AddFunction('legacyexit', HandleLegacy, fkMethod,
        MakeFunctionMethod(Hop.LegacyExit, 1, pkValue), False);
      Hop.FB.AddFunction('backtoa', HandleBack, fkMethod, MakeFunctionMethod(Hop.BackToA, 1, pkValue), False);
      Hop.FB.AddFunction('toc', HandleToC, fkMethod, MakeFunctionMethod(Hop.ToC, 1, pkValue), False);
      Hop.FC.AddFunction('backtoa', HandleBack, fkMethod, MakeFunctionMethod(Hop.BackToA, 1, pkValue), False);
      Ag.FParser.AddFunction('again', HandleAgain, fkMethod, MakeFunctionMethod(Ag.Again, 1, pkValue), False);
      E1_PlainRecursion;
      E2_ThroughForeignParser;
      E3_TwoForeignParsers;
      E4_MiddleParserOwnsItsExit;
      E5_LegacyConstructorInChain;
      E6_LegacyConstructorOutsideEvaluation;
      E8_ReentrantWithSeparateBuffers;
      E9_TryExceptAndTryFinally;
    finally
      Ag.FParser.Free;
      Hop.FC.Free;
      Hop.FB.Free;
      Hop.FA.Free;
      Ag.Free;
      Hop.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
