<#
.SYNOPSIS
    MACVPP-Set-ScopeTargeting.ps1 — build the target Entra group and retarget macOS app assignments.
.DESCRIPTION
    PURPOSE
        Creates (or reuses) the Entra security group used to target macOS app deployment, optionally
        adds members, and optionally retargets named App Store (VPP) / enterprise (LOB) app
        assignments from the pilot to a wave or all-devices group. Defaults to -WhatIf so nothing
        changes until you confirm. Pass names like PILOT - macOS App Deployment and ids like
        your-app-id, not angle-bracket placeholders.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Preview only (default -WhatIf — no change):
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Set-ScopeTargeting.ps1 -GroupName 'PILOT - macOS App Deployment'
        # Create/populate the group and retarget apps (explicit opt-in):
        powershell -ExecutionPolicy Bypass -File .\MACVPP-Set-ScopeTargeting.ps1 -GroupName 'WAVE1 - macOS App Deployment' -MemberDeviceIds id1,id2 -AppIds appId1,appId2 -Confirm:$false
        Required Graph scopes: Group.ReadWrite.All, DeviceManagementApps.ReadWrite.All
    EXPECTED RESULTS
        With -WhatIf (default): prints the group it WOULD create/reuse and the assignments it WOULD set.
        Without -WhatIf: ensures the group exists, adds members, and assigns the named apps Required
        (device-licensed for VPP) to that group.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -Confirm:$false or approval
    at the prompt. Read-only against Microsoft Graph until a change is confirmed.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$GroupName,
    [string[]]$MemberDeviceIds,
    [string[]]$AppIds
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementApps.ReadWrite.All' | Out-Null

# Default to preview: if the caller did not pass -WhatIf or -Confirm, run as -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $PSBoundParameters.ContainsKey('Confirm')) {
    $WhatIfPreference = $true
    Write-Host 'No -WhatIf/-Confirm supplied — running in preview (-WhatIf) mode. Pass -Confirm:$false to apply.' -ForegroundColor Yellow
}

# --- Ensure the target group exists ---
$grp = $null
try {
    $enc = [uri]::EscapeDataString($GroupName)
    $found = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$enc'"
    $grp = @($found.value)[0]
} catch {}

if ($grp) {
    Write-Host "Reusing existing group '$GroupName' (id $($grp.id))." -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($GroupName, 'Create Entra security group')) {
        $body = @{
            displayName     = $GroupName
            mailEnabled     = $false
            mailNickname    = ($GroupName -replace '[^0-9A-Za-z]', '')
            securityEnabled = $true
        }
        $grp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        Write-Host "Created group '$GroupName' (id $($grp.id))." -ForegroundColor Green
    } else {
        Write-Host "WhatIf: would create Entra security group '$GroupName'." -ForegroundColor Yellow
    }
}

$groupId = if ($grp) { $grp.id } else { 'the-new-group' }

# --- Add members (device objects) ---
foreach ($devId in ($MemberDeviceIds | Where-Object { $_ })) {
    if ($PSCmdlet.ShouldProcess("$GroupName", "Add device $devId as member")) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$devId" }
        try {
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$ref" -Body ($ref | ConvertTo-Json) -ContentType 'application/json' | Out-Null
            Write-Host "Added device $devId to '$GroupName'." -ForegroundColor Green
        } catch { Write-Warning "Could not add $devId: $($_.Exception.Message)" }
    }
}

# --- Retarget named apps (Required) to this group ---
foreach ($appId in ($AppIds | Where-Object { $_ })) {
    if ($PSCmdlet.ShouldProcess($appId, "Assign app Required to group $GroupName")) {
        # Detect VPP vs. non-VPP to pick the right assignment settings.
        $useVppSettings = $false
        try {
            $app = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$appId"
            $useVppSettings = ("$($app.'@odata.type')" -match 'macOsVppApp')
        } catch {}
        $assignment = @{
            '@odata.type' = '#microsoft.graph.mobileAppAssignment'
            intent = 'required'
            target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $groupId }
        }
        if ($useVppSettings) {
            $assignment.settings = @{ '@odata.type' = '#microsoft.graph.macOsVppAppAssignmentSettings'; useDeviceLicensing = $true }
        }
        $body = @{ mobileAppAssignments = @($assignment) }
        try {
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$appId/assign" -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
            Write-Host "App $appId assigned Required$(if($useVppSettings){' (device-licensed)'}) to '$GroupName'." -ForegroundColor Green
        } catch { Write-Warning "Assign failed for $appId: $($_.Exception.Message)" }
    }
}

Write-Host ''
Write-Host 'Scope targeting complete. Re-run MACVPP-Validation.ps1 on a member device to confirm the gate.' -ForegroundColor Green
