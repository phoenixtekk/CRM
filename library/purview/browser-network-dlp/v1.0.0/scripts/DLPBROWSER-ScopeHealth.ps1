<#
.SYNOPSIS
    DLPBROWSER-ScopeHealth.ps1 — report device onboarding, browser-extension, network-path coverage and licensing readiness flags for Browser & Network DLP (read-only).
.DESCRIPTION
    PURPOSE
        Readiness/scope helper for Browser & Network DLP. Reports the Endpoint DLP–bearing licensing signal
        (subscribedSkus via Graph), managed-device signals (a proxy for onboarding readiness), pilot
        user/security group membership, the current Devices-location scope of the policy, and a readiness
        CHECKLIST for the coverage that has no direct PowerShell read — the Microsoft Purview browser
        extension (Chrome/Firefox), native Edge integration, and any network-DLP path. Read-only; it never
        changes scope (it prints the command for you to run under change control).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Microsoft Graph and (optionally) Security & Compliance PowerShell:
          Connect-MgGraph -Scopes "Organization.Read.All","Device.Read.All","Group.Read.All"
          Connect-IPPSSession            # optional, to read the policy scope
          .\DLPBROWSER-ScopeHealth.ps1
          .\DLPBROWSER-ScopeHealth.ps1 -PilotGroup "SG-DLPBROWSER-Pilot"
    EXPECTED RESULTS
        A console summary: Endpoint DLP licensing flag, managed-device count (Graph), pilot-group membership,
        the policy's current Devices scope, and a printed extension/Edge/network-path readiness checklist.
        Confirm actual device ONBOARDING and EXTENSION deployment in the Purview portal / your MDM (no
        PowerShell equivalent).
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Uses standard Microsoft Graph
    (Get-MgSubscribedSku / Get-MgDeviceManagementManagedDevice / Get-MgGroup) and Get-DlpCompliancePolicy;
    none invented. Graph managed-device data and the SKU flag are PROXIES/readiness signals — Endpoint DLP
    onboarding, browser-extension presence, and network-DLP coverage are confirmed in the Purview portal /
    your MDM, and the SKU-to-capability mapping is licensing-dependent (verify against your plan).
#>
[CmdletBinding()]
param(
    [string]$PilotGroup = "SG-DLPBROWSER-Pilot",
    [string]$PolicyName = "Browser & Network DLP - Devices - Pilot"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPBROWSER ScopeHealth — onboarding / extension / network / licensing readiness (read-only) ===" -ForegroundColor Cyan

# --- Graph: Endpoint DLP licensing signal (subscribedSkus) ---
try {
    $ctx = Get-MgContext -ErrorAction Stop
    if ($null -eq $ctx) { throw "no context" }
    try {
        $skus = Get-MgSubscribedSku -All -ErrorAction Stop
        # Endpoint DLP is carried by E5 / E5 Compliance / E5 Information Protection & Governance SKUs.
        # SKU part numbers vary by tenant/agreement — match on common fragments and FLAG for verification.
        $e5Like = @($skus | Where-Object { $_.SkuPartNumber -match 'E5|COMPLIANCE|INFORMATION_PROTECTION|IP_GOVERNANCE|EQUIVIO|EOP_ENTERPRISE_PREMIUM' })
        if (@($e5Like).Count -gt 0) {
            Write-Host ("  Endpoint DLP–bearing SKU signal: PRESENT (verify against your plan): {0}" -f (@($e5Like | Select-Object -ExpandProperty SkuPartNumber) -join ', ')) -ForegroundColor Green
        } else {
            Write-Host "  Endpoint DLP–bearing SKU signal: NOT DETECTED by name-match — VERIFY licensing (E5 / E5 Compliance / E5 IP&G) in the admin center." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  WARN: could not read subscribedSkus (scope Organization.Read.All?): $($_.Exception.Message)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Microsoft Graph not connected. Run Connect-MgGraph -Scopes 'Organization.Read.All','Device.Read.All','Group.Read.All' for licensing/device signals." -ForegroundColor Yellow
}

# --- Graph: managed devices (proxy for onboarding readiness) ---
try {
    if (Get-MgContext -ErrorAction SilentlyContinue) {
        try {
            $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop |
                        Where-Object { $_.OperatingSystem -match "Windows|macOS|OS X" }
            Write-Host ("  Managed devices (Graph/Intune, Windows/macOS): {0}" -f @($devices).Count) -ForegroundColor Green
            $byOs = $devices | Group-Object OperatingSystem | Sort-Object Count -Descending
            foreach ($o in $byOs) { Write-Host ("    OS {0,-12} : {1}" -f $o.Name, $o.Count) -ForegroundColor Gray }
            Write-Host "  (Managed-device counts are a PROXY. Confirm Endpoint DLP onboarding in Purview > Settings > Device onboarding.)" -ForegroundColor DarkYellow
        } catch {
            Write-Host "  WARN: could not read managed devices (scope Device.Read.All / DeviceManagementManagedDevices.Read.All?): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} catch { Write-Host "  WARN: managed-device read failed: $($_.Exception.Message)" -ForegroundColor Yellow }

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
        Write-Host ("  Policy '{0}' not found (run DLPBROWSER-Configure.ps1 -Commit first)." -f $PolicyName) -ForegroundColor Yellow
    }
} catch {
    Write-Host "  (S&C PowerShell not connected — skipping policy-scope read. Connect-IPPSSession to include it.)" -ForegroundColor Gray
}

# --- Coverage checklist that has NO direct PowerShell read (confirm by hand) ---
Write-Host "`n  Coverage readiness checklist (no PowerShell read — verify in portal / MDM):" -ForegroundColor Cyan
Write-Host "    [ ] Devices ONBOARDED to Purview (Settings > Device onboarding)." -ForegroundColor Gray
Write-Host "    [ ] Microsoft Purview browser EXTENSION deployed + enabled on Chrome and Firefox (enterprise browser policy)." -ForegroundColor Gray
Write-Host "    [ ] Microsoft Edge NATIVE integration relied upon (no extension needed) — confirm on a pilot device." -ForegroundColor Gray
Write-Host "    [ ] Unallowed-browsers list set so sensitive items can't move through an uninspected browser." -ForegroundColor Gray
Write-Host "    [ ] Network-DLP path (if in scope) covered per your design — verify availability against your licensing/tenant." -ForegroundColor Gray

Write-Host "`nScopeHealth complete. Confirm onboarding/extension in the portal; then DLPBROWSER-Validate.ps1 for configuration gates." -ForegroundColor Cyan
