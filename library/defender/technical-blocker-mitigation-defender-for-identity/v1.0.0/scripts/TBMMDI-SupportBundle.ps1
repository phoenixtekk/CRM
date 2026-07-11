<#
.SYNOPSIS
    TBMMDI-SupportBundle.ps1 — read-only assembly of a support-ready diagnostic bundle for a Defender
    for Identity blocker that survives a correct fix.
.DESCRIPTION
    PURPOSE
        Read-only packaging for the "Technical Blocker Mitigation — Defender for Identity" solution.
        When the sensor is on a supported OS with service reach, the DSA and audit policy are correct,
        and it still will not go healthy or stream (likely a Microsoft service issue), this assembles the
        bundle 'MDI Support Bundle - <case> - Escalate': the discovery snapshot, the DC audit-policy
        readiness output, the affected DC list, tenant context, and timestamps. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDI-SupportBundle.ps1 -Case "MSCASE-12345" -AffectedDCs "DC01,DC02"
        Point it at the artifacts you already produced:
        .\TBMMDI-SupportBundle.ps1 -Case "MSCASE-12345" -Discovery .\MDI-blocker-discovery.json -AuditPolicy .\MDI-auditpolicy-DC01.json
    EXPECTED RESULTS
        A single folder 'MDI-Support-Bundle-<case>' with a manifest and copies of the read-only
        artifacts. ALSO run the MDI SENSOR's own log-collection ON the DC and add its output — that is
        the on-DC half Microsoft support asks for.
.NOTES
    White-label. Read-only — collects existing read-only artifacts; changes nothing.
    Do not place the bundle in shared/unsecured storage; it contains DC/tenant identifiers.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Case,
    [string]$AffectedDCs = "",
    [string]$Discovery = ".\MDI-blocker-discovery.json",
    [string]$AuditPolicy = "",
    [string]$Report = ".\MDI-blocker-report.json"
)

$safeCase = ($Case -replace '[^A-Za-z0-9._-]','_')
$dir = ".\MDI-Support-Bundle-$safeCase"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "`n=== TBMMDI — support bundle assembly (read-only) ===" -ForegroundColor Cyan
Write-Host ("Bundle: {0}" -f $dir)

# Auto-include any audit-policy snapshots in the current folder if not explicitly named.
$auditFiles = if ($AuditPolicy -and (Test-Path $AuditPolicy)) { @($AuditPolicy) } else { @(Get-ChildItem -Path . -Filter 'MDI-auditpolicy-*.json' -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }) }

$included = @()
foreach ($f in (@($Discovery,$Report) + $auditFiles)) {
    if ($f -and (Test-Path $f)) { Copy-Item $f -Destination $dir -Force; $included += (Split-Path $f -Leaf); Write-Host ("   + {0}" -f (Split-Path $f -Leaf)) -ForegroundColor Green }
    else { Write-Host ("   - {0} (missing — generate it first)" -f $f) -ForegroundColor Yellow }
}

$manifest = [ordered]@{
    Case = $Case
    GeneratedAt = (Get-Date).ToString('s')
    AffectedDCs = @($AffectedDCs.Split(',') | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    IncludedArtifacts = $included
    ManualStepsForSupport = @(
        "Run the MDI sensor's own log-collection ON the affected DC and add its output to this folder.",
        "Confirm the sensor is on a supported OS with confirmed outbound service reach.",
        "Confirm the DSA is registered with the required permissions.",
        "Confirm the required audit subcategories are enabled and NNR ports are open.",
        "Attach this whole folder to the Microsoft support case."
    )
    EscalationCriteria = "Supported OS + service reach, DSA correct, audit subcategories enabled, NNR open, correct fix applied + warm-up elapsed, sensor still unhealthy/silent => service-side issue."
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $dir "manifest.json") -Encoding UTF8

Write-Host "`nBundle assembled (read-only). Add the sensor log-collection output, then attach the folder to the case." -ForegroundColor Green
Write-Host "Identity response actions and incident-response decisions remain the SOC/security team's." -ForegroundColor DarkGray
