<#
  The build matrix of the published repository, the Windows side.

  A separate file rather than a copy of the monorepo matrix: that one also runs the
  graph engine, the plugin and the parity of the panels, none of which is in this
  repository. The steps below are exactly what lies here and has to build.

  What is checked:

    lint          conditional code: brackets in directives, word size not through the OS
    Delphi        win32 and win64: the parser, the accelerator, tests
    packages      three Delphi packages from the command line
    samples       the documentation programs: build, run, compare the output
    FPC/Windows   the parser and the accelerator, with LCL and without it
    one by one    every unit on its own, with both compilers

  The Linux side lives next door: ci/check-linux.sh.

  The environment (all of it optional):
    BDS_BIN      the bin directory of Delphi, if BDS is not set
    FPC_EXE      the FPC compiler
    LAZARUS_DIR  the Lazarus directory, needed by tests that pull in Forms

  To run: pwsh -File ci\check-windows.ps1
  The return code is the number of failed steps PLUS skipped ones. A skip is
  included deliberately: a run with skips is never green, it is incomplete, and the
  return code must not stay silent about that.
#>

[CmdletBinding()]
param(
    # Skip the unit-by-unit build: it is the longest and also the most valuable. A run
    # with this switch DECLARES itself incomplete and is never green.
    [switch]$SkipUnits
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path $PSScriptRoot -Parent
$Failed = 0
$Skipped = 0
$Report = @()

# A skip is DECLARED AS A STEP rather than printed to the log.
#
# Printing is not enough. A step that left through an ordinary return takes
# $LASTEXITCODE from the PREVIOUS command, and that is a zero from the last green
# step. Checked by a run on 10.08.2026: with a 32-bit compiler deliberately absent
# the step reported ok in zero seconds, the summary said THE MATRIX IS GREEN, return
# code 0. So a whole declared platform could disappear from the check without a
# single red word.
#
# The rule of the project: a run with skips is never green, it is INCOMPLETE.
function Skip([string]$Why) {
    Write-Host "    SKIPPED: $Why" -ForegroundColor Yellow
    $script:SkipThis = $true
}

# A refusal FROM THE STEP ITSELF, not through a return code.
#
# return 1 from the body of a step does not set $LASTEXITCODE: Step would see a zero
# from the previous command and record "ok". Exactly the trap that once made a skip
# green.
#
# The reason for the refusal IS NAMED rather than implied. The first version wrote
# "FAILED (setup)" into the summary for any refusal from a step, and a failure of
# the tests themselves, coming from parsing the summary line of the child, would
# have been declared a wrong setup. Whoever read the table would go and fix the
# environment instead of the library.
function Fail([string]$Why, [string]$What = 'setup') {
    Write-Host "    ERROR: $Why" -ForegroundColor Red
    $script:FailThis = $true
    $script:FailWhat = $What
}

# The outcome of the CHILD script is parsed from its summary line, not from its code.
#
# By the common rule of the project the child build_fpc.ps1 leaves with the sum of
# failures AND skips, one number that cannot tell one from the other. Without
# parsing, a step with two tests skipped for want of LCL would get FAILED (2) and a
# summary "STEPS FAILED: 1", so the top would be shouting about breakage where the
# matrix is in fact INCOMPLETE. The contract about three outcomes has to survive as
# far as the summary rather than be lost at the boundary between processes.
#
# A missing summary line is a failure too: it means the child did not reach the end.
function ReadChild([object[]]$Out) {
    $Line = $Out | Select-String -Pattern 'DONE: failures (\d+), skipped (\d+)' |
        Select-Object -Last 1
    if (-not $Line) {
        Fail 'the child script never reached the final DONE line, the outcome of the run is unknown (the reason is in the output above)'
        return
    }
    $F = [int]$Line.Matches[0].Groups[1].Value
    $S = [int]$Line.Matches[0].Groups[2].Value
    if ($F -gt 0) { Fail "test programs failed: $F" 'tests' }
    elseif ($S -gt 0) { Skip "test programs skipped: $S, see the SKIP lines above" }
}

function Step([string]$Name, [scriptblock]$Action) {
    Write-Host ''
    Write-Host "--- $Name" -ForegroundColor Cyan
    $Started = Get-Date
    $Code = 0
    $script:SkipThis = $false
    $script:FailThis = $false
    $script:FailWhat = 'setup'
    try {
        & $Action
        $Code = $LASTEXITCODE
        if ($null -eq $Code) { $Code = 0 }
    }
    catch {
        Write-Host "    broke down: $($_.Exception.Message)" -ForegroundColor Red
        $Code = 1
    }
    $Spent = [math]::Round(((Get-Date) - $Started).TotalSeconds)
    if ($script:FailThis) {
        $script:Failed++
        $Verdict = "FAILED ($script:FailWhat)"
    }
    elseif ($script:SkipThis) {
        $script:Skipped++
        $Verdict = 'SKIPPED'
    }
    elseif ($Code -ne 0) {
        $script:Failed++
        $Verdict = "FAILED ($Code)"
    }
    else {
        $Verdict = 'ok'
    }
    $script:Report += [PSCustomObject]@{
        Step = $Name
        Result = $Verdict
        Seconds = $Spent
    }
}

Write-Host '=== Build matrix: Windows ===' -ForegroundColor White

Step 'conditional-code lint' {
    & (Join-Path $PSScriptRoot 'lint-sources.ps1') | Out-Host
}

Step 'Delphi: parser and accelerator (win32 + win64)' {
    & (Join-Path $Root 'tests\build.ps1') 2>&1 |
        Select-String -Pattern 'TOTAL|=== DONE|Error:|Fatal:|^FAIL ' | Out-Host
}

Step 'Delphi packages: runtime and the palette' {
    & (Join-Path $Root 'packages\delphi\build.ps1') 2>&1 |
        Select-String -Pattern 'lines,|DID NOT BUILD|not built' | Out-Host
}

Step 'documentation samples: build and run' {
    & (Join-Path $Root 'samples\docs\build.ps1') 2>&1 |
        Select-String -Pattern 'ok ->|EXPECTED|BUILD FAILED|failures' | Out-Host
}

Step 'FPC/Windows x64: parser and accelerator' {
    # The word size is asked for here as well, otherwise the check would be one-sided.
    # The child script builds for whatever target the compiler it is given names: put a
    # 32-bit one in FPC_EXE and the step named x64 will run i386, get ok, and nobody
    # will check 64 bits.
    $Fpc = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }

    # Presence is asked for BEFORE the word size and by the same two ways as on the x32
    # step. Without that a missing compiler gave not a skip but a broken step with the
    # message "broke off: the name is not recognised as the name of a cmdlet", red
    # instead of yellow and about something else entirely. A missing toolchain and a
    # wrong toolchain are different things, and the contract tells them apart in the
    # same way on both steps.
    if (-not (Get-Command $Fpc -ErrorAction SilentlyContinue) -and -not (Test-Path $Fpc)) {
        Skip "no FPC at $Fpc; set FPC_EXE, otherwise 64 bits are checked by nothing"
        return
    }

    $Cpu = (& $Fpc -iTP 2>$null | Select-Object -First 1)
    if ($Cpu) { $Cpu = $Cpu.ToString().Trim() }
    if ($Cpu -ne 'x86_64') {
        Fail "FPC_EXE points at a compiler whose target is '$Cpu', and x86_64 is what is needed; the step named x64 running a different word size would give a green matrix without a single 64-bit build"
        return
    }

    # SKIP in the pattern is required: without it a test skipped inside the child script
    # did not reach the eye at all.
    #
    # The WHOLE output is caught, not success with failures alone: the child script
    # speaks through Write-Host, and when it is called in the same process that goes
    # into the information stream and is not taken by a "2>&1" capture, the lines go
    # straight to the console past the variable. Checked by a run on 10.08.2026: the
    # child printed "DONE: failures 0, skipped 0", the parsing did not see it and
    # declared the outcome unknown. Tee-Object keeps the output alive and at the same
    # time puts all of it into a variable.
    & (Join-Path $Root 'tests\build_fpc.ps1') *>&1 |
        Tee-Object -Variable Out |
        Select-String -Pattern 'target |TOTAL|DONE|SKIP|Error:|Fatal:|FAIL|not found|exit=[1-9]' | Out-Host
    ReadChild $Out
}

# 32 bits is a separate NATIVE installation of FPC rather than a switch to the
# 64-bit one: the compiler forbids cross-building to i386 from a host where Extended
# equals Double, and on Win64 it does. The skip is declared out loud: a silent one
# reads as "checked".
Step 'FPC/Windows x32: parser and accelerator' {
    $W32 = if ($env:FPC_EXE_W32) { $env:FPC_EXE_W32 } else { 'C:\fpc322w32\bin\i386-win32\fpc.exe' }

    # Presence is checked AS A COMMAND, not only as a file: FPC_EXE_W32 may be simply
    # 'fpc.exe' with the compiler in PATH, and Test-Path will not find such a one. The
    # same defect has already been fixed once for the ordinary FPC_EXE.
    if (-not (Get-Command $W32 -ErrorAction SilentlyContinue) -and -not (Test-Path $W32)) {
        Skip "no 32-bit FPC at $W32; set FPC_EXE_W32, otherwise 32 bits are checked by nothing"
        return
    }

    # AND THE WORD SIZE IS ASKED OF THE COMPILER ITSELF.
    #
    # The existence of a file says nothing about the target. The child build_fpc.ps1
    # finds the target through -iTP/-iTO, that is it will obediently build with whatever
    # it is given: put a 64-bit compiler in FPC_EXE_W32 and the step named x32 will run
    # x64 a second time, both steps will go green, and i386 will not start at all.
    # That is not a skip but a wrong setup, and it has to be RED.
    $W32Cpu = (& $W32 -iTP 2>$null | Select-Object -First 1)
    if ($W32Cpu) { $W32Cpu = $W32Cpu.ToString().Trim() }
    if ($W32Cpu -ne 'i386') {
        Fail "FPC_EXE_W32 points at a compiler whose target is '$W32Cpu', and i386 is what is needed; the step named x32 running x64 would give a green matrix without a single 32-bit build"
        return
    }

    $Keep = $env:FPC_EXE
    $env:FPC_EXE = $W32
    try {
        & (Join-Path $Root 'tests\build_fpc.ps1') *>&1 |
            Tee-Object -Variable Out |
            Select-String -Pattern 'target |TOTAL|DONE|SKIP|Error:|Fatal:|FAIL|not found|exit=[1-9]' | Out-Host
        ReadChild $Out
    }
    finally { $env:FPC_EXE = $Keep }
}

# The -SkipUnits switch DECLARES a skip rather than turning steps off in silence.
#
# The first version simply did not create those two steps: they were neither in the
# report nor in the counter, and a run with them calmly said THE MATRIX IS GREEN
# with code 0. So the rule "a run with skips is never green" was gone around by the
# only regular skip the script has at all, and by the very one that is described
# right there as the most valuable.
#
# A deliberate skip differs from an accidental one only in having been asked for.
# The run stays incomplete in both cases.
if ($SkipUnits) {
    Step 'one by one: every unit, Delphi' {
        Skip 'requested by -SkipUnits; the one-by-one build did not run'
    }
    Step 'one by one: every unit, FPC' {
        Skip 'requested by -SkipUnits; the one-by-one build did not run'
    }
}
else {
    Step 'one by one: every unit, Delphi' {
        & (Join-Path $Root 'tests\compile_all.ps1') -Compiler delphi | Out-Host
    }
    Step 'one by one: every unit, FPC' {
        & (Join-Path $Root 'tests\compile_all.ps1') -Compiler fpc | Out-Host
    }
}

Write-Host ''
Write-Host '=== Result ===' -ForegroundColor White
$Report | Format-Table -AutoSize | Out-Host
if ($Failed -gt 0) {
    Write-Host "STEPS FAILED: $Failed" -ForegroundColor Red
}
elseif ($Skipped -gt 0) {
    # An incomplete run is never green. A skipped step is a platform nobody checked, and
    # the return code must not stay silent about that.
    Write-Host "THE MATRIX IS INCOMPLETE: steps skipped $Skipped" -ForegroundColor Yellow
}
else {
    Write-Host 'THE MATRIX IS GREEN' -ForegroundColor Green
}
exit ($Failed + $Skipped)
