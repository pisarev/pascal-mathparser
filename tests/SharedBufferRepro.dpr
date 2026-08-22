{ ************************************************************************** }
{                                                                            }
{ SharedBufferRepro                                                          }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program SharedBufferRepro;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils, Thread;

{
  What this file reproduces, on purpose: the use the documentation forbids.

  A TScript is not immutable bytecode. Evaluation writes into the script
  headers - the accumulator of the running formula, the result, and the values
  of internal scripts computed up front all live there. One buffer therefore
  carries the state of exactly one evaluation, and sharing it costs correctness
  in two ways, neither of which raises anything.

  Two reproducers, kept out of the green suite because they demonstrate the
  forbidden case rather than a defect to be fixed:

    R1  the same buffer entered again from inside itself, one thread
    R2  the same buffer evaluated by four threads at once

  R1 answers 302 where 301 is due. R2 answers wrongly a few thousand times out
  of four thousand per thread, and the exact count moves with the scheduler, so
  the check here is only that a wrong answer appears at all.

  Both stay in the tree for two reasons: they are the evidence behind the
  restriction the README states, and they are the starting measurement for the
  day the execution image becomes read-only. On that day R1 has to answer 301.
}

const
  Workers = 4;
  Rounds = 4000;

type
  { Entering the SAME buffer from inside its own evaluation. The depth is capped
    at one level: the first nested entry is what matters, and anything deeper
    would descend forever. }
  TReenter = class
  private
    FParser: TMathParser;
    FSame: TScript;
    FDepth: Integer;
    FNestedValue: Double;
  public
    function Again(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

  TShared = class(TThread)
  private
    FParser: TMathParser;
    FScript: TScript;
    FWant: Double;
    FBad: Integer;
    FNote: string;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  end;

var
  Re: TReenter;
  Handle: TFunctionHandle;
  Outer: TScript;
  Note: string;
  Got: Double;
  P: TMathParser;
  Pack: array [0 .. Workers - 1] of TShared;
  Values: array [0 .. Workers - 1] of TValue;
  Shared: TScript;
  I, Spent, Wrong: Integer;
  Alive: Boolean;

function TReenter.Again(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Inc(FDepth);
  try
    if FDepth = 1 then FNestedValue := GetDouble(FParser.ExecuteScript(FSame)^);
  finally
    Dec(FDepth);
  end;
  Result := MakeDouble(1);
end;

procedure TShared.Work;
var
  R: Integer;
  Answer: Double;
begin
  try
    for R := 1 to Rounds do
    begin
      Answer := GetDouble(FParser.ExecuteScript(FScript)^);
      if Abs(Answer - FWant) > 1E-9 then Inc(FBad);
    end;
  except
    on E: Exception do FNote := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TShared.Done;
begin
  FEnded := True;
end;

begin
  Writeln('R1: the same buffer entered again from inside itself, one thread');
  Re := TReenter.Create;
  Re.FParser := TMathParser.Create(nil);
  try
    Re.FParser.AddFunction('again', Handle, fkMethod, MakeFunctionMethod(Re.Again, 1, pkValue), False);
    Re.FSame := nil;
    Re.FParser.StringToScript('100 + 100 + 100 + again(0)', Re.FSame);
    Note := '';
    Got := 0;
    try
      Got := GetDouble(Re.FParser.ExecuteScript(Re.FSame)^);
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Writeln(Format('  nested %.0f, outer %.0f, due 301, note "%s"', [Re.FNestedValue, Got, Note]));
    if Abs(Got - 301) > 1E-9 then
      Writeln('  reproduced: the outer accumulator was overwritten by the nested evaluation')
    else
      Writeln('  NOT reproduced: the execution image no longer carries evaluation state');
  finally
    Re.FParser.Free;
    Re.Free;
  end;
  Writeln;
  Writeln('R2: the same buffer evaluated by four threads at once');
  P := TMathParser.Create(nil);
  try
    for I := 0 to Workers - 1 do
    begin
      AssignDouble(Values[I], I + 1);
      P.AddVariable('v' + IntToStr(I), Values[I]);
    end;
    Shared := nil;
    P.StringToScript('v0 * 1000 + v1 * 100 + v2 * 10 + v3', Shared);
    Got := GetDouble(P.ExecuteScript(Shared)^);
    Writeln(Format('  single evaluation gives %.0f', [Got]));
    for I := 0 to Workers - 1 do
    begin
      Pack[I] := TShared.Create(nil);
      Pack[I].FParser := P;
      { No Copy - that is exactly the forbidden case }
      Pack[I].FScript := Shared;
      Pack[I].FWant := Got;
      Pack[I].Start;
    end;
    Spent := 0;
    repeat
      Sleep(20);
      Inc(Spent, 20);
      Alive := False;
      for I := 0 to Workers - 1 do if not Pack[I].FEnded then Alive := True;
    until (not Alive) or (Spent > 120000);
    Wrong := 0;
    for I := 0 to Workers - 1 do
    begin
      Inc(Wrong, Pack[I].FBad);
      Writeln(Format('  worker %d: %d wrong out of %d, note "%s"', [I, Pack[I].FBad, Rounds, Pack[I].FNote]));
    end;
    if Wrong > 0 then
      Writeln('  reproduced: the shared result cell was written by several threads')
    else
      Writeln('  NOT reproduced this run: the count moves with the scheduler, repeat it');
    for I := Workers - 1 downto 0 do Pack[I].Free;
  finally
    P.Free;
  end;
end.
