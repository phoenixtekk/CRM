<#
.SYNOPSIS
    WS1MAC-Report.ps1 — fleet/ring migration status + parity rollup for migrated Macs (Intune, Graph).
.DESCRIPTION
    PURPOSE
        Reports, across the Mac fleet or a migration ring, how each device evaluates against the named
        WS1MAC parity objects in Intune — by reading device statuses for the settings-catalog parity
        policies and custom configuration profiles, plus the run states of the parity shell scripts.
        Summarizes succeeded vs drifted (error/conflict/failed/notApplicable) per object, so you can
        confirm a ring reached parity before expanding. Read-only against Microsoft Graph (Intune).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1MAC-Report.ps1 -ParityNameLike "WS1MAC Parity" -CsvPath C:\Temp\ws1mac-parity.csv
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-object breakdown of device states (succeeded/error/conflict/failed/etc.) and an optional
        per-device CSV showing which Macs have drifted from parity. Nothing is changed.
.NOTES
    Migrations — Workspace ONE to Intune macOS. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$ParityNameLike = 'WS1MAC Parity',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

$rows = @()

# Settings catalog (configurationPolicies) — macOS parity
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$ParityNameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.name; Type='SettingsCatalog'; Device=$d.deviceDisplayName; State=$d.status } }
}

# Custom .mobileconfig profiles (deviceConfigurations)
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$ParityNameLike')").value
foreach ($p in $dcs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.displayName; Type='CustomProfile'; Device=$d.deviceDisplayName; State=$d.status } }
}

# macOS shell scripts (deviceShellScripts) — run states
$scripts = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts").value | Where-Object { $_.displayName -like "$ParityNameLike*" }
foreach ($s in $scripts) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts/$($s.id)/deviceRunStates?`$expand=managedDevice").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$s.displayName; Type='ShellScript'; Device=$d.managedDevice.deviceName; State=$d.runState } }
}

Write-Host "=== WS1->Intune macOS — migration parity by object ===" -ForegroundColor Cyan
if (-not $rows) { Write-Host "No WS1MAC parity objects/states found (check -ParityNameLike)." -ForegroundColor Yellow }
$rows | Group-Object Object | ForEach-Object {
    Write-Host ("`nObject: {0}" -f $_.Name) -ForegroundColor Cyan
    $_.Group | Group-Object State | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
}

$drift = $rows | Where-Object { $_.State -notin @('compliant','succeeded','success') }
Write-Host ("`nDrifted/errored device-object states: {0} of {1}" -f ($drift | Measure-Object).Count, ($rows | Measure-Object).Count) -ForegroundColor ($(if($drift){'Yellow'}else{'Green'}))
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Write-Host "`nFor stuck devices, run WS1MAC-Remediation.ps1 (preview first)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
