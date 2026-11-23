# Shared shell configuration for the build/test scripts.
# This file is meant to be sourced, not executed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FPC="${FPC:-fpc}"

# Compiler flags shared by snippets and tests.
FPCFLAGS=(-Mobjfpc -Sh -gl)

# Prefer the fpc.cfg that ships next to the compiler binary. Some installs
# (e.g. fpcup) have a stale /etc/fpc.cfg that points to missing unit paths;
# the per-compiler file is authoritative for such installs.
_fpc_bin="$(command -v "$FPC")"
_fpc_cfg="$(dirname "$(readlink -f "$_fpc_bin")")/fpc.cfg"
if [[ -f "$_fpc_cfg" ]]; then
  FPC_CONFIG=(-n "@$_fpc_cfg")
else
  FPC_CONFIG=()
fi
