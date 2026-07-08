<#
.SYNOPSIS
    DLPCLIP-ScopeHealth.ps1 — report device onboarding + Endpoint DLP feature/licensing readiness for clipboard & screen-capture controls (read-only).
.DESCRIPTION
    PURPOSE
        Readiness helper for clipboard & screen-capture Endpoint DLP. Reports managed-device signals from
        Microsoft Graph (a PROXY for onboarding readiness), summarizes the pilot user/security group membership,
        shows the current Devices-location scope of the policy, and checks whether the Endpoint DLP settings and
        the copy-to-clipboard / screen-capture activities look available in the tenant — so you can see whether
        the endpoint is ready to enforce the two controls before you build/widen anything. Read-only.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Microsoft Graph and (optionally) Security & Compliance PowerShell:
          Connect-MgGraph -Scopes "Device.Read.All","Group.Read.All"
          Connect-IPPSSession            # optional, to read the policy scope + endpoint settings
          .\DLPCLIP-ScopeHealth.ps1
          .\DLPCLIP-ScopeHealth.ps1 -PilotGroup "DLP Pilot Ring - Stage1"
    EXPECTED RESULTS
        A console summary: managed-device count (Graph), pilot-group membership, the policy's current Devices
        scope, and an Endpoint-DLP-settings readability check. Confirm actual device ONBOARDING in Purview portal
        > Settings > Device onboarding (no PowerShell equivalent). Screen-capture readiness is flagged as
        newer/preview — verify your licensing/tenant.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses standard Microsoft Graph
    (Get-MgDeviceManagementManagedDevice / Get-MgGroup / Get-MgGroupMember) and Get-DlpCompliancePolicy /
    Get-PolicyConfig; none invented. Graph managed-device data is a PROXY for onboarding readiness — Endpoint DLP
    onboarding status itself is confirmed in the Purview portal. Screen-capture restriction is newer/preview.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup = "DLP Pilot Ring - Stage1",
    [string]$PolicyName = "DLP - Endpoint Clipboard+Screen - Simulation"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPCLIP ScopeHealth — onboarding + clipboard/screen-capture readiness (read-only) ===" -ForegroundColor Cyan

# --- Graph: managed devices (proxy for onboarding readiness) ---
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($null -eq $ctx) { throw "no context" }
    try {
        $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop
        $winCount = @($devices | Where-Object { $_.OperatingSystem -match "Windows" }).Count
        $macCount = @($devices | Where-Object { $_.OperatingSystem -match "macOS|OS X|Mac" }).Count
        Write-Host ("  Managed devices (Graph/Intune): {0}  (Windows: {1}, macOS: {2})" -f @($devices).Count, $winCount, $macCount) -ForegroundColor Green
        $byVer = $devices | Group-Object OSVersion | Sort-Object Count -Descending | Select-Object -First 5
        foreach ($v in $byVer) { Write-Host ("    OSVersion {0,-16} : {1}" -f $v.Name, $v.Count) -ForegroundColor Gray }
        Write-Host "  (Managed-device counts are a PROXY. Confirm Endpoint DLP onboarding in Purview > Settings > Device onboarding.)" -ForegroundColor DarkYellow
        Write-Host "  (Clipboard/screen-capture also require a supported minimum OS build — verify per Microsoft docs.)" -ForegroundColor DarkYellow
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

# --- S&C PowerShell: current Devices scope of the policy + Endpoint DLP settings readability ---
try {
    Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($pol) {
        $scope = @($pol.EndpointDlpLocation) -join ", "
        if ([string]::IsNullOrWhiteSpace($scope)) { $scope = "(none)" }
        Write-Host ("  Policy '{0}' current Devices scope: {1}  (Mode={2})" -f $PolicyName, $scope, $pol.Mode) -ForegroundColor Green
        if (@($pol.EndpointDlpLocation) -contains "All") { Write-Host "    NOTE: scope is ALL devices — confirm this is intended (post-pilot only)." -ForegroundColor Yellow }
    } else {
        Write-Host ("  Policy '{0}' not found (run DLPCLIP-Configure.ps1 -Commit first)." -f $PolicyName) -ForegroundColor Yellow
    }

    # Endpoint DLP settings readability (allowed/unallowed apps & browsers) — needed for false-positive control
    try {
        Get-PolicyConfig -ErrorAction Stop | Out-Null
        Write-Host "  Endpoint DLP settings: readable (Get-PolicyConfig). Review allowed/unallowed apps & browsers before enforcing." -ForegroundColor Green
    } catch {
        Write-Host "  NOTE: Endpoint DLP settings not readable here (role/tenant). Confirm allowed/unallowed apps & browsers in the portal." -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "  (S&C PowerShell not connected — skipping policy-scope + endpoint-settings read. Connect-IPPSSession to include them.)" -ForegroundColor Gray
}

Write-Host "`nReadiness reminders:" -ForegroundColor Cyan
Write-Host "  - CLIPBOARD restriction: verify E5 / E5 Compliance licensing and device onboarding." -ForegroundColor Cyan
Write-Host "  - SCREEN CAPTURE restriction: NEWER / MAY BE IN PREVIEW, OS-/app-gated — VERIFY YOUR LICENSING/TENANT; deliver clipboard first if unavailable." -ForegroundColor DarkYellow
Write-Host "Next: DLPCLIP-Validate.ps1 for the configuration gates once the policy is built in simulation." -ForegroundColor Cyan
