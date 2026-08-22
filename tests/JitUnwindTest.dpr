{ ************************************************************************** }
{                                                                            }
{ JitUnwindTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program JitUnwindTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  SysUtils, Math, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Parser, TestKit in 'TestKit.pas';

{
  What this file guards: that the stack can be unwound through a frame of
  machine code the engine wrote at run time.

  Win64 does not walk frames by guesswork. For every function in an image there
  is a record describing its prologue, and the unwinder reads that record - it
  never inspects the instructions. Code produced at run time has no such record
  from anywhere, so the system treats it as a LEAF function: it assumes the
  stack pointer never moved and the return address sits at RSP. Our frame opens
  with "sub rsp, N", so the assumption is wrong, the unwinder walks off into
  rubbish, and no handler is ever found.

  What that was in practice, not in theory. An exception raised inside a
  function called from the machine code was NOT caught by the try..except
  around it: the process died with code 0EEDFADE without finishing the line it
  was printing. Demonstrated on 05.08.2026 by making Sqrt raise and computing
  Sqrt(x) through the accelerator; the same probe passes once the record is
  registered.

  The checks below are two, and they are deliberately of different kinds.

  The first asks Windows itself: given the address of our code, does it find a
  description for it? That check speaks about the mechanism and can only be
  answered by the system.

  The second raises for real and requires the answer to come back. It uses the
  only thing in this engine that can raise from inside the frame without any
  help: division by zero with the floating point exceptions unmasked. The
  parser masks them on purpose - that is why NaN comes out of the demo instead
  of an error - so the mask is lifted here and put back afterwards.
}

var
  P: TJitParser;
  X: TValue;

{$IFDEF MSWINDOWS}
{$IFDEF CPUX64}
type
  PRuntimeFunctionRec = ^TRuntimeFunctionRec;
  TRuntimeFunctionRec = packed record
    BeginAddress: LongWord;
    EndAddress: LongWord;
    UnwindData: LongWord;
  end;

function RtlLookupFunctionEntry(ControlPc: NativeUInt; var ImageBase: NativeUInt;
  HistoryTable: Pointer): PRuntimeFunctionRec; stdcall; external 'kernel32.dll';
{$ENDIF}
{$ENDIF}

function Compile(const Text: string): TJitScript;
var
  Script: TScript;
begin
  Script := nil;
  P.StringToScript(Text, Script);
  Result := P.CompileScript(Script);
end;

procedure WindowsFindsTheDescription;
{$IFDEF MSWINDOWS}{$IFDEF CPUX64}
var
  Code: TJitScript;
  Base: NativeUInt;
  Entry: PRuntimeFunctionRec;
  Info: PByte;
{$ENDIF}{$ENDIF}
begin
  BeginSection('the system finds the frame description');
  {$IFDEF MSWINDOWS}{$IFDEF CPUX64}
  Code := Compile('Sqrt(x) + Sin(x)');
  Check('the formula was built as machine code', Code.Ready, Code.Reason);
  if not Code.Ready then Exit;
  Base := 0;
  Entry := RtlLookupFunctionEntry(NativeUInt(Code.Code.Address), Base, nil);
  Check('a description for our code was found', Assigned(Entry),
    'the system takes this code for a leaf function');
  if not Assigned(Entry) then Exit;
  Check(
    'the description points at the start of our code',
    Base + Entry.BeginAddress = NativeUInt(Code.Code.Address),
    Format(
      'base %x, begin %x, code %x',
      [
        Base,
        Entry.BeginAddress,
        NativeUInt(Code.Code.Address)
      ]
    )
  );
  Info := PByte(Base + Entry.UnwindData);
  Check('the description is version one', Info[0] and 7 = 1, Format('%d', [Info[0] and 7]));
  Check('one stack move is described', Info[2] = 2, Format('words %d', [Info[2]]));
  Check('the move is named as a large one', Info[5] and 15 = 1, Format('code %d', [Info[5] and 15]));
  Check('the frame depth is not zero', PWord(Info + 6)^ > 0, Format('eights %d', [PWord(Info + 6)^]));
  {$ELSE}
  Check('this check is for Windows x86-64 only', True, 'skipped');
  {$ENDIF}{$ENDIF}
end;

procedure ThrowingThroughTheFrameIsCaught;
var
  Code: TJitScript;
  Mask: TArithmeticExceptionMask;
  Value: Double;
  Caught, Alive: Boolean;
begin
  BeginSection('a throw through a frame of machine code is caught');
  {
    The formula deliberately has a CALL in it, not a division.

    Division by zero is raised inside our own frame, and that is caught even
    without an unwind description - proved by mutation: the description was
    removed and the check stayed green. The only thing that tells the two states
    apart is an exception raised DEEPER: then the unwinder has a return address
    to find, which it looks up in the description and, without one, takes from
    the wrong place.

    Sqrt of a negative number with the mask lifted raises inside the called
    function - exactly the case the process used to die on.
  }
  Code := Compile('Sqrt(x)');
  Check('the formula was built as machine code', Code.Ready, Code.Reason);
  if not Code.Ready then Exit;
  AssignDouble(X, -1);
  Caught := False;
  Alive := False;
  Value := 0;
  Mask := GetExceptionMask;
  try
    {
      The mask is lifted only for the experiment. The parser sets it in its
      constructor on purpose: without the mask a division by zero in a formula
      would be an error rather than an infinity, and the demo would answer with
      a refusal where it now simply lifts the pen.
    }
    SetExceptionMask(Mask - [exZeroDivide, exInvalidOp]);
    try
      Value := Code.Execute;
    except
      on E: Exception do Caught := True;
    end;
    Alive := True;
  finally
    SetExceptionMask(Mask);
  end;
  Check('a throw from a called function reached the handler', Caught,
    Format('there was no exception, it returned %g', [Value]));
  Check('the process is still running', Alive);
  { Under the mask nothing changed: not a number, rather than an error }
  Value := Code.Execute;
  Check('under the mask the answer is unchanged - not a number', IsNan(Value), Format('%g', [Value]));
end;

begin
  try
    P := TJitParser.Create(nil);
    try
      AssignDouble(X, 4);
      P.AddVariable('x', X);
      WindowsFindsTheDescription;
      ThrowingThroughTheFrameIsCaught;
    finally
      P.Free;
    end;
  except
    on E: Exception do Fail('the run', E.ClassName + ': ' + E.Message);
  end;
  Halt(TestSummary);
end.
