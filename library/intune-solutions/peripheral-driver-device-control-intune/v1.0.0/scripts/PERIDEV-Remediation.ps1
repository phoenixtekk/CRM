<#
.SYNOPSIS
    PERIDEV-Remediation.ps1 — safely fix devices missing or blocked from PERIDEV coverage.
.DESCRIPTION
    PURPOSE
        Safe remediation for devices out of coverage: ensures the target group is assigned to
        the PERIDEV driver, printer, and device-control policies, and triggers a device sync so
        fixes apply. Defaults to preview mode (-WhatIf) and changes nothing until you re-run to
        confirm. Only re-assigns known PERIDEV policies and syncs devices - it never blocks,
        deletes, or reconfigures policy rules.
    HOW TO RUN
        Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Remediation.ps1

        Apply changes:
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Remediation.ps1 -WhatIf:$false

        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All,
        DeviceManagementManagedDevices.PrivilegedOperations.All, Group.Read.All
    EXPECTED RESULTS
        In preview: a list of the assignments and syncs that WOULD be performed. When applied:
        the target group is assigned to any PERIDEV policy missing it, and covered devices are
        sent a sync. Pass = planned/applied actions listed without error.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; re-run with -WhatIf:$false to apply.
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$GroupName = 'SG-PERIDEV-Pilot'
)

# Default to preview unless the caller explicitly turns WhatIf off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'

$PolicyNames = @(
    'PERIDEV-DriverUpdates-Pilot',
    'PERIDEV-Printers-Pilot',
    'PERIDEV-Peripherals-DeviceInstall',
    'PERIDEV-DeviceControl-USB-Pilot'
)

function Connect-PeridevGraph {
    $scopes = @('DeviceManagementConfiguration.ReadWrite.All','DeviceManagementManagedDevices.PrivilegedOperations.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph." -ForegroundColor Green
}

Connect-PeridevGraph

# Resolve target group
$gid = $null
try {
    $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'" -ErrorAction Stop
    $gid = $g.value[0].id
} catch { }
if (-not $gid) { throw "Target group '$GroupName' not found. Create it first (see PERIDEV-Set-ScopeTargeting.ps1)." }
Write-Host ("Target group '{0}' resolved ({1})." -f $GroupName, $gid) -ForegroundColor Cyan

# 1) Ensure PERIDEV configuration policies are assigned to the group
try {
    $conf = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=200" -ErrorAction Stop
    foreach ($p in $conf.value) {
        if ($PolicyNames -notcontains $p.name) { continue }
        $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/assignments" -ErrorAction Stop
        $already = $asg.value | Where-Object { $_.target.groupId -eq $gid }
        if ($already) {
            Write-Host ("  OK  '{0}' already assigned to {1}." -f $p.name, $GroupName) -ForegroundColor DarkGray
            continue
        }
        if ($PSCmdlet.ShouldProcess("$($p.name)", "Assign group '$GroupName'")) {
            $existing = @()
            foreach ($a in $asg.value) { $existing += @{ target = $a.target } }
            $existing += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $gid } }
            $body = @{ assignments = $existing } | ConvertTo-Json -Depth 6
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/assign" -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
            Write-Host ("  FIXED  assigned '{0}' to {1}." -f $p.name, $GroupName) -ForegroundColor Green
        }
    }
} catch { Write-Warning "Assignment check/fix failed: $($_.Exception.Message)" }

# 2) Trigger a sync on member devices so fixes apply
try {
    $members = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$gid/members?`$top=200" -ErrorAction Stop
    $names = $members.value | Where-Object { $_.displayName } | ForEach-Object { $_.displayName }
    if ($names) {
        $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$top=200" -ErrorAction Stop
        $targetDevices = $md.value | Where-Object { $names -contains $_.deviceName }
        foreach ($d in $targetDevices) {
            if ($PSCmdlet.ShouldProcess($d.deviceName, "Trigger Intune sync")) {
                Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($d.id)/syncDevice" -ErrorAction Stop | Out-Null
                Write-Host ("  SYNC  requested for {0}." -f $d.deviceName) -ForegroundColor Green
            }
        }
    }
} catch { Write-Warning "Sync step failed: $($_.Exception.Message)" }

if ($WhatIfPreference) {
    Write-Host "`nPreview only. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
} else {
    Write-Host "`nRemediation applied." -ForegroundColor Green
}
