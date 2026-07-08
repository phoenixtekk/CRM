<#
.SYNOPSIS
    PURVDSPM-Tracker.ps1 — snapshot DSPM recommendations and reduction-policy states for tracking (read-only).
.DESCRIPTION
    PURPOSE
        Captures the before/after state you drive to completion: the current DLP and auto-labeling policy
        states (the levers DSPM recommends) and their mode, so re-running after acting on recommendations
        shows movement. Because DSPM recommendation objects are surfaced primarily in the portal and via
        evolving APIs, this tracker records the policy-state evidence and lets you attach the portal
        recommendation status alongside. Read-only.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell:
          Connect-IPPSSession
          .\PURVDSPM-Tracker.ps1
        Re-run after acting on recommendations and compare to the prior snapshot (Testing doc, Test 10).
    EXPECTED RESULTS
        DSPM-Recommendations-Estate-Tracker.csv: each DLP / auto-labeling policy with its mode/enabled
        state and a Snapshot timestamp — the baseline to re-measure posture improvement against.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: DSPM's own recommendation list lives in Purview → DSPM → Recommendations; its
    programmatic surface is evolving and not assumed here. This tracker records the authoritative
    policy-state evidence via standard cmdlets (Get-DlpCompliancePolicy, Get-AutoSensitivityLabelPolicy);
    add the portal recommendation status in the Notes column as you work the queue.
#>
[CmdletBinding()]
param(
    [string]$OutPath = ".\DSPM-Recommendations-Estate-Tracker.csv"
)

$ErrorActionPreference = "Stop"
$snapshot = (Get-Date).ToString("s")
Write-Host "=== PURVDSPM Tracker — recommendation/action baseline (read-only) ===" -ForegroundColor Cyan

try { Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first." -ForegroundColor Red; return }

$rows = [System.Collections.Generic.List[object]]::new()

foreach ($d in (Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    $rows.Add([pscustomobject]@{
        Snapshot = $snapshot; Lever = "DLP"; Name = $d.Name
        Mode = $d.Mode; Enabled = $d.Enabled; Workload = $d.Workload
        Notes = ""   # <- record the related DSPM recommendation status from the portal here
    })
}
try {
    foreach ($a in (Get-AutoSensitivityLabelPolicy -ErrorAction Stop)) {
        $rows.Add([pscustomobject]@{
            Snapshot = $snapshot; Lever = "AutoLabel"; Name = $a.Name
            Mode = $a.Mode; Enabled = ($a.Mode -ne 'Disable'); Workload = ($a.Workload -join ",")
            Notes = ""
        })
    }
} catch { Write-Host "  Auto-labeling not readable (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

# Append if the tracker already exists, so successive snapshots accumulate for trend comparison
if (Test-Path $OutPath) {
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8 -Append
    Write-Host ("Appended {0} row(s) to existing tracker {1}" -f $rows.Count, $OutPath) -ForegroundColor Green
} else {
    $rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Baseline written to {0}  (DSPM Recommendations - Estate - Tracker)" -f $OutPath) -ForegroundColor Green
}

Write-Host "`nPolicy states this snapshot:" -ForegroundColor Cyan
$rows | Sort-Object Lever, Name | ForEach-Object { Write-Host ("  {0,-10} {1,-45} Mode={2}" -f $_.Lever, $_.Name, $_.Mode) }
Write-Host "`nNote: add each portal DSPM recommendation's status in the Notes column, then re-run after acting to show movement." -ForegroundColor Cyan
