<#
.SYNOPSIS
    DLPOD-Report.ps1 — read-only OneDrive DLP match / false-positive tuning report from the unified audit log.
.DESCRIPTION
    PURPOSE
        Exports DLP rule matches for OneDrive/SharePoint over a time window so you can classify
        true-positive vs false-positive and compute the false-positive rate that gates
        simulation-to-enforcement. Works for policies in simulation AND enforcement — simulation matches
        are logged the same way. Read-only — queries Search-UnifiedAuditLog only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPOD-Report.ps1 -Days 14 -CsvPath .\DLPOD-Matches.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and audit logging enabled.
    EXPECTED RESULTS
        A console breakdown of DLP matches by policy, and a per-event CSV (time, user, workload, policy,
        rule, SIT, action) with a blank 'Disposition' column for you to mark TP/FP. Compute FP rate =
        FP / (TP + FP). PASS gate: FP rate at/under the agreed threshold with true positives (including
        external over-shares) still present.
.NOTES
    Purview — OneDrive for Business DLP. Read-only reporting from the unified audit log. No changes made.
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
# OneDrive DLP events are carried in the SharePoint DLP record type (OneDrive is a SharePoint workload).
$recordTypes = 'ComplianceDLPSharePoint'

Write-Host ("=== OneDrive DLP matches: {0:yyyy-MM-dd} to {1:yyyy-MM-dd} ({2} days) ===" -f $start, $end, $Days) -ForegroundColor Cyan

$events = @()
foreach ($rt in $recordTypes) {
    $sessionId = "DLPOD-$rt-$(Get-Random)"
    do {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt `
                    -SessionId $sessionId -SessionCommand ReturnLargeSet -ResultSize 5000 -ErrorAction SilentlyContinue
        if ($batch) { $events += $batch }
    } while ($batch -and $batch.Count -eq 5000)
}

if (-not $events -or $events.Count -eq 0) {
    Write-Host 'No OneDrive/SharePoint DLP matches found in the window. If the policy is freshly created, allow dwell time and re-run.' -ForegroundColor Yellow
    return
}

$rows = foreach ($e in $events) {
    $d = $null
    try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    $policyName = $null; $ruleName = $null; $sit = $null; $action = $null; $workload = $e.RecordType; $target = $null
    if ($d) {
        if ($d.Workload)   { $workload = $d.Workload }         # 'OneDrive' vs 'SharePoint'
        if ($d.ObjectId)   { $target   = $d.ObjectId }
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
        Workload    = $workload
        User        = $e.UserIds
        Target      = $target
        Policy      = $policyName
        Rule        = $ruleName
        SIT         = $sit
        Action      = $action
        Disposition = ''   # <-- mark TP or FP here
    }
}

# Focus the summary on OneDrive where the workload is distinguishable.
$odRows = @($rows | Where-Object { $_.Workload -match 'OneDrive' })
Write-Host ("OneDrive-workload matches: {0}   (all SPO+OneDrive DLP events in window: {1})" -f $odRows.Count, $rows.Count) -ForegroundColor Green

Write-Host '--- Matches by policy ---' -ForegroundColor Cyan
$rows | Where-Object Policy | Group-Object Policy | Sort-Object Count -Descending |
    Select-Object @{n='Policy';e={$_.Name}}, Count | Format-Table -AutoSize

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Exported to {0} — classify each row TP/FP in the Disposition column, then compute FP rate = FP / (TP+FP)." -f $CsvPath) -ForegroundColor Green
} else {
    Write-Host 'Tip: pass -CsvPath to export for TP/FP classification and false-positive-rate calculation.' -ForegroundColor Cyan
}
