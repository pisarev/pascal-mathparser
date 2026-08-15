<#
  Building the Delphi packages.

  Three packages: two runtime ones (the core and the accelerator) and one
  design-time package that puts the components on the palette. They are built
  from the command line so that the matrix catches a drift in the composition:
  if a unit appeared in or vanished from MANIFEST.md while the .dpk was not
  regenerated, the build falls here.

  The design-time package exists for 32 bits only: the Delphi IDE is 32-bit and
  needs a .bpl to match.

  Run: pwsh -File build.ps1
  The exit code is the number of packages that did not build.
#>

$ErrorActionPreference = 'Continue'

# The bin directory of the studio. BDS_BIN overrides it; otherwise BDS is used,
# which Delphi sets itself; the last guess is the standard install location.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

$Here = $PSScriptRoot

# The library directories. In the monorepo they are 0-foundation\pascal and
# pascal-jit, in the published repository they are src and jit at the root.
# PARSER_SRC and PARSER_JIT override both guesses.
$MonoSrc = Join-Path $Here '..\pascal'
$MonoJit = Join-Path $Here '..\pascal-jit'
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

$Failed = 0

foreach ($Target in @('win32', 'win64')) {
    $Dcc = if ($Target -eq 'win32') { Join-Path $Bin 'dcc32.exe' } else { Join-Path $Bin 'dcc64.exe' }
    $Rtl = Join-Path (Split-Path $Bin) "lib\$Target\release"

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
$RunRoot = Initialize-RunRoot (Join-Path $Here '..')
if ($null -eq $RunRoot) { exit 1 }
    $Out = Join-Path $RunRoot "$Target"
    New-Item -ItemType Directory -Force $Out | Out-Null

    # The palette package builds for 32 bits only: there is no designide for 64.
    $Packages = if ($Target -eq 'win32') {
        @('crosspascal_parser', 'crosspascal_parserjit', 'crosspascal_parser_dsgn')
    } else {
        @('crosspascal_parser', 'crosspascal_parserjit')
    }

    foreach ($Pkg in $Packages) {
        Write-Host "=== $Pkg ($Target)"
        & $Dcc -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl + ';' + $Out) ('-I' + $Src) `
            ('-LE' + $Out) ('-LN' + $Out) ('-NU' + $Out) '-NSSystem;System.Win;WinApi;Vcl' `
            (Join-Path $Here "$Pkg.dpk") |
            Select-String -Pattern 'Error|Fatal|lines,' | Select-Object -First 3 | ForEach-Object { "    $_" }
        if ($LASTEXITCODE -ne 0) { Write-Host "    DID NOT BUILD" -ForegroundColor Red; $Failed++ }
    }
}

Write-Host ''
Write-Host "=== Delphi packages: did not build $Failed ==="
exit $Failed
