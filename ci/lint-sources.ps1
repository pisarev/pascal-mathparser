<#
  Linting the conditional code in the sources.

  A conditional branch that has never been compiled is worse than a missing one:
  it looks like working code, but the compiler never looks inside - to it the
  text is crossed out. That is how a stray bracket in a VersionUtils directive, a
  lost ENDIF in BlobManager and a word size chosen by the name of the operating
  system all survived for years.

  Three checks:

    1. Bracket balance in {$IF ...} directives. A stray bracket does not bother
       the compiler while the branch is not taken, and stays silent until the
       first build for another platform.

    2. Word size is not asked through the operating system. WIN64 answers "is
       this Windows 64" correctly, but it was used to answer "is this 64 bits" -
       and on 64-bit Linux a pointer was truncated to Integer. For word size
       there is CPU64 (FPC) and CPU64BITS (Delphi).

    3. A measurement: how many conditional branches there are in total, and what
       share of them belongs to targets the build matrix does not cover. That is
       not an error but a number showing the size of the unchecked part.

  Third-party code and output folders are not checked.
#>

[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent

# Folders with our own code. Third-party code is deliberately out of scope.
# A published repository has none of the monorepo layers, and then the whole
# root is checked: otherwise the file list would be empty and the report green
# while checking nothing.
$Areas = @('0-foundation', '1-bindings', '3-algorithms', '4-ml', '6-apps', 'examples')

function OurSources {
    $Found = @($Areas | Where-Object { Test-Path (Join-Path $Root $_) })
    if ($Found.Count -eq 0) { $Found = @('.') }
    foreach ($Area in $Found) {
        $Path = Join-Path $Root $Area
        Get-ChildItem $Path -Recurse -File -Include '*.pas', '*.inc', '*.dpr', '*.lpr' |
            Where-Object { $_.FullName -notmatch '\\(out|lib|backup|__history|thirdparty)\\' }
    }
}

# Reads a file, working out the encoding: the repository has both UTF-8 and cp1251.
function ReadSource([string]$Path) {
    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    try { return [System.Text.UTF8Encoding]::new($false, $true).GetString($Bytes) }
    catch { return [System.Text.Encoding]::GetEncoding(1251).GetString($Bytes) }
}

$Files = @(OurSources)
$Failed = 0
Write-Host "=== Conditional code: files checked $($Files.Count) ==="

# --- 1. Bracket balance in directives ---
$Unbalanced = @()
foreach ($File in $Files) {
    $Text = ReadSource $File.FullName
    $LineNo = 0
    foreach ($Line in ($Text -split "\r?\n")) {
        $LineNo++
        foreach ($M in [regex]::Matches($Line, '\{\$IF[^}]*\}')) {
            $D = $M.Value
            $Open = ($D.ToCharArray() | Where-Object { $_ -eq '(' }).Count
            $Close = ($D.ToCharArray() | Where-Object { $_ -eq ')' }).Count
            if ($Open -ne $Close) {
                $Unbalanced += ("{0}:{1}: {2}" -f $File.FullName.Replace("$Root\", ''), $LineNo, $D)
            }
        }
    }
}
if ($Unbalanced.Count) {
    Write-Host "`n  FAIL brackets in directives do not balance:" -ForegroundColor Red
    $Unbalanced | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    $Failed++
} else { Write-Host "`n  ok   brackets balance in every {`$IF ...} directive" }

<#
  --- 2. Word size through the operating system ---

  WIN64 is only flagged where the surrounding lines work with the machine word:
  a cast to Integer or NativeInt, an atomic exchange, a pointer. Simply naming
  the build target, as ExtendedProbe does, is legitimate and must not be
  complained about.
#>
$WidthWords = 'Integer|NativeInt|Int64|LongInt|Pointer|AtomicExchange|InterlockedExchange|PColor|@'
$OsForWidth = @()
foreach ($File in $Files) {
    $Text = ReadSource $File.FullName
    $Lines = $Text -split "\r?\n"
    for ($I = 0; $I -lt $Lines.Count; $I++) {
        if ($Lines[$I] -notmatch '\{\$IF(N?DEF)?\s*[^}]*\bWIN64\b') { continue }
        # look at the line itself and the next three - the branch body is there
        $Window = ($Lines[$I..([Math]::Min($I + 3, $Lines.Count - 1))] -join ' ')
        if ($Window -match $WidthWords) {
            $OsForWidth += ("{0}:{1}" -f $File.FullName.Replace("$Root\", ''), ($I + 1))
        }
    }
}
if ($OsForWidth.Count) {
    Write-Host "`n  FAIL word size asked through WIN64 - use CPU64 or CPU64BITS:" -ForegroundColor Red
    $OsForWidth | ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    $Failed++
} else { Write-Host '  ok   word size is nowhere decided by the name of the system' }

<#
  --- 3. Measuring the unchecked part ---

  The matrix builds Delphi 37 (win32, win64) and FPC 3.3.1 (win64, linux64). In
  both cases Directives.inc declares ENHANCED and the whole DELPHI_* list,
  because the compilers are recent. So the ELSE branch of such a check - the
  fallback for Delphi older than XE7 - is never compiled by anything.

  That is not an error: support for old compilers was written on purpose. But it
  is useful to see the size: that much code sits in the sources having never
  passed a compiler, and anything can be in there - like the stray bracket in
  VersionUtils.
#>
$Legacy = 'DELPHI_(XE7|XE5|XE|10\.2|2009|2010|7|2006)|UNICODE|ENHANCED'
$Total = 0
$Dead = 0
foreach ($File in $Files) {
    $Text = ReadSource $File.FullName
    $Stack = New-Object System.Collections.Generic.Stack[bool]
    foreach ($M in [regex]::Matches($Text, '\{\$(IFDEF|IFNDEF|IF|ELSE|ELSEIF|ENDIF|IFEND)[^}]*\}')) {
        $D = $M.Value
        if ($D -match '^\{\$IF') {
            $Total++
            $Stack.Push([bool]($D -match $Legacy))
        }
        elseif ($D -match '^\{\$ELSE' -and $Stack.Count) {
            if ($Stack.Peek()) { $Dead++ }
        }
        elseif ($D -match '^\{\$(ENDIF|IFEND)' -and $Stack.Count) {
            [void]$Stack.Pop()
        }
    }
}
$Share = if ($Total) { [math]::Round($Dead * 100.0 / $Total, 1) } else { 0 }
Write-Host "`n  measured: conditional blocks $Total, of them fallback branches for"
Write-Host "            obsolete compilers $Dead ($Share%) - compiled by nothing"

Write-Host ''
if ($Failed -eq 0) {
    Write-Host '=== CONDITIONAL CODE IS CLEAN ===' -ForegroundColor Green
} else {
    Write-Host "=== FINDINGS: $Failed ===" -ForegroundColor Red
}
exit $Failed
