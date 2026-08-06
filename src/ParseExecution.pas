{ ************************************************************************** }
{                                                                            }
{ ParseExecution                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseExecution;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  PExecuteFrame = ^TExecuteFrame;

  TExecuteFrame = record
    Previous: PExecuteFrame;
    Parser: TObject;
  end;

threadvar
  CurrentExecuteFrame: PExecuteFrame;

function CurrentParserOf(const AFrame: PExecuteFrame): TObject;
function HasExecuteFrame(const AParser: TObject; AFrame: PExecuteFrame): Boolean;

implementation

function CurrentParserOf(const AFrame: PExecuteFrame): TObject;
begin
  if Assigned(AFrame) then
    Result := AFrame.Parser
  else
    Result := nil;
end;

function HasExecuteFrame(const AParser: TObject; AFrame: PExecuteFrame): Boolean;
begin
  while Assigned(AFrame) do
  begin
    if AFrame.Parser = AParser then Exit(True);
    AFrame := AFrame.Previous;
  end;
  Result := False;
end;

end.
