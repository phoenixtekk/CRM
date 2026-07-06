<#
.SYNOPSIS
    MACSSOEXT-Report.ps1 — SSO coverage report for macOS devices (app-extension applied or not).
.DESCRIPTION
    PURPOSE
        Produces an SSO-coverage report across macOS devices: for each managed Mac, whether the
        Microsoft Enterprise SSO app-extension configuration profile is applied. Use it to measure
        coverage before widening a rollout and to find devices still missing the app/browser SSO
        extension. Read-only. Reports the app/browser SSO extension only, not Platform SSO device
        login.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACSSOEXT-Report.ps1
        Optional: -ProfileName "macOS SSO App Extension - Pilot"  -CsvPath .\MACSSOEXT-coverage.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of macOS devices with an Applied column (Yes/No/Error) plus a
        coverage summary. Full coverage = every intended Mac shows Applied = Yes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'macOS SSO App Extension - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

$ExtensionId = 'com.microsoft.CompanyPortalMac.ssoextension'

# Locate the SSO app-extension profile
$policy = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'macOS'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $policy = $pol; break } }
    if (-not $policy) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match [regex]::Escape($ExtensionId)) { $policy = $pol; break }
        }
    }
} catch {}

if (-not $policy) { Write-Host "No SSO app-extension profile found (looked for '$ProfileName'). Nothing to report." -ForegroundColor Yellow; return }

# Devices that report a status for this profile
$applied = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/deviceStatuses"
    foreach ($s in @($stat.value)) {
        $key = "$($s.deviceDisplayName)"
        $applied[$key] = if ($s.status -match 'success|compliant') { 'Yes' } elseif ($s.status -match 'error|failed') { 'Error' } else { 'No' }
    }
} catch {}

# All managed macOS devices
$rows = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    foreach ($d in @($md.value)) {
        $rows += [pscustomobject]@{
            Device   = $d.deviceName
            User     = $d.userPrincipalName
            OSVersion= $d.osVersion
            Applied  = $(if ($applied.ContainsKey($d.deviceName)) { $applied[$d.deviceName] } else { 'No' })
        }
    }
} catch { Write-Warning "Could not enumerate macOS devices: $($_.Exception.Message)" }

$rows | Sort-Object Applied, Device | Format-Table -AutoSize
if ($CsvPath) { $rows | Sort-Object Applied, Device | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

$total = @($rows).Count
$yes   = @($rows | Where-Object Applied -eq 'Yes').Count
Write-Host ''
Write-Host ("Coverage: {0}/{1} macOS device(s) have the SSO app extension applied (profile '{2}')." -f $yes, $total, $policy.name) -ForegroundColor Cyan
