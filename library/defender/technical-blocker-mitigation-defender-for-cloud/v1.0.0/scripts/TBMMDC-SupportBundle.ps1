<#
.SYNOPSIS
    TBMMDC-SupportBundle.ps1 — read-only assembly of a support-ready diagnostic bundle for a Defender
    for Cloud blocker that survives a correct fix.
.DESCRIPTION
    PURPOSE
        Read-only packaging for the "Technical Blocker Mitigation — Defender for Cloud" solution.
        When the plan is On (not overridden), provisioning/agentless is enabled, the connector role is
        correct, and the benchmark policy is assigned, yet the blocker persists (likely a Microsoft
        service issue), this assembles the bundle 'MDC Support Bundle - <case> - Escalate': the discovery
        snapshot, the coverage analysis, the affected scope, tenant/subscription context, and timestamps.
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDC-SupportBundle.ps1 -Case "MSCASE-12345" -AffectedScope "sub1,aws-connector-prod"
        Point it at the artifacts you already produced:
        .\TBMMDC-SupportBundle.ps1 -Case "MSCASE-12345" -Discovery .\MDC-blocker-discovery.json -Coverage .\MDC-coverage.json
    EXPECTED RESULTS
        A single folder 'MDC-Support-Bundle-<case>' with a manifest and copies of the read-only
        artifacts, ready to attach to a Microsoft support case.
.NOTES
    White-label. Read-only — collects existing read-only artifacts; changes nothing.
    Do not place the bundle in shared/unsecured storage; it contains subscription/cloud-account identifiers.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Case,
    [string]$AffectedScope = "",
    [string]$Discovery = ".\MDC-blocker-discovery.json",
    [string]$Coverage = ".\MDC-coverage.json",
    [string]$Report = ".\MDC-blocker-report.json"
)

$safeCase = ($Case -replace '[^A-Za-z0-9._-]','_')
$dir = ".\MDC-Support-Bundle-$safeCase"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "`n=== TBMMDC — support bundle assembly (read-only) ===" -ForegroundColor Cyan
Write-Host ("Bundle: {0}" -f $dir)

$included = @()
foreach ($f in @($Discovery,$Coverage,$Report)) {
    if ($f -and (Test-Path $f)) { Copy-Item $f -Destination $dir -Force; $included += (Split-Path $f -Leaf); Write-Host ("   + {0}" -f (Split-Path $f -Leaf)) -ForegroundColor Green }
    else { Write-Host ("   - {0} (missing — generate it first)" -f $f) -ForegroundColor Yellow }
}

$manifest = [ordered]@{
    Case = $Case
    GeneratedAt = (Get-Date).ToString('s')
    AffectedScope = @($AffectedScope.Split(',') | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    IncludedArtifacts = $included
    ManualStepsForSupport = @(
        "Export the Environment settings / Defender plan blade and connector status for the affected scope.",
        "Confirm the plan is On and not overridden by an Azure Policy/deny or management-group setting.",
        "Confirm auto-provisioning / agentless scanning is enabled and the workspace is reachable.",
        "Confirm the AWS/GCP connector role/permissions are correct.",
        "Confirm the Microsoft cloud security benchmark policy is assigned and evaluating.",
        "Attach this whole folder to the Microsoft support case."
    )
    EscalationCriteria = "Plan On (not overridden) + providers registered, provisioning/agentless enabled, connector role correct, benchmark assigned, correct fix applied + warm-up elapsed, blocker persists => service-side issue."
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $dir "manifest.json") -Encoding UTF8

Write-Host "`nBundle assembled (read-only). Add the portal exports, then attach the folder to the case." -ForegroundColor Green
Write-Host "Plan-enablement cost decisions and incident-response decisions remain the customer's." -ForegroundColor DarkGray
