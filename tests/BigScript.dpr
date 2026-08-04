{ ************************************************************************** }
{                                                                            }
{ BigScript                                                                  }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program BigScript;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Parser,
  ParseJit.Decoder, TestKit in 'TestKit.pas';

var
  P: TJitParser;
  X: Double;

procedure BigCase(const Terms: Integer);
var
  Formula: string;
  I: Integer;
  Script: TScript;
  Compiled: TJitScript;
  A, B: Double;
  Decoder: TJitDecoder;
  Ops: Integer;
begin
  Formula := 'x';
  for I := 1 to Terms do Formula := Formula + ' + x * ' + IntToStr(I);
  P.StringToScript(Formula, Script);
  Decoder := TJitDecoder.Create(P);
  try
    Decoder.Decode(Script);
    Ops := Decoder.Count;
  finally
    Decoder.Free;
  end;
  Compiled := P.CompileScript(Script);
  try
    A := GetDouble(P.ExecuteScript(Script)^);
    if not Compiled.Ready then
    begin
      Writeln(Format('terms=%d ops=%d -> tier-down [%s]', [Terms, Ops, Compiled.Reason]));
      Exit;
    end;
    B := Compiled.Execute;
    CheckDouble(Format('big script: %d terms (%d ops)', [Terms, Ops]), B, A, Abs(A) * 1E-12);
  finally
    Compiled.Free;
  end;
  Script := nil;
end;

var
  Failed: Integer;
begin
  P := TJitParser.Create(nil);
  try
    X := 1.5;
    P.AddVariable('x', X);
    BeginSection('Large scripts: stack frame stress');
    BigCase(10);
    BigCase(50);
    BigCase(200);
    BigCase(500);
    BigCase(1000);
    Failed := TestSummary;
  finally
    P.Free;
  end;
  if Failed > 0 then System.ExitCode := 1;
end.
