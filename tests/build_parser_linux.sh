#!/bin/bash
# Building and running the parser tests under FPC/Linux. The counterpart of
# build_fpc.ps1 from Windows.
#
# ParserBugTests uses Forms, so LCL and its widgetset are needed, and with them a
# display. On a machine without a desktop the run goes through Xvfb, otherwise GTK
# refuses to start.
# The FPC environment and the directories are set by variables:
#   FPC_ENV    a file that adds the right fpc to PATH (optional)
#   LAZ        the Lazarus directory, needed because of the Messages unit in LCL
#   PARSER_SRC the library directory, if the guess is wrong
#   PARSER_JIT the accelerator directory, if the guess is wrong
[ -n "${FPC_ENV:-}" ] && [ -f "${FPC_ENV}" ] && source "${FPC_ENV}"
# The Lazarus directory is asked of lazbuild itself instead of being guessed. A
# hardcoded /usr/lib/lazarus is not right everywhere: the package also puts it in
# /usr/share/lazarus/<version>, and then LCL is not found and the build stops at
# "Can't find unit Interfaces". That reads like a defect in the code, while the
# cause is a path.
if [ -z "${LAZ:-}" ]; then
  LAZBUILD=$(command -v lazbuild 2>/dev/null)
  [ -n "$LAZBUILD" ] && LAZ=$(dirname "$(readlink -f "$LAZBUILD")")
fi
LAZ=${LAZ:-/usr/lib/lazarus}
# The script directory is worked out in a checkable way: if dirname failed, cd goes
# nowhere and pwd returns the current directory, and the run stays green only
# because it was started from the right place.
D=$(dirname "$0")
DCODE=$?
if [ "$DCODE" -ne 0 ] || [ -z "$D" ]; then
  echo "SCRIPT DIRECTORY NOT RESOLVED: dirname returned $DCODE"
  exit 1
fi
HERE=$(cd "$D" && pwd)
if [ -z "$HERE" ] || [ ! -d "$HERE" ]; then
  echo "SCRIPT DIRECTORY NOT RESOLVED: $D"
  exit 1
fi

# In the monorepo the library sits in 0-foundation/pascal and pascal-jit, in the
# published repository in src and jit next to the tests.
#
# Two layouts present at once is not a reason to take whichever turned up first, it
# is a sign that the situation is unclear and a person has to decide. An unrelated
# directory named pascal next to the release tree quietly CHANGES THE SUBJECT OF THE
# CHECK: measured on 11.08.2026 on a copy of the deployment, a broken published src
# gave zero failures and code 0, because the neighbour was the thing being built.
MONO="$HERE/../../pascal"
SHIP="$HERE/../src"
MONOJIT="$HERE/../../pascal-jit"
SHIPJIT="$HERE/../jit"
# The layout is settled ONCE, and both roots are derived FROM IT. Picking the roots
# separately closed the ambiguity only: if there is no jit of its own while a foreign
# one lies next to it, the refusal did not fire and the gate took the foreign one,
# masking the absence.
#
# THE LIMIT OF TRUST: both variables set means the person has deliberately allowed
# any pair, and the gate treats it as authoritative.
if [ -n "${PARSER_SRC:-}" ] && [ -n "${PARSER_JIT:-}" ]; then
  SRC=$PARSER_SRC
  JIT=$PARSER_JIT
elif [ -n "${PARSER_SRC:-}" ] || [ -n "${PARSER_JIT:-}" ]; then
  echo "ROOTS GIVEN BY HALVES: the other half would have to be guessed"
  echo "  set both PARSER_SRC and PARSER_JIT - or neither"
  exit 1
else
  MONOOK=0; [ -d "$MONO" ] && [ -d "$MONOJIT" ] && MONOOK=1
  SHIPOK=0; [ -d "$SHIP" ] && [ -d "$SHIPJIT" ] && SHIPOK=1
  if [ "$MONOOK" = 1 ] && [ "$SHIPOK" = 1 ]; then
    echo "LAYOUT IS AMBIGUOUS: both are complete - $MONO with $MONOJIT, and $SHIP with $SHIPJIT"
    echo "  set PARSER_SRC and PARSER_JIT explicitly - otherwise what is checked is unknown"
    exit 1
  elif [ "$MONOOK" = 1 ]; then
    SRC=$(cd "$MONO" && pwd); JIT=$(cd "$MONOJIT" && pwd)
  elif [ "$SHIPOK" = 1 ]; then
    SRC=$(cd "$SHIP" && pwd); JIT=$(cd "$SHIPJIT" && pwd)
  else
    echo "NO COMPLETE LAYOUT, and filling it from a neighbour is forbidden. What is missing:"
    [ -d "$MONO" ] || echo "  no $MONO"
    [ -d "$MONOJIT" ] || echo "  no $MONOJIT"
    [ -d "$SHIP" ] || echo "  no $SHIP"
    [ -d "$SHIPJIT" ] || echo "  no $SHIPJIT"
    exit 1
  fi
fi

LCL=$LAZ/lcl/units/x86_64-linux
LU=$LAZ/components/lazutils/lib/x86_64-linux

# Leaving the tree OUTWARDS, one rule for all the scripts, see runroot.sh.
. "$HERE/runroot.sh" || { echo "REFUSED: runroot.sh not sourced"; exit 1; }
runroot_init "$HERE/../.." || exit 1

# Two directories rather than one: a build with LCL and a console build give
# incompatible ppu files, and a shared directory left the second mode with the
# leftovers of the first.
OUT=$RUNROOT/fpc-linux
OUT_CONSOLE=$RUNROOT/fpc-linux-console
mkdir -p "$OUT" "$OUT_CONSOLE" || { echo "REFUSED: output directories not created"; exit 1; }
echo "run root: $RUNROOT"
cd "$HERE"

RUN=""
[ -z "$DISPLAY" ] && command -v xvfb-run >/dev/null && RUN="xvfb-run -a"

# The list follows the Windows one. Five sets - ConstantsTest,
# ExitRoutingTest, LoopGuardTest, ThreadSafetyTest, ThreadShareTest - did
# not run here at all, and ConstantsTest is among them: it is the set that
# holds both debts of the parser.
TARGETS="${@:-ParserBugTests ThreadWaitTest JitDump JitBench JitParserTest JitContractTest PublicApiTest DocumentedSyntaxTest JitRedirectTest ExitRoutingTest LoopGuardTest LoopScopeTest ThreadSafetyTest ThreadShareTest DemoSpeed BigScript MathFamilyTest FpuMaskTest MethodLockTest ConstantsTest ScientificTest SignCacheTest PlatformTextTest CacheContractTest C31Console}"

# Two ways of building, and the difference is fundamental.
#
# ParserBugTests and ThreadWaitTest pull in Forms, they need LCL with a widgetset.
# The other tests are console ones, and LCL must not be pulled in for them: the
# widgetset paths drag in wsforms, and without the Interfaces unit its registration
# does not exist, so linking falls over on WSRegisterCustomForm. Earlier this went
# unnoticed because all the tests except two pulled in Interfaces anyway.
#
# The console ones are built with src/compat, where the replacement for Messages
# lies, and without a single path to Lazarus: RTL is enough for the library. That is
# checked by a run rather than assumed.
NEEDS_LCL=" ParserBugTests ThreadWaitTest "

# The widgetset directory inside LCL. Naming it by guesswork is not allowed: builds
# of Lazarus differ, gtk2, gtk3, qt5, nogui, and the Interfaces unit lies exactly
# there. A hardcoded name gave "Can't find unit Interfaces" on a sound machine, and
# the refusal read as a defect in the code. We take the first directory where that
# unit is.
WIDGETSET=""
for W in gtk2 gtk3 qt5 qt6 nogui; do
  if [ -f "$LCL/$W/interfaces.ppu" ]; then WIDGETSET="$LCL/$W"; break; fi
done
if [ -z "$WIDGETSET" ]; then
  echo "WARNING: no widgetset with an Interfaces unit was found in $LCL"
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
echo "=== RESULT: failures $FAILED ==="
exit $FAILED
