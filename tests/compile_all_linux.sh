#!/bin/bash
# Tries to compile every module of the library on its own on FPC/Linux.
# The counterpart of compile_all.ps1. The test bench does not pull in all of
# them, and modules outside its dependencies would otherwise never be compiled:
# that is how a stray bracket in a VersionUtils directive hid for years.
#
# Modules marked windows, delphi or never in PLATFORMS.tsv are not counted as
# breakage. Everything else has to build.
[ -n "${FPC_ENV:-}" ] && [ -f "${FPC_ENV}" ] && source "${FPC_ENV}"
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
OUT=/tmp/allunits
mkdir -p "$OUT"
cd "$SRC"

SKIP=$(grep -v '^#' PLATFORMS.tsv | grep -v '^[[:space:]]*$' \
       | awk -F'\t' '$2=="windows" || $2=="delphi" || $2=="never" {print $1}')

OK=0; BAD=0; SKIPPED=0
BADLIST=""; SKIPLIST=""
for f in *.pas; do
  U="${f%.pas}"
  if echo "$SKIP" | grep -qx "$U"; then
    SKIPPED=$((SKIPPED+1))
    SKIPLIST="$SKIPLIST
    (skipped) $U - $(grep -P "^$U\t" PLATFORMS.tsv | cut -f3)"
    continue
  fi
  ERR=$(fpc -MDelphi -Sh -B -Fu"$SRC" -Fu"$JIT" -Fu"$LCL" -Fu"$LCL/gtk3" -Fu"$LU" \
        -Fi"$SRC" -FU"$OUT" "$f" 2>&1 | grep -E 'Error:|Fatal:' | head -3)
  if [ -z "$ERR" ]; then
    OK=$((OK+1))
  else
    BAD=$((BAD+1))
    BADLIST="$BADLIST
--- $U
$ERR"
  fi
done
echo "BUILT: $OK   NOT BUILT: $BAD   not required: $SKIPPED"
echo "$SKIPLIST"
echo "$BADLIST"
exit $BAD
