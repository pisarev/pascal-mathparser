# pascal-jit - the MathParser accelerator

A layer on top of the parser library in `../src`: it compiles the bytecode
script to x86-64 machine code and runs that instead of the interpreter. The
parser itself is untouched - this plugs in above it.

## What it gives you

The numbers are the output of `../tests/JitParserTest.dpr` on the machine that
prepared the 2026-07-31 release; two consecutive runs agreed to within a few per
cent. Nothing here is typed in by hand.

| Scenario (Win64) | base parser | with the layer | speedup |
|---|---:|---:|---:|
| `AsDouble('x * 2 + 1')` | 928 ns | 42.0 ns | **22x** |
| `AsDouble` of a degree-3 polynomial | 2337 ns | 59.3 ns | **39x** |
| `AsDouble` of a sin/cos/sqrt/exp/ln chain | 2898 ns | 152 ns | **19x** |
| **one turn of a `while` loop** with a counter | 4319 ns | 37.1 ns | **116x** |
| bulk evaluation of `x * 2 + 1` over an array | 968 ns | 7.7 ns | **125x** |
| bulk evaluation of a polynomial over an array | 2070 ns | 13.9 ns | **149x** |

On FPC/Lazarus (x86_64-win64) the same machine code is generated, and the ratios
are higher because the baseline interpreter is slower there: `x*2+1` 33x, the
polynomial 47x, a loop turn **199x**, bulk mode 136x. Details and package
installation are in `../packages/lazarus/README.md`.

On Win32, and on any platform without the emitter, an IR-walking stage takes
over: 1.4x to 3.7x on the same formulas, with no machine code involved. Measured
on 05.08.2026 - win64 gave 1.5x to 3.4x, win32 gave 1.4x to 3.7x. This line used
to say 4.5x to 8.8x, a number from an old run that stopped reproducing and went
on living in the text by itself.

Correctness: 3000 random formulas through the generator - **zero disagreements**
with the base parser.

## Units

| Unit | What it does |
|---|---|
| `ParseJit.Decoder.pas` | Reads a `TScript` into a linear IR of ten opcodes, binds functions and variables statically, infers the value class, and can dump what it built |
| `ParseJit.Executor.pas` | Walks that IR without the byte stream or the type matrices. Portable, 2x to 3x, and the fallback for anything the code generator declines |
| `ParseJit.CodeGen.pas` | Emits x86-64 SSE2: constants, `Double` variables, `*`, `/`, term signs, brackets, and direct calls to sin, cos, tan, sqrt, sqr, ln, exp, abs, arctan |
| `ParseJit.Parser.pas` | `TJitParser`: an `AsDouble` that looks the same, a cache of compiled code, the bulk `ExecuteMany`, counters and diagnostics |

A longer walkthrough with scenarios is in [USAGE.md](USAGE.md).

## Using it

The listing below is the file `../samples/docs/bulk.dpr`, which the build matrix
compiles and runs. Inventing examples in prose is forbidden by our publication
rules: an example that does not compile once went out into the world.

```pascal
program Bulk;

{$APPTYPE CONSOLE}

uses
  ParseJit.Parser;

var
  P: TJitParser;
  X: Double;
  Inputs, Outputs: array of Double;
  I: Integer;
begin
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);

    SetLength(Inputs, 100000);
    SetLength(Outputs, 100000);
    for I := 0 to High(Inputs) do
      Inputs[I] := I / 1000;

    P.ExecuteMany('x * x * 3 + 1', X, Inputs, Outputs);
    Writeln(Outputs[High(Outputs)]:0:2);
  finally
    P.Free;
  end;
end.
```

Whatever does not compile is answered by the base parser, and the answer is
always the same. `CodeReason(Text)` tells you why a particular formula was
declined.

**The result of `ExecuteMany` has to be checked.** It is the one call that
reports a refusal to the caller: on `False` it does not touch the output array,
and a caller who trusted it gets zeros instead of numbers. That is exactly how
the defect found on 2026-07-27 showed itself: the generation of the cache entry
was stamped before the script was compiled, so the first formula of any parser
stayed on the interpreter forever, and bulk mode on it quietly returned `False`.
`../tests/JitContractTest.dpr` now stands guard over this.

## What compiles to machine code

- arithmetic: constants, variables, `*`, `/`, term signs, brackets to any depth;
- math: `sin`, `cos`, `tan`, `sqrt`, `sqr`, `ln`, `exp`, `abs`, `arctan`, as
  direct calls into `double -> double` wrappers;
- comparison `=`, `<>`, `>`, `<`, `>=`, `<=`, through helpers that use the same
  epsilon as the interpreter, so the two agree bit for bit;
- control flow: `if` with real jumps and only one branch evaluated, `while`,
  `repeat`;
- script variables: `get` and `set` with the name resolved while compiling, so a
  loop turn is a direct memory access instead of a lookup by name.

## Limitations of the current version

- The emitter is x86-64 only (Delphi and FPC). On 32-bit builds the IR stage
  takes over automatically (1.4-3.7x), and the interpreter remains the last line.
- Everything is computed in `Double`. Integer constants past the exact range of
  the mantissa, 2^53, are not compiled - such a script goes back down rather than
  drift away from the interpreter.
- Not compiled: `for`, `tryexcept` and `tryfinally`, `new` and `delete`,
  functions that take a parameter block (`mean`, `poly`, `min`, `max`), string
  operations, variables of non-numeric types, scripts with a redirect category.
  The base parser answers all of these.
- The code cache is invalidated automatically on notifications from the parser
  (`ntCompile`, functions and types added or removed); `ClearCode` is there for
  the manual case.

## Tests

`../tests/build.ps1` builds and runs the lot: the library regression on win32
and win64 (75 checks), the redirection contract (47), the documented syntax
(34), the fuzzer against the interpreter (34), the machine-code contract (26),
the public API from the outside (23), plus the IR dump and the benchmarks.
