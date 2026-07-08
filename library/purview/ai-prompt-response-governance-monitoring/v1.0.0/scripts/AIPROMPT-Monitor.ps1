<#
.SYNOPSIS
    AIPROMPT-Monitor.ps1 — monitor AI prompt/response usage and sensitive interactions (read-only).
.DESCRIPTION
    PURPOSE
        The AI usage monitoring report. Pulls AI/Copilot interaction records from Purview auditing
        (CopilotInteraction, the same signal that feeds DSPM for AI): who used AI, which app, and which
        prompts/responses referenced sensitive/labeled resources. Read-only evidence baseline.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Exchange Online / Security & Compliance PowerShell (Search-UnifiedAuditLog):
          Connect-ExchangeOnline
          .\AIPROMPT-Monitor.ps1 -Days 30
    EXPECTED RESULTS
        AI-Usage-Copilot-Monitor.csv (all AI interactions) and Sensitive-AI-Interactions-Estate-Assess.csv
        (only interactions touching labeled/sensitive resources). Empty results usually mean auditing is off
        (Req 2.3) or Copilot/AI has not been used yet — confirm both.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: the audit RecordType that surfaces AI interactions evolves. This script
    parameterizes it (-AiRecordTypes, default CopilotInteraction); confirm the exact value in Purview -> Audit.
    For the richest view use the DSPM for AI reports in the portal — this script provides the portable,
    scriptable signal, not a replacement for that blade.
#>
[CmdletBinding()]
param(
    [int]$Days = 30,
    [string[]]$AiRecordTypes = @("CopilotInteraction"),
    [int]$ResultSize = 5000,
    [string]$UsageOutPath = ".\AI-Usage-Copilot-Monitor.csv",
    [string]$SensitiveOutPath = ".\Sensitive-AI-Interactions-Estate-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIPROMPT Monitor — AI prompt/response usage (read-only) ===" -ForegroundColor Cyan
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    Write-Host "Search-UnifiedAuditLog not available. Connect Exchange Online / S&C PowerShell first (Connect-ExchangeOnline)." -ForegroundColor Red
    return
}

$start = (Get-Date).AddDays(-1 * [math]::Abs($Days)); $end = Get-Date
Write-Host ("Window: {0:yyyy-MM-dd} .. {1:yyyy-MM-dd}  RecordType={2}" -f $start, $end, ($AiRecordTypes -join ",")) -ForegroundColor Cyan

try { $raw = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $AiRecordTypes -ResultSize $ResultSize -Formatted -ErrorAction Stop) }
catch { Write-Host "  Audit search failed: $($_.Exception.Message)" -ForegroundColor Red; return }

$rows = foreach ($e in $raw) {
    $d = $null; try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    $accessed = @()
    $labels   = @()
    if ($d.CopilotEventData.AccessedResources) {
        $accessed = @($d.CopilotEventData.AccessedResources | ForEach-Object { $_.Name })
        $labels   = @($d.CopilotEventData.AccessedResources | ForEach-Object { $_.SensitivityLabelId } | Where-Object { $_ })
    }
    [pscustomobject]@{
        CreationDate      = $e.CreationDate
        User              = $e.UserIds
        Operation         = $e.Operations
        RecordType        = $e.RecordType
        AppHost           = $d.CopilotEventData.AppHost
        AccessedResources = ($accessed -join "; ")
        SensitivityLabels = (($labels | Select-Object -Unique) -join "; ")
        TouchesSensitive  = [bool]($labels.Count -gt 0)
    }
}
$rows = @($rows)
$rows | Export-Csv -Path $UsageOutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`n{0} AI-interaction record(s) -> {1}  (AI Usage - Copilot - Monitor)" -f $rows.Count, $UsageOutPath) -ForegroundColor Green

$sensitive = @($rows | Where-Object { $_.TouchesSensitive })
$sensitive | Export-Csv -Path $SensitiveOutPath -NoTypeInformation -Encoding UTF8
Write-Host ("{0} sensitive AI interaction(s) -> {1}  (Sensitive AI Interactions - Estate - Assess)" -f $sensitive.Count, $SensitiveOutPath) -ForegroundColor Green

if ($rows.Count -eq 0) {
    Write-Host "  No AI interactions found — confirm auditing is ON (Req 2.3), that Copilot/AI has been used, and the -AiRecordTypes value for your tenant." -ForegroundColor Yellow
} else {
    Write-Host "`n=== Top AI users by interaction count ===" -ForegroundColor Cyan
    $rows | Where-Object User | Group-Object User | Sort-Object Count -Descending | Select-Object -First 10 |
        ForEach-Object { Write-Host ("  {0,-6} {1}" -f $_.Count, $_.Name) }
    Write-Host "`n=== AI apps in use (AppHost) ===" -ForegroundColor Cyan
    $rows | Where-Object AppHost | Group-Object AppHost | Sort-Object Count -Descending |
        ForEach-Object { Write-Host ("  {0,-6} {1}" -f $_.Count, $_.Name) }
}

Write-Host "`nNext: cross-read with DSPM for AI -> Reports, then design + pilot the governance policy (Implementation Steps 3-5)." -ForegroundColor Cyan
