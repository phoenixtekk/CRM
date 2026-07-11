<#
.SYNOPSIS
    SOAXDR-Discovery.ps1 — read-only cross-pillar discovery of the Microsoft Defender suite (per-pillar
    onboarding signal, unified-RBAC assignments, incident-correlation evidence, Secure Score); saves
    the baseline.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Security Optimization Assessment — Microsoft Defender (Suite/XDR)"
        solution. Enumerates, via Microsoft Graph (Security) + directory reads and Az: per-pillar
        onboarding/licensing signal (endpoint/identity/email/cloud-apps/cloud), privileged directory-
        role assignments (unified-RBAC evidence), unified security alerts/incidents (correlation
        evidence), and Microsoft Secure Score. Writes a JSON baseline (`Posture Baseline - Defender
        Suite - Assess`). Makes NO changes.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","RoleManagement.Read.Directory","Directory.Read.All"
        Connect-AzAccount   # for the cloud pillar (optional if Azure not in use)
        powershell -ExecutionPolicy Bypass -File .\SOAXDR-Discovery.ps1 `
            -OutputPath ".\Posture Baseline - Defender Suite - Assess.json"
        Read-only roles: Security Reader / Global Reader.
    EXPECTED RESULTS
        A JSON baseline with four domain sections and a per-pillar coverage map — the evidence scored
        by the rest of the assessment.
.NOTES
    White-label. Read-only. Some per-pillar onboarding is confirmed in the portal Settings; where it
    cannot be read via Graph the script records a manual check. Licensing/preview facts flagged verify.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\Posture Baseline - Defender Suite - Assess.json",
    [switch]$SkipAzure
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph (one-time, CurrentUser)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "SecurityEvents.Read.All","RoleManagement.Read.Directory","Directory.Read.All" | Out-Null
}

function Invoke-GraphGet {
    param([string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        try { $resp = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop }
        catch { Write-Warning "GET $next failed: $($_.Exception.Message)"; break }
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Write-Host "SOAXDR-Discovery — read-only. Signed in as: $((Get-MgContext).Account)" -ForegroundColor Cyan

$baseline = [ordered]@{
    solution     = "SOAXDR"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    tenant       = (Get-MgContext).TenantId
    readOnly     = $true
    domains      = [ordered]@{}
    manualChecks = @()
}

# --- Domain: Suite-wide Secure Score + incident-correlation evidence ------------------------------
$secureScores = Invoke-GraphGet "https://graph.microsoft.com/v1.0/security/secureScores?`$top=1"
$latestScore = $secureScores | Select-Object -First 1
$baseline.domains["suiteSecureScore"] = [ordered]@{
    currentScore = $latestScore.currentScore
    maxScore     = $latestScore.maxScore
    percentage   = if ($latestScore.maxScore) { [math]::Round(($latestScore.currentScore / $latestScore.maxScore) * 100, 1) } else { $null }
    note         = "Microsoft Secure Score across the suite. Improvement actions are worked in the Defender portal."
}

$incidents = Invoke-GraphGet "https://graph.microsoft.com/v1.0/security/incidents?`$top=100"
# Multi-pillar incidents (correlation evidence) — incidents whose alerts span >1 service source.
$alerts = Invoke-GraphGet "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=200"
$sources = @($alerts | ForEach-Object { $_.serviceSource } | Where-Object { $_ } | Select-Object -Unique)
$baseline.domains["incidentCorrelation"] = [ordered]@{
    incidentsSampled   = ($incidents | Measure-Object).Count
    alertsSampled      = ($alerts | Measure-Object).Count
    distinctAlertSources = $sources
    distinctSourceCount  = ($sources | Measure-Object).Count
    note               = "Alerts spanning multiple serviceSource values indicate cross-pillar signal. A single source suggests only one pillar is feeding the queue."
}

# --- Domain: Unified RBAC (privileged directory-role assignments) ---------------------------------
$roleAssignments = Invoke-GraphGet "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments?`$top=200&`$expand=roleDefinition"
$privilegedRoleNames = @('Global Administrator','Security Administrator','Security Operator','Security Reader','Global Reader')
$privileged = @($roleAssignments | Where-Object { $_.roleDefinition.displayName -in $privilegedRoleNames })
$baseline.domains["unifiedRbac"] = [ordered]@{
    totalRoleAssignments      = ($roleAssignments | Measure-Object).Count
    securityRelevantAssignments = @($privileged | ForEach-Object { @{ role = $_.roleDefinition.displayName; principalId = $_.principalId } })
    globalAdminCount          = @($privileged | Where-Object { $_.roleDefinition.displayName -eq 'Global Administrator' }).Count
    note                      = "Whether Defender XDR Unified RBAC is ACTIVATED (vs legacy per-product permissions) is confirmed in Settings -> Permissions & roles — record via SOAXDR-Validate.ps1 -UnifiedRbacActivated. Verify current RBAC model availability."
}
$baseline.manualChecks += "Confirm whether Defender XDR Unified RBAC is activated (Settings -> Permissions & roles)."

# --- Domain: Cross-pillar coverage (per-pillar onboarding signal) ---------------------------------
# Graph does not expose a single 'is pillar X onboarded' flag uniformly; capture the signals we can
# read and require portal confirmation for the rest (recorded via SOAXDR-Validate -PillarsOnboarded).
$devices = Invoke-GraphGet "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$top=1"
$pillars = [ordered]@{
    endpoint  = @{ signal = "managed devices present: $(@($devices).Count -gt 0)"; confirmInPortal = "Settings -> Endpoints -> onboarding" }
    identity  = @{ signal = "confirm sensors in Settings -> Identities"; confirmInPortal = "Settings -> Identities -> sensors" }
    email     = @{ signal = "confirm MDO policies in Email & collaboration -> Policies"; confirmInPortal = "Email & collaboration -> Policies & rules" }
    cloudapps = @{ signal = "alert sources include cloudAppSecurity: $($sources -contains 'microsoftCloudAppSecurity' -or $sources -contains 'microsoftDefenderForCloudApps')"; confirmInPortal = "Cloud apps -> Connected apps" }
    cloud     = @{ signal = "confirm Defender for Cloud plans (see SOAMDC / Az)"; confirmInPortal = "portal.azure.com -> Defender for Cloud -> Environment settings" }
}
$baseline.domains["crossPillarCoverage"] = [ordered]@{
    pillars = $pillars
    note    = "Onboarding/licensing per pillar is confirmed in the portal and recorded via SOAXDR-Validate.ps1 -PillarsOnboarded. Deep single-pillar review is delegated to the dedicated assessments."
}
$baseline.manualChecks += "Confirm onboarding/licensing for each of the five pillars and pass the onboarded set to SOAXDR-Validate.ps1."

# --- Cloud pillar via Az (optional) ---------------------------------------------------------------
if (-not $SkipAzure) {
    try {
        Import-Module Az.Accounts -ErrorAction Stop
        if (Get-AzContext) {
            Import-Module Az.Security -ErrorAction SilentlyContinue
            $pricings = Get-AzSecurityPricing -ErrorAction SilentlyContinue
            $baseline["cloudPillarAz"] = @{ standardPlans = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' } | ForEach-Object { $_.Name }) }
        } else {
            $baseline["cloudPillarAz"] = @{ note = "No Az context — cloud pillar not read (mark N/A in scope if Azure not in use)." }
        }
    } catch { $baseline["cloudPillarAz"] = @{ note = "Az not available: $($_.Exception.Message)" } }
}

$baseline | ConvertTo-Json -Depth 9 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Baseline written: $OutputPath" -ForegroundColor Green
Write-Host "Manual portal confirmations required: $($baseline.manualChecks.Count) (see 'manualChecks')." -ForegroundColor Yellow
Write-Host "This script made NO changes to the tenant." -ForegroundColor Green
