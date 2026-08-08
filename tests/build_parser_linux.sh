#!/bin/bash
# Build and run the parser tests on FPC/Linux. The counterpart of build_fpc.ps1.
#
# ParserBugTests uses Forms, so it needs the LCL and its widgetset, and with
# them a display. On a machine without a desktop the run goes through Xvfb,
# otherwise GTK refuses to start.
# The FPC environment and the folders are set by variables:
#   FPC_ENV    - a file that puts the right fpc on PATH (optional)
#   LAZ        - the Lazarus folder, needed for the Messages unit in the LCL
#   PARSER_SRC - the library folder, if the guess is wrong
#   PARSER_JIT - the accelerator folder, if the guess is wrong
[ -n "${FPC_ENV:-}" ] && [ -f "${FPC_ENV}" ] && source "${FPC_ENV}"
# The Lazarus folder is asked of lazbuild rather than guessed. A hard-wired
# /usr/lib/lazarus is not right everywhere: the package also installs it into
# /usr/share/lazarus/<version>, and then the LCL is not found - the build stops
# on "Can't find unit Interfaces". That reads like a defect in the code while
# the fault is in the path.
if [ -z "${LAZ:-}" ]; then
  LAZBUILD=$(command -v lazbuild 2>/dev/null)
  [ -n "$LAZBUILD" ] && LAZ=$(dirname "$(readlink -f "$LAZBUILD")")
fi
LAZ=${LAZ:-/usr/lib/lazarus}
HERE=$(cd "$(dirname "$0")" && pwd)

# In the monorepo the library lives in 0-foundation/pascal and pascal-jit; in
# the published repository it is src and jit next to the tests.
if [ -n "${PARSER_SRC:-}" ]; then SRC=$PARSER_SRC
elif [ -d "$HERE/../../pascal" ]; then SRC=$(cd "$HERE/../../pascal" && pwd)
else SRC=$(cd "$HERE/../src" && pwd); fi
if [ -n "${PARSER_JIT:-}" ]; then JIT=$PARSER_JIT
elif [ -d "$HERE/../../pascal-jit" ]; then JIT=$(cd "$HERE/../../pascal-jit" && pwd)
else JIT=$(cd "$HERE/../jit" && pwd); fi

LCL=$LAZ/lcl/units/x86_64-linux
LU=$LAZ/components/lazutils/lib/x86_64-linux
# Two output folders, not one: the LCL build and the console build produce
# incompatible ppu files, and a shared folder left the second mode with the
# leftovers of the first.
OUT=$HERE/out/fpc-linux
OUT_CONSOLE=$HERE/out/fpc-linux-console
mkdir -p "$OUT" "$OUT_CONSOLE"
cd "$HERE"

RUN=""
[ -z "$DISPLAY" ] && command -v xvfb-run >/dev/null && RUN="xvfb-run -a"

TARGETS="${@:-ParserBugTests ThreadWaitTest JitDump JitBench JitParserTest JitContractTest PublicApiTest DocumentedSyntaxTest JitRedirectTest DemoSpeed BigScript MathFamilyTest LoopScopeTest FpuMaskTest MethodLockTest C31Console}"

# Two ways to build, and the difference matters.
#
# ParserBugTests and ThreadWaitTest use Forms and need the LCL with a widgetset.
# The other tests are console programs and must NOT be given the LCL: the
# widgetset paths pull in wsforms, whose registration does not exist without the
# Interfaces unit, and linking fails on WSRegisterCustomForm. This used to go
# unnoticed because every test but two pulled in Interfaces anyway.
#
# The console ones are built with src/compat, which holds the stand-in for
# Messages, and without a single path to Lazarus: the RTL is enough for the
# library. That is proved by building, not assumed.
NEEDS_LCL=" ParserBugTests ThreadWaitTest "

# The widgetset folder inside the LCL. Naming one is a guess: a Lazarus
# build carries gtk2, gtk3, qt5 or nogui, and the Interfaces unit lives in
# whichever it is. A hardwired name reported a missing unit on a healthy
# machine, and the refusal read like a defect in the code. Take the first
# folder that actually holds the unit.
WIDGETSET=""
for W in gtk2 gtk3 qt5 qt6 nogui; do
  if [ -f "$LCL/$W/interfaces.ppu" ]; then WIDGETSET="$LCL/$W"; break; fi
done
if [ -z "$WIDGETSET" ]; then
  echo "WARNING: no widgetset with an Interfaces unit under $LCL"
fi

FAILED=0
for T in $TARGETS; do
  echo "=== BUILD $T ==="
  rm -f "$OUT/$T" "$OUT_CONSOLE/$T"
  if [[ "$NEEDS_LCL" == *" $T "* ]]; then
    fpc -MDelphi -O2 -Sh -B -Fu"$SRC" -Fu"$JIT" -Fu"$LCL" -Fu"$WIDGETSET" -Fu"$LU" \
        -Fi"$SRC" -FU"$OUT" -FE"$OUT" "$T.dpr" 2>&1 \
      | grep -E 'Error:|Fatal:' | head -20
  else
    fpc -MDelphi -O2 -Sh -B -dNOFORMS -dNOGRAPHICS \
        -Fu"$SRC/compat" -Fu"$SRC" -Fu"$JIT" \
        -Fi"$SRC" -FU"$OUT_CONSOLE" -FE"$OUT_CONSOLE" "$T.dpr" 2>&1 \
      | grep -E 'Error:|Fatal:' | head -20
  fi
  if [[ "$NEEDS_LCL" == *" $T "* ]]; then WHERE=$OUT; else WHERE=$OUT_CONSOLE; fi
  if [ ! -x "$WHERE/$T" ]; then echo "BUILD FAILED: $T"; FAILED=$((FAILED+1)); continue; fi
  echo "=== RUN $T ==="
  $RUN "$WHERE/$T" 2>&1 | grep -v 'Gtk-WARNING\|Gtk-CRITICAL'
  CODE=${PIPESTATUS[0]}
  echo "code=$CODE"
  [ $CODE -ne 0 ] && FAILED=$((FAILED+1))
done
echo "=== TOTAL: failures $FAILED ==="
exit $FAILED
