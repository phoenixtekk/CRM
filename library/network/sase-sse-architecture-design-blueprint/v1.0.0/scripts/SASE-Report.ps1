<#
.SYNOPSIS
    SASE-Report.ps1 - Read-only capability-coverage + gap report and operating-model KPI view.

    PURPOSE:
        Produces the run dashboard for a SASE/SSE estate: a coverage/gap matrix across the capability
        services (SWG, ZTNA, CASB, SSL inspection, DLP-adjacent) and the roadmap phases, plus the
        operating-model KPI view (steering coverage, phase rollout progress, targeting-group
        population). It derives the identity/endpoint side from Microsoft Graph (read-only) and merges
        a small operator-maintained status CSV for the Netskope-side capability state (which is
        deferred to the Netskope console). Output is a CSV plus a console summary.

        Why a status CSV: Netskope capability state (e.g. "SWG enabled for Broad") is read in the
        Netskope console per Netskope documentation, not invented here. The operator records each
        phase/capability status in the status CSV; this report combines it with the live Graph
        targeting-group population to compute coverage and surface gaps.

    HOW TO RUN:
        1. Install the module (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. (Optional) Prepare a status CSV with columns: Phase, Capability, Stage, Status
           (Status one of: NotStarted | Pilot | Broad | Complete). A template is written if absent.
        3. Run (read-only):
             .\SASE-Report.ps1 -StatusCsv ".\SASE Phase Status - Edge - Program.csv" `
                               -OutputCsv ".\SASE Coverage Report - Edge - Run.csv"

    EXPECTED RESULTS:
        A coverage CSV (one row per phase/capability with stage, status, pilot/broad group sizes) and a
        console KPI summary (phases complete, steering/targeting coverage, open gaps). No tenant changes
        are made - strictly read-only.

.NOTES
    Network Solutions - read-only. The repeatable way.
#>

[CmdletBinding()]
param(
    [string]$StatusCsv = ".\SASE Phase Status - Edge - Program.csv",
    [string]$OutputCsv = ".\SASE Coverage Report - Edge - Run.csv",
    [string]$GroupNamePrefix = "SASE Phase Scope"
)

$ErrorActionPreference = 'Stop'

# Canonical phase/capability map for the roadmap.
$matrix = @(
    [pscustomobject]@{ Phase='Phase 0'; Capability='Steering/Baseline';  Scope='Baseline' }
    [pscustomobject]@{ Phase='Phase 1'; Capability='SWG';                Scope='SWG' }
    [pscustomobject]@{ Phase='Phase 1'; Capability='SSL Inspection';     Scope='SWG' }
    [pscustomobject]@{ Phase='Phase 2'; Capability='CASB';               Scope='CASB' }
    [pscustomobject]@{ Phase='Phase 3'; Capability='ZTNA';               Scope='ZTNA' }
    [pscustomobject]@{ Phase='Phase 4'; Capability='DLP-adjacent hooks'; Scope='DataHook' }
)

# --- Write a status template if none exists, then load it ---
if (-not (Test-Path $StatusCsv)) {
    Write-Warning "Status CSV not found - writing a template to $StatusCsv (edit it, set Status per row from the Netskope console state)."
    $matrix | ForEach-Object {
        [pscustomobject]@{ Phase=$_.Phase; Capability=$_.Capability; Stage='-'; Status='NotStarted' }
    } | Export-Csv -Path $StatusCsv -NoTypeInformation -Encoding UTF8
}
$status = Import-Csv $StatusCsv

# --- Live targeting-group population from Graph (read-only) ---
$groupSizes = @{}
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
    $groups = Get-MgGroup -Filter "startswith(displayName,'$GroupNamePrefix')" -All -ErrorAction Stop
    foreach ($g in $groups) {
        $groupSizes[$g.DisplayName] = (Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
    }
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Warning "Graph group sizing unavailable ($($_.Exception.Message)); report will show group sizes as 'n/a'."
}

function Get-Size {
    param([string]$name)
    if ($groupSizes.ContainsKey($name)) { return $groupSizes[$name] } else { return 'n/a' }
}

# --- Build coverage rows ---
$report = New-Object System.Collections.Generic.List[object]
foreach ($m in $matrix) {
    $s = $status | Where-Object { $_.Phase -eq $m.Phase -and $_.Capability -eq $m.Capability } | Select-Object -First 1
    $st = if ($s) { $s.Status } else { 'NotStarted' }
    $report.Add([pscustomobject]@{
        Phase       = $m.Phase
        Capability  = $m.Capability
        Status      = $st
        PilotGroup  = "$GroupNamePrefix - $($m.Scope) - Pilot"
        PilotSize   = Get-Size "$GroupNamePrefix - $($m.Scope) - Pilot"
        BroadGroup  = "$GroupNamePrefix - $($m.Scope) - Broad"
        BroadSize   = Get-Size "$GroupNamePrefix - $($m.Scope) - Broad"
        Gap         = if ($st -in @('NotStarted','Pilot')) { 'OPEN' } else { 'closed' }
    })
}

$report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("Coverage report written to {0}" -f $OutputCsv) -ForegroundColor Green

# --- KPI / gap summary ---
$complete = ($report | Where-Object { $_.Status -eq 'Complete' }).Count
$openGaps = ($report | Where-Object { $_.Gap -eq 'OPEN' }).Count
Write-Host "`n=== SASE coverage / KPI summary ===" -ForegroundColor Cyan
Write-Host ("  Capabilities complete : {0} / {1}" -f $complete, $report.Count)
Write-Host ("  Open gaps             : {0}" -f $openGaps)
Write-Host "`n=== Per-capability status ===" -ForegroundColor Cyan
$report | ForEach-Object {
    Write-Host ("  {0,-8} {1,-20} {2,-12} Pilot={3,-5} Broad={4,-5} [{5}]" -f `
        $_.Phase, $_.Capability, $_.Status, $_.PilotSize, $_.BroadSize, $_.Gap)
}
Write-Host "`nReminder: per-capability Status is read from the Netskope console (per Netskope docs) into the status CSV; group sizes are live from Graph." -ForegroundColor Yellow
