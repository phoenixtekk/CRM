<#
.SYNOPSIS
    DLPUSB-ScopeHealth.ps1 — report onboarding/scope health and preview pilot-scope targeting for removable-media DLP (read-only; -WhatIf for any scope change).
.DESCRIPTION
    PURPOSE
        Scope and health helper for USB / removable-media DLP. Reports managed-device signals from Microsoft
        Graph (a proxy for onboarding readiness), summarizes the pilot user/security group membership, and
        shows the current Devices-location scope of the removable-media Endpoint DLP policy — so you can see
        what the policy WOULD cover before you widen it. Read-only by default; any scope change is
        preview-only via -WhatIf (this tool does not itself widen scope — it prints the command for you to run
        under change control).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Microsoft Graph and (optionally) Security & Compliance PowerShell:
          Connect-MgGraph -Scopes "Device.Read.All","Group.Read.All"
          Connect-IPPSSession            # optional, to read the policy scope
          .\DLPUSB-ScopeHealth.ps1
          .\DLPUSB-ScopeHealth.ps1 -PilotGroup "SG-USB-Pilot" -WhatIf
    EXPECTED RESULTS
        A console summary: managed-device count (Graph), pilot-group membership, and the policy's current
        Devices scope. With -WhatIf, a PREVIEW of the scope-widening command (nothing is changed). Confirm
        actual device ONBOARDING in Purview portal > Settings > Device onboarding (no PowerShell equivalent).
.NOTES
    White-label Microsoft Purview tooling. Read-only / -WhatIf only. No credentials stored. Uses standard
    Microsoft Graph (Get-MgDeviceManagementManagedDevice / Get-MgGroup) and Get-DlpCompliancePolicy; none
    invented. Graph managed-device data is a PROXY for onboarding readiness — Endpoint DLP onboarding status
    itself is confirmed in the Purview portal.
#>
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [string]$PilotGroup = "SG-USB-Pilot",
    [string]$PolicyName = "EDLP-USB-Pilot"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPUSB ScopeHealth — onboarding/scope signals (read-only) ===" -ForegroundColor Cyan

# --- Graph: managed devices (proxy for onboarding readiness) ---
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($null -eq $ctx) { throw "no context" }
    try {
        $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop
        $count = @($devices).Count
        Write-Host ("  Managed devices (Graph/Intune): {0}" -f $count) -ForegroundColor Green
        $byOs = $devices | Group-Object OperatingSystem | Sort-Object Count -Descending | Select-Object -First 5
        foreach ($o in $byOs) { Write-Host ("    OS {0,-16} : {1}" -f $o.Name, $o.Count) -ForegroundColor Gray }
        Write-Host "  (Managed-device counts are a PROXY. Confirm Endpoint DLP onboarding in Purview > Settings > Device onboarding.)" -ForegroundColor DarkYellow
    } catch {
        Write-Host "  WARN: could not read managed devices (scope Device.Read.All / DeviceManagementManagedDevices.Read.All?): $($_.Exception.Message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Microsoft Graph not connected. Run Connect-MgGraph -Scopes 'Device.Read.All','Group.Read.All' for device/group signals." -ForegroundColor Yellow
}

# --- Graph: pilot group membership ---
try {
    if (Get-MgContext -ErrorAction SilentlyContinue) {
        $grp = Get-MgGroup -Filter "displayName eq '$PilotGroup'" -ErrorAction Stop
        if ($grp) {
            $members = Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction Stop
            Write-Host ("  Pilot group '{0}' members: {1}" -f $PilotGroup, @($members).Count) -ForegroundColor Green
        } else {
            Write-Host ("  Pilot group '{0}' not found — create it before scoping the pilot." -f $PilotGroup) -ForegroundColor Yellow
        }
    }
} catch { Write-Host "  WARN: could not read pilot group: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- S&C PowerShell: current Devices scope of the policy ---
try {
    Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($pol) {
        $scope = @($pol.EndpointDlpLocation) -join ", "
        if ([string]::IsNullOrWhiteSpace($scope)) { $scope = "(none)" }
        Write-Host ("  Policy '{0}' current Devices scope: {1}  (Mode={2})" -f $PolicyName, $scope, $pol.Mode) -ForegroundColor Green
        if (@($pol.EndpointDlpLocation) -contains "All") { Write-Host "    NOTE: scope is ALL devices — confirm this is intended (post-pilot only)." -ForegroundColor Yellow }
    } else {
        Write-Host ("  Policy '{0}' not found (run DLPUSB-Configure.ps1 -Commit first)." -f $PolicyName) -ForegroundColor Yellow
    }
} catch {
    Write-Host "  (S&C PowerShell not connected — skipping policy-scope read. Connect-IPPSSession to include it.)" -ForegroundColor Gray
}

# --- Scope-change PREVIEW only (this tool never widens scope itself) ---
if ($WhatIf) {
    Write-Host "`n  -WhatIf PREVIEW — to widen the pilot scope, run this yourself under change control:" -ForegroundColor Cyan
    Write-Host ("    Set-DlpCompliancePolicy -Identity '{0}' -EndpointDlpLocation '{1}'" -f $PolicyName, $PilotGroup) -ForegroundColor Gray
    Write-Host "  (No change was made. Validate with DLPUSB-Validate.ps1 after any scope change; widen the device-control assignment in your management tool too.)" -ForegroundColor DarkYellow
}

Write-Host "`nScopeHealth complete. Confirm onboarding in the portal; then DLPUSB-Validate.ps1 for configuration gates." -ForegroundColor Cyan
