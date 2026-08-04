# Tries to compile every module of the library on its own.
# The test bench does not pull in all of them, and modules outside its
# dependencies would otherwise never be compiled: that is how a stray bracket
# in a VersionUtils directive hid for years on FPC/Linux.
#
# Modules that do not build everywhere are listed in src\PLATFORMS.tsv and are
# not counted as breakage. Everything else has to build.
param([ValidateSet('delphi', 'fpc')][string]$Compiler = 'delphi')

$ErrorActionPreference = 'Continue'

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

$Out = Join-Path $PSScriptRoot "out\allunits-$Compiler"
New-Item -ItemType Directory -Force $Out | Out-Null

# who is excused from building here
$Skip = @{}
foreach ($Line in (Get-Content (Join-Path $Src 'PLATFORMS.tsv'))) {
    if ($Line -match '^\s*#' -or $Line.Trim() -eq '') { continue }
    $Part = $Line -split "`t"
    $Where = $Part[1].Trim()
    $Excused = switch ($Where) {
        'never'   { $true }
        'windows' { $false }              # a Windows module: on Windows it has to build
        'delphi'  { $Compiler -eq 'fpc' }
        'fpc'     { $Compiler -eq 'delphi' }
        default   { $false }
    }
    if ($Excused) { $Skip[$Part[0].Trim()] = $Part[2].Trim() }
}

$Ok = 0
$Bad = @()
$Excused = @()
foreach ($File in (Get-ChildItem $Src -Filter '*.pas' | Sort-Object Name)) {
    if ($Skip.ContainsKey($File.BaseName)) {
        $Excused += "$($File.BaseName) - $($Skip[$File.BaseName])"
        continue
    }
    if ($Compiler -eq 'delphi') {
        # The Delphi folder: BDS_BIN, else BDS from the IDE, else the standard place.
        $BdsBin = if ($env:BDS_BIN) { $env:BDS_BIN }
                  elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
                  else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }
        $Bin = Join-Path $BdsBin 'dcc64.exe'
        $Rtl = Join-Path (Split-Path $BdsBin) 'lib\win64\release'
        $Err = & $Bin -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) ('-I' + $Src) `
            ('-N0' + $Out) '-NSSystem;System.Win;WinApi;Vcl' $File.FullName 2>&1 |
            Select-String -Pattern 'Error:|Fatal:' | Select-Object -First 3
    }
    else {
        $Bin = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }
        $LazDir = if ($env:LAZARUS_DIR) { $env:LAZARUS_DIR } else { 'C:\lazarus' }
        $Lcl = Join-Path $LazDir 'lcl\units\x86_64-win64'
        $LazUtils = Join-Path $LazDir 'components\lazutils\lib\x86_64-win64'
        $Err = & $Bin -MDelphi -Sh -B ("-Fu$Src") ("-Fu$Jit") ("-Fu$Lcl") ("-Fu$Lcl\win32") `
            ("-Fu$LazUtils") ("-Fi$Src") ("-FU$Out") $File.FullName 2>&1 |
            Select-String -Pattern 'Error:|Fatal:' | Select-Object -First 3
    }
    if ($Err) { $Bad += [PSCustomObject]@{ Unit = $File.BaseName; Error = ($Err -join '; ') } }
    else { $Ok++ }
}

Write-Host "BUILT: $Ok   NOT BUILT: $($Bad.Count)   not required: $($Excused.Count)"
foreach ($E in $Excused) { Write-Host "    (skipped) $E" }
foreach ($B in $Bad) { Write-Host "--- $($B.Unit)"; Write-Host "    $($B.Error)" }
exit $Bad.Count
