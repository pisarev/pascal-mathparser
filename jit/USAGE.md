# How to use the accelerator

The accelerator is a layer over the ordinary parser. The parser itself is
unchanged: you add the layer, change the parser class, and everything else works
as before. Whatever the accelerator cannot do it quietly hands back to the
ordinary parser - there are no wrong answers.

## Adding it to a project

Delphi: add `src` and `jit` to the project search path.
Lazarus: use the packages in `../packages/lazarus` (see the README there).

In uses:

```pascal
uses Parser, ParseTypes, ValueTypes, ValueUtils, ParseJit.Parser;
```

## Scenario 1. Formulas given as text (the simplest one)

Replace `TMathParser` with `TJitParser` - nothing else is needed, the machine
code turns itself on:

```pascal
var
  P: TJitParser;
  X: Double;
begin
  P := TJitParser.Create(nil);
  try
    P.AddVariable('x', X);        // bound by address, as usual
    X := 2.5;
    Writeln(P.AsDouble('x * 2 + 1'));       // machine code answers
    Writeln(P.AsDouble('mean(1, 2, 3)'));   // not supported - the parser answers, same result
  finally
    P.Free;
  end;
end;
```

A formula is compiled on the first call and cached; later calls with the same
text go straight into machine code.

## Scenario 2. A script compiled once and run in a loop

This is the case of the "Speed test of a compiled script execution" demo. The
ordinary code looks like this:

```pascal
FParser.StringToScript(edFormula.Text, Script);
FParser.OptimizeScript(Script);
for I := 1 to FRepeatCount do FParser.ExecuteScript(Script);
```

To put the accelerator on the job, three edits are needed: the parser class,
the compilation of the script, and the call inside the loop. `Ready` means the
accelerator has prepared an executable stage - machine code, or the portable
intermediate one; `Execute` goes through machine code where it is ready and
through the intermediate stage otherwise. That the intermediate stage usually
measures faster than the interpreter is a benchmark fact, not part of the
`Ready` contract:

```pascal
var
  FParser: TJitParser;          // was TParser
  Compiled: TJitScript;
...
FParser.StringToScript(edFormula.Text, Script);
FParser.OptimizeScript(Script);

Compiled := FParser.CompileScript(Script);       // prepare an executable stage
try
  if Compiled.Ready then
    for I := 1 to FRepeatCount do Compiled.Execute        // machine code where there is any
  else
    for I := 1 to FRepeatCount do FParser.ExecuteScript(Script);   // as before
finally
  Compiled.Free;
end;
```

`Compiled.Execute` returns a Double. If the script is not supported, the reason
is in `Compiled.Reason` (or `FParser.ScriptReason(Script)`).

Measurements for this scenario (Win64, Integer variables, as in the demo):

| Formula | interpreter | machine code | speedup |
|---|---:|---:|---:|
| `X + Y` | 176 ns | 9.7 ns | **18x** |
| `X * 2 + Y * 3` | 328 ns | 14.1 ns | **23x** |
| `(X + Y) * (X - Y) / 2` | 518 ns | 24.6 ns | **21x** |
| `X*X*X*3 + X*X*2 + X*7 + 11` | 758 ns | 28.2 ns | **27x** |
| `sin(X)*cos(Y) + sqrt(X*X + Y*Y)` | 943 ns | 92.7 ns | **10x** |
| `if(X > Y, X * 2, Y * 2)` | 2139 ns | 38.1 ns | **56x** |

## Scenario 3. One formula over an array of values

When a formula has to be evaluated for thousands of inputs there is a bulk mode:
compiled once, then called without overhead.

```pascal
var
  Inputs, Outputs: array of Double;
begin
  SetLength(Inputs, 1000000);
  SetLength(Outputs, 1000000);
  // ... fill Inputs ...
  if not P.ExecuteMany('x * x * 3 + 1', X, Inputs, Outputs) then
    ; // it did not parse, or the output is shorter: whatever the call could
    ;  // have written holds NaN
end;
```

That gives 121x to 141x over the ordinary path.

**Check the result.** `ExecuteMany` is the one call that reports a refusal to
the caller. On `False` everything it could have written holds "not a number", so
a caller who trusts the return value and reads on gets NaN rather than stale
numbers - which is the point.

## What machine code supports

- arithmetic: constants, variables, `*`, `/`, term signs, brackets;
- variables of type Double, Extended, Single, Integer, LongWord, Int64,
  NativeInt (integers are loaded with a conversion, everything is computed in
  Double);
- math: `sin`, `cos`, `tan`, `sqrt`, `sqr`, `ln`, `exp`, `abs`, `arctan`;
- comparison `=`, `<>`, `>`, `<`, `>=`, `<=`, with the same epsilon as the parser;
- control flow: `if`, `while`, `repeat`;
- script variables: `get` and `set` with the name resolved while compiling.

## What goes back to the ordinary parser

`for`, `tryexcept` and `tryfinally`, `new` and `delete`, functions that take a
parameter block (`mean`, `poly`, `min`, `max`), string operations, variables of
non-numeric types, integer constants above 2^53. Scripts with a redirect
category are compiled - the chain is resolved while building, and there is a
section on it below. On 32-bit builds there is no machine code at all - the
intermediate stage works instead (IR walking, 1.4-3.7x).

## Useful details

| What | How |
|---|---|
| Find out why a formula was not accelerated | `P.CodeReason('formula')` - an empty string means "machine code answers" |
| The same for a prepared script | `P.ScriptReason(Script)` |
| Turn the accelerator off for a while | `P.JitEnabled := False` |
| Clear the code cache by hand | `P.ClearCode` (it clears itself when the function registry changes) |
| Look at the statistics | `P.HitCount`, `P.MissCount`, `P.CompileCount` |
| See what a script was decoded into | `ParseJit.Decoder.DumpScript(P, Script)` - a disassembler for the format |

## Worth remembering

- Variables are bound by address: a variable must outlive the parser's use of it.
- Register every function and variable before evaluating. The code cache clears
  itself on notifications from the parser, but needless clearing costs a
  recompilation.
- A compiled script (`TJitScript`) is yours to hold and to free when it is no
  longer needed. It is tied to the script it was built from and to the parser
  that built it: once the parser is gone the object can still be freed, but not
  evaluated with.
- The accelerator computes in Double. If you need integer semantics on large
  numbers (beyond 2^53), use the ordinary parser.

## Threads: one accelerating parser belongs to one thread

`TJitParser` keeps a cache: the text of the last formula, the list of compiled
entries and the counters beside them. All of it is written the first time a
formula is met, and none of it is behind a lock. Two threads that run into a
formula the cache does not hold yet will both compile it and both append to the
list.

The plain `TMathParser` does not suffer from this: once everything is
registered, evaluating a ready script is thread-safe.

To evaluate in parallel, do what the plotting component does - and no locks are
needed for it:

- compile the scripts up front, in one thread, with `CompileScript`;
- run the ready `TJitScript` from as many threads as you like - evaluation does
  not change it.

## Parallel evaluation: redirecting variables

When several threads evaluate one formula, each needs its own variable. The
parser does this by redirection: a script is marked with a category
(`SetRedirectCategory`), and a table (`CreateRedirect` plus `SetRedirect`)
translates a reference to the shared variable into the thread's own variable for
that category.

The accelerator supports this: the redirection chain is resolved while building,
and the address of the final variable goes into the code. The conditions are:

- every thread gets **its own copy of the script** with its own category;
- **building happens after all the preparation**. Any change to the parser -
  adding a variable, `Notify(ntCompile)` - invalidates code built earlier;
- the built object is yours, but it is bound to its parser: holding it and
  freeing it without the parser is fine, evaluating with it is not. See below.

```pascal
Script := Copy(Source);
Parser.SetRedirectCategory(Script, Category);
Redirect := Parser.CreateRedirect;
Parser.SetRedirect(Redirect, Category, GlobalHandle, LocalHandle);
// and only now
Compiled := Parser.CompileScript(Script);
if Compiled.Ready then Value := Compiled.Execute
else Value := GetExtended(Parser.ExecuteScript(Script)^);
```

## When built code goes stale

`Ready` answers two questions: did it build, and is it still correct. Built
code remembers the parser's generation and the assumptions it made about
redirection; as soon as the parser changes, or redirection starts pointing
somewhere else, `Ready` goes out and `Reason` says `parser changed`.

So there is one rule: **check `Ready` before using it**, and on a refusal
evaluate with the parser. Then the answer is always right, and as fast as it can
be.

## Lifetime: a script is bound to its parser

`TJitScript` is bound to the parser that built it. Outliving that parser is
allowed - the object can be held, inspected and freed. Evaluating with it once
the parser is gone is not: `Ready` goes out, `Reason` says `the parser that
compiled this script is gone`, and `Execute` raises `EJitOrphan`.

This is not caution. Built code holds more than one reference to the parser: the
check on redirection assumptions asks its table of functions, and the executor
for the intermediate representation keeps pointers to methods of its objects.
Neither of those outlives the parser, so evaluating afterwards would not be a
refusal but a read of freed memory.

What the contract does not promise: destroying the parser must not run at the
same time as a call into `TJitScript` or its own destruction. That is about two
threads in one moment, not about order - the order is free.

## What the accelerator can do with variables

- **a typed reference** (`AddVariable(Name, X: Double)` and friends) - a direct
  load from memory, the fastest path;
- **a `TValue` record** (`AddVariable(Name, V: TValue, ...)`) - the type is only
  known at evaluation time, so reading goes through a helper: one call more
  expensive than a load, but incomparably cheaper than parsing the script.
