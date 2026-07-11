<#
.SYNOPSIS
    SOAMDC-Report.ps1 — produce the prioritized, risk-ranked Defender for Cloud findings report and
    show drift versus a prior saved baseline. Read-only.
.DESCRIPTION
    PURPOSE
        Combines the validation output (Pass/Gap per control), the posture score, and the coverage
        analysis into a single prioritized findings report. Each finding carries: domain, severity,
        risk rank (severity x exposure), evidence, and a remediation pointer to the Remediation
        Playbook. If a prior report is supplied, shows new / resolved / unchanged findings (drift).
        NO changes are made.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAMDC-Report.ps1 `
            -ValidationPath ".\SOAMDC-validation.json" `
            -ScorePath ".\Posture Score - Defender for Cloud - Pilot.json" `
            -CoveragePath ".\coverage.json" `
            -PriorReportPath ".\Findings Report - Defender for Cloud - Validate (previous).json" `
            -OutputPath ".\Findings Report - Defender for Cloud - Validate.json"
        -PriorReportPath is optional (omit on the first run).
    EXPECTED RESULTS
        A findings report (JSON + console summary) sorted by risk rank, with drift when a prior run is
        supplied. This is the backlog handed to the Remediation Playbook.
.NOTES
    White-label. Read-only. Risk-acceptance and remediation priority are the security owner's
    decisions — this report supplies the evidence and a suggested rank, not the authorization.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ValidationPath,
    [Parameter(Mandatory)][string]$ScorePath,
    [string]$CoveragePath,
    [string]$PriorReportPath,
    [string]$OutputPath = ".\Findings Report - Defender for Cloud - Validate.json"
)

$ErrorActionPreference = 'Stop'
$validation = Get-Content $ValidationPath -Raw | ConvertFrom-Json
$score      = Get-Content $ScorePath -Raw | ConvertFrom-Json

$domainMeta = @{
    secureScore          = @{ severity='Medium'; exposure=2; remediation='SOAREM §Secure Score & recommendations' }
    planCoverage         = @{ severity='High';   exposure=3; remediation='SOAREM §Plan coverage' }
    regulatoryCompliance = @{ severity='Medium'; exposure=2; remediation='SOAREM §Regulatory compliance posture' }
    agentCoverage        = @{ severity='High';   exposure=3; remediation='SOAREM §Agent/agentless coverage' }
}
$sevWeight = @{ Critical=4; High=3; Medium=2; Low=1 }

$findings = @()
foreach ($check in ($validation.checks | Where-Object { $_.result -eq 'Gap' })) {
    $meta = $domainMeta[$check.domain]
    $rank = ($sevWeight[$meta.severity]) * ($meta.exposure)
    $findings += [ordered]@{
        id          = ("SOAMDC-{0}-{1}" -f $check.domain, ([math]::Abs($check.control.GetHashCode()) % 10000))
        domain      = $check.domain
        control     = $check.control
        severity    = $meta.severity
        riskRank    = $rank
        evidence    = $check.evidence
        remediation = $meta.remediation
    }
}

# Fold coverage-gap assessment groups in as agentCoverage findings.
if ($CoveragePath -and (Test-Path $CoveragePath)) {
    $coverage = Get-Content $CoveragePath -Raw | ConvertFrom-Json
    foreach ($gap in @($coverage.coverageGaps)) {
        $findings += [ordered]@{
            id          = "SOAMDC-coveragegap-$([math]::Abs($gap.displayName.GetHashCode()) % 100000)"
            domain      = 'agentCoverage'
            control     = "Unhealthy coverage assessment: $($gap.displayName)"
            severity    = 'High'
            riskRank    = (3 * 3)
            evidence    = "affectedResources=$($gap.count_)"
            remediation = 'SOAREM §Agent/agentless coverage'
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
    solution     = "SOAMDC"
    title        = "Findings Report - Defender for Cloud - Validate"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    overallScore = $score.overallScore
    band         = $score.band
    findingCount = ($sorted | Measure-Object).Count
    findings     = $sorted
    drift        = $drift
    note         = "Prioritized by risk rank (severity x exposure). Risk-acceptance, priority, and paid-plan cost acceptance are the customer's decisions. Hand to the Remediation Playbook (SOAREM)."
}
$report | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Findings Report — overall {0}/100 ({1}); {2} findings" -f $score.overallScore, $score.band, $report.findingCount) -ForegroundColor Cyan
$sorted | ForEach-Object { Write-Host ("  rank {0,2}  [{1}]  {2}  -> {3}" -f $_.riskRank, $_.severity, $_.control, $_.remediation) -ForegroundColor Yellow }
Write-Host "Written: $OutputPath (read-only). Store securely — it is sensitive." -ForegroundColor Green
