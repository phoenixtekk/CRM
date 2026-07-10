<#
.SYNOPSIS
    DEFMDOP2-Report.ps1 — report post-delivery email threats and Attack Simulation user-risk (read-only).
.DESCRIPTION
    PURPOSE
        Produces two management-facing reports: (1) post-delivery threat activity over the window
        (delivered-then-detected mail, post-delivery clicks) via Advanced Hunting KQL, and (2) the
        Attack Simulation Training user-risk / repeat-offender picture (who was compromised, who was
        assigned training). Read-only — reporting only.
    HOW TO RUN
        pwsh -File .\DEFMDOP2-Report.ps1 -LookbackDays 30 -OutputCsv .\mdop2-report.csv

        Prereqs: Microsoft.Graph (ThreatHunting.Read.All; AttackSimulation.Read.All where available —
        BETA, verify). Government cloud: pass -Environment. Attack-simulation Graph endpoints are beta
        and may differ — verify current availability; the script degrades gracefully if unavailable.
    EXPECTED RESULTS
        A post-delivery threat table and an attack-simulation user-risk summary printed and, with
        -OutputCsv, written to CSV. Use it to review pilot results before Expand. Read-only.
.NOTES
    White-label. Read-only. Graph runHuntingQuery + attack-simulation (beta) reporting. No creds in code.
#>

[CmdletBinding()]
param(
    [int] $LookbackDays = 30,
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
$look = "ago({0}d)" -f $LookbackDays

try {
    Connect-MgGraph -Scopes 'ThreatHunting.Read.All','AttackSimulation.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host 'Connected to Microsoft Graph.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# --- 1. Post-delivery threat activity ---------------------------------------------------------------
Write-Section ("Post-delivery threat activity (last {0}d)" -f $LookbackDays)
$threatRows = @()
try {
    $kql = @"
EmailEvents
| where Timestamp > $look
| where DeliveryAction == 'Delivered' and (ThreatTypes has 'Phish' or ThreatTypes has 'Malware')
| summarize Messages=count(), Recipients=dcount(RecipientEmailAddress) by ThreatTypes, DeliveryLocation
| sort by Messages desc
"@
    $body = @{ Query = $kql } | ConvertTo-Json -Depth 4
    $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $threatRows = @($resp.results)
    if ($threatRows.Count -gt 0) { $threatRows | Format-Table -AutoSize }
    else { Write-Host 'No post-delivery phish/malware in the window (or table names differ — verify schema).' -ForegroundColor Yellow }
}
catch { Write-Warning ("Post-delivery threat query failed: {0}" -f $_.Exception.Message) }

# --- 2. Attack Simulation user-risk (beta endpoint; degrade gracefully) -----------------------------
Write-Section 'Attack Simulation Training — user-risk / repeat-offender summary (beta API, verify)'
$simRows = @()
try {
    $sims = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/attackSimulation/simulations'
    $vals = @($sims.value)
    if ($vals.Count -eq 0) { Write-Host 'No simulations returned (none run yet, or endpoint unavailable in your cloud).' -ForegroundColor Yellow }
    else {
        foreach ($s in $vals) {
            $simRows += [pscustomobject]@{
                Simulation   = $s.displayName
                Status       = $s.status
                LaunchedUtc  = $s.launchDateTime
                CompletedUtc = $s.completionDateTime
            }
        }
        $simRows | Format-Table -AutoSize
        Write-Host 'Drill into each simulation report in the portal for per-user compromise + training-assigned detail.' -ForegroundColor DarkGray
    }
}
catch { Write-Warning ("Attack-simulation report unavailable (beta / permissions / cloud): {0}" -f $_.Exception.Message) }

# --- Export ----------------------------------------------------------------------------------------
if ($OutputCsv) {
    try {
        $threatRows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        if ($simRows.Count -gt 0) { $simRows | Export-Csv -Path ($OutputCsv -replace '\.csv$','-sim.csv') -NoTypeInformation -Encoding UTF8 }
        Write-Host ("Wrote report CSV(s) alongside {0}" -f $OutputCsv) -ForegroundColor Green
    }
    catch { Write-Warning ("Could not write CSV: {0}" -f $_.Exception.Message) }
}

Write-Section 'Report complete'
Write-Host 'Review with stakeholders before Expand; a falling repeat-offender rate is the goal.'
