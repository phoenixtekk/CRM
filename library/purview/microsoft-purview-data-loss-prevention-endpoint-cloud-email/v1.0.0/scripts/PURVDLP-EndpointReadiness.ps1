<#
.SYNOPSIS
    PURVDLP-EndpointReadiness.ps1 — read-only Endpoint-DLP onboarding/readiness checker.
.DESCRIPTION
    PURPOSE
        Checks whether Endpoint DLP can actually function before you scope a Devices-location policy:
        (1) licensing signals for Endpoint DLP (E5 / E5 Compliance service plans) from Microsoft Graph,
        (2) whether any existing DLP policy uses the Endpoint (Devices) location, and (3) an
        environmental device-count signal (MDM/Intune-enrolled devices via Graph) as context. Read-only.
        NOTE: authoritative Purview device-onboarding state is viewed in the Purview portal
        (Settings > Device onboarding); enrolled-device counts here are context, not proof of onboarding.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVDLP-EndpointReadiness.ps1
        Requires Microsoft Graph PowerShell (Organization.Read.All; DeviceManagementManagedDevices.Read.All
        for the device-count signal) and Security & Compliance PowerShell (Connect-IPPSSession) for the
        policy-location check.
    EXPECTED RESULTS
        A readiness summary. PASS signal: an Endpoint-DLP-capable plan is present AND devices are
        onboarded per the portal. FAIL/verify signal: no capable plan, or the Devices location is
        unavailable — resolve licensing/onboarding (Req 2.1/2.3) before building endpoint policies.
.NOTES
    Purview — Data Loss Prevention (Endpoint). Read-only. Verify final onboarding state in the Purview portal.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName
)

Write-Host '=== Endpoint DLP Readiness (read-only) ===' -ForegroundColor Cyan

# --- 1) Licensing signal via Graph subscribedSkus ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
try {
    Connect-MgGraph -Scopes 'Organization.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome -ErrorAction Stop
    $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
    # Service plans associated with advanced compliance / Endpoint DLP (indicative — verify in admin center):
    $capablePlans = 'INFORMATION_BARRIERS','MIP_S_CLP2','M365_ADVANCED_AUDITING','Content_Explorer','MICROSOFTENDPOINTDLP','INFO_GOVERNANCE'
    $found = @()
    foreach ($s in $skus) {
        foreach ($sp in $s.servicePlans) {
            if ($capablePlans -contains $sp.servicePlanName -and $sp.provisioningStatus -eq 'Success') { $found += $sp.servicePlanName }
        }
    }
    $found = $found | Select-Object -Unique
    if ($found -contains 'MICROSOFTENDPOINTDLP') {
        Write-Host 'Licensing: MICROSOFTENDPOINTDLP service plan present — Endpoint DLP capable.' -ForegroundColor Green
    } elseif ($found.Count -gt 0) {
        Write-Host ("Licensing: advanced-compliance plans present ({0}) — likely E5/E5 Compliance; CONFIRM Endpoint DLP in admin center." -f ($found -join ', ')) -ForegroundColor Yellow
    } else {
        Write-Host 'Licensing: no Endpoint-DLP service-plan signal found — VERIFY your licensing (E5 / E5 Compliance).' -ForegroundColor Red
    }

    # --- 3) Environmental device-count signal (Intune/MDM managed devices) ---
    try {
        $devCount = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/managedDevices/$count' -Headers @{ ConsistencyLevel = 'eventual' })
        Write-Host ("Context: {0} MDM/Intune-enrolled device(s) in the tenant (NOT proof of Purview onboarding)." -f $devCount)
    } catch {
        Write-Host 'Context: could not read managed-device count (scope/permission) — check onboarding in the Purview portal.' -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Graph check skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- 2) Does any DLP policy use the Endpoint (Devices) location? ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}
$endpointPolicies = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue |
    Where-Object { $_.EndpointDlpLocation -and $_.EndpointDlpLocation.Count -gt 0 }
if ($endpointPolicies) {
    Write-Host ("Endpoint location in use by {0} policy(ies):" -f (@($endpointPolicies).Count)) -ForegroundColor Cyan
    $endpointPolicies | Select-Object Name, Mode | Format-Table -AutoSize
} else {
    Write-Host 'No DLP policy currently targets the Endpoint (Devices) location.' -ForegroundColor Yellow
}

Write-Host '--------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host 'ACTION: confirm onboarded devices in Purview portal > Settings > Device onboarding before' -ForegroundColor Cyan
Write-Host 'scoping any Devices-location policy. A Devices policy is inert until devices are onboarded.' -ForegroundColor Cyan
