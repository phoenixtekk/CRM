<#
.SYNOPSIS
    SOAREM-Discovery.ps1 — read-only ingest of a Defender Security Optimization Assessment findings
    report; maps each finding to its remediation procedure and gate; writes the remediation plan.
.DESCRIPTION
    PURPOSE
        Ingests a findings report produced by any Defender Security Optimization Assessment (SOAMCA /
        SOAMDC / SOAXDR / endpoint / identity / office). For each finding it looks up the remediation
        procedure and its gating (pilot-first always; some categories additionally approval-gated /
        disruptive), and writes the remediation plan (`Remediation Plan - Defender SOA - Assess`).
        READ-ONLY — reads the report and emits a plan; changes nothing in the tenant.
    HOW TO RUN
        Connect-MgGraph -Scopes "SecurityEvents.Read.All","Directory.Read.All"   # read-only
        powershell -ExecutionPolicy Bypass -File .\SOAREM-Discovery.ps1 `
            -FindingsReportPath ".\Findings Report - Cloud Apps - Validate.json" `
            -OutputPath ".\Remediation Plan - Defender SOA - Assess.json"
    EXPECTED RESULTS
        A remediation plan JSON: each finding with its mapped remediation, gate, and pilot-first note.
.NOTES
    White-label. Read-only. Does NOT apply any change — SOAREM-Remediate.ps1 performs the gated apply.
    Production change-approval and priority are the customer's decisions.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$FindingsReportPath,
    [string]$OutputPath = ".\Remediation Plan - Defender SOA - Assess.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $FindingsReportPath)) { throw "Findings report not found: $FindingsReportPath. Run the assessment first." }
$report = Get-Content $FindingsReportPath -Raw | ConvertFrom-Json

# Finding-domain -> remediation procedure + gate. 'disruptive' categories require -ConfirmDisruptive
# in SOAREM-Remediate.ps1 and apply in monitor/audit first where supported.
$map = @{
    connectorsDiscovery   = @{ remediation='Connect missing app / enable continuous discovery (log upload or MDE integration)'; gate='pilot'; monitorMode=$false }
    appGovernanceOAuth    = @{ remediation='Enable app governance; create OAuth-app policy for risky consent'; gate='pilot+approval'; monitorMode=$false; disruptive=$true }
    sessionAccessPolicies = @{ remediation='Create Conditional Access App Control session/access policy in MONITOR first'; gate='pilot+approval'; monitorMode=$true; disruptive=$true }
    alertHygiene          = @{ remediation='Tune alert policy severity/scope/exclusions; retire duplicates'; gate='pilot'; monitorMode=$false }
    secureScore           = @{ remediation="Apply the recommendation's Fix on the pilot subscription"; gate='pilot'; monitorMode=$false }
    planCoverage          = @{ remediation='Enable the workload plan on the pilot subscription'; gate='pilot+approval'; monitorMode=$false; disruptive=$true }
    regulatoryCompliance  = @{ remediation='Map the required standard to the compliance dashboard'; gate='pilot'; monitorMode=$false }
    agentCoverage         = @{ remediation='Enable agentless scanning / onboard the agent on the pilot scope'; gate='pilot+approval'; monitorMode=$false; disruptive=$true }
    crossPillarCoverage   = @{ remediation='Onboard the dark pillar (see the pillar''s onboarding solution)'; gate='pilot+approval'; monitorMode=$false; disruptive=$true }
    unifiedRbac           = @{ remediation='Activate unified RBAC; assign least-privilege roles to a pilot'; gate='pilot+approval'; monitorMode=$false; disruptive=$true }
    incidentCorrelation   = @{ remediation='Ensure pillars feed signal (downstream of coverage)'; gate='pilot'; monitorMode=$false }
}

$plan = @()
foreach ($f in @($report.findings)) {
    $m = $map[$f.domain]
    if (-not $m) { $m = @{ remediation='MANUAL: no mapped remediation — treat as manual, record separately'; gate='manual'; monitorMode=$false } }
    $plan += [ordered]@{
        findingId     = $f.id
        domain        = $f.domain
        control       = $f.control
        severity      = $f.severity
        riskRank      = $f.riskRank
        remediation   = $m.remediation
        gate          = $m.gate
        disruptive    = [bool]$m.disruptive
        monitorFirst  = [bool]$m.monitorMode
        status        = 'planned'
    }
}

$out = [ordered]@{
    solution        = "SOAREM"
    generatedUtc    = (Get-Date).ToUniversalTime().ToString("o")
    readOnly        = $true
    sourceReport    = $FindingsReportPath
    sourceSolution  = $report.solution
    planCount       = ($plan | Measure-Object).Count
    plan            = @($plan | Sort-Object -Property riskRank -Descending)
    note            = "Read-only plan. Apply is performed by SOAREM-Remediate.ps1 (-WhatIf default; -Apply to pilot; -ConfirmDisruptive for approval-gated categories). Change-approval and priority are the customer's decisions."
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Remediation plan for {0} findings (read-only):" -f $out.planCount) -ForegroundColor Cyan
$out.plan | ForEach-Object {
    $tag = if ($_.disruptive) { 'APPROVAL-GATED' } else { 'pilot' }
    Write-Host ("  rank {0,2}  [{1}]  {2}  => {3}  ({4})" -f $_.riskRank, $_.severity, $_.control, $_.remediation, $tag) -ForegroundColor Yellow
}
Write-Host "Written: $OutputPath. This script made NO changes." -ForegroundColor Green
