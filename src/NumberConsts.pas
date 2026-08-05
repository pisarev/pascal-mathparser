{ ************************************************************************** }
{                                                                            }
{ NumberConsts                                                               }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit NumberConsts;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses SysUtils, TextConsts, Types;

type
  TNumberType = (ntZero, ntOne, ntTwo, ntThree, ntFour, ntFive, ntSix, ntSeven,
    ntEight, ntNine);
  TNumberTypeSet = set of TNumberType;

  TCharFlag = (ifA, ifB, ifC, ifD, ifE, ifF, ifG, ifH, ifI, ifJ, ifK, ifL, ifM,
    ifN, ifO, ifP, ifQ, ifR, ifS, ifT, ifU, ifV, ifW, ifX, ifY, ifZ);
  TCharFlagSet = set of TCharFlag;

const
  NumberChar: array[TNumberType] of Char = '0123456789';
  LCaseIndexChar: array[TCharFlag] of Char = 'abcdefghijklmnopqrstuvwxyz';
  UCaseIndexChar: array[TCharFlag] of Char = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  Quecca = 1E30;
  Ronna = 1E27;
  Yotta = 1E24;
  Zetta = 1E21;
  Exa = 1E18;
  Peta = 1E15;
  Tera = 1E12;
  Giga = 1E9;
  Mega = 1E6;
  Kilo = 1E3;
  Hecto = 1E2;
  Deca = 1E1;
  Deci = 1E-1;
  Centi = 1E-2;
  Milli = 1E-3;
  Micro = 1E-6;
  Nano = 1E-9;
  Pico = 1E-12;
  Femto = 1E-15;
  Atto = 1E-18;
  Zepto = 1E-21;
  Yocto = 1E-24;
  Ronto = 1E-27;
  Quecto = 1E-30;
  Zero = Ord(ntZero);
  One = Ord(ntOne);
  Two = Ord(ntTwo);
  Three = Ord(ntThree);
  Four = Ord(ntFour);
  Five = Ord(ntFive);
  Six = Ord(ntSix);
  Seven = Ord(ntSeven);
  Eight = Ord(ntEight);
  Nine = Ord(ntNine);
  Kilobyte: LongWord = 1024;
  Megabyte: LongWord = 1048576;
  Gigabyte: LongWord = 1073741824;
  Terabyte: Int64 = 1099511627776;
  Petabyte: Int64 = 1125899906842624;

const
  Operators: TSysCharSet = [Plus, Minus];
  Digits: TSysCharSet = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

implementation

{$IFNDEF UNICODE}
uses
  TextUtils;
{$ENDIF}

end.
