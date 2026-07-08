<#
.SYNOPSIS
    DLPCMMC-Report.ps1 — read-only CUI DLP match / false-positive & evidence report.
.DESCRIPTION
    PURPOSE
        Exports CUI DLP activity from the unified audit log (DLP rule matches across Exchange, SharePoint,
        OneDrive, Teams, and Endpoint) so you can classify each match as true-positive vs false-positive,
        compute the false-positive rate during the simulation dwell, and retain an EVIDENCE trail for
        assessment/audit. Read-only — queries the audit log only, makes no changes. Requires unified
        audit logging enabled and an audit/View-Only DLP role.
    HOW TO RUN
        powershell -File .\DLPCMMC-Report.ps1 -Days 14 -CsvPath .\DLPCMMC-Matches.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession). Widen -Days if the audit log is
        still catching up (events can lag).
    EXPECTED RESULTS
        A console summary (match count by workload/policy) and an optional CSV with one row per DLP match
        (time, user, workload, policy, and available detail) for TP/FP classification and evidence
        retention. PASS signal: matches for your CUI simulation policies appear; add a TP/FP column and
        compute the false-positive rate against the Gate B threshold.
.NOTES
    Purview — CMMC / CUI DLP Pack. Read-only (audit-log query). No changes, no credentials in code.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$CsvPath,
    [string]$PolicyFilter = 'CUI',
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
Write-Host ("=== CUI DLP Match / Evidence Report — last {0} days (read-only) ===" -f $Days) -ForegroundColor Cyan

# DLP match records surface under these audit record types across the workloads.
$recordTypes = 'DLPEndpoint','ComplianceDLPExchange','ComplianceDLPSharePoint'
$raw = @()
foreach ($rt in $recordTypes) {
    try {
        $chunk = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 5000 -ErrorAction SilentlyContinue
        if ($chunk) { $raw += $chunk }
    } catch {
        Write-Host ("Note: could not query record type {0} ({1})." -f $rt, $_.Exception.Message) -ForegroundColor Gray
    }
}

if (-not $raw -or $raw.Count -eq 0) {
    Write-Host 'No DLP match records returned. Check: audit logging enabled, dwell time elapsed, role, and widen -Days.' -ForegroundColor Yellow
    Write-Host 'This is a read-only query — nothing was changed.' -ForegroundColor Gray
    return
}

$rows = foreach ($r in $raw) {
    $data = $null
    try { $data = $r.AuditData | ConvertFrom-Json -ErrorAction SilentlyContinue } catch {}
    $policy = if ($data -and $data.PolicyName) { $data.PolicyName } elseif ($data -and $data.PolicyDetails) { ($data.PolicyDetails | ForEach-Object { $_.PolicyName }) -join ';' } else { '' }
    [pscustomobject]@{
        TimeUtc   = $r.CreationDate
        User      = $r.UserIds
        Workload  = if ($data) { $data.Workload } else { $r.RecordType }
        Operation = $r.Operations
        Policy    = $policy
        Object    = if ($data) { $data.ObjectId } else { '' }
        TP_or_FP  = ''   # <- classify each row TP/FP to compute the false-positive rate (Gate B)
    }
}

# Focus on CUI-named policies where possible (keeps the evidence set to this solution).
$cuiRows = @($rows | Where-Object { $_.Policy -match $PolicyFilter -or $_.Policy -eq '' })
$scope = if ($cuiRows.Count -gt 0) { $cuiRows } else { $rows }

Write-Host ("Total DLP match records: {0}   (CUI-matched: {1})" -f $rows.Count, @($rows | Where-Object { $_.Policy -match $PolicyFilter }).Count) -ForegroundColor Cyan
Write-Host '--- By workload ---' -ForegroundColor Cyan
$scope | Group-Object Workload | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize
Write-Host '--- By policy ---' -ForegroundColor Cyan
$scope | Group-Object Policy | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize

if ($CsvPath) {
    $scope | Sort-Object TimeUtc | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Evidence export written to {0} — add a TP/FP classification, then compute FP rate = FP / (TP+FP)." -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Retain this export as evidence; whether the FP rate/action is acceptable is a compliance sign-off.' -ForegroundColor Cyan
