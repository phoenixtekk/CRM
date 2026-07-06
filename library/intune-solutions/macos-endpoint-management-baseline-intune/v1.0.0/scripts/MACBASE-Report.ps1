<#
.SYNOPSIS
    MACBASE-Report.ps1 — fleet macOS baseline posture + drift via Microsoft Graph (Intune macOS objects).
.DESCRIPTION
    PURPOSE
        Reports, across the Mac fleet, how each device evaluates against the macOS baseline objects in
        Intune — by reading the device statuses for the named settings-catalog policies (config,
        restrictions, software update), any custom configuration profiles, and the baseline compliance
        policy. Summarizes succeeded/compliant vs drifted (error/conflict/failed/etc.) per object, with
        an optional per-device CSV. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACBASE-Report.ps1 -PolicyNameLike "macOS Baseline" -CsvPath C:\Temp\macbase-posture.csv
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-object breakdown of device states and a total drift count; optional per-device CSV.
        Pass = drift count is zero (every Mac succeeded/compliant on every baseline object).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$PolicyNameLike = 'macOS Baseline',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

$rows = @()

# Settings-catalog (configurationPolicies) — macOS baseline
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

# Baseline compliance policy
$comp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceCompliancePolicies").value | Where-Object { $_.displayName -like "$PolicyNameLike*" }
foreach ($c in $comp) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceCompliancePolicies/$($c.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$c.displayName; Type='Compliance'; Device=$d.deviceDisplayName; State=$d.status } }
}

Write-Host "=== macOS Baseline posture by object ===" -ForegroundColor Cyan
if (-not $rows) { Write-Host "No macOS baseline objects/states found (check -PolicyNameLike)." -ForegroundColor Yellow }
$rows | Group-Object Object | ForEach-Object {
    Write-Host ("`nObject: {0}" -f $_.Name) -ForegroundColor Cyan
    $_.Group | Group-Object State | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
}

$drift = $rows | Where-Object { $_.State -notin @('compliant','succeeded','success') }
Write-Host ("`nDrifted/errored device-object states: {0} of {1}" -f ($drift | Measure-Object).Count, ($rows | Measure-Object).Count) -ForegroundColor ($(if($drift){'Yellow'}else{'Green'}))
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null
