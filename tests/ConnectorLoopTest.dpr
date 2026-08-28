{ ************************************************************************** }
{                                                                            }
{ ConnectorLoopTest                                                          }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ConnectorLoopTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, Classes, Notifier, Connector, TestKit in 'TestKit.pas';

{
  What this file guards.

  A LOOP IN THE CHAIN OF LINKS. A Connector links to another Connector, and the
  chain runs longer than one step: Parser - C1 - C2 - ParseValueList, which is a
  working arrangement. Until August 2026 nothing forbade closing it: C1.Connector
  := C2 and C2.Connector := C1 were both accepted in silence, and the search for
  a parser along the chain went round and never ended. Found by the owner on a
  form in Lazarus: the IDE hung on the second assignment.

  There are two guards now, and they are of DIFFERENT kinds, because one of them
  can be talked past:

    the ban on a link       SetConnector refuses when the value already leads
                            back here;
    a walk that ends on     GetRemoteParser moves two pointers and ends even
    any chain               where the loop was built past the ban.

  The second one is not decoration: Connector is declared on the ancestor as a
  TComponent written straight into the field, so a chain can be closed with a
  type cast that never reaches the setter. That is what happens below - without
  it the second guard would not be checked at all.
}

type
  TWalk = class(TThread)
  private
    FSource: TConnector;
  public
    Walked: Boolean;
    constructor Create(const Source: TConnector);
    procedure Execute; override;
  end;

constructor TWalk.Create(const Source: TConnector);
begin
  FSource := Source;
  Walked := False;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TWalk.Execute;
begin
  FSource.RemoteParser;
  Walked := True;
end;

procedure ChainAndLoop;
var
  Owner: TComponent;
  A, B: TConnector;
  Refused: Boolean;
  Reason: string;
begin
  BeginSection('the chain of links');
  Owner := TComponent.Create(nil);
  try
    A := TConnector.Create(Owner);
    A.Name := 'A';
    B := TConnector.Create(Owner);
    B.Name := 'B';
    A.Connector := B;
    Check('a direct link is accepted', A.Connector = B);
    Refused := False;
    Reason := '';
    try
      B.Connector := A;
    except
      on E: Exception do
      begin
        Refused := True;
        Reason := E.ClassName + ': ' + E.Message;
      end;
    end;
    Check('closing the chain is refused', Refused, Reason);
    Check('after the refusal the link stayed empty', B.Connector = nil);
    A.Connector := A;
    Check('a link to itself was not accepted', A.Connector <> A);
  finally
    Owner.Free;
  end;
end;

procedure WalkEnds;
var
  Owner: TComponent;
  A, B: TConnector;
  Walk: TWalk;
  T0: Int64;
begin
  BeginSection('the walk over a closed chain');
  Owner := TComponent.Create(nil);
  A := TConnector.Create(Owner);
  A.Name := 'A';
  B := TConnector.Create(Owner);
  B.Name := 'B';
  A.Connector := B;

  { The loop is built with a type cast, past the ban: that is what puts the SECOND guard under test. }
  TCustomAddressee(B).Connector := A;
  Walk := TWalk.Create(A);
  T0 := Now64;
  while (not Walk.Walked) and (Elapsed(T0) < 5) do
    Sleep(10);
  Check('the walk ended instead of going round', Walk.Walked,
    Format('waited %.1f s', [Elapsed(T0)]));
  { A walk that never ended holds the thread and the owner; freeing them then
    is not allowed, and the process ends on Halt anyway. }
  if Walk.Walked then
  begin
    Walk.WaitFor;
    Walk.Free;
    Owner.Free;
  end;
end;

begin
  ChainAndLoop;
  WalkEnds;
  Halt(TestSummary);
end.
