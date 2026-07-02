<#
.SYNOPSIS
    INTCFG-Remediation.ps1 — safe re-sync / fix for a device stuck at the sync layer.
.DESCRIPTION
    PURPOSE
        For a device that is correctly assigned but has not received the policy (stuck sync), this
        triggers an MDM check-in so the assignment reaches the device, then reports the new sync
        result. It does NOT change any policy or setting. Defaults to -WhatIf: it shows what it would
        do and changes nothing until you re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\INTCFG-Remediation.ps1
        Apply the sync:     powershell -ExecutionPolicy Bypass -File .\INTCFG-Remediation.ps1 -WhatIf:$false
        Run elevated on the affected device. No Graph scopes needed.
    EXPECTED RESULTS
        In -WhatIf: "WHATIF: would trigger MDM sync". Applied: "MDM sync triggered", then re-run
        INTCFG-Validation.ps1 to confirm a recent check-in and cleared setting status.
.NOTES
    White-label — the repeatable way. Default -WhatIf. Confirm assignment BEFORE re-syncing.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$WhatIf = $true
)
# make -WhatIf the default while still honouring an explicit -WhatIf:$false
if ($PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = [bool]$WhatIf } else { $WhatIfPreference = $true }

Write-Host "=== INTCFG Remediation (re-sync) — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Write-Host "Reminder: confirm the device IS assigned (INTCFG-Discovery.ps1) before re-syncing." -ForegroundColor Yellow

$deviceEnroller = "$env:WINDIR\System32\deviceenroller.exe"

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Trigger MDM check-in (deviceenroller /c /AutoEnrollMDM)')) {
    try {
        Start-Process -FilePath $deviceEnroller -ArgumentList '/c /AutoEnrollMDM' -WindowStyle Hidden -ErrorAction Stop
        Write-Host "  MDM sync triggered — the assignment will be re-evaluated on this device." -ForegroundColor Green

        # also kick the scheduled OMA-DM sync task if present (belt and braces)
        try {
            Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -TaskName 'PushLaunch' -ErrorAction Stop |
                Start-ScheduledTask -ErrorAction SilentlyContinue
            Write-Host "  OMA-DM PushLaunch task started." -ForegroundColor Green
        } catch {}

        Write-Host "`nWait a few minutes, then run INTCFG-Validation.ps1 to confirm a recent check-in." -ForegroundColor Cyan
    } catch {
        Write-Host "  Failed to trigger sync: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  WHATIF: would trigger MDM sync via deviceenroller /c /AutoEnrollMDM (no change made)." -ForegroundColor Gray
    Write-Host "  Re-run with -WhatIf:`$false to apply." -ForegroundColor Gray
}
