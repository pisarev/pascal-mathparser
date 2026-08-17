# MathParser

Expression parser and virtual machine for Object Pascal. It compiles a formula
to flat bytecode, runs it with a linear pass over memory, and on x86-64 can
compile that bytecode to machine code.

Delphi and Free Pascal, Windows and Linux, one source. MIT licensed.

Try it without installing anything: the
[live demo](https://pisarev.github.io/mathparser-live/demo/) runs this very
parser, compiled to WebAssembly, in your browser. The pages around it walk
through [getting started](https://pisarev.github.io/mathparser-live/start.html),
the [syntax](https://pisarev.github.io/mathparser-live/syntax.html), the
[accelerator](https://pisarev.github.io/mathparser-live/accelerator.html) and
what the parser [will not do](https://pisarev.github.io/mathparser-live/limitations.html).

```pascal
program Hero;

{$APPTYPE CONSOLE}

uses
  CalcUtils;

begin
  Writeln(AsInteger('2 + 2'));
end.
```

That is a whole program, and it prints 4. Every listing in this file is a file
under `samples/docs`, compiled and run by the build matrix, so none of them can
drift from what actually works.

## Why another one

Most expression parsers build a tree of objects and walk it. This one compiles
to a contiguous byte array and runs a linear pass with no allocations. On top of
that it caches by *shape*: once `2 + 3` has been compiled, `5 + 7` reuses the
same script and only writes the numbers into a copy.

With the optional accelerator on top, the same formulas run 9x to 167x faster,
depending on what they do - the ends of that range are the slowest and the
fastest row of the measured table, not a guess. The
[measured table](https://pisarev.github.io/mathparser-live/accelerator.html) says
which is which, how many runs each row was averaged over, and what exactly was
compared. Those are the current Delphi numbers, and they come from one file the
benchmark programs write - `build/bench.tsv` in the site repository - rather than
from anybody's typing.

Other tables in this repository are other runs, and each says which: the one in
`jit/README.md` names the program that produced it and the date, the one beside
the Lazarus packages is Free Pascal rather than Delphi. Numbers that describe a
past release are allowed to stay, as long as they are named as past.

One `AsDouble` call, start to finish, averaged over a million runs. These are the
numbers printed by `tests/JitParserTest.dpr` on the machine that prepared this
release, and two consecutive runs agreed to within a few per cent. Run them on
your own machine rather than trusting the table: the ratio depends on the
compiler, the cache and what else the machine is doing.

## Thirty seconds

```pascal
program BindVar;

{$APPTYPE CONSOLE}

uses
  Parser;

var
  P: TMathParser;
  X: Double;
begin
  P := TMathParser.Create(nil);
  try
    P.AddVariable('x', X);
    X := 2.5;
    Writeln(P.AsDouble('x * 2 + 1'):0:1);
  finally
    P.Free;
  end;
end.
```

A variable is bound by address, so assigning to `X` is all it takes for the next
evaluation to see the new value.

Ask for the type you want and the conversion happens on the way out:
`AsInteger`, `AsDouble`, `AsExtended`, `AsBoolean`, `AsString`, `AsDateTime`.
`AsString` converts the answer to text. The language itself is arithmetic rather
than string handling, and that shows up in two ways. Pascal-style single quotes
are refused outright: the parser answers `contains reserved character`. A
double-quoted literal standing on its own is refused as well. But double quotes
are how text reaches the functions that read text - `Parse("2 + 3")` evaluates
to 5.

If a single answer is all you need, `CalcUtils` has the same calls as plain
functions over a parser it owns, which is what the program at the top uses.

This works on every target, console programs on Linux included. It did not always:
the owned `TCalculator` uses a synchronising timer, and under FPC that timer was
built from the widgetset, so a console program refused to link. The timer now runs
on a plain thread, and the core compiles against the RTL alone. All eight samples
under `samples/docs` are compiled and run by both matrices, on Windows and Linux -
console programs, no widgetset anywhere.

Two units ask for more when you leave them at their defaults: `Thread` routes an
exception raised in a worker through `Application.HandleException`, and
`BlobManager` stores images as `TGraphic`. Both stand behind `NOFORMS` and
`NOGRAPHICS`, and the Lazarus packages set those two defines themselves. So the
packages require no LCL, install without it, and a console project built against
them needs no `Interfaces` in its uses clause. Delphi is untouched by any of
this: it builds from the sources, where neither define is set and `TGraphic` is
the VCL one.

Want those two features under Lazarus? Drop the defines from
`packages/lazarus/crosspascal_parser.lpk` and add the LCL to its required
packages. Nothing else about the package changes.

## The accelerator

To run the hot path as machine code, change one word. Both halves of this print
the same number:

```pascal
P := TMathParser.Create(nil);
try
  Write(Answer(P):0:2, ' ');
finally
  P.Free;
end;

P := TJitParser.Create(nil);
try
  Writeln(Answer(P):0:2);
finally
  P.Free;
end;
```

`TJitParser` descends from `TMathParser`, so one variable holds either engine and
nothing else in your code changes. Whatever the compiler declines falls to the
stage below it - the intermediate one, and the interpreter behind that - without
a word, so the answer is never fast but wrong, and
`CodeReason` tells you why in one phrase. See [jit/README.md](jit/README.md).

## Syntax that surprises people

Five of these have caught every person who has used the library, including its
author.

- **Power is `**`, not `^`.** `^` is exclusive or. `x ^ 2` quietly returns
  `x xor 2`, which is a perfectly good number and almost never the one you meant.
- **`//` is a root, not a comment.** `8 // 3` is 2. There are no comments inside
  a formula.
- **Comparison answers -1.** True is -1 and false is 0, the Pascal convention for
  a boolean held as a number. So `(3 > 2) + 1` is 0, not 2. Use `AsBoolean` for a
  `Boolean`.
- **`!` is negation, not a factorial.** `!0` is -1, the same as `not 0`. The
  factorial is a function: `factorial(5)` is 120.
- **`exit` ends the whole evaluation, brackets included.** A bracketed group is a
  script in its own right, so `99 + (exit(42))` is 42 and never 141. That holds
  whichever way `ExecuteKindSet` is set; up to 1.0.1 the group kept its own `exit`
  when groups were evaluated up front. An `exit` belongs to the parser whose
  formula raised it: if that formula reaches a second parser and the second one
  calls back into the first, the `exit` passes the middle parser untouched and
  ends the evaluation it came from. Up to 1.0.2 the middle parser took it.

Case never separates two names. `Sin`, `sin` and `SIN` are one built-in, and a
variable registered as `Rate` also answers to `rate`; registering a second
`rate` beside it is refused rather than shadowing it.

There are 163 functions you can call, from `sin` to `weeksbetween`, and you can
add your own; the table holds 249 names in all, the rest being operators written
as signs, constants, and the words that drive the parser itself. `if` is lazy,
so `if(x <> 0, 1 / x, 0)` is safe. `parse` compiles a
formula while the outer one is running, and `deriv` differentiates symbolically.

## Adding your own function

The handler takes the parameters as an array and returns a `TValue`:

```pascal
type
  TPricing = class
    function Discount(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
      const PA: TParameterArray): TValue;
  end;

function TPricing.Discount(const Header: PScriptHeader; const AFunction: PFunction; const AType: PType;
  const PA: TParameterArray): TValue;
begin
  Result := MakeDouble(GetDouble(PA[0].Value) * (1 - GetDouble(PA[1].Value) / 100));
end;
```

Registering it needs a handle variable, and its type must be `TFunctionHandle`
from `ParseTypes`:

```pascal
    P.AddFunction('discount', Handle, fkMethod, MakeFunctionMethod(Pricing.Discount, 2, pkValue), False);
    P.AddVariable('rate', Rate);
    Rate := 20;
    Writeln(P.AsDouble('discount(1000, rate)'):0:2);
```

Two details cost time if you meet them by accident. A function called with
brackets takes `TMethod3` and a parameter count; `TMethod2` is for binary
operators, and using it for `f(a, b)` gives a formula that parses and then fails
at evaluation. And the handle must be a `TFunctionHandle`: on Delphi 12 and later
the library defines its own `NativeInt`, so the plain system type will not bind to
that `var` parameter and the compiler will only say that no overload matches -
while under FPC the library's `NativeInt` does not exist at all, so naming it
explicitly is not portable either. `TFunctionHandle` is right on every target. The
whole example is in `samples/docs/extend.dpr`.

## Installation

Nothing to install: this is a set of units. Clone it, put `src` on the search
path - and `jit` as well for the accelerator - and you are done. What follows is
that sentence turned into commands that have been run.

```
mkdir %USERPROFILE%\Desktop\Parser
cd /d %USERPROFILE%\Desktop\Parser
git clone https://github.com/pisarev/pascal-mathparser.git
cd pascal-mathparser
```

The commands are for `cmd`; where PowerShell needs something else it is said on
the spot.

### With Delphi, by hand

```
mkdir out
dcc64 -B -Q -U"src;jit" -I"src" -NS"System;System.Win;Winapi" -Eout samples\docs\bindvar.dpr
out\bindvar.exe
```

That builds one of the listings from this file and runs it; it prints `6`.

Three things about that command line, each of which stops the compiler when it is
missing. The namespace prefixes have to be given: the IDE takes them from the
project, `dcc64` does not, and without them it fails on `SysUtils` and then on
`Windows`. The include path has to be given separately from the unit path: the
IDE passes one search path as both, `dcc64` does not. And in PowerShell the
quotes have to stay, since the switches carry semicolons.

`dcc64` is not on the path by default - it lives in the `bin` folder of the
installation, and `rsvars.bat` there puts it on the path of the current prompt.

### With Delphi, by script

The design-time packages are built for you:

```
pwsh -File packages\delphi\build.ps1
```

It ends with `Delphi packages: did not build 0`. Install
`packages\delphi\crosspascal_parser_dsgn.dproj` from the IDE afterwards if you
want the components on the palette.

### With Lazarus, by hand

The packages build from a configuration of their own, which leaves your installed
Lazarus exactly as it was:

```
mkdir lazpcp
"C:\lazarus\lazbuild.exe" --pcp=%CD%\lazpcp packages\lazarus\crosspascal_parser.lpk
"C:\lazarus\lazbuild.exe" --pcp=%CD%\lazpcp packages\lazarus\crosspascal_parserjit.lpk
```

The second one is the accelerator and is optional.

### With Free Pascal, by script

The battery under FPC on Windows:

```
set FPC_EXE=C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe
set LAZARUS_DIR=C:\lazarus
pwsh -File tests\build_fpc.ps1
```

It ends with `FPC DONE: failures 0, skipped 0`. Both variables are needed and for
different reasons: the first because a normal Lazarus install does not put `fpc`
on the path, the second because two of the test programs reach LazUtils, and
without it they stop at `Can't find unit FPCAdds used by LazUTF8`.

On Linux the same battery is `tests/build_parser_linux.sh`.

## Building

Add `src` to the project search path, and `jit` as well if you want the
accelerator. On Delphi that is all a console build needs.

Free Pascal without the LCL needs three more things, and the Linux matrix in
`tests/build_parser_linux.sh` uses exactly them: `-dNOFORMS -dNOGRAPHICS` to
leave the GUI out, `src/compat` ahead of `src` for the stand-in units the RTL
does not carry there, and `-Fi src` for the includes.

Under Lazarus you need none of it by hand: the packages in `packages/lazarus`
set the defines themselves and add `src/compat` on the targets whose runtime has
no unit of that name - which is why they do not add it on Windows, where it
would stand in front of the system one. Open `crosspascal_parser.lpk` and add it
to your project - `Use` -> `Add to project` in the package window; add
`crosspascal_parserjit.lpk` the same way for the accelerator, and a console
project needs nothing else. The projects in `samples/docs` are set up that way -
open any `.lpi` and build it.

Both packages also install into the IDE. Open `crosspascal_parser.lpk` and press
`Install`: the IDE rebuilds itself, and eleven components appear on the
`Samples` palette page - `TParser`, `TMathParser`, `TCalculator`, `TCalcThread`,
`TParseManager`, `TParseValueList`, `TConnector`, `TBlobManager`, `TSyncThread`,
`TSyncTimer` and `TExactTimer`. You do not need any of that to use the library
from code; install it only if you want to drop those components on a form.

One of them deserves a warning. `TExactTimer` calls `OnTimer` in a **different
thread** under FPC, while under Delphi the same component calls it in the main
one: there the timer is a window timer, here it is a thread. Anything you do in
that handler must be safe to do off the main thread - no windows, no canvases,
no fonts or pens. Hand the work to the main thread instead, and keep the handler
to that hand-off.

| | |
|---|---|
| Delphi 10.2 Tokyo through 13 | win32, win64 |
| Free Pascal 3.2.2 | win32, win64, linux64 |
| Free Pascal 3.3.1 | win64 |
| Accelerator | machine code on x86-64; elsewhere the intermediate stage walks it, with the interpreter behind both |

Every line of that table is a matrix that runs before a release, not a guess.
The Delphi row is six installations - 10.2 Tokyo, 10.3 Rio, 10.4 Sydney, 11
Alexandria, 12 Athens and 13 - and on each of them the units are compiled one at
a time: 50 of the 51 build. The one that does not is `WinMem`, which carries a
`MODE` directive in its header and belongs to Free Pascal alone. `PLATFORMS.tsv`
beside the sources declares that, and both the build script and the release
check read the table rather than a list of their own. Anything older than 10.2
is untested and not claimed.

On Free Pascal 3.2.2 one thing is narrower. Function references - `reference to
function` - arrived in 3.3.1, so on 3.2.2 the iterator callbacks in `MemoryUtils`
are method pointers instead: you pass a method where you would otherwise pass an
anonymous function. Nothing else changes, and nothing inside the library uses
those callbacks. Nine functions that 3.2.2 lacks in its `Math` unit - `ArcCot`,
`ArcCotH`, `ArcCsc`, `ArcCscH`, `ArcSec`, `ArcSecH`, `CotH`, `CscH`, `SecH` -
travel with the library, taken verbatim from the 3.3.1 runtime so the values
agree to the last bit. `tests/MathFamilyTest.dpr` is what keeps them agreeing.

## Tests

`tests/build.ps1` builds and runs the battery under Delphi. Two of the targets
run on both word sizes - that is where a 32-bit answer once differed from the
64-bit one - and the rest are 64-bit, which is where the code generator lives.
`tests/build_fpc.ps1` runs the battery under FPC on Windows - point `FPC_EXE` at
a 32-bit compiler and it runs there too, which is a separate installation rather
than a switch, because FPC will not target i386 from a host whose `Extended` is
`Double`. `tests/build_parser_linux.sh` runs it on Linux.
`ci/check-windows.ps1` and `ci/check-linux.sh` run the whole matrix, including a
per-unit compile that catches conditional branches nothing else reaches, the
documentation samples, and the Linux side at two locales.

The fuzzer in `tests/JitParserTest.dpr` writes random formulas and has both
engines evaluate each one: 3000 formulas, zero disagreements, none declined.

Three test files are about contracts rather than answers, which is a distinction
this library learned the hard way:

- `JitContractTest.dpr` asserts that machine code really ran. Comparing values
  cannot see a silently declined formula, because a stage below then answers and
  the answer is correct.
- `PublicApiTest.dpr` calls the library the way a stranger does, from outside the
  compiled unit, which is the only way the `NativeInt` trap above is visible.
- `DocumentedSyntaxTest.dpr` runs every claim this file makes about the language.
  A sentence here is either checked there or it is not published.

## Stopping a formula that will not finish

`while`, `repeat` and `for` can be written so that they never end. Two guards in
`ParseTypes` let the caller take control back. Both are off by default, so a
program that already runs its loops to completion is unaffected.

```pascal
ArmLoopGuard(Guard, 1000);
try
  Note := '';
  try
    P.AsDouble('While(1 = 1, Set("cnt", cnt + 1))');
  except
    on E: Exception do Note := E.Message;
  end;
finally
  DisarmLoopGuard(Guard);
end;
Writeln(Format('%s stopped it, cnt reached %.0f', [Copy(Note, 1, 10), GetDouble(Cnt)]));
```

That prints `Loop limit stopped it, cnt reached 999`: the guard is read before
each turn, so the thousandth read is the one that stops a loop that has run 999
times. The cancellation flag is the other half - pass it as the third argument
of `ArmLoopGuard`, a worker thread's `Stopped` typically. It is read at the same
place, so a formula that spins from the very first turn still stops. Inside WebAssembly the
budget is the only way out at all, since a module cannot be interrupted from
outside. `nil` and zero mean no guard.

A spent budget is not the same as no budget: once it runs out, every further
loop in that run fails at once. Otherwise a single aborted evaluation would
silently lift the limit for everything after it - one point of a curve would
abort on the limit and the next would spin forever.

That is why the guard is armed in a pair. `DisarmLoopGuard` puts back whatever
was there before, so a spent budget stays spent for the rest of your run and
stops existing the moment the run ends. Without the pair it outlived the run:
the exhausted state is written as a negative number in a thread variable, and
the next piece of code in that thread - a different parser, a later button
press, something that never armed a guard at all - was refused on an honest ten
turn loop. Arming nests, too: a formula that calls `Parse` may arm a budget of
its own, and disarming it hands the outer one back rather than clearing the
thread.

Both guards are thread-local. One parser is normally shared by several threads,
and a field on the object would let one thread's cancellation tear down the
others. Inside a thread they are shared by every nested evaluation, and that is
deliberate: a formula function that evaluates another formula spends from the
same budget and watches the same flag. A budget per evaluation would be no
budget at all, since a nested loop can hang a page exactly as well as an outer
one.

## Known traps

- The handle passed to `AddFunction` must be a `TFunctionHandle`, and a `var`
  parameter of type `TArray<NativeInt>` coming from a compiled unit is likewise
  not the same type as a fresh one at the call site on Delphi 13. Use the
  library's named types: `TFunctionOrder` or `TNativeIntDynArray`.
- `Extended` is 10 bytes on 32-bit Delphi and on FPC for Linux, and 8 bytes on
  64-bit Windows, so the last bit of a long chain can differ between targets.
- `TJitParser` keeps a cache of compiled formulas and writes it without a lock, so
  one accelerating parser belongs to one thread. To evaluate in parallel, compile
  the scripts up front with `CompileScript` and run the compiled `TJitScript`:
  executing it does not modify it, so several threads may run one script - as far
  as the variables it reads and the functions it calls are themselves safe to use
  that way. See [jit/USAGE.md](jit/USAGE.md).

## Thread safety

A `TMathParser` instance may be shared by multiple OS threads only after its
evaluation configuration has been frozen. Complete all function, variable and
type registration, redirects, event-handler assignment and relevant property
changes before starting worker threads. Do not modify or destroy the parser
while an evaluation is active.

The floating point exception mask belongs to the thread, and the library treats
it that way: an evaluation installs its own mask - everything masked, so that
division by zero answers infinity instead of raising - and puts the caller's
mask back when it returns. A program that wants exceptions in its own arithmetic
keeps getting them, and a worker thread that never created the parser still gets
the documented answer. The mask an evaluation installs is the `ExceptionMask`
property; narrow it if you would rather have the exceptions inside formulas too.

A `TScript` is a mutable execution image, not immutable bytecode. Evaluation
writes intermediate and final values into the script headers. The same script
storage must therefore never have more than one active evaluation. This
restriction applies both to concurrent evaluations in different threads and to
reentrant evaluations in the same thread.

Every simultaneously active evaluation requires an independent byte copy:

```pascal
for I := 0 to High(Pack) do
begin
  P.StringToScript(StringReplace('v0 * v0 + 1', 'v0', 'v' + IntToStr(I), [rfReplaceAll]), Compiled);
  Pack[I].FScript := Copy(Compiled);
end;
for I := 0 to High(Pack) do Pack[I].Start;
```

A plain assignment - `WorkerScript := CompiledScript` - is not enough: after it
both variables refer to the same script storage, because that is what assigning
a dynamic array does in Delphi and in Free Pascal alike. A worker may reuse its
private copy for any number of serial, non-overlapping evaluations.

Registered variables and callbacks are external shared state. Variable storage
must either remain unchanged during parallel evaluation or be redirected to
storage private to the current worker. Registered callbacks, event handlers and
parser overrides must themselves be reentrant and thread-safe.

Operations that modify parser-owned or application-owned state are not part of
the parallel-evaluation contract. Do not concurrently perform registration,
deletion, redirect changes, parser-property changes or state-changing formula
operations on a shared parser. Formula functions such as `parse`, `new`,
`delete`, `set`, `setepsilon`, `setdecimalseparator` and other user or built-in
functions that mutate shared state require their own synchronization or isolated
parser state.

`ExecuteScript` returns a `PValue` that points into the supplied script buffer.
The pointer remains valid only while that exact buffer still exists and has not
been resized, reassigned or released. Its contents are overwritten by the next
execution of the same script storage. Read or copy the value immediately. Do not
retain the pointer and do not share it with another evaluation.

The high-level conversion methods such as `AsInteger`, `AsDouble`, `AsExtended`,
`AsBoolean`, `AsString` and `AsDateTime` return their results by value and are
the recommended public interface.

`TJitParser` has additional restrictions described in
[jit/USAGE.md](jit/USAGE.md).

## License

MIT, see [LICENSE](LICENSE).
