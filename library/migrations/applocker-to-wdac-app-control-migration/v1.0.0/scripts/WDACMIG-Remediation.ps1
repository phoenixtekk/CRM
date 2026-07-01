<#
.SYNOPSIS
    WDACMIG-Remediation.ps1 — safe rollback: revert a device from Enforced back to Audit mode.
.DESCRIPTION
    PURPOSE
        Recovery for an over-strict enforced WDAC policy during migration. After you UNASSIGN
        'App Control - Fleet - Enforce' in Intune (and re-assign 'App Control - Fleet - Audit'), this
        forces an MDM sync so the change reaches the device and (Windows 11) refreshes the local
        policy set with citool, returning the device to a non-blocking audit state. Runs in -WhatIf
        by default — it only previews actions until you pass -WhatIf:$false.
    HOW TO RUN
        Preview (default, no changes):  powershell -ExecutionPolicy Bypass -File .\WDACMIG-Remediation.ps1
        Apply:                          powershell -ExecutionPolicy Bypass -File .\WDACMIG-Remediation.ps1 -WhatIf:$false
    EXPECTED RESULTS
        With -WhatIf (default): the steps it WOULD take. Applied: MDM sync requested and local policy
        refreshed; reboot if a policy persists, then run WDACMIG-Validation.ps1 (expect Audit).
.NOTES
    Unassign the Intune Enforce policy and re-assign Audit FIRST. Default -WhatIf for safety.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param()

# Default to preview unless the caller explicitly turns -WhatIf off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== AppLocker to WDAC Migration — Remediation / Revert to Audit ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "(PREVIEW MODE — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

Write-Host "Step 1: in Intune, UNASSIGN 'App Control - Fleet - Enforce' and RE-ASSIGN 'App Control - Fleet - Audit' for this device's ring group." -ForegroundColor Yellow

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Request MDM sync (deliver the audit re-assignment)")) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

$citool = "$env:WINDIR\System32\citool.exe"
if (Test-Path $citool) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "citool --refresh (apply the updated policy set)")) {
        try { & $citool --refresh 2>$null; Write-Host "  citool --refresh issued." -ForegroundColor Green } catch {}
    }
    Write-Host "  Current active policies:" -ForegroundColor Cyan
    & $citool --list-policies 2>$null | Select-String 'FriendlyName|IsEnforced' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
} else {
    Write-Host "  (Windows 10: the policy mode updates on next sync; a reboot may be required.)" -ForegroundColor Gray
}

Write-Host "`nIf the device is still enforced/blocking, reboot, then run WDACMIG-Validation.ps1 (expect Audit)." -ForegroundColor Green
Write-Host "If AppLocker was already retired on this ring, re-deploy it temporarily for coverage while you fix WDAC trust." -ForegroundColor Gray
