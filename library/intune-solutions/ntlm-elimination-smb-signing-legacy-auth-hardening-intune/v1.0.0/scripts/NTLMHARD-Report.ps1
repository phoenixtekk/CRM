<#
.SYNOPSIS
    NTLMHARD-Report.ps1 — coverage report for Windows devices (NTLM/SMB hardening applied or not).
.DESCRIPTION
    PURPOSE
        Produces a coverage report across Windows 10/11 devices: for each managed device, whether the
        NTLM/SMB legacy-auth hardening Settings Catalog policy is applied. Use it to measure coverage
        before widening a rollout and to find endpoints still missing the hardening. Read-only. Reports
        the endpoint hardening policy only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Report.ps1
        Optional: -ProfileName "NTLM-SMB Hardening - Pilot"  -CsvPath .\NTLMHARD-coverage.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of Windows devices with an Applied column (Yes/No/Error/Conflict) plus
        a coverage summary. Full coverage = every intended device shows Applied = Yes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'NTLM-SMB Hardening - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

$anchors = @('lmcompatibilitylevel','requiresecuritysignature','allowinsecureguestauth','restrictremoteclients')

# Locate the Settings Catalog policy (by name, then by settings content)
$policy = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($p in @($cfg.value)) { if ($p.name -eq $ProfileName) { $policy = $p; break } }
    if (-not $policy) {
        foreach ($p in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if (($anchors | Where-Object { $json -match [regex]::Escape($_) }).Count -ge 2) { $policy = $p; break }
        }
    }
} catch {}

if (-not $policy) { Write-Host "No NTLM/SMB hardening policy found (looked for '$ProfileName'). Nothing to report." -ForegroundColor Yellow; return }
$pName = $policy.name

# Devices that report a status for this policy
$applied = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/deviceStatuses"
    foreach ($s in @($stat.value)) {
        $applied["$($s.deviceDisplayName)"] = if ($s.status -match 'conflict') { 'Conflict' } elseif ($s.status -match 'success|compliant') { 'Yes' } elseif ($s.status -match 'error|failed') { 'Error' } else { 'No' }
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
$conf  = @($rows | Where-Object Applied -eq 'Conflict').Count
Write-Host ''
Write-Host ("Coverage: {0}/{1} Windows device(s) have the NTLM/SMB hardening applied (policy '{2}')." -f $yes, $total, $pName) -ForegroundColor Cyan
if ($conf -gt 0) { Write-Host ("  {0} device(s) in Conflict — another policy (e.g. a CIS/STIG baseline) likely sets the same settings." -f $conf) -ForegroundColor Yellow }
