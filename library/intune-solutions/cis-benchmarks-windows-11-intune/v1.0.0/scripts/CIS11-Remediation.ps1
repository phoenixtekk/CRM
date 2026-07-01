<#
.SYNOPSIS
    CIS11-Remediation.ps1 — safely reapply a drifted CIS Win11 baseline by forcing policy re-apply.
.DESCRIPTION
    PURPOSE
        When CIS11-Validation/CIS11-Report shows drift, this forces the Intune-managed baseline to
        re-apply to the device: it triggers an MDM sync so the CIS configuration policies re-evaluate
        and re-write their settings. It does NOT hand-edit individual security settings outside
        Intune — Intune remains the single source of truth.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\CIS11-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\CIS11-Remediation.ps1 -WhatIf:$false
    EXPECTED RESULTS
        With -WhatIf (default): prints the actions it WOULD take. With -WhatIf:$false: requests an
        MDM sync so the CIS policies re-apply. Re-run CIS11-Validation.ps1 after a policy cycle.
.NOTES
    Intune Solutions — CIS Win11. Defaults to -WhatIf (no change unless -WhatIf:$false).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param()

# Default to WhatIf unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== CIS Win11 Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (WhatIf mode — no changes will be made. Re-run with -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Warn on a conflicting local authority that would defeat reapply
$wsus = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -ErrorAction SilentlyContinue).UseWUServer
if ($wsus -eq 1) { Write-Host "  WARNING: local WSUS/GPO authority present — resolve the conflict or reapply may not stick." -ForegroundColor Yellow }

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Trigger Intune/MDM sync to re-apply CIS Win11 baseline")) {
    try {
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
        Write-Host "  MDM sync requested — CIS configuration policies will re-evaluate on the next cycle." -ForegroundColor Green
    } catch { Write-Host "  Sync trigger failed: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "`nRe-run CIS11-Validation.ps1 after a policy cycle to confirm the drift cleared." -ForegroundColor Green
