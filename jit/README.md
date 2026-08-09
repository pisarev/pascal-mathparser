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

On FPC/Lazarus (x86_64-win64) the same machine code is generated. That is a
DIFFERENT run with numbers of its own: they are given as one table in
`../packages/lazarus/README.md`, along with package installation. They are not
repeated here on purpose - the repetition had already drifted from the original,
and two different runs cannot be compared with each other: different programs,
different scenarios, and no comparable measurement was ever made.

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
| `ParseJit.Executor.pas` | Walks that IR without the byte stream or the type matrices. Portable, and the fallback for anything the code generator declines. How much faster than the interpreter is stated above, once, by a measurement - the figure is not repeated here |
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

    if not P.ExecuteMany('x * x * 3 + 1', X, Inputs, Outputs) then
    begin
      Writeln('the bulk call refused, the outputs hold NaN');
      Halt(1);
    end;
    Writeln(Outputs[High(Outputs)]:0:2);
  finally
    P.Free;
  end;
end.
```

Whatever does not compile is answered by the base parser, and the answer is
always the same. `CodeReason(Text)` tells you why a particular formula was
declined.

**The result of `ExecuteMany` has to be checked, and you have to know what it
means.** The first thing the call does is fill with "not a number" everything it
could have written: the whole output array when it is shorter than the input
one, the input range otherwise. The tail of a longer output array is left alone.
So `False` does not mean your data survived untouched - it means that range holds
NaN.

It was not always so. Before 1.0.9 a refusal had two meanings: a short output
array left the caller data untouched, a formula that did not parse left NaN
behind - and the contract could not be stated in one sentence, which is how three
places in the documentation came to disagree.

`False` happens in two cases: the output array is shorter than the input one,
and the formula does not parse. A formula the code generator turns down is NOT a
refusal - it is evaluated the ordinary way and returns `True` just as machine
code does. `MachineCount` and `ExecutorCount` tell the two apart, and
`CodeReason` names the reason for the retreat.

The defect found on 2026-07-27 was a different thing: the generation of the
cache entry was stamped before the script was compiled, so the first formula of
any parser stayed on the interpreter forever.
`../tests/JitContractTest.dpr` stands guard over that.

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
  takes over automatically - how much faster than the interpreter is stated above,
  once, by a measurement. The interpreter remains the last line.
- Everything is computed in `Double`. Integer constants past the exact range of
  the mantissa, 2^53, are not compiled - such a script goes back down rather than
  drift away from the interpreter.
- Not compiled: `for`, `tryexcept` and `tryfinally`, `new` and `delete`,
  functions that take a parameter block (`mean`, `poly`, `min`, `max`), string
  operations, variables of non-numeric types. The base parser answers all of
  these. Scripts with a redirect category are compiled: the redirect chain is
  resolved while building.
- The code cache is invalidated automatically on notifications from the parser
  (`ntCompile`, functions and types added or removed); `ClearCode` is there for
  the manual case.

## Tests

`../tests/build.ps1` builds and runs the lot: the library regression on win32
and win64 (ParserBugTests: 75), the redirection contract (JitRedirectTest: 47),
the documented syntax (DocumentedSyntaxTest: 34), the fuzzer against the
interpreter (JitParserTest: 48), the machine-code contract (JitContractTest: 80),
the public API from the outside (PublicApiTest: 23), plus the IR dump and the
benchmarks.

The numbers in brackets are not typed in: the run prints them, the same script
writes them to `tests/counts.tsv`, and a release check compares every claim
written this way against that file. Left to a human they rotted quietly - the
machine-code contract stood at 26 in the documentation while the run had long
been giving 80.
