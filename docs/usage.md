# Usage

## Command line

| Command | Effect |
| ------- | ------ |
| `make` | Default target: build the test runner and run all tests. |
| `make test` | Same as `make`, but accepts FPCUnit options via `ARGS`. |
| `make test ARGS='--suite=TTextUtilsTest'` | Run one `TTestCase` class. |
| `make test ARGS='--list'` | Build, then list registered tests without running. |
| `make test ARGS='--format=xml --file=build/report.xml'` | Write an XML report. |
| `make lazbuild` | Build `tests/tests.lpi` with `lazbuild` (no tests are run). |
| `make clean` | Delete `build/`. |
| `make doctor` | Print the `fpc` and `lazbuild` paths and versions. |
| `make help` | Print the target summary. |

`ARGS` is passed straight through to the FPCUnit console runner. Quote it as a
single argument so `make` does not split the options.

### Running the binary directly

`make` produces `build/tests/tests`. It behaves like a normal console
application:

```sh
./build/tests/tests                     # all tests, plain output (default)
./build/tests/tests --list              # list test cases and methods
./build/tests/tests --suite=TTextUtilsTest
./build/tests/tests --format=xml
./build/tests/tests --format=latex --file=build/report.tex
./build/tests/tests --sparse            # only failures/errors
./build/tests/tests --skipTiming
./build/tests/tests --help
```

Supported runner options (from `--help`):

```
--format=FMT        plain | plainnotiming | latex | xml
--skiptiming        do not print timings
--sparse            less output (errors/failures only)
--no-addresses      do not display address info
--stylesheet=REF    stylesheet reference (XML)
--file=FILE         write results to FILE
-l, --list          list registered tests
-a, --all           run all tests
-p, --progress      show progress
--suite=NAME        run a single test suite class
--no-exitcode       always exit 0
-h, --help          show help
```

`scripts/run-tests.sh --help` prints a shorter summary of the wrapper.

## Exit codes

The process exit status is a bit mask built by FPCUnit:

| Value | Meaning |
| ----- | ------- |
| `0` | All tests passed (ignored/skipped tests do not fail the run). |
| `1` | At least one assertion failed (bit 0). |
| `2` | At least one test raised an exception (bit 1). |
| `3` | Both failures and errors occurred. |

Any non-zero value means "do not accept this build". A test that *fails* an
assertion produces `1`; an unexpected exception is reported as an *error* and
produces `2` — `2` is not "worse" than `1`, it is just a different bit.
Pass `--no-exitcode` only when you intentionally want to ignore results.

This table describes the **test binary**. `make` wraps the recipe and reports
its own status when the recipe fails: GNU make exits `2`, regardless of
whether the binary returned `1` or `2`. Use the binary directly (or inspect
the report) when you need the precise bitmask; use `make` when you only need
"passed / did not pass".

## Lazarus

Open `tests/tests.lpi` (File → Open, or double-click it) and press **Run**.

- The runner is configured so that **no command-line options means "run all
  tests with plain output"**; that is why Run works without setting run
  parameters. (FPCUnit's runner on its own only prints usage and exits 0 when
  invoked without options — see `docs/troubleshooting.md`.)
- Breakpoints work in `tests/` and in the units under `src/`; the build uses
  `-gl` line information. The unit under test is also listed in the project
  (`../src/utextutils.pas`) so it opens alongside the tests.
- The project's unit search path is `../src`, and its output goes to
  `build/tests/`. Adding a new unit in `src/` does not require changing the
  project file, only the `uses` clauses.
- To run one test method, set the run parameter
  `--suite=TTextUtilsTest.TestReverse` (Run → Run Parameters).
- If your Lazarus setup does not show console output, run `make test` in a
  terminal instead. Do **not** enable Run → Run Parameters → "Use launching
  application" while debugging: it makes the debugger launch xterm instead of
  your test binary, so breakpoints are ignored. See `docs/lazarus.md`.

See `docs/lazarus.md` for the full IDE workflow: side-by-side editing, debug
windows, watches, and stepping into the code under test.

Headless equivalent of pressing Run:

```sh
make lazbuild                # build only
make test                    # build and run with fpc
```

## Build outputs

Everything generated lives under `build/` and is ignored by git:

```
build/tests/tests        # test runner executable
build/tests/*.o, *.ppu   # compiler artifacts next to the executable
build/tests/lib/         # unit output directory created by lazbuild
```

`make clean` removes the whole directory. A clean checkout plus `make` is the
supported starting point.
