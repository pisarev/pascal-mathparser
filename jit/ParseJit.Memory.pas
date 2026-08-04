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

{$ENDIF}

end.
