<#
.SYNOPSIS
    CMPDASH-Set-Configuration.ps1 — Author the dashboard config and (optionally) enable audit ingestion (default -WhatIf; -Commit to write).
.DESCRIPTION
    PURPOSE
        Writes RiskComplianceDashboard.config.json — the dashboard's tiles, RAG thresholds, refresh
        cadence, distribution list, and per-signal source (live vs owner-captured). Optionally enables
        unified audit-log ingestion (Set-AdminAuditLogConfig), which is tenant-wide and therefore gated.
        Safe by default: previews with -WhatIf and changes nothing until -Commit. Writes only local files
        plus, when requested, the one tenant setting (audit ingestion) — no Purview policy is changed.
    HOW TO RUN
        Preview  : powershell -ExecutionPolicy Bypass -File .\CMPDASH-Set-Configuration.ps1 -WhatIf
        Write cfg: powershell -ExecutionPolicy Bypass -File .\CMPDASH-Set-Configuration.ps1 -Commit
        Enable audit ingestion (piloted, change control):
                   .\CMPDASH-Set-Configuration.ps1 -EnableAuditIngestion -Commit
        Connect first: Connect-IPPSSession as an admin with the required roles. PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        With -WhatIf: prints the config it would write and any action it would take, no changes.
        With -Commit: RiskComplianceDashboard.config.json written; audit ingestion enabled only if asked.
.NOTES
    Purview category — Risk & Compliance Dashboard. Default -WhatIf. Enabling audit is high-impact — pilot +
    change control. RAG thresholds are your policy, not a Microsoft default. No secrets in this script.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = "./RiskComplianceDashboard.config.json",
    [int]$WindowDays = 30,
    [string[]]$Distribution = @('compliance-leads@contoso.com'),
    [switch]$EnableAuditIngestion,
    [switch]$Commit,
    [switch]$WhatIf = $true
)

if ($Commit) { $WhatIf = $false }

# --- Default config scaffold: tiles, RAG thresholds (YOUR policy), and source per signal ---
$config = [ordered]@{
    schemaVersion = "1.0"
    generatedOn   = (Get-Date).ToString("s")
    windowDays    = $WindowDays
    distribution  = $Distribution
    signalScope   = "Risk & Compliance Dashboard — Signal Scope"
    signals = @(
        [ordered]@{ key='complianceManager'; title='Compliance Manager — score'; source='owner-captured'; owner='TBD'; capturedOn=$null; metric='overallScorePercent'; rag=@{ greenMin=80; amberMin=60 }; note='verify your licensing/tenant — no stable public read' }
        [ordered]@{ key='dlp';               title='Data Loss Prevention';        source='live';           metric='enforcedPolicyCount + matchVolume'; rag=@{ redIfAnySimulationOnly=$true; amberIfMatchVolumeOver=1000 } }
        [ordered]@{ key='sensitivityLabels'; title='Sensitivity labels';          source='live';           metric='publishedLabelCount + labelingActivity'; rag=@{ greenMin=1 } }
        [ordered]@{ key='retention';         title='Data lifecycle & records';     source='live';           metric='retentionPolicyCount + workloadCoverage'; rag=@{ greenMin=1 } }
        [ordered]@{ key='insiderRisk';       title='Insider Risk (aggregate)';     source='owner-captured'; owner='TBD'; capturedOn=$null; metric='activePolicies + openAlerts'; note='E5; HR-sensitive; aggregate-only; role-separated; determinations deferred to HR/legal' }
        [ordered]@{ key='commCompliance';    title='Communication Compliance (aggregate)'; source='owner-captured'; owner='TBD'; capturedOn=$null; metric='activePolicies + pendingItems'; note='E5; HR-sensitive; aggregate-only; role-separated; outcomes deferred to HR/legal' }
        [ordered]@{ key='audit';             title='Audit';                        source='live';           metric='unifiedAuditIngestionEnabled + tier'; rag=@{ redIfIngestionOff=$true } }
        [ordered]@{ key='dspm';              title='Data Security Posture (DSPM)';  source='owner-captured'; owner='TBD'; capturedOn=$null; metric='openRecommendations'; note='E5; interface evolving — verify your licensing/tenant' }
    )
    cadence = @{ refresh='weekly'; ownerCaptureMaxAgeDays=30 }
}

Write-Host "=== CMPDASH-Set-Configuration ($(if($WhatIf){'WhatIf — preview'}else{'COMMIT'})) ===" -ForegroundColor Cyan
Write-Host "Config target : $ConfigPath" -ForegroundColor DarkGray
Write-Host "RAG thresholds below are YOUR policy — confirm with compliance/records/legal before publishing." -ForegroundColor DarkGray
$json = $config | ConvertTo-Json -Depth 8

if ($WhatIf) {
    Write-Host "`n-- would write RiskComplianceDashboard.config.json: --" -ForegroundColor Yellow
    Write-Host $json
} else {
    $json | Out-File -FilePath $ConfigPath -Encoding utf8
    Write-Host "`nWrote $ConfigPath" -ForegroundColor Green
    Write-Host "Set the 'owner' + 'capturedOn' fields for owner-captured signals before the first published dashboard." -ForegroundColor DarkGray
}

# --- Optional tenant write: enable unified audit-log ingestion (gated) ---
if ($EnableAuditIngestion) {
    Write-Host "`n-- Unified audit-log ingestion --" -ForegroundColor Cyan
    if ($WhatIf) {
        Write-Host "WhatIf: would run Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true (tenant-wide; audit captures from enablement forward)." -ForegroundColor Yellow
    } else {
        try {
            Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -ErrorAction Stop
            Write-Host "Enabled unified audit-log ingestion. Note: audit begins capturing from now; no historical volume before this date." -ForegroundColor Green
        } catch {
            Write-Host ("Failed to enable audit ingestion: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

Write-Host "`nDone. Next: CMPDASH-Report.ps1 (collect + render, read-only), then CMPDASH-Validation.ps1 (reconcile)." -ForegroundColor Cyan
