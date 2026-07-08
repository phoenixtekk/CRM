<#
.SYNOPSIS
    IRMDEPART-Report.ps1 — roll up departing-user IRM alert/case activity from the audit log (read-only).
.DESCRIPTION
    PURPOSE
        Produces a leadership rollup of Insider Risk Management activity that is readable from the unified
        audit log — counts of IRM-related administrative and review events over a time window, grouped by
        operation — and writes it to CSV. It is a SUMMARY aid: the authoritative alert and case detail
        lives in the Purview portal (Insider Risk Management -> Alerts / Cases). Read-only — it changes
        nothing and does not de-anonymize anyone.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IRMDEPART-Report.ps1 -DaysBack 30 -OutputCsv .\IRMDEPART-rollup.csv

        Connects to Security & Compliance PowerShell (Connect-IPPSSession). Uses Search-UnifiedAuditLog
        filtered to the Insider Risk Management workload. Requires unified audit-log ingestion to be on
        (see IRMDEPART-Test-HRConnector.ps1) and audit-read permission. Verify capability/record
        availability against your licensing/tenant.
    EXPECTED RESULTS
        A console summary (event counts by operation over the window) and a CSV at the path you gave.
        PASS = the search completes and the rollup reconciles with the portal Alerts/Cases dashboards.
        If nothing is returned, confirm audit ingestion is on and widen -DaysBack; the portal remains
        authoritative.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell. No credentials in code. Portal is authoritative.
#>

[CmdletBinding()]
param(
    [ValidateRange(1,180)]
    [int]    $DaysBack   = 30,
    [string] $OutputCsv  = ".\IRMDEPART-rollup.csv",
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message)
    return
}

$start = (Get-Date).AddDays(-$DaysBack)
$end   = Get-Date

Write-Section ("Searching IRM audit activity ({0} days)" -f $DaysBack)
$records = @()
try {
    # RecordType for Insider Risk Management activity; fall back to a free-text workload filter if the
    # named record type is not accepted in this tenant/version.
    try {
        $records = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType 'InsiderRiskManagementAlert' -ResultSize 5000 -ErrorAction Stop)
    }
    catch {
        Write-Warning 'RecordType InsiderRiskManagementAlert not accepted here; retrying with a workload free-text filter.'
        $records = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -FreeText 'InsiderRisk' -ResultSize 5000 -ErrorAction Stop)
    }
}
catch {
    Write-Warning ("Audit search failed: {0}" -f $_.Exception.Message)
    Write-Host 'Confirm unified audit-log ingestion is ON (IRMDEPART-Test-HRConnector.ps1) and that you have'
    Write-Host 'audit-read permission. The Purview portal Alerts/Cases dashboards remain authoritative.'
    return
}

if ($records.Count -eq 0) {
    Write-Host 'No IRM audit records returned for the window.' -ForegroundColor Yellow
    Write-Host 'Widen -DaysBack, confirm audit ingestion is on, and check the portal (authoritative).'
    return
}

Write-Section 'Rollup by operation'
$byOp = $records | Group-Object Operations | Sort-Object Count -Descending |
    Select-Object @{n='Operation';e={$_.Name}}, Count
$byOp | Format-Table -AutoSize
Write-Host ("Total IRM audit records in window: {0}" -f $records.Count)

try {
    $byOp | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("Rollup written to {0}" -f $OutputCsv) -ForegroundColor Green
}
catch {
    Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message)
}

Write-Section 'Note'
Write-Host 'This rollup summarizes AUDIT activity only and does not de-anonymize users. The authoritative'
Write-Host 'alert severity/status and case detail for IRM-DepartingUser-DataTheft live in'
Write-Host 'purview.microsoft.com -> Insider Risk Management -> Alerts / Cases. Reconcile this rollup with'
Write-Host 'those dashboards (testing Gate 9).'
