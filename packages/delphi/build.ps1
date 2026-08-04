<#
  Building the Delphi packages.

  Three packages: two runtime ones (the core and the accelerator) and one
  design-time package that puts the components on the palette. They are built
  from the command line so that the build matrix catches a drift in composition:
  if a module appears in or disappears from MANIFEST.md and the .dpk has not
  been regenerated, the build fails here.

  The design-time package exists for 32 bits only: the Delphi IDE is 32-bit and
  needs a matching .bpl.

  Run: pwsh -File build.ps1
  The exit code is the number of packages that failed to build.
#>

$ErrorActionPreference = 'Continue'

# The Delphi bin folder. BDS_BIN wins; otherwise BDS, which the IDE itself
# sets; the last guess is the standard install location.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

$Here = $PSScriptRoot

# Where the library lives. In the monorepo that is 0-foundation\pascal and
# pascal-jit; in the published repository it is src and jit at the root.
# PARSER_SRC and PARSER_JIT override both guesses.
$MonoSrc = Join-Path $Here '..\pascal'
$MonoJit = Join-Path $Here '..\pascal-jit'
$Src = if ($env:PARSER_SRC) { $env:PARSER_SRC }
       elseif (Test-Path $MonoSrc) { (Resolve-Path $MonoSrc).Path }
       else { (Resolve-Path (Join-Path $Here '..\..\src')).Path }
$Jit = if ($env:PARSER_JIT) { $env:PARSER_JIT }
       elseif (Test-Path $MonoJit) { (Resolve-Path $MonoJit).Path }
       else { (Resolve-Path (Join-Path $Here '..\..\jit')).Path }

$Failed = 0

foreach ($Target in @('win32', 'win64')) {
    $Dcc = if ($Target -eq 'win32') { Join-Path $Bin 'dcc32.exe' } else { Join-Path $Bin 'dcc64.exe' }
    $Rtl = Join-Path (Split-Path $Bin) "lib\$Target\release"
    $Out = Join-Path $Here "out\$Target"
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
        if ($LASTEXITCODE -ne 0) { Write-Host "    NOT BUILT" -ForegroundColor Red; $Failed++ }
    }
}

Write-Host ''
Write-Host "=== Delphi packages: not built $Failed ==="
exit $Failed
