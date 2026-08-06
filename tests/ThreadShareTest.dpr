{ ************************************************************************** }
{                                                                            }
{ ThreadShareTest                                                            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ThreadShareTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, Thread, TestKit in 'TestKit.pas';

{
  What this file guards: one parser, many threads.

  The plotting component hands every worker the SAME parser object and lets
  four of them sample a curve at once. Two things could go wrong, and they
  need to be told apart.

  The first is fine, and this file proves it rather than assuming it: every
  worker gets Copy(Script), TScript is a dynamic array of bytes, and
  System.Copy allocates a new array. ExecuteScript writes Header.Value into
  those bytes, so each thread writes into its own header. The variables are
  separated the same way - each worker registers its own and the script is
  redirected at it.

  The second was not fine. ExecuteScript used to keep a nesting counter in a
  FIELD OF THE PARSER - shared by all of them - and moved it with a plain Inc
  and Dec, which are read-modify-write on a machine word without a lock. Two
  threads could lose one of the updates. The counter was not decoration: the
  handler for Exit inside a formula compared it against 1 to decide whether to
  take the value or re-raise the exception. A drifted counter therefore turned
  Exit into an escaping exception - and it stayed drifted, so the damage
  outlived the moment. The depth now lives in a frame on the stack of the call
  and there is no shared counter left to drift; ThreadSafetyTest is where that
  is proved case by case.

  The check below runs the arithmetic that has no Exit in it - that part must
  simply be correct - and then asks the parser to evaluate a formula WITH Exit
  after the storm. That second part is what a drifted counter used to break,
  and it is kept as a regression: nothing else notices the damage.
}

const
  Workers = 4;
  Rounds = 6000;
  Plain = 'Sin(v) * v + Cos(v * 2) / (1 + v * v)';

type
  TWorker = class(TThread)
  private
    FScript: TScript;
    FValue: TValue;
    FBad: Integer;
    FNote: string;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  end;

var
  P: TMathParser;
  Pack: array [0 .. Workers - 1] of TWorker;
  Wanted: array [0 .. Workers - 1, 0 .. 15] of Double;
  I, R: Integer;
  Spent: LongWord;
  Alive: Boolean;
  Probe: TScript;
  ProbeValue: TValue;
  Got: Double;
  Escaped: string;

{ The value worker W feeds on round R. Different per worker on purpose:
  identical inputs would hide a shared-state race behind equal answers. }
function Feed(const W, R: Integer): Double;
begin
  Result := (R mod 16) / 7 + W;
end;

procedure TWorker.Work;
var
  R: Integer;
  Answer: Double;
begin
  try
    for R := 0 to Rounds - 1 do
    begin
      AssignDouble(FValue, Feed(Tag, R));
      Answer := GetDouble(P.ExecuteScript(FScript)^);
      if Abs(Answer - Wanted[Tag, R mod 16]) > 1E-9 then Inc(FBad);
    end;
  except
    on E: Exception do FNote := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TWorker.Done;
begin
  FEnded := True;
end;

begin
  try
    P := TMathParser.Create(nil);
    try
      BeginSection('one parser, four threads, a copy of the script each');
      { Everything is registered BEFORE the first evaluation - that is the
        documented contract, and the component keeps it too. }
      for I := 0 to Workers - 1 do
      begin
        Pack[I] := TWorker.Create(nil);
        Pack[I].Tag := I;
        AssignDouble(Pack[I].FValue, 0);
        P.AddVariable('v' + IntToStr(I), Pack[I].FValue);
        P.StringToScript(StringReplace(Plain, 'v', 'v' + IntToStr(I), [rfReplaceAll]), Pack[I].FScript);
      end;
      { The answers each worker must get, computed here with nobody else
        running. }
      for I := 0 to Workers - 1 do
        for R := 0 to 15 do
        begin
          AssignDouble(Pack[I].FValue, Feed(I, R));
          Wanted[I, R] := GetDouble(P.ExecuteScript(Pack[I].FScript)^);
        end;
      Check('the formula gives a number at all', not IsNan(Wanted[0, 0]), Format('%g', [Wanted[0, 0]]));
      for I := 0 to Workers - 1 do Pack[I].Start;
      Spent := 0;
      repeat
        Sleep(20);
        Inc(Spent, 20);
        Alive := False;
        for I := 0 to Workers - 1 do if not Pack[I].FEnded then Alive := True;
      until (not Alive) or (Spent > 180000);
      Check('all four workers finished', not Alive, Format('%d ms', [Spent]));
      for I := 0 to Workers - 1 do
      begin
        Check(Format('worker %d raised nothing', [I]), Pack[I].FNote = '', Pack[I].FNote);
        Check(Format('worker %d got its own answers every time', [I]), Pack[I].FBad = 0,
          Format('%d wrong out of %d', [Pack[I].FBad, Rounds]));
      end;
      {
        Nesting is private, so it is checked by what depends on it. Exit inside
        a formula is caught by the parser and its value returned - but only
        while the evaluation knows it is the outermost one. Back when that was
        decided by a shared counter, a storm of concurrent evaluations left the
        answer wrong here, and nowhere else.
      }
      BeginSection('Exit still works after the storm');
      AssignDouble(ProbeValue, 0);
      P.AddVariable('probe', ProbeValue);
      Probe := nil;
      Escaped := '';
      Got := 0;
      try
        P.StringToScript('Script(probe, Exit(42))', Probe);
        Got := GetDouble(P.ExecuteScript(Probe)^);
      except
        on E: Exception do Escaped := E.ClassName + ': ' + E.Message;
      end;
      Check('Exit inside a formula is still caught by the parser', Escaped = '', Escaped);
      CheckDouble('and still returns its value', Got, 42);
    finally
      P.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
