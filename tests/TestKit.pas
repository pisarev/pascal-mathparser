{ ************************************************************************** }
{                                                                            }
{ TestKit                                                                    }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                      }
{                                                                            }
{ ************************************************************************** }

unit TestKit;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses SysUtils, Math;

procedure BeginSection(const Name: string);
procedure Check(const Name: string; const Condition: Boolean; const Details: string = '');
procedure CheckDouble(const Name: string; const Actual, Expected: Double; const Epsilon: Double = 1E-9);
procedure Fail(const Name, Details: string);
function TestSummary: Integer;

{ A precise clock for speed measurements.

  Kept apart from TDateTime: a measurement needs a resolution noticeably finer
  than a millisecond. On Windows that is QueryPerformanceCounter, on Unix it is
  CLOCK_MONOTONIC, which does not jump when the system clock is changed. }
function Now64: Int64;

{ Seconds elapsed since a Now64 mark. }
function Elapsed(const From: Int64): Double;

implementation

uses
  {$IFDEF MSWINDOWS}
  {$IFDEF FPC}Windows;{$ELSE}WinApi.Windows;{$ENDIF}
  {$ELSE}
  BaseUnix, UnixType{$IFDEF LINUX}, Linux{$ENDIF};
  {$ENDIF}

var
  TestCount: Integer = 0;
  FailCount: Integer = 0;

{$IFDEF MSWINDOWS}

var
  Frequency: Int64 = 0;

function Now64: Int64;
begin
  QueryPerformanceCounter(Result);
end;

function Elapsed(const From: Int64): Double;
var
  Stamp: Int64;
begin
  if Frequency = 0 then QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(Stamp);
  Result := (Stamp - From) / Frequency;
end;

{$ELSE}

function Now64: Int64;
{$IFDEF LINUX}
var
  Stamp: TTimeSpec;
begin
  { a monotonic clock: it does not jump when system time is changed }
  clock_gettime(CLOCK_MONOTONIC, @Stamp);
  Result := Int64(Stamp.tv_sec) * 1000000000 + Stamp.tv_nsec;
end;
{$ELSE}
var
  Stamp: TTimeVal;
begin
  { other Unix: microsecond resolution, enough for timing loops }
  fpGetTimeOfDay(@Stamp, nil);
  Result := Int64(Stamp.tv_sec) * 1000000000 + Int64(Stamp.tv_usec) * 1000;
end;
{$ENDIF}

function Elapsed(const From: Int64): Double;
begin
  Result := (Now64 - From) / 1000000000;
end;

{$ENDIF}

procedure BeginSection(const Name: string);
begin
  Writeln;
  Writeln('--- ', Name, ' ---');
end;

procedure Check(const Name: string; const Condition: Boolean; const Details: string);
begin
  Inc(TestCount);
  if Condition then
    Writeln('PASS  ', Name)
  else begin
    Inc(FailCount);
    Write('FAIL  ', Name);
    if Details <> '' then Write('  [', Details, ']');
    Writeln;
  end;
  Flush(Output);
end;

procedure CheckDouble(const Name: string; const Actual, Expected, Epsilon: Double);
begin
  Check(Name, SameValue(Actual, Expected, Epsilon), Format('actual=%.10g expected=%.10g', [Actual, Expected]));
end;

procedure Fail(const Name, Details: string);
begin
  Check(Name, False, Details);
end;

function TestSummary: Integer;
begin
  Writeln;
  Writeln(Format('TOTAL: %d, FAILED: %d', [TestCount, FailCount]));
  Result := FailCount;
end;

end.
