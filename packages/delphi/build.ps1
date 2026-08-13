<#
  Building the Delphi packages.

  Three packages: two run-time ones (the core and the accelerator) and one
  design-time package that puts the components into the palette. They are built from
  the command line so that the matrix catches a divergence of composition: if a unit
  has appeared in or gone from MANIFEST.md while the .dpk has not been regenerated,
  the build will fall over here.

  The design-time package exists for 32 bits only: the Delphi environment is 32-bit,
  and the .bpl it needs has to match.

  To run: pwsh -File build.ps1
  The return code is the number of packages that did not build.
#>

$ErrorActionPreference = 'Continue'

# The bin directory of the studio. BDS_BIN overrides it; otherwise BDS is taken, the
# one Delphi sets itself; the last guess is the standard place of installation.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

$Here = $PSScriptRoot

# Library directories. In the monorepo these are 0-foundation\pascal and pascal-jit,
# in the published repository they are src and jit at the root. PARSER_SRC and
# PARSER_JIT override both guesses.
$MonoSrc = Join-Path $Here '..\pascal'
$MonoJit = Join-Path $Here '..\pascal-jit'
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

$Failed = 0

foreach ($Target in @('win32', 'win64')) {
    $Dcc = if ($Target -eq 'win32') { Join-Path $Bin 'dcc32.exe' } else { Join-Path $Bin 'dcc64.exe' }
    $Rtl = Join-Path (Split-Path $Bin) "lib\$Target\release"

# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
$RunRootRule = Join-Path $Here '..\tests\parser\runroot.ps1'
if (-not (Test-Path -LiteralPath $RunRootRule -PathType Leaf)) {
    Write-Host "REFUSED: run root rule not found: $RunRootRule"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $Here '..')
if ($null -eq $RunRoot) { exit 1 }
    $Out = Join-Path $RunRoot "$Target"
    New-Item -ItemType Directory -Force $Out | Out-Null

    # The palette package is built for 32 bits only: for 64 there is no designide.
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
Write-Host "=== Delphi packages: not built $Failed ==="
exit $Failed
