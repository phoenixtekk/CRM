<#
.SYNOPSIS
    EPICWS-Remediation.ps1 — Safely re-triggers MDM sync / re-applies a named profile or app to a clinical workstation.

.DESCRIPTION
    PURPOSE
        For a device that failed validation (EPICWS-Validation.ps1), safely nudges it back toward the
        standard: triggers an Intune MDM sync so pending configuration profiles, the unit printer
        policy, and peripheral apps re-evaluate and re-apply. Optionally restarts the print spooler
        (a common cause of "printer missing/wrong default" after a deployment) and re-asserts the
        unit default printer locally. READ-ONLY / -WhatIf by DEFAULT — it previews every action and
        changes nothing until you pass -Apply, and only ever in an approved maintenance window.

    HOW TO RUN
        On the affected device, in an elevated PowerShell window:
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\EPICWS-Remediation.ps1
        Apply in a maintenance window:
            .\EPICWS-Remediation.ps1 -Apply -RestartSpooler -SetDefaultPrinter "<UNIT_DEFAULT_PRINTER>"

    EXPECTED RESULTS
        Without -Apply: a list of what WOULD happen (sync trigger, spooler restart, default-printer set).
        With -Apply: the MDM sync is triggered, the spooler optionally restarted, and the default
        printer optionally set. Wait for the next Intune sync to complete, then re-run
        EPICWS-Validation.ps1. If it still fails, re-check the Intune assignments for this device's
        unit group.

.NOTES
    Healthcare Solutions — read-only / -WhatIf by default; only -Apply makes changes, intended for an
    approved maintenance window. Never captures patient data. Triggers a device MDM sync and (opt-in)
    local print-spooler restart / default-printer set; it does NOT change Intune policy or other devices.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Apply,
    [switch]$RestartSpooler,
    [string]$SetDefaultPrinter
)

# Default posture is preview unless -Apply is explicitly passed.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== EPIC Clinical Workstation Remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
Write-Host ("Mode: " + ($(if ($Apply) { 'APPLY (changes will be made)' } else { 'PREVIEW / -WhatIf (no changes)' }))) -ForegroundColor ($(if ($Apply) { 'Yellow' } else { 'Green' }))

# 1) Trigger Intune MDM sync (re-evaluates profiles, printer policy, peripheral apps).
if ($PSCmdlet.ShouldProcess('Intune MDM enrollment', 'Trigger device sync (re-apply pending policies/apps)')) {
    try {
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -TaskName 'PushLaunch' -ErrorAction SilentlyContinue
        if ($task) { $task | Start-ScheduledTask; Write-Host "MDM sync triggered (PushLaunch)." -ForegroundColor Green }
        else { Write-Host "PushLaunch task not found; use Settings > Accounts > Access work or school > Sync." -ForegroundColor Yellow }
    } catch { Write-Host "Could not trigger MDM sync: $($_.Exception.Message)" -ForegroundColor Yellow }
}

# 2) Restart the print spooler (opt-in) — clears stuck queues / mapping after a deployment.
if ($RestartSpooler) {
    if ($PSCmdlet.ShouldProcess('Spooler service', 'Restart print spooler')) {
        try { Restart-Service -Name Spooler -Force -ErrorAction Stop; Write-Host "Print spooler restarted." -ForegroundColor Green }
        catch { Write-Host "Could not restart spooler: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

# 3) Re-assert the unit default printer (opt-in) — fixes the most common drift.
if ($SetDefaultPrinter) {
    if ($PSCmdlet.ShouldProcess($SetDefaultPrinter, 'Set as default printer')) {
        try {
            $exists = Get-Printer -Name $SetDefaultPrinter -ErrorAction SilentlyContinue
            if (-not $exists) { Write-Host "Printer '$SetDefaultPrinter' not installed on this device — deploy it first (Implementation Step 8/9)." -ForegroundColor Yellow }
            else {
                (New-Object -ComObject WScript.Network).SetDefaultPrinter($SetDefaultPrinter)
                Write-Host "Default printer set to '$SetDefaultPrinter'." -ForegroundColor Green
            }
        } catch { Write-Host "Could not set default printer: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
}

Write-Host "`nNext: wait for the Intune sync to complete, then re-run EPICWS-Validation.ps1. If still failing, verify this device's unit group assignment in Intune." -ForegroundColor Yellow
