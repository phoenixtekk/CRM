<#
.SYNOPSIS
    TBMMDO-SupportBundle.ps1 — read-only assembly of a support-ready diagnostic bundle for a Defender
    for Office 365 blocker that survives a correct fix.
.DESCRIPTION
    PURPOSE
        Read-only packaging for the "Technical Blocker Mitigation — Defender for Office 365" solution.
        When routing reaches EOP, the winning policy is correct and scoped, the plan is assigned, and
        protection still does not apply (likely a Microsoft service issue), this assembles the bundle
        'MDO Support Bundle - <case> - Escalate': the discovery snapshot, the mail-flow analysis, the
        affected recipients, message-trace IDs, tenant context, and timestamps. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDO-SupportBundle.ps1 -Case "MSCASE-12345" -MessageIds "id1,id2"
        Point it at the artifacts you already produced:
        .\TBMMDO-SupportBundle.ps1 -Case "MSCASE-12345" -Discovery .\MDO-blocker-discovery.json -MailFlow .\MDO-mailflow.json
    EXPECTED RESULTS
        A single folder 'MDO-Support-Bundle-<case>' with a manifest and copies of the read-only
        artifacts, ready to attach to a Microsoft support case.
.NOTES
    White-label. Read-only — collects existing read-only artifacts; changes nothing.
    Do not place the bundle in shared/unsecured storage; it contains recipient/tenant identifiers.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Case,
    [string]$MessageIds = "",
    [string]$Discovery = ".\MDO-blocker-discovery.json",
    [string]$MailFlow = ".\MDO-mailflow.json",
    [string]$Report = ".\MDO-blocker-report.json"
)

$safeCase = ($Case -replace '[^A-Za-z0-9._-]','_')
$dir = ".\MDO-Support-Bundle-$safeCase"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "`n=== TBMMDO — support bundle assembly (read-only) ===" -ForegroundColor Cyan
Write-Host ("Bundle: {0}" -f $dir)

$included = @()
foreach ($f in @($Discovery,$MailFlow,$Report)) {
    if ($f -and (Test-Path $f)) { Copy-Item $f -Destination $dir -Force; $included += (Split-Path $f -Leaf); Write-Host ("   + {0}" -f (Split-Path $f -Leaf)) -ForegroundColor Green }
    else { Write-Host ("   - {0} (missing — generate it first)" -f $f) -ForegroundColor Yellow }
}

$manifest = [ordered]@{
    Case = $Case
    GeneratedAt = (Get-Date).ToString('s')
    MessageTraceIds = @($MessageIds.Split(',') | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    IncludedArtifacts = $included
    ManualStepsForSupport = @(
        "Export the message trace / entity for the test message and add it to this folder.",
        "Confirm routing reaches EOP (see MDO-mailflow.json).",
        "Confirm the WINNING policy for the affected recipients is intended, enabled, and scoped.",
        "Confirm the required MDO plan is assigned.",
        "Attach this whole folder to the Microsoft support case."
    )
    EscalationCriteria = "Routing reaches EOP, winning policy correct+enabled+scoped, plan assigned, propagation elapsed, protection still not applied => service-side issue."
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $dir "manifest.json") -Encoding UTF8

Write-Host "`nBundle assembled (read-only). Add the message-trace export, then attach the folder to the case." -ForegroundColor Green
Write-Host "Mail-remediation and incident-response actions remain the SOC/security team's." -ForegroundColor DarkGray
