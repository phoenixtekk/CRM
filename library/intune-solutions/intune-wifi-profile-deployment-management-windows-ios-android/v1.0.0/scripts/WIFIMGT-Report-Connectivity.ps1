<#
.SYNOPSIS
    WIFIMGT-Report-Connectivity.ps1 — Wi-Fi profile deployment-state report across the fleet (read-only, cloud-aware).
.DESCRIPTION
    PURPOSE
        For the named Wi-Fi profiles, reports the per-device deployment state (Succeeded / Error /
        Conflict / Pending / Not applicable) using Intune's deviceConfiguration deviceStatuses, so you
        can see whether devices actually received the profile. A rising Error/Conflict count is the
        signal to investigate before widening assignment. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Report-Connectivity.ps1
        Sovereign cloud:  .\WIFIMGT-Report-Connectivity.ps1 -Environment USGov      (or USGovDoD)
        Export to CSV:    .\WIFIMGT-Report-Connectivity.ps1 -OutputCsv .\wifi-state.csv
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A per-profile state summary (counts by status) and, with -OutputCsv, a per-device breakdown.
.NOTES
    White-label — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string[]] $ProfileNames = @(
        'WIFIMGT - Corp WiFi - Windows - Pilot',
        'WIFIMGT - Corp WiFi - iOS - Pilot',
        'WIFIMGT - Corp WiFi - Android - Pilot'
    ),
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome
Write-Host "Connected to Graph ($Environment) tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan

function Get-All($uri) {
    $out = @(); $next = $uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}

$allDc = Get-All "/beta/deviceManagement/deviceConfigurations?`$select=id,displayName"
$detail = New-Object System.Collections.Generic.List[object]

foreach ($name in $ProfileNames) {
    Write-Host "`n=== $name ===" -ForegroundColor Yellow
    $p = $allDc | Where-Object { $_.displayName -eq $name }
    if (-not $p) { Write-Host "  [MISSING] profile not found." -ForegroundColor Red; continue }
    $statuses = @()
    try { $statuses = Get-All "/beta/deviceManagement/deviceConfigurations/$($p[0].id)/deviceStatuses" }
    catch { Write-Warning "  Could not read deviceStatuses: $($_.Exception.Message)"; continue }

    if (-not $statuses) { Write-Host "  (no device status yet — devices may not have checked in)" -ForegroundColor DarkYellow; continue }

    $byState = $statuses | Group-Object status | Sort-Object Name
    foreach ($g in $byState) {
        $color = switch ($g.Name) { 'compliant' {'Green'} 'error' {'Red'} 'conflict' {'Red'} default {'Gray'} }
        Write-Host ("  {0,-14} : {1}" -f $g.Name, $g.Count) -ForegroundColor $color
    }
    foreach ($s in $statuses) {
        $detail.Add([pscustomobject]@{ Profile=$name; Device=$s.deviceDisplayName; User=$s.userName; Status=$s.status; LastReport=$s.lastReportedDateTime })
    }
}

Write-Host "`nSummary across requested profiles:" -ForegroundColor Cyan
$detail | Group-Object Status | Sort-Object Name | ForEach-Object { Write-Host ("  {0,-14} : {1}" -f $_.Name, $_.Count) }

if ($OutputCsv) { $detail | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8; Write-Host "`nPer-device detail written to $OutputCsv" -ForegroundColor Cyan }

Disconnect-MgGraph | Out-Null
