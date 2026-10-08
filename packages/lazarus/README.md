# MathParser in Lazarus / Free Pascal

MathParser and its accelerator build with Free Pascal 3.2.2. The accelerator
generates native code on supported x86-64 targets and uses its portable
executor or the interpreter for expressions that native compilation declines.

## Packages

| Package | Contents | Required package |
|---|---|---|
| `crosspascal_parser.lpk` | Parser and supporting components; 46 source units | `FCL` |
| `crosspascal_parserjit.lpk` | Accelerator; four source units | `crosspascal_parser` |

The packages declare registration procedures for these components:
`TParser`, `TMathParser`, `TJitParser`, `TCalculator`, `TParseValueList`,
`TParseManager`, `TConnector`, `TCalcThread`, `TSyncThread`, `TSyncTimer`,
`TExactTimer` and `TBlobManager`.

Both package files define `NOFORMS` and `NOGRAPHICS`. The parser package
adds `src/compat` on non-Windows targets; Windows uses the RTL Messages unit.
These configurations do not require LCL or LazUtils.
Applications using the optional graphics support need the corresponding LCL
units and widget set.

## Use in a project

In Lazarus, choose **Package > Open Package File**, open
`crosspascal_parser.lpk` and select **Compile**. Repeat for
`crosspascal_parserjit.lpk`. Select **Use > Add to Project** for the packages
your application needs. This adds dependencies without rebuilding the IDE.

## Install components into the IDE

1. Open `crosspascal_parser.lpk`, compile it and select **Use > Install**.
2. Open `crosspascal_parserjit.lpk`, compile it and select **Use > Install**.
3. Accept **Rebuild Lazarus** and restart the rebuilt IDE. If the first package
   prompts for a rebuild before the second is selected, complete that rebuild
   first, then install the second package.
4. Create an application with a form. On the `CrossPascal` palette page, place
   `TMathParser` and `TJitParser`, save the form, close it and reopen it.
5. Build and run the application.

Compiling a package or adding it to a project does not install its components
into the IDE palette. Command-line and non-visual applications do not need
the IDE installation steps.

## Build and run the tests

From the repository root on Windows:

```powershell
$env:FPC_EXE = 'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe'
$env:LAZARUS_DIR = 'C:\lazarus'
$env:RUNROOT = 'C:\mathparser-test-output'
powershell -NoProfile -ExecutionPolicy Bypass -File tests/build_fpc.ps1
```

Use the paths of your installation. Keep `RUNROOT` outside the source tree.
`ParserBugTests` and `ThreadWaitTest` require LCL and a matching widget set;
the other programs use the console configuration. Missing prerequisites are
reported as unsuccessful or skipped tests, not as successful execution.

On Linux, use `tests/build_parser_linux.sh`; graphical tests require a display
or Xvfb. The `LAZ` environment variable selects the Lazarus installation.
Unix programs using worker threads must include `cthreads` before other units
that use threads, as shown in the supplied examples for FPC 3.2.2.

On 8 October 2026, FPC 3.2.2 on x86_64-win64 completed 1016 checks in 21
counted programs, with no failed or skipped runs. The console component
example also ran successfully. Delphi 13.2 completed 1105 checks in 26
Win64 programs and 122 checks in two additional Win32 runs.

## Loop limits and cancellation

`ParseLoopLeft` and `ParseBreak` apply to interpreted and compiled loops.
An exhausted iteration budget or a cancellation request stops the entire
evaluation before an enclosing assignment can complete. The exception matches
the interpreter's response.

The native compiler supports up to 64 loop guards per formula. A formula
requiring more guards is declined as a whole. `AsDouble` and `ExecuteMany`
fall back to interpreted execution. When using `CompileScript`, check
`Compiled.Ready`; if it is false, call `ExecuteScript` with the source script.
`Compiled.Reason` identifies why native compilation was declined.

The loop tests cover 63, 64 and 65 guards, nested loops, cancellation, finite
iteration budgets and unarmed guards through scalar, compiled and bulk calls.

## Concurrent execution

Prepare scripts and finish parser registration before starting worker threads.
A ready `TJitScript` may be shared only when its variables and called functions
also permit concurrent access. Keep the parser alive and unchanged while the
workers execute. Each worker using the ordinary interpreter needs its own
copy of the source bytecode, because `ExecuteScript` writes into that buffer.

See [accelerator usage](../../jit/USAGE.md) for readiness, lifetime, variable
redirection and floating-point exception handling.
