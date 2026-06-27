<#
.SYNOPSIS
    Converts all file and folder names in a directory tree to GitBook's
    lowercase-hyphen naming convention and updates internal Markdown links.

.DESCRIPTION
    Three-phase operation:
      1. Rename  – All files and folders become lowercase with hyphens.
                   Optional: collapse runs of 2+ hyphens to a single hyphen.
      2. Links   – Relative .md file paths inside ](...) / ](<...>) are updated.
      3. Images  – HTML <img src="..."> paths are updated.

    Safe on Windows NTFS (case-insensitive) via a two-step rename through a
    temporary name.  External URLs (http:// / https://) are never modified.
    Anchor fragments (#...) after .md are preserved unchanged.

.PARAMETER Path
    Root folder to process.  Defaults to the current working directory.

.PARAMETER NormalizeHyphens
    When set, collapses runs of 2 or more consecutive hyphens (-- or ---)
    to a single hyphen in file and folder names.  Default: $true.

.PARAMETER DryRun
    Preview changes without writing anything to disk.

.EXAMPLE
    .\gitbook-rename.ps1 -Path "C:\Docs\my-gitbook"

.EXAMPLE
    .\gitbook-rename.ps1 -Path "C:\Docs\my-gitbook" -NormalizeHyphens:$false

.EXAMPLE
    .\gitbook-rename.ps1 -Path "C:\Docs\my-gitbook" -DryRun
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $Path             = (Get-Location).Path,
    [bool]   $NormalizeHyphens = $true,
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Helpers ─────────────────────────────────────────────────────────────────

function Get-NewName([string]$name) {
    if ($NormalizeHyphens) { $name = $name -replace '-{2,}', '-' }
    return $name.ToLower()
}

function Transform-Path([string]$path) {
    # Apply the same transformation to each forward-slash-delimited segment.
    ($path -split '/' | ForEach-Object { Get-NewName $_ }) -join '/'
}

function Write-Change([string]$label, [string]$from, [string]$to) {
    $tag = if ($DryRun) { '[DRY RUN] ' } else { '' }
    Write-Host "${tag}${label}: $from  ->  $to"
}

# ─── Phase 1 · Rename files and folders ──────────────────────────────────────

Write-Host "`n=== Phase 1: Renaming files and folders ===`n"

$allItems = Get-ChildItem -Path $Path -Recurse -Force |
    Sort-Object { ($_.FullName -split '\\').Count } -Descending

$renameCount = 0

foreach ($item in $allItems) {
    $newName = Get-NewName $item.Name
    if ($newName -ceq $item.Name) { continue }

    Write-Change 'Rename' $item.Name $newName
    $renameCount++

    if (-not $DryRun) {
        $parentDir = if ($item.PSIsContainer) { $item.Parent.FullName }
                     else                     { $item.DirectoryName   }
        $tempName  = 'RNMTMP__' + $item.Name
        $tempPath  = Join-Path $parentDir $tempName

        try {
            # Two-step rename avoids Windows case-insensitive collision
            Rename-Item -LiteralPath $item.FullName -NewName $tempName  -Force -ErrorAction Stop
            Rename-Item -LiteralPath $tempPath       -NewName $newName   -Force -ErrorAction Stop
        } catch {
            Write-Warning "FAILED to rename '$($item.Name)': $_"
        }
    }
}

Write-Host "`nPhase 1 complete: $renameCount item(s) $(if ($DryRun) {'would be'} else {'were'}) renamed."

# ─── Phase 2 · Update Markdown links and HTML image paths ────────────────────

Write-Host "`n=== Phase 2: Updating links in Markdown files ===`n"

$enc     = New-Object System.Text.UTF8Encoding $false   # UTF-8 without BOM
$mdFiles = Get-ChildItem -Path $Path -Recurse -Filter '*.md'
$updateCount = 0

foreach ($file in $mdFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName)

    # ── A. All relative .md link paths ──────────────────────────────────────
    #       Handles both ](<path>) and ](path), with or without #anchor.
    #       Skips external URLs.
    $newContent = [regex]::Replace($content,
        '\]\((<?)([^)>\s]*?\.md)(#[^)>\s]*)?(>?)\)',
        {
            param($m)
            $open   = $m.Groups[1].Value
            $path   = $m.Groups[2].Value
            $anchor = $m.Groups[3].Value
            $close  = $m.Groups[4].Value
            if ($path -match '^https?://|^//') { return $m.Value }
            $newPath = Transform-Path $path
            if ($newPath -ceq $path) { return $m.Value }
            return "]($open$newPath$anchor$close)"
        }
    )

    # ── B. HTML <img src="..."> paths ────────────────────────────────────────
    $newContent = [regex]::Replace($newContent,
        '(?<=src=")([^"]+)(?=")',
        {
            param($m)
            $newPath = Transform-Path $m.Value
            if ($newPath -ceq $m.Value) { return $m.Value }
            return $newPath
        }
    )

    if ($newContent -cne $content) {
        Write-Change 'Links ' $file.Name $file.Name
        $updateCount++
        if (-not $DryRun) {
            [System.IO.File]::WriteAllText($file.FullName, $newContent, $enc)
        }
    }
}

Write-Host "`nPhase 2 complete: $updateCount file(s) $(if ($DryRun) {'would be'} else {'were'}) updated."

# ─── Verification ─────────────────────────────────────────────────────────────

if (-not $DryRun) {
    Write-Host "`n=== Verification ===`n"

    $badNames = Get-ChildItem -Path $Path -Recurse -Force |
        Where-Object { $_.Name -cmatch '[A-Z]' }
    if ($badNames) {
        Write-Warning "Uppercase names still found:"
        $badNames | ForEach-Object { Write-Host "  $($_.FullName)" }
    } else {
        Write-Host "PASS: No uppercase file or folder names."
    }

    $badLinks = Get-ChildItem -Path $Path -Recurse -Filter '*.md' |
        Select-String -Pattern '\]\([^)]*[A-Z][^)]*\.md[^)]*\)' -CaseSensitive |
        Where-Object { $_.Line -notmatch '\]\(https?://' }
    if ($badLinks) {
        Write-Warning "Uppercase .md paths still found in links:"
        $badLinks | ForEach-Object {
            Write-Host "  $($_.Filename) line $($_.LineNumber): $($_.Line.Trim())"
        }
    } else {
        Write-Host "PASS: No uppercase paths in Markdown links."
    }
}

Write-Host "`n=== Done! ===`n"
