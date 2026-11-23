program tests;

{ FPCUnit runner. With no arguments it runs all registered tests in plain
  text, so it works both from the command line and with Lazarus' Run command:

      make test                                          # all tests
      make test ARGS='--suite=TTextUtilsTest'            # one suite
      build/tests/tests --list                           # list tests
      build/tests/tests --format=xml                     # other report format }

{$mode objfpc}{$H+}

uses
  consoletestrunner,
  testregistry,
  utextutils_tests;

var
  Runner: TTestRunner;
begin
  { Defaults; explicit command-line options still win. }
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;

  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Title := 'Wirth-ADS tests';
    Runner.Run;
  finally
    Runner.Free;
  end;
end.
