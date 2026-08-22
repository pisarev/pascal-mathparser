{ ************************************************************************** }
{                                                                            }
{ JitDump                                                                    }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program JitDump;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Decoder, TestKit in 'TestKit.pas';

var
  P: TMathParser;
  XVar, YVar: Double;
  Decoder: TJitDecoder;

procedure DecodeCase(const Formula: string; const Show: Boolean);
var
  Script: TScript;
begin
  try
    P.StringToScript(Formula, Script);
    if Decoder.Decode(Script) then
    begin
      Check('decoded: ' + Formula, True);
      if Show then
      begin
        Writeln;
        Writeln('  ', Formula, '   (', Decoder.ScriptSize, ' bytes, ', Decoder.Count,
          ' ops, depth ', Decoder.MaxDepth, ', calls ', Decoder.CallCount, ', vars ',
          Decoder.VariableCount, ')');
        Write(Decoder.Dump);
        Flush(Output);
      end;
    end
    else
      Fail('decoded: ' + Formula, Decoder.Reason);
    Script := nil;
  except
    on E: Exception do Fail('decoded: ' + Formula, E.ClassName + ': ' + E.Message);
  end;
end;

var
  Failed: Integer;

begin
  P := TMathParser.Create(nil);
  Decoder := TJitDecoder.Create(P);
  try
    XVar := 2.5;
    YVar := 4;
    P.AddVariable('x', XVar);
    P.AddVariable('y', YVar);
    BeginSection('IR dump (representative scripts)');
    DecodeCase('2 + 2 * 2', True);
    DecodeCase('x * 2 + 1', True);
    DecodeCase('sin(x) + sqrt(y)', True);
    DecodeCase('if(x > 0, x * 2, 0 - x)', True);
    DecodeCase('set("bi", 0) + while(get("bi") < 3, set("bi", get("bi") + 1))', True);
    DecodeCase('get("bi")', True);
    DecodeCase('x > 1', True);
    BeginSection('IR coverage (must decode everything)');
    DecodeCase('42', False);
    DecodeCase('-42', False);
    DecodeCase('1 + 2 - 3 + 4', False);
    DecodeCase('(1 + 2) * (3 + 4)', False);
    DecodeCase('2 ** 3 ** 2', False);
    DecodeCase('8 // 3', False);
    DecodeCase('x * x * x * 3 + x * x * 2 + x * 7 + 11', False);
    DecodeCase('sin(x) * cos(x) + sqrt(x) + exp(x * 0.001) + ln(x + 1)', False);
    DecodeCase('mean(1, 2, 3, 4, 5)', False);
    DecodeCase('max(x, y)', False);
    DecodeCase('1 + 2 > 2', False);
    DecodeCase('1 and 1 or 0', False);
    DecodeCase('x bxor 0', False);
    DecodeCase('x || 0', False);
    DecodeCase('Integer x + 1', False);
    DecodeCase('strtofloat("2.5") + 1', False);
    DecodeCase('ifthen(1, 2, 3)', False);
    DecodeCase('tryexcept(1 / 1, 0)', False);
    DecodeCase('new("jv", 7) + get("jv")', False);
    DecodeCase('for("fi", 1, 3, get("fi"))', False);
    DecodeCase('repeat(set("jv", get("jv") + 1), get("jv") > 8)', False);
    DecodeCase('parse("2 + 3")', False);
    DecodeCase('deriv("x ** 2", "x")', False);
    DecodeCase('exit(5) + 1', False);
    DecodeCase('random(10) + 1', False);
    DecodeCase('poly(2, 1, 2, 3)', False);
    DecodeCase('pi * 2', False);
    DecodeCase('MaxNativeInt - 1', False);
    DecodeCase('encodedate(2026, 7, 20)', False);
    DecodeCase('roundto(x, -2)', False);
    Failed := TestSummary;
  finally
    Decoder.Free;
    P.Free;
  end;
  if Failed > 0 then System.ExitCode := 1;
end.
