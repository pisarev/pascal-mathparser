# Working in Lazarus and FPC

The parser library and the accelerator build and run under FPC 3.2.2, machine
code generation included. Verified by full runs of the test suite on 5 October
2026: 767 checks in 21 programs under FPC 3.2.2 on x86_64-win64, and under
Delphi (Studio 37) 856 checks in 26 programs on win64, with two of them -
`ParserBugTests` (75) and `JitRedirectTest` (47) - run additionally on win32:
28 runs in all, 978 checks, no failures in either. The earlier wording, "978
checks in 28 programs under Delphi on win64", folded two word sizes into one row
and credited the sum to win64; the review round of 5 October 2026 found it.

TWO OLDER NUMBERS ARE GONE. This paragraph used to claim 467 checks on 3.3.1
(x86_64-win64) and 454 on 3.2.2 (x86_64-linux). Neither can be re-measured on
this machine: FPC 3.3.1 is not installed (3.2.2 and 3.2.3 are), and Linux is
available only as WSL, which has no FPC. A number nobody can recheck is a
promise without a subject, so both are gone; they come back when the runs are
made on those compilers and on that platform.

What was measured instead, on 5 October 2026, one and the same suite:

| environment | programs | checks | failures |
|---|---:|---:|---:|
| FPC 3.2.2, x86_64-win64 (from the Lazarus 3.6 installation) | 21 | 767 | 0 |
| FPC 3.2.3, x86_64-win64 (standalone) | 19 of 21 | 686 | 0 |
| Delphi, Studio 37, win64 | 26 | 856 | 0 |
| Delphi, Studio 37, win32 (two targets out of the same 26) | 2 | 122 | 0 |

The Delphi rows are split by word size on purpose: `tests/build.ps1` writes the
win64 numbers into `counts.tsv`, and the win32 stage runs two targets -
`ParserBugTests` (75 checks) and `JitRedirectTest` (47). Folding them into one
"win64" row credits the sum with somebody else's word size, and that is exactly
what stood here until 5 October 2026: 28 programs and 978 checks in the win64
row.

Under 3.2.3 two programs DID NOT BUILD: `ParserBugTests` and `ThreadWaitTest`,
both with "Fatal: Can't find unit Interfaces". That is a property of a
standalone FPC with no Lazarus units, not of the library: the same suite builds
both under the 3.2.2 that comes with Lazarus. The count is therefore given for
the programs that built - 686 against 767 does not mean failed checks.

The stable 3.2.2 is named first on purpose: the project has to build for someone
who has not installed trunk.

## Packages

| Package | What is inside |
|---|---|
| `crosspascal_parser.lpk` | The parser core and everything around it: 46 units from `src` |
| `crosspascal_parserjit.lpk` | The accelerator: 4 units from `jit`, depends on the package above |

Installing: in Lazarus choose Package, Open package file, open
`crosspascal_parser.lpk` and press Compile, then do the same for
`crosspascal_parserjit.lpk`. To use them in a project it is enough to choose
Use, Add to project: installing into the IDE is not required. The packages do
carry a register procedure, though, and that is worth saying plainly:
`HasRegisterProc` is declared for eight units of the core and one of the
accelerator, and after installing into the IDE the `CrossPascal` palette shows
twelve components - `TParser`, `TMathParser`, `TJitParser`, `TCalculator`,
`TParseValueList`, `TParseManager`, `TConnector`, `TCalcThread`, `TSyncThread`,
`TSyncTimer`, `TExactTimer`, `TBlobManager`. Measured on 4 October 2026 over the
published tree: the `RegisterComponents` calls in `src` and `jit`. The previous
wording, "these packages register no palette components", was untrue, and the
review round of release 1.3.8 removed it.

What the packages depend on is declared, and nothing more: `RequiredPkgs` holds
one entry in each - `FCL` for the parser and `crosspascal_parser` for the
accelerator. Neither LCL nor LazUtils is among them, the build carries
`-dNOFORMS -dNOGRAPHICS` in the `CustomOptions` of both `.lpk` files, and
`src/compat` goes on the unit path - so the library needs nothing but the RTL
and no `Interfaces` unit. That is not an assumption: the build matrix compiles
exactly this way, without a single path to Lazarus. The LCL appears only in a
default configuration, where `ParseMessages` takes `LMessages` from it - that
is, in a GUI project, which pulls the LCL in anyway.

Measured on the published tree on 4 October 2026: 46 `Files/Item` entries in the
parser package and 4 in the accelerator package, all of them `.pas`;
`HasRegisterProc=True` for eight units of the core (BlobManager, Calculator,
Connector, ExactTimer, ParseManager, ParseValueList, Parser, SyncThread) and for
one unit of the accelerator (ParseJit.Parser). The first draft of this
correction said `RequiredPkgs` was empty: the probe looked for an `ItemName`
attribute, while the `.lpk` files carry `<PackageName Value="...">`. The same
review round that found the original disagreement removed the mistake - which is
why a number in a document has to travel with the way it was measured.

## Building from the command line

```
tests/build_fpc.ps1
```

The script builds and runs both sets of tests under FPC. Paths are overridden
with the `FPC_EXE` and `LAZARUS_DIR` environment variables.

## Results under FPC (x86_64-win64)

Every test is green. The counts below are from the Free Pascal 3.2.2 run of 5
October 2026, which is a different run from the Delphi one and has counts of its
own: the library regression 75 checks, redirection 47, documented syntax 34, the
fuzzer against the interpreter 48, the machine-code contract 80, the public API
28, the `WaitFor` contract 6, the loop guard 57, the coprocessor mask 33.

Machine code is generated under FPC as well.

The numbers below are the output of JitParserTest built with FPC 3.2.2, the LAST
of five consecutive runs on 5 October 2026. That is a separate run, and they
describe that run only. The spread of the five runs, by multiplier: one turn of a
loop 111x-135x, bulk `x * 2 + 1` 119x-140x, bulk polynomial 164x-172x. A number
without its spread on values like these claims a precision that does not exist:
one element of bulk mode costs 10-15 ns, and a single run lies.

They are not compared with the table in `../../jit/README.md`. That is a
different program over a different set of scenarios, with a signature of its own,
and no comparable measurement - one machine, one commit, one set of inputs, one
harness - has been made. This paragraph used to say "the speedups are even higher
than on Delphi", and that conclusion was withdrawn on 4 October 2026 as false.
The measurement of 5 October 2026 needs one more thing said: the multipliers
under FPC are now higher in all three rows - 130x against 95x for a turn of a
loop, 128x against 93x and 164x against 132x for bulk mode - and that does NOT
mean the accelerator is faster under FPC. In absolute numbers it is about the
same (44.2 ns per turn against 41.6 ns); the multiplier is higher because the
base is slower: the interpreter under FPC spends 5736 ns on a turn against 3953 ns
under Delphi. A multiplier divides one base by another, and it cannot be read as
"better".

The run file itself stays in the development monorepo; it is not part of this
repository.

| Scenario | base parser | with the accelerator | speedup |
|---|---:|---:|---:|
| one turn of a script loop | 5736 ns | 44.2 ns | **130x** |
| bulk `x * 2 + 1` over an array | 1269 ns | 9.9 ns | **128x** |
| bulk polynomial over an array | 2512 ns | 15.3 ns | **164x** |

A turn of a loop costs more here than it did: since 4 October 2026 every turn of
a compiled loop asks the turn limit for permission (the section below), and that
is one call per turn. The price of the call was measured separately by a probe:
6.91 ns under dcc64 and 27.56 ns under FPC 3.2.2, of which reading the two thread
variables of the limit and of the cancellation flag costs 2.34 ns and 8.68 ns
respectively. The call is four times more expensive under FPC, and that is a
property of the compiler, not of the way the check is built.

The table used to carry three more rows - `x * 2 + 1`, a polynomial and a
sin/cos/sqrt/exp/ln chain through `AsDouble`. The run file does not contain them,
so there is nothing to confirm them with and they are gone. They come back when
the run writes them.

## The loop guard works in the accelerator too

`ArmLoopGuard` and somebody else's cancellation flag stop compiled code as well
as the interpreter: since 4 October 2026 every turn of a compiled `While` or
`Repeat` asks for permission. A refusal stops the WHOLE evaluation and not one
loop: the jumps of all the limit checks are patched to one shared abort point, so
the surrounding expression - an assignment the loop was an argument of, for one -
does not run, and the exception is raised by the execution wrapper on the Pascal
side. The message is the one the interpreter gives: "Loop limit reached:
`While`" for a spent budget and "Calculation stopped: `While`" for somebody
else's flag.

Before that date the accelerator knew nothing of the limit. Measured on the tree
of release 1.3.8: the interpreter with a budget of 1000 turns came back in 0.4 s
with the limit message and the counter at 999, while the accelerator - through
`AsDouble` and through `CompileScript`/`Execute` alike - had not returned after
25 s, and the loop was running as machine code (`MachineCount` 1,
`ExecutorCount` 0).

BOTH HALVES of the promise are checked. The section "the accelerator obeys the
same guard" in `LoopGuardTest` runs one and the same set of formulas through both
paths and demands the admission that machine code was in use: without it the
section would stay green exactly when the compilation was declined. The section
"an armed guard leaves an honest count alone" compares the VALUE of a formula
between the two executors - a guard that is armed but never triggered has no
right to change anything. That second half had to be added after a measurement of
the same day: the first edition of the shared abort point lay on the
straight-line path of the code (machine code has no barrier between two adjacent
blocks), and every honest loop returned zero instead of its accumulated value -
with the counter reaching the end, the budget unspent and no exception raised.
Three failures of `JitParserTest`, the same on FPC 3.2.2 and on dcc64.

## What had to be fixed for FPC

1. **The Synchronize queue.** The library's own mechanism never reached the main
   thread under FPC: pool threads finished, but the Done handler was never
   called. Under FPC the queue now comes from the RTL - `TSyncThread.DoDone`
   posts the task through `Classes.TThread.Synchronize`, and
   `Thread.CheckSynchronize` is routed to `Classes.CheckSynchronize`.
2. **Waiting for the pool.** `TThread.WaitFor` waited on the thread's finished
   flag, although the count of active threads drops later, in the Done handler.
   It now waits for that count to reach zero and pumps the synchronize queue
   itself.
3. **A registry that moves.** `new()` inside a script grows the function array,
   and the pointer to the running function was left dangling - under FPC that
   gave an access violation. `ExecuteFunction` now re-reads the pointer by
   handle after the call.
4. **Thirteen math functions** (the inverse cotangents, secants, cosecants and
   the Cycle conversions) no longer raise "not implemented" - the Math functions
   of FPC are used.
5. **Poly** is implemented with Horner's scheme, since the FPC branch has no
   `Math.Poly`.
6. **CleanDateTime** no longer glues the date to the time: under FPC that broke
   `strtodatetime("01.02.2020 10:30")`. On a modern Delphi RTL it did
   not show.
7. **Graphics became optional.** BlobManager pulled in the Graphics unit and
   with it the whole LCL; with `-dNOGRAPHICS` the graphical methods are switched
   off and the parser builds in a plain console environment.
8. **The timer left the widgetset.** Under FPC `SyncThread` used to create its
   timer through the LCL widgetset, so anything that went through `Calculator`
   would not link in a console program. It now uses the thread-based
   `TExactTimer`.
9. **LazUtils is gone.** The whole library required it for a single call,
   `FileUtil.FileSize`; it is replaced by `FindFirst`, the same implementation
   that the WebAssembly build already used.
