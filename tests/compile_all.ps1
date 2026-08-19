# Tries to build every unit of the 0-foundation layer on its own.
# The parser bench does not pull in everything, and units outside its
# dependencies are not checked otherwise: that is how a stray character in a
# VersionUtils directive hid for years under FPC/Linux.
#
# Units that do not build everywhere are listed in pascal\PLATFORMS.tsv and are
# not counted as breakage. Everything else has to build.
param([ValidateSet('delphi', 'fpc')][string]$Compiler = 'delphi')

$ErrorActionPreference = 'Continue'

# The library directories. In the monorepo they are 0-foundation\pascal and
# pascal-jit, in the published repository they are src and jit next to the
# tests. PARSER_SRC and PARSER_JIT override both guesses.
$MonoSrc = Join-Path $PSScriptRoot '..\..\pascal'
$MonoJit = Join-Path $PSScriptRoot '..\..\pascal-jit'
$ShipSrc = Join-Path $PSScriptRoot '..\src'
$ShipJit = Join-Path $PSScriptRoot '..\jit'

# Both layouts at once is not a reason to take whichever turned up first, it is
# a sign that the situation is unclear and a person has to decide. An unrelated
# directory named pascal next to the release tree quietly CHANGES THE SUBJECT OF
# THE CHECK: measured on 11.08.2026 on a copy of the publication - a broken
# published src gave BUILT: 50, NOT BUILT: 0 and code 0, because the neighbour
# was the thing being built. Without the neighbour the same src gave 22 failures.
#
# The layout is decided ONCE, and both roots follow FROM IT.
#
# Choosing the roots SEPARATELY closed the ambiguity alone, and that is not
# enough: if the release has no jit of its own while a foreign one lies next
# door, the refusal does not fire - there is no second candidate - and the gate
# quietly takes the foreign one. A release without its own accelerator passes
# green, the absence masked by a neighbour. Measured on 11.08.2026 on a tree
# where release/jit was missing.
#
# THE TRUST BOUNDARY, said out loud: if BOTH variables are set, the person has
# deliberately allowed any pair, including their own src with an external jit.
# The gate treats such a pair as authoritative. This is a documented exception.
if ($env:PARSER_SRC -and $env:PARSER_JIT) {
    $Src = $env:PARSER_SRC
    $Jit = $env:PARSER_JIT
} elseif ($env:PARSER_SRC -or $env:PARSER_JIT) {
    Write-Host "THE ROOTS ARE SET BY HALVES: the other half would have to be guessed" -ForegroundColor Red
    Write-Host "  set both PARSER_SRC and PARSER_JIT - or neither"
    exit 1
} else {
    $MonoOk = (Test-Path $MonoSrc) -and (Test-Path $MonoJit)
    $ShipOk = (Test-Path $ShipSrc) -and (Test-Path $ShipJit)
    if ($MonoOk -and $ShipOk) {
        Write-Host "THE LAYOUT IS AMBIGUOUS: both layouts are complete" -ForegroundColor Red
        Write-Host "  set PARSER_SRC and PARSER_JIT explicitly - otherwise it is unknown what is checked"
        exit 1
    } elseif ($MonoOk) {
        $Src = (Resolve-Path $MonoSrc).Path; $Jit = (Resolve-Path $MonoJit).Path
    } elseif ($ShipOk) {
        $Src = (Resolve-Path $ShipSrc).Path; $Jit = (Resolve-Path $ShipJit).Path
    } else {
        Write-Host "THERE IS NO COMPLETE LAYOUT, and filling it in with a neighbour is forbidden. What is missing:" -ForegroundColor Red
        foreach ($P in @($MonoSrc, $MonoJit, $ShipSrc, $ShipJit)) {
            if (-not (Test-Path $P)) { Write-Host "  no $P" }
        }
        exit 1
    }
}


# Leaving the tree OUTWARDS, one rule for all the scripts, see tests/parser/runroot.ps1.
$RunRootRule = Join-Path $PSScriptRoot 'runroot.ps1'
if (-not (Test-Path -LiteralPath $RunRootRule -PathType Leaf)) {
    Write-Host "REFUSED: the run-root rule was not found: $RunRootRule"
    exit 1
}
. $RunRootRule
$RunRoot = Initialize-RunRoot (Join-Path $PSScriptRoot '..\..')
if ($null -eq $RunRoot) { exit 1 }
$Out = Join-Path $RunRoot "allunits-$Compiler"

# The output directory IS CLEARED rather than reused.
#
# It is also the search directory for units: anything left from the previous run
# will be found and pulled in by the compiler. Measured on 10.08.2026:
# Messages.ppu, built once, shadowed the LCL unit of the same name, and the next
# run gave 19 built units instead of 52. The source itself had been taken off
# the list by then - it fell over the leftovers alone. The same goes for a unit
# removed from the library: its ppu keeps satisfying other people's uses, and
# nobody notices the loss.
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force $Out | Out-Null

# The clearing IS CHECKED rather than assumed.
#
# Remove-Item might have failed - a file busy, the wrong permissions - and the
# run would have gone on with the leftovers the clearing exists to get rid of.
# This very class once gave 19 built units instead of 52.
# The checker has to PROVE that it enumerated the directory.
#
# A suppressed enumeration error turned "could not look" into "empty": a
# directory with 0333 permissions allows entering and writing but not listing,
# and the check declared it clean. The same fail-open, only now inside the check
# of the clearing itself.
$LErr = $null
$Left = @(Get-ChildItem $Out -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable LErr)
if ($LErr) {
    Write-Host "THE DIRECTORY CANNOT BE ENUMERATED: $Out - $($LErr[0].Exception.Message)" -ForegroundColor Red
    exit 1
}
if ($Left.Count -gt 0) {
    Write-Host "THE OUTPUT DIRECTORY WAS NOT CLEARED: $Out, files left $($Left.Count)" -ForegroundColor Red
    $Left | Select-Object -First 3 | ForEach-Object { Write-Host "    left: $($_.Name)" -ForegroundColor Red }
    exit 1
}

# who is not obliged to build here
#
# The UNIT NAME is compared WITHOUT regard to case, the VALUE - with it.
#
# At first I reduced both platforms to the shell rule and made the names
# case-sensitive. That was a fix in the wrong direction: for Object Pascal Foo
# and foo are ONE AND THE SAME unit, and in a shared output directory they will
# collide. So both the table and the search for units of the same name have to
# count them as one. And the values of the second column are keywords, they are
# written in lower case and that is that.
$Skip = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
# The platform table HAS TO exist: without it there is no telling what counts as
# an exclusion, and the run would go on with an empty list, as if there were
# nobody to excuse.
$Tsv = [IO.Path]::Combine($Src, 'PLATFORMS.tsv')
if (-not (Test-Path $Tsv)) {
    Write-Host "NO PLATFORM TABLE: $Tsv - what counts as an exception is unknown" -ForegroundColor Red
    exit 1
}
# Existing is still not the same as being READ.
#
# The existence check closed the absence of the file alone. A file that is in
# place but not readable gives an empty exclusion list, exactly the same "nobody
# to excuse", now with a permission error instead of an absence.
$Rows = $null
# The table is read AS UTF-8, not by the code page of the system.
#
# Without an explicit encoding Windows PowerShell reads a file without a BOM in
# a single-byte encoding, and the reasons for skipping came out garbled in the
# report: the word "(skipped)" printed correctly because it is a literal of the
# script, while the reason from the table did not. A person saw rubbish exactly
# where the explanation of why a unit was not checked belongs.
try { $Rows = @(Get-Content $Tsv -Encoding UTF8 -ErrorAction Stop) }
catch {
    Write-Host "THE PLATFORM TABLE CANNOT BE READ: $Tsv - $($_.Exception.Message)" -ForegroundColor Red
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
    # A broken line (fewer than three fields, spaces instead of a tab) used to
    # tear the access to $Part[1], and with ErrorActionPreference=Continue the
    # statement was simply dropped: the line quietly meant nothing. An unknown
    # word in the second field went to the default branch and also kept quiet.
    # That is how an exclusion disappears without a trace, and everything depends
    # on whether somebody notices it by eye.
    if ($Part.Count -ne 3) {
        $TsvBad += "line ${LineNo}: fields $($Part.Count), 3 tab-separated are needed"
        continue
    }
    $Unit = $Part[0].Trim()
    $Where = $Part[1].Trim()

    # An empty name and an empty reason are a broken line too.
    #
    # The line "<tab>never<tab>reason" passed every check: three fields, a known
    # value, no repetition. It is worth nothing, and it looks like a working
    # exclusion.
    if (-not $Unit) {
        $TsvBad += "line ${LineNo}: empty unit name"
        continue
    }
    if (-not $Part[2].Trim()) {
        $TsvBad += "line ${LineNo}: ${Unit} - empty reason"
        continue
    }
    if ($Known -cnotcontains $Where) {
        $TsvBad += "line ${LineNo}: ${Unit} - unknown value '$Where', the known ones are: $($Known -join ', ')"
        continue
    }
    if ($TsvSeen.ContainsKey($Unit)) {
        $TsvBad += "line ${LineNo}: ${Unit} is mentioned again (it was on line $($TsvSeen[$Unit]))"
        continue
    }
    $TsvSeen[$Unit] = $LineNo
    $Excused = switch ($Where) {
        'never'   { $true }
        'windows' { $false }              # a Windows unit: on Windows it has to build
        'unix'    { $true }               # outside Windows only: here it is not pulled in
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
    Write-Host "THE PLATFORM TABLE WAS NOT PARSED IN FULL: lines with errors $($TsvBad.Count)" -ForegroundColor Red
    exit ($TsvBad.Count)
}

$Ok = 0
$Bad = @()
$Excused = @()
# The composition: EVERYTHING that ships, not the top level of a single
# directory.
#
# It used to enumerate only $Src without -Recurse, while $Jit was not walked at
# all. The step was called "every unit" and took 46 out of 52: the whole
# accelerator (five units) and src\compat went past it. So the youngest code was
# checked only in the company of neighbours - exactly what the unit-by-unit
# build exists to avoid.
#
# AND EVERY ROOT HAS TO GIVE A NON-EMPTY LIST.
#
# A common "more than zero built" is not enough: with a sound $Src and an empty
# or wrong $Jit the core builds, the counter grows, there are no failures - and
# the accelerator is again checked in the amount of zero units, only now in
# silence. The requirement of completeness has to be per component, not summed.
$Roots = [ordered]@{ 'src' = $Src; 'jit' = $Jit }
$Units = @()
$Empty = @()
$OkByRoot = @{}
$EnumBad = @()
foreach ($Name in $Roots.Keys) {
    # ENUMERATION errors are not silenced.
    #
    # SilentlyContinue hid more than an empty root: on a partially unreadable
    # tree the walk returns the available part, the error disappears, the counter
    # stays non-zero - and the per-root check is satisfied although some units
    # never made the list at all. An unreachable subdirectory does not mean
    # "fewer units", it means "it is unknown how many there are".
    $Err = $null
    # The census takes ORDINARY FILES, not everything ending in .pas.
    #
    # A directory named Ghost.pas satisfied both the census and the check "a
    # table entry points at an existing unit": the basename is the same, and
    # there is no unit. A stale entry came back to life as an empty directory,
    # and the run stayed green.
    $Found = @(Get-ChildItem $Roots[$Name] -File -Filter '*.pas' -Recurse `
                             -ErrorAction SilentlyContinue -ErrorVariable Err)
    foreach ($E in $Err) { $EnumBad += "$Name : $($E.Exception.Message)" }
    Write-Host ("root {0,-4} {1,-60} units {2}" -f $Name, $Roots[$Name], $Found.Count)
    if ($Found.Count -eq 0) { $Empty += "$Name ($($Roots[$Name]))" }
    $OkByRoot[$Name] = 0
    foreach ($F in $Found) { $Units += [PSCustomObject]@{ File = $F; Root = $Name } }
}
foreach ($E in $Empty) {
    Write-Host "THE ROOT IS EMPTY OR NOT FOUND: $E - nothing was checked from there" -ForegroundColor Red
}
foreach ($E in $EnumBad) {
    Write-Host "THE WALK OF THE TREE IS NOT COMPLETE: $E" -ForegroundColor Red
}

# The roots have to be DIFFERENT.
#
# Set PARSER_JIT equal to PARSER_SRC and both roots are non-empty, both give
# units, both counters grow: the per-root check is satisfied, and the
# accelerator has not been checked once. One directory counted twice is not two
# roots.
$Same = @()
$Seen = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($Name in $Roots.Keys) {
    $Full = try { (Resolve-Path $Roots[$Name] -ErrorAction Stop).Path.TrimEnd('\') } catch { $Roots[$Name] }
    if ($Seen.ContainsKey($Full)) { $Same += "$($Seen[$Full]) and $Name -> $Full" }
    else { $Seen[$Full] = $Name }
}
foreach ($S in $Same) {
    Write-Host "THE ROOTS COINCIDE: $S - one directory counted twice" -ForegroundColor Red
}

# Units of the same name in different roots are a failure too.
#
# The output directory is shared: the second such unit overwrites the ppu of the
# first, while the platform table tells units apart by name and would excuse
# both at once. The check would come to depend on the order of the walk.
$Dup = @($Units | Group-Object { $_.File.BaseName.ToLowerInvariant() } | Where-Object { $_.Count -gt 1 })
foreach ($D in $Dup) {
    Write-Host ("ONE NAME IN DIFFERENT ROOTS: {0} - {1}" -f $D.Name,
                (($D.Group | ForEach-Object { $_.Root }) -join ', ')) -ForegroundColor Red
}

# An entry about a unit that does not exist is an error of the table too.
#
# Such a line excuses nothing and protects nobody, yet it looks like a working
# exclusion: rename a unit and the old line stays on guard over emptiness, while
# the new unit goes into the check without any permission at all.
$Names = [Collections.Generic.Dictionary[string,bool]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($U in $Units) { $Names[$U.File.BaseName] = $true }
$Stale = @($TsvSeen.Keys | Where-Object { -not $Names.ContainsKey($_) } | Sort-Object)
foreach ($S in $Stale) {
    Write-Host "PLATFORM TABLE: $S is mentioned, and there is no such unit in the tree" -ForegroundColor Red
}

# The compiler is located ONCE, and its presence is checked BEFORE the run.
#
# Otherwise the old trap appears one level down: if the file is missing, the
# call operator prints "the name is not recognised" - that is neither Error: nor
# Fatal:, while $LASTEXITCODE holds the code of the LAST program that ran, that
# is a zero from something unrelated. Neither a sign nor a code - and the unit
# was counted as built although the compiler never started.
#
# Paths from environment variables are joined WITHOUT Join-Path.
#
# Join-Path turns to the provider and on a non-existent drive raises a
# terminating error: BDS_BIN=Z:\... left $Bin empty, and the condition of the
# check fell right after it - entirely, together with the if statement. The
# check silently did not run, and 50 units went into "did not build" instead of
# an honest refusal "there is no compiler". [IO.Path]::Combine is pure string
# work.
if ($Compiler -eq 'delphi') {
    # The studio directory: BDS_BIN, otherwise BDS from Delphi itself, otherwise the
    # standard place.
# The bin folder of the studio. Order: the builder's own variable, the one RAD
# Studio sets for its command prompt, then the registry. The registry replaced a
# path written here by hand. That path named a single version - 13 - and on a
# machine with Delphi 12 the build stopped at "dcc64.exe is not recognized",
# which says nothing about the real cause: the studio is installed, just not
# that one.
function Find-BdsBin($Keys = @('HKLM:\SOFTWARE\WOW6432Node\Embarcadero\BDS',
                               'HKLM:\SOFTWARE\Embarcadero\BDS')) {
    $found = @()
    foreach ($key in $Keys) {
        if (-not (Test-Path $key)) { continue }
        foreach ($item in Get-ChildItem $key) {
            $root = (Get-ItemProperty -Path $item.PSPath -Name RootDir -ErrorAction SilentlyContinue).RootDir
            if (-not $root) { continue }
            $bin = Join-Path $root 'bin'
            if (-not (Test-Path (Join-Path $bin 'dcc64.exe'))) { continue }
            # The key is named after the version: 19.0, 23.0, 37.0. Only the major
            # part is read, and as an integer: [double] would parse 23.0 through the
            # current culture and give nothing on a comma-decimal one.
            $number = 0
            [void][int]::TryParse((($item.PSChildName -split '\.')[0]), [ref]$number)
            $found += [pscustomobject]@{ Version = $number; Bin = $bin }
        }
    }
    if (-not $found) { return '' }
    ($found | Sort-Object Version -Descending)[0].Bin
}

    $BdsBin = if ($env:BDS_BIN) { $env:BDS_BIN }
              elseif ($env:BDS) { [IO.Path]::Combine($env:BDS, 'bin') }
              else { Find-BdsBin }
    if (-not $BdsBin) {
        throw 'Delphi was not found. Set BDS_BIN to the bin folder of the installation, or run this from the RAD Studio command prompt.'
    }
    $Bin = [IO.Path]::Combine($BdsBin, 'dcc64.exe')
    $Rtl = [IO.Path]::Combine([IO.Path]::GetDirectoryName($BdsBin.TrimEnd('\')), 'lib\win64\release')
}
else {
    $Bin = if ($env:FPC_EXE) { $env:FPC_EXE } else { 'fpc.exe' }
    # The default is the same as in the neighbouring build_fpc.ps1. The divergence was
    # costly: there it was 'C:\pascal\laz36', here 'C:\lazarus', and on a machine with
    # Lazarus in the first place the unit-by-unit build quietly lost LCL.
    $LazDir = if ($env:LAZARUS_DIR) { $env:LAZARUS_DIR } else { 'C:\pascal\laz36' }
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

<#
  EVERY UNIT HAS ITS OWN OUTPUT DIRECTORY.

  A shared directory gets poisoned. On a full rebuild the compiler puts there
  not only our unit but everything it rebuilt along the way - foreign units
  included. Such a unit then shadows the one LCL was built against, and the
  following builds fall far away from the place of the error.

  Measured on the slice of release 1.1.1: twenty units out of fifty-two did not
  build with the message "Can't find unit LMessages used by Graphics" - while
  each of them builds in a clean directory. The culprit was found by halving:
  Messages. It landed in the shared directory during a rebuild and broke LCL.
  This very class has been caught twice already - the header of this file holds
  two notes about it - and both times it was treated with the exclusion list. An
  exclusion list treats the case, an own directory treats the class.

  The price is disk space: the full rebuild happens for every unit anyway.
#>
foreach ($Item in ($Units | Sort-Object { $_.File.Name })) {
    $File = $Item.File
    if ($Skip.ContainsKey($File.BaseName)) {
        $Excused += "$($File.BaseName) - $($Skip[$File.BaseName])"
        continue
    }
    $UnitOut = Join-Path $Out $File.BaseName
    New-Item -ItemType Directory -Force $UnitOut | Out-Null
    if ($Compiler -eq 'delphi') {
        $Raw = & $Bin -B -Q ('-U' + $Src + ';' + $Jit + ';' + $Rtl) ('-I' + $Src) `
            ('-N0' + $UnitOut) '-NSSystem;System.Win;WinApi;Vcl' $File.FullName 2>&1
    }
    else {
        $Raw = & $Bin -MDelphi -Sh -B ("-Fu$Src") ("-Fu$Jit") ("-Fu$Lcl") ("-Fu$Lcl\win32") `
            ("-Fu$LazUtils") ("-Fi$Src") ("-FU$UnitOut") $File.FullName 2>&1
    }
    $Code = $LASTEXITCODE
    $Err = $Raw | Select-String -Pattern 'Error:|Fatal:' | Select-Object -First 3
    # The CONTRACT is asked for, not a sign. Earlier the outcome was judged by
    # Error:/Fatal: lines in the output alone - a compiler that fell without those
    # words counted as having built.
    if ($Err -or $Code -ne 0) {
        $Why = if ($Err) { $Err -join '; ' } else { "the compiler returned code $Code without the words Error/Fatal" }
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
# The exit code is the number that did not build, and nothing can fail to build
# if nothing was attempted: it is enough for the platform table to excuse
# everyone by mistake, and the matrix step would record an ok without touching a
# single file. Measured on 10.08.2026 on a copy of the tree with a substituted
# table: "BUILT: 0", exit code 0.
if ($Ok -eq 0) {
    Write-Host 'NOT A SINGLE UNIT WAS BUILT: there was nothing to check' -ForegroundColor Red
    exit ($Bad.Count + 1)
}
# A non-empty root still does not mean that anything from it was CHECKED.
#
# What has to be counted is not the files found but the ones built: the platform
# table can excuse every unit of a root, and then the list is non-empty, there
# are no failures, and exactly nothing from that root was checked. The
# requirement of completeness applies to the result, not to the enumeration.
$Mute = @($Roots.Keys | Where-Object { $OkByRoot[$_] -eq 0 })
foreach ($Name in $Mute) {
    Write-Host ("FROM THE ROOT {0} NOT A SINGLE UNIT WAS BUILT: files found {1}, built 0" -f
                $Name, @($Units | Where-Object { $_.Root -eq $Name }).Count) -ForegroundColor Red
}
$Wrong = $Mute.Count + $Same.Count + $Dup.Count + $Stale.Count + $EnumBad.Count
if ($Wrong -gt 0) {
    exit ($Bad.Count + $Wrong)
}
exit $Bad.Count
