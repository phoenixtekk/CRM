<#
.SYNOPSIS
    CREDGUARD-Report.ps1 — credential-protection coverage report for Windows devices.
.DESCRIPTION
    PURPOSE
        Produces a coverage report across managed Windows 10/11 devices: for each device, whether the
        named credential-theft-protection profile is applied, alongside a hardware-readiness signal
        (from managed-device inventory) useful for the VBS controls (Credential Guard / LSASS PPL). Use
        it to measure coverage before widening a rollout and to find devices still missing the
        credential-theft defense. Read-only. Reports the endpoint credential-protection controls only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Report.ps1
        Optional: -ProfileName "Credential Guard - Pilot"  -CsvPath .\CREDGUARD-coverage.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of Windows devices with an Applied column (Yes/No/Error) plus a
        coverage summary. Full coverage = every intended device shows Applied = Yes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'Credential Guard - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

# Locate the profile (Settings Catalog first, then template)
$profile = $null; $kind = 'none'
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; $kind = 'catalog'; break } }
    if (-not $profile) {
        $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
        foreach ($p in @($tpl.value)) { if ($p.displayName -eq $ProfileName) { $profile = $p; $kind = 'template'; break } }
    }
} catch {}

if (-not $profile) { Write-Host "No credential-protection profile found (looked for '$ProfileName'). Nothing to report." -ForegroundColor Yellow; return }
$pName = if ($kind -eq 'catalog') { $profile.name } else { $profile.displayName }
$base  = if ($kind -eq 'catalog') { "configurationPolicies/$($profile.id)" } else { "deviceConfigurations/$($profile.id)" }

# Devices that report a status for this profile
$applied = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/deviceStatuses"
    foreach ($s in @($stat.value)) {
        $applied["$($s.deviceDisplayName)"] = if ($s.status -match 'success|compliant') { 'Yes' } elseif ($s.status -match 'error|failed') { 'Error' } else { 'No' }
    }
} catch {}

# All managed Windows devices (with a readiness hint from inventory)
$rows = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'"
    foreach ($d in @($md.value)) {
        $rows += [pscustomobject]@{
            Device    = $d.deviceName
            User      = $d.userPrincipalName
            OSVersion = $d.osVersion
            Applied   = $(if ($applied.ContainsKey($d.deviceName)) { $applied[$d.deviceName] } else { 'No' })
        }
    }
} catch { Write-Warning "Could not enumerate Windows devices: $($_.Exception.Message)" }

$rows | Sort-Object Applied, Device | Format-Table -AutoSize
if ($CsvPath) { $rows | Sort-Object Applied, Device | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

$total = @($rows).Count
$yes   = @($rows | Where-Object Applied -eq 'Yes').Count
Write-Host ''
Write-Host ("Coverage: {0}/{1} Windows device(s) have '{2}' applied." -f $yes, $total, $pName) -ForegroundColor Cyan
Write-Host "Tip: for the VBS controls, confirm runtime state on each device with Win32_DeviceGuard (Credential Guard running), not just profile status." -ForegroundColor DarkGray
