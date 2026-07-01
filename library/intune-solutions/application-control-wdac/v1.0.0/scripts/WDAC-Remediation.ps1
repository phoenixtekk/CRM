<#
.SYNOPSIS
    WDAC-Remediation.ps1 — recovery for an over-strict App Control policy: refresh/clear and sync.
.DESCRIPTION
    PURPOSE
        After you UNASSIGN the App Control policy in Intune, this forces an MDM sync so the removal
        reaches the device, and (Windows 11) refreshes the local policy set with citool. Use it to
        recover a device that was over-restricted under Enforce. A reboot may be required to fully clear.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WDAC-Remediation.ps1
    EXPECTED RESULTS
        MDM sync requested; local policy refreshed. Reboot if a policy persists, then WDAC-Validation.ps1.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Unassign the Intune policy FIRST.
#>
[CmdletBinding()] param()
Write-Host "=== WDAC Remediation / Recovery — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Write-Host "Step 1: ensure the App Control policy is UNASSIGNED in Intune for this device's group." -ForegroundColor Yellow
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "  MDM sync requested (delivers the policy removal)." -ForegroundColor Green
$citool = "$env:WINDIR\System32\citool.exe"
if (Test-Path $citool) {
    try { & $citool --refresh 2>$null; Write-Host "  citool --refresh issued." -ForegroundColor Green } catch {}
    Write-Host "  Current active policies:" -ForegroundColor Cyan
    & $citool --list-policies 2>$null | Select-String 'FriendlyName|IsEnforced' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
} else {
    Write-Host "  (Windows 10: policy clears on next sync; a reboot may be required.)" -ForegroundColor Gray
}
Write-Host "`nIf a policy persists, reboot, then run WDAC-Validation.ps1." -ForegroundColor Green
