# Toolchain and build pipeline

## Verified environment

This workspace was set up and verified on GNU/Linux x86_64 with:

- Free Pascal 3.2.4 (fpcup installation; compiler, units and `fpc.cfg` in one
  prefix)
- Lazarus / lazbuild 4.8
- GNU make and bash

`make doctor` prints the versions actually in use on your machine. The suite
only depends on the FPC RTL and the bundled `fcl-fpcunit` package, so no
third-party libraries are needed.

## Files involved

| File | Role |
| ---- | ---- |
| `Makefile` | User-facing entry points; no compiler logic of its own. |
| `scripts/common.sh` | Locates the compiler, builds the flag list, selects `fpc.cfg`. |
| `scripts/run-tests.sh` | Compiles `tests/tests.lpr` into `build/tests/tests` and runs it. |
| `src/*.pas` | Units under test. |
| `tests/*_tests.pas` | FPCUnit test units. |
| `tests/tests.lpr` | Runner program; registers test units via `uses`. |
| `tests/tests.lpi` | Lazarus project for the same runner. |

## Command-line build

`make` → `scripts/run-tests.sh` runs the equivalent of:

```sh
fpc -n @<compiler-dir>/fpc.cfg \
    -Mobjfpc -Sh -gl \
    -Fu<repo>/src -Fu<repo>/tests \
    -FU<repo>/build/tests -FE<repo>/build/tests \
    -o<repo>/build/tests/tests \
    <repo>/tests/tests.lpr
build/tests/tests
```

Why these flags (defined in `scripts/common.sh`):

| Flag | Meaning | Reason |
| ---- | ------- | ------ |
| `-Mobjfpc` | `{$mode objfpc}` | Modern Pascal: classes, `Result`, `specialize`, ... |
| `-Sh` | Ansistrings by default | Normal `string` semantics (`AnsiString`), UTF-8-friendly. |
| `-gl` | Line info / debug info | Breakpoints and stack traces in Lazarus/gdb. |
| `-Fu` | Unit search path | Finds `src/` and the test units. |
| `-FU` | Unit output directory | Keeps `.o`/`.ppu` under `build/`. |
| `-FE` | Executable output directory | Keeps the binary under `build/`. |

The `$mode` directive is also present in each source file so that tools
opening a single file (Lazarus, editors, `fpc file.pas`) behave the same way.

## The fpc.cfg problem and how the scripts handle it

Free Pascal reads exactly one configuration file, searching in this order:

1. `fpc.cfg` in the current directory,
2. `~/.fpc.cfg`,
3. `/etc/fpc.cfg`,
4. `fpc.cfg` in the compiler's own directory.

A mixed installation can leave a stale `/etc/fpc.cfg` from a distribution
package (unit paths such as `/usr/lib/x86_64-linux-gnu/fpc/3.2.4/units/...`)
while the active compiler is a self-contained install elsewhere (for example
under `~/.local/opt/fpc`). Because `/etc` is searched first, the compiler then
fails with `Fatal: Can't find unit system`.

To make builds deterministic, `scripts/common.sh` checks whether a `fpc.cfg`
exists next to the resolved compiler binary and, if so, passes
`-n @<that file>`. `-n` disables the normal config search, so the
self-contained install's own paths are used. If no compiler-local `fpc.cfg`
exists (typical distribution install), no `-n` is added and the default
behaviour applies — in that case `/etc/fpc.cfg` is the correct one.

`lazbuild` is not affected: it invokes the compiler through the installation's
wrapper (`fpc.sh` in fpcup installs), which already passes its own config
file. The build log shows
`Start of reading config file .../fpc.cfg`.

Diagnose with:

```sh
make doctor
command -v fpc              # which compiler is used
fpc -iV                     # its version
readlink -f "$(command -v fpc)"
```

## Lazarus build

`make lazbuild` runs `lazbuild tests/tests.lpi`. Relevant project settings in
`tests/tests.lpi`:

- target: `../build/tests/tests`
- unit output: `../build/tests/lib`
- other unit files: `../src`
- debug info on, optimisations off (debug build)

Lazarus adds its own flags (for example `-MObjFPC`, `-Scgi`, `-CX`, `-g`,
`-gl`). They are compatible with the command-line build; both produce a
runnable `build/tests/tests`.

## Runner defaults

`tests/tests.lpr` sets two exported variables from `consoletestrunner` before
creating the runner:

```pascal
DefaultRunAllTests := True;
DefaultFormat := fPlain;
```

FPCUnit's raw console runner only prints usage and exits `0` when started
without options. Setting these defaults makes the binary useful in two ways:

- `./build/tests/tests` and Lazarus **Run** with no arguments run the whole
  suite in plain text;
- explicit options (`--list`, `--suite=...`, `--format=xml`, ...) still take
  precedence.

Exit codes are FPCUnit's bit mask: `1` = assertion failures, `2` = errors
(exceptions), `3` = both, `0` = success. See `docs/usage.md`.

## Design decisions

- **Units, not programs.** The repository is for procedures and functions;
  each topic gets a unit and a test unit. There is no build target per
  experiment and no "runner program" to maintain.
- **Only the test project is a project.** `tests/tests.lpi` gives IDE users a
  Run button and a debugger without introducing GUI or app scaffolding.
- **Generated files never enter git.** All output goes to `build/`, which is
  ignored. A clean checkout plus `make` is enough.
- **Minimal dependencies.** FPC RTL + `fcl-fpcunit`; no fpmake, no external
  test framework, no packages beyond what ships with FPC.

## Verification checklist

These checks were run when the workspace was created (rerun them after
changing the scripts):

```sh
make doctor                 # prints fpc and lazbuild versions
make clean && make          # 7 tests, 0 errors, 0 failures, exit 0
make test ARGS='--list'     # lists TTextUtilsTest and its methods
make test ARGS='--format=xml --file=build/report.xml'
make debug-check            # DWARF present, not stripped, gdb resolves sources
make lazbuild               # links build/tests/tests
./build/tests/tests         # runs all tests without arguments
```

A deliberately failing assertion makes the test binary exit `1` (assertion
failure bit) while `make` reports `2` (GNU make's own error status); restore
the assertion and both return to success. After editing tests in quick
succession, use `make clean && make` if a rebuild ever seems to be skipped,
because FPC uses file timestamps. `make test ARGS='--suite=TTextUtilsTest'`
restricts execution to one suite.
