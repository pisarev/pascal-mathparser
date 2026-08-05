{ ************************************************************************** }
{                                                                            }
{ ParseJit.Memory                                                            }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseJit.Memory;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

function AllocCode(const Size: NativeInt): Pointer;

function ProtectCode(const Address: Pointer; const Size: NativeInt): Boolean;

procedure FreeCode(const Address: Pointer; const Size: NativeInt);

function DescribeCode(const Address: Pointer;
  const Size, CodeSize, FrameSize, PrologSize: NativeInt): Boolean;

procedure ForgetCode(const Address: Pointer; const CodeSize: NativeInt);

const
  UnwindReserve = 32;

implementation

uses
  {$IFDEF MSWINDOWS}
  {$IFDEF FPC}Windows;{$ELSE}WinApi.Windows;{$ENDIF}
  {$ELSE}
  BaseUnix;
  {$ENDIF}

{$IFDEF MSWINDOWS}

function AllocCode(const Size: NativeInt): Pointer;
begin
  Result := VirtualAlloc(nil, Size, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
end;

function ProtectCode(const Address: Pointer; const Size: NativeInt): Boolean;
var
  Previous: LongWord;
begin
  Result := VirtualProtect(Address, Size, PAGE_EXECUTE_READ, @Previous);
  if Result then FlushInstructionCache(GetCurrentProcess, Address, Size);
end;

procedure FreeCode(const Address: Pointer; const Size: NativeInt);
begin
  VirtualFree(Address, 0, MEM_RELEASE);
end;

{$IFDEF CPUX64}

const
  UnwindVersion = 1;
  UnwindNoFrameRegister = 0;
  UnwindCodeCount = 2;
  UwopAllocLarge = 1;
  UwopAllocLargeSmallOperand = 0;
  UnwindInfoSize = 8;
  MaxLargeAllocation = 512 * 1024 - 8;
  StackAlignment = 8;

type
  TRuntimeFunction = packed record
    BeginAddress: LongWord;
    EndAddress: LongWord;
    UnwindData: LongWord;
  end;
  PRuntimeFunction = ^TRuntimeFunction;

function RtlAddFunctionTable(FunctionTable: PRuntimeFunction; EntryCount: LongWord;
  BaseAddress: NativeUInt): ByteBool; stdcall;
  external 'kernel32.dll';
function RtlDeleteFunctionTable(FunctionTable: PRuntimeFunction): ByteBool;
  stdcall; external 'kernel32.dll';

function UnwindAt(const CodeSize: NativeInt): NativeInt;
begin
  Result := (CodeSize + 3) and not 3;
end;

function DescribeCode(const Address: Pointer;
  const Size, CodeSize, FrameSize, PrologSize: NativeInt): Boolean;
var
  Info: PByte;
  Entry: PRuntimeFunction;
  At: NativeInt;
begin
  Result := False;
  if (FrameSize <= 0) or (FrameSize mod StackAlignment <> 0) then Exit;
  if FrameSize > MaxLargeAllocation then Exit;
  if (PrologSize <= 0) or (PrologSize > High(Byte)) then Exit;
  At := UnwindAt(CodeSize);
  if At + UnwindReserve > Size then Exit;
  Info := PByte(Address) + At;
  Info[0] := UnwindVersion;
  Info[1] := PrologSize;
  Info[2] := UnwindCodeCount;
  Info[3] := UnwindNoFrameRegister;
  Info[4] := PrologSize;
  Info[5] := UwopAllocLarge or (UwopAllocLargeSmallOperand shl 4);
  PWord(Info + 6)^ := FrameSize div StackAlignment;
  Entry := PRuntimeFunction(Info + UnwindInfoSize);
  Entry.BeginAddress := 0;
  Entry.EndAddress := CodeSize;
  Entry.UnwindData := At;
  Result := RtlAddFunctionTable(Entry, 1, NativeUInt(Address));
end;

procedure ForgetCode(const Address: Pointer; const CodeSize: NativeInt);
begin
  if Assigned(Address) then
    RtlDeleteFunctionTable(PRuntimeFunction(PByte(Address) + UnwindAt(CodeSize) + UnwindInfoSize));
end;

{$ELSE}

function DescribeCode(const Address: Pointer;
  const Size, CodeSize, FrameSize, PrologSize: NativeInt): Boolean;
begin
  Result := True;
end;

procedure ForgetCode(const Address: Pointer; const CodeSize: NativeInt);
begin
end;

{$ENDIF}

{$ELSE}

function AllocCode(const Size: NativeInt): Pointer;
begin
  Result := Fpmmap(nil, Size, PROT_READ or PROT_WRITE, MAP_PRIVATE or MAP_ANONYMOUS, -1, 0);
  if Result = Pointer(-1) then Result := nil;
end;

function ProtectCode(const Address: Pointer; const Size: NativeInt): Boolean;
begin
  Result := Fpmprotect(Address, Size, PROT_READ or PROT_EXEC) = 0;
end;

procedure FreeCode(const Address: Pointer; const Size: NativeInt);
begin
  Fpmunmap(Address, Size);
end;

function DescribeCode(const Address: Pointer;
  const Size, CodeSize, FrameSize, PrologSize: NativeInt): Boolean;
begin
  Result := True;
end;

procedure ForgetCode(const Address: Pointer; const CodeSize: NativeInt);
begin
end;

{$ENDIF}

end.
