<#
.SYNOPSIS
    SENTRULE-Report.ps1 — per-rule alert volume and false-positive (benign) rate for tuning (read-only).
.DESCRIPTION
    PURPOSE
        Produces the tuning data that decides when a rule is trustworthy: per-rule ALERT volume over the
        window (from SecurityAlert) and, from closed incidents' classification, the BENIGN /
        FALSE-POSITIVE rate per rule (from SecurityIncident). Also lists the top entities driving alerts.
        This is the signal for Gate 5/6 in 05-testing.md. Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\SENTRULE-Report.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -Days 7 -TolerancePercent 10

        Prereqs: Az.Accounts, Az.OperationalInsights; Microsoft Sentinel Reader on the workspace.
    EXPECTED RESULTS
        A table of AlertName -> alert count, a table of rule -> closed incidents with benign% vs the
        tolerance, and a top-entities list. A CSV is written next to the script. A rule at or under the
        tolerance is a candidate for promotion (Gate 6). Verify classification practices in your SOC —
        benign% is only as good as analysts' incident dispositions.
.NOTES
    White-label. Read-only. Az / KQL (Invoke-AzOperationalInsightsQuery). No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [int] $Days = 7,
    [double] $TolerancePercent = 10,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsId = $ws.CustomerId
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

function Invoke-Kql([string]$Query){ (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $Query -ErrorAction Stop).Results }

# --- Alert volume per rule --------------------------------------------------------------------------
Write-Section ("Alert volume per rule (last {0}d)" -f $Days)
$alerts = @()
try {
    $q = @"
SecurityAlert
| where TimeGenerated > ago(${Days}d)
| summarize Alerts = count() by AlertName
| sort by Alerts desc
"@
    $alerts = @(Invoke-Kql $q)
    if ($alerts.Count -eq 0) { Write-Host 'No alerts in the window (rules may not be firing yet).' -ForegroundColor Yellow }
    else { $alerts | Format-Table AlertName, Alerts -AutoSize }
}
catch { Write-Warning ("SecurityAlert query failed: {0}" -f $_.Exception.Message) }

# --- False-positive (benign) rate per rule ----------------------------------------------------------
Write-Section ("False-positive (benign) rate per rule vs {0}% tolerance" -f $TolerancePercent)
$fp = @()
try {
    $q = @"
SecurityIncident
| where TimeGenerated > ago(${Days}d)
| where Status == 'Closed'
| mv-expand Titles = AlertIds to typeof(string)
| summarize Total = count(),
            Benign = countif(Classification == 'BenignPositive' or Classification == 'FalsePositive')
          by Title
| extend BenignPct = round(100.0 * Benign / Total, 1)
| sort by BenignPct desc
"@
    $fp = @(Invoke-Kql $q)
    if ($fp.Count -eq 0) { Write-Host 'No closed incidents with classifications yet — let the pilot run / ensure analysts classify on close.' -ForegroundColor Yellow }
    else {
        foreach ($row in $fp) {
            $pct = [double]$row.BenignPct
            $flag = if ($pct -le $TolerancePercent) { 'WITHIN' } else { 'OVER' }
            $color = if ($pct -le $TolerancePercent) { 'Green' } else { 'Red' }
            Write-Host ("  {0,-45} benign {1,5}% [{2} tolerance]  (n={3})" -f $row.Title, $pct, $flag, $row.Total) -ForegroundColor $color
        }
        Write-Host ''
        Write-Host 'WITHIN tolerance = candidate for promotion (Gate 6). OVER = keep tuning (Phase 3).'
    }
}
catch { Write-Warning ("SecurityIncident query failed (schema/classification may differ by tenant): {0}" -f $_.Exception.Message) }

# --- Top entities driving alerts --------------------------------------------------------------------
Write-Section 'Top accounts/IPs driving alerts (tuning candidates for allow-list/suppression)'
try {
    $q = @"
SecurityAlert
| where TimeGenerated > ago(${Days}d)
| extend Ents = tostring(Entities)
| summarize Alerts = count() by AlertName
| top 10 by Alerts
"@
    (Invoke-Kql $q) | Format-Table -AutoSize
    Write-Host 'Inspect each noisy rule''s entities in the portal; allow-list known-good via WL-AuthorizedAdminIPs-Tenant.'
}
catch { Write-Warning ("Entity query failed: {0}" -f $_.Exception.Message) }

# --- Export ----------------------------------------------------------------------------------------
if ($fp.Count -gt 0) {
    $out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ("SENTRULE-fprate-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
    $fp | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    Write-Host ''
    Write-Host ("False-positive report exported to: {0}" -f $out) -ForegroundColor Green
}
