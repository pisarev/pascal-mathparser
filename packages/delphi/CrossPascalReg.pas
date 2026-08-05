{ ************************************************************************** }
{                                                                            }
{ CrossPascalReg                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit CrossPascalReg;

interface

procedure Register;

implementation

uses
  Classes, BlobManager, Calculator, Connector, ExactTimer, ParseManager, ParseValueList,
  Parser, SyncThread;

const
  Palette = 'CrossPascal';

procedure Register;
begin
  RegisterComponents(Palette, [TParser, TMathParser, TCalculator]);
  RegisterComponents(Palette, [TParseValueList, TParseManager, TConnector]);
  RegisterComponents(Palette, [TCalcThread, TSyncThread, TSyncTimer, TExactTimer]);
  RegisterComponents(Palette, [TBlobManager]);
end;
end.
