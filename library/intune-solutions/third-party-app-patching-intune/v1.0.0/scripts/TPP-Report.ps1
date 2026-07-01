<#
.SYNOPSIS
    TPP-Report.ps1 — fleet-wide out-of-date exposure for managed third-party apps (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Pulls Intune's discovered-apps inventory across managed Windows devices and, for each app you
        manage, compares the detected version against a target you supply — producing a per-app /
        per-device list of devices that are below target (out-of-date exposure) and a current count.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TPP-Report.ps1 -CsvPath C:\Temp\tpp-exposure.csv
        Requires the Microsoft Graph PowerShell SDK and the scopes:
            DeviceManagementManagedDevices.Read.All
        Edit the $Targets table below (or pass -TargetsCsv with columns NameLike,MinVersion).
    EXPECTED RESULTS
        A summary of devices below target per managed app, plus an optional per-device CSV. Read-only.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$CsvPath, [string]$TargetsCsv)

# Managed apps and target versions — substitute your real values (placeholders shown).
$Targets = @(
    [pscustomobject]@{ NameLike = '*Reader*';  MinVersion = '0.0.0' },
    [pscustomobject]@{ NameLike = '*Browser*'; MinVersion = '0.0.0' }
)
if ($TargetsCsv) { $Targets = Import-Csv -Path $TargetsCsv }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

# Enumerate managed Windows devices, then their detected apps.
$devices = @()
$uri = "/v1.0/deviceManagement/managedDevices?`$select=id,deviceName,operatingSystem&`$filter=operatingSystem eq 'Windows'"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$rows = New-Object System.Collections.Generic.List[object]
foreach ($d in $devices) {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices/$($d.id)/detectedApps").value
    foreach ($t in $Targets) {
        $hit = $apps | Where-Object { $_.displayName -like $t.NameLike } |
            Sort-Object { try { [version]$_.version } catch { [version]'0.0' } } -Descending |
            Select-Object -First 1
        if (-not $hit) { continue }
        $current = $false
        try { $current = [version]$hit.version -ge [version]$t.MinVersion } catch { $current = $false }
        $rows.Add([pscustomobject]@{
            Device       = $d.deviceName
            App          = $hit.displayName
            Installed    = $hit.version
            Target       = $t.MinVersion
            Status       = $(if ($current) { 'Current' } else { 'OutOfDate' })
        })
    }
}

Write-Host "`n=== Third-party exposure by app ===" -ForegroundColor Cyan
$rows | Group-Object App | ForEach-Object {
    $behind = @($_.Group | Where-Object Status -eq 'OutOfDate').Count
    $total  = $_.Count
    Write-Host ("  {0}: {1} of {2} out of date" -f $_.Name, $behind, $total) -ForegroundColor ($(if ($behind) { 'Yellow' } else { 'Green' }))
}
Write-Host ("Devices evaluated: {0}" -f $devices.Count) -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
