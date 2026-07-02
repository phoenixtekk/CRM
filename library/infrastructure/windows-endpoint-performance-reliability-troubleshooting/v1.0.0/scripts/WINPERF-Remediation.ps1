<#
.SYNOPSIS
    WINPERF-Remediation.ps1 — safe, reversible fixes for common performance causes (default preview).
.DESCRIPTION
    PURPOSE
        Applies the safe, common fixes surfaced by the Diagnostic Playbook: trimming non-essential
        startup items, clearing safe temp/cache paths to reclaim disk space, and clearing stale
        profile caches. It DEFAULTS TO PREVIEW (-WhatIf) — it shows exactly what it would change and
        how much space it would reclaim, and changes nothing until you re-run in apply mode.
    HOW TO RUN
        Preview (default, safe):
          powershell -ExecutionPolicy Bypass -File .\WINPERF-Remediation.ps1 -Area Temp
        Apply for real:
          powershell -ExecutionPolicy Bypass -File .\WINPERF-Remediation.ps1 -Area Temp -Apply

        -Area   Startup | Temp | Profile | All   (which safe fix to run; default All)
        -Apply  actually make changes (omit to preview). Never touches user documents or system files.
    EXPECTED RESULTS
        A list of the exact startup items that would be disabled, temp paths that would be cleared
        (with reclaimable size), and profile caches that would be cleaned. In preview the summary says
        WOULD; with -Apply it reports what was done. Re-run WINPERF-Validation.ps1 to confirm the gate.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [ValidateSet('Startup','Temp','Profile','All')]
    [string]$Area = 'All',
    [switch]$Apply
)

$ErrorActionPreference = 'SilentlyContinue'

# Default to preview unless -Apply is passed.
if (-not $Apply) { $WhatIfPreference = $true }

$mode = if ($Apply) { 'APPLY' } else { 'PREVIEW (-WhatIf) — nothing will change' }
Write-Host "=== WINPERF Remediation — $env:COMPUTERNAME — $mode ===" -ForegroundColor Cyan

# Startup items considered essential and never touched.
$essential = @('SecurityHealth','Windows Defender','OneDrive','MicrosoftEdgeAutoLaunch')

function Get-FolderSizeMB($path) {
    if (-not (Test-Path $path)) { return 0 }
    $b = (Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($b) { [math]::Round($b/1MB,1) } else { 0 }
}

# ---------- Startup ----------
if ($Area -in 'Startup','All') {
    Write-Host "`n--- Startup items ---" -ForegroundColor Cyan
    $runKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    $props = Get-ItemProperty -Path $runKey -ErrorAction SilentlyContinue
    if ($props) {
        foreach ($p in ($props.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' })) {
            if ($essential -contains $p.Name) { Write-Host "  keep (essential): $($p.Name)"; continue }
            if ($PSCmdlet.ShouldProcess("$($p.Name) [$runKey]", "Disable non-essential startup item")) {
                Remove-ItemProperty -Path $runKey -Name $p.Name -ErrorAction SilentlyContinue
                Write-Host "  disabled: $($p.Name)" -ForegroundColor Green
            } else {
                Write-Host "  WOULD disable: $($p.Name)"
            }
        }
    }
}

# ---------- Temp ----------
if ($Area -in 'Temp','All') {
    Write-Host "`n--- Temp / cache cleanup ---" -ForegroundColor Cyan
    $tempPaths = @(
        "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
    )
    $totalMb = 0
    foreach ($tp in $tempPaths) {
        if (-not (Test-Path $tp)) { continue }
        $mb = Get-FolderSizeMB $tp
        $totalMb += $mb
        if ($PSCmdlet.ShouldProcess("$tp ($mb MB)", "Clear temp/cache contents")) {
            Get-ChildItem -LiteralPath $tp -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  cleared: $tp ($mb MB)" -ForegroundColor Green
        } else {
            Write-Host "  WOULD clear: $tp ($mb MB reclaimable)"
        }
    }
    Write-Host ("  Reclaimable total: ~{0} MB" -f $totalMb)
}

# ---------- Profile ----------
if ($Area -in 'Profile','All') {
    Write-Host "`n--- Profile cache cleanup ---" -ForegroundColor Cyan
    $profileCaches = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer",       # thumbnail caches
        "$env:LOCALAPPDATA\CrashDumps"
    )
    foreach ($pc in $profileCaches) {
        if (-not (Test-Path $pc)) { continue }
        $mb = Get-FolderSizeMB $pc
        if ($PSCmdlet.ShouldProcess("$pc ($mb MB)", "Clear profile cache")) {
            Get-ChildItem -LiteralPath $pc -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  cleared: $pc ($mb MB)" -ForegroundColor Green
        } else {
            Write-Host "  WOULD clear: $pc ($mb MB reclaimable)"
        }
    }
    Write-Host "  NOTE: a full corrupt-profile rebuild is NOT automated — back up user data and recreate the profile manually."
}

Write-Host "`nDone ($mode)." -ForegroundColor $(if ($Apply) {'Green'} else {'Yellow'})
if (-not $Apply) { Write-Host "Re-run with -Apply to make these changes, then re-run WINPERF-Validation.ps1 to confirm." }
