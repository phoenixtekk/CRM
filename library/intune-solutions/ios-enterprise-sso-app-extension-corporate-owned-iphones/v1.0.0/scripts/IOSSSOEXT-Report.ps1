<#
.SYNOPSIS
    IOSSSOEXT-Report.ps1 — SSO coverage report for iOS/iPadOS devices (app-extension applied or not).
.DESCRIPTION
    PURPOSE
        Produces an SSO-coverage report across iOS/iPadOS devices: for each managed iPhone/iPad,
        whether the Microsoft Enterprise SSO app-extension profile is applied. Use it to measure
        coverage before widening a rollout and to find corporate devices still missing the
        app/browser SSO extension. Read-only. Reports the app/browser SSO extension only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Report.ps1
        Optional: -ProfileName "iOS SSO App Extension - Pilot"  -CsvPath .\IOSSSOEXT-coverage.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of iOS/iPadOS devices with an Applied column (Yes/No/Error) plus a
        coverage summary. Full coverage = every intended device shows Applied = Yes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'iOS SSO App Extension - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

$ExtensionId = 'com.microsoft.azureauthenticator.ssoextension'

# Locate the SSO app-extension profile (template first, then settings catalog)
$profile = $null; $kind = 'none'
try {
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosDeviceFeaturesConfiguration')"
    foreach ($p in @($tpl.value)) { if ($p.displayName -eq $ProfileName) { $profile = $p; $kind = 'template'; break } }
    if (-not $profile) { foreach ($p in @($tpl.value)) { if (("$($p | ConvertTo-Json -Depth 30)") -match 'singleSignOnExtension') { $profile = $p; $kind = 'template'; break } } }
    if (-not $profile) {
        $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'iOS'"
        foreach ($pol in @($cfg.value)) {
            if ($pol.name -eq $ProfileName) { $profile = $pol; $kind = 'catalog'; break }
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match [regex]::Escape($ExtensionId)) { $profile = $pol; $kind = 'catalog'; break }
        }
    }
} catch {}

if (-not $profile) { Write-Host "No iOS SSO app-extension profile found (looked for '$ProfileName'). Nothing to report." -ForegroundColor Yellow; return }
$pName = if ($kind -eq 'template') { $profile.displayName } else { $profile.name }
$base  = if ($kind -eq 'template') { "deviceConfigurations/$($profile.id)" } else { "configurationPolicies/$($profile.id)" }

# Devices that report a status for this profile
$applied = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/deviceStatuses"
    foreach ($s in @($stat.value)) {
        $applied["$($s.deviceDisplayName)"] = if ($s.status -match 'success|compliant') { 'Yes' } elseif ($s.status -match 'error|failed') { 'Error' } else { 'No' }
    }
} catch {}

# All managed iOS devices
$rows = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'"
    foreach ($d in @($md.value)) {
        $rows += [pscustomobject]@{
            Device    = $d.deviceName
            User      = $d.userPrincipalName
            OSVersion = $d.osVersion
            Applied   = $(if ($applied.ContainsKey($d.deviceName)) { $applied[$d.deviceName] } else { 'No' })
        }
    }
} catch { Write-Warning "Could not enumerate iOS devices: $($_.Exception.Message)" }

$rows | Sort-Object Applied, Device | Format-Table -AutoSize
if ($CsvPath) { $rows | Sort-Object Applied, Device | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

$total = @($rows).Count
$yes   = @($rows | Where-Object Applied -eq 'Yes').Count
Write-Host ''
Write-Host ("Coverage: {0}/{1} iOS/iPadOS device(s) have the SSO app extension applied (profile '{2}')." -f $yes, $total, $pName) -ForegroundColor Cyan
