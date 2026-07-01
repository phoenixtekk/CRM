<#
.SYNOPSIS
    CISMAC-Report.ps1 — fleet CIS posture + drift via Microsoft Graph (Intune macOS config + scripts).
.DESCRIPTION
    PURPOSE
        Reports, across the Mac fleet, how each device evaluates against the CIS macOS objects in
        Intune — by reading the device statuses for the named settings-catalog policies and custom
        configuration profiles, plus the run states of the CIS macOS shell scripts. Summarizes
        compliant vs drifted (error/conflict/failed/notApplicable) per object. Read-only against Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISMAC-Report.ps1 -PolicyNameLike "CIS macOS" -CsvPath C:\Temp\cismac-posture.csv
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-object breakdown of device states (succeeded/error/conflict/failed/etc.) and an optional
        per-device CSV showing which Macs have drifted.
.NOTES
    Intune Solutions — CIS macOS. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$PolicyNameLike = 'CIS macOS',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

$rows = @()

# Settings catalog (configurationPolicies) — macOS
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$PolicyNameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.name; Type='SettingsCatalog'; Device=$d.deviceDisplayName; State=$d.status } }
}

# Custom .mobileconfig profiles (deviceConfigurations)
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$PolicyNameLike')").value
foreach ($p in $dcs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.displayName; Type='CustomProfile'; Device=$d.deviceDisplayName; State=$d.status } }
}

# macOS shell scripts (deviceShellScripts) — run states
$scripts = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts").value | Where-Object { $_.displayName -like "$PolicyNameLike*" }
foreach ($s in $scripts) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts/$($s.id)/deviceRunStates?`$expand=managedDevice").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$s.displayName; Type='ShellScript'; Device=$d.managedDevice.deviceName; State=$d.runState } }
}

Write-Host "=== CIS macOS posture by object ===" -ForegroundColor Cyan
if (-not $rows) { Write-Host "No CIS macOS objects/states found (check -PolicyNameLike)." -ForegroundColor Yellow }
$rows | Group-Object Object | ForEach-Object {
    Write-Host ("`nObject: {0}" -f $_.Name) -ForegroundColor Cyan
    $_.Group | Group-Object State | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
}

$drift = $rows | Where-Object { $_.State -notin @('compliant','succeeded','success') }
Write-Host ("`nDrifted/errored device-object states: {0} of {1}" -f ($drift | Measure-Object).Count, ($rows | Measure-Object).Count) -ForegroundColor ($(if($drift){'Yellow'}else{'Green'}))
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null
