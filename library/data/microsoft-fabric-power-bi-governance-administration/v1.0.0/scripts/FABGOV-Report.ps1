<#
.SYNOPSIS
    FABGOV-Report.ps1 — weekly capacity-utilization and activity-log governance summary.
.DESCRIPTION
    PURPOSE
        Produces the standing governance report: per-capacity metadata (SKU/state/region) and a rolled-up
        activity summary from the admin activity log — top share/export/publish-to-web actions, top actors,
        and workspace creation/deletion — so the governance review can spot sprawl and risky trends. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FABGOV-Report.ps1 -Days 7
        Unattended (scheduled) runs use a service principal per requirement 2.6:
          .\FABGOV-Report.ps1 -ServicePrincipal -TenantId <guid> -AppId <guid> -AppSecret <secret>
        Requires MicrosoftPowerBIMgmt and read-only admin API access.
    EXPECTED RESULTS
        A console summary plus an HTML + CSV report written to the output folder, ready to attach to the
        weekly governance review.
.NOTES
    Data — Fabric/Power BI Governance. Read-only against the Power BI admin REST APIs.
    White-label. Secrets are parameters, never hard-coded; prefer a managed secret store when scheduling.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 30)][int]$Days = 7,
    [switch]$ServicePrincipal,
    [string]$TenantId,
    [string]$AppId,
    [string]$AppSecret,
    [string]$OutputFolder = ".\FABGOV-Report-Output"
)

if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Install-Module MicrosoftPowerBIMgmt -Scope CurrentUser -Force -AllowClobber
}
Import-Module MicrosoftPowerBIMgmt -ErrorAction Stop

try {
    if ($ServicePrincipal) {
        if (-not ($TenantId -and $AppId -and $AppSecret)) { throw "ServicePrincipal run needs -TenantId, -AppId and -AppSecret." }
        $sec = ConvertTo-SecureString $AppSecret -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($AppId, $sec)
        Connect-PowerBIServiceAccount -ServicePrincipal -Credential $cred -Tenant $TenantId -ErrorAction Stop | Out-Null
    } else {
        Connect-PowerBIServiceAccount -ErrorAction Stop | Out-Null
    }
} catch { Write-Host "Sign-in failed: $($_.Exception.Message)" -ForegroundColor Red; return }

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
function Get-PbiValue { param([string]$Uri)
    try { (Invoke-PowerBIRestMethod -Url $Uri -Method Get | ConvertFrom-Json).value } catch { @() }
}

Write-Host "`n=== Capacity summary ===" -ForegroundColor Cyan
$caps = Get-PbiValue "admin/capacities"
$caps | Select-Object displayName, sku, state, region | Format-Table -AutoSize
$caps | Export-Csv "$OutputFolder\report-capacities-$stamp.csv" -NoTypeInformation
Write-Host "For live utilization/throttling, cross-check the 'Microsoft Fabric Capacity Metrics' app." -ForegroundColor Gray

Write-Host "`n=== Activity summary (last $Days day[s]) ===" -ForegroundColor Cyan
$events = @()
for ($d = 0; $d -lt $Days; $d++) {
    $day = (Get-Date).AddDays(-$d).ToString('yyyy-MM-dd')
    $uri = "admin/activityevents?startDateTime='$($day)T00:00:00.000Z'&endDateTime='$($day)T23:59:59.999Z'"
    try {
        $resp = Invoke-PowerBIRestMethod -Url $uri -Method Get | ConvertFrom-Json
        $events += $resp.activityEventEntities
        while ($resp.continuationUri) {
            $resp = Invoke-PowerBIRestMethod -Url $resp.continuationUri -Method Get | ConvertFrom-Json
            $events += $resp.activityEventEntities
        }
    } catch { }
}

$byOp = $events | Group-Object Operation | Sort-Object Count -Descending | Select-Object Name, Count
$risky = 'ShareReport','ExportReport','ExportTile','ExportArtifact','PublishToWebReport'
$riskyEvents = $events | Where-Object { $risky -contains $_.Operation }
$topActors = $riskyEvents | Group-Object UserId | Sort-Object Count -Descending | Select-Object -First 10 Name, Count
$wsChanges = $events | Where-Object { $_.Operation -in 'CreateGroup','DeleteGroup' } |
    Select-Object CreationTime, Operation, UserId, WorkspaceName

Write-Host "Total events: $($events.Count) | Risky share/export/publish-to-web: $($riskyEvents.Count)" -ForegroundColor Green
$byOp | Select-Object -First 15 | Format-Table -AutoSize

$byOp | Export-Csv "$OutputFolder\report-ops-$stamp.csv" -NoTypeInformation
$topActors | Export-Csv "$OutputFolder\report-top-actors-$stamp.csv" -NoTypeInformation
$wsChanges | Export-Csv "$OutputFolder\report-workspace-changes-$stamp.csv" -NoTypeInformation

$html = @"
<html><head><meta charset='utf-8'><title>Fabric/Power BI Governance Report</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px} h2{color:#217346} table{border-collapse:collapse;margin:8px 0} td,th{border:1px solid #ccc;padding:4px 10px;text-align:left}</style></head><body>
<h1>Fabric &amp; Power BI Governance Report</h1>
<p>Window: last $Days day(s). Generated $(Get-Date -Format 'u'). Total events: $($events.Count); risky actions: $($riskyEvents.Count).</p>
<h2>Capacities</h2><table><tr><th>Name</th><th>SKU</th><th>State</th><th>Region</th></tr>
$([string]::Join('', ($caps | ForEach-Object { "<tr><td>$($_.displayName)</td><td>$($_.sku)</td><td>$($_.state)</td><td>$($_.region)</td></tr>" })))
</table>
<h2>Top operations</h2><table><tr><th>Operation</th><th>Count</th></tr>
$([string]::Join('', ($byOp | Select-Object -First 15 | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" })))
</table>
<h2>Top actors (risky share/export)</h2><table><tr><th>User</th><th>Count</th></tr>
$([string]::Join('', ($topActors | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" })))
</table></body></html>
"@
$html | Out-File "$OutputFolder\FABGOV-Report-$stamp.html" -Encoding utf8

Write-Host "`nReport written to $OutputFolder (HTML + CSVs)." -ForegroundColor Cyan
Disconnect-PowerBIServiceAccount | Out-Null
