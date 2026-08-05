{ ************************************************************************** }
{                                                                            }
{ ZUtils                                                                     }
{                                                                            }
{ Copyright © 2005 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ZUtils;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes, ZStream, NumberConsts;
  {$ELSE}
  Windows, Classes, ZLib, NumberConsts;
  {$ENDIF}

const
  DataSize = 524288;

function CompressStream(const Source, Target: TStream; const Level: TCompressionLevel = clDefault): Single;
function Compress(const Stream: TStream; const Level: TCompressionLevel = clDefault): Single;
procedure DecompressStream(const Source, Target: TStream);
procedure Decompress(const Stream: TStream);

implementation

function CompressStream(const Source, Target: TStream; const Level: TCompressionLevel): Single;
var
  Z: TCompressionStream;
begin
  Z := TCompressionStream.Create(Level, Target);
  try
    Z.CopyFrom(Source, 0);
    Result := {$IFDEF FPC}Z.get_compressionrate{$ELSE}Z.CompressionRate{$ENDIF};
  finally
    Z.Free;
  end;
end;

function Compress(const Stream: TStream; const Level: TCompressionLevel): Single;
var
  Z: TMemoryStream;
begin
  Z := TMemoryStream.Create;
  try
    Result := CompressStream(Stream, Z, Level);
    Stream.Size := 0;
    Stream.CopyFrom(Z, 0);
  finally
    Z.Free;
  end;
end;

procedure DecompressStream(const Source, Target: TStream);
var
  Z: TDecompressionStream;
  P: Pointer;
  Count: Integer;
begin
  Source.Position := 0;
  Z := TDecompressionStream.Create(Source);
  try
    GetMem(P, DataSize);
    try
      repeat
        Count := Z.Read(P^, DataSize);
        Target.Write(P^, Count);
      until Count = 0;
    finally
      FreeMem(P);
    end;
  finally
    Z.Free;
  end;
end;

procedure Decompress(const Stream: TStream);
var
  Z: TMemoryStream;
begin
  Z := TMemoryStream.Create;
  try
    DecompressStream(Stream, Z);
    Stream.Size := 0;
    Stream.CopyFrom(Z, 0);
  finally
    Z.Free;
  end;
end;
end.
