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

# Tries to build every unit of the 0-foundation layer on its own under FPC/Linux.
# The counterpart of compile_all.ps1. The parser test bench does not pull in
# everything, and units outside its dependencies get no other check: that is how a
# stray character in a VersionUtils directive stayed hidden for years.
#
# Units listed in PLATFORMS.tsv as windows, delphi or never do not count as
# breakage. Everything else has to build.
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
# The script directory is worked out in a CHECKABLE way, the same as in the twin
# that handles the samples.
#
# When dirname fails the substitution yields an empty string, cd "" in bash goes
# NOWHERE, and pwd returns the current directory: the run stays green only because
# it was started from the right place.
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

# In the monorepo the library sits in 0-foundation/pascal and pascal-jit; in the
# published repository it sits in src and jit next to the tests.
# The layout is settled UNAMBIGUOUSLY, otherwise the gate refuses.
#
# It used to be "whichever directory turned up first": an unrelated directory with
# a fitting name next to the release tree quietly CHANGED THE SUBJECT OF THE
# CHECK, and both gates came out green having checked the wrong tree. Two layouts
# present at once is not a reason to pick one, it is a sign that the situation is
# unclear and a person has to decide.
MONO="$HERE/../../pascal"
SHIP="$HERE/../src"
MONOJIT="$HERE/../../pascal-jit"
SHIPJIT="$HERE/../jit"

# The layout is settled ONCE, and both roots are derived FROM IT.
#
# The earlier version picked the roots SEPARATELY and closed the ambiguity only.
# That is not enough: measured on 11.08.2026, PARSER_SRC pointed at release/src,
# the release/jit directory was ABSENT (a defect of the release), and pascal-jit
# lay next to it. The refusal did not fire because no second candidate existed,
# and the gate quietly took a FOREIGN old jit:
#   src root /tmp/mixprobe/release/src units 1
#   jit root /tmp/mixprobe/pascal-jit units 1
#   code 0
# A release without an accelerator of its own passed green: the absence was masked
# by an unrelated directory.
#
# THE LIMIT OF TRUST, said out loud: if BOTH variables are set, the person has
# deliberately allowed any pair, release/src with an external jit included. The
# gate treats such a pair as authoritative. This is a documented exception, not a
# casual concession.
if [ -n "${PARSER_SRC:-}" ] && [ -n "${PARSER_JIT:-}" ]; then
  SRC=$PARSER_SRC
  JIT=$PARSER_JIT
elif [ -n "${PARSER_SRC:-}" ] || [ -n "${PARSER_JIT:-}" ]; then
  echo "ROOTS GIVEN BY HALVES: the other half would have to be guessed"
  echo "  set both PARSER_SRC and PARSER_JIT - or neither"
  exit 1
else
  # A layout is COMPLETE only if BOTH of its directories exist.
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
# The roots are reduced to a PHYSICAL path and have to differ.
#
# Classification ran as a text comparison against "$JIT"/*, and one and the same
# directory is written in more than one way: /tmp/tree/src and /tmp/tree/src/. are
# different as strings and the same for the file system. Both "roots" came out
# non-empty, builds succeeded from both, and the per-root check was satisfied,
# while the real accelerator directory took no part at all.
# A root has to be a DIRECTORY, and reducing the path has to succeed.
#
# Before: cd "$SRC" || printf, and when it pointed at a file cd failed, the
# fallback branch quietly kept the wrong path, and find happily accepts a file as
# a starting point and reports "one unit". The run came out green having built two
# units instead of fifty.
for V in SRC JIT; do
  eval "P=\$$V"
  if [ ! -d "$P" ]; then
    echo "ROOT IS NOT A DIRECTORY: $V = $P"
    exit 1
  fi
  R=$(cd "$P" && pwd -P)
  if [ $? -ne 0 ] || [ -z "$R" ]; then
    echo "ROOT PATH NOT RESOLVED: $V = $P"
    exit 1
  fi
  eval "$V=\$R"
done
SAME=0
if [ "$SRC" = "$JIT" ]; then
  echo "ROOTS COINCIDE: src and jit -> $SRC - one directory counted twice"
  SAME=1
fi

LCL=$LAZ/lcl/units/x86_64-linux
LU=$LAZ/components/lazutils/lib/x86_64-linux
OUT=/tmp/allunits
# The output directory is CLEARED rather than reused: it is also the search
# directory for units, and anything left from the previous run will be found and
# pulled in by the compiler. On Windows this has already produced 19 built units
# instead of 52.
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

# The compiler is checked BEFORE the run: otherwise zero built units looks like an
# absence of breakage.
if ! command -v fpc >/dev/null 2>&1; then
  echo 'NO COMPILER: fpc not found - zero units built, there was nothing to check with'
  exit 1
fi
cd "$SRC"

# The platform table HAS TO exist.
#
# Without it grep printed "No such file or directory", the exclusion list came out
# empty, and the run went on as if there were nobody to excuse: the control file is
# missing, the error is there for the eye to see, and the outcome is green.
# Existing is still not the same as being READ. A file that is in place but not
# readable gives an empty exclusion list: the same "nobody to excuse", with a
# permission error instead of an absence.
if [ ! -f PLATFORMS.tsv ]; then
  echo "NO PLATFORM TABLE: $SRC/PLATFORMS.tsv - what counts as an exception is unknown"
  exit 1
fi
if [ ! -r PLATFORMS.tsv ]; then
  echo "THE PLATFORM TABLE DOES NOT READ: $SRC/PLATFORMS.tsv"
  exit 1
fi

# The table is the INPUT LANGUAGE of the check, and it is parsed strictly.
#
# A broken line (fewer than three fields, spaces instead of a tab) and an unknown
# word in the second field simply did not fall into the awk selection: the line
# quietly meant nothing, and the exclusion vanished without a trace.
TSVBAD=$(awk -F'\t' '
  /^#/ || /^[[:space:]]*$/ { next }
  NF != 3 { printf "line %d: fields %d, need 3 separated by a tab\n", NR, NF; next }
  $1 ~ /^[[:space:]]*$/ { printf "line %d: empty unit name\n", NR; next }
  $3 ~ /^[[:space:]]*$/ { printf "line %d: %s - empty reason\n", NR, $1; next }
  $2 != "never" && $2 != "windows" && $2 != "unix" && $2 != "delphi" && $2 != "fpc" {
    printf "line %d: %s - unknown value %s\n", NR, $1, $2; next }
  seen[tolower($1)]++ { printf "line %d: %s mentioned twice\n", NR, $1 }
' PLATFORMS.tsv)
AWKCODE=$?
# The return code of awk ITSELF is part of the verdict.
#
# I fixed the syntax breakage, but the mechanism stayed: if the nested program dies
# for any reason the output will be empty, and empty output is read as "no errors".
# Emptiness from an absence of errors cannot be told from emptiness caused by the
# death of whoever was checking, unless the return code is asked for.
if [ "$AWKCODE" -ne 0 ]; then
  echo "THE TABLE WAS NOT PARSED: awk returned $AWKCODE"
  exit 1
fi
if [ -n "$TSVBAD" ]; then
  printf '%s\n' "$TSVBAD" | sed 's/^/PLATFORM TABLE: /'
  echo "THE PLATFORM TABLE WAS NOT PARSED IN FULL"
  exit 1
fi
# Every link is judged by ITS OWN convention, not by a threshold laid over the
# pipeline.
#
# A threshold cannot work at all: with pipefail the code that comes out is the one
# from the RIGHTMOST link that failed. Let the first grep truly die with code 2 and
# produce nothing, the second grep gets empty input and lawfully returns 1, awk
# returns 0, and the pipeline hands out 1. Allowing a one for the sake of a lawful
# empty list would hide a real failure of the neighbouring link.
#
# So the pipeline is taken apart into steps. For grep 1 means "no matches" and that
# is lawful, a failure is 2 and above. For awk any non-zero code is a failure.
NOCOMM=$(grep -v '^#' PLATFORMS.tsv)
GCODE=$?
if [ "$GCODE" -gt 1 ]; then
  echo "THE EXCUSE LIST WAS NOT BUILT: grep over comments returned $GCODE"
  exit 1
fi
NOBLANK=$(printf '%s\n' "$NOCOMM" | grep -v '^[[:space:]]*$')
GCODE2=$?
if [ "$GCODE2" -gt 1 ]; then
  echo "THE EXCUSE LIST WAS NOT BUILT: grep over blank lines returned $GCODE2"
  exit 1
fi
SKIP=$(printf '%s\n' "$NOBLANK" | awk -F'\t' '$2=="windows" || $2=="delphi" || $2=="never" {print $1}')
ACODE=$?
if [ "$ACODE" -ne 0 ]; then
  echo "THE EXCUSE LIST WAS NOT BUILT: awk returned $ACODE"
  exit 1
fi

OK=0; BAD=0; SKIPPED=0; EMPTY=0; OK_SRC=0; OK_JIT=0; ENUMBAD=0
BADLIST=""; SKIPLIST=""

# Composition: BOTH roots and recursively, not the top level of one directory.
# Earlier only $SRC was listed, without nested files, and $JIT served as a search
# path alone: the step was called "every unit" and took 46 out of 52. And each root
# has to give a non-empty list, a shared "more than zero built" is not enough: with
# an empty $JIT the core builds while the accelerator has been checked in the
# amount of zero units.
UNITS=""
NL=$'\n'
for NAME in src jit; do
  case $NAME in
    src) ROOT=$SRC ;;
    jit) ROOT=$JIT ;;
  esac
  # Errors of LISTING are not silenced: 2>/dev/null hid more than an empty root. On a
  # partly unreadable tree find hands out the part it can reach, the error
  # disappears, the counter stays non-zero, and the per-root check is satisfied
  # although some units never made the list. An unreachable subdirectory does not
  # mean "fewer units", it means "how many there are is unknown".
  # The census takes ORDINARY FILES, not everything that ends in .pas.
  #
  # A directory named Ghost.pas satisfied both the census and the check "a table
  # entry points at an existing unit": the basename is the same and the unit is not
  # there. A stale entry came back to life through an empty directory, and the run
  # stayed green.
  FERR=$(find "$ROOT" -type f -iname '*.pas' 2>&1 >/dev/null)
  FCODE=$?
  # The CODE is asked for, not the text alone. A find that died in silence gave an
  # empty FERR, and a truncated census passed green. A partial loss is more dangerous
  # than a complete zero: zero is caught by the emptiness check, a shortage of some
  # units is not.
  if [ "$FCODE" -ne 0 ] || [ -n "$FERR" ]; then
    [ -n "$FERR" ] || FERR="find returned $FCODE and said nothing"
    printf '%s\n' "$FERR" | sed 's|^|TREE TRAVERSAL IS NOT COMPLETE: |'
    ENUMBAD=$((ENUMBAD+1))
  fi
  # The census travels through NUL, not through line breaks.
  #
  # A line break is a lawful character in a file name. A text census tore such a name
  # into two lines, neither of them was a file, both were quietly skipped as foreign,
  # and a BROKEN unit never once reached the compiler, with code 0. Measured on
  # 11.08.2026 on a tree holding Foo<line break>Bar.pas: "units 3, BUILT: 2, NOT
  # BUILT: 0", and both halves of the name also matched entries of the platform table
  # and were counted as lawfully skipped.
  #
  # Further on the census lives in lines, so a name with a line break is REJECTED
  # right here rather than carried into a form unfit for it.
  ROSTER=$(mktemp)
  RCODE=$?
  if [ "$RCODE" -ne 0 ] || [ -z "$ROSTER" ]; then
    echo "THE ROSTER WAS NOT BUILT: temporary file not created - code $RCODE"
    ENUMBAD=$((ENUMBAD+1))
    ROSTER=/dev/null
  fi
  set -o pipefail
  find "$ROOT" -type f -iname '*.pas' -print0 2>/dev/null | sort -z > "$ROSTER"
  SCODE=$?
  set +o pipefail
  if [ "$SCODE" -ne 0 ]; then
    echo "THE ROSTER WAS NOT BUILT: $ROOT - code $SCODE"
    ENUMBAD=$((ENUMBAD+1))
  fi
  # The SHELL does the counting, not an external grep -c.
  #
  # A grep that died returned zero, and a violation already found and printed was
  # lost between a boolean fact and a return code: the gate knew about the violation
  # itself and forgot it itself.
  FOUND=""
  N=0
  while IFS= read -r -d '' P; do
    case "$P" in
      *"$NL"*)
        echo "NAME WITH A LINE BREAK: [$P] - the roster will not survive such a name"
        ENUMBAD=$((ENUMBAD+1))
        continue
        ;;
    esac
    FOUND="$FOUND$P
"
    N=$((N+1))
  done < "$ROSTER"
  [ "$ROSTER" = /dev/null ] || command rm -f "$ROSTER"
  echo "root $NAME $ROOT units $N"
  if [ "$N" -eq 0 ]; then
    echo "ROOT IS EMPTY OR MISSING: $NAME ($ROOT) - nothing was checked from there"
    EMPTY=$((EMPTY+1))
  fi
  UNITS="$UNITS$FOUND"
done

# Units of the same name in different roots: refusal.
#
# The output directory is shared: a second such unit would overwrite the ppu of the
# first, and the platform table tells units apart by name and would excuse both at
# once.
# A failure of the tool is a failure of the check: the same case as with the
# exclusion list. Without pipefail the code is taken from the last link, and the
# death of any earlier one goes unnoticed.
# The unit name is taken by SHELL SUBSTITUTION, without an external program.
#
# An external basename gave 52 process starts and a whole class of failures: its
# death on one iteration out of fifty lost the name, units of the same name stopped
# being found, and the run stayed green. Substitution cannot fail. RC is kept as a
# second line of defence.
#
# The status of the loop remembers ANY failure, not the last one alone.
#
# The whole while is a stage of the pipeline, and its status after a normal end is
# the status of the LAST command of the body. A failure of basename on the first
# iteration out of fifty-two was lost: the last one finished successfully and the
# pipeline handed out a zero. So a failure accumulates in RC, and the group ends
# with a check of RC.
DUPS=$(set -o pipefail; printf '%s\n' "$UNITS" | grep -v '^$' | { RC=0; while IFS= read -r f; do
         N=${f##*/}; printf '%s\n' "${N%.*}" || RC=1; done; [ "$RC" -eq 0 ]; } | tr 'A-Z' 'a-z' | sort | uniq -d)
DUPCODE=$?
# Strictness is back: the concession about "1 = empty" is needed ONLY where the
# pipeline has a grep that can lawfully find nothing. There is none here, while
# basename and awk are, and for them a failure is exactly code 1.
if [ "$DUPCODE" -ne 0 ]; then
  echo "THE SEARCH FOR SAME-NAMED UNITS DID NOT RUN: code $DUPCODE"
  exit 1
fi
DUP=0
if [ -n "$DUPS" ]; then
  printf '%s\n' "$DUPS" | sed 's/^/ONE NAME IN DIFFERENT ROOTS: /'
  DUP=0
  while IFS= read -r CL; do
    [ -n "$CL" ] && DUP=$((DUP+1))
  done <<COUNT_END
$DUPS
COUNT_END
fi

# A table entry about a unit that does not exist excuses nothing, yet it looks like
# a working exclusion: the unit was renamed, the line stayed to guard an emptiness,
# and the new unit went into the check without permission.
ALLNAMES=$(set -o pipefail; printf '%s\n' "$UNITS" | grep -v '^$' | { RC=0; while IFS= read -r f; do
             N=${f##*/}; printf '%s\n' "${N%.*}" || RC=1; done; [ "$RC" -eq 0 ]; } | tr 'A-Z' 'a-z' | sort -u)
ANCODE=$?
# This list feeds the search for stale entries: a truncated list means not "there
# are no stale ones" but "there was nothing to compare them against". A silent
# death of basename made the check blind without bringing the run down.
if [ "$ANCODE" -ne 0 ]; then
  echo "THE NAME LIST WAS NOT BUILT: code $ANCODE"
  exit 1
fi
STALE=$(set -o pipefail; awk -F'\t' '!/^#/ && NF >= 3 { print tolower($1) }' PLATFORMS.tsv | sort -u \
        | comm -23 - <(printf '%s\n' "$ALLNAMES"))
STCODE=$?
if [ "$STCODE" -ne 0 ]; then
  echo "THE SEARCH FOR STALE ENTRIES DID NOT RUN: code $STCODE"
  exit 1
fi
MISS=0
if [ -n "$STALE" ]; then
  printf '%s\n' "$STALE" | sed 's/^/PLATFORM TABLE: mentioned, but no such unit in the tree: /'
  MISS=0
  while IFS= read -r CL; do
    [ -n "$CL" ] && MISS=$((MISS+1))
  done <<COUNT_END
$STALE
COUNT_END
fi

# The traversal goes BY LINE, not by the shell splitting words.
#
# "for FULL in $UNITS" splits the list on spaces: a path such as
# /tmp/release candidate/src/Foo.pas turned into two files that do not exist, each
# of them giving a compiler failure, while the real unit would not be checked at
# all.
while IFS= read -r FULL; do
  [ -n "$FULL" ] || continue
  # The name is taken by shell substitution, as in the census: an external basename
  # was the most dangerous thing here, its code was not read at all, and one that
  # returned a foreign name together with a non-zero code would send a sound unit
  # into (skipped).
  U=${FULL##*/}; U=${U%.*}
  # The name is lowercased: for Object Pascal Foo and foo are one unit, so the
  # comparison with the exclusion list ignores case.
  UL=${U,,}
  # Comparison of the name is LITERAL, not by pattern.
  #
  # grep -x without -F takes the name as a regular expression: a dot in the name
  # matches any character, and the table line "A.B" excused the unit "AxB", which is
  # not in the table at all. A pure false green.
  # Membership of the list is checked by the SHELL, without an external program.
  #
  # With an external grep the death of the check quietly cancelled the exclusion: a
  # unit that has to be skipped went off to be built, and the run stayed green.
  # Measured: with the exclusion it was 51 built and 1 not required, with a dead grep
  # 52 and 0, without a single word. There is nothing left here to disappear.
  ISSKIP=0
  while IFS= read -r S; do
    [ -z "$S" ] && continue
    SL=${S,,}
    [ "$SL" = "$UL" ] && { ISSKIP=1; break; }
  done <<SKIPLIST_END
$SKIP
SKIPLIST_END
  if [ "$ISSKIP" = 1 ]; then
    SKIPPED=$((SKIPPED+1))
    SKIPLIST="$SKIPLIST
    (skipped) $U - $(awk -F'\t' -v u="$U" 'tolower($1)==tolower(u) {print $3; exit}' PLATFORMS.tsv)"
    continue
  fi
  # The CONTRACT is asked for, not a sign: the compiler has a return code. Earlier
  # the outcome was judged by Error:/Fatal: lines in the output alone, and a compiler
  # that died in silence counted as having built.
  OUTTXT=$(fpc -MDelphi -Sh -B -Fu"$SRC" -Fu"$JIT" -Fu"$LCL" -Fu"$LCL/gtk3" -Fu"$LU" \
           -Fi"$SRC" -FU"$OUT" "$FULL" 2>&1)
  CODE=$?
  ERR=$(printf '%s\n' "$OUTTXT" | grep -E 'Error:|Fatal:' | head -3)
  if [ -z "$ERR" ] && [ "$CODE" -eq 0 ]; then
    OK=$((OK+1))
    case "$FULL" in
      "$JIT"/*) OK_JIT=$((OK_JIT+1)) ;;
      *) OK_SRC=$((OK_SRC+1)) ;;
    esac
  else
    BAD=$((BAD+1))
    [ -z "$ERR" ] && ERR="the compiler returned $CODE with no Error/Fatal words"
    BADLIST="$BADLIST
--- $U
$ERR"
  fi
done < <(printf '%s\n' "$UNITS")
echo "BUILT: $OK   NOT BUILT: $BAD   not required: $SKIPPED"
printf '%s\n' "$SKIPLIST"
printf '%s\n' "$BADLIST"

# A run that built ZERO units is never green: there is nothing to fail if nothing
# was tried. An empty root is not a green outcome either.
if [ "$OK" -eq 0 ]; then
  echo 'NOT A SINGLE UNIT WAS BUILT: there was nothing to check'
  BAD=$((BAD+1))
fi

# A non-empty root still does not mean anything from it was CHECKED: the platform
# table can excuse all of its units, and then the list is non-empty, there are no
# failures, and exactly nothing has been checked. What counts is what was BUILT,
# not what was found.
MUTE=0
if [ "$OK_SRC" -eq 0 ]; then
  echo 'NOT A SINGLE UNIT BUILT FROM ROOT src'
  MUTE=$((MUTE+1))
fi
if [ "$OK_JIT" -eq 0 ]; then
  echo 'NOT A SINGLE UNIT BUILT FROM ROOT jit'
  MUTE=$((MUTE+1))
fi
BAD=$((BAD+MUTE+SAME+DUP+MISS+ENUMBAD))
FINISHED=1
# A return code in Unix is EIGHT BITS: exit 256 gives a ZERO.
#
# The failure counter went into exit directly, so exactly 256 failures (or 512, or
# 768) read from outside as success: the run honestly printed the number and handed
# out a zero. The number in the report stays exact, what goes out is truncated, but
# NEVER a zero when the count is non-zero.
CODE=$BAD
[ "$CODE" -gt 255 ] && CODE=255
exit $CODE
