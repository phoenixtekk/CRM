<#
.SYNOPSIS
    WINSECOPT-Report.ps1 — coverage report for the Windows interactive-logon & network-access hardening profile.
.DESCRIPTION
    PURPOSE
        Produces a coverage report across Windows devices: for each managed Windows 10/11 device,
        whether the interactive-logon & network-access hardening Settings Catalog profile is applied.
        Use it to measure coverage before widening a rollout and to find corporate devices still missing
        the four Security-Options controls. Read-only. Reports THIS gap-only pack only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Report.ps1
        Optional: -ProfileName "Interactive Logon & Network-Access Hardening - Pilot"  -CsvPath .\WINSECOPT-coverage.csv
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
    [string]$ProfileName = 'Interactive Logon & Network-Access Hardening - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

# Locate the Settings Catalog profile (by name first, then by carried settings)
$profile = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if ($json -match 'dontdisplaynetworkselectionui' -and $json -match 'smartcardremovalbehavior') { $profile = $pol; break }
        }
    }
} catch {}

if (-not $profile) { Write-Host "No Windows hardening profile found (looked for '$ProfileName'). Nothing to report." -ForegroundColor Yellow; return }
$pName = $profile.name

# Devices that report a status for this profile
$applied = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/deviceStatuses"
    foreach ($s in @($stat.value)) {
        $applied["$($s.deviceDisplayName)"] = if ($s.status -match 'success|compliant') { 'Yes' } elseif ($s.status -match 'error|failed') { 'Error' } else { 'No' }
    }
} catch {}

# All managed Windows devices
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
Write-Host ("Coverage: {0}/{1} Windows device(s) have the interactive-logon & network-access hardening profile applied (profile '{2}')." -f $yes, $total, $pName) -ForegroundColor Cyan
