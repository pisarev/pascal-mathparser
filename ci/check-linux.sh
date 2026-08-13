#!/bin/bash
#
# The build matrix of the published repository, the Linux side.
#
# The counterpart of ci/check-windows.ps1. The second platform is needed not for the
# sake of Linux as such: it turns assumptions into facts that can be checked.
#
# What is checked:
#
#   parser and accelerator  under two locales: C.UTF-8 and ru_RU.UTF-8. The
#                           separator of the fractional part comes from the locale,
#                           and parsing numbers has to stay independent of it
#   documentation samples   build, run, compare the output
#   one by one              every unit on its own
#
# The environment (all of it optional):
#   FPC_ENV  a file that adds the right fpc to PATH
#   LAZ      the Lazarus directory, needed by tests that pull in Forms
#
# The root is worked out from the place of the script, nothing is hardcoded.
#
# The return code is the number of failed steps.

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")

FAILED=0
declare -a REPORT

step() {
  local name="$1"; shift
  echo
  echo "--- $name"
  local started=$SECONDS
  if "$@"; then local code=0; else local code=$?; fi
  local spent=$((SECONDS - started))
  [ $code -ne 0 ] && FAILED=$((FAILED + 1))
  local mark="ok"; [ $code -ne 0 ] && mark="FAILED ($code)"
  REPORT+=("$(printf '%-46s %-12s %3d c' "$name" "$mark" "$spent")")
  return 0
}

parser_at() {
  local loc="$1"
  LC_ALL="$loc" LANG="$loc" bash "$ROOT/tests/build_parser_linux.sh" 2>&1 |
    grep -E 'TOTAL|RESULT|code=|Error:|Fatal:|^FAIL'
  return ${PIPESTATUS[0]}
}

echo "=== Build matrix: Linux ==="
echo "root: $ROOT"

step 'parser and accelerator, locale C.UTF-8'     parser_at C.UTF-8
step 'parser and accelerator, locale ru_RU.UTF-8' parser_at ru_RU.UTF-8

step 'documentation samples' bash "$ROOT/samples/docs/build.sh"

step 'one by one: every unit' bash "$ROOT/tests/compile_all_linux.sh"

echo
echo '=== Result ==='
for line in "${REPORT[@]}"; do echo "  $line"; done
echo
if [ $FAILED -eq 0 ]; then
  echo 'THE MATRIX IS GREEN'
else
  echo "STEPS FAILED: $FAILED"
fi
# A return code in Unix is EIGHT BITS: exit 256 gives a ZERO.
#
# The failure counter went into exit directly, so exactly 256 failures (or 512, or
# 768) read from outside as success: the run honestly printed the number and handed
# out a zero. The number in the report stays exact, what goes out is truncated, but
# NEVER a zero when the count is non-zero.
CODE=$FAILED
[ "$CODE" -gt 255 ] && CODE=255
exit $CODE
