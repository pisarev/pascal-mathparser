{ ************************************************************************** }
{                                                                            }
{ ParseErrors                                                                }
{                                                                            }
{ Copyright © 2006 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseErrors;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, ValueTypes;
  {$ELSE}
  {$IFDEF DELPHI_XE7}
  System.SysUtils, ValueTypes;
  {$ELSE}
  SysUtils, ValueTypes;
  {$ENDIF}
  {$ENDIF}

type
  EParserExit = class(Exception)
  private
    FValue: TValue;
  public
    constructor Create(const AValue: TValue);
    property Value: TValue read FValue;
  end;

  TErrorType = (
    etOK,
    etUnknown,
    etNotImplementedError,
    etAMutualExcessError,
    etBMutualExcessError,
    etBracketError,
    etEmptyTextError,
    etFunctionHandleError,
    etFunctionExpectError,
    etElementError,
    etRExcessError,
    etLTextExcessError,
    etLTextExpectError,
    etDefinitionError,
    etAParamExcessError,
    etBParamExcessError,
    etAParamExpectError,
    etBParamExpectError,
    etReserveError,
    etRTextExcessError,
    etRTextExpectError,
    etScriptError,
    etStringError,
    etStringTypeError,
    etNumberTypeError,
    etFunctionTypeError,
    etScriptTypeError,
    etTextError,
    etTypeError,
    etSizeError);

  PError = ^TError;
  TError = record
    ErrorType: TErrorType;
    ErrorText: string;
  end;

  EParserError = class(Exception);

const
  ErrorMessage = '%s: "%s"';
  NotImplementedError = 'Not implemented: %s';
  AMutualExcessError = 'Function "%s" requires expression after itself, function "%s" requires expression before itself';
  BMutualExcessError = 'Function "%s" does not require expression after itself, function "%s" does not require expression before itself';
  BracketError = 'Bracket character expected';
  EmptyTextError = 'Empty text';
  FunctionHandleError = 'Function handle error: "%s"';
  FunctionExpectError = 'Function expected: "%s"';
  ElementError = 'Unknown element: "%s"';
  RExcessError = '"%s" does not require expression after itself';
  LTextExcessError = 'Function "%s" does not require expression before itself';
  LTextExpectError = 'Function "%s" requires expression before itself';
  DefinitionError = '"%s" cannot start with a number';
  AParamExcessError = 'Function "%s" does not require parameters';
  BParamExcessError = 'Too much parameters for function "%s"';
  AParamExpectError = 'Function "%s" requires parameters';
  BParamExpectError = 'Not enough parameters for function "%s"';
  ReserveError = 'Text "%s" contains reserved character: "%s"';
  RTextExcessError = 'Function "%s" does not require expression after itself';
  RTextExpectError = 'Function "%s" requires expression after itself';
  ScriptError = 'Script error';
  StringError = '"%s" cannot be the part of math expression';
  StringTypeError = '"%s" cannot have type of string';
  NumberTypeError = 'Cannot apply "%s" type to "%s" number in "%s" expression';
  FunctionTypeError = 'Cannot apply "%s" type to "%s" function in "%s" expression';
  ScriptTypeError = 'Cannot apply "%s" type to "%s" script in "%s" expression';
  TypeError = 'Type error';
  TextError = 'Expression expected: "%s"';
  SizeError = 'Incomplete expression';
  LoopBreakError = 'Calculation stopped: "%s"';
  LoopLimitError = 'Loop limit reached: "%s"';

function MakeError(const AErrorType: TErrorType; const AErrorText: string): TError;
function Error(const Message: string): Exception; overload;
function EText(const Message: string; const Arguments: array of const): string; overload;
function Error(const Message: string; const Arguments: array of const): Exception; overload;
function Error(const Text, Message: string): Exception; overload;
function EText(const Text, Message: string; const Arguments: array of const): string; overload;
function Error(const Text, Message: string; const Arguments: array of const): Exception; overload;

implementation

constructor EParserExit.Create(const AValue: TValue);
begin
  inherited Create('script exit');
  FValue := AValue;
end;

function MakeError(const AErrorType: TErrorType; const AErrorText: string): TError;
begin
  FillChar(Result, SizeOf(TError), 0);
  with Result do
  begin
    ErrorType := AErrorType;
    ErrorText := AErrorText;
  end;
end;

function Error(const Message: string): Exception;
begin
  Result := Error(Message, []);
end;

function EText(const Message: string; const Arguments: array of const): string;
begin
  Result := Format(Message, Arguments);
end;

function Error(const Message: string; const Arguments: array of const): Exception;
begin
  Result := EParserError.Create(EText(Message, Arguments));
end;

function Error(const Text, Message: string): Exception;
begin
  Result := Error(Text, Message, []);
end;

function EText(const Text, Message: string; const Arguments: array of const): string;
begin
  Result := Format(ErrorMessage, [Format(Message, Arguments), Text]);
end;

function Error(const Text, Message: string; const Arguments: array of const): Exception;
begin
  Result := Error(EText(Text, Message, Arguments));
end;
end.
