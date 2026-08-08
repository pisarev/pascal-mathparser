$ErrorActionPreference = 'Stop'

# The Delphi bin folder. BDS_BIN wins; otherwise BDS, which the IDE itself
# sets; the last guess is the standard install location.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

# Where the library lives. In the monorepo that is 0-foundation\pascal and
# pascal-jit; in the published repository it is src and jit next to the tests.
# PARSER_SRC and PARSER_JIT override both guesses.
$MonoSrc = Join-Path $PSScriptRoot '..\..\pascal'
$MonoJit = Join-Path $PSScriptRoot '..\..\pascal-jit'
$Src = if ($env:PARSER_SRC) { $env:PARSER_SRC }
       elseif (Test-Path $MonoSrc) { (Resolve-Path $MonoSrc).Path }
       else { (Resolve-Path (Join-Path $PSScriptRoot '..\src')).Path }
$Jit = if ($env:PARSER_JIT) { $env:PARSER_JIT }
       elseif (Test-Path $MonoJit) { (Resolve-Path $MonoJit).Path }
       else { (Resolve-Path (Join-Path $PSScriptRoot '..\jit')).Path }

$FailedRuns = 0
# How many checks each program gave: filled as we go, written to counts.tsv.
$Counts = @{}

# Both word sizes: ParserBugTests is the library regression, JitRedirectTest is
# the redirection contract.
#
# Why redirection is checked on both word sizes and not only on x64: the
# difference between them once hid a defect. Registering without Prepare left
# the prepared script pointing into memory that had been moved; on win64
# ExecuteScript happened to return the right number, on win32 it faulted. One
# run of one word size does not see that. There is no machine code on win32,
# but the IR tier works, so the whole path is exercised.
foreach ($Target in @('win32', 'win64')) {
    $Out = Join-Path $PSScriptRoot "out\$Target"
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
        $Output = & (Join-Path $PSScriptRoot "out\$Target\$Test.exe") 2>&1
        $Output | Out-Host
        Write-Host "exit=$LASTEXITCODE"
        if ($LASTEXITCODE -ne 0) { $FailedRuns++ }
        # Taken from win64: everything else in counts.tsv is measured there too.
        if ($Target -eq 'win64') {
            $Line = $Output | Where-Object { $_ -match '^TOTAL:\s*(\d+)' } | Select-Object -Last 1
            if ($Line -and $Line -match '^TOTAL:\s*(\d+)') { $Counts[$Test] = [int]$Matches[1] }
        }
    }
}

# The rest of the JIT layer: x64 only, since that is where the emitter works.
# The thread tests and the loop guard are not about the JIT but take the same
# build path, and word size does not affect their contract.
#
# The thread tests and ExitRoutingTest used to be listed for FPC only. What they
# guard - who owns an Exit in a chain of parsers, and the thread-safe subset -
# is written in code both compilers share, so a regression there would have gone
# unnoticed on Delphi. They were run by hand instead, which is the definition of
# a regression waiting to happen: it holds only while somebody remembers.
$Out = Join-Path $PSScriptRoot 'out\win64'
$Rtl = Join-Path (Split-Path $Bin) 'lib\win64\release'
foreach ($Test in @('JitDump', 'JitBench', 'JitParserTest', 'JitContractTest', 'PublicApiTest', 'DocumentedSyntaxTest', 'DemoSpeed', 'BigScript', 'ThreadWaitTest', 'ThreadSafetyTest', 'ThreadShareTest', 'ExitRoutingTest', 'LoopGuardTest', 'LoopScopeTest', 'FpuMaskTest', 'MethodLockTest', 'MathFamilyTest', 'C31Console')) {
    Write-Host "=== BUILD $Test (win64) ==="
    & (Join-Path $Bin 'dcc64.exe') -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) ('-I' + $Src) ('-E' + $Out) ('-N0' + (Join-Path $Out 'dcu')) '-NSSystem;System.Win;WinApi;Vcl' (Join-Path $PSScriptRoot "$Test.dpr")
    if ($LASTEXITCODE -ne 0) { throw "build failed: $Test" }
    Write-Host "=== RUN $Test ==="
    $Output = & (Join-Path $Out "$Test.exe") 2>&1
    $Output | Out-Host
    Write-Host "exit=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { $FailedRuns++ }
    <#
      The number of checks comes from the run rather than being typed by hand.

      By hand it rotted: the documentation promised 26 checks of the machine-code
      contract while the run was already giving 80. Nobody saw it for years,
      because there was nothing to compare the number against. Now the run leaves
      it here, and a release check compares every claim marked that way against
      this file.
    #>
    $Line = $Output | Where-Object { $_ -match '^TOTAL:\s*(\d+)' } | Select-Object -Last 1
    if ($Line -and $Line -match '^TOTAL:\s*(\d+)') { $Counts[$Test] = [int]$Matches[1] }
}

$CountsFile = Join-Path $PSScriptRoot 'counts.tsv'
$Tab = [char]9
$Lines = @('# How many checks the run gave. Written by build.ps1, not edited by hand.')
$Lines += ('# program' + $Tab + 'checks')
foreach ($k in ($Counts.Keys | Sort-Object)) { $Lines += ($k + $Tab + $Counts[$k]) }
Set-Content -Path $CountsFile -Value $Lines -Encoding UTF8
Write-Host "=== COUNTS -> $CountsFile ($($Counts.Count) programs) ==="

Write-Host "=== DONE: failed runs: $FailedRuns ==="
exit $FailedRuns
