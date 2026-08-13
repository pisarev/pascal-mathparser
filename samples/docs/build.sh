#!/bin/bash

# Guard against an early exit.
#
# source runs in the CURRENT shell, so the line "exit 0" in an environment file
# ended the WHOLE script with a zero code: the gate reported success without doing
# anything. Scanning the file for the word exit is fragile, so the guard watches
# the exit itself: if the script left before reaching the end, that is a failure
# whatever the code says.
FINISHED=""
trap 'C=$?; if [ -z "$FINISHED" ]; then echo "THE RUN BROKE OFF BEFORE THE END: code $C"; exit 1; fi' EXIT

#
# Building and running the samples from the documentation, the Linux side. The
# counterpart of build.ps1.
#
# Every sample is a real program with its expected output in a SEPARATE COMMENT
# LINE { expect: ... }. That line is not the first one: above it sits the licence
# header, and in no sample does the marker stand on the first line. It used to say
# "on the first line" here, a promise the code never made and could not make; to
# whoever checks, such a discrepancy reads as a defect in the code, while the
# defect was in the text. A sample that did not build or gave the wrong line does
# not reach the page.
#
# The return code is the number of samples that failed.

set -u
# An environment named explicitly has to APPLY, not to stay a wish.
#
# Before: if FPC_ENV was set but the file was missing or source returned an error,
# the script went on quietly with the default environment. The person said "use
# this file", got a refusal, and the run pretended nothing had happened, so it
# could check an entirely different compiler. Not set is fine; set means the file
# has to exist and source has to return 0.
if [ -n "${FPC_ENV:-}" ]; then
  if [ ! -f "$FPC_ENV" ]; then
    echo "ENVIRONMENT FILE MISSING: $FPC_ENV"
    exit 1
  fi
  # The environment file runs in a CHILD shell; only variables are taken back out.
  #
  # source means "run this in MY shell", and a script cannot defend itself against
  # code it pulls in: the lines "trap - EXIT; exit 0" and "exec /bin/true" in an
  # environment file ended the gate with a zero and in silence, measured. Patching
  # the guard is pointless, so foreign code is no longer allowed in here: exit, exec
  # and clearing traps touch the child process only.
  # The FULL state of the environment is carried out, removals included.
  #
  # export -p gives back the positive part only: if the environment file unsets a
  # variable, that does not travel out and the removal is lost in silence, the
  # person wrote unset and the gate pretended not to notice. So the list of names is
  # taken before and after, and the difference is applied explicitly.
  BEFORE=$(export -p)
  ENVDUMP=$(bash -c '. "$1" >/dev/null 2>&1 || exit 3; export -p' _ "$FPC_ENV")
  ECODE=$?
  if [ "$ECODE" -ne 0 ]; then
    echo "ENVIRONMENT FILE NOT APPLIED: $FPC_ENV - code $ECODE"
    exit 1
  fi
  if [ -z "$ENVDUMP" ]; then
    echo "ENVIRONMENT FILE NOT APPLIED: $FPC_ENV - the child shell exited early and returned no variables"
    exit 1
  fi
  eval "$ENVDUMP"
  # Names are compared WITH A LIST OF NAMES, not by searching the whole dump for a
  # string.
  #
  # The earlier check looked for "declare -x NAME=" anywhere in the dump, and that
  # text can turn up inside the VALUE of another variable, so a variable that had
  # been unset would look alive. The list of names is built first, and the
  # comparison then runs on whole names.
  ENVNAMES=""
  while IFS= read -r AL; do
    case "$AL" in "declare -x "*) ;; *) continue ;; esac
    AN=${AL#declare -x }
    AN=${AN%%=*}
    ENVNAMES="$ENVNAMES
$AN"
  done <<AFTER_END
$ENVDUMP
AFTER_END
  while IFS= read -r EL; do
    case "$EL" in "declare -x "*) ;; *) continue ;; esac
    ENM=${EL#declare -x }
    ENM=${ENM%%=*}
    FOUNDNAME=0
    while IFS= read -r AN2; do
      [ "$AN2" = "$ENM" ] && { FOUNDNAME=1; break; }
    done <<NAMES_END
$ENVNAMES
NAMES_END
    [ "$FOUNDNAME" = 0 ] && unset "$ENM"
  done <<BEFORE_END
$BEFORE
BEFORE_END
fi
# The script directory is worked out in a CHECKABLE way.
#
# It used to be HERE=$(cd "$(dirname "$0")" && pwd): when dirname fails the
# substitution yields an empty string, cd "" in bash goes nowhere, and pwd returns
# the CURRENT directory. The run stayed green only because it was started from the
# right place, by chance rather than by design.
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

# Library directories. In the monorepo these are 0-foundation/pascal and pascal-jit,
# in the published repository they are src and jit at the root. PARSER_SRC and
# PARSER_JIT override both guesses.
# The layout is settled UNAMBIGUOUSLY, otherwise the gate refuses.
#
# It used to be "whichever directory turned up first": an unrelated directory with
# a fitting name next to the release tree quietly CHANGED THE SUBJECT OF THE CHECK,
# and both gates came out green having checked the wrong tree. Two layouts present
# at once is not a reason to pick one, it is a sign that the situation is unclear
# and a person has to decide.
MONO="$HERE/../../pascal"
SHIP="$HERE/../../src"
MONOJIT="$HERE/../../pascal-jit"
SHIPJIT="$HERE/../../jit"
# The layout is settled ONCE, and both roots are derived FROM IT.
#
# The earlier version picked the roots SEPARATELY and closed the ambiguity only.
# That is not enough: if the release has no jit of its own while a foreign one lies
# next to it, the refusal does not fire because no second candidate exists, and the
# gate quietly takes the foreign one. A release without an accelerator of its own
# passes green, the absence masked by a neighbour.
#
# THE LIMIT OF TRUST, said out loud: if BOTH variables are set, the person has
# deliberately allowed any pair. The gate treats it as authoritative.
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
# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.sh.
RR=$HERE/../../tests/parser/runroot.sh
if [ ! -f "$RR" ]; then
  echo "REFUSED: run root rule not found: $RR"
  exit 1
fi
. "$RR" || { echo "REFUSED: run root rule not sourced"; exit 1; }
runroot_init "$HERE/../.." || exit 1
OUT=$RUNROOT/samples-docs
# The build directory is CLEARED: the outcome of a run must not depend on the past.
# A binary left from last time will start and print what is expected even if this
# build produced nothing. The same illness has already turned up in the
# unit-by-unit build: rubbish from the previous run gave 19 built units instead
# of 52.
rm -rf "$OUT"
# The return code of rm is asked for: a failed removal is the first link of a
# falsely green run in which nothing was built and last time's program was the one
# that ran.
RMCODE=$?
if [ "$RMCODE" -ne 0 ]; then
  echo "CLEANUP NOT DONE: rm returned $RMCODE"
  exit 1
fi
# The return code of mkdir is ASKED FOR as well.
#
# "The directory seems to have appeared" and "the program that created it finished
# successfully" are different statements. Measured on 11.08.2026: a stand-in mkdir
# created the directory and returned 7, the gate went on and left with a zero.
# Checking that the directory exists instead of the code means trusting an
# indirect sign instead of the contract.
mkdir -p "$OUT"
MKCODE=$?
if [ "$MKCODE" -ne 0 ] || [ ! -d "$OUT" ]; then
  echo "BUILD DIRECTORY NOT CREATED: mkdir returned $MKCODE"
  exit 1
fi

# Clearing is CHECKED rather than assumed: rm could have failed, and the run would
# go on with the very rubbish the clearing was put there to remove. Whoever checks
# has to PROVE that the directory was listed: a suppressed traversal error turned
# "could not look" into "empty".
LEFTERR=$(find "$OUT" -mindepth 1 2>&1 >/dev/null)
LEFTCODE=$?
# The verdict comes from the RETURN CODE, not from whether the tool said a word.
# A find that died in silence gave an empty LEFTERR, and that read as "no errors".
if [ "$LEFTCODE" -ne 0 ] || [ -n "$LEFTERR" ]; then
  echo "DIRECTORY DOES NOT LIST: $OUT"
  printf '%s\n' "$LEFTERR" | head -2 | sed 's/^/    /'
  exit 1
fi
# The status of the SECOND traversal is asked for exactly as for the first.
#
# Earlier it ran unchecked: a find that died in silence gave an empty LEFT, the
# directory was declared clean, and the run went on with last time's programs.
# Together with a failed rm this produced a fully green run in which nothing was
# built and yesterday's build was the one that ran.
LEFT=$(find "$OUT" -mindepth 1 2>/dev/null)
LCODE=$?
if [ "$LCODE" -ne 0 ]; then
  echo "DIRECTORY DOES NOT LIST: $OUT - find returned code $LCODE"
  exit 1
fi
LEFT=$(printf '%s\n' "$LEFT" | grep -v '^$' | head -3)
if [ -n "$LEFT" ]; then
  echo "OUTPUT DIRECTORY NOT CLEARED: $OUT"
  printf '%s\n' "$LEFT" | sed 's/^/    left over: /'
  exit 1
fi

FAILED=0

# The samples are console programs: they need neither forms nor graphics.
#
# Messages is taken from src/compat rather than from LCL: that one drags in a
# widgetset, and a console program does not link with it (there is no
# WSRegisterCustomForm and its kin). There is no Lazarus here at all, neither LCL
# nor LazUtils: RTL is enough for the library. If one day it stops being enough,
# this build will be the first to fall.
# Compiler arguments live in an ARRAY, not in a string.
#
# A string expands into shell words, and a path with a space is torn apart:
# -Fu/tmp/mp round13/src turned into two arguments, "-Fu/tmp/mp" and "round13/src".
# The outcome of the run does not show it, the compiler simply looks in the wrong
# place, so what has to be checked is the argv that was taken, not the return code.
FLAGS=(-MDelphi -Sh -O2 -B -dNOFORMS -dNOGRAPHICS)
PATHS=(-Fu"$SRC/compat" -Fu"$SRC" -Fu"$JIT" -Fi"$SRC")

# An empty list of samples is a failure too. A run that found not a single .dpr
# honestly reached "failures 0": there was nothing to check, and what was said was
# "checked and clean".
# The census of samples takes ORDINARY FILES: otherwise a directory named like
# Foo.dpr would land in the list of samples.
# The census of samples is built ONCE and serves both the counter and the traversal.
#
# There used to be two different meanings: find saw dot files while the for pattern
# skipped them. A hidden .Hidden.dpr gave "samples found 1", the loop checked zero
# files, and the run came out green. Reconciling two meanings makes no sense, the
# census has to be one.
# The census lives as an ARRAY on NUL separators, not as text with lines.
#
# A file name may contain a line break. In a text census such a name fell apart
# into two lines, neither of which is a file, both were quietly skipped, and an
# UNCHECKED sample gave a green run. The NUL separator is the only one that cannot
# turn up in a name.
ROSTER=$(mktemp) || { echo "ROSTER TEMPORARY FILE NOT CREATED"; exit 1; }
set -o pipefail
find "$HERE" -maxdepth 1 -type f -iname '*.dpr' -print0 | sort -z > "$ROSTER"
SCODE=$?
set +o pipefail
if [ "$SCODE" -ne 0 ]; then
  echo "THE SAMPLE ROSTER WAS NOT BUILT: code $SCODE"
  command rm -f "$ROSTER"
  exit 1
fi
SAMPLES=()
while IFS= read -r -d '' F; do SAMPLES+=("$F"); done < "$ROSTER"
command rm -f "$ROSTER"
COUNT=${#SAMPLES[@]}
echo "samples found: $COUNT"
if [ "$COUNT" -eq 0 ]; then
  echo 'NO SAMPLES FOUND: there was nothing to check'
  FAILED=$((FAILED + 1))
fi

for FILE in "${SAMPLES[@]}"; do
  [ -f "$FILE" ] || continue
  [ -e "$FILE" ] || continue
  # The name is taken by substitution and by the LAST dot: the census no longer tells
  # the case of the extension apart, so Foo.DPR has to give the name Foo, not Foo.DPR.
  # There is no external basename here either: its death went unchecked.
  NAME=${FILE##*/}; NAME=${NAME%.*}
  # The marker is taken ONLY FROM A SEPARATE COMMENT LINE, and the codes of the tools
  # are asked for.
  #
  # The earlier pattern snatched expect from anywhere in the file, including from the
  # CONTENTS of a string literal: a sample without a single real marker could get a
  # green verdict. The comment meanwhile promised "on the first line" while the code
  # took from everywhere, and promise and behaviour parted ways.
  #
  # And separately: the codes of both pipelines were not asked for at all. A head that
  # failed still managed to hand out the right result, and the gate went on as if
  # nothing had happened, a live counterexample to a rule I considered closed.
  EXPECT=$(set -o pipefail; sed -n 's/^[[:space:]]*{[[:space:]]*expect:[[:space:]]*\(.*\)[[:space:]]*}[[:space:]]*$/\1/p' "$FILE" | head -1)
  ECODE1=$?
  if [ "$ECODE1" -ne 0 ]; then
    echo "  MARKER NOT EXTRACTED: code $ECODE1"
    FAILED=$((FAILED + 1))
    continue
  fi
  EXPECT=$(set -o pipefail; printf '%s\n' "$EXPECT" | sed 's/[[:space:]]*$//')
  ECODE2=$?
  if [ "$ECODE2" -ne 0 ]; then
    echo "  MARKER NOT EXTRACTED: code $ECODE2"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Without a marker a sample IS NOT CHECKED, and staying silent about that is not
  # allowed.
  #
  # Below, the comparison runs by the pattern *"$EXPECT"*, and with an empty
  # expectation any output fits it: a sample printing obvious nonsense would pass
  # with a cheerful "ok".
  if [ -z "$EXPECT" ]; then
    echo "--- $NAME"
    echo "  NO { expect: ... } MARKER: there is nothing to compare the output with"
    FAILED=$((FAILED + 1))
    continue
  fi

  # There are no skips here: on unix every single sample is built and run. The skip
  # branch was there because of the timer in SyncThread, which under FPC was done by
  # the LCL widgetset; the timer has been moved to an ordinary thread, not a single
  # sample carries the "needs: lcl on unix" label any more, and the branch quietly
  # skipped an empty set.
  echo "--- $NAME (expecting: $EXPECT)"

  # The target is removed BEFORE EVERY build, not once for the whole batch.
  #
  # Two files whose names differ in the case of the extension give one program name.
  # The directory was cleared once at the start, so the second build found the binary
  # of the FIRST one, and the check "the build created a program" passed on a foreign
  # file, while the run started the wrong program and printed ok.
  #
  # The CODE of the removal itself IS ASKED FOR: otherwise the defence against a
  # stale binary rests on the assumption that it worked. Measured on 11.08.2026: a
  # stand-in rm refused on exactly $OUT/$NAME with code 9, the old program stayed in
  # place, and both samples got ok.
  if ! command rm -f "$OUT/$NAME"; then
    echo "  THE OLD PROGRAM WAS NOT REMOVED: $OUT/$NAME"
    FAILED=$((FAILED + 1))
    continue
  fi
  if [ -e "$OUT/$NAME" ]; then
    echo "  THE OLD PROGRAM IS STILL IN PLACE: $OUT/$NAME"
    FAILED=$((FAILED + 1))
    continue
  fi
  if ! fpc "${FLAGS[@]}" "${PATHS[@]}" -FU"$OUT" -FE"$OUT" "$FILE" > "$OUT/$NAME.build.log" 2>&1; then
    echo "  BUILD FAILED"
    grep -E 'Error:|Fatal:' "$OUT/$NAME.build.log" | head -3 | sed 's/^/      /'
    FAILED=$((FAILED + 1))
    continue
  fi

  # The build has to CREATE a program, not merely return a zero.
  if [ ! -x "$OUT/$NAME" ]; then
    echo "  THE BUILD PRODUCED NO PROGRAM: $OUT/$NAME"
    FAILED=$((FAILED + 1))
    continue
  fi

  # The output is taken INTO A FILE, not into a variable.
  #
  # $( ) strips TRAILING line breaks, which is a property of substitution rather than
  # a bug. So a program that printed exactly one line break gave an empty variable
  # and got ok on the marker "nothing printed": measured on 11.08.2026, output of a
  # single LF byte passed as complete silence. A shell variable is unfit in principle
  # for a promise of silence, what is needed is a carrier that keeps the bytes.
  RUNOUT=$(mktemp)
  ROCODE=$?
  if [ "$ROCODE" -ne 0 ] || [ -z "$RUNOUT" ]; then
    echo "  OUTPUT TEMPORARY FILE NOT CREATED: code $ROCODE"
    FAILED=$((FAILED + 1))
    continue
  fi
  if ! "$OUT/$NAME" > "$RUNOUT" 2>&1; then
    echo "  THE RUN FAILED"
    command rm -f "$RUNOUT"
    FAILED=$((FAILED + 1))
    continue
  fi
  # The output file has to EXIST after the run.
  #
  # Without this check a file that disappeared would read as empty, and empty with a
  # silence marker means ok. So the loss of the carrier of the evidence would give a
  # green verdict again, the same class one floor down.
  if [ ! -f "$RUNOUT" ]; then
    echo "  THE OUTPUT FILE DISAPPEARED: $RUNOUT"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Reading the file by BUILT-IN substitution, without an external program.
  #
  # What stood here was $(cat "$RUNOUT"), and nobody asked for the code of cat. With
  # that I closed the class "a helper program handed out a useful result and REPORTED
  # a failure, and the failure was forgotten", and by the same edit created it anew:
  # a stand-in cat that honestly passed the output through and returned 7 gave a
  # green verdict again. The device is the same one that closed basename and grep:
  # where a lawful outcome and a failure cannot be told apart by the code, the tool
  # is REMOVED rather than fenced with checks. No external process means no code that
  # can be forgotten.
  OUTPUT=$(<"$RUNOUT")

  # The last non-empty line is taken BY THE SHELL, without external programs.
  #
  # There used to be a pipeline printf | grep | tail | sed: the death of any link
  # gave an empty LAST, and with the marker nothing printed emptiness reads as ok, so
  # the death of whoever was checking turned into a green answer. There is nothing to
  # guard here: grep in this place LAWFULLY returns 1 when the program printed
  # nothing, and a threshold over the pipeline would not tell the lawful case from
  # the failure.
  LAST=''
  while IFS= read -r LN; do
    LN="${LN#"${LN%%[![:space:]]*}"}"
    LN="${LN%"${LN##*[![:space:]]}"}"
    [ -n "$LN" ] && LAST=$LN
  done <<LASTLINE
$OUTPUT
LASTLINE
  # The promise of silence is checked BY THE SIZE OF THE FILE, not by a variable.
  #
  # Checking by the trimmed last line was wrong: a program printing a line of spaces
  # or tabs gave emptiness after trimming and got ok. But "nothing was printed" and
  # "a line of spaces was printed" are different states, and the marker promises the
  # first. The variable is unfit for a second reason as well: it has already been
  # through $( ) and lost its trailing line breaks. Zero bytes in the file is the
  # only record that means silence and nothing else.
  if [ "$EXPECT" = 'nothing printed' ]; then
    if [ -s "$RUNOUT" ]; then
      SIZE=$(wc -c < "$RUNOUT")
      echo "  EXPECTED SILENCE, but bytes printed: $SIZE [$OUTPUT]"
      FAILED=$((FAILED + 1))
    else
      echo '  ok'
    fi
    command rm -f "$RUNOUT"
    continue
  fi
  command rm -f "$RUNOUT"

  # The comparison runs on the trimmed last non-empty line, as a whole, not by
  # containment. The pattern *"$EXPECT"* would let the expectation "4" pass on the
  # output "14", "40" and "4 workers, 0 wrong". Every sample prints the expected line
  # word for word, and not one of them needs the concession.
  if [ "$LAST" = "$EXPECT" ]; then
    echo "  ok -> $LAST"
  else
    echo "  EXPECTED '$EXPECT', got '$LAST'"; FAILED=$((FAILED + 1))
  fi
done

echo
echo "=== documentation samples: failures $FAILED ==="
FINISHED=1
# A return code in Unix is EIGHT BITS: exit 256 gives a ZERO.
#
# The failure counter went into exit directly, so exactly 256 failures (or 512, or
# 768) read from outside as success: the run honestly printed the number and handed
# out a zero. The number in the report stays exact, what goes out is truncated, but
# NEVER a zero when the count is non-zero.
CODE=$FAILED
[ "$CODE" -gt 255 ] && CODE=255
exit $CODE
