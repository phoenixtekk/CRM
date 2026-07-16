<#
.SYNOPSIS
    SHAREDIPAD-Set-Restrictions.ps1 — assigns and verifies the field lockdown profile assignment.
    THE ONLY STATE-CHANGING SCRIPT IN THIS SOLUTION. DEFAULTS TO -WhatIf.

.DESCRIPTION
    PURPOSE
        Verifies, and where missing adds, the group assignment of the configuration profile
        'SHARED IPAD - Restrictions - Field Lockdown' to a named device group
        ('SHARED IPAD - FMD - Pilot' by default, 'SHARED IPAD - FMD - Production' at Expand).

        It exists because extending the lockdown to a new wave is the one repetitive click-path in this
        solution, and a missed assignment is a fleet of unlocked field iPads that nobody notices until
        someone installs a game on one.

        It also verifies (read-only, always) the two things that make the assignment actually deliver:
          * The target group is ASSIGNED, not Dynamic.
          * The Intune Provisioning Client service principal (AppId f1346770-5b25-470b-88bd-d5744ab7952c)
            is an OWNER of the group. Without this owner the group stays empty at enrollment and the
            assignment reaches nothing (Implementation Step 2b).

    *** THIS SCRIPT DEFAULTS TO -WhatIf ***
        Run with no switches and it CHANGES NOTHING. It reports exactly what it WOULD do and stops.
        This is deliberate: it is the only script here that can alter your tenant.

        To actually apply the assignment you must pass -WhatIf:$false EXPLICITLY:

            .\SHAREDIPAD-Set-Restrictions.ps1                      # WHAT-IF — reports only, changes nothing
            .\SHAREDIPAD-Set-Restrictions.ps1 -WhatIf:$false       # APPLIES the assignment (prompts to confirm)
            .\SHAREDIPAD-Set-Restrictions.ps1 -WhatIf:$false -Confirm:$false   # applies without prompting

        The script never removes an existing assignment, never edits the profile's settings, and never
        touches any other object.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser      # once

        # 1. Always dry-run first (this is the default):
        .\SHAREDIPAD-Set-Restrictions.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Pilot'

        # 2. Read the output. If it says what you expect, apply it:
        .\SHAREDIPAD-Set-Restrictions.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Pilot' -WhatIf:$false

        # At Expand (Implementation Step 14):
        .\SHAREDIPAD-Set-Restrictions.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Production' -WhatIf:$false

    REQUIRED GRAPH SCOPES
        DeviceManagementConfiguration.Read.All      (find the profile and read its assignments)
        DeviceManagementConfiguration.ReadWrite.All (ONLY needed to apply — i.e. with -WhatIf:$false)
        Group.Read.All                              (group type and owner verification)

    EXPECTED RESULTS
        In WHAT-IF (default): the profile and group are resolved, the current assignment state is
        reported, the group type and Provisioning Client owner are verified, and the script prints the
        exact change it WOULD make. Nothing is altered.

        With -WhatIf:$false: the group assignment is added if missing (existing assignments are
        preserved), then the result is re-read and confirmed. Already-assigned = reported and skipped.

.NOTES
    Intune Solutions — the only state-changing script in this package. Defaults to -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$DeviceGroupName = 'SHARED IPAD – FMD – Pilot',
    [string]$ProfileName     = 'SHARED IPAD – Restrictions – Field Lockdown'
)

$ErrorActionPreference = 'Stop'

# DEFAULT TO -WhatIf. If the caller did not explicitly pass -WhatIf, turn it ON.
# The caller must pass -WhatIf:$false to make any change.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
}

$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'

$scopes = @('DeviceManagementConfiguration.Read.All','Group.Read.All')
if (-not $WhatIfPreference) { $scopes += 'DeviceManagementConfiguration.ReadWrite.All' }

Connect-MgGraph -Scopes $scopes | Out-Null

function Get-GraphCollection {
    param([string]$Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($page.value) { $items += $page.value }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

Write-Host ''
Write-Host '=== Shared iPad — field lockdown assignment ===' -ForegroundColor Cyan
if ($WhatIfPreference) {
    Write-Host ''
    Write-Host ' *** WHAT-IF MODE (the default) — NOTHING WILL BE CHANGED. ***' -ForegroundColor Yellow
    Write-Host ' Pass -WhatIf:$false to apply.' -ForegroundColor Yellow
}
Write-Host ''

# ---------------------------------------------------------------------------
# Resolve the profile (exact display-name match)
# ---------------------------------------------------------------------------
$cfg  = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName'
$prof = @($cfg | Where-Object { $_.displayName -eq $ProfileName })

if ($prof.Count -eq 0) {
    throw "Configuration profile '$ProfileName' not found. The name must match EXACTLY — note the en dash characters (–), not hyphens. Create it first (Implementation Step 9)."
}
if ($prof.Count -gt 1) {
    throw "Found $($prof.Count) profiles named '$ProfileName'. Resolve the duplicate in Intune before running this — the script will not guess which one you mean."
}
$profileId = $prof[0].id
Write-Host "Profile: '$ProfileName'  (id $profileId)" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Resolve the group (exact display-name match)
# ---------------------------------------------------------------------------
$escaped = $DeviceGroupName.Replace("'", "''")
$grp = @(Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName,groupTypes")

if ($grp.Count -eq 0) {
    throw "Group '$DeviceGroupName' not found. The name must match EXACTLY — note the en dash characters (–), not hyphens. Create it first (Implementation Step 2)."
}
if ($grp.Count -gt 1) {
    throw "Found $($grp.Count) groups named '$DeviceGroupName'. Resolve the duplicate in Entra before running this."
}
$groupId = $grp[0].id
Write-Host "Group:   '$DeviceGroupName'  (id $groupId)" -ForegroundColor Green
Write-Host ''

# ---------------------------------------------------------------------------
# Pre-flight verification (always read-only — runs in both modes)
# ---------------------------------------------------------------------------
Write-Host '--- Pre-flight verification ---' -ForegroundColor Cyan
$preflightOk = $true

# Group must be Assigned, not Dynamic.
$isDynamic = $grp[0].groupTypes -contains 'DynamicMembership'
if ($isDynamic) {
    Write-Host '  [FAIL] Group membership type is DYNAMIC.' -ForegroundColor Red
    Write-Host '         Enrollment-time device grouping requires an ASSIGNED group. Assigning this'
    Write-Host '         profile to a dynamic group will not reliably reach ADE-enrolled devices'
    Write-Host '         (Implementation Step 2).'
    $preflightOk = $false
} else {
    Write-Host '  [PASS] Group membership type is Assigned.' -ForegroundColor Green
}

# The Intune Provisioning Client must own the group.
$ownerOk = $false
try {
    $owners = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/owners"
    foreach ($o in $owners) { if ($o.appId -eq $ProvisioningClientAppId) { $ownerOk = $true; break } }
} catch { }

if ($ownerOk) {
    Write-Host '  [PASS] Intune Provisioning Client is an Owner of the group.' -ForegroundColor Green
} else {
    Write-Host '  [FAIL] Intune Provisioning Client is NOT an Owner of the group.' -ForegroundColor Red
    Write-Host "         AppId $ProvisioningClientAppId is missing from Owners."
    Write-Host '         The group will stay EMPTY at enrollment and this assignment will reach'
    Write-Host '         NOTHING. Add it: Entra > Groups > (group) > Owners > Add owners, and search'
    Write-Host '         by the AppId — NOT the display name, which varies by tenant'
    Write-Host '         (Implementation Step 2b).'
    $preflightOk = $false
}

# Member count — informational.
try {
    $members = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/members?`$select=id"
    Write-Host "  [INFO] Group currently has $($members.Count) member(s)."
} catch { }

Write-Host ''

# ---------------------------------------------------------------------------
# Current assignment state
# ---------------------------------------------------------------------------
$assignments = @(Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$profileId/assignments")
$already = $assignments | Where-Object { $_.target -and $_.target.groupId -eq $groupId }

Write-Host '--- Current assignment state ---' -ForegroundColor Cyan
Write-Host "  '$ProfileName' currently has $($assignments.Count) assignment(s)."

if ($already) {
    Write-Host ''
    Write-Host "  [ALREADY ASSIGNED] '$ProfileName' is already assigned to '$DeviceGroupName'." -ForegroundColor Green
    Write-Host '  No change needed. Nothing to do.'
    Write-Host ''
    if (-not $preflightOk) {
        Write-Host '  NOTE: the assignment exists but PRE-FLIGHT FAILED above. The assignment is in' -ForegroundColor Yellow
        Write-Host '  place but will not deliver until the pre-flight failures are fixed.' -ForegroundColor Yellow
    }
    return
}

Write-Host ''
Write-Host "  [NOT ASSIGNED] '$ProfileName' is NOT assigned to '$DeviceGroupName'." -ForegroundColor Yellow
Write-Host ''

# ---------------------------------------------------------------------------
# The change
# ---------------------------------------------------------------------------
Write-Host '--- Proposed change ---' -ForegroundColor Cyan
Write-Host "  ADD a group assignment:"
Write-Host "     Profile : '$ProfileName'"
Write-Host "     Group   : '$DeviceGroupName'  ($groupId)"
Write-Host "     Existing $($assignments.Count) assignment(s) will be PRESERVED. Nothing is removed."
Write-Host ''

if (-not $preflightOk) {
    Write-Host ' PRE-FLIGHT FAILED. Fix the failures above before applying this assignment —' -ForegroundColor Red
    Write-Host ' otherwise you will assign a profile to a group that reaches no devices, and the' -ForegroundColor Red
    Write-Host ' field iPads will not be locked down while your console says they are.' -ForegroundColor Red
    Write-Host ''
}

# Rebuild the full assignment list (Graph replaces the set) — preserve what is there, add ours.
$newAssignments = @()
foreach ($a in $assignments) {
    $newAssignments += @{ target = $a.target }
}
$newAssignments += @{
    target = @{
        '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
        groupId       = $groupId
    }
}
$body = @{ assignments = $newAssignments } | ConvertTo-Json -Depth 10

if ($PSCmdlet.ShouldProcess("Profile '$ProfileName'", "Add group assignment to '$DeviceGroupName'")) {
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$profileId/assign" `
        -Body $body -ContentType 'application/json' | Out-Null

    Write-Host '  Assignment submitted. Verifying...' -ForegroundColor Cyan
    Start-Sleep -Seconds 3

    $after   = @(Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$profileId/assignments")
    $confirmed = $after | Where-Object { $_.target -and $_.target.groupId -eq $groupId }

    Write-Host ''
    if ($confirmed) {
        Write-Host "  [APPLIED] '$ProfileName' is now assigned to '$DeviceGroupName'." -ForegroundColor Green
        Write-Host "  The profile now has $($after.Count) assignment(s)."
        Write-Host ''
        Write-Host '  Next: allow the devices to sync, then confirm enforcement on the device itself'
        Write-Host '  (Testing Test 6). An assignment in the console is not enforcement on the iPad.'
    } else {
        Write-Host "  [WARNING] The assignment was submitted but could not be confirmed on read-back." -ForegroundColor Yellow
        Write-Host '  Check Intune > Devices > Configuration > (the profile) > Assignments manually.'
    }
} else {
    Write-Host ' WHAT-IF: no change was made.' -ForegroundColor Yellow
    Write-Host ' Re-run with -WhatIf:$false to apply the change described above.' -ForegroundColor Yellow
}
