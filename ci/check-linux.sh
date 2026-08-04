#!/bin/bash
#
# The build matrix of this repository, Linux side.
#
# The pair to ci/check-windows.ps1. The second platform is not there for the
# sake of Linux: it turns assumptions into facts that can be checked.
#
# What is checked:
#
#   parser and accelerator  under two locales: C.UTF-8 and ru_RU.UTF-8. The
#                           decimal separator comes from the locale, and reading
#                           numbers must not depend on it
#   documentation samples   build, run, compare the output
#   unit by unit            every module on its own
#
# Environment (all optional):
#   FPC_ENV  a file that puts the right fpc on PATH
#   LAZ      the Lazarus folder, needed by the tests that use Forms
#
# The root is worked out from the location of the script; nothing is hardwired.
#
# The exit code is the number of failed steps.

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
    grep -E 'TOTAL|code=|Error:|Fatal:|^FAIL'
  return ${PIPESTATUS[0]}
}

echo "=== Build matrix: Linux ==="
echo "root: $ROOT"

step 'parser and accelerator, locale C.UTF-8'     parser_at C.UTF-8
step 'parser and accelerator, locale ru_RU.UTF-8' parser_at ru_RU.UTF-8

step 'documentation samples' bash "$ROOT/samples/docs/build.sh"

step 'unit by unit' bash "$ROOT/tests/compile_all_linux.sh"

echo
echo '=== Summary ==='
for line in "${REPORT[@]}"; do echo "  $line"; done
echo
if [ $FAILED -eq 0 ]; then
  echo 'MATRIX IS GREEN'
else
  echo "STEPS FAILED: $FAILED"
fi
exit $FAILED
