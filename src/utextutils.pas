unit utextutils;

{ Procedures and functions to experiment with. Add your own here (or create
  another unit in src/) and write a matching test in tests/. }

{$mode objfpc}{$H+}

interface

uses
  Classes;

{ Reverse a string, character by character. }
function ReverseText(const S: string): string;

{ True if S reads the same forwards and backwards, ignoring case and
  anything that is not a letter or digit. }
function IsPalindrome(const S: string): Boolean;

{ Append every whitespace-separated word in S to List.
  This is a procedure with an out-parameter, the usual shape for helpers
  that fill a collection instead of returning a value. }
procedure SplitWords(const S: string; List: TStrings);

{ Number of whitespace-separated words in S. }
function WordCount(const S: string): Integer;

implementation

uses
  SysUtils;

function ReverseText(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  SetLength(Result, Length(S));
  for I := 1 to Length(S) do
    Result[Length(S) - I + 1] := S[I];
end;

function IsPalindrome(const S: string): Boolean;
var
  Clean: string;
  I: Integer;
begin
  Clean := '';
  for I := 1 to Length(S) do
    if S[I] in ['a'..'z', 'A'..'Z', '0'..'9'] then
      Clean := Clean + LowerCase(S[I]);
  Result := Clean = ReverseText(Clean);
end;

procedure SplitWords(const S: string; List: TStrings);
var
  I, Start: Integer;

  procedure Emit(EndPos: Integer);
  begin
    if EndPos > Start then
      List.Add(Copy(S, Start, EndPos - Start));
  end;

begin
  Start := 1;
  for I := 1 to Length(S) + 1 do
  begin
    if (I > Length(S)) or (S[I] <= ' ') then
    begin
      Emit(I);
      Start := I + 1;
    end;
  end;
end;

function WordCount(const S: string): Integer;
var
  Words: TStringList;
begin
  Words := TStringList.Create;
  try
    SplitWords(S, Words);
    Result := Words.Count;
  finally
    Words.Free;
  end;
end;

end.
