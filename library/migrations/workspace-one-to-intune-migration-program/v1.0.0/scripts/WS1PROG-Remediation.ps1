<#
.SYNOPSIS
    WS1PROG-Remediation.ps1 - Safe remediation helpers for failed Workspace ONE -> Intune migrations.

    PURPOSE:
        Fixes common post-cutover issues, all SAFE BY DEFAULT (-WhatIf / preview; -Apply to act):
          - RetryEnrollmentSync  : trigger an Intune sync on a managed device so it re-pulls policy/apps.
          - AddToWaveGroup       : (re-)add a device or user to its wave Entra group so targeting applies.
          - ReEvaluateCompliance : trigger a compliance re-check (device sync) on a managed device.
        These act ONLY on the Microsoft Intune / Entra TARGET side via Microsoft Graph. Releasing a
        device from Workspace ONE (the source side) is a console/API action DEFERRED to current VMware
        documentation and is intentionally NOT performed here.

    HOW TO RUN:
        1. Install the Microsoft Graph PowerShell SDK (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Preview (default, no changes):
             .\WS1PROG-Remediation.ps1 -Mode RetryEnrollmentSync -InputCsv ".\fixes.csv"
        3. Apply (you will still be asked to confirm):
             .\WS1PROG-Remediation.ps1 -Mode RetryEnrollmentSync -InputCsv ".\fixes.csv" -Apply

        Input CSV columns by mode:
          RetryEnrollmentSync  : DeviceName
          AddToWaveGroup       : WaveGroupName, MemberName        (MemberName = device or user display name/UPN)
          ReEvaluateCompliance : DeviceName

    EXPECTED RESULTS:
        Without -Apply: a per-row "WOULD ..." preview and no changes. With -Apply: the action is taken
        (with confirmation) and reported per row. A changed/skipped/failed summary prints at the end.

.NOTES
    Migrations - safe-by-default (-WhatIf). Intune/Entra side via Microsoft Graph PowerShell.
    Workspace ONE (source) release actions are deferred to current VMware documentation.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateSet('RetryEnrollmentSync','AddToWaveGroup','ReEvaluateCompliance')]
    [string]$Mode,
    [Parameter(Mandatory)][string]$InputCsv,
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
$rows = Import-Csv $InputCsv
$changed = 0; $skipped = 0; $failed = 0

# Force preview unless -Apply (ShouldProcess honors WhatIfPreference automatically).
if (-not $Apply) { $WhatIfPreference = $true }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = switch ($Mode) {
    'AddToWaveGroup' { @("Group.ReadWrite.All","Device.Read.All","User.Read.All","Directory.Read.All") }
    default          { @("DeviceManagementManagedDevices.ReadWrite.All") }
}
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $scopes -NoWelcome
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

function Do-Action {
    param([string]$Target, [string]$Op, [scriptblock]$Action)
    try {
        if ($PSCmdlet.ShouldProcess($Target, $Op)) {
            & $Action
            Write-Host ("CHANGED: {0} - {1}" -f $Op, $Target) -ForegroundColor Green
            $script:changed++
        } else {
            Write-Host ("WOULD {0}: {1}" -f $Op, $Target) -ForegroundColor Yellow
            $script:skipped++
        }
    } catch {
        Write-Host ("FAILED: {0} - {1} :: {2}" -f $Op, $Target, $_.Exception.Message) -ForegroundColor Red
        $script:failed++
    }
}

function Get-DeviceByName {
    param([string]$Name)
    Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$Name'" -Top 1
}

switch ($Mode) {

    'RetryEnrollmentSync' {
        foreach ($r in $rows) {
            $dev = Get-DeviceByName -Name $r.DeviceName
            if (-not $dev) { Write-Host ("SKIP: device not found in Intune - {0}" -f $r.DeviceName) -ForegroundColor Yellow; $skipped++; continue }
            Do-Action -Target $r.DeviceName -Op "Trigger Intune device sync" -Action {
                Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $dev.Id -ErrorAction Stop
            }
        }
    }

    'ReEvaluateCompliance' {
        foreach ($r in $rows) {
            $dev = Get-DeviceByName -Name $r.DeviceName
            if (-not $dev) { Write-Host ("SKIP: device not found in Intune - {0}" -f $r.DeviceName) -ForegroundColor Yellow; $skipped++; continue }
            # A device sync forces a fresh compliance evaluation against the assigned policy.
            Do-Action -Target $r.DeviceName -Op "Force compliance re-evaluation (device sync)" -Action {
                Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $dev.Id -ErrorAction Stop
            }
        }
    }

    'AddToWaveGroup' {
        foreach ($r in $rows) {
            $grp = Get-MgGroup -Filter "displayName eq '$($r.WaveGroupName)'" -Top 1
            if (-not $grp) { Write-Host ("SKIP: wave group not found - {0}" -f $r.WaveGroupName) -ForegroundColor Yellow; $skipped++; continue }

            # Resolve the member as a device first, then a user (by displayName or UPN).
            $member = Get-MgDevice -Filter "displayName eq '$($r.MemberName)'" -Top 1
            if (-not $member) { $member = Get-MgUser -Filter "userPrincipalName eq '$($r.MemberName)' or displayName eq '$($r.MemberName)'" -Top 1 }
            if (-not $member) { Write-Host ("SKIP: member not found - {0}" -f $r.MemberName) -ForegroundColor Yellow; $skipped++; continue }

            Do-Action -Target ("{0} -> {1}" -f $r.MemberName, $r.WaveGroupName) -Op "Add member to wave group" -Action {
                New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $member.Id -ErrorAction Stop
            }
        }
    }
}

Write-Host ("`nSummary [{0}] - Changed: {1}  WouldChange/Skipped: {2}  Failed: {3}" -f $Mode, $changed, $skipped, $failed) -ForegroundColor Cyan
if (-not $Apply) { Write-Host "Preview only. Re-run with -Apply to make changes." -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
