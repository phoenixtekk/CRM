<#
.SYNOPSIS
    SOCXDR-IncidentQueue.ps1 — incident-queue health across severity, owner, and tags.
.DESCRIPTION
    PURPOSE
        Gives SOC leadership a one-look health view of the unified queue: open incidents grouped by
        severity and by owner, the count that are UNOWNED or untriaged, whether the alignment tags
        (e.g. SOC-Triage / priority) are present, and the oldest open incident. Read-only.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SOCXDR-IncidentQueue.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - SOC - Workspace"
        Requires modules: Az.Accounts, Az.SecurityInsights.
    EXPECTED RESULTS
        Counts by severity and status, an owned-vs-unowned split, a tag-coverage figure (how many
        incidents carry the alignment tags), and the oldest open incident age.
.NOTES
    Sentinel Solutions. White-label. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$AlignmentTag = 'SOC-Triage'
)

Write-Host "=== SOCXDR Incident Queue — health ===" -ForegroundColor Cyan
try {
    $incidents = Get-AzSentinelIncident -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop
} catch {
    Write-Host ("Could not read incidents: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "(Confirm Microsoft Sentinel Responder/Reader on the workspace — Requirement 2.3.)"
    return
}
$open = $incidents | Where-Object { $_.Status -ne 'Closed' }
Write-Host ("Open incidents        : {0}  (of {1} total returned)" -f ($open|Measure-Object).Count, ($incidents|Measure-Object).Count)

Write-Host "`n--- By severity (open) ---" -ForegroundColor Cyan
$open | Group-Object Severity | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14}: {1}" -f $_.Name, $_.Count) }

Write-Host "`n--- By status (open) ---" -ForegroundColor Cyan
$open | Group-Object Status | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14}: {1}" -f $_.Name, $_.Count) }

Write-Host "`n--- Ownership ---" -ForegroundColor Cyan
$unowned = $open | Where-Object { -not $_.OwnerAssignedTo -and -not $_.OwnerUserPrincipalName }
Write-Host ("  Owned   : {0}" -f (($open|Measure-Object).Count - ($unowned|Measure-Object).Count)) -ForegroundColor Green
Write-Host ("  UNOWNED : {0}" -f ($unowned|Measure-Object).Count) -ForegroundColor ($(if(($unowned|Measure-Object).Count -gt 0){'Yellow'}else{'Green'}))

Write-Host "`n--- Alignment tag coverage ('$AlignmentTag') ---" -ForegroundColor Cyan
$tagged = $open | Where-Object { $_.LabelName -contains $AlignmentTag -or ($_.Label | ForEach-Object { $_.LabelName }) -contains $AlignmentTag }
Write-Host ("  Tagged  : {0} / {1}" -f ($tagged|Measure-Object).Count, ($open|Measure-Object).Count) -ForegroundColor ($(if(($tagged|Measure-Object).Count -eq ($open|Measure-Object).Count){'Green'}else{'Yellow'}))
Write-Host "  (Low coverage = the automation rule 'Incident Alignment - SOC - Pilot' may not match all incidents — Troubleshooting D.)"

if ($open) {
    $oldest = $open | Sort-Object CreatedTimeUtc | Select-Object -First 1
    $ageH = [math]::Round(((Get-Date).ToUniversalTime() - [datetime]$oldest.CreatedTimeUtc).TotalHours, 1)
    Write-Host ("`nOldest open incident  : {0}h — {1} [{2}]" -f $ageH, $oldest.Title, $oldest.Severity)
}
