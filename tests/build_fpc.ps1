# Building and running the tests under FPC/Lazarus (x86_64-win64).
# The paths to FPC and LCL can be overridden by the environment variables FPC_EXE
# and LAZARUS_DIR.
$ErrorActionPreference = 'Continue'

$Fpc = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }
# Our own Lazarus against the target FPC 3.2.2. The default C:\lazarus pointed at
# nothing, while the working installation of the user is built from trunk: its .ppu
# files in the PPU208 format are incompatible with our PPU207, and FPC calls that
# not "a foreign version" but "unit not found". Because of that two tests with Forms
# did not build at all.
$LazDir = if ($env:LAZARUS_DIR) { $env:LAZARUS_DIR } else { 'C:\laz36' }
# The word size is taken from the compiler rather than hardcoded: x86_64-win64 used
# to stand here, and on 32 bits the paths led into nothing.
$TargetCpu = (& $Fpc -iTP 2>$null | Select-Object -First 1)
$TargetOs = (& $Fpc -iTO 2>$null | Select-Object -First 1)
if ($TargetCpu) { $TargetCpu = $TargetCpu.ToString().Trim() } else { $TargetCpu = 'x86_64' }
if ($TargetOs) { $TargetOs = $TargetOs.ToString().Trim() } else { $TargetOs = 'win64' }
$Target = "$TargetCpu-$TargetOs"
$Lcl = Join-Path $LazDir "lcl\units\$Target"
$LazUtils = Join-Path $LazDir "components\lazutils\lib\$Target"

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

# Two directories rather than one: configurations with LCL and without it give
# incompatible ppu files, and a shared directory made the second mode trip over the
# leftovers of the first.

# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
$RunRootRule = Join-Path $PSScriptRoot 'runroot.ps1'
if (-not (Test-Path -LiteralPath $RunRootRule -PathType Leaf)) {
    Write-Host "REFUSED: run root rule not found: $RunRootRule"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $PSScriptRoot '..\..')
if ($null -eq $RunRoot) { exit 1 }
$Out = Join-Path $RunRoot 'fpc'
$OutConsole = Join-Path $RunRoot 'fpc-console'
New-Item -ItemType Directory -Force $Out | Out-Null
New-Item -ItemType Directory -Force $OutConsole | Out-Null
Set-Location $PSScriptRoot

# Test-Path looks for a FILE rather than a command: given a bare "fpc.exe" it looks
# in the current directory and answers "no" even when the compiler is perfectly
# visible in PATH. Both are asked for: the name of the command and an explicit path.
if (-not (Get-Command $Fpc -ErrorAction SilentlyContinue) -and -not (Test-Path $Fpc)) {
    Write-Host "FPC not found: $Fpc"
    exit 1
}

# The target version of the compiler. The OPM directory builds on 3.2.2, and the
# rejected acceptance of 08.08.2026 came from exactly there: the script called
# fpc.exe from PATH, and trunk was installed there. The build was green on our side
# and red for the other person. The version is checked before the first call to the
# compiler; it is overridden by an environment variable deliberately.
$Want = if ($env:FPC_VERSION_WANT) { $env:FPC_VERSION_WANT } else { '3.2.2' }
$Have = (& $Fpc -iV 2>$null | Select-Object -First 1).ToString().Trim()
if ($Have -ne $Want) {
    Write-Host "FPC version mismatch: $Fpc reports $Have, target is $Want"
    Write-Host "Set FPC_EXE to the target compiler, or FPC_VERSION_WANT to override."
    exit 1
}

$Targets = if ($args.Count -gt 0) { $args } else { @('ParserBugTests', 'JitParserTest', 'JitContractTest', 'PublicApiTest', 'DocumentedSyntaxTest', 'JitRedirectTest', 'ThreadWaitTest', 'ThreadSafetyTest', 'ThreadShareTest', 'ExitRoutingTest', 'LoopGuardTest', 'LoopScopeTest', 'FpuMaskTest', 'MethodLockTest', 'MathFamilyTest', 'C31Console') }
$Failed = 0
$Skipped = 0

# Two ways of building, as on the Linux side.
#
# ParserBugTests and ThreadWaitTest pull in Forms: they need the whole of LCL. The
# other tests are console ones and do not need LCL, they are built with src\compat,
# where the replacement for Messages lies, and with the NOFORMS and NOGRAPHICS
# switches, otherwise BlobManager would demand Graphics and SyncThread a widgetset.
# Neither LCL nor LazUtils is pulled into this branch at all: RTL is enough for the
# library, and here that is checked by a run rather than assumed.
$NeedsLcl = @('ParserBugTests', 'ThreadWaitTest')

Write-Host "FPC $Have, target $Target"

foreach ($Test in $Targets) {
    # Two tests pull in Forms THEMSELVES, the library does not. Until LCL is built for
    # this target there is nothing to build them with, and the skip is declared out
    # loud: a silent one reads as "checked".
    if (($NeedsLcl -contains $Test) -and -not (Test-Path (Join-Path $Lcl 'forms.ppu'))) {
        Write-Host "=== FPC SKIP ${Test}: no LCL built for $Target in $LazDir ==="
        $Skipped++
        continue
    }
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

# A skip has to reach the CALLER rather than stay a line in the log.
#
# Earlier a skipped test was printed and lost: the script left with a zero, the
# matrix above saw the zero and wrote "ok". So two tests could fail to start at all
# while the run was called green. The rule is one for every level: a run with skips
# is never green, it is incomplete, and the return code has to say so.
Write-Host "=== FPC DONE: failures $Failed, skipped $Skipped ==="
exit ($Failed + $Skipped)
