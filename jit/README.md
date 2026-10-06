# pascal-jit - the MathParser accelerator

A layer on top of the parser library in `../src`: it compiles the bytecode
script to x86-64 machine code and runs that instead of the interpreter. The
parser itself is untouched - this plugs in above it.

## What it gives you

The numbers are the output of `../tests/JitParserTest.dpr` of 5 October 2026
(dcc64, x86_64-win64), the last of five consecutive runs; the same run is the
source of `bench.tsv`, from which the showcase takes its table. Nothing here is
typed in by hand.

| Scenario (Win64) | base parser | with the layer | speedup |
|---|---:|---:|---:|
| `AsDouble('x * 2 + 1')` | 882 ns | 64.7 ns | **14x** |
| `AsDouble` of a degree-3 polynomial | 1941 ns | 84.0 ns | **23x** |
| `AsDouble` of a sin/cos/sqrt/exp/ln chain | 2633 ns | 171 ns | **15x** |
| **one turn of a `while` loop** with a counter | 3953 ns | 41.6 ns | **95x** |
| bulk evaluation of `x * 2 + 1` over an array | 877 ns | 9.4 ns | **93x** |
| bulk evaluation of a polynomial over an array | 1929 ns | 14.6 ns | **132x** |

The spread of the five `JitParserTest` runs, by multiplier: `AsDouble('x * 2 + 1')` 13.6x-14.4x,
the polynomial 23.1x-28.3x, the chain 13.6x-17.0x, one turn of a loop 86x-113x,
bulk mode 93x-98x and 132x-139x. The loop turn wanders more than the rest, and
that is not rounding: its base is measured as twenty repetitions of a loop of ten
thousand turns, and one of the five runs gave 4703 ns instead of 3953 ns. A
number without its spread on values like these promises a precision that does not
exist.

THE TABLE WAS RE-MEASURED, and none of the old numbers were carried over. Until 5
October 2026 this place held the run of 2026-07-27: 21x, 40x, 17x, 108x, 115x and
165x. Two reasons why they could not stay, both measured:

1. A turn of a loop costs one call more: since 4 October 2026 every turn of a
   compiled loop asks the turn limit for permission. The price of the call,
   measured separately by a probe, is 6.91 ns under dcc64; in the loop row that is
   the difference between 35.9 ns and 41.6 ns. It is paid by whoever started a
   loop: in formulas with no loops the check is not emitted at all, and the
   bookkeeping of a refusal does not run.
2. Bulk mode was evaluated through the wrapper of the entry, which armed the FPU
   mask at every element although `ExecuteMany` had already armed it for the whole
   set. Measured: `GetExceptionMask` costs 6.97 ns, and the whole wrapper cost
   11.85 ns out of 21.4 ns per element. The stage itself now runs inside the set,
   and an element costs 9.4 ns. The mask contract did not suffer and is covered by
   a check: `tests/FpuMaskTest.dpr`, the section on the three entries of the
   accelerator, which fails without the arming on the set - shown by a mutation,
   EInvalidOp and a set that was not evaluated to the end.

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

The case found on 2026-07-27 was a different thing: the generation of the
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
the public API from the outside (PublicApiTest: 28), plus the IR dump and the
benchmarks.

The numbers in brackets are not typed in: the run prints them, the same script
writes them to `tests/counts.tsv`, and a release check compares every claim
written this way against that file. Left to a human they rotted quietly - the
machine-code contract stood at 26 in the documentation while the run had long
been giving 80.
