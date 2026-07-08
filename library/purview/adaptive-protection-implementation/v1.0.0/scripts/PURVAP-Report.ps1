<#
.SYNOPSIS
    PURVAP-Report.ps1 — summarize adaptive-protection DLP enforcement activity from the unified audit log to CSV (read-only).
.DESCRIPTION
    PURPOSE
        Queries the unified audit log for DLP enforcement activity over a window and produces a
        leadership rollup (by action/workload/time) to CSV — evidence of how protection adapted. It is
        READ-ONLY. The portal's Activity explorer / DLP alerts and the Conditional Access report-only
        insights are AUTHORITATIVE; this rollup is a convenience summary. Risk-level attribution is
        surfaced only where the audit records expose it — otherwise report by DLP action/workload and
        reconcile per-level detail in Activity explorer.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVAP-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\PURVAP-Report.ps1 -Days 14 -OutputCsv .\ap-rollup.csv

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession / Connect-ExchangeOnline), MFA-capable
        admin with audit-search rights, and unified audit logging enabled. No credentials in code.
    EXPECTED RESULTS
        A console summary and a CSV of DLP activity counts over the window. PASS = the rollup completes
        and reconciles with the portal (Activity explorer / DLP alerts). Empty results usually mean the
        policy is still in simulation with no matches yet, or audit ingestion latency — not an error.
.NOTES
    White-label. Read-only. Security & Compliance PowerShell / Exchange Online. No credentials in code.
    Portal (Activity explorer / DLP alerts / CA report-only) is authoritative.
#>

[CmdletBinding()]
param(
    [int]    $Days          = 7,
    [string] $OutputCsv     = ".\ap-enforcement-rollup.csv",
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect: {0}" -f $_.Exception.Message)
    return
}

$end   = (Get-Date)
$start = $end.AddDays(-1 * [Math]::Abs($Days))
Write-Section ("Searching DLP activity {0:yyyy-MM-dd} .. {1:yyyy-MM-dd}" -f $start, $end)

# DLP-related record types across workloads. We do not assume an adaptive-only record type; we pull DLP
# activity and roll it up. Per-level detail lives in Activity explorer where the audit blob lacks it.
$recordTypes = @('DLPEndpoint','ComplianceDLPExchange','ComplianceDLPSharePoint','Dlp')

$results = New-Object System.Collections.Generic.List[object]
foreach ($rt in $recordTypes) {
    try {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 5000 -ErrorAction SilentlyContinue
        foreach ($r in $batch) { $results.Add($r) }
    }
    catch {
        Write-Warning ("Record type '{0}' not searchable here: {1}" -f $rt, $_.Exception.Message)
    }
}

if ($results.Count -eq 0) {
    Write-Host 'No DLP audit records in the window. If the policy is still in SIMULATION with no matches,'
    Write-Host 'or audit ingestion is lagging, this is expected — confirm in Activity explorer / DLP alerts.'
    return
}

Write-Section 'Rollup (by workload / operation)'
$rows = foreach ($r in $results) {
    $op = $r.Operations
    if (-not $op) { $op = $r.RecordType }
    [pscustomobject]@{
        Workload  = "$($r.RecordType)"
        Operation = "$op"
        Date      = ([datetime]$r.CreationDate).ToString('yyyy-MM-dd')
    }
}
$summary = $rows | Group-Object Workload, Operation | Sort-Object Count -Descending |
    Select-Object @{n='Workload/Operation';e={$_.Name}}, Count
$summary | Format-Table -AutoSize

try {
    $rows | Group-Object Workload, Operation, Date |
        Select-Object @{n='Workload';e={($_.Name -split ', ')[0]}},
                      @{n='Operation';e={($_.Name -split ', ')[1]}},
                      @{n='Date';e={($_.Name -split ', ')[2]}},
                      Count |
        Sort-Object Date, Workload |
        Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("CSV written: {0}" -f (Resolve-Path $OutputCsv)) -ForegroundColor Green
}
catch {
    Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message)
}

Write-Section 'Reconcile'
Write-Host 'Compare this rollup to Purview -> Activity explorer / DLP alerts (per-risk-level detail) and'
Write-Host 'to Entra sign-in logs -> report-only (for CA-InsiderRisk-Elevated). The portal is authoritative.'
Write-Host 'Keep leadership reporting aggregate and privacy-respecting — identity follows IRM role-gated rules.'
