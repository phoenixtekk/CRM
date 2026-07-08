<#
.SYNOPSIS
    DLPGDPR-Report.ps1 — read-only EU-personal-data DLP match / false-positive tuning report from the unified audit log (safe: read-only).
.DESCRIPTION
    PURPOSE
        Exports DLP rule matches (Exchange, SharePoint/OneDrive, Teams, and Endpoint) over a time window so
        you can classify true-positive vs false-positive and compute the false-positive rate that gates
        simulation-to-enforcement for the GDPR/PII policy set. Works for policies in simulation AND
        enforcement — simulation matches are logged the same way. Read-only — queries
        Search-UnifiedAuditLog only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPGDPR-Report.ps1 -Days 14 -CsvPath .\DLPGDPR-Matches.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and audit logging enabled.
.EXAMPLE
    .\DLPGDPR-Report.ps1 -Days 14 -CsvPath .\DLPGDPR-Matches.csv
    Breaks matches down by workload and policy and exports a per-event CSV with a blank Disposition column.
.NOTES
    Purview — GDPR / PII DLP Pack. Read-only reporting from the unified audit log. No changes made.
    Note: exported rows contain personal-data evidence — store and share the CSV under least-privilege access.
    Expected results: classify each row TP/FP, compute FP rate = FP / (TP+FP); PASS = rate at/under the agreed threshold.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$start = (Get-Date).AddDays(-$Days)
$end   = Get-Date
# DLP record types across the locations this solution covers.
$recordTypes = 'ComplianceDLPExchange','ComplianceDLPSharePoint','DLPEndpoint'

Write-Host ("=== GDPR/PII DLP matches: {0:yyyy-MM-dd} to {1:yyyy-MM-dd} ({2} days) ===" -f $start, $end, $Days) -ForegroundColor Cyan

$events = @()
foreach ($rt in $recordTypes) {
    $sessionId = "DLPGDPR-$rt-$(Get-Random)"
    do {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt `
                    -SessionId $sessionId -SessionCommand ReturnLargeSet -ResultSize 5000 -ErrorAction SilentlyContinue
        if ($batch) { $events += $batch }
    } while ($batch -and $batch.Count -eq 5000)
}

if (-not $events -or $events.Count -eq 0) {
    Write-Host 'No DLP matches found in the window. If policies are freshly created, allow dwell time and re-run.' -ForegroundColor Yellow
    return
}

$rows = foreach ($e in $events) {
    $d = $null
    try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    $policyName = $null; $ruleName = $null; $sit = $null; $action = $null
    if ($d) {
        if ($d.PolicyDetails) {
            $policyName = ($d.PolicyDetails | ForEach-Object { $_.PolicyName }) -join '; '
            $rule = $d.PolicyDetails.Rules | Select-Object -First 1
            if ($rule) {
                $ruleName = $rule.RuleName
                $action   = ($rule.Actions -join ', ')
                if ($rule.ConditionsMatched -and $rule.ConditionsMatched.SensitiveInformation) {
                    $sit = ($rule.ConditionsMatched.SensitiveInformation | ForEach-Object { $_.SensitiveInformationTypeName }) -join '; '
                }
            }
        }
    }
    [pscustomobject]@{
        TimeUtc     = $e.CreationDate
        Workload    = $e.RecordType
        User        = $e.UserIds
        Policy      = $policyName
        Rule        = $ruleName
        SIT         = $sit
        Action      = $action
        Disposition = ''   # <-- mark TP or FP here
    }
}

Write-Host '--- Matches by workload ---' -ForegroundColor Cyan
$rows | Group-Object Workload | Sort-Object Count -Descending |
    Select-Object @{n='Workload';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host '--- Matches by policy ---' -ForegroundColor Cyan
$rows | Where-Object Policy | Group-Object Policy | Sort-Object Count -Descending |
    Select-Object @{n='Policy';e={$_.Name}}, Count | Format-Table -AutoSize

Write-Host ("Total DLP match events: {0}" -f $rows.Count) -ForegroundColor Green

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Exported to {0} — classify each row TP/FP in the Disposition column, then compute FP rate = FP / (TP+FP)." -f $CsvPath) -ForegroundColor Green
    Write-Host 'Reminder: this CSV contains personal-data evidence — protect it under least-privilege access.' -ForegroundColor Yellow
} else {
    Write-Host 'Tip: pass -CsvPath to export for TP/FP classification and false-positive-rate calculation.' -ForegroundColor Cyan
}
