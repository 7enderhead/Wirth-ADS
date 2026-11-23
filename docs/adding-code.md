# Adding code and tests

The loop is: declare and implement in `src/`, test in `tests/`, run `make`.

## 1. Add a procedure to an existing unit

Open `src/utextutils.pas` and put the declaration in the `interface` section
and the body in the `implementation` section:

```pascal
{ Collapse runs of whitespace into single spaces and trim the ends. }
function SqueezeSpaces(const S: string): string;
```

```pascal
function SqueezeSpaces(const S: string): string;
var
  I: Integer;
  PendingSpace: Boolean;
begin
  Result := '';
  PendingSpace := False;
  for I := 1 to Length(S) do
  begin
    if S[I] <= ' ' then
      PendingSpace := Result <> ''
    else
    begin
      if PendingSpace then
        Result := Result + ' ';
      Result := Result + S[I];
      PendingSpace := False;
    end;
  end;
end;
```

## 2. Add the test method

In `tests/utextutils_tests.pas`, add the method to the class's `published`
section (it must be `published` for FPCUnit to discover it):

```pascal
procedure TestSqueezeSpaces;
```

Then implement it in the `implementation` section:

```pascal
procedure TTextUtilsTest.TestSqueezeSpaces;
begin
  AssertEquals('a b c', SqueezeSpaces('  a   b  c  '));
  AssertEquals('', SqueezeSpaces('   '));
end;
```

The class is registered once in the unit's `initialization` section:

```pascal
initialization
  RegisterTest(TTextUtilsTest);
```

New methods are picked up because they belong to an already registered class;
`tests/tests.lpr` already uses this unit.

## 3. Run

```sh
make
```

If the test fails you get the method name, expected and actual values, and a
non-zero exit code.

## Adding a new unit

1. Create `src/u<topic>.pas`:

   ```pascal
   unit ustringsx;
   {$mode objfpc}{$H+}
   interface
   function Shout(const S: string): string;
   implementation
   uses SysUtils;
   function Shout(const S: string): string;
   begin
     Result := UpperCase(S) + '!';
   end;
   end.
   ```

   The file name must match the unit name.

2. Create `tests/u<topic>_tests.pas` with a `TTestCase` descendant and
   `RegisterTest(...)`.

3. Add the test unit to the `uses` clause of `tests/tests.lpr`:

   ```pascal
   uses
     consoletestrunner,
     testregistry,
     utextutils_tests,
     ustringsx_tests;
   ```

4. In the IDE, optionally add the new files to `tests/tests.lpi`
   (Project → Add Editor Files). Only the test unit is strictly necessary;
   `src/` is already on the search path.

5. `make`

## Test design conventions

- One behaviour per test method; use several `Assert*` calls only when they
  describe the same behaviour.
- Test method names start with `Test` (FPCUnit shows them as-is).
- Keep tests deterministic: no network, no clock, no relying on the current
  directory. Pass data in and check values out.
- Use `SetUp`/`TearDown` for fixtures instead of duplicating constructor code:

  ```pascal
  type
    TFixtureTest = class(TTestCase)
    private
      FList: TStringList;
    protected
      procedure SetUp; override;
      procedure TearDown; override;
    published
      procedure TestSomething;
    end;
  ```

  ```pascal
  procedure TFixtureTest.SetUp;
  begin
    FList := TStringList.Create;
  end;

  procedure TFixtureTest.TearDown;
  begin
    FList.Free;
  end;
  ```

## Assertions

Provided by `TTestCase` (`fpcunit`):

| Assertion | Use |
| --------- | --- |
| `AssertEquals(Expected, Actual)` | Values must be equal (strings, numbers, ...). |
| `AssertTrue(Condition)` | Condition must be `True`. |
| `AssertFalse(Condition)` | Condition must be `False`. |
| `AssertNull(Instance)` / `AssertNotNull(Instance)` | Object existence. |
| `AssertException(ExceptClass, @Method)` | The method must raise that exception class. |
| `Fail('message')` | Unconditional failure, useful in `else` branches. |
| `Ignore('reason')` | Skip a test deliberately. |

Each assertion also has an overload with a custom message as the last
argument, e.g. `AssertEquals('reason', Expected, Actual)`.

## Naming rules that matter

- Unit file name = unit name (`u<topic>.pas` declares `unit u<topic>;`).
- Do **not** reuse an RTL unit name (`strings`, `classes`, `sysutils`, `types`,
  `math`, ...). It produces `Fatal: Syntax error, "UNIT" expected but
  "PROGRAM" found` because the compiler resolves the name to the RTL unit.
  See `docs/troubleshooting.md`.
- Avoid generic unit names that may clash with packages you later add
  (`json`, `xml`, `http`, ...). Prefix with `u` by convention.
