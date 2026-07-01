<#
.SYNOPSIS
    TPP-Remediation.ps1 — safely nudge a device whose third-party app update is stuck.
.DESCRIPTION
    PURPOSE
        Forces an Intune/MDM sync so app assignments re-apply and restarts the Intune Management
        Extension service so it re-evaluates Win32 app installs (the mechanism that delivers packaged
        third-party updates). Runs in preview mode by default and changes nothing until you opt in.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\TPP-Remediation.ps1
        Act:               powershell -ExecutionPolicy Bypass -File .\TPP-Remediation.ps1 -WhatIf:$false
        Run elevated. After it acts, allow a policy cycle, then re-run TPP-Validation.ps1.
    EXPECTED RESULTS
        With -WhatIf (default): a list of the actions it WOULD take, no changes made.
        With -WhatIf:$false: an MDM sync requested and the Intune Management Extension restarted.
.NOTES
    Workplace Marketplace — Intune Solutions. Defaults to -WhatIf (no changes).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param()

# Default to preview unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== Third-party update remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "(preview mode — no changes will be made; re-run with -WhatIf:`$false to act)" -ForegroundColor DarkGray }

# 1) Force an MDM sync so app assignments re-apply.
if ($PSCmdlet.ShouldProcess('this device', 'Request MDM sync (deviceenroller /c /AutoEnrollMDM)')) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

# 2) Restart the Intune Management Extension so Win32 app installs are re-evaluated.
$svc = Get-Service -Name 'IntuneManagementExtension' -ErrorAction SilentlyContinue
if ($svc) {
    if ($PSCmdlet.ShouldProcess('IntuneManagementExtension service', 'Restart-Service')) {
        Restart-Service -Name 'IntuneManagementExtension' -Force -ErrorAction SilentlyContinue
        Write-Host "  Intune Management Extension restarted (Win32 apps will re-evaluate)." -ForegroundColor Green
    }
} else {
    Write-Host "  Intune Management Extension service not found — confirm the device is Intune-managed." -ForegroundColor Yellow
}

Write-Host "`nAfter a policy cycle, re-run TPP-Validation.ps1 to confirm the update applied." -ForegroundColor Green
