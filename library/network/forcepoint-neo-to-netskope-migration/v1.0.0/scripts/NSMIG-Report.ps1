<#
.SYNOPSIS
    NSMIG-Report.ps1 — fleet migration coverage and conflict report (Microsoft Graph, read-only).
.DESCRIPTION
    PURPOSE
        Summarizes the migration across managed Windows devices using Intune detected-apps data:
        which devices still have the Forcepoint Neo agent, which have the Netskope client, and which
        have BOTH (a coexistence/conflict watch item). Gives you the legacy-estate count for the
        decommission gate and flags devices that are dual-equipped. Steering-ownership in the consoles
        is deferred to Netskope/Forcepoint docs; this reports installed-agent coverage from Intune.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSMIG-Report.ps1 -CsvPath C:\Temp\nsmig.csv
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Counts of Forcepoint-only, Netskope-only, both, and neither; a per-device CSV; and a flag if
        any device has both agents. Read-only against Graph.
.NOTES
    Network Solutions. Read-only against Graph. Netskope/Forcepoint console specifics deferred to vendor docs.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

# Pull Windows managed devices with their detected apps
$devs = @(); $uri = '/beta/deviceManagement/managedDevices?$select=id,deviceName,operatingSystem&$filter=operatingSystem eq ''Windows'''
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$report = foreach ($d in $devs) {
    $apps = @()
    try { $apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices/$($d.id)/detectedApps?`$select=displayName").value } catch {}
    $names = ($apps | ForEach-Object { $_.displayName }) -join '|'
    $fp = [bool]($names -match 'Forcepoint|Neo')
    $ns = [bool]($names -match 'Netskope')
    $state = if ($fp -and $ns) { 'BOTH (watch)' } elseif ($ns) { 'Netskope only' } elseif ($fp) { 'Forcepoint only' } else { 'Neither' }
    [pscustomobject]@{ Device = $d.deviceName; Forcepoint = $fp; Netskope = $ns; State = $state }
}

Write-Host "=== Migration coverage (installed agents) ===" -ForegroundColor Cyan
$report | Group-Object State | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
$legacy = ($report | Where-Object { $_.Forcepoint }).Count
$both   = ($report | Where-Object { $_.State -eq 'BOTH (watch)' }).Count
Write-Host ("Legacy estate (Forcepoint present): {0} device(s)" -f $legacy) -ForegroundColor ($(if($legacy){'Yellow'}else{'Green'}))
if ($both) { Write-Host ("CONFLICT WATCH: {0} device(s) have BOTH agents — confirm only one is enforcing." -f $both) -ForegroundColor Yellow }
if ($legacy -eq 0) { Write-Host "Decommission gate: no device reports the Forcepoint Neo agent." -ForegroundColor Green }

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
