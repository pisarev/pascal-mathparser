{ ************************************************************************** }
{                                                                            }
{ TextConsts                                                                 }
{                                                                            }
{ Copyright © 2007 Yuriy Pisarev (ypisareff@outlook.com)                     }
{                                                                            }
{ ************************************************************************** }

unit TextConsts;

{$B-}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

const
  Above = '>';
  Ampersand = '&';
  Asterisk = '*';
  AtSign = '@';
  Backslash = '\';
  Below = '<';
  Colon = ':';
  Comma = ',';
  CarriageReturn = #13;
  CR = CarriageReturn;
  Dash = '-';
  Dollar = '$';
  Dot = '.';
  DoubleQuote = '"';
  DQ = DoubleQuote;
  DoubleSlash = '//';
  DS = DoubleSlash;
  Equal = '=';
  Exclamation = '!';
  Inquiry = '?';
  LBrace = '{';
  LBracket = '[';
  LParenthesis = '(';
  LineFeed = #10;
  LF = LineFeed;
  Minus = '-';
  Negative = Minus;
  Percent = '%';
  Pipe = '|';
  Plus = '+';
  Positive = Plus;
  Pound = '#';
  Quote = '''';
  RBrace = '}';
  RBracket = ']';
  RParenthesis = ')';
  Semicolon = ';';
  Slash = '/';
  Space = ' ';
  Tilde = '~';
  Underscore = '_';
  LineBreak = {$IFDEF UNIX}LF{$ELSE}CR + LF{$ENDIF};
  LB = LineBreak;

  Blanks = [CR, LF, Space, Chr(160)];
  Breaks = [CR, LF];

implementation

end.
