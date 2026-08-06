# Build and run the tests on FPC/Lazarus (x86_64-win64).
# The paths to FPC and the LCL can be overridden with FPC_EXE and LAZARUS_DIR.
$ErrorActionPreference = 'Continue'

$Fpc = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }
$LazDir = if ($env:LAZARUS_DIR) { $env:LAZARUS_DIR } else { 'C:\lazarus' }
$Lcl = Join-Path $LazDir 'lcl\units\x86_64-win64'
$LazUtils = Join-Path $LazDir 'components\lazutils\lib\x86_64-win64'

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

# Two output folders, not one: the configurations with and without the LCL
# produce incompatible ppu files, and a shared folder left the second mode
# tripping over the leftovers of the first.
$Out = Join-Path $PSScriptRoot 'out\fpc'
$OutConsole = Join-Path $PSScriptRoot 'out\fpc-console'
New-Item -ItemType Directory -Force $Out | Out-Null
New-Item -ItemType Directory -Force $OutConsole | Out-Null
Set-Location $PSScriptRoot

if (-not (Test-Path $Fpc)) { Write-Host "FPC not found: $Fpc"; exit 1 }

$Targets = if ($args.Count -gt 0) { $args } else { @('ParserBugTests', 'JitParserTest', 'JitContractTest', 'PublicApiTest', 'DocumentedSyntaxTest', 'JitRedirectTest', 'ThreadWaitTest', 'ThreadSafetyTest', 'ThreadShareTest', 'ExitRoutingTest', 'LoopGuardTest', 'C31Console') }
$Failed = 0

# Two ways to build, the same as on the Linux side.
#
# ParserBugTests and ThreadWaitTest use Forms, so they need the whole LCL. The
# other tests are console programs and do not need it: they are built with
# src\compat, which holds the stand-in for Messages, and with NOFORMS and
# NOGRAPHICS, or BlobManager would ask for Graphics and SyncThread for a
# widgetset. Neither the LCL nor LazUtils is referenced in this branch at all:
# the RTL is enough for the library, and that is proved here by building, not
# assumed.
$NeedsLcl = @('ParserBugTests', 'ThreadWaitTest')

foreach ($Test in $Targets) {
    Write-Host "=== FPC BUILD $Test ==="
    if ($NeedsLcl -contains $Test) {
        & $Fpc -MDelphi -O2 -vw- -Sh -B ("-Fu$Src") ("-Fu$Jit") ("-Fu$Lcl") ("-Fu$Lcl\win32") `
            ("-Fu$LazUtils") ("-Fi$Src") ("-FU$Out") ("-FE$Out") "$Test.dpr" 2>&1 |
            Select-String -Pattern 'Error:|Fatal' | Select-Object -First 10
    } else {
        & $Fpc -MDelphi -O2 -vw- -Sh -B -dNOFORMS -dNOGRAPHICS ("-Fu$Src\compat") ("-Fu$Src") `
            ("-Fu$Jit") ("-Fi$Src") ("-FU$OutConsole") ("-FE$OutConsole") "$Test.dpr" 2>&1 |
            Select-String -Pattern 'Error:|Fatal' | Select-Object -First 10
    }
    if ($LASTEXITCODE -ne 0) { Write-Host "BUILD FAILED: $Test"; $Failed++; continue }
    Write-Host "=== FPC RUN $Test ==="
    $Where = if ($NeedsLcl -contains $Test) { $Out } else { $OutConsole }
    & (Join-Path $Where "$Test.exe")
    Write-Host "exit=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { $Failed++ }
}

Write-Host "=== FPC DONE: failures $Failed ==="
exit $Failed
