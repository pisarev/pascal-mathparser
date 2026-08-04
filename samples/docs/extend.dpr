{ ************************************************************************** }
{                                                                            }
{ extend                                                                     }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program Extend;

{ expect: 800.00 }
{$APPTYPE CONSOLE}

uses
  ParseTypes, ValueTypes, ValueUtils, Parser;

type
  TPricing = class
    function Discount(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

function TPricing.Discount(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Result := MakeDouble(GetDouble(PA[0].Value) * (1 - GetDouble(PA[1].Value) / 100));
end;

var
  P: TMathParser;
  Pricing: TPricing;
  Handle: TFunctionHandle;
  Rate: Double;
begin
  P := TMathParser.Create(nil);
  Pricing := TPricing.Create;
  try
    P.AddFunction('discount', Handle, fkMethod, MakeFunctionMethod(Pricing.Discount, 2, pkValue), False);

    P.AddVariable('rate', Rate);
    Rate := 20;
    Writeln(P.AsDouble('discount(1000, rate)'):0:2);
  finally
    Pricing.Free;
    P.Free;
  end;
end.
