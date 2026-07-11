<#
.SYNOPSIS
    TBMMCA-SupportBundle.ps1 — read-only assembly of a support-ready diagnostic bundle for a Defender
    for Cloud Apps blocker that survives a correct fix.
.DESCRIPTION
    PURPOSE
        Read-only packaging for the "Technical Blocker Mitigation — Defender for Cloud Apps" solution.
        When the plan is assigned, the connector re-consented, the discovery source confirmed, and the
        CA App Control policy enabled+scoped, yet the blocker persists (likely a Microsoft service
        issue), this assembles the bundle 'MDCA Support Bundle - <case> - Escalate': the discovery
        snapshot, the CA App Control analysis, the affected apps/policies, tenant context, and
        timestamps. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMCA-SupportBundle.ps1 -Case "MSCASE-12345" -AffectedApps "Salesforce,ServiceNow"
        Point it at the artifacts you already produced:
        .\TBMMCA-SupportBundle.ps1 -Case "MSCASE-12345" -Discovery .\MDCA-blocker-discovery.json -CAPolicy .\MDCA-conditionalaccess.json
    EXPECTED RESULTS
        A single folder 'MDCA-Support-Bundle-<case>' with a manifest and copies of the read-only
        artifacts, ready to attach to a Microsoft support case.
.NOTES
    White-label. Read-only — collects existing read-only artifacts; changes nothing.
    Do not place the bundle in shared/unsecured storage; it contains tenant/app identifiers.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Case,
    [string]$AffectedApps = "",
    [string]$Discovery = ".\MDCA-blocker-discovery.json",
    [string]$CAPolicy = ".\MDCA-conditionalaccess.json",
    [string]$Report = ".\MDCA-blocker-report.json"
)

$safeCase = ($Case -replace '[^A-Za-z0-9._-]','_')
$dir = ".\MDCA-Support-Bundle-$safeCase"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "`n=== TBMMCA — support bundle assembly (read-only) ===" -ForegroundColor Cyan
Write-Host ("Bundle: {0}" -f $dir)

$included = @()
foreach ($f in @($Discovery,$CAPolicy,$Report)) {
    if ($f -and (Test-Path $f)) { Copy-Item $f -Destination $dir -Force; $included += (Split-Path $f -Leaf); Write-Host ("   + {0}" -f (Split-Path $f -Leaf)) -ForegroundColor Green }
    else { Write-Host ("   - {0} (missing — generate it first)" -f $f) -ForegroundColor Yellow }
}

$manifest = [ordered]@{
    Case = $Case
    GeneratedAt = (Get-Date).ToString('s')
    AffectedApps = @($AffectedApps.Split(',') | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    IncludedArtifacts = $included
    ManualStepsForSupport = @(
        "Export the connector status / activity-log entries for the affected app and add them here.",
        "Confirm the MDCA (and Entra, for App Control) plan is assigned.",
        "Confirm the connector was re-consented with the required permissions.",
        "Confirm the Cloud Discovery source is feeding the service.",
        "Confirm the CA App Control policy is enabled + scoped and the app is onboarded to session control.",
        "Attach this whole folder to the Microsoft support case."
    )
    EscalationCriteria = "Plan assigned, connector re-consented, discovery source confirmed, CA App Control enabled+scoped + app onboarded, correct fix applied + warm-up elapsed, blocker persists => service-side issue."
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $dir "manifest.json") -Encoding UTF8

Write-Host "`nBundle assembled (read-only). Add the connector/activity export, then attach the folder to the case." -ForegroundColor Green
Write-Host "Session-control enforcement and incident-response decisions remain the SOC/security team's." -ForegroundColor DarkGray
