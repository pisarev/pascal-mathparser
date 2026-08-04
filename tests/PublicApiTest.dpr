{ ************************************************************************** }
{                                                                            }
{ PublicApiTest                                                              }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }
program PublicApiTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads,{$ENDIF}{$ENDIF}
  SysUtils,
  BaseTypes,
  Parser,
  ParseTypes,
  ValueTypes,
  ValueUtils,
  TestKit in 'TestKit.pas';

{
  What this file guards.

  The library is compiled once and used from outside, and the two sides do not
  see the same types. On Delphi 12 and later BaseTypes redeclares NativeInt as a
  distinct type, so a caller who writes Handle: NativeInt using the plain system
  type cannot call AddFunction at all: the var parameter refuses it and the
  compiler reports only that no overload matches. Nothing inside the library ever
  hits this, because inside the library NativeInt already means the library's
  type. Naming the type explicitly does not help either: BaseTypes.NativeInt does
  not exist under FPC, where the redeclaration is switched off.

  The portable answer is TFunctionHandle from ParseTypes, and this test is what
  keeps it portable: it is built by Delphi win32, Delphi win64, FPC/Windows and
  FPC/Linux, so a type that works on only one of them fails here.

  So this test is written the way a stranger writes code: it registers its own
  function and its own variable through the public surface, exactly as the README
  tells them to. If the public surface stops being callable from outside, this
  file stops compiling, which is the point.
}

type
  TPricing = class
    function Discount(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
    function Double_(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

function TPricing.Discount(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Result := MakeDouble(GetDouble(PA[0].Value) * (1 - GetDouble(PA[1].Value) / 100));
end;

function TPricing.Double_(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Result := MakeDouble(GetDouble(PA[0].Value) * 2);
end;

procedure OwnFunctionOfTwoArguments;
var
  P: TMathParser;
  Pricing: TPricing;
  Handle: TFunctionHandle;
  Rate: Double;
begin
  BeginSection('a function of two arguments, registered from outside');
  P := TMathParser.Create(nil);
  Pricing := TPricing.Create;
  try
    { A function called with brackets takes TMethod3 and a parameter count.
      TMethod2 is for binary operators, not for f(a, b), and using it here gives
      a formula that parses and then fails at evaluation. }
    Check('registration was accepted',
      P.AddFunction('discount', Handle, fkMethod, MakeFunctionMethod(Pricing.Discount, 2, pkValue), False));
    Check('the handle was filled in', Handle <> 0, Format('  handle=%d', [Handle]));

    P.AddVariable('rate', Rate);
    Rate := 20;
    CheckDouble('the function is called with both arguments', P.AsDouble('discount(1000, rate)'), 800);

    Rate := 50;
    CheckDouble('the variable is read at evaluation, not at registration', P.AsDouble('discount(1000, rate)'), 500);

    CheckDouble('it composes with the built-ins', P.AsDouble('discount(1000, rate) / 2 + 1'), 251);
  finally
    Pricing.Free;
    P.Free;
  end;
end;

procedure OwnFunctionOfOneArgument;
var
  P: TMathParser;
  Pricing: TPricing;
  Handle: TFunctionHandle;
begin
  BeginSection('a function of one argument');
  P := TMathParser.Create(nil);
  Pricing := TPricing.Create;
  try
    Check('registration was accepted', P.AddFunction('twice', Handle, fkMethod, MakeFunctionMethod(Pricing.Double_, 1, pkValue), False));
    CheckDouble('it answers', P.AsDouble('twice(21)'), 42);
    CheckDouble('it nests', P.AsDouble('twice(twice(3))'), 12);
  finally
    Pricing.Free;
    P.Free;
  end;
end;

procedure VariablesAreBoundByAddress;
var
  P: TMathParser;
  X: Double;
  N: Integer;
  Flag: Boolean;
begin
  BeginSection('variables are bound by address');
  P := TMathParser.Create(nil);
  try
    P.AddVariable('x', X);
    P.AddVariable('n', N);
    P.AddVariable('flag', Flag);

    X := 2.5;
    N := 4;
    Flag := True;
    CheckDouble('a Double is read live', P.AsDouble('x * 2'), 5);
    CheckDouble('an Integer is read live', P.AsDouble('n + 1'), 5);
    Check('a Boolean is read live', P.AsBoolean('flag'));

    X := 10;
    N := 40;
    Flag := False;
    CheckDouble('changing the Double changes the answer', P.AsDouble('x * 2'), 20);
    CheckDouble('changing the Integer changes the answer', P.AsDouble('n + 1'), 41);
    Check('changing the Boolean changes the answer', not P.AsBoolean('flag'));
  finally
    P.Free;
  end;
end;

procedure NamesIgnoreCase;
var
  P: TMathParser;
  Rate, Other: Double;
begin
  BeginSection('names ignore case, both built-in and registered');
  P := TMathParser.Create(nil);
  try
    P.AddVariable('Rate', Rate);
    Rate := 3;
    CheckDouble('the registered spelling works', P.AsDouble('Rate + 1'), 4);
    CheckDouble('lower case reaches the same variable', P.AsDouble('rate + 1'), 4);
    CheckDouble('upper case reaches the same variable', P.AsDouble('RATE + 1'), 4);

    { Case does not separate two names, so the second registration is refused
      rather than shadowing the first. The README used to claim the opposite. }
    Check('a name differing only in case cannot be registered twice', not P.AddVariable('rate', Other));
    CheckDouble('the first variable is untouched', P.AsDouble('rate'), 3);

    CheckDouble('a built-in answers in lower case', P.AsDouble('sin(0)'), 0);
    CheckDouble('and in mixed case', P.AsDouble('Sin(0)'), 0);
  finally
    P.Free;
  end;
end;

procedure UnknownNamesAreRefused;
var
  P: TMathParser;
  Failed: Boolean;
begin
  BeginSection('an unknown name is refused, not guessed');
  P := TMathParser.Create(nil);
  try
    Failed := False;
    try
      P.AsDouble('nosuchfunction(1)');
    except
      on E: Exception do Failed := True;
    end;
    Check('an unregistered function raises', Failed);

    Failed := False;
    try
      P.AsDouble('nosuchvariable + 1');
    except
      on E: Exception do Failed := True;
    end;
    Check('an unregistered variable raises', Failed);
  finally
    P.Free;
  end;
end;

begin
  Writeln('=== the public surface, used the way a stranger uses it ===');
  OwnFunctionOfTwoArguments;
  OwnFunctionOfOneArgument;
  VariablesAreBoundByAddress;
  NamesIgnoreCase;
  UnknownNamesAreRefused;
  ExitCode := TestSummary;
end.
