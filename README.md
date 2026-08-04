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

| | Interpreted | Compiled | Times faster |
|---|---:|---:|---:|
| `x * 2 + 1` | 869 ns | 41 ns | 21 |
| polynomial, degree 3 | 1978 ns | 49 ns | 41 |
| heavy math chain | 2689 ns | 145 ns | 19 |
| one turn of a `while` loop | 3966 ns | 36 ns | 110 |
| bulk mode, `x * 2 + 1` | 902 ns | 8 ns | 121 |

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
on a plain thread, and the library needs `LazUtils` but no LCL. All six samples
under `samples/docs` are compiled and run by both matrices, on Windows and Linux.

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
nothing else in your code changes. Whatever the compiler declines it hands back
to the interpreter without a word, so the answer is never fast but wrong, and
`CodeReason` tells you why in one phrase. See [jit/README.md](jit/README.md).

## Syntax that surprises people

Four of these have caught every person who has used the library, including its
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

Case never separates two names. `Sin`, `sin` and `SIN` are one built-in, and a
variable registered as `Rate` also answers to `rate`; registering a second
`rate` beside it is refused rather than shadowing it.

There are 199 registered names, from `sin` to `weeksbetween`, and you can add
your own. `if` is lazy, so `if(x <> 0, 1 / x, 0)` is safe. `parse` compiles a
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
accelerator. There is nothing else to install: the library depends only on the
RTL.

| | |
|---|---|
| Delphi | 37.0 (Delphi 13) is what the matrix runs, win32 and win64 |
| Free Pascal | 3.2.2 and 3.3.1 are what the matrix runs, win64 and linux64 |
| Accelerator | x86-64 only; elsewhere the interpreter answers |

Older compilers are likely to work and are not claimed to: the table lists what
is actually built and run before a release, nothing more.

## Tests

`tests/build.ps1` builds and runs everything under Delphi on both word sizes;
`tests/build_fpc.ps1` and `tests/build_parser_linux.sh` do the same under FPC.
`ci/check-windows.ps1` and `ci/check-linux.sh` run the whole matrix, including a
per-unit compile that catches conditional branches nothing else reaches, the
documentation samples, and the Linux side at two locales.

The fuzzer in `tests/JitParserTest.dpr` writes random formulas and has both
engines evaluate each one: 3000 formulas, zero disagreements, none declined.

Three test files are about contracts rather than answers, which is a distinction
this library learned the hard way:

- `JitContractTest.dpr` asserts that machine code really ran. Comparing values
  cannot see a silently declined formula, because the interpreter then answers
  and the answer is correct.
- `PublicApiTest.dpr` calls the library the way a stranger does, from outside the
  compiled unit, which is the only way the `NativeInt` trap above is visible.
- `DocumentedSyntaxTest.dpr` runs every claim this file makes about the language.
  A sentence here is either checked there or it is not published.

## Known traps

- The handle passed to `AddFunction` must be a `TFunctionHandle`, and a `var`
  parameter of type `TArray<NativeInt>` coming from a compiled unit is likewise
  not the same type as a fresh one at the call site on Delphi 13. Use the
  library's named types: `TFunctionOrder` or `TNativeIntDynArray`.
- `Extended` is 10 bytes on 32-bit Delphi and on FPC for Linux, and 8 bytes on
  64-bit Windows, so the last bit of a long chain can differ between targets.
- Register every function and variable before the first evaluation. Evaluation is
  thread-safe after that; registration itself is not.

## License

MIT, see [LICENSE](LICENSE).
