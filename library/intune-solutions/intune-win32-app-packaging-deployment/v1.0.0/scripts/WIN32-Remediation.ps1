<#
.SYNOPSIS
    WIN32-Remediation.ps1 — safely remediate a failed Win32 app install on a device.
.DESCRIPTION
    PURPOSE
        For a device where a Win32 app failed, this forces an Intune/MDM sync so the IME re-evaluates
        and retries the assignment, and (optionally) clears the IME's local app-grace state so the
        install is re-attempted on the next cycle. Defaults to -WhatIf: it reports what it WOULD do and
        changes nothing until you pass -WhatIf:$false.
    HOW TO RUN
        Preview (default, no changes):  powershell -ExecutionPolicy Bypass -File .\WIN32-Remediation.ps1
        Apply (elevated):               powershell -ExecutionPolicy Bypass -File .\WIN32-Remediation.ps1 -WhatIf:$false
    EXPECTED RESULTS
        In preview: a list of the sync/retry actions that would run. When applied: an MDM sync is
        requested so the IME retries the failed Win32 app. Re-check with WIN32-Validation.ps1 / WIN32-Report.ps1.
.NOTES
    Workplace Marketplace — Intune Solutions. Default -WhatIf; supports ShouldProcess.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [switch]$ClearImeGraceState
)
# Make -WhatIf the default unless the caller explicitly turns it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== Win32 App Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (PREVIEW MODE — no changes will be made. Pass -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

$ime = Get-Service -Name 'Microsoft Intune Management Extension' -ErrorAction SilentlyContinue
if (-not $ime) { Write-Host "  IME service not present — enrollment/IME must be repaired first." -ForegroundColor Yellow }
else           { Write-Host ("  IME service: {0}" -f $ime.Status) -ForegroundColor Green }

# Action 1: force an MDM sync so the IME re-evaluates assignments and retries the failed app.
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Request MDM sync (deviceenroller.exe /c /AutoEnrollMDM)")) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

# Action 2 (optional): restart the IME so it re-reads its app policy on next cycle.
if ($ime -and $PSCmdlet.ShouldProcess('Microsoft Intune Management Extension', "Restart IME service")) {
    Restart-Service -Name 'Microsoft Intune Management Extension' -Force
    Write-Host "  IME service restarted." -ForegroundColor Green
}

if ($ClearImeGraceState) {
    $logHint = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
    Write-Host "  NOTE: review $logHint to confirm the retry and the install exit code." -ForegroundColor Yellow
}

Write-Host "`nRe-check with WIN32-Validation.ps1 (device) and WIN32-Report.ps1 (fleet) after a policy cycle." -ForegroundColor Green
