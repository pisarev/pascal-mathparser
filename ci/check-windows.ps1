<#
  The build matrix of the published repository, the Windows side.

  A separate file rather than a copy of the monorepo matrix: that one also runs
  the graph engine, the plugin and the panel parity, none of which live in this
  repository. The steps below are exactly what is here and has to build.

  What is checked:

    lint          conditional code: brackets in directives, bitness not by OS
    Delphi        win32 and win64: the parser, the accelerator, the tests
    packages      three Delphi packages from the command line
    samples       the documentation programs: build, run, compare the output
    FPC/Windows   the parser and the accelerator, with the LCL and without it
    one by one    every unit on its own, with both compilers

  The Linux side lives next door: ci/check-linux.sh.

  Environment (all optional):
    BDS_BIN      the bin directory of Delphi, if BDS is not set
    FPC_EXE      the FPC compiler
    LAZARUS_DIR  the Lazarus directory, needed by the tests that use Forms

  Run: pwsh -File ci\check-windows.ps1
  The exit code is the number of failed PLUS skipped steps. A skip is counted in
  deliberately: a run with skips is never green, it is incomplete, and the exit
  code must not keep quiet about it.
#>

[CmdletBinding()]
param(
    # Skip the unit-by-unit build: it is the longest one, and also the most
    # valuable. A run with this switch DECLARES itself incomplete and is never
    # green.
    [switch]$SkipUnits
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path $PSScriptRoot -Parent
$Failed = 0
$Skipped = 0
$Report = @()

# A skip is DECLARED AS A STEP rather than printed into the log.
#
# Printing is not enough. A step that returned normally picks up $LASTEXITCODE
# of the PREVIOUS command - and that is a zero from the last green step. Measured
# on 10.08.2026: with a deliberately missing 32-bit compiler the step reported ok
# in zero seconds, the summary said THE MATRIX IS GREEN, exit code 0. That is, a
# whole declared platform could vanish from the check without a single red word.
#
# The rule of the project: a run with skips is never green, it is INCOMPLETE.
function Skip([string]$Why) {
    Write-Host "    SKIPPED: $Why" -ForegroundColor Yellow
    $script:SkipThis = $true
}

# A refusal FROM THE STEP ITSELF, not through an exit code.
#
# `return 1` out of a step block does not set $LASTEXITCODE - Step would see the
# zero of the previous command and write "ok". Exactly the trap that once made a
# skip green.
#
# The reason for the refusal is NAMED rather than implied. The first edition
# wrote "FAILED (setup)" into the summary for any refusal from a step - and a
# failure of the tests themselves, coming from the parsing of the child summary
# line, would have been declared a wrong setup. Whoever read the table would go
# and fix the environment instead of the library.
function Fail([string]$Why, [string]$What = 'setup') {
    Write-Host "    ERROR: $Why" -ForegroundColor Red
    $script:FailThis = $true
    $script:FailWhat = $What
}

# The outcome of the CHILD script is read from its summary line, not from its
# exit code.
#
# By the common rule of the project the child build_fpc.ps1 exits with the sum of
# failures AND skips - a single number that cannot tell one from the other.
# Without parsing, a step with two tests skipped for a missing LCL would get
# FAILED (2) and the summary "STEPS FAILED: 1", that is, the top level would
# shout about a breakage where the matrix is in fact INCOMPLETE. A contract about
# three outcomes has to survive as far as the summary, not get lost at a process
# boundary.
#
# A missing summary line is a refusal too: it means the child did not reach its
# end.
function ReadChild([object[]]$Out) {
    $Line = $Out | Select-String -Pattern 'DONE: failures (\d+), skipped (\d+)' |
        Select-Object -Last 1
    if (-not $Line) {
        Fail 'the child script did not reach its DONE summary line, the outcome of the run is unknown (the reason is in the output above)'
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
        Verdict = $Verdict
        Seconds = $Spent
    }
}

Write-Host '=== Build matrix: Windows ===' -ForegroundColor White

Step 'lint of conditional code' {
    & (Join-Path $PSScriptRoot 'lint-sources.ps1') | Out-Host
}

Step 'Delphi: the parser and the accelerator (win32 + win64)' {
    & (Join-Path $Root 'tests\build.ps1') 2>&1 |
        Select-String -Pattern 'TOTAL|=== DONE|Error:|Fatal:|^FAIL ' | Out-Host
}

Step 'Delphi packages: runtime and palette' {
    & (Join-Path $Root 'packages\delphi\build.ps1') 2>&1 |
        Select-String -Pattern 'lines,|DID NOT BUILD|did not build' | Out-Host
}

Step 'documentation samples: build and run' {
    & (Join-Path $Root 'samples\docs\build.ps1') 2>&1 |
        Select-String -Pattern 'ok ->|EXPECTED|BUILD FAILED|failures' | Out-Host
}

Step 'FPC/Windows x64: the parser and the accelerator' {
    # The bitness is asked here as well - otherwise the check would be one-sided.
    # The child script builds for whatever target the compiler it is given names:
    # point FPC_EXE at a 32-bit one and the step called x64 will run i386, get an
    # ok, and nobody will have checked 64 bits.
    $Fpc = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }

    # Presence is asked BEFORE the bitness and by the same two ways as in the x32
    # step. Without it a missing compiler produced not a skip but a breakdown of
    # the step with "broke down: the name is not recognized as a cmdlet" - red
    # instead of yellow and about the wrong thing entirely. A missing toolchain
    # and a wrong toolchain are different things, and the contract tells them
    # apart the same way in both steps.
    if (-not (Get-Command $Fpc -ErrorAction SilentlyContinue) -and -not (Test-Path $Fpc)) {
        Skip "there is no FPC at $Fpc; set FPC_EXE, otherwise nothing has checked 64 bits"
        return
    }

    $Cpu = (& $Fpc -iTP 2>$null | Select-Object -First 1)
    if ($Cpu) { $Cpu = $Cpu.ToString().Trim() }
    if ($Cpu -ne 'x86_64') {
        Fail "FPC_EXE points at a compiler targeting '$Cpu', and x86_64 is needed; an x64 step running a different bitness would give a green matrix without a single 64-bit build"
        return
    }

    # SKIP in the pattern is mandatory: without it a test skipped inside the
    # child script did not reach anyone's eyes at all.
    #
    # The WHOLE output is captured, not only success with failures: the child
    # speaks through Write-Host, and that, when called in the same process, goes
    # to the information stream and is not taken by "2>&1" - the lines go
    # straight to the console past the variable. Measured on 10.08.2026: the
    # child printed "DONE: failures 0, skipped 0", the parsing did not see it and
    # declared the outcome unknown. Tee-Object keeps the output alive and at the
    # same time puts all of it into the variable.
    & (Join-Path $Root 'tests\build_fpc.ps1') *>&1 |
        Tee-Object -Variable Out |
        Select-String -Pattern 'target |TOTAL|DONE|SKIP|Error:|Fatal:|FAIL|not found|exit=[1-9]' | Out-Host
    ReadChild $Out
}

# 32 bits is a separate NATIVE installation of FPC, not a switch to the 64-bit
# one: the compiler forbids cross-building to i386 from a host where Extended
# equals Double, and on Win64 it does. The skip is announced out loud: a silent
# one reads as "checked".
Step 'FPC/Windows x32: the parser and the accelerator' {
    $W32 = if ($env:FPC_EXE_W32) { $env:FPC_EXE_W32 } else { 'C:\fpc-i386\bin\i386-win32\fpc.exe' }

    # Presence is checked AS A COMMAND, not only as a file: FPC_EXE_W32 may be
    # simply 'fpc.exe' with the compiler on the PATH, and Test-Path will not find
    # such a one. The same defect was fixed once already for the ordinary
    # FPC_EXE.
    if (-not (Get-Command $W32 -ErrorAction SilentlyContinue) -and -not (Test-Path $W32)) {
        Skip "there is no 32-bit FPC at $W32; set FPC_EXE_W32, otherwise nothing has checked 32 bits"
        return
    }

    # AND THE BITNESS IS ASKED OF THE COMPILER ITSELF.
    #
    # The existence of a file says nothing about its target. The child
    # build_fpc.ps1 determines the target through -iTP/-iTO, that is, it will
    # obediently build with whatever it is given: point FPC_EXE_W32 at a 64-bit
    # compiler and the step called x32 will run x64 a second time, both steps
    # will go green, and i386 will not run at all. That is not a skip but a wrong
    # setup, and it has to be RED.
    $W32Cpu = (& $W32 -iTP 2>$null | Select-Object -First 1)
    if ($W32Cpu) { $W32Cpu = $W32Cpu.ToString().Trim() }
    if ($W32Cpu -ne 'i386') {
        Fail "FPC_EXE_W32 points at a compiler targeting '$W32Cpu', and i386 is needed; an x32 step running x64 would give a green matrix without a single 32-bit build"
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

# The -SkipUnits switch DECLARES a skip rather than turning steps off silently.
#
# The first edition simply did not create these two steps: they were in neither
# the report nor the counter, and a run with them said THE MATRIX IS GREEN with
# code 0 quite happily. That is, the rule "a run with skips is never green" was
# bypassed by the only regular skip the script has at all - and by the very one
# about which it says, right there, that it is the most valuable.
#
# A deliberate skip differs from an accidental one only in having been asked for.
# The run stays incomplete in both cases.
if ($SkipUnits) {
    Step 'one by one: every unit, Delphi' {
        Skip 'asked for by the -SkipUnits switch; the unit-by-unit build did not run'
    }
    Step 'one by one: every unit, FPC' {
        Skip 'asked for by the -SkipUnits switch; the unit-by-unit build did not run'
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
Write-Host '=== Summary ===' -ForegroundColor White
$Report | Format-Table -AutoSize | Out-Host
if ($Failed -gt 0) {
    Write-Host "STEPS FAILED: $Failed" -ForegroundColor Red
}
elseif ($Skipped -gt 0) {
    # An incomplete run is never green. A skipped step is a platform nobody
    # checked, and the exit code must not keep quiet about it.
    Write-Host "THE MATRIX IS INCOMPLETE: steps skipped $Skipped" -ForegroundColor Yellow
}
else {
    Write-Host 'THE MATRIX IS GREEN' -ForegroundColor Green
}
exit ($Failed + $Skipped)
