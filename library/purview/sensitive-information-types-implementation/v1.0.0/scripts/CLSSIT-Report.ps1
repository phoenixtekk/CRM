<#
.SYNOPSIS
    CLSSIT-Report.ps1 — export the simulation policy's SIT matches for true/false-positive classification (read-only).
.DESCRIPTION
    PURPOSE
        Reads what the SIT measurement policy WOULD have matched (simulation mode) from the unified audit
        log over the last N days and exports one row per match event — policy, rule, workload, and the
        sensitive-information-type hit — so you can classify each as true positive or false positive and
        find the false-positive drivers during tuning (Phase 4). Read-only: it reads audit events only and
        changes nothing. For the actual matched CONTENT, cross-reference Purview Content Explorer (needs the
        Content Explorer viewer role) — this tool points you there; it does not read item bodies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CLSSIT-Report.ps1 -Days 14 -CsvPath .\CLSSIT-Matches.csv
        powershell -ExecutionPolicy Bypass -File .\CLSSIT-Report.ps1 -Days 14 -PolicyName 'SIT Measure - Payment Card - Simulation'
        Requires Security & Compliance PowerShell (Connect-IPPSSession) and permission to run
        Search-UnifiedAuditLog. Unified audit-log ingestion must be enabled. PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        A per-match table + optional CSV of simulation matches (policy/rule/workload/SIT). If audit
        ingestion is off or no matches yet, that is reported (not an error) — let the policy dwell longer.
.NOTES
    Purview — Sensitive Information Types Implementation. Read-only. Whether a match is a true/false positive
    and the acceptable FP threshold are your tuning decisions; SIT regulatory sufficiency is a compliance/legal determination.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$PolicyName,                 # optional: filter to one measurement policy
    [string]$CsvPath,
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'Installing ExchangeOnlineManagement module...' -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName -ShowBanner:$false } else { Connect-ExchangeOnline -ShowBanner:$false }
}

$end = Get-Date; $start = $end.AddDays(-$Days)
Write-Host ("=== SIT simulation matches — last {0} day(s) ({1:d} to {2:d}) ===" -f $Days, $start, $end) -ForegroundColor Cyan

# DLP match events across workloads. Simulation policies still record match events in the audit log.
$recordTypes = @('ComplianceDLPExchange','ComplianceDLPSharePoint')
$events = @()
foreach ($rt in $recordTypes) {
    try {
        $batch = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $rt -ResultSize 5000 -ErrorAction Stop
        $events += $batch
    } catch {
        Write-Host ("  Could not read record type {0}: {1}" -f $rt, $_.Exception.Message) -ForegroundColor DarkYellow
    }
}

if (-not $events -or $events.Count -eq 0) {
    Write-Host "  No DLP match events found. Either the policy needs more dwell time, unified audit-log ingestion is off, or nothing matched." -ForegroundColor Yellow
    Write-Host "  Verify ingestion: Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled" -ForegroundColor DarkGray
    return
}

$rows = @()
foreach ($e in $events) {
    $d = $null
    try { $d = $e.AuditData | ConvertFrom-Json } catch {}
    $pol = if ($d.PolicyDetails.PolicyName) { $d.PolicyDetails.PolicyName } elseif ($d.PolicyName) { $d.PolicyName } else { '(policy in AuditData)' }
    if ($PolicyName -and ($pol -notlike "*$PolicyName*")) { continue }
    # Pull SIT names from the rule's sensitive-info-type detail where present.
    $sitNames = @()
    try { $sitNames = @($d.PolicyDetails.Rules.ConditionsMatched.SensitiveInformation.SensitiveInformationTypeName) | Where-Object { $_ } } catch {}
    $rows += [pscustomobject]@{
        TimeUtc    = $e.CreationDate
        Workload   = $d.Workload
        Policy     = $pol
        Operation  = $d.Operation
        Location   = if ($d.ObjectId) { $d.ObjectId } else { $d.SiteUrl }
        SITs       = ($sitNames -join '; ')
        Classify   = ''      # you fill: TruePositive / FalsePositive
        Driver     = ''      # you fill: what caused a false positive
    }
}

if ($rows.Count -eq 0) {
    Write-Host ("  {0} DLP event(s) read, but none matched the policy filter '{1}'." -f $events.Count, $PolicyName) -ForegroundColor Yellow
    return
}

$rows | Sort-Object TimeUtc -Descending | Format-Table TimeUtc, Workload, Policy, SITs -AutoSize
Write-Host ("`n{0} match event(s). Classify each TruePositive/FalsePositive and note the driver." -f $rows.Count) -ForegroundColor Cyan
Write-Host "For the actual matched content, open Purview > Data classification > Content explorer (needs the Content Explorer viewer role)." -ForegroundColor DarkGray

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Wrote {0}" -f $CsvPath) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}
Write-Host "`nTuning: raise confidence and/or instance count first (SIT Threshold Register); copy the built-in SIT only if the dials aren't enough. Re-measure after each change." -ForegroundColor DarkGray
