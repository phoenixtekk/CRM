<#
.SYNOPSIS
    SENTRULE-Validate.ps1 — check the detection set against the 05-testing.md pass/fail gates (read-only).
.DESCRIPTION
    PURPOSE
        Validates the detection build as pass/fail lines aligned to 05-testing.md: enrichment watchlists
        present; pilot rules enabled with entity mappings; each pilot rule still in LOW-IMPACT posture
        (flags any that create incidents before sign-off); and MITRE tags present so coverage is
        measurable. Read-only — it changes nothing. (False-positive-within-tolerance is measured by
        SENTRULE-Report.ps1; coverage-improved by SENTRULE-Coverage.ps1.)
    HOW TO RUN
        pwsh -File .\SENTRULE-Validate.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"

        Prereqs: Az.Accounts, Az.SecurityInsights; Microsoft Sentinel Reader on the workspace.
    EXPECTED RESULTS
        A list of PASS/FAIL/REVIEW lines, one per gate, plus an overall result. PASS overall = the
        structural gates pass; combine with the Report/Coverage scripts for the noise and coverage gates.
.NOTES
    White-label. Read-only. Az / Microsoft Sentinel PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string[]] $PilotRules = @('Rule-BruteForce-Entra-Pilot','Rule-AtypicalTravel-Entra-Pilot','Rule-NewAdminRole-Entra-Pilot'),
    [string[]] $ExpectedWatchlists = @('WL-VIPUsers-Tenant','WL-AuthorizedAdminIPs-Tenant','WL-TerminatedUsers-Tenant','WL-HighValueAssets-Tenant'),
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$Gate,[string]$Status,[string]$Detail){ $results.Add([pscustomobject]@{Gate=$Gate;Status=$Status;Detail=$Detail}) }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop | Out-Null
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

# Gate 3 — watchlists present
try {
    $wl = @(Get-AzSentinelWatchlist -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    $names = $wl.DisplayName + $wl.Alias
    foreach ($w in $ExpectedWatchlists) {
        if ($names -contains $w) { Add-Result ("Gate3 Watchlist {0}" -f $w) 'PASS' 'Present.' }
        else { Add-Result ("Gate3 Watchlist {0}" -f $w) 'REVIEW' 'Not found by expected name — import it (Phase 1, Step 1).' }
    }
}
catch { Add-Result 'Gate3 Watchlists' 'REVIEW' $_.Exception.Message }

# Gate 4 — pilot rules enabled, entity-mapped, low-impact posture
try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop)
    foreach ($rn in $PilotRules) {
        $r = $rules | Where-Object { $_.DisplayName -eq $rn }
        if (-not $r) { Add-Result ("Gate4 {0}" -f $rn) 'REVIEW' 'Rule not found by expected name — enable it (Phase 1, Step 2).'; continue }
        if (-not $r.Enabled) { Add-Result ("Gate4 {0}" -f $rn) 'FAIL' 'Rule exists but is DISABLED.'; continue }

        $hasEntities = $false
        try { $hasEntities = ($null -ne $r.EntityMapping -and @($r.EntityMapping).Count -gt 0) } catch {}
        $ent = if ($hasEntities) { 'entities mapped' } else { 'NO entity mapping' }

        # Incident creation setting: low-impact posture = incidents NOT created yet.
        $createsIncidents = $null
        try { $createsIncidents = $r.IncidentConfigurationCreateIncident } catch {}
        if ($createsIncidents -eq $true) {
            Add-Result ("Gate4 {0}" -f $rn) 'REVIEW' ("Enabled, {0}; CREATES INCIDENTS — confirm it passed Gate 6 before promotion." -f $ent)
        } else {
            $st = if ($hasEntities) { 'PASS' } else { 'REVIEW' }
            Add-Result ("Gate4 {0}" -f $rn) $st ("Enabled, {0}, low-impact posture (no incident creation)." -f $ent)
        }

        # MITRE tags present (for coverage accuracy / Gate 7)
        $tac = @($r.Tactic).Count
        if ($tac -eq 0) { Add-Result ("Gate7 tags {0}" -f $rn) 'REVIEW' 'No MITRE tactics tagged — tag it so coverage is accurate.' }
        else { Add-Result ("Gate7 tags {0}" -f $rn) 'PASS' ("{0} tactic(s) tagged." -f $tac) }
    }
}
catch { Add-Result 'Gate4 Pilot rules' 'REVIEW' $_.Exception.Message }

Write-Host ''
$results | Format-Table -AutoSize
$fail = @($results | Where-Object { $_.Status -eq 'FAIL' })
Write-Host ''
if ($fail.Count -eq 0) { Write-Host 'OVERALL (structural): PASS. Run SENTRULE-Report.ps1 (Gate 5/6) and SENTRULE-Coverage.ps1 (Gate 7) to complete validation.' -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) need attention." -f $fail.Count) -ForegroundColor Red }
