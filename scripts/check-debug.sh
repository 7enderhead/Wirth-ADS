#!/usr/bin/env bash
# Verify that the test binary can actually be debugged:
#   - it exists,
#   - it contains DWARF debug info,
#   - it is not stripped,
#   - gdb (if installed) can resolve the project sources.
#
# This checks the binary only. Breakpoints in the IDE additionally require
# that the run is started with the debugger (see docs/lazarus.md).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

bin="$ROOT/build/tests/tests"
failed=0

if [[ ! -x "$bin" ]]; then
  echo "FAIL: $bin is missing; run 'make' first"
  exit 1
fi

if readelf -S "$bin" 2>/dev/null | grep -q '\.debug_info'; then
  echo "ok:   DWARF debug info present"
else
  echo "FAIL: no .debug_info section (compiled without -g?)"
  failed=1
fi

if file "$bin" | grep -q 'not stripped'; then
  echo "ok:   symbols not stripped"
else
  echo "FAIL: binary is stripped (check for -Xs)"
  failed=1
fi

if command -v gdb >/dev/null 2>&1; then
  if gdb -batch -ex 'info sources' "$bin" 2>/dev/null | grep -q 'utextutils'; then
    echo "ok:   gdb resolves the project sources"
  else
    echo "WARN: gdb could not list the project sources"
  fi
else
  echo "skip: gdb not installed (Lazarus' FpDebug backend does not need it)"
fi

if [[ $failed -ne 0 ]]; then
  echo
  echo "Rebuild with: make clean && make"
  exit 1
fi

echo
echo "Binary is debug-ready. In Lazarus, remember to disable"
echo "'Use launching application' while debugging (docs/lazarus.md)."
