<#
.SYNOPSIS
    CVPNMIG-Remediation.ps1 — safely clean up legacy Cisco VPN artifacts / fix double-deployment conflicts.
.DESCRIPTION
    PURPOSE
        For a device that has been cut over to Intune but still shows legacy residue — a lingering GPO
        applying Cisco policy, a stale duplicate profile XML, or a reinstall loop from two authorities —
        this previews and (with -Execute) performs safe fixes: forces a Group Policy refresh so a
        removed GPO stops applying, triggers an Intune/MDM sync so the client re-evaluates cleanly, and
        reports duplicate profile XML files for review. Default is preview (-WhatIf); no deletes.
        Removing the device from the SCCM collection / GPO scope is done in the consoles, not here.
    HOW TO RUN
        Elevated on the affected device. Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Remediation.ps1
        Apply the safe fixes:
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Remediation.ps1 -Execute
        (No Graph scopes required — local device actions only.)
    EXPECTED RESULTS
        In preview: the actions that would run and any duplicate profile XML flagged. With -Execute: a
        Group Policy refresh and an MDM sync requested so a removed legacy path stops re-asserting.
        Re-run CVPNMIG-Validation.ps1 / CVPNMIG-Discovery.ps1 after a policy cycle to confirm.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param([switch]$Execute)
$whatIf = -not $Execute
Write-Host "=== CVPNMIG Remediation — $($env:COMPUTERNAME) ($(if ($whatIf) { 'PREVIEW / -WhatIf' } else { 'EXECUTE' })) ===" -ForegroundColor Cyan

# --- 1. Refresh Group Policy so an unlinked/descoped legacy GPO stops applying ---
if ($whatIf) { Write-Host "  [WhatIf] Would run 'gpupdate /force' so a removed Cisco GPO stops applying." -ForegroundColor Yellow }
else { Start-Process -FilePath "$env:WINDIR\System32\gpupdate.exe" -ArgumentList '/force' -WindowStyle Hidden; Write-Host "  Group Policy refresh requested." -ForegroundColor Green }

# --- 2. Trigger an MDM sync so the Intune client/profile/cert re-evaluate cleanly ---
if ($whatIf) { Write-Host "  [WhatIf] Would request an MDM sync (deviceenroller.exe /c /AutoEnrollMDM)." -ForegroundColor Yellow }
else {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList '/c /AutoEnrollMDM' -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

# --- 3. Flag duplicate / stale profile XML for review (never auto-deleted) ---
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profiles = Get-ChildItem -Path $profileDirs -Filter *.xml -ErrorAction SilentlyContinue
if ($profiles.Count -gt 1) {
    Write-Host ("  Found {0} profile XML files — a stale legacy profile may conflict with the Intune one:" -f $profiles.Count) -ForegroundColor Yellow
    $profiles | ForEach-Object { Write-Host ("    {0}  (modified {1})" -f $_.FullName, $_.LastWriteTime) -ForegroundColor Yellow }
    Write-Host "  Review and remove the stale profile manually after confirming which is the Intune-delivered one." -ForegroundColor Yellow
} else {
    Write-Host ("  Profile XML files present: {0} (no duplicate to reconcile)." -f $profiles.Count) -ForegroundColor Green
}

# --- 4. Report the IntuneManagementExtension service (reinstall-loop diagnostics) ---
$ime = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if (-not $ime) { Write-Host "  Intune Management Extension service not found (is the device enrolled?)." -ForegroundColor Yellow }
elseif ($whatIf) { Write-Host "  [WhatIf] Would restart IntuneManagementExtension to break a stuck re-evaluation loop." -ForegroundColor Yellow }
else { Restart-Service -Name IntuneManagementExtension -Force; Write-Host "  IntuneManagementExtension restarted; app re-evaluates once." -ForegroundColor Green }

Write-Host "`nReminder: remove the device from the SCCM collection and the GPO scope in the consoles — this script only clears local residue." -ForegroundColor Cyan
Write-Host "Re-run CVPNMIG-Validation.ps1 and CVPNMIG-Discovery.ps1 after a policy cycle to confirm Intune-only." -ForegroundColor Green
if ($whatIf) { Write-Host "No changes made (preview). Re-run with -Execute to apply." -ForegroundColor Cyan }
