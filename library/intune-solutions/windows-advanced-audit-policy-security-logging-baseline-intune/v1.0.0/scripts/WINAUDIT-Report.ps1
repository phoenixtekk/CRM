<#
.SYNOPSIS
    WINAUDIT-Report.ps1 — audit-baseline coverage report for Windows devices (applied or not).
.DESCRIPTION
    PURPOSE
        Produces an audit-coverage report across Windows 10/11 devices: for each managed device, whether
        the Windows Advanced Audit Policy Settings Catalog profile is applied. Use it to measure coverage
        before widening a rollout and to find corporate devices still missing the audit baseline.
        Read-only. Reports the audit configuration baseline only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINAUDIT-Report.ps1
        Optional: -ProfileName "Win Audit Policy - Baseline - Pilot"  -CsvPath .\WINAUDIT-coverage.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of Windows devices with an Applied column (Yes/No/Error) plus a
        coverage summary. Full coverage = every intended device shows Applied = Yes.
.NOTES
    White-label - the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'Win Audit Policy - Baseline - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

# Locate the Windows Settings Catalog audit profile (by name, then by audit content)
$profile = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match 'audit_' -or ("$($settings | ConvertTo-Json -Depth 25)") -match 'ForceAuditPolicy') { $profile = $pol; break }
        }
    }
} catch {}

if (-not $profile) { Write-Host "No Windows audit Settings Catalog profile found (looked for '$ProfileName'). Nothing to report." -ForegroundColor Yellow; return }
$pName = $profile.name
$base  = "configurationPolicies/$($profile.id)"

# Devices that report a status for this profile
$applied = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/deviceStatuses"
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
Write-Host ("Coverage: {0}/{1} Windows device(s) have the audit baseline applied (profile '{2}')." -f $yes, $total, $pName) -ForegroundColor Cyan
