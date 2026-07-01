<#
.SYNOPSIS
    FWMIG-Remediation.ps1 - Safely resolve firewall double-management / conflicts (default -WhatIf).

.DESCRIPTION
    PURPOSE
        Resolves the classic GPO-to-Intune migration conflict on a device that is double-managed:
        when a device has been assigned the Intune (MDM) firewall policy but GPO is STILL applying
        firewall rules, the two authorities fight and can merge-loop. This script forces a Group
        Policy refresh and an Intune sync so the device drops out of GPO scope (per your coexistence
        control) and settles on the single Intune authority, then re-checks the state.

        SAFETY: runs in -WhatIf mode by DEFAULT - it reports the actions it WOULD take and changes
        nothing. Re-run with -Apply to actually perform the (non-destructive) refresh/sync. It never
        deletes firewall rules and never edits GPOs.

    HOW TO RUN
        Preview (default, safe):
            .\FWMIG-Remediation.ps1
        Apply the refresh/sync:
            .\FWMIG-Remediation.ps1 -Apply

    EXPECTED RESULTS
        - -WhatIf (default): a list of the remediation actions that WOULD run, plus the current
          authority state - no changes made.
        - -Apply: runs 'gpupdate /force' and triggers an Intune MDM sync, then reports whether the
          device is now single-authority (run FWMIG-Validation.ps1 to confirm parity afterwards).
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [switch] $Apply
)

# Default posture is preview-only. -Apply opts in to performing actions.
if (-not $Apply) { $WhatIfPreference = $true }

Import-Module NetSecurity -ErrorAction SilentlyContinue

function Get-AuthorityState {
    $gpo = @(Get-NetFirewallRule -PolicyStore RSOP -ErrorAction SilentlyContinue).Count
    $mdm = @(Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue |
             Where-Object { $_.PolicyStoreSource -match 'MDM' -or $_.PolicyStoreSourceType -eq 'MDM' }).Count
    [pscustomobject]@{ GpoRules = $gpo; MdmRules = $mdm }
}

$before = Get-AuthorityState
Write-Host "FWMIG Remediation on $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "  Before: GPO rules=$($before.GpoRules)  MDM rules=$($before.MdmRules)"
if (-not $Apply) { Write-Host '  MODE: -WhatIf (preview only). Re-run with -Apply to make changes.' -ForegroundColor Yellow }

if ($before.GpoRules -gt 0 -and $before.MdmRules -gt 0) {
    Write-Host '  Detected DOUBLE MANAGEMENT (GPO + MDM). Remediation: refresh GPO so the device' -ForegroundColor Yellow
    Write-Host '  drops out of GPO firewall scope (per coexistence control), then re-sync Intune.' -ForegroundColor Yellow
} else {
    Write-Host '  No double-management detected; remediation will simply refresh + re-sync.' -ForegroundColor Green
}

# Action 1 - force a Group Policy refresh (so removed-from-scope takes effect)
if ($PSCmdlet.ShouldProcess('local machine', 'gpupdate /force')) {
    Start-Process -FilePath 'gpupdate.exe' -ArgumentList '/force' -Wait -NoNewWindow
}

# Action 2 - trigger an Intune MDM sync via the scheduled task that the MDM enrollment registers
if ($PSCmdlet.ShouldProcess('local machine', 'Trigger Intune MDM sync (PushLaunch scheduled task)')) {
    $task = Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object { $_.TaskPath -like '*EnterpriseMgmt*' -and $_.TaskName -eq 'PushLaunch' } |
            Select-Object -First 1
    if ($task) {
        Start-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
    } else {
        Write-Host '  Intune MDM sync task not found - device may not be MDM-enrolled.' -ForegroundColor Yellow
    }
}

if ($Apply) {
    Start-Sleep -Seconds 5
    $after = Get-AuthorityState
    Write-Host "  After:  GPO rules=$($after.GpoRules)  MDM rules=$($after.MdmRules)"
    if ($after.GpoRules -eq 0 -and $after.MdmRules -gt 0) {
        Write-Host '  RESULT: single authority (Intune/MDM). Run FWMIG-Validation.ps1 to confirm parity.' -ForegroundColor Green
    } elseif ($after.GpoRules -gt 0) {
        Write-Host '  RESULT: GPO still applying. Confirm the device was removed from the firewall GPO scope.' -ForegroundColor Red
    }
}
