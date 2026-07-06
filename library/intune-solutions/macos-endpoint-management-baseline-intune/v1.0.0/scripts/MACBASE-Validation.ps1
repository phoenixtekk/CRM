<#
.SYNOPSIS
    MACBASE-Validation.ps1 — per-device applied-state check for the macOS baseline (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Checks, for one named Mac, whether the macOS baseline objects have applied: it reads the
        device's configuration-policy states for the named baseline policies (config, restrictions,
        software update, and any custom profile) and the device's evaluation of the baseline
        compliance policy, then reports applied/succeeded vs error/conflict/failed. Use it on a pilot
        Mac after assignment and any time you suspect drift. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACBASE-Validation.ps1 -DeviceName your-mac-name
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All +
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A per-object line for the named Mac (SettingsCatalog / CustomProfile / Compliance) with its
        state. Pass = every baseline object shows succeeded/compliant; fail = any error/conflict/failed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$DeviceName,
    [string]$PolicyNameLike = 'macOS Baseline'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host ("`n=== macOS Baseline — applied-state for '{0}' ===" -f $DeviceName) -ForegroundColor Cyan

$dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $DeviceName)).value | Select-Object -First 1
if (-not $dev) { Write-Host "Mac '$DeviceName' not found as a managed macOS device. Check the name and enrollment." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

$rows = @()

# Settings-catalog baseline policies — per-device status
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$PolicyNameLike')").value
foreach ($p in $cps) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value |
          Where-Object { $_.deviceDisplayName -eq $DeviceName }
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.name; Type='SettingsCatalog'; State=$d.status } }
}

# Custom .mobileconfig profiles (deviceConfigurations) — per-device status
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$PolicyNameLike')").value
foreach ($p in $dcs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value |
          Where-Object { $_.deviceDisplayName -eq $DeviceName }
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$p.displayName; Type='CustomProfile'; State=$d.status } }
}

# Baseline compliance policy — device evaluation
$comp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceCompliancePolicies").value |
        Where-Object { $_.displayName -like "$PolicyNameLike*" }
foreach ($c in $comp) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceCompliancePolicies/$($c.id)/deviceStatuses").value |
          Where-Object { $_.deviceDisplayName -eq $DeviceName }
    foreach ($d in $st) { $rows += [pscustomobject]@{ Object=$c.displayName; Type='Compliance'; State=$d.status } }
}

if (-not $rows) {
    Write-Host "No baseline objects report a state for this Mac yet. Confirm it is in the assigned group and force a sync, then re-run." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; exit 0
}

$rows | Format-Table -AutoSize
$bad = $rows | Where-Object { $_.State -notin @('compliant','succeeded','success') }
if ($bad) {
    Write-Host ("`nDRIFT: {0} baseline object(s) not in a good state on this Mac." -f ($bad | Measure-Object).Count) -ForegroundColor Yellow
    Write-Host "Investigate conflicts (Troubleshooting) or run MACBASE-Remediation.ps1 to re-sync." -ForegroundColor Yellow
} else {
    Write-Host "`nPASS: all baseline objects applied/compliant on this Mac." -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
