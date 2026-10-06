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
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, Thread,
  ParseJit.Parser, TestKit in 'TestKit.pas';

const
  HostMask = [exDenormalized, exUnderflow, exPrecision];

type
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

type
  THolder = class
  private
    FInner: TMathParser;
    FNote: string;
  public
    function Inner(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

var
  P: TMathParser;
  Inner: TMathParser;
  Holder: THolder;
  InnerHandle: TFunctionHandle;
  Runners: array [0 .. 7] of TRunner;
  RunnerCount: Integer;
  I: Integer;

function THolder.Inner(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  FNote := '';
  Result := MakeDouble(0);
  try
    Result := MakeDouble(FInner.AsDouble('1 / 0'));
  except
    on E: Exception do FNote := E.ClassName + ': ' + E.Message;
  end;
end;

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

procedure LivingParserDoesNotHoldTheMask;
begin
  BeginSection('a living parser does not hold the mask of the thread');
  Check('creating a parser left the mask alone', GetExceptionMask = HostMask, MaskText(GetExceptionMask));
  Check('the host still gets its exceptions', not (exZeroDivide in GetExceptionMask),
    MaskText(GetExceptionMask));
end;

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
  Check('after the evaluation the host mask came back', GetExceptionMask = HostMask,
    MaskText(GetExceptionMask));
end;

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

procedure NestedParserInstallsItsOwnMask;
var
  Value: Double;
  Note: string;
begin
  BeginSection('a nested parser installs its own mask');
  Inner := TMathParser.Create(nil);
  try
    Inner.ExceptionMask := HostMask;
    Holder.FInner := Inner;
    Holder.FNote := '';
    Note := '';
    Value := 0;
    try
      Value := P.AsDouble('inner(0)');
    except
      on E: Exception do Note := E.ClassName;
    end;
    Check('the outer evaluation ran to the end', Note = '', Note);
    Check('the inner parser got ITS OWN exception', Pos('EZeroDivide', Holder.FNote) > 0, Holder.FNote);
    Check('and handed a zero back out rather than a number', Value = 0, Format('%g', [Value]));
    Check('after the evaluation the host mask is in place', GetExceptionMask = HostMask,
      MaskText(GetExceptionMask));
  finally
    Inner.Free;
    Holder.FInner := nil;
  end;
end;

procedure EveryEntryKeepsTheContract;
var
  J: TJitParser;
  Held: TJitScript;
  Script: TScript;
  Inputs, Outputs: array of Double;
  X, Value: Double;
  Note: string;
  Done: Boolean;
begin
  BeginSection('all three entries of the accelerator keep the mask contract');
  J := TJitParser.Create(nil);
  try
    X := 0;
    J.AddVariable('x', X);
    Note := '';
    Value := 0;
    try
      Value := J.AsDouble('Sqrt(0 - 1)');
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('AsDouble: no exception', Note = '', Note);
    Check('AsDouble: the answer is NaN', IsNan(Value), Format('%g', [Value]));
    Check('AsDouble: the host mask is back', GetExceptionMask = HostMask,
      MaskText(GetExceptionMask));
    Note := '';
    Value := 0;
    Script := nil;
    J.StringToScript('Sqrt(x - 1)', Script);
    J.OptimizeScript(Script);
    Held := J.CompileScript(Script);
    try
      Check('held script: prepared', Held.Ready, Held.Reason);
      try
        Value := Held.Execute;
      except
        on E: Exception do Note := E.ClassName + ': ' + E.Message;
      end;
      Check('held script: no exception', Note = '', Note);
      Check('held script: the answer is NaN', IsNan(Value), Format('%g', [Value]));
      Check('held script: the host mask is back', GetExceptionMask = HostMask,
        MaskText(GetExceptionMask));
    finally
      Held.Free;
    end;
    SetLength(Inputs, 3);
    SetLength(Outputs, 3);
    Inputs[0] := 0;
    Inputs[1] := 3;
    Inputs[2] := 4;
    Outputs[0] := 0;
    Outputs[1] := 0;
    Outputs[2] := 0;
    Note := '';
    Done := False;
    try
      Done := J.ExecuteMany('Sqrt(x - 3)', X, Inputs, Outputs);
      if not Done then Note := 'the set was not evaluated';
    except
      on E: Exception do Note := E.ClassName + ': ' + E.Message;
    end;
    Check('bulk: no exception', Note = '', Note);
    Check('bulk: the special point gave NaN', IsNan(Outputs[0]), Format('%g', [Outputs[0]]));
    Check('bulk: the other points were evaluated',
      (Abs(Outputs[1]) < 1E-9) and (Abs(Outputs[2] - 1) < 1E-9),
      Format('%g %g', [Outputs[1], Outputs[2]]));
    Check('bulk: the host mask is back', GetExceptionMask = HostMask, MaskText(GetExceptionMask));
    Check('bulk: the host variable did not drift to a special value',
      not (IsInfinite(X) or IsNan(X)), Format('%g', [X]));
  finally
    J.Free;
  end;
end;

procedure PreparationRunsUnderTheHostMask;
var
  J: TJitParser;
  Script: TScript;
  Note, Stage: string;

  procedure Walk(const Tag: string; const Plain: Boolean);
  begin
    Script := nil;
    Note := '';
    Stage := 'parse';
    try
      try
        if Plain then
        begin
          P.StringToScript('1 / 0', Script);
          Stage := 'optimize';
          P.OptimizeScript(Script);
        end
        else begin
          J.StringToScript('1 / 0', Script);
          Stage := 'optimize';
          J.OptimizeScript(Script);
        end;
        Stage := 'preparation went through';
      except
        on E: Exception do Note := E.ClassName;
      end;
    finally
      Check(Tag + ': the folding raised at the optimize stage',
        (Stage = 'optimize') and (Note <> ''), Stage + ' ' + Note);
      Check(Tag + ': the host mask was not touched by it',
        GetExceptionMask = HostMask, MaskText(GetExceptionMask));
    end;
  end;

begin
  BeginSection('the preparation of a script runs under the host mask');
  J := TJitParser.Create(nil);
  try
    Walk('ordinary parser', True);
    Walk('accelerator', False);
  finally
    J.Free;
  end;
end;

begin
  try
    SetExceptionMask(HostMask);
    P := TMathParser.Create(nil);
    Holder := THolder.Create;
    try
      P.AddFunction('inner', InnerHandle, fkMethod, MakeFunctionMethod(Holder.Inner, 1, pkValue), False);
      LivingParserDoesNotHoldTheMask;
      FormulaKeepsItsContract;
      ForeignThreadGetsTheNumber;
      NestedParserInstallsItsOwnMask;
      EveryEntryKeepsTheContract;
      PreparationRunsUnderTheHostMask;
    finally
      P.Free;
      Holder.Free;
    end;
    Check('after the parser is freed the host mask is unchanged', GetExceptionMask = HostMask,
      MaskText(GetExceptionMask));
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  for I := 0 to RunnerCount - 1 do Runners[I].Free;
  Halt(TestSummary);
end.
