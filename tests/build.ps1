$ErrorActionPreference = 'Stop'

# The bin directory of the studio. BDS_BIN overrides it; otherwise BDS is taken, the
# one Delphi sets itself; the last guess is the standard place of installation.
# The bin folder of the studio. Order: the builder's own variable, the one RAD
# Studio sets for its command prompt, then the registry. The registry replaced a
# path written here by hand. That path named a single version - 13 - and on a
# machine with Delphi 12 the build stopped at "dcc64.exe is not recognized",
# which says nothing about the real cause: the studio is installed, just not
# that one.
function Find-BdsBin($Keys = @('HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS',
                               'HKLM:\SOFTWARE\Embarcadero\BDS')) {
    $found = @()
    foreach ($key in $Keys) {
        if (-not (Test-Path $key)) { continue }
        foreach ($item in Get-ChildItem $key) {
            $root = (Get-ItemProperty -Path $item.PSPath -Name RootDir -ErrorAction SilentlyContinue).RootDir
            if (-not $root) { continue }
            $bin = Join-Path $root 'bin'
            if (-not (Test-Path (Join-Path $bin 'dcc64.exe'))) { continue }
            # The key is named after the version: 19.0, 23.0, 37.0. Only the major
            # part is read, and as an integer: [double] would parse 23.0 through the
            # current culture and give nothing on a comma-decimal one.
            $number = 0
            [void][int]::TryParse((($item.PSChildName -split '\.')[0]), [ref]$number)
            $found += [pscustomobject]@{ Version = $number; Bin = $bin }
        }
    }
    if (-not $found) { return '' }
    ($found | Sort-Object Version -Descending)[0].Bin
}

$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { Find-BdsBin }
if (-not $Bin -or -not (Test-Path (Join-Path $Bin 'dcc64.exe'))) {
    throw 'Delphi was not found. Set BDS_BIN to the bin folder of the installation, or run this from the RAD Studio command prompt.'
}

# Library directories. In the monorepo these are 0-foundation\pascal and pascal-jit,
# in the published repository they are src and jit next to the tests. PARSER_SRC and
# PARSER_JIT override both guesses.
$MonoSrc = Join-Path $PSScriptRoot '..\..\pascal'
$MonoJit = Join-Path $PSScriptRoot '..\..\pascal-jit'
$ShipSrc = Join-Path $PSScriptRoot '..\src'
$ShipJit = Join-Path $PSScriptRoot '..\jit'

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

$FailedRuns = 0
# How many checks each program gave: filled in as the run goes and written to counts.tsv.
$Counts = @{}

# Both word sizes: ParserBugTests is the regression of the library, JitRedirectTest
# is the contract of redirection.
#
# Why redirection is checked on both word sizes rather than on x64 alone: it was
# exactly the divergence between them that once hid a defect. Registration without
# Prepare left a prepared script with pointers into memory that had moved; on win64
# ExecuteScript happened to return the right number, on win32 it gave an AV. One run
# of one word size does not see such a thing. On win32 there is no machine code,
# while the IR stage works, so the whole path is checked.
foreach ($Target in @('win32', 'win64')) {

# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
$RunRootRule = Join-Path $PSScriptRoot 'runroot.ps1'
if (-not (Test-Path -LiteralPath $RunRootRule -PathType Leaf)) {
    Write-Host "REFUSED: run root rule not found: $RunRootRule"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $PSScriptRoot '..\..')
if ($null -eq $RunRoot) { exit 1 }
    $Out = Join-Path $RunRoot "$Target"
    New-Item -ItemType Directory -Force (Join-Path $Out 'dcu') | Out-Null
    $Dcc = if ($Target -eq 'win32') { Join-Path $Bin 'dcc32.exe' } else { Join-Path $Bin 'dcc64.exe' }
    $Rtl = Join-Path (Split-Path $Bin) "lib\$Target\release"
    foreach ($Test in @('ParserBugTests', 'JitRedirectTest')) {
        Write-Host "=== BUILD $Test $Target ==="
        $Paths = if ($Test -eq 'ParserBugTests') { $Src + ';' + $Rtl } else { $Src + ';' + $Jit + ';' + $Rtl }
        & $Dcc -B -Q ('-U' + $Paths) ('-I' + $Src) ('-E' + $Out) ('-N0' + (Join-Path $Out 'dcu')) '-NSSystem;System.Win;WinApi;Vcl' (Join-Path $PSScriptRoot "$Test.dpr")
        if ($LASTEXITCODE -ne 0) { throw "build failed: $Test $Target" }
    }
}

foreach ($Target in @('win32', 'win64')) {
    foreach ($Test in @('ParserBugTests', 'JitRedirectTest')) {
        Write-Host "=== RUN $Test $Target ==="
        $Output = & (Join-Path $Out "$Test.exe") 2>&1
        $Output | Out-Host
        Write-Host "exit=$LASTEXITCODE"
        if ($LASTEXITCODE -ne 0) { $FailedRuns++ }
        # The number is taken from win64: so is everything else in counts.tsv.
        if ($Target -eq 'win64') {
            $Line = $Output | Where-Object { $_ -match '^TOTAL:\s*(\d+)' } | Select-Object -Last 1
            if ($Line -and $Line -match '^TOTAL:\s*(\d+)') { $Counts[$Test] = [int]$Matches[1] }
        }
    }
}

# The rest of the JIT layer: x64 only (the machine code emitter). The thread tests
# and the loop guard are not about JIT, but they go by the same build path, and the
# word size does not affect their contract.
#
# The thread tests and ExitRoutingTest used to be in the FPC list alone. The
# contracts they guard, ownership of Exit in a chain of parsers and the thread-safe
# subset, are written in code common to both compilers, and the battery would not
# have caught a regression there on Delphi at all. On Delphi they were run by hand,
# which is the definition of a regression not caught: for as long as somebody
# remembers to start it.
$Out = Join-Path $RunRoot 'win64'
$Rtl = Join-Path (Split-Path $Bin) 'lib\win64\release'
foreach ($Test in @('JitDump', 'JitBench', 'JitParserTest', 'JitContractTest', 'PublicApiTest', 'DocumentedSyntaxTest', 'DemoSpeed', 'BigScript', 'ThreadWaitTest', 'ThreadSafetyTest', 'ThreadShareTest', 'ExitRoutingTest', 'LoopGuardTest', 'LoopScopeTest', 'FpuMaskTest', 'MethodLockTest', 'MathFamilyTest', 'ConstantsTest', 'ScientificTest', 'SignCacheTest', 'PlatformTextTest', 'CacheContractTest', 'ConnectorLoopTest', 'C31Console', 'TextDcRace')) {
    Write-Host "=== BUILD $Test (win64) ==="
    & (Join-Path $Bin 'dcc64.exe') -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) ('-I' + $Src) ('-E' + $Out) ('-N0' + (Join-Path $Out 'dcu')) '-NSSystem;System.Win;WinApi;Vcl' (Join-Path $PSScriptRoot "$Test.dpr")
    if ($LASTEXITCODE -ne 0) { throw "build failed: $Test" }
    Write-Host "=== RUN $Test ==="
    $Output = & (Join-Path $Out "$Test.exe") 2>&1
    $Output | Out-Host
    Write-Host "exit=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { $FailedRuns++ }
    <#
      The number of checks is taken from the run rather than rewritten by hand.

      By hand it rotted: the documentation promised 26 checks of the machine code
      contract when the run was already giving 80. Nobody saw the error for years,
      because there was nothing to compare the number with. Now the run leaves it here,
      and the release check compares the marked statements of the texts against this
      file.

#>
    $Line = $Output | Where-Object { $_ -match '^TOTAL:\s*(\d+)' } | Select-Object -Last 1
    if ($Line -and $Line -match '^TOTAL:\s*(\d+)') { $Counts[$Test] = [int]$Matches[1] }
}

$CountsFile = Join-Path $PSScriptRoot 'counts.tsv'
$Tab = [char]9
# The header is ENGLISH because the file itself ships. It is declared in
# jit/README.md and goes out as it is; the comment stripping does not touch it,
# since it is not a Pascal source. The monorepo copy of this script used to write
# a Russian header while the published copy already wrote an English one - and
# counts.tsv is produced by the monorepo copy, so 64 Cyrillic characters reached
# the release tree and reddened the publication-defect gate. Fixing the file
# itself does not hold: the next run rewrites it. It is fixed here, in what
# produces it.
$Lines = @('# How many checks the run gave. Written by build.ps1, not edited by hand.')
$Lines += ('# program' + $Tab + 'checks')
foreach ($k in ($Counts.Keys | Sort-Object)) { $Lines += ($k + $Tab + $Counts[$k]) }
Set-Content -Path $CountsFile -Value $Lines -Encoding UTF8
Write-Host "=== COUNTS -> $CountsFile ($($Counts.Count) programs) ==="

Write-Host "=== DONE: failed runs: $FailedRuns ==="
exit $FailedRuns
