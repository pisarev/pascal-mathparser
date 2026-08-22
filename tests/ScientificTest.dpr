{ ************************************************************************** }
{                                                                            }
{ ScientificTest                                                             }
{                                                                            }
{ Copyright © 2026 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

program ScientificTest;

{$APPTYPE CONSOLE}
{$B-}

uses
  {$IFDEF UNIX}{$IFDEF FPC}cthreads, cwstring,{$ENDIF}{$ENDIF}
  SysUtils, ParseUtils, TestKit in 'TestKit.pas';

{
  What this file guards.

  ExpandScientific is declared in the interface of ParseUtils, which means it
  travels into the release as a public function. Nothing inside the library
  calls it, and without a battery of its own it would go out unmeasured: a
  person takes it from the header and gets behaviour nobody ever checked.

  The function turns a record with an exponent into a plain one: 1E3 into 1000.
  Anything that is not such a number has to come back unchanged - rubbish,
  hexadecimal records and ordinary words alike.

  Three sections, and they carry different weight.

  THE CANON is the table set by the author. That is a contract, and a
  divergence here is a defect.

  BEYOND THE CANON are the edge cases the table does not name: an empty
  mantissa, an exponent without digits, two exponents, spaces at the edges.
  A defect here too: the rule "give back what you did not understand" covers
  them as well.

  THE LOCALE is the same canon with a comma as the system separator. The
  function does not use the system separator: it takes the one standing in the
  record itself, and puts a full stop when there is none. That statement is
  CHECKED by a run here rather than asserted in a comment: between Windows and
  Linux the locale is the first thing to move.
}

procedure Same(const Name, Input, Want: string);
var
  Got: string;
begin
  Got := ExpandScientific(Input);
  Check(Name, Got = Want, Format('%s -> %s, expected %s', [Input, Got, Want]));
end;

{ A record with no exponent has to come back as the same string, byte for byte. }
procedure Untouched(const Name, Input: string);
begin
  Same(Name, Input, Input);
end;

var
  Long: string;
begin
  BeginSection('the canon: the author table');
  Same('an integer with an exponent', '1E3', '1000');
  Same('an exponent in lower case', '1e3', '1000');
  Same('an exponent with an explicit plus', '1E+3', '1000');
  Same('a negative exponent', '1E-3', '0.001');
  Same('a fractional mantissa', '1.25E3', '1250');
  Same('a fractional mantissa with a minus', '1.25E-3', '0.00125');
  Same('a sign in front of the mantissa', '-1.25E3', '-1250');
  Same('a mantissa below one', '0.5E1', '5');
  Same('trailing zeros are dropped', '1.2300E2', '123');
  Same('a comma as the separator is kept', '1,25E-2', '0,0125');
  Untouched('a plain integer', '123');
  Untouched('a plain fraction', '123.45');
  Untouched('not a number at all', 'abc');
  Untouched('letters after the exponent', '12Efoo');
  BeginSection('beyond the canon: the edge cases');
  Same('a full stop at the start of the mantissa', '.5E3', '500');
  Same('a full stop at the end of the mantissa', '5.E3', '5000');
  Same('a zero exponent', '1E0', '1');
  Same('a zero with an exponent', '0E0', '0');
  { A leading sign is kept as written - the minus and the plus alike. That is one
    rule rather than two: the canon asks for -1.25E3 -> -1250, and +1E3 -> +1000
    follows from it. }
  Same('a plus in front of the mantissa is kept', '+1E3', '+1000');
  Same('a signed zero', '-0E5', '0');
  Same('a minus zero in the exponent', '1E-0', '1');
  Same('the exponent cancels one digit', '10E-1', '1');
  Same('the exponent cancels six digits', '1000000E-6', '1');
  Untouched('an exponent with no digits', '1E');
  Untouched('an empty mantissa', 'E3');
  Untouched('an exponent sign with no digits', '1E+');
  Untouched('two exponents in a row', '1EE3');
  Untouched('a space on the left', ' 1E3');
  Untouched('a space on the right', '1E3 ');
  Untouched('a fractional exponent', '1E3.5');
  Untouched('two full stops in the mantissa', '1.2.3E1');
  Untouched('a Pascal hexadecimal record', '$FF');
  Untouched('a C hexadecimal record', '0x1F');
  Untouched('a binary record', '%1010');
  Untouched('an octal record', '&17');
  Untouched('an empty string', '');
  Same('fifteen digits', '1E15', '1000000000000000');
  Same('a long mantissa is not rounded', '1.7976931348623157E10', '17976931348.623157');
  BeginSection('the contract: a second call changes nothing');
  Check('1E3 expands once',
    ExpandScientific(ExpandScientific('1E3')) = ExpandScientific('1E3'),
    ExpandScientific(ExpandScientific('1E3')));
  Check('1E-3 expands once',
    ExpandScientific(ExpandScientific('1E-3')) = ExpandScientific('1E-3'),
    ExpandScientific(ExpandScientific('1E-3')));
  Check('abc does not change the second time either',
    ExpandScientific(ExpandScientific('abc')) = 'abc', ExpandScientific('abc'));
  {
    A ceiling on growth. Without it 1E1000000 built a million characters, and an
    exponent near two billion asked for gigabytes - for a public function fed
    somebody else's input that is a way to hang the program. A record that does
    not fit into MaxLength now comes back as it was, by the same rule as any
    non-numeric string.

    Both sides of the ceiling are checked: that what is close to it expands, and
    that what is past it comes back untouched.
  }
  BeginSection('the ceiling on growth');
  Same('below the ceiling it expands', '1E1000', '1' + StringOfChar('0', 1000));
  Untouched('an exponent of a million comes back as it was', '1E1000000');
  Untouched('and an exponent near two billion too', '1E2000000000');
  Untouched('to the left the ceiling is the same', '1E-1000000');
  Same('a small one below the ceiling expands', '1E-3', '0.001');
  Long := ExpandScientific('1E1000000');
  Check('a large exponent takes no memory',
    Length(Long) = Length('1E1000000'), Format('got %d characters', [Length(Long)]));
  BeginSection('the locale: a comma as the system separator');
  {
    The system separator is changed to a comma and the canon is run again. If
    the function leans on FormatSettings anywhere, these lines go red.
  }
  FormatSettings.DecimalSeparator := ',';
  FormatSettings.ThousandSeparator := '.';
  Same('an integer with an exponent under a comma', '1E3', '1000');
  Same('a negative exponent under a comma', '1E-3', '0.001');
  Same('a fractional mantissa under a comma', '1.25E-3', '0.00125');
  Same('a sign in front of the mantissa under a comma', '-1.25E3', '-1250');
  Same('a comma in the record under a comma', '1,25E-2', '0,0125');
  Untouched('a plain fraction under a comma', '123.45');
  Halt(TestSummary);
end.
