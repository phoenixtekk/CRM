<#
.SYNOPSIS
    CIS11-Report.ps1 — fleet CIS posture + drift via Microsoft Graph (Intune device config states).
.DESCRIPTION
    PURPOSE
        Reports, across the fleet, how each device evaluates against the CIS Win11 configuration
        policies in Intune — by reading the deviceConfigurationDeviceStatuses for the named policies
        (settings catalog / ADMX). Summarizes compliant vs drifted (error/conflict/notApplicable)
        per policy. Read-only against Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CIS11-Report.ps1 -PolicyNameLike "CIS Win11" -CsvPath C:\Temp\cis-posture.csv
        Requires Microsoft Graph SDK and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-policy breakdown of device states (succeeded/error/conflict/etc.) and an optional
        per-device CSV showing which devices have drifted.
.NOTES
    Intune Solutions — CIS Win11. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$PolicyNameLike = 'CIS Win11',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome

# Find the CIS Win11 configuration policies (settings catalog = configurationPolicies; legacy/ADMX = deviceConfigurations)
$rows = @()

# Settings catalog (configurationPolicies)
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$PolicyNameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Policy=$p.name; Device=$d.deviceDisplayName; State=$d.status } }
}

# Imported ADMX / legacy templates (deviceConfigurations)
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$PolicyNameLike')").value
foreach ($p in $dcs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value
    foreach ($d in $st) { $rows += [pscustomobject]@{ Policy=$p.displayName; Device=$d.deviceDisplayName; State=$d.status } }
}

Write-Host "=== CIS Win11 posture by policy ===" -ForegroundColor Cyan
if (-not $rows) { Write-Host "No CIS Win11 policies/states found (check -PolicyNameLike)." -ForegroundColor Yellow }
$rows | Group-Object Policy | ForEach-Object {
    Write-Host ("`nPolicy: {0}" -f $_.Name) -ForegroundColor Cyan
    $_.Group | Group-Object State | Sort-Object Name | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
}

$drift = $rows | Where-Object { $_.State -notin @('compliant','succeeded') }
Write-Host ("`nDrifted/errored device-policy states: {0} of {1}" -f $drift.Count, $rows.Count) -ForegroundColor ($(if($drift){'Yellow'}else{'Green'}))
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null
