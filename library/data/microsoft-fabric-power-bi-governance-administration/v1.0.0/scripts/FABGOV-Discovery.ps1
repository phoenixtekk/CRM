<#
.SYNOPSIS
    FABGOV-Discovery.ps1 — read-only inventory of the Fabric/Power BI platform for governance assessment.
.DESCRIPTION
    PURPOSE
        Captures the "before" picture for the Assess step: the capacities in the tenant, a workspace
        inventory (flagging personal/orphaned workspaces), and a sharing/export summary from the
        activity log. Also confirms the admin/scanner APIs are reachable. Everything is read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FABGOV-Discovery.ps1
        Optional: -Days 7   (activity-log look-back window; default 7, max 30 per admin API)
        Requires the MicrosoftPowerBIMgmt module and the Fabric/Power BI Administrator role
        (interactive/delegated sign-in). Unattended runs use a service-principal per requirement 2.6.
    EXPECTED RESULTS
        Tables of capacities and workspaces, a count of orphaned/personal workspaces, and a top-N
        summary of share / export / publish-to-web activity — saved to a timestamped CSV set.
.NOTES
    Data — Fabric/Power BI Governance. Read-only against the Power BI admin REST APIs.
    White-label. No tenant-specific values are hard-coded.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 30)]
    [int]$Days = 7,
    [string]$OutputFolder = ".\FABGOV-Discovery-Output"
)

if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing MicrosoftPowerBIMgmt (CurrentUser)..." -ForegroundColor Yellow
    Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop

try { Connect-PowerBIServiceAccount -ErrorAction Stop | Out-Null }
catch { Write-Host "Sign-in failed: $($_.Exception.Message)" -ForegroundColor Red; return }

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Get-PbiValue {
    param([string]$Uri)
    try { (Invoke-PowerBIRestMethod -Url $Uri -Method Get | ConvertFrom-Json).value }
    catch { Write-Host "  API call failed ($Uri): $($_.Exception.Message)" -ForegroundColor Yellow; @() }
}

Write-Host "`n=== Capacities ===" -ForegroundColor Cyan
$caps = Get-PbiValue "admin/capacities"
if ($caps) {
    $caps | Select-Object id, displayName, sku, state, region | Format-Table -AutoSize
    $caps | Export-Csv "$OutputFolder\capacities-$stamp.csv" -NoTypeInformation
    Write-Host ("Capacities found: {0}" -f $caps.Count) -ForegroundColor Green
    Write-Host "Confirm 'Fabric Capacity - Analytics - Prod' is present and Active." -ForegroundColor Gray
} else { Write-Host "No capacities returned (or insufficient rights)." -ForegroundColor Yellow }

Write-Host "`n=== Workspace inventory ===" -ForegroundColor Cyan
$ws = Get-PbiValue "admin/groups?`$top=5000&`$expand=users"
if ($ws) {
    $orphaned = $ws | Where-Object { $_.type -eq 'PersonalGroup' -or -not ($_.users | Where-Object { $_.groupUserAccessRight -eq 'Admin' }) }
    $ws | Select-Object id, name, type, state, isOnDedicatedCapacity, capacityId |
        Export-Csv "$OutputFolder\workspaces-$stamp.csv" -NoTypeInformation
    Write-Host ("Total workspaces: {0}" -f $ws.Count) -ForegroundColor Green
    Write-Host ("Personal / no-admin (review) workspaces: {0}" -f ($orphaned | Measure-Object).Count) -ForegroundColor Yellow
    $orphaned | Select-Object id, name, type, state |
        Export-Csv "$OutputFolder\workspaces-review-$stamp.csv" -NoTypeInformation
} else { Write-Host "No workspaces returned (or insufficient rights)." -ForegroundColor Yellow }

Write-Host "`n=== Sharing / export activity (last $Days day[s]) ===" -ForegroundColor Cyan
$interesting = 'ShareReport','ExportReport','ExportTile','ExportArtifact','PublishToWebReport','UpdateFolderAccess','AddExternalResource'
$events = @()
for ($d = 0; $d -lt $Days; $d++) {
    $day = (Get-Date).AddDays(-$d).ToString('yyyy-MM-dd')
    $start = "$($day)T00:00:00.000Z"; $end = "$($day)T23:59:59.999Z"
    $uri = "admin/activityevents?startDateTime='$start'&endDateTime='$end'"
    try {
        $resp = Invoke-PowerBIRestMethod -Url $uri -Method Get | ConvertFrom-Json
        $events += $resp.activityEventEntities
        while ($resp.continuationUri) {
            $resp = Invoke-PowerBIRestMethod -Url $resp.continuationUri -Method Get | ConvertFrom-Json
            $events += $resp.activityEventEntities
        }
    } catch { Write-Host "  Activity log for $day not available: $($_.Exception.Message)" -ForegroundColor Yellow }
}
$risky = $events | Where-Object { $interesting -contains $_.Operation }
if ($risky) {
    $risky | Group-Object Operation | Sort-Object Count -Descending |
        Select-Object Name, Count | Format-Table -AutoSize
    Write-Host "`nTop 10 users by risky share/export actions:" -ForegroundColor Gray
    $risky | Group-Object UserId | Sort-Object Count -Descending | Select-Object -First 10 Name, Count | Format-Table -AutoSize
    $risky | Select-Object CreationTime, Operation, UserId, WorkspaceName, ArtifactName |
        Export-Csv "$OutputFolder\activity-risky-$stamp.csv" -NoTypeInformation
} else { Write-Host "No share/export/publish-to-web events in the window (or log not enabled)." -ForegroundColor Yellow }

Write-Host "`nDiscovery complete. CSVs written to $OutputFolder" -ForegroundColor Cyan
Disconnect-PowerBIServiceAccount | Out-Null
