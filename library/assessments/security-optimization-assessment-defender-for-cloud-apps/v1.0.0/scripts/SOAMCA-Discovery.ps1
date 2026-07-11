<#
.SYNOPSIS
    SOAMCA-Discovery.ps1 — read-only discovery of Defender for Cloud Apps configuration (connectors,
    discovery sources, policy inventory, alert state); saves the assessment baseline.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Security Optimization Assessment — Defender for Cloud Apps"
        solution. Enumerates, via Microsoft Graph (Security) and directory read APIs: app/API
        connectors, cloud-discovery data sources, the Cloud Apps policy inventory (app-governance/
        OAuth, session, access, activity, file, anomaly), and current alert state. Writes a single
        JSON snapshot used as the assessment baseline (`Posture Baseline - Cloud Apps - Assess`).
        Makes NO changes to the tenant.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Application.Read.All","Directory.Read.All"
        powershell -ExecutionPolicy Bypass -File .\SOAMCA-Discovery.ps1 `
            -OutputPath ".\Posture Baseline - Cloud Apps - Assess.json"
        Requires the Microsoft.Graph module and a read-only role (Security Reader / Global Reader).
    EXPECTED RESULTS
        A JSON baseline with four domain sections (connectors/discovery, app-governance/OAuth,
        session/access, alerts) — the point-in-time evidence the rest of the assessment scores.
.NOTES
    White-label. Read-only — reports configuration/identifiers only; makes no changes.
    Licensing/plan/preview facts are indicative — verify current availability in your tenant.
    Some Cloud Apps configuration is not fully exposed via Graph; where an area cannot be read
    programmatically the script records it for manual confirmation in the portal.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\Posture Baseline - Cloud Apps - Assess.json"
)

$ErrorActionPreference = 'Stop'

function Connect-IfNeeded {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host "Installing Microsoft.Graph (one-time, CurrentUser)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) {
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Application.Read.All","Directory.Read.All" | Out-Null
    }
}

function Invoke-GraphGet {
    param([string]$Uri)
    # Read-only GET with basic paging and throttle-friendly retry.
    $results = @()
    $next = $Uri
    while ($next) {
        try {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop
        } catch {
            Write-Warning "GET $next failed: $($_.Exception.Message)"
            break
        }
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-IfNeeded
Write-Host "SOAMCA-Discovery — read-only. Signed in as: $((Get-MgContext).Account)" -ForegroundColor Cyan

$baseline = [ordered]@{
    solution      = "SOAMCA"
    generatedUtc  = (Get-Date).ToUniversalTime().ToString("o")
    tenant        = (Get-MgContext).TenantId
    readOnly      = $true
    scopesUsed    = (Get-MgContext).Scopes
    domains       = [ordered]@{}
    manualChecks  = @()
}

# --- Domain 1: Connector & discovery coverage -----------------------------------------------------
# OAuth/service-principal footprint stands in for connected-app breadth that Graph can read directly.
$servicePrincipals = Invoke-GraphGet "https://graph.microsoft.com/v1.0/servicePrincipals?`$select=id,appId,displayName,accountEnabled,publisherName,servicePrincipalType&`$top=100"
$baseline.domains["connectorsDiscovery"] = [ordered]@{
    servicePrincipalCount = ($servicePrincipals | Measure-Object).Count
    servicePrincipals     = @($servicePrincipals | Select-Object displayName, appId, servicePrincipalType, publisherName)
    note                  = "Cloud-discovery data sources (automatic log upload / Defender for Endpoint integration) and API connectors must also be confirmed in the portal: Cloud apps -> Cloud discovery -> Settings."
}
$baseline.manualChecks += "Confirm cloud-discovery ingestion method (continuous automatic log upload vs manual snapshots vs MDE integration) in the Defender portal."
$baseline.manualChecks += "Confirm which sanctioned/unsanctioned app tags are applied in Cloud discovery."

# --- Domain 2: App-governance & OAuth policies ----------------------------------------------------
# Enumerate OAuth grants (delegated + app role assignments) as the app-governance evidence surface.
$oauthGrants = Invoke-GraphGet "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$top=100"
$baseline.domains["appGovernanceOAuth"] = [ordered]@{
    oauth2PermissionGrantCount = ($oauthGrants | Measure-Object).Count
    note = "App governance is a licensed add-on (verify entitlement). Its OAuth-app policies are confirmed under Cloud apps -> App governance. This section captures the raw OAuth grant footprint scored by SOAMCA-OAuthAudit.ps1."
}
$baseline.manualChecks += "Confirm App governance is licensed and enabled (Cloud apps -> App governance). Verify current entitlement."
$baseline.manualChecks += "Confirm OAuth-app policies exist for over-permissioned / unverified-publisher / dormant apps."

# --- Domain 3 & 4: Session/access policies + alerts (portal-confirmed) -----------------------------
# The Cloud Apps policy set and alert tuning are not fully exposed as a single Graph object across
# tenants; record them as manual confirmations so scoring reflects verified state rather than guesses.
$baseline.domains["sessionAccessPolicies"] = [ordered]@{
    note = "Confirm Conditional Access App Control session and access policies in the Defender portal (Cloud apps -> Policies -> Policy management). Record counts + whether piloted before enforcement."
}
$baseline.manualChecks += "Record count of session policies and access policies, and whether each was piloted (monitor) before enforce."

# Security alerts (Graph security API) as the alert-hygiene evidence.
$alerts = Invoke-GraphGet "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=100"
$open = @($alerts | Where-Object { $_.status -in @('new','inProgress') })
$baseline.domains["alertHygiene"] = [ordered]@{
    totalAlertsSampled = ($alerts | Measure-Object).Count
    openAlerts         = ($open | Measure-Object).Count
    bySeverity         = ($alerts | Group-Object severity | ForEach-Object { @{ severity = $_.Name; count = $_.Count } })
    note               = "Cloud Apps alert policies are tuned under Cloud apps -> Policies. A large open backlog indicates alerts are not being resolved."
}
$baseline.manualChecks += "Confirm alert policies are tuned (severity/scope/exclusions) and that open alerts are being resolved (not a growing backlog)."

$baseline | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Baseline written: $OutputPath" -ForegroundColor Green
Write-Host "Manual portal confirmations required: $($baseline.manualChecks.Count) (see 'manualChecks' in the JSON)." -ForegroundColor Yellow
Write-Host "This script made NO changes to the tenant." -ForegroundColor Green
