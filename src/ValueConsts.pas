{ ************************************************************************** }
{                                                                            }
{ ValueConsts                                                                }
{                                                                            }
{ Copyright © 2008 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ValueConsts;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  ValueTypes;

var
  EmptyValue: TValue;

procedure Check(const Value: TValue); overload;
procedure Check(const Value: array of TValue); overload;

implementation

uses
  ValueErrors;

procedure Check(const Value: TValue);
begin
  if Value.ValueType = vtUnknown then raise Error(UnknownTypeError);
end;

procedure Check(const Value: array of TValue);
var
  I: Integer;
begin
  for I := Low(Value) to High(Value) do Check(Value[I]);
end;

initialization
  FillChar(EmptyValue, SizeOf(TValue), 0);
  EmptyValue.ValueType := vtByte;

end.
