# Troubleshooting

## Lazarus breakpoints are never hit

The breakpoint icons are set, the program runs, but execution never stops —
in test code or in `src/` units. Check these in order.

### 1. "Use launching application" is enabled

This is the most common cause and easy to enable accidentally while trying to
see console output. Run → Run Parameters → uncheck **Use launching
application**.

With that option, Lazarus wraps the run in a terminal command
(`xterm -e .../runwait.sh ...`) and hands the wrapper to the debugger. The
test binary becomes a child process of xterm, so breakpoints in your units
never bind. Use the option only for **Run without debugging**.

The setting is stored in the project session (`tests.lps`, git-ignored). If
Lazarus currently has the project open, change it in the dialog; the session
file is rewritten when the IDE closes.

### 2. The program was started without the debugger

Use **Run → Run** (F9) rather than "Run without debugging" or a run icon
configured for that. If in doubt, check the IDE's Run menu.

### 3. The executable is stale or not rebuilt

Lazarus may run an old binary if the build failed or was skipped. Use
Run → Build, or from a terminal:

```sh
make clean && make
make debug-check
```

`make debug-check` verifies that `build/tests/tests` contains DWARF info, is
not stripped, and that gdb can resolve the project sources.

### 4. The debugger backend is not configured or not working

Tools → Options → Debugger → Backends:

- **FpDebug** (built-in) needs no external program and is a good default.
- **GDB** needs a working `gdb`; on this machine `/usr/bin/gdb` exists and the
  fpcup symlink points to it. Use it if FpDebug fails to start or cannot
  handle the binary.

After changing the backend, rebuild and run again. The first line of the
debugger output/log often says why a breakpoint was rejected.

### 5. The breakpoint is in code that is not compiled

If you added a new unit, make sure it is in the `uses` clause of
`tests/tests.lpr` (or of the test unit). `make debug-check` plus a clean
rebuild catches this.

### 6. The build has no usable debug info

The project enables Dwarf 3 debug info, no optimisation, and no stripping.
If you changed those settings, restore them (Project Options → Compiler
Options) or compare with `tests/tests.lpi`. `-Xs` strips symbols; `-O2` can
remove the code you set a breakpoint on.

### 7. The breakpoint is on a line without executable code

A breakpoint on a `var`/`type` declaration, a comment, or a blank line can
never be hit. Lazarus may show it as invalid or move it silently. Put the
breakpoint on a statement inside a procedure body — for a function, that means
a line inside its body, not the `function` header. (The original session in
this workspace had a breakpoint on a `var` declaration line; it was moved to
an executable line.)

### Confirm outside the IDE

If gdb stops but Lazarus does not, the binary is fine and the problem is IDE
configuration (usually item 1 or 4):

```sh
gdb -batch \
  -ex 'break src/utextutils.pas:37' \
  -ex 'run --suite=TTextUtilsTest.TestReverse' \
  -ex 'bt 3' \
  ./build/tests/tests
```

It should stop inside `REVERSETEXT` with `TESTREVERSE` on the call stack.

## `Fatal: Can't find unit system` (or any RTL unit)

The compiler is reading a config file whose unit paths do not exist. This is
common with mixed installations: a distribution `/etc/fpc.cfg` points at
`/usr/lib/.../fpc/<version>/units`, while the compiler binary lives in a
self-contained prefix (fpcup, manual build).

Check what is being used:

```sh
make doctor
command -v fpc
fpc -iV
readlink -f "$(command -v fpc)"
```

Fixes, in order of preference:

1. Use this repository's scripts: `scripts/common.sh` already passes
   `-n @<compiler-dir>/fpc.cfg` when that file exists, bypassing the stale
   `/etc/fpc.cfg`. If you added your own build command, add the same option.
2. Make the compiler-local config the default for your shell, e.g. compile
   through the installation's `fpc.sh` wrapper.
3. Fix or remove the stale `/etc/fpc.cfg` (requires root).

`lazbuild` normally is not affected because it calls the installation's
wrapper, which forces the right config.

## `Fatal: Syntax error, "UNIT" expected but "PROGRAM" found`

The unit/program name collides with an RTL or package unit. When a file is
named `strings.pas`, the compiler resolves `strings` to the RTL unit and then
re-enters your file expecting a `unit` header.

Rename it, preferably with the repository's `u` prefix: `ustrings.pas`
declaring `unit ustrings;`. The same applies to `classes`, `sysutils`, `types`,
`math`, `json`, `xml`, and similar common names. The file name must always
match the unit name.

## Tests print nothing and exit 0

FPCUnit's console runner, used without options, prints usage and exits `0`.
That is easy to mistake for "all tests passed".

In this repository `tests/tests.lpr` sets `DefaultRunAllTests := True`, so a
no-argument run does execute the suite. If you script the runner yourself,
either pass no options or add `--all` explicitly. To confirm tests really ran,
look for `Number of run tests:` in the output or use `--list`.

## A test fails but the exit code is 2, not 1

Two different programs are reporting status here.

- The **test binary** uses FPCUnit's bit mask: bit 0 (`1`) means assertion
  failures, bit 1 (`2`) means errors such as unexpected exceptions.
- **GNU make** reports its own status when a recipe fails: it exits `2`, no
  matter which code the test binary returned.

So `make test` returning `2` with `Number of failures: 1` and
`Number of errors: 0` is normal: the suite had a failure and make propagated
"recipe failed". Run `./build/tests/tests` directly to see the binary's code
(`1` in that case). Any non-zero code should fail CI. See `docs/usage.md`.

## `make test ARGS=...` does not pass my options

Quote `ARGS` as one shell argument:

```sh
make test ARGS='--suite=TTextUtilsTest'          # correct
make test ARGS=--suite=TTextUtilsTest            # also works
make test ARGS='--format=xml --file=out.xml'     # correct
```

The Makefile expands `$(ARGS)` unquoted, so keep it as a single string.

## Lazarus cannot find `utextutils` (or another `src/` unit)

The project must have `../src` in its unit search path. In
`tests/tests.lpi` this is the `OtherUnitFiles` entry. Verify with:

```sh
make lazbuild        # reproduces the project build from the command line
```

If `lazbuild` succeeds but the IDE does not, close and reopen the project so
the code tools rescan the search path.

## `lazbuild: command not found`

Lazarus is optional. Install it, or point the Makefile at the binary:

```sh
make lazbuild LAZBUILD=/path/to/lazbuild
make doctor LAZBUILD=/path/to/lazbuild
```

Command-line test runs (`make`, `make test`) need only `fpc`.

## Stale or inconsistent build results

All generated files live in `build/`. Remove them and rebuild:

```sh
make clean && make
```

If a snippet of a previous experiment still leaves files around, check
`git status`; only sources, docs and scripts should be tracked.

## `fcl-fpcunit` unit not found

`fpcunit`, `testregistry`, `consoletestrunner`, and the report writers ship
with FPC as the `fcl-fpcunit` package. If they are missing, the FPC
installation is incomplete — install the full compiler package, or use an
installation that includes `units/<target>/fcl-fpcunit`.

## Test output appears in the IDE but the run ends immediately

Check whether the runner received options (for example from saved run
parameters in a `.lps` file) that prevent a run, such as `--list`. Run
`build/tests/tests` in a terminal to compare, or reset the project's run
parameters. Also see the "Tests print nothing and exit 0" section.
