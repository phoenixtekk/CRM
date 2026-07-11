<#
.SYNOPSIS
    SOAMCA-Validate.ps1 — validate that recommended Defender for Cloud Apps best-practice controls are
    present across the four assessment domains; returns Pass/Gap with evidence. Read-only.
.DESCRIPTION
    PURPOSE
        Consumes the baseline produced by SOAMCA-Discovery.ps1 (plus the operator's portal-confirmed
        values) and evaluates, per domain, whether the recommended controls exist:
          - Connector & discovery coverage: core apps connected + continuous discovery ingestion
          - App-governance & OAuth: app governance enabled + OAuth-app policies present
          - Session & access: at least one session and one access policy, piloted before enforce
          - Alert hygiene: alert policies tuned + open backlog under control
        Each check returns Pass or Gap WITH the evidence. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAMCA-Validate.ps1 `
            -BaselinePath ".\Posture Baseline - Cloud Apps - Assess.json"
        Optional portal-confirmed inputs (from the manual checks) can be supplied as parameters below.
    EXPECTED RESULTS
        A per-domain Pass/Gap table with evidence — the input to SOAMCA-Score.ps1 and the report.
.NOTES
    White-label. Read-only. Reflects a point-in-time snapshot. Licensing/preview facts flagged verify.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaselinePath,
    # Portal-confirmed values the operator records from the manual checks (read-only observations):
    [bool]$AppGovernanceEnabled = $false,
    [int]$OAuthPolicyCount = 0,
    [int]$SessionPolicyCount = 0,
    [int]$AccessPolicyCount = 0,
    [ValidateSet('continuous','manual','none')][string]$DiscoveryIngestion = 'none',
    [bool]$AlertPoliciesTuned = $false,
    [string]$OutputPath = ".\SOAMCA-validation.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $BaselinePath)) { throw "Baseline not found: $BaselinePath. Run SOAMCA-Discovery.ps1 first." }
$baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json

$checks = @()
function Add-Check {
    param([string]$Domain,[string]$Control,[bool]$Pass,[string]$Evidence)
    $script:checks += [ordered]@{ domain=$Domain; control=$Control; result=($(if($Pass){'Pass'}else{'Gap'})); evidence=$Evidence }
}

# Domain 1 — Connector & discovery coverage
$spCount = [int]$baseline.domains.connectorsDiscovery.servicePrincipalCount
Add-Check "connectorsDiscovery" "Core apps API-connected (service principals present)" ($spCount -gt 0) "servicePrincipalCount=$spCount"
Add-Check "connectorsDiscovery" "Cloud discovery fed continuously" ($DiscoveryIngestion -eq 'continuous') "ingestion=$DiscoveryIngestion (continuous scores best; manual = partial; none = gap)"

# Domain 2 — App governance & OAuth
Add-Check "appGovernanceOAuth" "App governance enabled" $AppGovernanceEnabled "appGovernanceEnabled=$AppGovernanceEnabled (verify entitlement/licensing)"
Add-Check "appGovernanceOAuth" "OAuth-app policies present" ($OAuthPolicyCount -gt 0) "oauthPolicyCount=$OAuthPolicyCount"

# Domain 3 — Session & access
Add-Check "sessionAccessPolicies" "At least one session policy" ($SessionPolicyCount -gt 0) "sessionPolicyCount=$SessionPolicyCount"
Add-Check "sessionAccessPolicies" "At least one access policy" ($AccessPolicyCount -gt 0) "accessPolicyCount=$AccessPolicyCount"

# Domain 4 — Alert hygiene
$openAlerts = [int]$baseline.domains.alertHygiene.openAlerts
Add-Check "alertHygiene" "Alert policies tuned" $AlertPoliciesTuned "alertPoliciesTuned=$AlertPoliciesTuned"
Add-Check "alertHygiene" "Open-alert backlog under control (<50 open sampled)" ($openAlerts -lt 50) "openAlerts=$openAlerts (large backlog => alerts not being resolved)"

$summary = $checks | Group-Object domain | ForEach-Object {
    $g = $_.Group
    [ordered]@{ domain=$_.Name; pass=@($g|?{$_.result -eq 'Pass'}).Count; gap=@($g|?{$_.result -eq 'Gap'}).Count }
}

$out = [ordered]@{
    solution     = "SOAMCA"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    checks       = $checks
    summary      = $summary
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Validation complete (read-only)." -ForegroundColor Green
$checks | ForEach-Object {
    $color = if ($_.result -eq 'Pass') { 'Green' } else { 'Yellow' }
    Write-Host ("[{0}] {1} :: {2} — {3}" -f $_.result, $_.domain, $_.control, $_.evidence) -ForegroundColor $color
}
Write-Host "Written: $OutputPath" -ForegroundColor Green
