# The run root is OUTSIDE the tree being checked. It is pulled in with . (a dot).
#
# Measured on 11.08.2026: 779 binary files from runs had settled in the release tree,
# 47 of them executable, so the gate was compiling INTO the subject of publication. A
# filtered fingerprint does not see them by construction, so "the tree has not
# changed" went on agreeing while the tree was changing.
#
# A twin of runroot.sh rather than a translation of it: Resolve-Path normalises ..
# but DOES NOT RESOLVE LINKS, whereas pwd -P resolves both. Directory junctions on
# Windows are met more often than symbolic links and give exactly the same way
# round: the name looks external while physically it leads inside the tree.

function Resolve-Physical {
    param([Parameter(Mandatory = $true)][string] $Path)

    $full = [System.IO.Path]::GetFullPath($Path)

    # Links are resolved LINK BY LINK: what leads inside the tree may be not the root
    # itself but any of its ancestors. The limit on the number of steps is against a loop
    # of links, otherwise the check would hang instead of refusing.
    for ($step = 0; $step -lt 64; $step++) {
        $target = $null
        try {
            $target = [System.IO.Directory]::ResolveLinkTarget($full, $true)
        } catch {
            $target = $null
        }
        if ($null -eq $target) { break }
        $next = [System.IO.Path]::GetFullPath($target.FullName)
        if ($next -eq $full) { break }
        $full = $next
    }
    return $full.TrimEnd('\', '/')
}

function Initialize-RunRoot {
    param([Parameter(Mandatory = $true)][string] $TreeRoot)

    if (-not (Test-Path -LiteralPath $TreeRoot -PathType Container)) {
        Write-Host "REFUSED: tree root does not exist: $TreeRoot"
        return $null
    }
    $tree = Resolve-Physical $TreeRoot

    $runRoot = $env:RUNROOT
    if ([string]::IsNullOrWhiteSpace($runRoot)) {
        $runRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    }
    try {
        $null = New-Item -ItemType Directory -Force -Path $runRoot -ErrorAction Stop
    } catch {
        Write-Host "REFUSED: run root not created: $runRoot"
        return $null
    }
    $runRoot = Resolve-Physical $runRoot

    # The comparison goes BY THE SEPARATOR BOUNDARY rather than by the start of the
    # string: otherwise the directory 0-foundation-old would pass as lying inside
    # 0-foundation.
    # Case is not significant on Windows, and comparing it significantly would create a
    # refusal where the tree is the same.
    $sep = [System.IO.Path]::DirectorySeparatorChar
    if ($runRoot.Equals($tree, [System.StringComparison]::OrdinalIgnoreCase) -or
        $runRoot.StartsWith($tree + $sep, [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "REFUSED: run root is physically INSIDE the tree under test"
        Write-Host "  tree: $tree"
        Write-Host "  root: $runRoot"
        return $null
    }

    Write-Host "run root: $runRoot"
    return $runRoot
}
