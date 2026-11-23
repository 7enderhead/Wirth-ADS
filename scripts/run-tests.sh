#!/usr/bin/env bash
# Build and run the FPCUnit test suite in tests/.
# Extra command-line options are forwarded to the test runner.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/run-tests.sh [FPCUnit options]

Builds tests/tests.lpr into build/tests/tests and runs it. With no options,
all tests run in plain text. Options are passed straight to the FPCUnit
console runner; the most useful ones are:

  --list, -l              list registered tests, do not run them
  --all, -a               run all tests (default when no options are given)
  --suite=NAME            run only the test case class NAME
  --suite=Class.Test      run a single test method; comma-separate several
  --format=FMT            plain | plainnotiming | latex | xml
  --file=FILE             write the report to FILE
  --sparse                show failures and errors only
  --skipTiming            omit timing information
  --no-exitcode           always exit 0
  -h, --help              show the complete FPCUnit help

Exit status (FPCUnit bit mask):
  0  success
  1  assertion failure(s)
  2  exception(s) / error(s)
  3  both

Environment:
  FPC                     compiler to use (default: fpc)

See docs/usage.md and docs/troubleshooting.md for details.
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

outdir="$ROOT/build/tests"
mkdir -p "$outdir"

"$FPC" "${FPC_CONFIG[@]}" "${FPCFLAGS[@]}" \
  -Fu"$ROOT/src" -Fu"$ROOT/tests" \
  -FU"$outdir" -FE"$outdir" -o"$outdir/tests" \
  "$ROOT/tests/tests.lpr"

exec "$outdir/tests" "$@"
