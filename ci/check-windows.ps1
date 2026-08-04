<#
  The build matrix of this repository, Windows side.

  What is checked:

    lint          conditional code: brackets in directives, word size not by OS
    Delphi        win32 and win64: the parser, the accelerator, the tests
    packages      the three Delphi packages from the command line
    samples       the documentation programs: build, run, compare the output
    FPC/Windows   the parser and the accelerator, with and without the LCL
    unit by unit  every module on its own, with both compilers

  The Linux side lives next to it: ci/check-linux.sh.

  Environment (all optional):
    BDS_BIN      the Delphi bin folder, if BDS is not set
    FPC_EXE      the FPC compiler
    LAZARUS_DIR  the Lazarus folder, needed by the tests that use Forms

  Run: pwsh -File ci\check-windows.ps1
  The exit code is the number of failed steps.
#>

[CmdletBinding()]
param(
    # Skip the unit-by-unit build: it is the longest step, and the most valuable.
    [switch]$SkipUnits
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path $PSScriptRoot -Parent
$Failed = 0
$Report = @()

function Step([string]$Name, [scriptblock]$Action) {
    Write-Host ''
    Write-Host "--- $Name" -ForegroundColor Cyan
    $Started = Get-Date
    $Code = 0
    try {
        & $Action
        $Code = $LASTEXITCODE
        if ($null -eq $Code) { $Code = 0 }
    }
    catch {
        Write-Host "    crashed: $($_.Exception.Message)" -ForegroundColor Red
        $Code = 1
    }
    $Spent = [math]::Round(((Get-Date) - $Started).TotalSeconds)
    if ($Code -ne 0) { $script:Failed++ }
    $script:Report += [PSCustomObject]@{
        Step = $Name
        Result = if ($Code -eq 0) { 'ok' } else { "FAILED ($Code)" }
        Seconds = $Spent
    }
}

Write-Host '=== Build matrix: Windows ===' -ForegroundColor White

Step 'lint: conditional code' {
    & (Join-Path $PSScriptRoot 'lint-sources.ps1') | Out-Host
}

Step 'Delphi: parser and accelerator (win32 + win64)' {
    & (Join-Path $Root 'tests\build.ps1') 2>&1 |
        Select-String -Pattern 'TOTAL|=== DONE|Error:|Fatal:|^FAIL ' | Out-Host
}

Step 'Delphi packages: runtime and palette' {
    & (Join-Path $Root 'packages\delphi\build.ps1') 2>&1 |
        Select-String -Pattern 'lines,|NOT BUILT|not built' | Out-Host
}

Step 'documentation samples: build and run' {
    & (Join-Path $Root 'samples\docs\build.ps1') 2>&1 |
        Select-String -Pattern 'ok ->|EXPECTED|BUILD FAILED|failures' | Out-Host
}

Step 'FPC/Windows: parser and accelerator' {
    & (Join-Path $Root 'tests\build_fpc.ps1') 2>&1 |
        Select-String -Pattern 'TOTAL|DONE|Error:|Fatal:|^FAIL' | Out-Host
}

if (-not $SkipUnits) {
    Step 'unit by unit, Delphi' {
        & (Join-Path $Root 'tests\compile_all.ps1') -Compiler delphi | Out-Host
    }
    Step 'unit by unit, FPC' {
        & (Join-Path $Root 'tests\compile_all.ps1') -Compiler fpc | Out-Host
    }
}

Write-Host ''
Write-Host '=== Summary ===' -ForegroundColor White
$Report | Format-Table -AutoSize | Out-Host
if ($Failed -eq 0) {
    Write-Host 'MATRIX IS GREEN' -ForegroundColor Green
} else {
    Write-Host "STEPS FAILED: $Failed" -ForegroundColor Red
}
exit $Failed
