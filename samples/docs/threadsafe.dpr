{ ************************************************************************** }
{                                                                            }
{ ThreadSafe                                                                 }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ThreadSafe;

{ expect: 4 workers, 0 wrong }
{$APPTYPE CONSOLE}

uses SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils, Thread;

type
  TWorker = class(TThread)
  private
    FParser: TMathParser;
    FScript: TScript;
    FValue: TValue;
    FWrong: Integer;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  end;

var
  P: TMathParser;
  Compiled: TScript;
  Pack: array [0 .. 3] of TWorker;
  I, Spent, Wrong: Integer;
  Alive: Boolean;

procedure TWorker.Work;
var
  R: Integer;
begin
  for R := 1 to 1000 do
  begin
    AssignDouble(FValue, R);
    if Abs(GetDouble(FParser.ExecuteScript(FScript)^) - (R * R + 1)) > 1E-9 then Inc(FWrong);
  end;
end;

procedure TWorker.Done;
begin
  FEnded := True;
end;

begin
  P := TMathParser.Create(nil);
  try
    Compiled := nil;
    for I := 0 to High(Pack) do
    begin
      Pack[I] := TWorker.Create(nil);
      Pack[I].FParser := P;
      AssignDouble(Pack[I].FValue, 0);
      { A variable of its own for each worker: a shared one would be external
        state the caller answers for, not the parser }
      P.AddVariable('v' + IntToStr(I), Pack[I].FValue);
    end;
    P.StringToScript('v0 * v0 + 1', Compiled);
    { show }
    for I := 0 to High(Pack) do
    begin
      P.StringToScript(StringReplace('v0 * v0 + 1', 'v0', 'v' + IntToStr(I), [rfReplaceAll]), Compiled);
      Pack[I].FScript := Copy(Compiled);
    end;
    for I := 0 to High(Pack) do Pack[I].Start;
    { show done }
    Spent := 0;
    repeat
      Sleep(20);
      Inc(Spent, 20);
      Alive := False;
      for I := 0 to High(Pack) do if not Pack[I].FEnded then Alive := True;
    until (not Alive) or (Spent > 60000);
    Wrong := 0;
    for I := 0 to High(Pack) do Inc(Wrong, Pack[I].FWrong);
    Writeln(Format('%d workers, %d wrong', [Length(Pack), Wrong]));
    for I := High(Pack) downto 0 do Pack[I].Free;
  finally
    P.Free;
  end;
end.
