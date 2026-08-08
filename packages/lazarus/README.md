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

Every test is green: the library regression 75 checks, redirection 47,
documented syntax 34, the fuzzer against the interpreter 34, the machine-code
contract 26, the public API 23, the `WaitFor` contract 6.

Machine code is generated under FPC as well, and the speedups are even higher
than on Delphi because the base interpreter there is slower:

| Scenario | base parser | with the accelerator | speedup |
|---|---:|---:|---:|
| `x * 2 + 1` | 1240 ns | 37.3 ns | **33x** |
| a degree-3 polynomial | 2621 ns | 55.3 ns | **47x** |
| a sin/cos/sqrt/exp/ln chain | 3300 ns | 134 ns | **25x** |
| one turn of a script loop | 4638 ns | 23.4 ns | **199x** |
| bulk evaluation over an array | 1179 ns | 8.7 ns | **136x** |

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
