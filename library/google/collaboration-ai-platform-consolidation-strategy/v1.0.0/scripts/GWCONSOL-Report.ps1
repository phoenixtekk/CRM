<#
.SYNOPSIS
    GWCONSOL-Report.ps1 — Read-only consolidation/cost-savings + decommission-readiness report.
.DESCRIPTION
    PURPOSE
        Produces the run dashboard for a collaboration + AI platform consolidation: a
        decommission-readiness matrix per legacy system (candidate) and the operating-model KPI view
        (coexistence footprint, decommission progress, realized savings, licence reduction). It derives
        the live licence/group signals from Microsoft Graph (read-only) and merges a small
        operator-maintained status CSV that records, per candidate, its wave, its exit-criteria status,
        and the monthly run-rate its retirement removes (from the cost model). Output is a CSV plus a
        console summary.
        Why a status CSV: coexistence-exit-criteria status and per-system cost are decided by the
        program (governance clearance, dependency sign-off, contract run-rate) — not invented here. The
        operator records each candidate's status/cost in the status CSV; this report combines it with
        live Graph licence assignment to compute realized vs projected savings and decommission
        readiness.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCONSOL-Report.ps1
        Optional: -StatusCsv (candidate status/cost input; a template is written if absent) and
        -OutputCsv. Required Graph scopes (read-only): Group.Read.All, Directory.Read.All.
        Install once: Install-Module Microsoft.Graph -Scope CurrentUser
    EXPECTED RESULTS
        A decommission-readiness CSV (one row per candidate with wave, exit-criteria status, monthly
        savings, licence assignment, and a Readiness verdict) and a console KPI summary (candidates
        retired, coexistence footprint, realized vs projected monthly savings, open blockers). No tenant
        changes are made — strictly read-only.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$StatusCsv = ".\Consolidation Candidate Status - Platform - Program.csv",
    [string]$OutputCsv = ".\Consolidation Readiness Report - Platform - Run.csv"
)

$ErrorActionPreference = 'Stop'

# Canonical decommission-candidate map for the consolidation (legacy systems -> wave + representative SKU hint).
$candidates = @(
    [pscustomobject]@{ Candidate='Exchange Online (mail)';        Wave='Wave 1 - Collab';    SkuHint='EXCHANGE' }
    [pscustomobject]@{ Candidate='SharePoint / OneDrive (files)'; Wave='Wave 1 - Collab';    SkuHint='SHAREPOINT' }
    [pscustomobject]@{ Candidate='Teams (chat/meetings)';         Wave='Wave 1 - Collab';    SkuHint='TEAMS' }
    [pscustomobject]@{ Candidate='Microsoft 365 Copilot (AI)';    Wave='Wave 2 - AI';        SkuHint='COPILOT' }
    [pscustomobject]@{ Candidate='Duplicate identity/mgmt surface';Wave='Wave 3 - Identity'; SkuHint='' }
)

# --- Write a status template if none exists, then load it ---
if (-not (Test-Path $StatusCsv)) {
    Write-Warning "Status CSV not found - writing a template to $StatusCsv (edit it: set ExitCriteriaStatus + MonthlySavings per candidate)."
    $candidates | ForEach-Object {
        [pscustomobject]@{
            Candidate          = $_.Candidate
            Wave               = $_.Wave
            ExitCriteriaStatus = 'Open'    # Open | Met | Retired
            GovernanceCleared  = 'No'      # Yes | No
            DependenciesClear  = 'No'      # Yes | No
            MonthlySavings     = 0         # run-rate removed on retirement (from the cost model)
        }
    } | Export-Csv -Path $StatusCsv -NoTypeInformation -Encoding UTF8
}
$status = Import-Csv $StatusCsv

# --- Live licence assignment per candidate SKU hint from Graph (read-only) ---
$skuAssigned = @{}
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes @("Group.Read.All","Directory.Read.All") -NoWelcome
    $skus = Get-MgSubscribedSku -All -ErrorAction Stop
    foreach ($c in $candidates) {
        if (-not $c.SkuHint) { continue }
        $sum = 0
        foreach ($s in $skus) { if ($s.SkuPartNumber -match $c.SkuHint) { $sum += [int]$s.ConsumedUnits } }
        $skuAssigned[$c.Candidate] = $sum
    }
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Warning "Graph licence sizing unavailable ($($_.Exception.Message)); report will show licence assignment as 'n/a'."
}

function Get-Assigned {
    param([string]$name)
    if ($skuAssigned.ContainsKey($name)) { return $skuAssigned[$name] } else { return 'n/a' }
}

# --- Build decommission-readiness rows ---
$report = New-Object System.Collections.Generic.List[object]
foreach ($c in $candidates) {
    $s = $status | Where-Object { $_.Candidate -eq $c.Candidate } | Select-Object -First 1
    $exit = if ($s) { $s.ExitCriteriaStatus } else { 'Open' }
    $gov  = if ($s) { $s.GovernanceCleared } else { 'No' }
    $dep  = if ($s) { $s.DependenciesClear } else { 'No' }
    $save = if ($s -and $s.MonthlySavings) { [int]$s.MonthlySavings } else { 0 }

    # Readiness: READY only when exit criteria met, governance cleared, and dependencies clear.
    $ready = if ($exit -eq 'Retired') { 'RETIRED' }
             elseif ($exit -eq 'Met' -and $gov -eq 'Yes' -and $dep -eq 'Yes') { 'READY' }
             else { 'BLOCKED' }

    $report.Add([pscustomobject]@{
        Candidate          = $c.Candidate
        Wave               = $c.Wave
        ExitCriteriaStatus = $exit
        GovernanceCleared  = $gov
        DependenciesClear  = $dep
        AssignedLicences   = Get-Assigned $c.Candidate
        MonthlySavings     = $save
        Readiness          = $ready
    })
}

$report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("Decommission-readiness report written to {0}" -f $OutputCsv) -ForegroundColor Green

# --- KPI / savings summary ---
$total     = $report.Count
$retired   = ($report | Where-Object { $_.Readiness -eq 'RETIRED' }).Count
$ready     = ($report | Where-Object { $_.Readiness -eq 'READY' }).Count
$blocked   = ($report | Where-Object { $_.Readiness -eq 'BLOCKED' }).Count
$coexist   = $total - $retired
$projected = ($report | Measure-Object -Property MonthlySavings -Sum).Sum
$realized  = ($report | Where-Object { $_.Readiness -eq 'RETIRED' } | Measure-Object -Property MonthlySavings -Sum).Sum

Write-Host "`n=== Consolidation KPI summary ===" -ForegroundColor Cyan
Write-Host ("  Candidates retired        : {0} / {1}" -f $retired, $total)
Write-Host ("  Coexistence footprint     : {0} legacy systems still running" -f $coexist)
Write-Host ("  Ready to decommission     : {0}" -f $ready)
Write-Host ("  Blocked (open exit crit.) : {0}" -f $blocked)
Write-Host ("  Realized monthly savings  : {0} / {1} projected" -f $realized, $projected)
Write-Host "`n=== Per-candidate readiness ===" -ForegroundColor Cyan
$report | ForEach-Object {
    Write-Host ("  {0,-32} {1,-16} Exit={2,-8} Gov={3,-3} Dep={4,-3} Lic={5,-5} Save={6,-5} [{7}]" -f `
        $_.Candidate, $_.Wave, $_.ExitCriteriaStatus, $_.GovernanceCleared, $_.DependenciesClear, `
        $_.AssignedLicences, $_.MonthlySavings, $_.Readiness)
}
Write-Host "`nReminder: exit-criteria status, governance, dependencies, and per-system savings are recorded by the program in the status CSV; licence assignment is live from Graph." -ForegroundColor Yellow
