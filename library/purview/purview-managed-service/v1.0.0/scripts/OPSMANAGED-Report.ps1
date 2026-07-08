<#
.SYNOPSIS
    OPSMANAGED-Report.ps1 — roll a cycle's triage into a service report + SLO-adherence view (read-only).
.DESCRIPTION
    PURPOSE
        Produces `Managed Service – Service Report` for a cycle: it summarizes the triage CSV (from
        OPSMANAGED-Monitor.ps1 and the manual triage queue) into per-severity and per-workload counts,
        computes a simple SLO-adherence figure against a target response window, and exports the report as
        the baseline for the next cycle. Read-only — it summarizes and exports, it changes nothing. The
        portal is authoritative; reconcile before circulating.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Report.ps1 -TriageCsv .\opsmanaged-triage.csv
        powershell -ExecutionPolicy Bypass -File .\OPSMANAGED-Report.ps1 -TriageCsv .\in.csv -SloHours 8 -OutCsv .\service-report.csv
        Triage CSV columns (flexible): Severity, Workload, Policy, and optionally Opened/Closed timestamps
        and Owner for the SLO/ownership views.
    EXPECTED RESULTS
        Per-severity and per-workload counts, an SLO-adherence percentage (if Opened/Closed present), and
        (with -OutCsv) the report written out. PASS = the rollup reconciles with the portal and open items
        have an owner.
.NOTES
    White-label. Read-only. No credentials in code. The portal is authoritative — reconcile before issuing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string] $TriageCsv,
    [double] $SloHours = 8,
    [string] $OutCsv
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Test-Path $TriageCsv)) { Write-Error ("Triage CSV not found: {0}" -f $TriageCsv); return }
$rows = @(Import-Csv -Path $TriageCsv)
Write-Host ("`n=== Microsoft Purview Managed Service — service report ({0} triage rows) ===" -f $rows.Count) -ForegroundColor Cyan

# --- Per-severity counts ---------------------------------------------------------------------------
Write-Section 'By severity'
if ($rows | Get-Member -Name Severity -ErrorAction SilentlyContinue) {
    $rows | Group-Object Severity | Sort-Object Name | Select-Object Count, @{n='Severity';e={$(if($_.Name){$_.Name}else{'(unspecified)'})}} | Format-Table -AutoSize
} else { Write-Host '  No Severity column — add one to the triage queue.' -ForegroundColor Yellow }

# --- Per-workload counts ---------------------------------------------------------------------------
Write-Section 'By workload'
if ($rows | Get-Member -Name Workload -ErrorAction SilentlyContinue) {
    $rows | Group-Object Workload | Sort-Object Count -Descending | Select-Object Count, @{n='Workload';e={$_.Name}} | Format-Table -AutoSize
} else { Write-Host '  No Workload column.' -ForegroundColor Yellow }

# --- SLO adherence (if Opened/Closed present) ------------------------------------------------------
Write-Section ("SLO adherence (target: response within {0} h)" -f $SloHours)
$hasTimes = ($rows | Get-Member -Name Opened -ErrorAction SilentlyContinue) -and ($rows | Get-Member -Name Closed -ErrorAction SilentlyContinue)
if ($hasTimes) {
    $withTimes = @($rows | Where-Object { $_.Opened -and $_.Closed })
    $met = 0; $total = 0
    foreach ($r in $withTimes) {
        try {
            $o = [datetime]$r.Opened; $c = [datetime]$r.Closed
            $total++; if (($c - $o).TotalHours -le $SloHours) { $met++ }
        } catch {}
    }
    if ($total -gt 0) {
        $pct = [math]::Round(100.0 * $met / $total, 1)
        Write-Host ("  Items with response times: {0}   Met SLO: {1}   Adherence: {2}%" -f $total, $met, $pct) -ForegroundColor $(if($pct -ge 90){'Green'}elseif($pct -ge 75){'Yellow'}else{'Red'})
    } else { Write-Host '  No parseable Opened/Closed pairs — cannot compute adherence.' -ForegroundColor Yellow }
} else {
    Write-Host '  No Opened/Closed columns — add them to the triage queue to measure SLO adherence.' -ForegroundColor Yellow
}

# --- Ownership completeness ------------------------------------------------------------------------
Write-Section 'Ownership completeness'
if ($rows | Get-Member -Name Owner -ErrorAction SilentlyContinue) {
    $unowned = @($rows | Where-Object { [string]::IsNullOrWhiteSpace($_.Owner) })
    if ($unowned.Count -eq 0) { Write-Host '  PASS — every triage item has an owner.' -ForegroundColor Green }
    else { Write-Host ("  FAIL — {0} triage item(s) have no owner." -f $unowned.Count) -ForegroundColor Red }
} else { Write-Host '  No Owner column — add one so findings become owned work.' -ForegroundColor Yellow }

# --- Export ----------------------------------------------------------------------------------------
if ($OutCsv) { $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host ("`nService report exported to {0} (baseline for the next cycle)." -f $OutCsv) -ForegroundColor Green }
Write-Host 'Reconcile with the portal (authoritative) before circulating `Managed Service – Service Report`. Route determinations to governance.' -ForegroundColor DarkYellow
