#!/bin/bash
#
# Build and run the documentation samples, Linux side. The pair to build.ps1.
#
# Every sample is a real program with its expected output on the first line
# ({ expect: ... }). A sample that does not build, or prints the wrong line,
# does not reach the page.
#
# The exit code is the number of failed samples.

set -u
[ -n "${FPC_ENV:-}" ] && [ -f "${FPC_ENV}" ] && source "${FPC_ENV}"
HERE=$(cd "$(dirname "$0")" && pwd)

# Where the library lives. In the monorepo that is 0-foundation/pascal and
# pascal-jit; in the published repository it is src and jit at the root.
# PARSER_SRC and PARSER_JIT override both guesses.
if [ -n "${PARSER_SRC:-}" ]; then SRC=$PARSER_SRC
elif [ -d "$HERE/../../pascal" ]; then SRC=$(cd "$HERE/../../pascal" && pwd)
else SRC=$(cd "$HERE/../../src" && pwd); fi
if [ -n "${PARSER_JIT:-}" ]; then JIT=$PARSER_JIT
elif [ -d "$HERE/../../pascal-jit" ]; then JIT=$(cd "$HERE/../../pascal-jit" && pwd)
else JIT=$(cd "$HERE/../../jit" && pwd); fi
OUT=$HERE/out
mkdir -p "$OUT"

FAILED=0

# The samples are console programs: they need neither forms nor graphics.
#
# Messages comes from src/compat rather than the LCL: the LCL drags in a
# widgetset and a console program will not link against it (WSRegisterCustomForm
# and its relatives are missing). There is no Lazarus here at all - no LCL, no
# LazUtils: the RTL is enough for the library. If it ever stops being enough,
# this build is the first to fail.
FLAGS="-MDelphi -Sh -O2 -B -dNOFORMS -dNOGRAPHICS"
PATHS="-Fu$SRC/compat -Fu$SRC -Fu$JIT -Fi$SRC"

for FILE in "$HERE"/*.dpr; do
  NAME=$(basename "$FILE" .dpr)
  EXPECT=$(sed -n 's/.*{[[:space:]]*expect:[[:space:]]*\(.*\)[[:space:]]*}.*/\1/p' "$FILE" | head -1)
  EXPECT=$(echo "$EXPECT" | sed 's/[[:space:]]*$//')

  # A skip is announced out loud: a silent skip reads as "checked".
  # CalcUtils goes through Calculator, and that through SyncThread, whose timer
  # on FPC is made of the LCL widgetset. A console program will not link against
  # it, so on unix such samples are covered by the Windows side only.
  echo "--- $NAME (expecting: $EXPECT)"
  if grep -q 'needs: lcl on unix' "$FILE"; then
    echo "  SKIPPED on unix: the CalcUtils path needs the LCL"
    continue
  fi


  if ! fpc $FLAGS $PATHS -FU"$OUT" -FE"$OUT" "$FILE" > "$OUT/$NAME.build.log" 2>&1; then
    echo "  BUILD FAILED"
    grep -E 'Error:|Fatal:' "$OUT/$NAME.build.log" | head -3 | sed 's/^/      /'
    FAILED=$((FAILED + 1))
    continue
  fi

  if ! OUTPUT=$("$OUT/$NAME" 2>&1); then
    echo "  RUN FAILED"
    FAILED=$((FAILED + 1))
    continue
  fi

  LAST=$(echo "$OUTPUT" | grep -v '^[[:space:]]*$' | tail -1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  if [ "$EXPECT" = 'nothing printed' ]; then
    if [ -z "$LAST" ]; then echo '  ok'; else echo "  EXPECTED SILENCE, got: $LAST"; FAILED=$((FAILED + 1)); fi
    continue
  fi

  case "$LAST" in
    *"$EXPECT"*) echo "  ok -> $LAST" ;;
    *) echo "  EXPECTED '$EXPECT', got '$LAST'"; FAILED=$((FAILED + 1)) ;;
  esac
done

echo
echo "=== documentation samples: failures $FAILED ==="
exit $FAILED
