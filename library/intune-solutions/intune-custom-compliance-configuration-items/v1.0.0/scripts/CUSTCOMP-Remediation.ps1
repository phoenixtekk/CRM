<#
.SYNOPSIS
    CUSTCOMP-Remediation.ps1 — safely force an MDM sync so the custom compliance policy re-evaluates.
.DESCRIPTION
    PURPOSE
        Triggers an Intune/MDM sync so the custom compliance detection script and config item
        re-apply and the device re-reports its state. Defaults to -WhatIf: it shows what it would do
        and changes nothing until you pass -WhatIf:$false (or -Confirm:$false).
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\CUSTCOMP-Remediation.ps1
        Apply:             powershell -ExecutionPolicy Bypass -File .\CUSTCOMP-Remediation.ps1 -WhatIf:$false
    EXPECTED RESULTS
        In preview, the actions it would take. When applied, an MDM sync is requested; re-run
        CUSTCOMP-Report.ps1 / check the portal after a policy cycle.
.NOTES
    White-label — Intune Solutions. Default -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param()
# Default to -WhatIf unless the caller explicitly turned it off
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm')) { $WhatIfPreference = $true }
Write-Host "=== Custom Compliance Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (preview mode — pass -WhatIf:`$false to apply)" -ForegroundColor Yellow }

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Request MDM sync (deviceenroller /AutoEnrollMDM)")) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Restart IntuneManagementExtension service to re-run detection")) {
    try { Restart-Service -Name IntuneManagementExtension -ErrorAction Stop; Write-Host "  IntuneManagementExtension restarted." -ForegroundColor Green }
    catch { Write-Host "  Could not restart IntuneManagementExtension: $($_.Exception.Message)" -ForegroundColor Yellow }
}
Write-Host "`nAfter a policy cycle, re-check with CUSTCOMP-Report.ps1 or the Intune portal." -ForegroundColor Green
