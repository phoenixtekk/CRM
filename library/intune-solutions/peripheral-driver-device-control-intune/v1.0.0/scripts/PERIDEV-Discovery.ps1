<#
.SYNOPSIS
    PERIDEV-Discovery.ps1 — inventory driver, peripheral/printer, and device-control policies in Intune.
.DESCRIPTION
    PURPOSE
        Read-only discovery of the current state for peripheral, driver, and device-control
        management. Lists Windows driver update policies, printer/peripheral configuration
        profiles, and removable-storage / Defender device-control policies, with their group
        assignments, so you can assess before you configure. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Discovery.ps1

        Required Graph scopes: DeviceManagementConfiguration.Read.All, Group.Read.All
    EXPECTED RESULTS
        A per-policy list grouped by area (Drivers / Peripherals-Printers / Device-Control)
        with names, IDs, and assigned groups, plus a summary count. Pass = the console prints
        the inventory without error; Fail = a connection or scope error is shown.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$OutCsv
)

$ErrorActionPreference = 'Stop'

function Connect-PeridevGraph {
    $scopes = @('DeviceManagementConfiguration.Read.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph." -ForegroundColor Green
}

function Get-PeridevAssignments {
    param([string]$Uri)
    $groups = @()
    try {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
        foreach ($a in $resp.value) {
            $gid = $a.target.groupId
            if ($gid) {
                try {
                    $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$gid" -ErrorAction Stop
                    $groups += $g.displayName
                } catch { $groups += $gid }
            } elseif ($a.target.'@odata.type' -match 'allDevices') { $groups += 'All Devices' }
            elseif ($a.target.'@odata.type' -match 'allLicensedUsers') { $groups += 'All Users' }
        }
    } catch { }
    return ($groups -join '; ')
}

Connect-PeridevGraph

$results = @()

Write-Host "`n=== Drivers: Windows driver update policies ===" -ForegroundColor Cyan
try {
    $drv = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsDriverUpdateProfiles" -ErrorAction Stop
    foreach ($p in $drv.value) {
        $asg = Get-PeridevAssignments -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsDriverUpdateProfiles/$($p.id)/assignments"
        $row = [pscustomobject]@{ Area='Drivers'; Name=$p.displayName; Id=$p.id; Detail=$p.approvalType; Assignments=$asg }
        $results += $row
        Write-Host ("  {0}  [{1}]  -> {2}" -f $p.displayName, $p.approvalType, $asg)
    }
    if (-not $drv.value) { Write-Host "  (none found)" -ForegroundColor DarkGray }
} catch { Write-Warning "Driver policy read failed: $($_.Exception.Message)" }

Write-Host "`n=== Peripherals / Printers & Device-Control: configuration profiles ===" -ForegroundColor Cyan
try {
    $conf = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=200" -ErrorAction Stop
    foreach ($p in $conf.value) {
        $name = $p.name
        $area = 'Peripherals-Printers'
        if ($name -match 'DeviceControl|USB|Removable|Device Control') { $area = 'Device-Control' }
        $asg = Get-PeridevAssignments -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/assignments"
        $results += [pscustomobject]@{ Area=$area; Name=$name; Id=$p.id; Detail=$p.platforms; Assignments=$asg }
        Write-Host ("  [{0}] {1}  -> {2}" -f $area, $name, $asg)
    }
    if (-not $conf.value) { Write-Host "  (none found)" -ForegroundColor DarkGray }
} catch { Write-Warning "Configuration policy read failed: $($_.Exception.Message)" }

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Group-Object Area | ForEach-Object {
    Write-Host ("  {0}: {1}" -f $_.Name, $_.Count)
}

if ($OutCsv) {
    $results | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported to $OutCsv" -ForegroundColor Green
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
