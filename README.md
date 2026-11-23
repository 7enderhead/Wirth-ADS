# Wirth-ADS

A small workspace for writing Free Pascal procedures and functions and testing
them with FPCUnit — from the command line and from the Lazarus IDE.

There are no standalone CLI programs here. Code lives in units under `src/`;
an FPCUnit suite under `tests/` exercises it. Add a procedure, add a test, run
`make`. That is the whole loop.

Tested on GNU/Linux x86_64 with Free Pascal 3.2.4 and Lazarus/lazbuild 4.8
(see `make doctor` on your machine).

## Quick start

```sh
make doctor                  # show fpc / lazbuild that will be used
make                         # build and run all tests
make test ARGS='--suite=TTextUtilsTest'
make lazbuild                # build tests/tests.lpi the Lazarus way
make debug-check             # verify the test binary is debuggable
make clean
```

The no-argument test binary also runs everything and exits non-zero on
failure:

```sh
./build/tests/tests
./build/tests/tests --list
./build/tests/tests --format=xml
```

## Layout

```
.
├── Makefile                 # make / make test / make lazbuild / make clean / make doctor / make help
├── src/
│   └── utextutils.pas       # example unit: functions + a procedure with an out-parameter
├── tests/
│   ├── tests.lpr            # FPCUnit console runner (runs all tests by default)
│   ├── tests.lpi            # the same project for the Lazarus IDE
│   └── utextutils_tests.pas # tests for src/utextutils.pas
├── scripts/
│   ├── common.sh            # shared compiler flags and fpc.cfg detection
│   └── run-tests.sh         # builds and runs the suite; --help lists options
├── docs/                    # detailed documentation (see below)
└── build/                   # generated output, git-ignored
```

## Documentation

| File                       | Contents                                                        |
| -------------------------- | --------------------------------------------------------------- |
| `docs/usage.md`            | Make targets, runner options, exit codes, Lazarus workflow      |
| `docs/lazarus.md`          | Code + tests in the IDE: run, single-test runs, debugging       |
| `docs/adding-code.md`      | Step-by-step: new procedure, new unit, new test, assertions     |
| `docs/toolchain.md`        | Build pipeline, compiler flags, fpc.cfg handling, verification  |
| `docs/troubleshooting.md`  | Common failures and their fixes                                 |
| `docs/README.md`           | Index of the documentation                                      |

## Conventions at a glance

- One unit per topic in `src/u<topic>.pas`; one matching test unit in
  `tests/u<topic>_tests.pas`.
- Test methods live in a `published` section and start with `Test`.
- Register the test class once with `RegisterTest(TYourTest);` in the test
  unit's `initialization`.
- Add the test unit to the `uses` clause of `tests/tests.lpr`.
- Do not name a unit after an RTL unit (`strings`, `classes`, `sysutils`,
  `types`, ...). The compiler will try to read your file as that unit and fail
  with `"UNIT" expected but "PROGRAM" found`. Details in
  `docs/troubleshooting.md`.
- `build/` is disposable: `make clean && make` must always work and must not
  require anything outside this repository.

## Requirements

- Free Pascal 3.2 or newer (`fpc`), with the bundled `fcl-fpcunit` package
- GNU make, bash, and a POSIX shell
- Lazarus / `lazbuild` (optional; only needed for `make lazbuild` or IDE work)
