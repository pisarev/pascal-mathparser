<#
  Build and run the samples used by the documentation.

  Why: the samples on the site and in the README used to be text and nothing
  else, and for years they contained variables that came from nowhere. The
  compiler never saw them because nobody compiled them. Now every sample is a
  real program with its expected output on the first line ({ expect: ... }), and
  the page generator inserts that very file.

  The rule: a sample that does not build, or does not print the expected line,
  does not reach the page.

  Run: pwsh -File build.ps1
  The exit code is the number of failed samples.
#>

$ErrorActionPreference = 'Stop'

# The Delphi bin folder. BDS_BIN wins; otherwise BDS, which the IDE itself
# sets; the last guess is the standard install location.
$Bin = if ($env:BDS_BIN) { $env:BDS_BIN }
       elseif ($env:BDS) { Join-Path $env:BDS 'bin' }
       else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }

$Here = $PSScriptRoot

# Where the library lives. In the monorepo that is 0-foundation\pascal and
# pascal-jit; in the published repository it is src and jit at the root.
# PARSER_SRC and PARSER_JIT override both guesses.
$MonoSrc = Join-Path $Here '..\..\pascal'
$MonoJit = Join-Path $Here '..\..\pascal-jit'
$Src = if ($env:PARSER_SRC) { $env:PARSER_SRC }
       elseif (Test-Path $MonoSrc) { (Resolve-Path $MonoSrc).Path }
       else { (Resolve-Path (Join-Path $Here '..\..\src')).Path }
$Jit = if ($env:PARSER_JIT) { $env:PARSER_JIT }
       elseif (Test-Path $MonoJit) { (Resolve-Path $MonoJit).Path }
       else { (Resolve-Path (Join-Path $Here '..\..\jit')).Path }

$Rtl = Join-Path (Split-Path $Bin) 'lib\win64\release'
$Out = Join-Path $Here 'out'
New-Item -ItemType Directory -Force (Join-Path $Out 'dcu') | Out-Null

$Failed = 0

foreach ($File in Get-ChildItem (Join-Path $Here '*.dpr') | Sort-Object Name) {
    $Name = $File.BaseName
    $Text = Get-Content $File.FullName -Raw
    $Expect = ''
    if ($Text -match '\{\s*expect:\s*(.*?)\s*\}') { $Expect = $Matches[1] }

    Write-Host "--- $Name (expecting: $Expect)"
    & (Join-Path $Bin 'dcc64.exe') -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) `
        ('-I' + $Src) ('-E' + $Out) ('-N0' + (Join-Path $Out 'dcu')) `
        '-NSSystem;System.Win;WinApi;Vcl' $File.FullName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  BUILD FAILED" -ForegroundColor Red
        $Failed++
        continue
    }

    $Exe = Join-Path $Out "$Name.exe"
    $Lines = & $Exe 2>&1 | Where-Object { $_ -ne '' }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  RUN FAILED: code $LASTEXITCODE" -ForegroundColor Red
        $Failed++
        continue
    }

    if ($Expect -eq 'nothing printed') {
        if ($Lines) {
            Write-Host "  EXPECTED SILENCE, got: $($Lines -join ' ')" -ForegroundColor Red
            $Failed++
        } else {
            Write-Host "  ok"
        }
        continue
    }

    $Last = if ($Lines) { ($Lines | Select-Object -Last 1).Trim() } else { '' }
    if ($Last -like "*$Expect*") {
        Write-Host "  ok -> $Last"
    } else {
        Write-Host "  EXPECTED '$Expect', got '$Last'" -ForegroundColor Red
        $Failed++
    }
}

# The listings in the published README have to be excerpts from these same
# files. Otherwise the README starts living a life of its own, as it once did.
function Normalize([string]$Text) {
    $Text = $Text -replace "`r`n", "`n"
    $Lines = $Text -split "`n" |
        Where-Object { $_ -notmatch '\{\s*(expect:|needs:|show\b)' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' }
    return ($Lines -join "`n")
}

# The README original lives in publish\; in the published repository it is at
# the root.
$MonoReadme = Join-Path $Here '..\..\..\publish\pascal-mathparser\README.md'
$Readme = if (Test-Path $MonoReadme) { $MonoReadme } else { Join-Path $Here '..\..\README.md' }
if (Test-Path $Readme) {
    Write-Host ''
    Write-Host '--- README listings against the sample files'
    $All = (Get-ChildItem (Join-Path $Here '*.dpr') | ForEach-Object {
        Normalize (Get-Content $_.FullName -Raw) }) -join "`n"
    $Text = Get-Content $Readme -Raw
    $Blocks = [regex]::Matches($Text, '(?s)```pascal\r?\n(.*?)```')
    $Bad = 0
    foreach ($B in $Blocks) {
        $Snippet = Normalize $B.Groups[1].Value
        if ($All.Contains($Snippet)) {
            Write-Host ("  ok    " + ($Snippet -split "`n")[0])
        } else {
            Write-Host ("  NOT FROM A SAMPLE: " + ($Snippet -split "`n")[0]) -ForegroundColor Red
            $Bad++
        }
    }
    Write-Host ("  blocks: " + $Blocks.Count + ", foreign: $Bad")
    $Failed += $Bad
}

Write-Host ''
Write-Host "=== documentation samples: failures $Failed ==="
exit $Failed
