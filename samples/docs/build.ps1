<#
  Building and running the documentation samples.

  Why: the samples on the site and in the README used to live as text only, and
  for years they carried variables that come from nowhere. The compiler never
  saw them, because nobody compiled them. Now every sample is a real program
  with its expected output in a SEPARATE COMMENT LINE { expect: ... }, and the
  page generator puts that very file on the page. That line is not the first
  one: the copyright header sits above it. It used to say "in the first line"
  here - a promise the code did not make and could not make.

  The rule: a sample that does not build, or does not produce the expected
  line, does not reach the page.

  Run: powershell -File build.ps1
  The exit code is the number of failed samples.
#>

$ErrorActionPreference = 'Stop'

# The bin directory of the studio. BDS_BIN overrides it; otherwise BDS is used,
# which Delphi sets itself; the last guess is the standard install location.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

$Here = $PSScriptRoot

# The library directories. In the monorepo they are 0-foundation\pascal and
# pascal-jit, in the published repository they are src and jit at the root.
# PARSER_SRC and PARSER_JIT override both guesses.
$MonoSrc = Join-Path $Here '..\..\pascal'
$MonoJit = Join-Path $Here '..\..\pascal-jit'
$ShipSrc = Join-Path $Here '..\..\src'
$ShipJit = Join-Path $Here '..\..\jit'

# Both layouts at once is not a reason to take whichever turned up first, it is
# a sign that the situation is unclear and a person has to decide. An unrelated
# directory named pascal next to the release tree quietly CHANGES THE SUBJECT OF
# THE CHECK: measured on 11.08.2026 on a copy of the publication - a broken
# published src gave BUILT: 50, NOT BUILT: 0 and code 0, because the neighbour
# was the thing being built. Without the neighbour the same src gave 22 failures.
#
# The layout is decided ONCE, and both roots follow FROM IT.
#
# Choosing the roots SEPARATELY closed the ambiguity alone, and that is not
# enough: if the release has no jit of its own while a foreign one lies next
# door, the refusal does not fire - there is no second candidate - and the gate
# quietly takes the foreign one. A release without its own accelerator passes
# green, the absence masked by a neighbour. Measured on 11.08.2026 on a tree
# where release/jit was missing.
#
# THE TRUST BOUNDARY, said out loud: if BOTH variables are set, the person has
# deliberately allowed any pair, including their own src with an external jit.
# The gate treats such a pair as authoritative. This is a documented exception.
if ($env:PARSER_SRC -and $env:PARSER_JIT) {
    $Src = $env:PARSER_SRC
    $Jit = $env:PARSER_JIT
} elseif ($env:PARSER_SRC -or $env:PARSER_JIT) {
    Write-Host "THE ROOTS ARE SET BY HALVES: the other half would have to be guessed" -ForegroundColor Red
    Write-Host "  set both PARSER_SRC and PARSER_JIT - or neither"
    exit 1
} else {
    $MonoOk = (Test-Path $MonoSrc) -and (Test-Path $MonoJit)
    $ShipOk = (Test-Path $ShipSrc) -and (Test-Path $ShipJit)
    if ($MonoOk -and $ShipOk) {
        Write-Host "THE LAYOUT IS AMBIGUOUS: both layouts are complete" -ForegroundColor Red
        Write-Host "  set PARSER_SRC and PARSER_JIT explicitly - otherwise it is unknown what is checked"
        exit 1
    } elseif ($MonoOk) {
        $Src = (Resolve-Path $MonoSrc).Path; $Jit = (Resolve-Path $MonoJit).Path
    } elseif ($ShipOk) {
        $Src = (Resolve-Path $ShipSrc).Path; $Jit = (Resolve-Path $ShipJit).Path
    } else {
        Write-Host "THERE IS NO COMPLETE LAYOUT, and filling it in with a neighbour is forbidden. What is missing:" -ForegroundColor Red
        foreach ($P in @($MonoSrc, $MonoJit, $ShipSrc, $ShipJit)) {
            if (-not (Test-Path $P)) { Write-Host "  no $P" }
        }
        exit 1
    }
}

$Rtl = Join-Path (Split-Path $Bin) 'lib\win64\release'

# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
<#
  The run-root rule is looked up UPWARDS the tree, not by a hardcoded path.

  There are two layouts. In the monorepo the rule lives in tests\parser, while
  the slice puts the contents of that folder straight into tests; on top of that
  the script itself sits one level deeper in the slice. A single hardcoded path
  meant an instant refusal for anyone who downloaded the repository: measured on
  release 1.1.1 - the step fell in zero seconds, and none of our checks saw it,
  because nobody ran the matrix of the slice.
#>
$RunRootRule = $null
$Probe = $Here
foreach ($Level in 0..3) {
    foreach ($Tail in @('tests\parser\runroot.ps1', 'tests\runroot.ps1')) {
        $Candidate = Join-Path $Probe $Tail
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) { $RunRootRule = $Candidate; break }
    }
    if ($RunRootRule) { break }
    $Probe = Join-Path $Probe '..'
}
if (-not $RunRootRule) {
    Write-Host "REFUSED: the run-root rule was not found in any layout from $Here"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $Here '..\..')
if ($null -eq $RunRoot) { exit 1 }
$Out = Join-Path $RunRoot 'samples-docs'

# The build directory IS CLEARED: the outcome of a run must not depend on the past.
#
# Both the dcu files and the executables themselves stay here. An exe left from
# the previous time will run and print what is expected even if this build made
# nothing at all - all the more so because the program name comes from the
# source name, not from what has just been produced.
# The same disease has already turned up in the unit-by-unit build: there the
# leftovers of a previous run gave 19 built units instead of 52.
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
# The directory is created BEFORE the check, as in the other three scripts:
# otherwise the guard enumerates a directory that does not exist and goes red on
# the regular path.
New-Item -ItemType Directory -Force $Out | Out-Null
# The clearing IS CHECKED rather than assumed: Remove-Item might have failed,
# and the run would have gone on with programs from the previous time - the very
# thing the clearing exists to get rid of.
# The checker has to PROVE that it enumerated the directory.
#
# A suppressed enumeration error turned "could not look" into "empty": a
# directory with 0333 permissions allows entering and writing but not listing,
# and the check declared it clean. The same fail-open, only now inside the check
# of the clearing itself.
$LErr = $null
$Left = @(Get-ChildItem $Out -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable LErr)
if ($LErr) {
    Write-Host "THE DIRECTORY CANNOT BE ENUMERATED: $Out - $($LErr[0].Exception.Message)" -ForegroundColor Red
    exit 1
}
if ($Left.Count -gt 0) {
    Write-Host "THE BUILD DIRECTORY WAS NOT CLEARED: $Out, files left $($Left.Count)" -ForegroundColor Red
    exit 1
}
New-Item -ItemType Directory -Force (Join-Path $Out 'dcu') | Out-Null

$Failed = 0

# An empty list of samples is a failure too.
#
# A run that found no .dpr at all honestly reached "failures 0" and told the
# matrix step that the samples had been checked. There was nothing to check -
# which is not the same as checked and clean.
# The census of samples takes ORDINARY FILES: otherwise a directory named
# something like Foo.dpr would end up in the list of samples.
$Samples = @(Get-ChildItem (Join-Path $Here '*.dpr') -File | Sort-Object Name)
Write-Host "samples found: $($Samples.Count)"
if ($Samples.Count -eq 0) {
    Write-Host 'NOT A SINGLE SAMPLE WAS FOUND: there was nothing to check' -ForegroundColor Red
    $Failed++
}

foreach ($File in $Samples) {
    $Name = $File.BaseName
    $Text = Get-Content $File.FullName -Raw
    $Expect = ''
    if ($Text -match '\{\s*expect:\s*(.*?)\s*\}') { $Expect = $Matches[1] }

    # Without the marker the sample IS NOT CHECKED, and keeping quiet about that
    # is not allowed.
    #
    # Further down the comparison goes through -like "*$Expect*", and that is a
    # wildcard pattern: with an empty expectation it becomes "**", and any output
    # matches it. A sample printing obvious nonsense would pass with a cheerful
    # "ok ->". An empty marker differs from a missing one only in having been
    # written.
    if (-not $Expect) {
        Write-Host "--- $Name"
        Write-Host "  NO { expect: ... } MARKER: there is nothing to compare the output with" -ForegroundColor Red
        $Failed++
        continue
    }

    Write-Host "--- $Name (expecting: $Expect)"
    & (Join-Path $Bin 'dcc64.exe') -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) `
        ('-I' + $Src) ('-E' + $Out) ('-N0' + (Join-Path $Out 'dcu')) `
        '-NSSystem;System.Win;WinApi;Vcl' $File.FullName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  THE BUILD DID NOT PASS" -ForegroundColor Red
        $Failed++
        continue
    }

    # The build has to PRODUCE a program, not merely return zero.
    #
    # A compiler that returns zero and creates nothing is not a fantasy: replace
    # dcc64 with a stub and the run would carry on. Together with an uncleared
    # directory this gave the worst case: the program FROM THE PREVIOUS run was
    # started, printed the expected line, and the sample passed having built
    # nothing.
    $Exe = Join-Path $Out "$Name.exe"
    if (-not (Test-Path $Exe)) {
        Write-Host "  THE BUILD DID NOT CREATE A PROGRAM: $Exe" -ForegroundColor Red
        $Failed++
        continue
    }

    # A line of nothing but spaces is NOT output, the same as in the Linux twin.
    #
    # There the lines are filtered out by grep -v '^[[:space:]]*$', while here
    # the comparison went against an empty string: "   " is not equal to it, and
    # one and the same sample with the marker nothing printed passed on Linux and
    # went red on Windows.
    $Raw = (& $Exe 2>&1 | ForEach-Object { $_.ToString() }) -join "`n"
    $Lines = $Raw -split "`n" | Where-Object { $_.Trim() -ne '' }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  THE RUN FELL: code $LASTEXITCODE" -ForegroundColor Red
        $Failed++
        continue
    }

    # The promise of silence is checked LITERALLY, against the raw output, as in
    # the twin.
    #
    # Checking against the filtered lines was wrong: a program printing a line of
    # spaces gave an empty list and got an ok. But "nothing was printed" and "a
    # line of spaces was printed" are different states.
    if ($Expect -eq 'nothing printed') {
        if ($Raw -ne '') {
            Write-Host "  EXPECTED SILENCE, but the output is not empty: [$Raw]" -ForegroundColor Red
            $Failed++
        } else {
            Write-Host "  ok"
        }
        continue
    }

    # The comparison is EXACT, not by containment.
    #
    # It used to be -like "*$Expect*", that is a substring: a sample expecting
    # "4" would pass on the output "14", "40" and "4 workers, 0 wrong". An
    # expectation of one or two characters means almost nothing under such a
    # comparison. All eight samples print the expected line verbatim, so not one
    # of them needs the leniency.
    #
    # The comparison is -ceq, case-sensitive: the Linux twin compares with the =
    # operator inside [ ], and that one distinguishes case. The ordinary -eq
    # ignores case, and one and the same marker would mean different things on
    # the two platforms.
    $Last = if ($Lines) { ($Lines | Select-Object -Last 1).Trim() } else { '' }
    if ($Last -ceq $Expect) {
        Write-Host "  ok -> $Last"
    } else {
        Write-Host "  EXPECTED '$Expect', GOT '$Last'" -ForegroundColor Red
        $Failed++
    }
}

# The listings in the published README have to be extracts from these very
# files. Otherwise the README will start living a life of its own again, as it
# already did once.
function Normalize([string]$Text) {
    $Text = $Text -replace "`r`n", "`n"
    $Lines = $Text -split "`n" |
        Where-Object { $_ -notmatch '\{\s*(expect:|needs:|show\b)' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' }
    return ($Lines -join "`n")
}

# The original README lives in publish\, while in the published repository it is
# at the root.
$MonoReadme = Join-Path $Here '..\..\..\publish\pascal-mathparser\README.md'
$Readme = if (Test-Path $MonoReadme) { $MonoReadme } else { Join-Path $Here '..\..\README.md' }
if (Test-Path $Readme) {
    Write-Host ''
    Write-Host '--- README listings against the sample files'
    # The listings are compared with EACH sample separately, not with their
    # concatenation.
    #
    # Everything used to be joined into one string through -join, and at the
    # seam of two files a text appeared that exists in neither of them: the end
    # of one plus the beginning of the next. A README block landing on such a
    # seam was found in the concatenation and got an "ok", although it was an
    # extract from nothing.
    $EachSample = @(Get-ChildItem (Join-Path $Here '*.dpr') -File | ForEach-Object {
        Normalize (Get-Content $_.FullName -Raw) })
    $Text = Get-Content $Readme -Raw
    $Blocks = [regex]::Matches($Text, '(?s)```pascal\r?\n(.*?)```')
    $Bad = 0
    foreach ($B in $Blocks) {
        $Snippet = Normalize $B.Groups[1].Value

        # An EMPTY listing is not an extract, it is a hole in the check.
        #
        # Normalize of an empty block gives an empty string, and Contains('') is
        # true for any string: such a block got a cheerful "ok". Worse, it also
        # got around the guard against zero blocks - the block does exist, it
        # simply has nothing in it. Remove every real listing from the README and
        # leave one empty one, and half the check went green having compared not
        # a single line.
        if (-not $Snippet) {
            Write-Host '  AN EMPTY pascal LISTING: there is nothing to compare' -ForegroundColor Red
            $Bad++
            continue
        }

        $FromOne = @($EachSample | Where-Object { $_.Contains($Snippet) }).Count -gt 0
        if ($FromOne) {
            Write-Host ("  ok    " + ($Snippet -split "`n")[0])
        } else {
            Write-Host ("  NOT FROM A SAMPLE: " + ($Snippet -split "`n")[0]) -ForegroundColor Red
            $Bad++
        }
    }
    Write-Host ("  blocks: " + $Blocks.Count + ", foreign: $Bad")
    $Failed += $Bad

    # Zero blocks is not "all clean", it is "there was nothing to compare".
    # A README without listings would have passed this half silently and green.
    if ($Blocks.Count -eq 0) {
        Write-Host '  THE README HAS NOT A SINGLE pascal LISTING: there is nothing to compare' -ForegroundColor Red
        $Failed++
    }
}
else {
    # A check that silently did not run reads as a check that ran.
    # Without this branch a missing README meant the listings were compared with
    # nothing at all, while the run stayed green.
    Write-Host ''
    Write-Host "THE README WAS NOT FOUND ($Readme): the listings were not compared" -ForegroundColor Red
    $Failed++
}

Write-Host ''
Write-Host "=== documentation samples: failures $Failed ==="
exit $Failed
