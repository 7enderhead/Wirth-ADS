unit utextutils_tests;

{ Tests for src/utextutils.pas. Follow this pattern for new units: create a
  <unitname>_tests.pas, register the test class, and add the unit to the uses
  clause of tests/tests.lpr. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, utextutils;

type
  TTextUtilsTest = class(TTestCase)
  published
    procedure TestReverse;
    procedure TestReverseEmpty;
    procedure TestPalindromeIgnoresCaseAndPunctuation;
    procedure TestNotAPalindrome;
    procedure TestSplitWords;
    procedure TestWordCount;
    procedure TestWordCountEmpty;
  end;

implementation

procedure TTextUtilsTest.TestReverse;
begin
  AssertEquals('olleh', ReverseText('hello'));
end;

procedure TTextUtilsTest.TestReverseEmpty;
begin
  AssertEquals('', ReverseText(''));
end;

procedure TTextUtilsTest.TestPalindromeIgnoresCaseAndPunctuation;
begin
  AssertTrue(IsPalindrome('A man, a plan, a canal: Panama'));
  AssertTrue(IsPalindrome('Racecar'));
end;

procedure TTextUtilsTest.TestNotAPalindrome;
begin
  AssertFalse(IsPalindrome('Free Pascal'));
end;

procedure TTextUtilsTest.TestSplitWords;
var
  Words: TStringList;
begin
  Words := TStringList.Create;
  try
    SplitWords('  one two  three ', Words);
    AssertEquals(3, Words.Count);
    AssertEquals('one', Words[0]);
    AssertEquals('two', Words[1]);
    AssertEquals('three', Words[2]);
  finally
    Words.Free;
  end;
end;

procedure TTextUtilsTest.TestWordCount;
begin
  AssertEquals(7, WordCount('  A man, a plan, a canal: Panama  '));
end;

procedure TTextUtilsTest.TestWordCountEmpty;
begin
  AssertEquals(0, WordCount(''));
  AssertEquals(0, WordCount('   '));
end;

initialization
  RegisterTest(TTextUtilsTest);

end.
