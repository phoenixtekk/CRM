<#
.SYNOPSIS
    INTCFG-Validation.ps1 — per-device applied-state check for Intune configuration policies.
.DESCRIPTION
    PURPOSE
        Run this ON an affected device to check the sync and CSP-apply layers locally: MDM enrollment
        health, the last successful sync time, and any recent MDM/CSP result events (including error
        codes) from the device's own logs. Read-only — it changes nothing on the device.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\INTCFG-Validation.ps1
        No Graph scopes needed — reads local registry and event logs only.
    EXPECTED RESULTS
        Enrollment health (healthy / not enrolled), last sync time, and a short list of recent CSP
        results with any error codes. "MDM enrollment not found" if the device is not Intune-managed.
.NOTES
    White-label — the repeatable way. Read-only against the local device.
#>
[CmdletBinding()]
param()

Write-Host "=== INTCFG Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# 1. MDM enrollment health (Intune leaves an enrollment key with a UPN + provider)
$enrollRoot = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
$enrolled = $false
try {
    Get-ChildItem $enrollRoot -ErrorAction Stop | ForEach-Object {
        $e = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($e.UPN -and $e.ProviderID -eq 'MS DM Server') {
            $enrolled = $true
            Write-Host ("MDM enrollment : HEALTHY  (UPN: {0})" -f $e.UPN) -ForegroundColor Green
        }
    }
} catch {}
if (-not $enrolled) {
    Write-Host "MDM enrollment : NOT FOUND — device is not Intune-managed or enrollment is broken." -ForegroundColor Yellow
}

# 2. Last sync (scheduled-task history for the OMA-DM sync)
try {
    $sched = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction Stop |
        Get-ScheduledTaskInfo | Sort-Object LastRunTime -Descending | Select-Object -First 1
    if ($sched -and $sched.LastRunTime) {
        Write-Host ("Last MDM sync  : {0}  (result 0x{1:X})" -f $sched.LastRunTime, $sched.LastTaskResult) -ForegroundColor Cyan
    } else {
        Write-Host "Last MDM sync  : no sync task history found." -ForegroundColor Yellow
    }
} catch { Write-Host "Last MDM sync  : sync task not present (enrollment may be broken)." -ForegroundColor Yellow }

# 3. Recent CSP / DeviceManagement results, surfacing error codes
Write-Host "`nRecent MDM/CSP results (last 20):" -ForegroundColor Cyan
$logs = 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'
try {
    $events = Get-WinEvent -LogName $logs -MaxEvents 200 -ErrorAction Stop |
        Where-Object { $_.LevelDisplayName -in 'Error','Warning' -or $_.Message -match '0x8|result' } |
        Select-Object -First 20
    if ($events) {
        foreach ($ev in $events) {
            $code = if ($ev.Message -match '(0x[0-9A-Fa-f]{8})') { $Matches[1] } else { '' }
            $color = if ($ev.LevelDisplayName -eq 'Error') { 'Yellow' } else { 'Gray' }
            $line = ($ev.Message -split "`r?`n")[0]
            Write-Host ("  [{0}] {1} {2}" -f $ev.TimeCreated.ToString('MM-dd HH:mm'), $code, $line) -ForegroundColor $color
        }
    } else {
        Write-Host "  No recent error/warning CSP events — the sync layer looks clean." -ForegroundColor Green
    }
} catch {
    Write-Host "  DeviceManagement diagnostic log not available on this device." -ForegroundColor Gray
}

if ($enrolled) { exit 0 } else { exit 1 }
