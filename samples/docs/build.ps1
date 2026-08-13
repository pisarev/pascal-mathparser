<#
  Building and running the samples from the documentation.

  Why: the samples on the showcase and in the README used to live only as text, and
  for years they held variables that come from nowhere. The compiler did not see
  them because nobody compiled them. Now every sample is a real program with its
  expected output in a SEPARATE COMMENT LINE { expect: ... }, and the page generator
  puts exactly that file on the page. That line is not the first one: above it sits
  the licence header. It used to say "on the first line" here, a promise the code
  never made and could not make.

  The rule: a sample that does not build and does not give the expected line does
  not reach the page.

  To run: powershell -File build.ps1
  The return code is the number of samples that failed.
#>

$ErrorActionPreference = 'Stop'

# The bin directory of the studio. BDS_BIN overrides it; otherwise BDS is taken, the
# one Delphi sets itself; the last guess is the standard place of installation.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

$Here = $PSScriptRoot

# Library directories. In the monorepo these are 0-foundation\pascal and pascal-jit,
# in the published repository they are src and jit at the root. PARSER_SRC and
# PARSER_JIT override both guesses.
$MonoSrc = Join-Path $Here '..\..\pascal'
$MonoJit = Join-Path $Here '..\..\pascal-jit'
$ShipSrc = Join-Path $Here '..\..\src'
$ShipJit = Join-Path $Here '..\..\jit'

# Two layouts present at once is not a reason to take whichever turned up first, it
# is a sign that the situation is unclear and a person has to decide. An unrelated
# directory named pascal next to the release tree quietly CHANGES THE SUBJECT OF
# THE CHECK: measured on 11.08.2026 on a copy of the deployment, a broken published
# src gave BUILT: 50, NOT BUILT: 0 and code 0, because the neighbour was the thing
# being built. Without the neighbour the same src gave 22 failures.
#
# The layout is settled ONCE, and both roots are derived FROM IT.
#
# Picking the roots SEPARATELY closed the ambiguity only, and that is not enough:
# if the release has no jit of its own while a foreign one lies next to it, the
# refusal does not fire because no second candidate exists, and the gate quietly
# takes the foreign one. A release without an accelerator of its own passes green,
# the absence masked by a neighbour. Measured on 11.08.2026 on a tree where
# release/jit was missing.
#
# THE LIMIT OF TRUST, said out loud: if BOTH variables are set, the person has
# deliberately allowed any pair, their own src with an external jit included. The
# gate treats such a pair as authoritative. This is a documented exception.
if ($env:PARSER_SRC -and $env:PARSER_JIT) {
    $Src = $env:PARSER_SRC
    $Jit = $env:PARSER_JIT
} elseif ($env:PARSER_SRC -or $env:PARSER_JIT) {
    Write-Host "ROOTS GIVEN BY HALVES: the other half would have to be guessed" -ForegroundColor Red
    Write-Host "  set both PARSER_SRC and PARSER_JIT - or neither"
    exit 1
} else {
    $MonoOk = (Test-Path $MonoSrc) -and (Test-Path $MonoJit)
    $ShipOk = (Test-Path $ShipSrc) -and (Test-Path $ShipJit)
    if ($MonoOk -and $ShipOk) {
        Write-Host "LAYOUT IS AMBIGUOUS: both layouts are complete" -ForegroundColor Red
        Write-Host "  set PARSER_SRC and PARSER_JIT explicitly - otherwise what is checked is unknown"
        exit 1
    } elseif ($MonoOk) {
        $Src = (Resolve-Path $MonoSrc).Path; $Jit = (Resolve-Path $MonoJit).Path
    } elseif ($ShipOk) {
        $Src = (Resolve-Path $ShipSrc).Path; $Jit = (Resolve-Path $ShipJit).Path
    } else {
        Write-Host "NO COMPLETE LAYOUT, and filling it from a neighbour is forbidden. What is missing:" -ForegroundColor Red
        foreach ($P in @($MonoSrc, $MonoJit, $ShipSrc, $ShipJit)) {
            if (-not (Test-Path $P)) { Write-Host "  no $P" }
        }
        exit 1
    }
}

$Rtl = Join-Path (Split-Path $Bin) 'lib\win64\release'

# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
$RunRootRule = Join-Path $Here '..\..\tests\parser\runroot.ps1'
if (-not (Test-Path -LiteralPath $RunRootRule -PathType Leaf)) {
    Write-Host "REFUSED: run root rule not found: $RunRootRule"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $Here '..\..')
if ($null -eq $RunRoot) { exit 1 }
$Out = Join-Path $RunRoot 'samples-docs'

# The build directory is CLEARED: the outcome of a run must not depend on the past.
#
# Both the dcu files and the exe files stay here. An exe left from last time will
# start and print what is expected even if this build produced nothing, all the more
# so because the program name comes from the name of the source rather than from
# what has just been created.
# The same illness has already turned up in the unit-by-unit build: there rubbish
# from the previous run gave 19 built units instead of 52.
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
# The directory is created BEFORE the check, as in the other three scripts:
# otherwise the guard lists a directory that does not exist and goes red on the
# normal path.
New-Item -ItemType Directory -Force $Out | Out-Null
# Clearing is CHECKED rather than assumed: Remove-Item could have failed, and the
# run would go on with the programs from last time, the very ones the clearing was
# put there to remove.
# Whoever checks has to PROVE that the directory was listed.
#
# A suppressed traversal error turned "could not look" into "empty": a directory
# with rights 0333 gives entry and writing but not listing, and the check declared
# it clean. The same fail-open, now inside the check of the clearing itself.
$LErr = $null
$Left = @(Get-ChildItem $Out -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable LErr)
if ($LErr) {
    Write-Host "DIRECTORY DOES NOT LIST: $Out - $($LErr[0].Exception.Message)" -ForegroundColor Red
    exit 1
}
if ($Left.Count -gt 0) {
    Write-Host "BUILD DIRECTORY NOT CLEARED: $Out, files left $($Left.Count)" -ForegroundColor Red
    exit 1
}
New-Item -ItemType Directory -Force (Join-Path $Out 'dcu') | Out-Null

$Failed = 0

# An empty list of samples is a failure too.
#
# A run that found not a single .dpr honestly reached "failures 0" and told the
# matrix step that the samples had been checked. There was nothing to check, which
# is not the same as checked and clean.
# The census of samples takes ORDINARY FILES: otherwise a directory named like
# Foo.dpr would land in the list of samples.
$Samples = @(Get-ChildItem (Join-Path $Here '*.dpr') -File | Sort-Object Name)
Write-Host "samples found: $($Samples.Count)"
if ($Samples.Count -eq 0) {
    Write-Host 'NO SAMPLES FOUND: there was nothing to check' -ForegroundColor Red
    $Failed++
}

foreach ($File in $Samples) {
    $Name = $File.BaseName
    $Text = Get-Content $File.FullName -Raw
    $Expect = ''
    if ($Text -match '\{\s*expect:\s*(.*?)\s*\}') { $Expect = $Matches[1] }

    # Without a marker a sample IS NOT CHECKED, and staying silent about that is not
    # allowed.
    #
    # Further down the comparison goes through -like "*$Expect*", and that is a wildcard
    # pattern: with an empty expectation it becomes "**", and any output fits it. A
    # sample printing obvious nonsense would pass with a cheerful "ok ->". An empty
    # marker differs from a missing one only in having been written.
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
        Write-Host "  BUILD FAILED" -ForegroundColor Red
        $Failed++
        continue
    }

    # The build has to CREATE a program, not merely return a zero.
    #
    # A compiler that returns zero and creates nothing is not an invention: replace
    # dcc64 with a stub and the run would go on. Together with a directory that was not
    # cleared this gave the worst case: the program from the PREVIOUS run started,
    # printed the expected line, and the sample passed having built nothing.
    $Exe = Join-Path $Out "$Name.exe"
    if (-not (Test-Path $Exe)) {
        Write-Host "  THE BUILD PRODUCED NO PROGRAM: $Exe" -ForegroundColor Red
        $Failed++
        continue
    }

    # A line of spaces alone is NOT output, the same as in the Linux twin.
    #
    # There such lines are filtered out by grep -v '^[[:space:]]*$', while here the
    # comparison was against an empty string: "   " is not equal to it, and one and the
    # same sample with the marker nothing printed passed on Linux and went red on
    # Windows.
    $Raw = (& $Exe 2>&1 | ForEach-Object { $_.ToString() }) -join "`n"
    $Lines = $Raw -split "`n" | Where-Object { $_.Trim() -ne '' }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  THE RUN FAILED: code $LASTEXITCODE" -ForegroundColor Red
        $Failed++
        continue
    }

    # The promise of silence is checked LITERALLY, on the raw output, as in the twin.
    #
    # Checking by the filtered lines was wrong: a program printing a line of spaces gave
    # an empty list and got ok. But "nothing was printed" and "a line of spaces was
    # printed" are different states.
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
    # It used to be -like "*$Expect*", that is a substring: a sample expecting "4" would
    # pass on the output "14", "40" and "4 workers, 0 wrong". An expectation of one or
    # two characters means almost nothing with such a comparison. All eight samples
    # print the expected line word for word, so not one of them needs the concession.
    #
    # The comparison is -ceq, with regard to case: in the Linux twin the check goes
    # through the = operator inside [ ], and that one tells case apart. A plain -eq
    # ignores case, and one and the same marker would mean different things on the two
    # platforms.
    $Last = if ($Lines) { ($Lines | Select-Object -Last 1).Trim() } else { '' }
    if ($Last -ceq $Expect) {
        Write-Host "  ok -> $Last"
    } else {
        Write-Host "  EXPECTED '$Expect', got '$Last'" -ForegroundColor Red
        $Failed++
    }
}

# The listings in the published README have to be extracts from these same files.
# Otherwise the README will start living a life of its own again, as it already has.
function Normalize([string]$Text) {
    $Text = $Text -replace "`r`n", "`n"
    $Lines = $Text -split "`n" |
        Where-Object { $_ -notmatch '\{\s*(expect:|needs:|show\b)' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' }
    return ($Lines -join "`n")
}

# The original README lives in publish\, while in the published repository it is at
# the root.
$MonoReadme = Join-Path $Here '..\..\..\publish\pascal-mathparser\README.md'
$Readme = if (Test-Path $MonoReadme) { $MonoReadme } else { Join-Path $Here '..\..\README.md' }
if (Test-Path $Readme) {
    Write-Host ''
    Write-Host '--- README listings against the sample files'
    # The listings are compared with EACH sample separately, not with them glued
    # together.
    #
    # Earlier all the samples were merged into one string through -join, and at the seam
    # between two files there appeared text that is in neither of them: the end of one
    # plus the beginning of the next. A README block that landed on such a seam was
    # found in the glued string and got "ok", although it was an extract from nothing.
    $EachSample = @(Get-ChildItem (Join-Path $Here '*.dpr') -File | ForEach-Object {
        Normalize (Get-Content $_.FullName -Raw) })
    $Text = Get-Content $Readme -Raw
    $Blocks = [regex]::Matches($Text, '(?s)```pascal\r?\n(.*?)```')
    $Bad = 0
    foreach ($B in $Blocks) {
        $Snippet = Normalize $B.Groups[1].Value

        # An EMPTY listing is not an extract, it is a hole in the check.
        #
        # Normalize of an empty block gives an empty string, and Contains('') is true for
        # any string: such a block got a cheerful "ok". Worse, it also went around the
        # defence against zero blocks, because a block is there, it simply holds nothing.
        # Take all the real listings out of the README, leave one empty block, and half the
        # check went green without comparing a single line.
        if (-not $Snippet) {
            Write-Host '  EMPTY pascal LISTING: there is nothing to compare' -ForegroundColor Red
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

    # Zero blocks does not mean "all clean", it means "there was nothing to compare".
    # A README without listings would pass this half in silence and in green.
    if ($Blocks.Count -eq 0) {
        Write-Host '  README HAS NO pascal LISTING AT ALL: there is nothing to compare' -ForegroundColor Red
        $Failed++
    }
}
else {
    # A check that quietly did not run reads as a check that ran.
    # Without this branch the absence of a README meant the listings were compared with
    # nothing, while the run stayed green.
    Write-Host ''
    Write-Host "README NOT FOUND ($Readme): listings were not compared" -ForegroundColor Red
    $Failed++
}

Write-Host ''
Write-Host "=== documentation samples: failures $Failed ==="
exit $Failed
