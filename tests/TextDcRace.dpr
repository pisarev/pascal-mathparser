{ ************************************************************************** }
{                                                                            }
{ TextDcRace                                                                 }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

{ A shared screen device context in TextUtils: a race between threads.\n\n  WHAT WAS WRONG. TextUtils took one screen device context for the whole\n  process - at unit initialization - and every function that measures text\n  worked through it:\n\n      Handle := SelectObject(DC, FontHandle);\n      ... measuring ...\n      SelectObject(DC, Handle);\n\n  That sequence of three steps is not atomic, and the context is shared. Two\n  threads interleave like this: the first selects its font, the second\n  selects its own, the first measures - and measures with somebody else's\n  font. The second measures too, and by then the context may hold either\n  font.\n\n  IT IS NOT AN INVENTED CASE. The tree of graph components measures text\n  from its own threads. The same unit goes out as\n  pascal-mathparser/src/TextUtils.pas, where these functions are part of the\n  interface, and calling them from a working thread is as allowed as anything\n  else. Thread safety is a property of the unit, not a property of good\n  habits.\n\n  HOW THE RACE IS CAUGHT. First each font is measured alone, and the answer\n  is kept as the right one. Then two threads measure at the same time, each\n  with its own font, and check against its own right answer. Any single\n  disagreement is a defect: the width of a string does not depend on who else\n  is measuring at that moment.\n\n  The fonts are deliberately far apart in size: a disagreement is then not\n  subtle but gross, and an accidental match of widths is ruled out.\n\n  THE CHECK IS NOT SYMMETRIC. A race is probabilistic. A run without a\n  disagreement does not prove there is none - only that it did not show;\n  hence the count of probes is written down in the output. The evidence this\n  probe gives is one-sided: a disagreement is a verdict. }
program TextDcRace;

{$APPTYPE CONSOLE}
{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  SysUtils, Classes,
  {$IFDEF FPC}Windows,{$ELSE}WinApi.Windows,{$ENDIF}
  TestKit, TextUtils;

const
  Probes = 20000;
  Sample = 'MMMMMMMMWWWWWWWW';

{$IFNDEF FPC}
type
  TMeter = class(TThread)
  private
    FFont: THandle;
    FWant: Integer;
    FBad: Integer;
    FDone: Integer;
    FGo: PInteger;
  protected
    procedure Execute; override;
  public
    property Bad: Integer read FBad;
    property Done: Integer read FDone;
  end;

procedure TMeter.Execute;
var
  I: Integer;
  S: TSize;
begin
  { Both threads wait for a common signal: otherwise one could finish its\n    whole run before the other even starts, and there would be nothing to\n    interleave. }
  while FGo^ = 0 do
    Sleep(0);
  for I := 1 to Probes do
  begin
    S := GetTextSize(Sample, FFont);
    Inc(FDone);
    if S.cx <> FWant then
      Inc(FBad);
  end;
end;

function MakeFont(const Height: Integer): THandle;
begin
  Result := CreateFont(Height, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
    OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
    FIXED_PITCH or FF_MODERN, 'Courier New');
end;

procedure Run;
var
  Small, Large: THandle;
  WantSmall, WantLarge: Integer;
  A, B: TMeter;
  Go: Integer;
begin
  Small := MakeFont(-12);
  Large := MakeFont(-48);
  try
    Check('the small font was created', Small <> 0);
    Check('the large font was created', Large <> 0);

    { The right answer is taken alone - before the second thread starts. While\n      the stand is here, the two fonts are compared as well. }
    WantSmall := GetTextSize(Sample, Small).cx;
    WantLarge := GetTextSize(Sample, Large).cx;
    Writeln(Format('alone: small %d, large %d', [WantSmall, WantLarge]));
    Check('the two fonts measure differently', WantSmall <> WantLarge,
      Format('%d against %d', [WantSmall, WantLarge]));
    Check('the small width is above zero', WantSmall > 0);
    Go := 0;
    A := TMeter.Create(True);
    B := TMeter.Create(True);
    try
      A.FFont := Small;
      A.FWant := WantSmall;
      A.FGo := @Go;
      B.FFont := Large;
      B.FWant := WantLarge;
      B.FGo := @Go;
      A.FreeOnTerminate := False;
      B.FreeOnTerminate := False;
      A.Start;
      B.Start;
      Go := 1;
      A.WaitFor;
      B.WaitFor;
      Writeln(Format('measurements: %d and %d, disagreements: %d and %d',
        [A.Done, B.Done, A.Bad, B.Bad]));
      Check('the thread with the small font measured its own', A.Bad = 0,
        Format('%d disagreements out of %d', [A.Bad, A.Done]));
      Check('the thread with the large font measured its own', B.Bad = 0,
        Format('%d disagreements out of %d', [B.Bad, B.Done]));
    finally
      A.Free;
      B.Free;
    end;
  finally
    DeleteObject(Small);
    DeleteObject(Large);
  end;
end;
{$ENDIF}

begin
  {$IFDEF FPC}
  Writeln('skipped: these functions exist in the Delphi build only');
  {$ELSE}
  BeginSection('a shared screen device context under two threads');
  Run;
  {$ENDIF}
  Halt(TestSummary);
end.
