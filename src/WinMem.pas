{ ************************************************************************** }
{                                                                            }
{ WinMem                                                                     }
{                                                                            }
{ Copyright © 2024 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit WinMem;

{$mode ObjFPC}
{$H+}
{$B-}

interface

procedure MoveMemory(Destination: Pointer; Source: Pointer; Length: NativeUInt);
procedure CopyMemory(Destination: Pointer; Source: Pointer; Length: NativeUInt);
procedure FillMemory(Destination: Pointer; Length: NativeUInt; Fill: Byte);
procedure ZeroMemory(Destination: Pointer; Length: NativeUInt);

implementation

uses Classes, SysUtils;

procedure MoveMemory(Destination, Source: Pointer; Length: NativeUInt);
begin
  Move(Source^, Destination^, Length);
end;

procedure CopyMemory(Destination, Source: Pointer; Length: NativeUInt);
begin
  Move(Source^, Destination^, Length);
end;

procedure FillMemory(Destination: Pointer; Length: NativeUInt; Fill: Byte);
begin
  FillChar(Destination^, Length, Fill);
end;

procedure ZeroMemory(Destination: Pointer; Length: NativeUInt);
begin
  FillChar(Destination^, Length, 0);
end;

end.
