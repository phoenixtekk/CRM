<#
.SYNOPSIS
    CMG-Report.ps1 - Read-only internet-client health and reach report for a Configuration Manager
    Cloud Management Gateway (CMG) deployment.

.DESCRIPTION
    Purpose:
        Produces a report of internet-facing clients and CMG health: the CMG service state, the
        connection point, and per-client last policy / last inventory / last active time so you can
        tell a healthy internet client from a dark one. READ-ONLY: queries only; makes no changes.

    How to run:
        1. Run on the site server (or console host) elevated, as a user with ConfigMgr read access.
        2. .\CMG-Report.ps1 -SiteCode "ABC" -CollectionName "CMG - Internet Clients - Pilot" `
                            -CsvPath "C:\Temp\cmg-report.csv"
           (CollectionName defaults to 'CMG - Internet Clients - Pilot'; CsvPath optional.)

    Expected results:
        Console summary of CMG state and connection point, plus a per-device table (and optional CSV)
        of last policy/inventory/active times for the pilot collection. No objects are modified.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$SiteCode,
    [Parameter(Mandatory = $false)][string]$CollectionName = "CMG - Internet Clients - Pilot",
    [Parameter(Mandatory = $false)][string]$CsvPath
)

function Write-Section($Title) { Write-Host "`n=== $Title ===" -ForegroundColor Cyan }

if (-not $env:SMS_ADMIN_UI_PATH) { Write-Warning "Run on a host with the ConfigMgr console installed."; return }
$cmModule = Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH) "ConfigurationManager.psd1"
if (-not (Test-Path $cmModule)) { Write-Warning "ConfigurationManager.psd1 not found."; return }
Import-Module $cmModule -ErrorAction Stop

$siteDrive = Get-PSDrive -PSProvider CMSite -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $siteDrive) { Write-Warning "No CMSite PS drive found. Open the console once."; return }
if (-not $SiteCode) { $SiteCode = $siteDrive.Name }
Push-Location "$($SiteCode):"

try {
    Write-Section "CMG service health"
    $cmg = Get-CMCloudManagementGateway -ErrorAction SilentlyContinue
    if ($cmg) { $cmg | Select-Object Name, State | Format-Table -AutoSize | Out-String | Write-Host }
    else { Write-Host "No CMG found." -ForegroundColor Yellow }

    Write-Section "CMG connection point"
    $cp = Get-CMCloudManagementGatewayConnectionPoint -ErrorAction SilentlyContinue
    if ($cp) { $cp | Select-Object SiteCode, NetworkOSPath | Format-Table -AutoSize | Out-String | Write-Host }
    else { Write-Host "No CMG connection point found." -ForegroundColor Yellow }

    Write-Section "Internet-client health: $CollectionName"
    $coll = Get-CMDeviceCollection -Name $CollectionName -ErrorAction SilentlyContinue
    if (-not $coll) {
        Write-Host "Collection '$CollectionName' not found. Create it (Implementation Step 2)." -ForegroundColor Yellow
    } else {
        $devices = Get-CMDevice -CollectionName $CollectionName -ErrorAction SilentlyContinue
        if (-not $devices) {
            Write-Host "No devices in the collection." -ForegroundColor Yellow
        } else {
            $rows = $devices | Select-Object `
                Name,
                @{N='Client';        E={ if ($_.IsClient) {'Yes'} else {'No'} }},
                @{N='LastPolicy';    E={ $_.LastPolicyRequest }},
                @{N='LastActive';    E={ $_.LastActiveTime }},
                @{N='LastHWScan';    E={ $_.LastHardwareScan }}
            $rows | Format-Table -AutoSize | Out-String | Write-Host
            if ($CsvPath) {
                $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
                Write-Host "CSV written to $CsvPath" -ForegroundColor Green
            }
            $dark = $rows | Where-Object { -not $_.LastActive -or $_.LastActive -lt (Get-Date).AddDays(-7) }
            Write-Host ("Total: {0}   Possibly dark (no activity in 7 days): {1}" -f $rows.Count, ($dark | Measure-Object).Count)
        }
    }
}
finally {
    Pop-Location
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
