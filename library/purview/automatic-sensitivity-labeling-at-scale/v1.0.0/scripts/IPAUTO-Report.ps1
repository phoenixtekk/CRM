<#
.SYNOPSIS
    IPAUTO-Report.ps1 — read-only export of auto-labeling coverage + simulation match counts to CSV; changes nothing.
.DESCRIPTION
    PURPOSE
        Exports a reporting snapshot for Microsoft Purview auto-labeling: every service-side auto-labeling
        policy with its MODE, applied label, and (where surfaced) its SIMULATION match/scan counts, plus its
        rule(s). Use it to review what a SIMULATION policy WOULD label (match counts) before enforcing, and
        to track coverage climbing after enforcement. Read-only — it writes only a CSV, changes no policy.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with the ExchangeOnlineManagement module, then Connect-IPPSSession.
        All policies:            .\IPAUTO-Report.ps1
        One policy:              .\IPAUTO-Report.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB"
        Optional label activity via Graph (read-only), if available:  add  -IncludeActivity
    EXAMPLE
        .\IPAUTO-Report.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -OutPath .\AutoLabel-Coverage-Report.csv
    .NOTES
        White-label Microsoft Purview tooling. Read-only. No credentials stored.
        Expected results: AutoLabel-Coverage-Report.csv (AutoLabel Coverage - Estate - Report) listing
        policies (mode, label, workload, simulation/match counts where exposed) and rules. PASS = the CSV
        is produced without error and the counts are reviewable with the data owner.
        VERIFY IN YOUR TENANT: simulation match/count property names and scan latency vary by tenant/version;
        a zero/blank count may mean "still scanning", not "nothing matches" — allow scan time before concluding.
#>
[CmdletBinding()]
param(
    [string]$PolicyName,
    [string]$OutPath = ".\AutoLabel-Coverage-Report.csv",
    [switch]$IncludeActivity
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPAUTO Report — auto-labeling coverage + simulation counts (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Get-AutoSensitivityLabelPolicy not available. Run Connect-IPPSSession; check licensing/role (Req 2.2/2.3)." -ForegroundColor Red
    return
}

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($type, $name, $mode, $detail) {
    $rows.Add([pscustomobject]@{ ItemType = $type; Name = $name; Mode = $mode; Detail = $detail })
}

# Best-effort extraction of any simulation/match count exposed on the policy object (names vary by version).
function Get-MatchCount($pol) {
    foreach ($p in $pol.PSObject.Properties) {
        if ($p.Name -match "(?i)match|itemcount|count|processeditem" -and $p.Value -match '^\d+$') {
            return ("{0}={1}" -f $p.Name, $p.Value)
        }
    }
    return "match-count not surfaced (verify in tenant / allow scan time)"
}

$policies = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)
if ($PolicyName) { $policies = @($policies | Where-Object { $_.Name -eq $PolicyName }) }
if ($policies.Count -eq 0) { Write-Host "No matching auto-labeling policies found." -ForegroundColor Yellow }

Write-Host "`n[1/2] Service-side auto-labeling policies (mode + simulation/coverage counts)..." -ForegroundColor Cyan
foreach ($a in $policies) {
    $mc = Get-MatchCount $a
    $isSim = @('TestWithoutNotifications', 'TestWithNotifications') -contains "$($a.Mode)"
    $stage = if ($isSim) { 'SIMULATION (would-label counts)' } else { 'ENFORCED (applied-label coverage)' }
    Add-Row "AutoLabelPolicy" $a.Name "$($a.Mode)" ("Label={0}; Workload={1}; Stage={2}; {3}" -f $a.ApplySensitivityLabel, $a.Workload, $stage, $mc)
    Write-Host ("  {0}  [{1}]  {2}" -f $a.Name, $a.Mode, $mc) -ForegroundColor Gray
}

Write-Host "[2/2] Auto-labeling rules (conditions per policy)..." -ForegroundColor Cyan
if (Get-Command Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue) {
    foreach ($r in @(Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue)) {
        if ($PolicyName -and ("$($r.Policy)" -notmatch [regex]::Escape($PolicyName))) { continue }
        Add-Row "AutoLabelRule" $r.Name "" ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled)
    }
}

if ($IncludeActivity) {
    Write-Host "[opt] Label activity via Microsoft Graph (read-only)..." -ForegroundColor Cyan
    if (Get-Command Get-MgSecurityLabelSensitivityLabel -ErrorAction SilentlyContinue -ErrorVariable $null) {
        Write-Host "  Graph label endpoints available — extend here for tenant label-activity reporting (verify the current Graph endpoint/permissions in your tenant)." -ForegroundColor Yellow
    } else {
        Write-Host "  Graph label-activity cmdlet not available in this session — skipping (Connect-MgGraph with the right scopes to enable). Verify the current endpoint in your tenant." -ForegroundColor Yellow
    }
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host ("{0} row(s) -> {1}  (AutoLabel Coverage - Estate - Report)" -f $rows.Count, $OutPath) -ForegroundColor Green
Write-Host "Review SIMULATION match counts with the data owner BEFORE enforcing; track ENFORCED counts on a cadence after." -ForegroundColor Cyan
