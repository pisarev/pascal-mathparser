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
        & (Join-Path $PSScriptRoot "out\$Target\$Test.exe")
        Write-Host "exit=$LASTEXITCODE"
        if ($LASTEXITCODE -ne 0) { $FailedRuns++ }
    }
}

# The rest of the JIT layer: x64 only, since that is where the emitter works.
# ThreadWaitTest is not about the JIT but takes the same build path, and word
# size does not affect its contract.
$Out = Join-Path $PSScriptRoot 'out\win64'
$Rtl = Join-Path (Split-Path $Bin) 'lib\win64\release'
foreach ($Test in @('JitDump', 'JitBench', 'JitParserTest', 'JitContractTest', 'PublicApiTest', 'DocumentedSyntaxTest', 'DemoSpeed', 'BigScript', 'ThreadWaitTest', 'C31Console')) {
    Write-Host "=== BUILD $Test (win64) ==="
    & (Join-Path $Bin 'dcc64.exe') -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) ('-I' + $Src) ('-E' + $Out) ('-N0' + (Join-Path $Out 'dcu')) '-NSSystem;System.Win;WinApi;Vcl' (Join-Path $PSScriptRoot "$Test.dpr")
    if ($LASTEXITCODE -ne 0) { throw "build failed: $Test" }
    Write-Host "=== RUN $Test ==="
    & (Join-Path $Out "$Test.exe")
    Write-Host "exit=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { $FailedRuns++ }
}

Write-Host "=== DONE: failed runs: $FailedRuns ==="
exit $FailedRuns
