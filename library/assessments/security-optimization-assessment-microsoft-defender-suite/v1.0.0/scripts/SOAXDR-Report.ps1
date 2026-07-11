<#
.SYNOPSIS
    SOAXDR-Report.ps1 — produce the prioritized, risk-ranked Defender-suite findings report and show
    drift versus a prior saved baseline. Read-only.
.DESCRIPTION
    PURPOSE
        Combines the validation output (Pass/Gap per control), the suite posture score, and the RBAC
        audit into a single prioritized findings report. Each finding carries: domain, severity, risk
        rank (severity x exposure), evidence, and a remediation pointer (to the Remediation Playbook,
        or to a per-pillar deep-dive assessment where the gap is a whole dark pillar). If a prior
        report is supplied, shows new / resolved / unchanged findings (drift). NO changes are made.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAXDR-Report.ps1 `
            -ValidationPath ".\SOAXDR-validation.json" `
            -ScorePath ".\Posture Score - Defender Suite - Pilot.json" `
            -RBACAuditPath ".\rbac-audit.json" `
            -PriorReportPath ".\Findings Report - Defender Suite - Validate (previous).json" `
            -OutputPath ".\Findings Report - Defender Suite - Validate.json"
        -PriorReportPath is optional (omit on the first run).
    EXPECTED RESULTS
        A findings report (JSON + console summary) sorted by risk rank, with drift when a prior run is
        supplied. This is the backlog handed to the Remediation Playbook / deep-dive assessments.
.NOTES
    White-label. Read-only. Risk-acceptance and remediation priority are the security owner's
    decisions — this report supplies the evidence and a suggested rank, not the authorization.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ValidationPath,
    [Parameter(Mandatory)][string]$ScorePath,
    [string]$RBACAuditPath,
    [string]$PriorReportPath,
    [string]$OutputPath = ".\Findings Report - Defender Suite - Validate.json"
)

$ErrorActionPreference = 'Stop'
$validation = Get-Content $ValidationPath -Raw | ConvertFrom-Json
$score      = Get-Content $ScorePath -Raw | ConvertFrom-Json

$domainMeta = @{
    crossPillarCoverage = @{ severity='High';   exposure=3; remediation='SOAREM §Cross-pillar coverage (and the pillar''s dedicated assessment)' }
    unifiedRbac         = @{ severity='High';   exposure=3; remediation='SOAREM §Unified RBAC' }
    incidentCorrelation = @{ severity='Medium'; exposure=2; remediation='SOAREM §Incident correlation' }
    suiteSecureScore    = @{ severity='Medium'; exposure=2; remediation='SOAREM §Suite-wide Secure Score' }
}
$sevWeight = @{ Critical=4; High=3; Medium=2; Low=1 }

$findings = @()
foreach ($check in ($validation.checks | Where-Object { $_.result -eq 'Gap' })) {
    $meta = $domainMeta[$check.domain]
    $rank = ($sevWeight[$meta.severity]) * ($meta.exposure)
    $findings += [ordered]@{
        id          = ("SOAXDR-{0}-{1}" -f $check.domain, ([math]::Abs($check.control.GetHashCode()) % 10000))
        domain      = $check.domain
        control     = $check.control
        severity    = $meta.severity
        riskRank    = $rank
        evidence    = $check.evidence
        remediation = $meta.remediation
    }
}

# Fold RBAC audit flags in as unifiedRbac findings.
if ($RBACAuditPath -and (Test-Path $RBACAuditPath)) {
    $rbac = Get-Content $RBACAuditPath -Raw | ConvertFrom-Json
    foreach ($flag in @($rbac.flags)) {
        $findings += [ordered]@{
            id          = "SOAXDR-rbacflag-$([math]::Abs($flag.GetHashCode()) % 100000)"
            domain      = 'unifiedRbac'
            control     = "RBAC exposure: $flag"
            severity    = 'High'
            riskRank    = (3 * 3)
            evidence    = $flag
            remediation = 'SOAREM §Unified RBAC'
        }
    }
}

$sorted = @($findings | Sort-Object -Property riskRank -Descending)

$drift = $null
if ($PriorReportPath -and (Test-Path $PriorReportPath)) {
    $prior = Get-Content $PriorReportPath -Raw | ConvertFrom-Json
    $priorIds = @($prior.findings | ForEach-Object { $_.id })
    $currentIds = @($sorted | ForEach-Object { $_.id })
    $drift = [ordered]@{
        new       = @($sorted | Where-Object { $_.id -notin $priorIds } | ForEach-Object { $_.id })
        resolved  = @($prior.findings | Where-Object { $_.id -notin $currentIds } | ForEach-Object { $_.id })
        unchanged = @($sorted | Where-Object { $_.id -in $priorIds } | ForEach-Object { $_.id })
    }
} else {
    $drift = "No prior baseline supplied — first run."
}

$report = [ordered]@{
    solution     = "SOAXDR"
    title        = "Findings Report - Defender Suite - Validate"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    overallScore = $score.overallScore
    band         = $score.band
    findingCount = ($sorted | Measure-Object).Count
    findings     = $sorted
    drift        = $drift
    note         = "Prioritized by risk rank (severity x exposure). Risk-acceptance and priority are the security owner's decision. Hand to the Remediation Playbook (SOAREM); use the per-pillar assessments for deep single-pillar review."
}
$report | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Findings Report — suite {0}/100 ({1}); {2} findings" -f $score.overallScore, $score.band, $report.findingCount) -ForegroundColor Cyan
$sorted | ForEach-Object { Write-Host ("  rank {0,2}  [{1}]  {2}  -> {3}" -f $_.riskRank, $_.severity, $_.control, $_.remediation) -ForegroundColor Yellow }
Write-Host "Written: $OutputPath (read-only). Store securely — it is sensitive." -ForegroundColor Green
