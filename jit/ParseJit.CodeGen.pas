{ ************************************************************************** }
{                                                                            }
{ ParseJit.CodeGen                                                           }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit ParseJit.CodeGen;

{$B-}
{$O+}
{$R-}
{$Q-}
{$I Directives.inc}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, NumberUtils, ParseTypes, Parser, ValueConsts, ValueTypes, ValueUtils,
  ParseJit.Decoder, ParseJit.Memory;
  {$ELSE}
  System.SysUtils, NumberUtils, ParseTypes, Parser, ValueConsts,
  ValueTypes, ValueUtils, ParseJit.Decoder, ParseJit.Memory;
  {$ENDIF}

type
  TJitFunction = function: Double;

  TJitCode = class
  private
    FParser: TParser;
    FDecoder: TJitDecoder;
    FBuffer: PByte;
    FSize: NativeInt;
    FCapacity: NativeInt;
    FOverflow: Boolean;
    FDescribed: Boolean;
    FCodeSize: NativeInt;
    FCode: TJitFunction;
    FReady: Boolean;
    FReason: string;
    FSlot: Integer;
    FMaxSlot: Integer;
    FFrame: Integer;
    FMultiplyHandle: NativeInt;
    FDivideHandle: NativeInt;
    FCallHandle: array[0..15] of NativeInt;
    FCallAddress: array[0..15] of Pointer;
    FCallCount: Integer;
    FCompareHandle: array[0..5] of NativeInt;
    FCompareAddress: array[0..5] of Pointer;
    FIfHandle, FWhileHandle, FGetHandle, FSetHandle, FRepeatHandle: NativeInt;
    procedure AddCall(const Handle: NativeInt; const Address: Pointer);
    function FindCall(const Handle: NativeInt): Pointer;
    procedure EmitCall(const Address: Pointer);
    procedure EmitLoadArgument(const Value: Pointer);
    procedure EmitFloatArgument2;
    procedure Emit(const Bytes: array of Byte);
    procedure EmitInt32(const Value: Integer);
    procedure EmitInt64(const Value: Int64);
    procedure EmitLoadDouble(const Value: Double);
    procedure EmitLoadMemory(const Address: Pointer);
    function EmitLoadVariable(const Address: Pointer; const AValueType: TValueType): Boolean;
    procedure EmitStoreSlot(const Slot: Integer);
    procedure EmitLoadSlot(const Register1: Boolean; const Slot: Integer);
    function AllocSlot: Integer;
    procedure FreeSlot;
    function EmitScript(var Index: Integer): Boolean;
    function EmitTerm(var Index: Integer): Boolean;
    function EmitOperand(var Index: Integer): Boolean;
    function EmitCompare(const Handle: NativeInt; const Slot: Integer): Boolean;
    function EmitParametric(var Index: Integer; const Op: TJitOp): Boolean;
    function EmitParameterTerm(var Index: Integer): Boolean;
    function VariableOf(const Name: string; out Boxed: PValue; out Direct: PDouble): Boolean;
    function EmitJump(const Conditional: Boolean): Integer;
    procedure PatchJump(const Position: Integer);
    procedure EmitTestZero;
    procedure Reject(const AReason: string);
    procedure Release;
  public
    constructor Create(const AParser: TParser); virtual;
    destructor Destroy; override;
    function Compile(const Script: TScript): Boolean; virtual;
    function Execute: Double; virtual;
    property Ready: Boolean read FReady;
    property Reason: string read FReason;
    property Address: PByte read FBuffer;
    property CodeSize: NativeInt read FSize;
    property Decoder: TJitDecoder read FDecoder;
    class var TestCapacity: NativeInt;
  end;

implementation

const
  SlotSize = 16;
  ShadowSize = 32;
  ExactIntegerLimit = 9007199254740992.0;

function JitAbove(L, R: Double): Double;
begin
  if NumberUtils.Above(L, R, Epsilon) then Result := -1 else Result := 0;
end;

function JitBelow(L, R: Double): Double;
begin
  if NumberUtils.Below(L, R, Epsilon) then Result := -1 else Result := 0;
end;

function JitAboveOrEqual(L, R: Double): Double;
begin
  if NumberUtils.AboveOrEqual(L, R, Epsilon) then Result := -1 else Result := 0;
end;

function JitBelowOrEqual(L, R: Double): Double;
begin
  if NumberUtils.BelowOrEqual(L, R, Epsilon) then Result := -1 else Result := 0;
end;

function JitEqual(L, R: Double): Double;
begin
  if NumberUtils.Equal(L, R, Epsilon) then Result := -1 else Result := 0;
end;

function JitNotEqual(L, R: Double): Double;
begin
  if NumberUtils.Equal(L, R, Epsilon) then Result := 0 else Result := -1;
end;

function JitGetBoxed(P: PValue): Double;
begin
  Result := GetDouble(P^);
end;

function JitSetBoxed(P: PValue; V: Double): Double;
begin
  AssignDouble(P^, V);
  Result := -1;
end;

function JitSin(X: Double): Double;
begin
  Result := Sin(X);
end;

function JitCos(X: Double): Double;
begin
  Result := Cos(X);
end;

function JitTan(X: Double): Double;
begin
  Result := Sin(X) / Cos(X);
end;

function JitSqrt(X: Double): Double;
begin
  Result := Sqrt(X);
end;

function JitSqr(X: Double): Double;
begin
  Result := X * X;
end;

function JitLn(X: Double): Double;
begin
  Result := Ln(X);
end;

function JitExp(X: Double): Double;
begin
  Result := Exp(X);
end;

function JitAbs(X: Double): Double;
begin
  Result := Abs(X);
end;

function JitArcTan(X: Double): Double;
begin
  Result := ArcTan(X);
end;

constructor TJitCode.Create(const AParser: TParser);
begin
  inherited Create;
  FParser := AParser;
  FDecoder := TJitDecoder.Create(AParser);
  FMultiplyHandle := AParser.MultiplyHandle;
  FDivideHandle := AParser.DivideHandle;
  if AParser is TMathParser then
  begin
    AddCall(TMathParser(AParser).SinHandle, @JitSin);
    AddCall(TMathParser(AParser).CosHandle, @JitCos);
    AddCall(TMathParser(AParser).TanHandle, @JitTan);
    AddCall(TMathParser(AParser).SqrtHandle, @JitSqrt);
    AddCall(TMathParser(AParser).SqrHandle, @JitSqr);
    AddCall(TMathParser(AParser).LnHandle, @JitLn);
    AddCall(TMathParser(AParser).ExpHandle, @JitExp);
    AddCall(TMathParser(AParser).AbsHandle, @JitAbs);
    AddCall(TMathParser(AParser).ArcTanHandle, @JitArcTan);
  end;
  FCompareHandle[0] := AParser.AboveHandle;
  FCompareAddress[0] := @JitAbove;
  FCompareHandle[1] := AParser.BelowHandle;
  FCompareAddress[1] := @JitBelow;
  FCompareHandle[2] := AParser.AboveOrEqualHandle;
  FCompareAddress[2] := @JitAboveOrEqual;
  FCompareHandle[3] := AParser.BelowOrEqualHandle;
  FCompareAddress[3] := @JitBelowOrEqual;
  FCompareHandle[4] := AParser.EqualHandle;
  FCompareAddress[4] := @JitEqual;
  FCompareHandle[5] := AParser.NotEqualHandle;
  FCompareAddress[5] := @JitNotEqual;
  FIfHandle := AParser.IfHandle;
  FWhileHandle := AParser.WhileHandle;
  FRepeatHandle := AParser.RepeatHandle;
  FGetHandle := AParser.GetHandle;
  FSetHandle := AParser.SetHandle;
end;

procedure TJitCode.AddCall(const Handle: NativeInt; const Address: Pointer);
begin
  if (Handle < 0) or (FCallCount > High(FCallHandle)) then Exit;
  FCallHandle[FCallCount] := Handle;
  FCallAddress[FCallCount] := Address;
  Inc(FCallCount);
end;

function TJitCode.FindCall(const Handle: NativeInt): Pointer;
var
  I: Integer;
begin
  for I := 0 to FCallCount - 1 do
    if FCallHandle[I] = Handle then Exit(FCallAddress[I]);
  Result := nil;
end;

procedure TJitCode.EmitCall(const Address: Pointer);
begin
  Emit([$48, $B8]);
  EmitInt64(Int64(NativeInt(Address)));
  Emit([$FF, $D0]);
end;

procedure TJitCode.EmitLoadArgument(const Value: Pointer);
begin
  {$IFDEF MSWINDOWS}
  Emit([$48, $B9]);
  {$ELSE}
  Emit([$48, $BF]);
  {$ENDIF}
  EmitInt64(Int64(NativeInt(Value)));
end;

procedure TJitCode.EmitFloatArgument2;
begin
  {$IFDEF MSWINDOWS}
  Emit([$66, $0F, $28, $C8]);
  {$ENDIF}
end;

destructor TJitCode.Destroy;
begin
  Release;
  FDecoder.Free;
  inherited;
end;

procedure TJitCode.Release;
begin
  if Assigned(FBuffer) then
  begin
    if FDescribed then ForgetCode(FBuffer, FCodeSize);
    FDescribed := False;
    FreeCode(FBuffer, FCapacity);
    FBuffer := nil;
  end;
  FCode := nil;
  FReady := False;
  FSize := 0;
  FCapacity := 0;
end;

procedure TJitCode.Reject(const AReason: string);
begin
  if FReason = '' then FReason := AReason;
end;

procedure TJitCode.Emit(const Bytes: array of Byte);
var
  I: Integer;
begin
  for I := Low(Bytes) to High(Bytes) do
  begin
    if FSize >= FCapacity then
    begin
      FOverflow := True;
      Exit;
    end;
    FBuffer[FSize] := Bytes[I];
    Inc(FSize);
  end;
end;

procedure TJitCode.EmitInt32(const Value: Integer);
var
  P: PInteger;
begin
  if FSize + SizeOf(Integer) > FCapacity then
  begin
    FOverflow := True;
    Exit;
  end;
  P := PInteger(FBuffer + FSize);
  P^ := Value;
  Inc(FSize, SizeOf(Integer));
end;

procedure TJitCode.EmitInt64(const Value: Int64);
var
  P: PInt64;
begin
  if FSize + SizeOf(Int64) > FCapacity then
  begin
    FOverflow := True;
    Exit;
  end;
  P := PInt64(FBuffer + FSize);
  P^ := Value;
  Inc(FSize, SizeOf(Int64));
end;

procedure TJitCode.EmitLoadDouble(const Value: Double);
var
  Bits: Int64 absolute Value;
begin
  Emit([$48, $B8]);
  EmitInt64(Bits);
  Emit([$66, $48, $0F, $6E, $C0]);
end;

procedure TJitCode.EmitLoadMemory(const Address: Pointer);
begin
  Emit([$48, $B8]);
  EmitInt64(Int64(NativeInt(Address)));
  Emit([$F2, $0F, $10, $00]);
end;

function TJitCode.EmitLoadVariable(const Address: Pointer; const AValueType: TValueType): Boolean;
begin
  Result := True;
  case AValueType of
    ValueTypes.vtDouble: EmitLoadMemory(Address);
    ValueTypes.vtExtended:
      if SizeOf(Extended) = SizeOf(Double) then EmitLoadMemory(Address)
      else
        Result := False;
    ValueTypes.vtSingle:
      begin
        Emit([$48, $B8]);
        EmitInt64(Int64(NativeInt(Address)));
        Emit([$F3, $0F, $5A, $00]);
      end;
    ValueTypes.vtInteger:
      begin
        Emit([$48, $B8]);
        EmitInt64(Int64(NativeInt(Address)));
        Emit([$F2, $0F, $2A, $00]);
      end;
    ValueTypes.vtLongWord:
      begin
        Emit([$48, $B8]);
        EmitInt64(Int64(NativeInt(Address)));
        Emit([$8B, $00]);
        Emit([$F2, $48, $0F, $2A, $C0]);
      end;
    ValueTypes.vtInt64, ValueTypes.vtNativeInt:
      begin
        Emit([$48, $B8]);
        EmitInt64(Int64(NativeInt(Address)));
        Emit([$F2, $48, $0F, $2A, $00]);
      end;
  else
    Result := False;
  end;
end;

procedure TJitCode.EmitStoreSlot(const Slot: Integer);
begin
  Emit([$F2, $0F, $11, $84, $24]);
  EmitInt32(ShadowSize + Slot * SlotSize);
end;

procedure TJitCode.EmitLoadSlot(const Register1: Boolean; const Slot: Integer);
begin
  if Register1 then
    Emit([$F2, $0F, $10, $8C, $24])
  else
    Emit([$F2, $0F, $10, $84, $24]);
  EmitInt32(ShadowSize + Slot * SlotSize);
end;

function TJitCode.AllocSlot: Integer;
begin
  Result := FSlot;
  Inc(FSlot);
  if FSlot > FMaxSlot then FMaxSlot := FSlot;
end;

procedure TJitCode.FreeSlot;
begin
  Dec(FSlot);
end;

function TJitCode.EmitJump(const Conditional: Boolean): Integer;
begin
  if Conditional then Emit([$0F, $84])
  else
    Emit([$E9]);
  Result := FSize;
  EmitInt32(0);
end;

procedure TJitCode.PatchJump(const Position: Integer);
begin
  if (Position >= 0) and (Position + SizeOf(Integer) <= FCapacity) then
    PInteger(FBuffer + Position)^ := FSize - (Position + SizeOf(Integer));
end;

procedure TJitCode.EmitTestZero;
begin
  Emit([$66, $0F, $57, $C9]);
  Emit([$66, $0F, $2E, $C1]);
end;

function TJitCode.EmitCompare(const Handle: NativeInt; const Slot: Integer): Boolean;
var
  I: Integer;
begin
  for I := Low(FCompareHandle) to High(FCompareHandle) do
    if (FCompareHandle[I] = Handle) and (Handle >= 0) then
    begin
      Emit([$66, $0F, $28, $C8]);
      EmitLoadSlot(False, Slot);
      EmitCall(FCompareAddress[I]);
      Exit(True);
    end;
  Result := False;
end;

function TJitCode.VariableOf(const Name: string; out Boxed: PValue; out Direct: PDouble): Boolean;
var
  AFunction: PFunction;
begin
  Boxed := nil;
  Direct := nil;
  AFunction := FParser.FindFunction(Trim(Name));
  Result := Assigned(AFunction) and (AFunction.Method.MethodType = mtVariable);
  if not Result then Exit;
  if AFunction.Method.Variable.VariableType = ParseTypes.vtValue then
    Boxed := AFunction.Method.Variable.Variable
  else
    if (AFunction.Method.Variable.VariableRef.ValueType = ValueTypes.vtDouble) or
      ((AFunction.Method.Variable.VariableRef.ValueType = ValueTypes.vtExtended) and (SizeOf(Extended) = SizeOf(Double))) then
        Direct := PDouble(AFunction.Method.Variable.VariableRef.Float64)
  else
    Result := False;
  Result := Result and (Assigned(Boxed) or Assigned(Direct));
end;

function TJitCode.EmitParameterTerm(var Index: Integer): Boolean;
begin
  if (Index >= FDecoder.Count) or (FDecoder.Ops[Index].Code <> joTermBegin) then
  begin
    Reject('parameter shape');
    Exit(False);
  end;
  Inc(Index);
  if not EmitTerm(Index) then Exit(False);
  Inc(Index);
  Result := True;
end;

function TJitCode.EmitParametric(var Index: Integer; const Op: TJitOp): Boolean;
var
  Handle: NativeInt;
  Name: string;
  Boxed: PValue;
  Direct: PDouble;
  ElseJump, EndJump, LoopStart: Integer;
  Slot: Integer;
begin
  Handle := Op.AFunction.Handle^;
  Inc(Index);
  if (Index >= FDecoder.Count) or (FDecoder.Ops[Index].Code <> joParameterBegin) then
  begin
    Reject('parameter block expected');
    Exit(False);
  end;
  Inc(Index);
  if Handle = FGetHandle then
  begin
    if (Index + 1 >= FDecoder.Count) or (FDecoder.Ops[Index].Code <> joTermBegin) or
      (FDecoder.Ops[Index + 1].Code <> joString) then
      begin
        Reject('get needs a literal name');
        Exit(False);
      end;
    Name := FDecoder.Ops[Index + 1].Text;
    if not VariableOf(Name, Boxed, Direct) then
    begin
      Reject('unknown variable ' + Name);
      Exit(False);
    end;
    Inc(Index, 3);
    if Assigned(Direct) then EmitLoadMemory(Direct)
    else begin
      EmitLoadArgument(Boxed);
      EmitCall(@JitGetBoxed);
    end;
  end
  else if Handle = FSetHandle then
  begin
    if (Index + 1 >= FDecoder.Count) or (FDecoder.Ops[Index].Code <> joTermBegin) or
      (FDecoder.Ops[Index + 1].Code <> joString) then
      begin
        Reject('set needs a literal name');
        Exit(False);
      end;
    Name := FDecoder.Ops[Index + 1].Text;
    if not VariableOf(Name, Boxed, Direct) then
    begin
      Reject('unknown variable ' + Name);
      Exit(False);
    end;
    Inc(Index, 3);
    if not EmitParameterTerm(Index) then Exit(False);
    if Assigned(Direct) then
    begin
      Emit([$48, $B8]);
      EmitInt64(Int64(NativeInt(Direct)));
      Emit([$F2, $0F, $11, $00]);
      EmitLoadDouble(-1);
    end
    else begin
      EmitFloatArgument2;
      EmitLoadArgument(Boxed);
      EmitCall(@JitSetBoxed);
    end;
  end
  else if Handle = FIfHandle then
  begin
    if Op.ParameterCount < 2 then
    begin
      Reject('if arity');
      Exit(False);
    end;
    if not EmitParameterTerm(Index) then Exit(False);
    EmitTestZero;
    ElseJump := EmitJump(True);
    if not EmitParameterTerm(Index) then Exit(False);
    EndJump := EmitJump(False);
    PatchJump(ElseJump);
    if (Index < FDecoder.Count) and (FDecoder.Ops[Index].Code = joTermBegin) then
    begin
      if not EmitParameterTerm(Index) then Exit(False);
    end
    else
      EmitLoadDouble(0);
    PatchJump(EndJump);
  end
  else if Handle = FWhileHandle then
  begin
    Slot := AllocSlot;
    try
      EmitLoadDouble(0);
      EmitStoreSlot(Slot);
      LoopStart := FSize;
      if not EmitParameterTerm(Index) then Exit(False);
      EmitTestZero;
      EndJump := EmitJump(True);
      if not EmitParameterTerm(Index) then Exit(False);
      EmitTestZero;
      ElseJump := EmitJump(True);
      EmitLoadDouble(1);
      EmitStoreSlot(Slot);
      PatchJump(ElseJump);
      Emit([$E9]);
      EmitInt32(LoopStart - (FSize + SizeOf(Integer)));
      PatchJump(EndJump);
      EmitLoadSlot(False, Slot);
    finally
      FreeSlot;
    end;
  end
  else if Handle = FRepeatHandle then
  begin
    Slot := AllocSlot;
    try
      EmitLoadDouble(0);
      EmitStoreSlot(Slot);
      LoopStart := FSize;
      if not EmitParameterTerm(Index) then Exit(False);
      EmitTestZero;
      ElseJump := EmitJump(True);
      EmitLoadDouble(1);
      EmitStoreSlot(Slot);
      PatchJump(ElseJump);
      if not EmitParameterTerm(Index) then Exit(False);
      EmitTestZero;
      Emit([$0F, $84]);
      EmitInt32(LoopStart - (FSize + SizeOf(Integer)));
      EmitLoadSlot(False, Slot);
    finally
      FreeSlot;
    end;
  end
  else begin
    Reject('parametric ' + Op.Name);
    Exit(False);
  end;
  while (Index < FDecoder.Count) and (FDecoder.Ops[Index].Code <> joParameterEnd) do
  begin
    if FDecoder.Ops[Index].Code = joTermBegin then
    begin
      Inc(Index);
      while (Index < FDecoder.Count) and (FDecoder.Ops[Index].Code <> joTermEnd) do
      begin
        if FDecoder.Ops[Index].Code in [joScriptBegin, joParameterBegin] then
        begin
          Inc(Index);
          while (Index < FDecoder.Count) and
            not (FDecoder.Ops[Index].Code in [joScriptEnd, joParameterEnd]) do
              Inc(Index);
        end;
        Inc(Index);
      end;
    end;
    Inc(Index);
  end;
  if Index < FDecoder.Count then Inc(Index);
  Result := True;
end;

function TJitCode.EmitOperand(var Index: Integer): Boolean;
var
  Op: TJitOp;
  Address: Pointer;
begin
  Op := FDecoder.Ops[Index];
  case Op.Code of
    joConst:
      begin
        if Op.ValueClass = jcString then
        begin
          Reject('string constant');
          Exit(False);
        end;
        if (Op.ValueClass = jcInt) and (Abs(GetExtended(Op.Value)) > ExactIntegerLimit) then
        begin
          Reject('integer constant out of exact range');
          Exit(False);
        end;
        EmitLoadDouble(GetDouble(Op.Value));
        Inc(Index);
      end;
    joVariable:
      begin
        if Assigned(Op.Variable) then
        begin
          EmitLoadArgument(Op.Variable);
          EmitCall(@JitGetBoxed);
        end
        else
          if not EmitLoadVariable(Op.VariableRef, Op.VariableType) then
          begin
            Reject('variable type of ' + Op.Name);
            Exit(False);
          end;
        Inc(Index);
      end;
    joScriptBegin:
      begin
        Inc(Index);
        if not EmitScript(Index) then Exit(False);
        Inc(Index);
      end;
    joCall:
      begin
        if not Assigned(Op.AFunction) then
        begin
          Reject('unresolved call');
          Exit(False);
        end;
        if Op.AFunction.Method.Parameter.Count > 0 then
        begin
          if not EmitParametric(Index, Op) then Exit(False);
          Exit(True);
        end;
        Address := FindCall(Op.AFunction.Handle^);
        if not Assigned(Address) then
        begin
          Reject('call ' + Op.Name);
          Exit(False);
        end;
        if Op.AFunction.Method.Parameter.L then
        begin
          Reject('binary call ' + Op.Name);
          Exit(False);
        end;
        Inc(Index);
        if not EmitOperand(Index) then Exit(False);
        EmitCall(Address);
      end;
  else
    Reject('operand kind');
    Exit(False);
  end;
  Result := True;
end;

function TJitCode.EmitTerm(var Index: Integer): Boolean;
var
  Op: TJitOp;
  Slot: Integer;
  Multiply, Compare: Boolean;
begin
  Slot := AllocSlot;
  try
    if not EmitOperand(Index) then Exit(False);
    EmitStoreSlot(Slot);
    while (Index < FDecoder.Count) and (FDecoder.Ops[Index].Code <> joTermEnd) do
    begin
      Op := FDecoder.Ops[Index];
      if Op.Code <> joCall then
      begin
        Reject('unexpected element in term');
        Exit(False);
      end;
      if not Assigned(Op.AFunction) then
      begin
        Reject('unresolved call');
        Exit(False);
      end;
      Compare := False;
      if Op.AFunction.Handle^ = FMultiplyHandle then Multiply := True
      else if Op.AFunction.Handle^ = FDivideHandle then Multiply := False
      else begin
        Multiply := False;
        Compare := True;
      end;
      Inc(Index);
      if not EmitOperand(Index) then Exit(False);
      if Compare then
      begin
        if not EmitCompare(Op.AFunction.Handle^, Slot) then
        begin
          Reject('binary call ' + Op.Name);
          Exit(False);
        end;
      end
      else begin
        EmitLoadSlot(True, Slot);
        if Multiply then
          Emit([$F2, $0F, $59, $C8])
        else
          Emit([$F2, $0F, $5E, $C8]);
        Emit([$66, $0F, $28, $C1]);
      end;
      EmitStoreSlot(Slot);
    end;
    EmitLoadSlot(False, Slot);
    Result := True;
  finally
    FreeSlot;
  end;
end;

function TJitCode.EmitScript(var Index: Integer): Boolean;
var
  Slot: Integer;
  Sign: NativeInt;
  First: Boolean;
begin
  Slot := AllocSlot;
  try
    First := True;
    while (Index < FDecoder.Count) and (FDecoder.Ops[Index].Code = joTermBegin) do
    begin
      Sign := FDecoder.Ops[Index].Sign;
      Inc(Index);
      if not EmitTerm(Index) then Exit(False);
      Inc(Index);
      if First then
      begin
        if Sign <> 0 then
        begin
          Emit([$66, $0F, $57, $C9]);
          Emit([$F2, $0F, $5C, $C8]);
          Emit([$66, $0F, $28, $C1]);
        end;
        EmitStoreSlot(Slot);
        First := False;
      end
      else begin
        EmitLoadSlot(True, Slot);
        if Sign = 0 then Emit([$F2, $0F, $58, $C8])
        else
          Emit([$F2, $0F, $5C, $C8]);
        Emit([$66, $0F, $28, $C1]);
        EmitStoreSlot(Slot);
      end;
    end;
    if First then
    begin
      Reject('empty script');
      Exit(False);
    end;
    EmitLoadSlot(False, Slot);
  finally
    FreeSlot;
  end;
  Result := True;
end;

function TJitCode.Compile(const Script: TScript): Boolean;
var
  Index: Integer;
  Prologue, Epilogue: Integer;
  PrologBytes: Integer;
begin
  Release;
  FReason := '';
  {$IFNDEF CPUX64}
  FReason := 'x86-64 only';
  Exit(False);
  {$ENDIF}
  FSlot := 0;
  FMaxSlot := 0;
  FOverflow := False;
  if not FDecoder.Decode(Script) then
  begin
    FReason := FDecoder.Reason;
    Exit(False);
  end;
  if TestCapacity > 0 then FCapacity := TestCapacity
  else
    FCapacity := 4096 + UnwindReserve + FDecoder.Count * 64;
  FBuffer := AllocCode(FCapacity);
  if not Assigned(FBuffer) then
  begin
    FReason := 'no executable memory';
    Exit(False);
  end;
  FFrame := 0;
  Epilogue := 0;
  Emit([$48, $81, $EC]);
  Prologue := FSize;
  EmitInt32(0);
  PrologBytes := FSize;
  Index := 0;
  Result := EmitScript(Index);
  if Result then
  begin
    Emit([$48, $81, $C4]);
    Epilogue := FSize;
    EmitInt32(0);
    Emit([$C3]);
    Result := not FOverflow;
    if not Result then FReason := 'code buffer overflow';
  end;
  if Result then
  begin
    FFrame := ShadowSize + (FMaxSlot + 1) * SlotSize + 8;
    if FFrame > 4096 then
    begin
      FReason := 'stack frame is too deep';
      Result := False;
    end;
    if Result and (Epilogue = 0) then
    begin
      FReason := 'code layout is broken';
      Result := False;
    end;
  end;
  if Result then
  begin
    PInteger(FBuffer + Prologue)^ := FFrame;
    PInteger(FBuffer + Epilogue)^ := FFrame;
    FCodeSize := FSize;
    FDescribed := DescribeCode(FBuffer, FCapacity, FCodeSize, FFrame, PrologBytes);
    if not FDescribed then
    begin
      FReason := 'cannot describe stack frame';
      Exit(False);
    end;
    Result := ProtectCode(FBuffer, FCapacity);
    if Result then
    begin
      FCode := TJitFunction(FBuffer);
      FReady := True;
    end
    else
      FReason := 'cannot protect code';
  end;
  if not Result then
  begin
    if FReason = '' then FReason := 'code generation failed';
    Release;
  end;
end;

function TJitCode.Execute: Double;
begin
  if not FReady then
    raise Exception.Create('jit code is not ready: ' + FReason);
  Result := FCode();
end;
end.
