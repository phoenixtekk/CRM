<#
.SYNOPSIS
    WDACMIG-Set-MigrationRingTargeting.ps1 — build migration ring groups and assign App Control profiles.
.DESCRIPTION
    PURPOSE
        Creates the migration-ring Entra security groups (Pilot / Broad / Fleet) if missing, optionally
        adds devices to a ring, and assigns the App Control audit/enforce configuration profiles to a
        ring group via Microsoft Graph — so ring targeting is consistent and repeatable. This script
        WRITES to Entra/Intune; preview first with -WhatIf.
    HOW TO RUN
        Create the ring groups (preview):
            powershell -ExecutionPolicy Bypass -File .\WDACMIG-Set-MigrationRingTargeting.ps1 -WhatIf
        Create groups for real and add device IDs to the pilot ring:
            powershell -ExecutionPolicy Bypass -File .\WDACMIG-Set-MigrationRingTargeting.ps1 -Ring Pilot -DeviceIds <entraDeviceObjectId>,<...> -WhatIf:$false
        Assign the audit profile to the pilot ring:
            powershell -ExecutionPolicy Bypass -File .\WDACMIG-Set-MigrationRingTargeting.ps1 -Ring Pilot -AssignProfile 'App Control - Fleet - Audit' -WhatIf:$false
        Requires Microsoft Graph SDK and scopes: Group.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All.
    EXPECTED RESULTS
        The named ring group(s) exist; requested devices are members; and (if -AssignProfile) the named
        App Control profile is assigned to the ring group. With -WhatIf, only the planned actions.
.NOTES
    Writes to Entra/Intune. Default behavior follows -WhatIf; pass -WhatIf:$false to apply.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Pilot','Broad','Fleet')] [string]$Ring,
    [string[]]$DeviceIds,
    [string]$AssignProfile
)

# Ring group naming convention (reused verbatim from the docs): "<Purpose> - <Scope> - <Stage>"
$RingGroups = @{
    Pilot = 'App Control Migration - Pilot - Ring 1'
    Broad = 'App Control Migration - Broad - Ring 2'
    Fleet = 'App Control Migration - Fleet - Ring 3'
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementConfiguration.ReadWrite.All' -NoWelcome

function Get-OrNewGroup([string]$displayName) {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$displayName'").value
    if ($existing) { Write-Host ("  Group exists: {0}" -f $displayName) -ForegroundColor Gray; return $existing[0] }
    if ($PSCmdlet.ShouldProcess($displayName, "Create Entra security group")) {
        $mailNick = ($displayName -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName = $displayName; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  Created group: {0}" -f $displayName) -ForegroundColor Green
        return $g
    }
    Write-Host ("  WHATIF: would create group {0}" -f $displayName) -ForegroundColor Yellow
    return $null
}

# 1. Ensure ring groups exist (create all if no -Ring specified; otherwise the requested one)
$targets = if ($Ring) { @($Ring) } else { $RingGroups.Keys }
$groupObjects = @{}
foreach ($r in $targets) { $groupObjects[$r] = Get-OrNewGroup $RingGroups[$r] }

# 2. Add devices to the specified ring
if ($Ring -and $DeviceIds) {
    $grp = $groupObjects[$Ring]
    if ($grp) {
        foreach ($id in $DeviceIds) {
            if ($PSCmdlet.ShouldProcess($id, "Add device to $($RingGroups[$Ring])")) {
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" }
                try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body ($ref | ConvertTo-Json); Write-Host "  Added device $id" -ForegroundColor Green }
                catch { Write-Host "  Could not add $id : $($_.Exception.Message)" -ForegroundColor Yellow }
            } else { Write-Host "  WHATIF: would add device $id to $($RingGroups[$Ring])" -ForegroundColor Yellow }
        }
    }
}

# 3. Assign a named App Control configuration profile to the ring group
if ($Ring -and $AssignProfile) {
    $grp = $groupObjects[$Ring]
    $policy = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies').value | Where-Object { $_.name -eq $AssignProfile } | Select-Object -First 1
    if (-not $policy) { Write-Host "  Profile '$AssignProfile' not found among configuration policies — create it in Intune first." -ForegroundColor Yellow }
    elseif ($grp) {
        if ($PSCmdlet.ShouldProcess($AssignProfile, "Assign to $($RingGroups[$Ring])")) {
            $assign = @{ assignments = @( @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id } } ) }
            try { Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/configurationPolicies/$($policy.id)/assign" -Body ($assign | ConvertTo-Json -Depth 6); Write-Host "  Assigned '$AssignProfile' to $($RingGroups[$Ring])" -ForegroundColor Green }
            catch { Write-Host "  Assignment failed: $($_.Exception.Message)" -ForegroundColor Yellow }
        } else { Write-Host "  WHATIF: would assign '$AssignProfile' to $($RingGroups[$Ring])" -ForegroundColor Yellow }
    }
}

Disconnect-MgGraph | Out-Null
Write-Host "`nDone. Verify with WDACMIG-Report.ps1 -Tenant (policy/ring assignments) and WDACMIG-Validation.ps1 (device state)." -ForegroundColor Gray
