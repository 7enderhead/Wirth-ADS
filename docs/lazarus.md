# Working in Lazarus: code and tests side by side

The whole workspace is one Lazarus project: `tests/tests.lpi`. The project
contains the test runner, the test unit, and the unit under test, so you can
write a procedure and its test without switching projects, run the suite with
one key, and debug both sides in the same session.

`make lazbuild` proves the project builds headlessly at any time.

## Open the project

1. Lazarus → File → Open → `tests/tests.lpi`.
2. View → Project Inspector. It lists:
   - `tests.lpr` — the FPCUnit runner,
   - `utextutils_tests.pas` — tests,
   - `../src/utextutils.pas` — the code under test (listed as an editor file;
     it is compiled because the test unit uses it, not because it is part of
     the project's own `uses`).
3. Double-click either unit to open it. Keep both in editor tabs/windows; use
   Ctrl+Click (or Search → Find Declaration) on a procedure name to jump
   between test and implementation, and the other way with
   Search → Find Implementation.

If your own unit does not appear, add it once with **Project → Add Editor
Files…** and select `src/yourunit.pas`. Compilation does not depend on this —
`../src` is already in the unit search path — it only makes the file visible
in the Project Inspector and in "open unit" lists.

## Run the tests

- **Run → Run** (F9) builds and runs the suite. With no run parameters the
  runner executes *all* tests in plain text (see `tests/tests.lpr`).
- **Run → Build** compiles without running.
- Console output: when debugging (F9), the debugger captures the program's
  stdout and shows it in its console/pseudo-terminal window (View → Debug
  Windows). If you use the GDB backend and see nothing, start Lazarus from a
  terminal or redirect stdout in Run → Run Parameters. `make test` in a
  terminal always shows the report.

> **Do not enable "Use launching application" while debugging.** It makes
> Lazarus launch xterm (through `runwait.sh`) and hand *that* to the debugger.
> The test binary then runs as a child process, so breakpoints in it can never
> fire. Use that option only for **Run without debugging**. This is the most
> common reason for "breakpoints are ignored" after enabling a terminal window
> for console output.

### Run only the test you are working on

**Run → Run Parameters…** → *Command line parameters*:

```
--suite=TTextUtilsTest.TestReverse
```

Dotted names work for a single method, and several can be comma-separated:

```
--suite=TTextUtilsTest.TestReverse,TTextUtilsTest.TestSplitWords
```

Other useful parameters (see `docs/usage.md`):

```
--list                  # list registered tests, do not run
--suite=TTextUtilsTest  # whole class
--format=xml --file=build/report.xml
--sparse                # only failures/errors
```

Run parameters are stored in the IDE session (`tests.lps`, git-ignored), so
each machine/checkout can have its own selection.

## Debug code and tests

1. Click in the gutter (or press F5) next to a line in the **test** or in the
   **procedure under test** to set a breakpoint. Both are compiled with debug
   info (`-gl`, Dwarf, no optimisation — configured in `tests.lpi`).
   Make sure "Use launching application" is disabled (see above), otherwise
   the debugger never gets control of your binary.
2. Run → Run (F9). Execution stops at the breakpoint.
3. Step through with Run → Step Into (F7) / Step Over (F8); continue with
   Run → Continue, stop with Run → Stop (Ctrl+F2).
4. Inspect state with View → Debug Windows:
   - **Watches** — add expressions such as `S`, `Clean`, `Result`, `List`.
   - **Local Variables** — arguments and locals of the current frame.
   - **Call Stack** — when stopped in FPCUnit internals, select your test
     method or your unit's procedure frame.
   - **Evaluate/Modify** — evaluate an expression or change a variable while
     stopped; the debugger can also call simple functions from here.
5. If the debugger stops inside FPCUnit when a test *fails*, that is the
   caught `EAssertionFailedError`. Continue past it, or add
   `EAssertionFailedError` to the debugger's ignored exceptions (debugger
   settings, language-exceptions page) if you do not want to stop there.

Debugging one test is easier with a run parameter (above): the debugger does
not stop in the other tests.

### Debugging the code path without a failing test

- Set the breakpoint in the procedure, then run any test that calls it (use
  `--suite=` to narrow this down).
- Use **Run → Run to Cursor** to stop at a specific line without a
  breakpoint.
- For one-off experiments, temporarily add a test method that calls the
  procedure with the inputs you care about, debug it, then remove it. It will
  be picked up automatically because the class is already registered.

## Typical edit/run loop

1. Write the test first (failing) — `tests/utextutils_tests.pas`.
2. Run (F9); read the failure. No console? `make test` in a terminal.
3. Implement or fix the procedure in `src/utextutils.pas`.
4. Re-run. Add a breakpoint and step through if the behaviour is unclear.
5. Before committing, run `make clean && make` to confirm the same result
   outside the IDE.

## Command-line debugging

The same test binary can be debugged with gdb (installed here) without the
IDE:

```sh
gdb --args ./build/tests/tests --suite=TTextUtilsTest.TestReverse
```

```text
(gdb) break utextutils.pas:42
(gdb) run
(gdb) next          # step over
(gdb) step          # step into
(gdb) print S
(gdb) bt            # call stack
(gdb) continue
```

The binary is built with Dwarf symbols and is not stripped, so file/line
breakpoints work. If gdb does not find the source, check that `build/` was
produced by the current sources (`make clean && make`).

## Project settings relevant to debugging

| Setting | Value | Why |
| ------- | ----- | --- |
| Target | `../build/tests/tests` | Everything generated stays in `build/`. |
| Unit output | `../build/tests/lib` | Keeps `.ppu`/`.o` out of the source tree. |
| Other unit files | `../src` | Finds the units under test. |
| Debug info | on (`Dwarf`) | Breakpoints, watches, stack traces. |
| Optimisation | 0 | Reliable stepping and variable inspection. |
| Strip symbols | off | Symbol names remain available. |

Do not enable optimisation while debugging; values may be optimised away. The
command-line build uses the same flags (`scripts/common.sh`).

## Troubleshooting quick reference

- **Breakpoints are never hit** — "Use launching application" is enabled (turn
  it off), the breakpoint sits on a declaration/blank line, the program was
  started without the debugger, the binary is stale, or the debugger backend
  is not working. Run `make debug-check` and see `docs/troubleshooting.md`.
- **Breakpoint is ignored / "no debug info"** — rebuild (`Run → Build` or
  `make clean && make`); confirm the above settings; make sure the breakpoint
  is in a unit that is actually compiled (test unit or `src/` unit).
- **Lazarus cannot find `utextutils`** — `../src` missing from the project's
  search path; compare with `make lazbuild`.
- **Program seems to do nothing** — the runner may have received parameters
  such as `--list`; clear Run Parameters and run again.
- **Console output missing** — run Lazarus from a terminal or `make test`.

See `docs/troubleshooting.md` for non-IDE problems.
