<#
.SYNOPSIS
    SOAMCA-Report.ps1 — produce the prioritized, risk-ranked Defender for Cloud Apps findings report
    and show drift versus a prior saved baseline. Read-only.
.DESCRIPTION
    PURPOSE
        Combines the validation output (Pass/Gap per control), the posture score, and the OAuth audit
        into a single prioritized findings report. Each finding carries: domain, severity, risk rank
        (severity x exposure), evidence, and a remediation pointer to the Remediation Playbook. If a
        prior report/baseline is supplied, shows new / resolved / unchanged findings (drift). NO
        changes are made.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOAMCA-Report.ps1 `
            -ValidationPath ".\SOAMCA-validation.json" `
            -ScorePath ".\Posture Score - Cloud Apps - Pilot.json" `
            -OAuthAuditPath ".\oauth-audit.json" `
            -PriorReportPath ".\Findings Report - Cloud Apps - Validate (previous).json" `
            -OutputPath ".\Findings Report - Cloud Apps - Validate.json"
        -PriorReportPath is optional (omit on the first run).
    EXPECTED RESULTS
        A findings report (JSON + console summary) sorted by risk rank, with drift when a prior run
        is supplied. This is the backlog handed to the Remediation Playbook.
.NOTES
    White-label. Read-only. Risk-acceptance and remediation priority are the security owner's
    decisions — this report supplies the evidence and a suggested rank, not the authorization.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ValidationPath,
    [Parameter(Mandatory)][string]$ScorePath,
    [string]$OAuthAuditPath,
    [string]$PriorReportPath,
    [string]$OutputPath = ".\Findings Report - Cloud Apps - Validate.json"
)

$ErrorActionPreference = 'Stop'
$validation = Get-Content $ValidationPath -Raw | ConvertFrom-Json
$score      = Get-Content $ScorePath -Raw | ConvertFrom-Json

# Severity + exposure model per domain (higher = worse). Remediation pointers map to SOAREM sections.
$domainMeta = @{
    connectorsDiscovery   = @{ severity='Medium'; exposure=2; remediation='SOAREM §Connector & discovery coverage' }
    appGovernanceOAuth    = @{ severity='High';   exposure=3; remediation='SOAREM §App-governance & OAuth policies' }
    sessionAccessPolicies = @{ severity='High';   exposure=2; remediation='SOAREM §Session & access policies' }
    alertHygiene          = @{ severity='Medium'; exposure=2; remediation='SOAREM §Alert hygiene' }
}
$sevWeight = @{ Critical=4; High=3; Medium=2; Low=1 }

$findings = @()
foreach ($check in ($validation.checks | Where-Object { $_.result -eq 'Gap' })) {
    $meta = $domainMeta[$check.domain]
    $rank = ($sevWeight[$meta.severity]) * ($meta.exposure)
    $findings += [ordered]@{
        id          = ("SOAMCA-{0}-{1}" -f $check.domain, ([math]::Abs($check.control.GetHashCode()) % 10000))
        domain      = $check.domain
        control     = $check.control
        severity    = $meta.severity
        riskRank    = $rank
        evidence    = $check.evidence
        remediation = $meta.remediation
    }
}

# Fold in high-risk OAuth apps as discrete findings.
if ($OAuthAuditPath -and (Test-Path $OAuthAuditPath)) {
    $oauth = Get-Content $OAuthAuditPath -Raw | ConvertFrom-Json
    foreach ($app in @($oauth.findings | Where-Object { $_.riskScore -ge 3 })) {
        $findings += [ordered]@{
            id          = "SOAMCA-oauthapp-$($app.appId)"
            domain      = 'appGovernanceOAuth'
            control     = "Risky OAuth app: $($app.displayName)"
            severity    = 'High'
            riskRank    = (3 * 3) + $app.riskScore
            evidence    = ("flags={0}; scopes={1}" -f ($app.flags -join ','), $app.delegatedScopes)
            remediation = 'SOAREM §App-governance & OAuth policies'
        }
    }
}

$sorted = @($findings | Sort-Object -Property riskRank -Descending)

# Drift vs prior report
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
    solution     = "SOAMCA"
    title        = "Findings Report - Cloud Apps - Validate"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    readOnly     = $true
    overallScore = $score.overallScore
    band         = $score.band
    findingCount = ($sorted | Measure-Object).Count
    findings     = $sorted
    drift        = $drift
    note         = "Prioritized by risk rank (severity x exposure). Risk-acceptance and priority are the security owner's decision. Hand to the Remediation Playbook (SOAREM)."
}
$report | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Findings Report — overall {0}/100 ({1}); {2} findings" -f $score.overallScore, $score.band, $report.findingCount) -ForegroundColor Cyan
$sorted | ForEach-Object {
    Write-Host ("  rank {0,2}  [{1}]  {2}  -> {3}" -f $_.riskRank, $_.severity, $_.control, $_.remediation) -ForegroundColor Yellow
}
Write-Host "Written: $OutputPath (read-only). Store securely — it is sensitive." -ForegroundColor Green
