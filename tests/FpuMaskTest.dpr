{ ************************************************************************** }
{                                                                            }
{ FpuMaskTest                                                                }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program FpuMaskTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, Thread, TestKit in 'TestKit.pas';

{
  Who the floating point exception mask belongs to.

  The library promises numbers rather than exceptions: division by zero gives
  infinity, the square root of minus one gives NaN, and the formula runs to the
  end. The promise rests on the FPU mask: all six exceptions are masked, so the
  processor writes a special value instead of interrupting the computation.

  The mask is state of the THREAD. It used to be installed in the parser's
  constructor, with the previous value restored in the destructor. Those are
  different scopes, and they part in three places:

  1. The parser is created in one thread and evaluates in another. Only the
     first got the mask; the second is running with whatever the host set, and
     division by zero raises instead of giving infinity. That is exactly how the
     plotting component works: one parser, four worker threads.

  2. While the parser is alive the mask stands for the WHOLE program.
     Neighbouring code doing its own arithmetic in the same thread quietly stops
     getting the exceptions it counted on.

  3. The parser is created in one thread and destroyed in another: that third
     one is handed a mask taken down long ago in the first.

  THE MEASUREMENT WITHOUT WHICH THIS FILE WOULD BE EMPTY. A console program of
  this studio starts with the processor FULLY masked: 8087CW = 027F, MXCSR =
  1F80, and 1/0 gives +Inf before any parser exists. In the case one observes by
  default the constructor therefore changes nothing, and a check written
  "as it comes" would be green on any code at all.

  So the mask here is narrowed ON PURPOSE - the way a program does when it wants
  exceptions in its own arithmetic (a long habit of VCL applications). The
  divergence shows on a narrowed mask.
}

const
  { The mask of an application that wants exceptions in its own arithmetic: the
    three harmless ones masked, the three that matter not. }
  HostMask = [exDenormalized, exUnderflow, exPrecision];

type
  { Evaluates a formula in ITS OWN thread on somebody else's parser, having narrowed the mask to suit itself. }
  TRunner = class(TThread)
  private
    FParser: TMathParser;
    FText: string;
    FValue: Double;
    FNote: string;
    FMaskAfter: TFPUExceptionMask;
    FEnded: Boolean;
  protected
    procedure Work; override;
    procedure Done; override;
  end;

var
  P: TMathParser;
  Runners: array [0 .. 7] of TRunner;
  RunnerCount: Integer;
  I: Integer;

procedure TRunner.Work;
var
  Script: TScript;
begin
  SetExceptionMask(HostMask);
  Script := nil;
  try
    FParser.StringToScript(FText, Script);
    FValue := GetDouble(FParser.ExecuteScript(Script)^);
  except
    on E: Exception do FNote := E.ClassName + ': ' + E.Message;
  end;
  FMaskAfter := GetExceptionMask;
end;

procedure TRunner.Done;
begin
  FEnded := True;
end;

function Waiting(const Ended: PBoolean; const Time: LongWord): Boolean;
var
  Spent: LongWord;
begin
  Spent := 0;
  while not Ended^ and (Spent < Time) do
  begin
    Sleep(5);
    Inc(Spent, 5);
  end;
  Result := Ended^;
end;

function Launch(const Text: string): TRunner;
begin
  Result := TRunner.Create(nil);
  Runners[RunnerCount] := Result;
  Inc(RunnerCount);
  Result.FParser := P;
  Result.FText := Text;
  Result.Start;
end;

function MaskText(const Mask: TFPUExceptionMask): string;
begin
  Result := '';
  if exInvalidOp in Mask then Result := Result + 'InvalidOp ';
  if exDenormalized in Mask then Result := Result + 'Denormalized ';
  if exZeroDivide in Mask then Result := Result + 'ZeroDivide ';
  if exOverflow in Mask then Result := Result + 'Overflow ';
  if exUnderflow in Mask then Result := Result + 'Underflow ';
  if exPrecision in Mask then Result := Result + 'Precision ';
  if Result = '' then Result := '(empty)';
end;

{ 1 }

{ While the parser is alive the mask of the thread belongs to the host, not to the parser. }
procedure LivingParserDoesNotHoldTheMask;
begin
  BeginSection('a living parser does not hold the mask of the thread');
  Check('creating a parser left the mask alone', GetExceptionMask = HostMask, MaskText(GetExceptionMask));
  Check('the host still gets its exceptions', not (exZeroDivide in GetExceptionMask), MaskText(GetExceptionMask));
end;

{ 2 }

{ A formula is evaluated by the library's contract, not by the host mask. }
procedure FormulaKeepsItsContract;
var
  Value: Double;
  Note: string;
begin
  BeginSection('a formula answers with a number under the narrowed host mask');
  Note := '';
  Value := 0;
  try
    Value := P.AsDouble('1 / 0');
  except
    on E: Exception do Note := E.ClassName + ': ' + E.Message;
  end;
  Check('nothing was raised', Note = '', Note);
  Check('the answer is infinity', IsInfinite(Value), Format('%g', [Value]));
  Check('after the evaluation the host mask came back', GetExceptionMask = HostMask, MaskText(GetExceptionMask));
end;

{ 3 }

{ A foreign thread on a shared parser: the contract has to hold there too. }
procedure ForeignThreadGetsTheNumber;
var
  R: TRunner;
begin
  BeginSection('a foreign thread gets a number, not an exception');
  R := Launch('1 / 0');
  Check('the thread finished', Waiting(@R.FEnded, 10000), 'never arrived');
  Check('nothing was raised', R.FNote = '', R.FNote);
  Check('the answer is infinity', IsInfinite(R.FValue), Format('%g', [R.FValue]));
  Check('after the evaluation the thread mask is its own', R.FMaskAfter = HostMask, MaskText(R.FMaskAfter));
  R := Launch('Sqrt(0 - 1)');
  Check('the second thread finished', Waiting(@R.FEnded, 10000), 'never arrived');
  Check('nothing was raised', R.FNote = '', R.FNote);
  Check('the answer is NaN', IsNan(R.FValue), Format('%g', [R.FValue]));
end;

begin
  try
    {
      Narrowing the mask IS the host that wants exceptions. Without it the whole
      file would be green on any code: by default everything is masked.
    }
    SetExceptionMask(HostMask);
    P := TMathParser.Create(nil);
    try
      LivingParserDoesNotHoldTheMask;
      FormulaKeepsItsContract;
      ForeignThreadGetsTheNumber;
    finally
      P.Free;
    end;
    Check('after the parser is freed the host mask is unchanged', GetExceptionMask = HostMask, MaskText(GetExceptionMask));
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  for I := 0 to RunnerCount - 1 do Runners[I].Free;
  Halt(TestSummary);
end.
