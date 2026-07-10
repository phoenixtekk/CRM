<#
.SYNOPSIS
    THREATHUNTG-Report.ps1 — hunt-program metrics: hunts, findings, hand-offs, promotions, and coverage
    (read-only).
.DESCRIPTION
    PURPOSE
        Reports the health and trend of the hunt program so you can see it maturing: bookmarks
        (preserved findings) over the window, incidents that carry a hunt bookmark (hand-offs to the
        reactive process), promoted -Prod detections (hunts turned into standing coverage), and a
        coverage view of which ATT&CK tactics the saved hunt library actively covers. Read-only — it
        reads and reports; it changes nothing and takes no response action.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment      # Azure Government

        pwsh -File .\THREATHUNTG-Report.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -Days 30

        Prereqs: Az.Accounts, Az.OperationalInsights, Az.SecurityInsights; Microsoft Sentinel Reader.
    EXPECTED RESULTS
        Counts and tables for findings/bookmarks, hand-off incidents, promoted detections, and ATT&CK
        tactic coverage from the saved hunt library, plus a CSV written next to the script. A growing
        tagged-hunt count and promotions are the signs the program is working. GOVERNMENT (GCC High) is
        the DEFAULT: -Environment AzureUSGovernment (portal.azure.us) — verify endpoints for your cloud
        against current Microsoft Government documentation.
.NOTES
    White-label. Read-only. Az / KQL (Invoke-AzOperationalInsightsQuery). No credentials in code.
    No response actions.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [int] $Days = 30,
    # Government (GCC High / Azure Government) is the default for this edition.
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureUSGovernment'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsId = $ws.CustomerId
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

$summary = New-Object System.Collections.Generic.List[object]
function Add-Metric([string]$Metric, $Value) { $summary.Add([pscustomobject]@{ Metric = $Metric; Value = $Value }) }

# --- Findings preserved as bookmarks ----------------------------------------------------------------
Write-Section ("Findings preserved as bookmarks (last {0}d)" -f $Days)
try {
    $bm = @(Get-AzSentinelBookmark -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    $recent = @($bm | Where-Object { $_.Created -and ([datetime]$_.Created -gt (Get-Date).AddDays(-$Days)) })
    $huntBm = @($recent | Where-Object { $_.DisplayName -match 'Hunt|Finding|Bookmark-' })
    Write-Host ("  Bookmarks in window: {0}  (hunt findings: {1})" -f $recent.Count, $huntBm.Count)
    if ($huntBm.Count -gt 0) { $huntBm | Select-Object DisplayName, Created | Sort-Object Created -Descending | Format-Table -AutoSize }
    Add-Metric 'Bookmarks (window)' $recent.Count
    Add-Metric 'Hunt-finding bookmarks (window)' $huntBm.Count
}
catch { Write-Warning ("Bookmark query failed: {0}" -f $_.Exception.Message) }

# --- Hand-offs: incidents that carry a hunt bookmark ------------------------------------------------
Write-Section ("Hand-offs to incident response (incidents with a hunt bookmark, last {0}d)" -f $Days)
try {
    $q = @"
SecurityIncident
| where TimeGenerated > ago(${Days}d)
| summarize arg_max(TimeGenerated, *) by IncidentNumber
| extend Labels = tostring(Labels)
| where array_length(todynamic(BookmarksCount)) > 0 or Labels has 'Hunt' or Title has 'Hunt'
| project TimeGenerated, IncidentNumber, Title, Severity, Status
| sort by TimeGenerated desc
"@
    $inc = @((Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $q -ErrorAction Stop).Results)
    if ($inc.Count -eq 0) { Write-Host '  No hunt-linked incidents in the window (or bookmarks not linked to incidents yet).' -ForegroundColor Yellow }
    else { $inc | Format-Table IncidentNumber, Title, Severity, Status -AutoSize }
    Add-Metric 'Hunt-linked incidents (window)' $inc.Count
}
catch { Write-Warning ("Incident query failed (schema may differ by tenant): {0}" -f $_.Exception.Message) }

# --- Promotions: hunts turned into standing detections ----------------------------------------------
Write-Section 'Promotions — hunts turned into standing detections (Rule-<Hunt>-Prod)'
try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    $prod = @($rules | Where-Object { $_.DisplayName -match '-Prod$' -or $_.DisplayName -like 'Rule-*-Prod' })
    Write-Host ("  Promoted Sentinel detections: {0}" -f $prod.Count)
    if ($prod.Count -gt 0) { $prod | Select-Object DisplayName, Enabled | Format-Table -AutoSize }
    Write-Host '  (Defender custom detections CD-<Hunt>-Prod live in the Defender portal and are counted there.)'
    Add-Metric 'Promoted Sentinel detections' $prod.Count
}
catch { Write-Warning ("Rule query failed: {0}" -f $_.Exception.Message) }

# --- Coverage: which ATT&CK tactics the saved hunt library covers -----------------------------------
Write-Section 'ATT&CK coverage of the saved hunt library (tactics actively hunted)'
try {
    $hunts = @(Get-AzSentinelHuntingRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    $tactics = @($hunts | ForEach-Object { $_.Tactic } | Where-Object { $_ } | Sort-Object -Unique)
    Write-Host ("  Saved hunts: {0}   Distinct tactics covered: {1}" -f $hunts.Count, $tactics.Count)
    if ($tactics.Count -gt 0) { Write-Host ("  Tactics: {0}" -f ($tactics -join ', ')) }
    else { Write-Host '  No tagged tactics yet — tag hunts so coverage is measurable (Phase 1, Step 2).' -ForegroundColor Yellow }
    Add-Metric 'Saved hunts' $hunts.Count
    Add-Metric 'Distinct ATT&CK tactics hunted' $tactics.Count
}
catch { Write-Warning ("Hunt-coverage query failed: {0}" -f $_.Exception.Message) }

# --- Export -----------------------------------------------------------------------------------------
$out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ("THREATHUNTG-report-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
$summary | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host ("Program report exported to: {0}" -f $out) -ForegroundColor Green
Write-Host 'Trend to watch: growing tagged-hunt coverage + promotions + shrinking time-to-find = a maturing program.'
