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

With the optional accelerator on top, the same formulas run between nine and a
hundred times faster, depending on what they do. The
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
`AsString` converts the answer to text; a quoted literal inside an expression is
rejected, since the language is arithmetic rather than string handling.

If a single answer is all you need, `CalcUtils` has the same calls as plain
functions over a parser it owns, which is what the program at the top uses.

This works on every target, console programs on Linux included. It did not always:
the owned `TCalculator` uses a synchronising timer, and under FPC that timer was
built from the widgetset, so a console program refused to link. The timer now runs
on a plain thread, and the core compiles against the RTL alone. All six samples
under `samples/docs` are compiled and run by both matrices, on Windows and Linux -
console programs, no widgetset anywhere.

Two units ask for more when you leave them at their defaults: `Thread` routes an
exception raised in a worker through `Application.HandleException`, and
`BlobManager` stores images as `TGraphic`. That is why the Lazarus package lists
the LCL. Define `NOFORMS` and `NOGRAPHICS` and both step aside - that is exactly
what the console matrices and the WebAssembly build do, and it is the honest
answer to "does this drag the LCL in": only if you want those two features.

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

## Building

Add `src` to the project search path, and `jit` as well if you want the
accelerator. On Delphi that is all a console build needs.

Free Pascal without the LCL needs three more things, and the Linux matrix in
`tests/build_parser_linux.sh` uses exactly them: `-dNOFORMS -dNOGRAPHICS` to
leave the GUI out, `src/compat` ahead of `src` for the stand-in units the RTL
does not carry there, and `-Fi src` for the includes.

| | |
|---|---|
| Delphi | 37.0 (Delphi 13), win32 and win64 |
| Free Pascal | 3.2.2 and 3.3.1, win64 and linux64 |
| Accelerator | machine code on x86-64; elsewhere the intermediate stage walks it, with the interpreter behind both |

Every line of that table is a matrix that runs before a release, not a guess.
Older compilers are likely to work and are not claimed to.

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
`tests/build_fpc.ps1` runs the battery under FPC on 64-bit Windows, and
`tests/build_parser_linux.sh` runs it on Linux.
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
  the scripts up front with `CompileScript` and run the compiled `TJitScript` from
  as many threads as you like - see [jit/USAGE.md](jit/USAGE.md).

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
