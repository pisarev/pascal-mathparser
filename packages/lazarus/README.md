# Working in Lazarus and FPC

The parser library and the accelerator build and run under FPC 3.2.2 and 3.3.1,
machine code generation included. Verified by a full run of the test suite: 467
checks on 3.3.1 (x86_64-win64), 454 on 3.2.2 (x86_64-linux) - the difference is
the programs that are not there on Linux. No failures on either.

The stable 3.2.2 is named first on purpose: the project has to build for someone
who has not installed trunk.

## Packages

| Package | What is inside |
|---|---|
| `crosspascal_parser.lpk` | The parser core and everything around it (45 units from `src`) |
| `crosspascal_parserjit.lpk` | The accelerator from `jit` (depends on the package above) |

Installing: in Lazarus choose Package, Open package file, open
`crosspascal_parser.lpk` and press Compile, then do the same for
`crosspascal_parserjit.lpk`. To use them in a project it is enough to choose
Use, Add to project - installing into the IDE is not needed, since these
packages register no palette components.

The packages depend on the LCL, because in the default configuration
`ParseMessages` takes `LMessages` from it. That dependency is only for GUI
projects: a console program is built with `-dNOFORMS -dNOGRAPHICS` and the
`src/compat` folder on the unit path, and then the library needs nothing but the
RTL - no LCL, no LazUtils, no `Interfaces` unit. That is not an assumption: the
build matrix compiles exactly this way, without a single path to Lazarus.

## Building from the command line

```
tests/build_fpc.ps1
```

The script builds and runs both sets of tests under FPC. Paths are overridden
with the `FPC_EXE` and `LAZARUS_DIR` environment variables.

## Results under FPC (x86_64-win64)

Every test is green. The counts below are from the Free Pascal run of the
matrix, which is a different run from the Delphi one and has counts of its own:
the library regression 75 checks, redirection 47, documented syntax 34, the
fuzzer against the interpreter 48, the machine-code contract 80, the public API
23, the `WaitFor` contract 6.

Machine code is generated under FPC as well.

The numbers below are the output of JitParserTest built with FPC. That is a
separate run, and they describe that run only.

They are not compared with the table in `../../jit/README.md`. That is a
different program over a different set of scenarios, with a signature of its
own, and no comparable measurement - one machine, one commit, one set of
inputs, one harness - has been made. This paragraph used to say "the speedups
are even higher than on Delphi": the numbers were right and the conclusion
drawn from them was wrong - only the loop turn is higher, bulk mode is lower.

The run file itself stays in the development monorepo; it is not part of this
repository.

| Scenario | base parser | with the accelerator | speedup |
|---|---:|---:|---:|
| one turn of a script loop | 4342 ns | 17.9 ns | **242x** |
| bulk `x * 2 + 1` over an array | 1201 ns | 18.5 ns | **65x** |
| bulk polynomial over an array | 2387 ns | 31.8 ns | **75x** |

The table used to carry three more rows - `x * 2 + 1`, a polynomial and a
sin/cos/sqrt/exp/ln chain through `AsDouble`. The run file does not contain them,
so there is nothing to confirm them with and they are gone. They come back when
the run writes them.

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
   `strtodatetime("01.02.2020 10:30")`. On a modern Delphi RTL the defect did
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
