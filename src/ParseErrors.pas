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
    FOwnerParser: TObject;
    FValue: TValue;
  public
    constructor Create(const AValue: TValue); overload;
    constructor Create(const AOwnerParser: TObject; const AValue: TValue); overload;
    property OwnerParser: TObject read FOwnerParser;
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
    etNumberNameError,
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
  AMutualExcessError = 'Function "%s" expects a value on its right, and function "%s" expects a value on its left';
  BMutualExcessError = 'Function "%s" takes no value on its right, and function "%s" takes no value on its left';
  BracketError = 'A bracket is expected here';
  EmptyTextError = 'The expression is empty';
  FunctionHandleError = 'Invalid function handle: "%s"';
  FunctionExpectError = 'A function name is expected here: "%s"';
  ElementError = 'Unrecognized element: "%s"';
  RExcessError = '"%s" takes no value on its right';
  LTextExcessError = 'Function "%s" takes no value on its left';
  LTextExpectError = 'Function "%s" expects a value on its left';
  DefinitionError = 'A name cannot start with a digit: "%s"';
  NumberNameError = '"%s" cannot be used as a name: it reads as a number';
  AParamExcessError = 'Function "%s" takes no arguments';
  BParamExcessError = 'Too many arguments for function "%s"';
  AParamExpectError = 'Function "%s" requires arguments';
  BParamExpectError = 'Not enough arguments for function "%s"';
  ReserveError = '"%s" contains a reserved character: "%s"';
  RTextExcessError = 'Function "%s" takes no value on its right';
  RTextExpectError = 'Function "%s" expects a value on its right';
  ScriptError = 'Internal script error';
  StringError = '"%s" cannot be used in a math expression';
  StringTypeError = '"%s" cannot be of type string';
  NumberTypeError = 'Cannot apply type "%s" to number "%s" in expression "%s"';
  FunctionTypeError = 'Cannot apply type "%s" to function "%s" in expression "%s"';
  ScriptTypeError = 'Cannot apply type "%s" to script "%s" in expression "%s"';
  TypeError = 'Type mismatch';
  TextError = 'An expression is expected here: "%s"';
  SizeError = 'The expression is incomplete';
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

uses
  ParseExecution;

constructor EParserExit.Create(const AValue: TValue);
begin
  inherited Create('Script exit');
  FOwnerParser := CurrentParserOf(CurrentExecuteFrame);
  FValue := AValue;
end;

constructor EParserExit.Create(const AOwnerParser: TObject; const AValue: TValue);
begin
  inherited Create('Script exit');
  FOwnerParser := AOwnerParser;
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
  Result := EParserError.Create(Message);
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
