<#
.SYNOPSIS
    WS1APP-Discovery.ps1 — enumerate Intune apps and build a source-vs-target rebuild gap list.
.DESCRIPTION
    PURPOSE
        Read-only. Lists the apps already present in Microsoft Intune (mobileApps) grouped by type,
        and — when given the Workspace ONE source-app export — reports which source apps are NOT yet
        rebuilt in Intune (the gap to close). Source-side export from Workspace ONE is deferred to
        VMware documentation; supply that export as a CSV with a 'Name' column via -SourceCsv.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1APP-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\WS1APP-Discovery.ps1 -SourceCsv C:\Temp\ws1-apps.csv -CsvPath C:\Temp\gap.csv
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A count of Intune apps by type and, if -SourceCsv is supplied, a list of source apps still to
        rebuild (optionally exported to -CsvPath).
.NOTES
    Workplace Marketplace — Migrations. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$SourceCsv, [string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

$apps = @()
$uri  = '/v1.0/deviceAppManagement/mobileApps?$select=id,displayName'
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    $apps += $r.value
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host "`n=== Intune apps by type ===" -ForegroundColor Cyan
$apps |
    Group-Object { ($_.'@odata.type' -replace '#microsoft.graph.', '') } |
    Sort-Object Count -Descending |
    Select-Object Count, @{ n = 'AppType'; e = { $_.Name } } |
    Format-Table -AutoSize
Write-Host ("Total Intune apps: {0}" -f $apps.Count) -ForegroundColor Cyan

if ($SourceCsv) {
    if (-not (Test-Path $SourceCsv)) { Write-Host "Source CSV not found: $SourceCsv" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
    $source  = Import-Csv $SourceCsv
    $present = $apps.displayName
    $gap = $source | Where-Object { $present -notcontains $_.Name } |
        ForEach-Object { [pscustomobject]@{ SourceApp = $_.Name; Status = 'NOT yet rebuilt in Intune' } }
    Write-Host "`n=== Source apps still to rebuild ===" -ForegroundColor Cyan
    if ($gap) { $gap | Format-Table -AutoSize } else { Write-Host "All source apps have a matching Intune app name." -ForegroundColor Green }
    if ($CsvPath -and $gap) { $gap | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
}

Disconnect-MgGraph | Out-Null
