<#
.SYNOPSIS
    NEWSITE-Remediation.ps1 — safe remediation of failed site deployments (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Re-drives a device that failed go-live validation: forces an Intune/MDM sync so the site's
        baseline, app, and printer assignments re-apply and re-evaluate. Runs in preview mode by
        default; pass -Apply (or -WhatIf:$false) to actually perform the sync.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\NEWSITE-Remediation.ps1
        Apply the remediation:
            powershell -ExecutionPolicy Bypass -File .\NEWSITE-Remediation.ps1 -Apply
    EXPECTED RESULTS
        In preview: a list of the actions that would run. With -Apply: an MDM sync is requested;
        re-run NEWSITE-Validation.ps1 after a policy cycle.
.NOTES
    New-Site Endpoint Rollout Playbook. Defaults to -WhatIf (safe preview).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$Apply
)

# Default to preview unless -Apply is given.
if (-not $Apply -and -not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "`n=== New-Site Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# Sanity warnings (read-only) before any action
$dsreg = (dsregcmd /status) 2>$null
if (-not ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES')) {
    Write-Host "  WARNING: device is not Entra ID joined — fix enrollment before remediation will help." -ForegroundColor Yellow
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Trigger Intune/MDM sync to re-apply site assignments")) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" `
        -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested — baseline, app, and printer assignments will re-evaluate." -ForegroundColor Green
    Write-Host "  Re-run NEWSITE-Validation.ps1 after a policy cycle." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would trigger an MDM sync to re-apply the site's baseline, app, and printer assignments." -ForegroundColor Yellow
    Write-Host "  Run again with -Apply to perform the remediation." -ForegroundColor Yellow
}
