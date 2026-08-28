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
  Classes, DesignIntf, BlobManager, Calculator, Connector, ExactTimer, ParseJit.Parser,
  ParseManager, ParseValueList, Parser, SyncThread;

{$R CrossPascalIcons.dcr}

const
  Palette = 'CrossPascal';

procedure Register;
begin
  ForceDemandLoadState(dlDisable);
  RegisterComponents(Palette, [TParser, TMathParser, TJitParser, TCalculator]);
  RegisterComponents(Palette, [TParseValueList, TParseManager, TConnector]);
  RegisterComponents(Palette, [TCalcThread, TSyncThread, TSyncTimer, TExactTimer]);
  RegisterComponents(Palette, [TBlobManager]);
end;

end.
