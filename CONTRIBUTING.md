# Contributing

Thanks for taking the time. One person maintains this, so the process is short.

## Reporting a problem

Open an issue. What helps:

- the formula or the code that misbehaves, exactly as you wrote it;
- what you expected and what came out;
- compiler and platform: Delphi or FPC, which version, 32 or 64 bit.

A wrong number is a good report. "It does not work" is not, because the parser
has three back ends and they fail in different ways.

## Sending a change

Building and running the tests is described in the README. There is no separate
developer setup.

- keep one change about one thing;
- match the surrounding code - this is Object Pascal in the house style, and the
  tests are plain console programs that print TOTAL and FAILED;
- run the tests for the part you touched and put in the pull request what you
  ran and what it printed. Numbers travel better than assurances.

## Terms

By opening a pull request you agree that your contribution is licensed to
the project owner under the MIT licence, and that the owner may relicense
the project, including your contribution, under different terms in the
future.

You keep the copyright to what you wrote. This is a licence grant, not a
transfer: it exists so the project can change its licence later without
tracking down everyone who ever sent a patch.
