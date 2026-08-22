{ ************************************************************************** }
{                                                                            }
{ CacheContractTest                                                          }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program CacheContractTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, TestKit in 'TestKit.pas';

{
  What this file guards.

  THE CACHE CONTRACT. The parser caches what it compiled, and on 20.08.2026 it
  turned out that the cache changes the MEANING of a parse: on one instance,
  one after another, 1E3 gives 1000 and 2E3 gives 2. Silently, with no error.
  Turning the cache off (Cached := False) removes the divergence entirely -
  so the cache is to blame, not the grammar of a number.

  There is no way around this trouble: without the cache a parse is 13 times
  slower (measured by CacheCostProbe), and the panel evaluates a curve with
  thousands of calls.

  The contract is stated as properties rather than examples - examples run
  out, properties do not. The eight statements below came out of a peer review
  (#GAN-EXPERT-DUET, round 4, 20.08.2026) and are turned into a run here:

    1 transparency   - switching the cache on does not change the answer;
    2 independence   - the answer does not depend on what was parsed before;
    3 hit = miss     - a second parse of the same text gives what the first did;
    7 key isolation  - working on one text does not spoil another;
    8 repeatability  - the third and fourth parses match the second.

  Properties 4, 5 and 6 (immutability of the record, immutability of the read,
  no shared memory) are about the construction rather than the behaviour; from
  outside they show through 1, 2 and 3 exactly, and they get no run of their
  own here. That is a NAMED omission, not a forgotten one.

  The checks were written RED: on the tree of 20.08.2026 they failed. They
  went green after the cache was fixed.
}

const
  { The set is deliberately mixed: numbers with exponents, functions, powers,
  brackets. }
  Corpus: array[0..11] of string = (
    '1E3',
    '2E3',
    '3E3',
    '1E3 * 1',
    '2E3 * 1',
    '1.5E3 + 0',
    '2 + 3 ** 2',
    'Sin(2) * 3',
    '(2 + 1) ** 2',
    'Ln(100) / 2',
    '1E2 + 2E2',
    '10E2'
  );

function Fresh(const Text: string; out Ok: Boolean): Double;
var
  P: TMathParser;
begin
  Result := 0;
  Ok := True;
  P := TMathParser.Create(nil);
  try
    try
      Result := P.AsDouble(Text);
    except
      Ok := False;
    end;
  finally
    P.Free;
  end;
end;

function Same(const A, B: Double): Boolean;
begin
  Result := (IsNan(A) and IsNan(B)) or (Abs(A - B) <= 1E-9 * Max(1, Abs(A)));
end;

function Num(const V: Double; const Ok: Boolean): string;
begin
  if not Ok then
    Result := 'refused'
  else
    Result := FormatFloat('0.######', V);
end;

var
  P: TMathParser;

function Take(const Text: string; out Ok: Boolean): Double;
begin
  Result := 0;
  Ok := True;
  try
    Result := P.AsDouble(Text);
  except
    Ok := False;
  end;
end;

procedure TransparencyAndHistory;
var
  I: Integer;
  Got, Want: Double;
  GotOk, WantOk: Boolean;
begin
  BeginSection('1 and 2: the cache does not change the answer, the history does not tell');
  {
    One instance goes through the whole set in a row. Every answer is compared
    with the answer of a FRESH instance on the same text: the fresh one is what
    "as it should be" means, because it has no history.
  }
  P := TMathParser.Create(nil);
  try
    for I := Low(Corpus) to High(Corpus) do
    begin
      Got := Take(Corpus[I], GotOk);
      Want := Fresh(Corpus[I], WantOk);
      Check(Format('%d) %s gives what a fresh parser gives',
        [I + 1, Corpus[I]]),
        (GotOk = WantOk) and (not GotOk or Same(Got, Want)),
        Format('here %s, on a fresh one %s',
          [Num(Got, GotOk), Num(Want, WantOk)]));
    end;
  finally
    P.Free;
  end;
end;

procedure HitEqualsMiss;
var
  I: Integer;
  First, Second, Third: Double;
  A, B, C: Boolean;
begin
  BeginSection('3 and 8: a hit equals a miss, and it holds every time');
  for I := Low(Corpus) to High(Corpus) do
  begin
    P := TMathParser.Create(nil);
    try
      First := Take(Corpus[I], A);
      Second := Take(Corpus[I], B);
      Third := Take(Corpus[I], C);
      Check(Format('%d) %s: the second and third parse equal the first',
        [I + 1, Corpus[I]]),
        (A = B) and (B = C) and (not A or (Same(First, Second) and Same(Second, Third))),
        Format('%s, %s, %s', [Num(First, A), Num(Second, B), Num(Third, C)]));
    finally
      P.Free;
    end;
  end;
end;

procedure KeyIsolation;
var
  I, J: Integer;
  Before, After: Double;
  A, B, Dummy: Boolean;
begin
  BeginSection('7: working on one text does not spoil another');
  {
    Pair by pair: parse A, remember it; parse B; come back to A. The answer for
    A is obliged not to change. The pairs are taken every other one rather than
    all of them - otherwise the run grows quadratically without adding meaning.
  }
  for I := Low(Corpus) to High(Corpus) do
  begin
    J := (I + 1) mod Length(Corpus);
    P := TMathParser.Create(nil);
    try
      Before := Take(Corpus[I], A);
      Take(Corpus[J], Dummy);
      After := Take(Corpus[I], B);
      Check(Format('%s did not change after %s', [Corpus[I], Corpus[J]]),
        (A = B) and (not A or Same(Before, After)),
        Format('was %s, became %s', [Num(Before, A), Num(After, B)]));
    finally
      P.Free;
    end;
  end;
end;

procedure CacheOffMatches;
var
  I: Integer;
  WithCache, WithoutCache: Double;
  A, B: Boolean;
  Q: TMathParser;
begin
  BeginSection('1 directly: with the cache and without it, one answer');
  P := TMathParser.Create(nil);
  Q := TMathParser.Create(nil);
  try
    Q.Cached := False;
    for I := Low(Corpus) to High(Corpus) do
    begin
      WithCache := Take(Corpus[I], A);
      try
        WithoutCache := Q.AsDouble(Corpus[I]);
        B := True;
      except
        WithoutCache := 0;
        B := False;
      end;
      Check(Format('%d) %s: Cached=True equals Cached=False',
        [I + 1, Corpus[I]]),
        (A = B) and (not A or Same(WithCache, WithoutCache)),
        Format('with the cache %s, without it %s',
          [Num(WithCache, A), Num(WithoutCache, B)]));
    end;
  finally
    Q.Free;
    P.Free;
  end;
end;

begin
  TransparencyAndHistory;
  HitEqualsMiss;
  KeyIsolation;
  CacheOffMatches;
  Halt(TestSummary);
end.
