# Tries to build every unit of the 0-foundation layer on its own.
# The parser test bench does not pull in everything, and units outside its
# dependencies get no other check: that is how a stray character in a VersionUtils
# directive stayed hidden for years under FPC/Linux.
#
# Units that do not build everywhere are listed in pascal\PLATFORMS.tsv and do not
# count as breakage. Everything else has to build.
param([ValidateSet('delphi', 'fpc')][string]$Compiler = 'delphi')

$ErrorActionPreference = 'Continue'

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


# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
$RunRootRule = Join-Path $PSScriptRoot 'runroot.ps1'
if (-not (Test-Path -LiteralPath $RunRootRule -PathType Leaf)) {
    Write-Host "REFUSED: run root rule not found: $RunRootRule"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $PSScriptRoot '..\..')
if ($null -eq $RunRoot) { exit 1 }
$Out = Join-Path $RunRoot "allunits-$Compiler"

# The output directory is CLEARED rather than reused.
#
# It is also the search directory for units: anything left from the previous run
# will be found and pulled in by the compiler. Measured on 10.08.2026: Messages.ppu,
# built once, shadowed the LCL unit of the same name, and the next run gave 19 built
# units instead of 52. The source itself had been taken off the list by then, so it
# fell over from the rubbish alone. The same goes for a unit removed from the
# library: its ppu goes on satisfying the uses of others, and nobody notices the
# loss.
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force $Out | Out-Null

# Clearing is CHECKED rather than assumed.
#
# Remove-Item could have failed, the file busy or the rights wrong, and the run
# would go on with the very rubbish the clearing was put there to remove. Exactly
# this class once gave 19 built units instead of 52.
# Whoever checks has to PROVE that the directory was listed.
#
# A suppressed traversal error turned "could not look" into "empty": a directory
# with rights 0333 gives entry and writing but not listing, and the check declared
# it clean. The same fail-open, now inside the check of the clearing itself.
$LErr = $null
$Left = @(Get-ChildItem $Out -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable LErr)
if ($LErr) {
    Write-Host "DIRECTORY DOES NOT LIST: $Out - $($LErr[0].Exception.Message)" -ForegroundColor Red
    exit 1
}
if ($Left.Count -gt 0) {
    Write-Host "OUTPUT DIRECTORY NOT CLEARED: $Out, files left $($Left.Count)" -ForegroundColor Red
    $Left | Select-Object -First 3 | ForEach-Object { Write-Host "    left: $($_.Name)" -ForegroundColor Red }
    exit 1
}

# who is not obliged to build here
#
# The UNIT NAME is compared WITHOUT regard to case, the VALUE with regard to it.
#
# At first I brought both platforms to the shell rule and made the names
# case-sensitive. That was an edit in the wrong direction: for Object Pascal Foo and
# foo are ONE AND THE SAME unit, and in a shared output directory they will collide.
# So both the table and the search for units of the same name have to count them as
# one. And the values of the second column are keywords, they are written in lower
# case and that is that.
$Skip = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
# The platform table HAS TO exist: without it there is no telling what counts as an
# exclusion, and the run would go on with an empty list, as if there were nobody to
# excuse.
$Tsv = [IO.Path]::Combine($Src, 'PLATFORMS.tsv')
if (-not (Test-Path $Tsv)) {
    Write-Host "NO PLATFORM TABLE: $Tsv - what counts as an exception is unknown" -ForegroundColor Red
    exit 1
}
# Existing is still not the same as being READ.
#
# The existence check closed the absence of the file alone. A file that is in place
# but not readable gives an empty exclusion list, exactly the same "nobody to
# excuse", now with a permission error instead of an absence.
$Rows = $null
# The table is read AS UTF-8, not by the code page of the system.
#
# Without an explicit encoding Windows PowerShell reads a file without a BOM in a
# single-byte encoding, and the reasons for skipping came out garbled in the report:
# the word "(skipped)" printed correctly because it is a literal of the script,
# while the reason taken from the table did not. The person saw rubbish exactly
# where the explanation of why a unit was not checked belongs.
try { $Rows = @(Get-Content $Tsv -Encoding UTF8 -ErrorAction Stop) }
catch {
    Write-Host "THE PLATFORM TABLE DOES NOT READ: $Tsv - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
$Known = 'never', 'windows', 'unix', 'delphi', 'fpc'
$TsvBad = @()
$TsvSeen = [Collections.Generic.Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)
$LineNo = 0
foreach ($Line in $Rows) {
    $LineNo++
    if ($Line -match '^\s*#' -or $Line.Trim() -eq '') { continue }
    $Part = $Line -split "`t"

    # The table is the INPUT LANGUAGE of the check, and it has to be parsed more
    # strictly than anything else.
    #
    # A broken line (fewer than three fields, spaces instead of a tab) used to break the
    # access to $Part[1], and with ErrorActionPreference=Continue the statement was
    # simply dropped: the line quietly meant nothing. An unknown word in the second
    # field went to the default branch and also stayed silent. That is how an exclusion
    # disappears without a trace, and everything depends on whether somebody notices it
    # by eye.
    if ($Part.Count -ne 3) {
        $TsvBad += "line ${LineNo}: fields $($Part.Count), 3 tab-separated are required"
        continue
    }
    $Unit = $Part[0].Trim()
    $Where = $Part[1].Trim()

    # An empty name and an empty reason are a broken line too.
    if (-not $Unit) {
        $TsvBad += "line ${LineNo}: empty unit name"
        continue
    }
    if (-not $Part[2].Trim()) {
        $TsvBad += "line ${LineNo}: ${Unit} - empty reason"
        continue
    }
    if ($Known -cnotcontains $Where) {
        $TsvBad += "line ${LineNo}: ${Unit} - unknown value '$Where', known: $($Known -join ', ')"
        continue
    }
    if ($TsvSeen.ContainsKey($Unit)) {
        $TsvBad += "line ${LineNo}: ${Unit} named again (was on line $($TsvSeen[$Unit]))"
        continue
    }
    $TsvSeen[$Unit] = $LineNo
    $Excused = switch ($Where) {
        'never'   { $true }
        'windows' { $false }              # a Windows unit: on Windows it has to build
        'unix'    { $true }               # only outside Windows: it is not pulled in here at all
        'delphi'  { $Compiler -eq 'fpc' }
        'fpc'     { $Compiler -eq 'delphi' }
        default   { $false }
    }
    if ($Excused) { $Skip[$Unit] = $Part[2].Trim() }
}
foreach ($B in $TsvBad) {
    Write-Host "PLATFORM TABLE: $B" -ForegroundColor Red
}
if ($TsvBad.Count -gt 0) {
    Write-Host "THE PLATFORM TABLE WAS NOT PARSED IN FULL: bad lines $($TsvBad.Count)" -ForegroundColor Red
    exit ($TsvBad.Count)
}

$Ok = 0
$Bad = @()
$Excused = @()
# Composition: EVERYTHING that ships, not the top level of one directory.
#
# Earlier only $Src was listed, without -Recurse, and $Jit was not walked at all.
# The step was called "every unit" and took 46 out of 52: the whole accelerator
# (five units) and src\compat went past it. So the youngest code was checked only
# in the company of its neighbours, which is exactly what the unit-by-unit build
# exists to avoid.
#
# AND EACH ROOT HAS TO GIVE A NON-EMPTY LIST.
#
# A shared "more than zero built" is not enough: with a sound $Src and an empty or
# wrong $Jit the core builds, the counter grows, there are no failures, and the
# accelerator is again checked in the amount of zero units, only now in silence.
# The demand for completeness has to be per component, not a total.
$Roots = [ordered]@{ 'src' = $Src; 'jit' = $Jit }
$Units = @()
$Empty = @()
$OkByRoot = @{}
$EnumBad = @()
foreach ($Name in $Roots.Keys) {
    # Errors of LISTING are not silenced.
    #
    # SilentlyContinue hid more than an empty root: on a partly unreadable tree the
    # traversal hands out the part it can reach, the error disappears, the counter
    # stays non-zero, and the per-root check is satisfied although some units never
    # made the list at all. An unreachable subdirectory does not mean "fewer units", it
    # means "how many there are is unknown".
    $Err = $null
    # The census takes ORDINARY FILES, not everything that ends in .pas.
    #
    # A directory named Ghost.pas satisfied both the census and the check "a table
    # entry points at an existing unit": the basename is the same and the unit is not
    # there. A stale entry came back to life through an empty directory, and the run
    # stayed green.
    $Found = @(Get-ChildItem $Roots[$Name] -File -Filter '*.pas' -Recurse `
                             -ErrorAction SilentlyContinue -ErrorVariable Err)
    foreach ($E in $Err) { $EnumBad += "$Name : $($E.Exception.Message)" }
    Write-Host ("root {0,-4} {1,-60} units {2}" -f $Name, $Roots[$Name], $Found.Count)
    if ($Found.Count -eq 0) { $Empty += "$Name ($($Roots[$Name]))" }
    $OkByRoot[$Name] = 0
    foreach ($F in $Found) { $Units += [PSCustomObject]@{ File = $F; Root = $Name } }
}
foreach ($E in $Empty) {
    Write-Host "ROOT IS EMPTY OR MISSING: $E - nothing was checked from there" -ForegroundColor Red
}
foreach ($E in $EnumBad) {
    Write-Host "THE TREE WALK IS INCOMPLETE: $E" -ForegroundColor Red
}

# The roots have to be DIFFERENT.
#
# Set PARSER_JIT equal to PARSER_SRC and both roots are non-empty, both give units,
# both counters grow: the per-root check is satisfied and the accelerator has not
# been checked once. One directory counted twice is not two roots.
$Same = @()
$Seen = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($Name in $Roots.Keys) {
    $Full = try { (Resolve-Path $Roots[$Name] -ErrorAction Stop).Path.TrimEnd('\') } catch { $Roots[$Name] }
    if ($Seen.ContainsKey($Full)) { $Same += "$($Seen[$Full]) and $Name -> $Full" }
    else { $Seen[$Full] = $Name }
}
foreach ($S in $Same) {
    Write-Host "ROOTS COINCIDE: $S - one directory counted twice" -ForegroundColor Red
}

# Units of the same name in different roots are a failure too.
#
# The output directory is shared: a second such unit would overwrite the ppu of the
# first, and the platform table tells units apart by name and would excuse both at
# once. The check would come to depend on the order of traversal.
$Dup = @($Units | Group-Object { $_.File.BaseName.ToLowerInvariant() } | Where-Object { $_.Count -gt 1 })
foreach ($D in $Dup) {
    Write-Host ("ONE NAME IN DIFFERENT ROOTS: {0} - {1}" -f $D.Name,
                (($D.Group | ForEach-Object { $_.Root }) -join ', ')) -ForegroundColor Red
}

# An entry about a unit that does not exist is an error of the table too.
#
# Such a line excuses nothing and protects nobody, yet it looks like a working
# exclusion: the unit was renamed, the old line stayed to guard an emptiness, and
# the new unit went into the check without any permission at all.
$Names = [Collections.Generic.Dictionary[string,bool]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($U in $Units) { $Names[$U.File.BaseName] = $true }
$Stale = @($TsvSeen.Keys | Where-Object { -not $Names.ContainsKey($_) } | Sort-Object)
foreach ($S in $Stale) {
    Write-Host "PLATFORM TABLE: $S is named, but there is no such unit in the tree" -ForegroundColor Red
}

# The compiler is looked up ONCE, and its presence is checked BEFORE the run.
#
# Otherwise the old trap appears one level down: if the file is not there, the call
# operator prints "name not recognised", which is neither Error: nor Fatal:, while
# $LASTEXITCODE holds the code of the LAST program that ran, that is a zero from
# something unrelated. No sign and no code, so the unit counted as built although
# the compiler never started once.
#
# Paths from environment variables are joined WITHOUT Join-Path.
#
# Join-Path goes to the provider and on a drive that does not exist throws a
# terminating error: BDS_BIN=Z:\... left $Bin empty, and next the condition of the
# check itself fell over, whole, together with the if statement. The check quietly
# did not run, and 50 units went into "did not build" instead of an honest refusal
# "there is no compiler". [IO.Path]::Combine is plain work with a string.
if ($Compiler -eq 'delphi') {
    # The studio directory: BDS_BIN, otherwise BDS from Delphi itself, otherwise the
    # standard place.
    $BdsBin = if ($env:BDS_BIN) { $env:BDS_BIN }
              elseif ($env:BDS) { [IO.Path]::Combine($env:BDS, 'bin') }
              else { 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin' }
    $Bin = [IO.Path]::Combine($BdsBin, 'dcc64.exe')
    $Rtl = [IO.Path]::Combine([IO.Path]::GetDirectoryName($BdsBin.TrimEnd('\')), 'lib\win64\release')
}
else {
    $Bin = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }
    # The default is the same as in the neighbouring build_fpc.ps1. The divergence was
    # costly: there it was 'C:\laz36', here 'C:\lazarus', and on a machine with Lazarus
    # in the first place the unit-by-unit build quietly lost LCL.
    $LazDir = if ($env:LAZARUS_DIR) { $env:LAZARUS_DIR } else { 'C:\laz36' }
    $Lcl = [IO.Path]::Combine($LazDir, 'lcl\units\x86_64-win64')
    $LazUtils = [IO.Path]::Combine($LazDir, 'components\lazutils\lib\x86_64-win64')

    # The absence of LCL is said out loud in ONE line.
    #
    # Without this check the run handed out 32 identical "Can't find unit Graphics" and
    # left the person guessing whether the code is broken or Lazarus was not found.
    # This is not fail-open, the fall is honest, but the diagnosis was buried in noise.
    if (-not (Test-Path $Lcl)) {
        Write-Host "NO LCL UNITS: $Lcl" -ForegroundColor Red
        Write-Host "  set LAZARUS_DIR; without LCL the units using Graphics and Forms will not build" -ForegroundColor Red
        exit 1
    }
}
if ([string]::IsNullOrWhiteSpace($Bin) -or
    (-not (Get-Command $Bin -ErrorAction SilentlyContinue) -and -not (Test-Path $Bin -ErrorAction SilentlyContinue))) {
    Write-Host "NO COMPILER: $Bin - zero units built, there was nothing to check with" -ForegroundColor Red
    exit 1
}

foreach ($Item in ($Units | Sort-Object { $_.File.Name })) {
    $File = $Item.File
    if ($Skip.ContainsKey($File.BaseName)) {
        $Excused += "$($File.BaseName) - $($Skip[$File.BaseName])"
        continue
    }
    if ($Compiler -eq 'delphi') {
        $Raw = & $Bin -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) ('-I' + $Src) `
            ('-N0' + $Out) '-NSSystem;System.Win;WinApi;Vcl' $File.FullName 2>&1
    }
    else {
        $Raw = & $Bin -MDelphi -Sh -B ("-Fu$Src") ("-Fu$Jit") ("-Fu$Lcl") ("-Fu$Lcl\win32") `
            ("-Fu$LazUtils") ("-Fi$Src") ("-FU$Out") $File.FullName 2>&1
    }
    $Code = $LASTEXITCODE
    $Err = $Raw | Select-String -Pattern 'Error:|Fatal:' | Select-Object -First 3
    # The CONTRACT is asked for, not a sign. Earlier the outcome was judged by
    # Error:/Fatal: lines in the output alone, and a compiler that fell without those
    # words counted as having built.
    if ($Err -or $Code -ne 0) {
        $Why = if ($Err) { $Err -join '; ' } else { "the compiler returned $Code with no Error/Fatal words" }
        $Bad += [PSCustomObject]@{ Unit = $File.BaseName; Error = $Why }
    }
    else {
        $Ok++
        $OkByRoot[$Item.Root]++
    }
}

Write-Host "BUILT: $Ok   NOT BUILT: $($Bad.Count)   not required: $($Excused.Count)"
foreach ($E in $Excused) { Write-Host "    (skipped) $E" }
foreach ($B in $Bad) { Write-Host "--- $($B.Unit)"; Write-Host "    $($B.Error)" }

# A run that built ZERO units is never green.
#
# The return code is the number that did not build, and nothing can fail to build
# if nothing was tried: it is enough for the platform table to excuse everyone by
# mistake, and the matrix step would record ok without touching a single file.
# Measured on 10.08.2026 on a copy of the tree with a substituted table: "BUILT: 0",
# return code 0.
if ($Ok -eq 0) {
    Write-Host 'NOT A SINGLE UNIT WAS BUILT: there was nothing to check' -ForegroundColor Red
    exit ($Bad.Count + 1)
}
# A non-empty root still does not mean anything from it was CHECKED.
#
# What has to be counted is not the files found but the ones built: the platform
# table can excuse every unit of a root, and then the list is non-empty, there are
# no failures, and exactly nothing from that root has been checked. The demand for
# completeness applies to the result, not to the listing.
$Mute = @($Roots.Keys | Where-Object { $OkByRoot[$_] -eq 0 })
foreach ($Name in $Mute) {
    Write-Host ("NOT A SINGLE UNIT BUILT FROM ROOT {0}: files found {1}, built 0" -f
                $Name, @($Units | Where-Object { $_.Root -eq $Name }).Count) -ForegroundColor Red
}
$Wrong = $Mute.Count + $Same.Count + $Dup.Count + $Stale.Count + $EnumBad.Count
if ($Wrong -gt 0) {
    exit ($Bad.Count + $Wrong)
}
exit $Bad.Count
