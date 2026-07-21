<#
.SYNOPSIS
    WINGETSTORE-Set-Assignment.ps1 — assign a Microsoft Store (new) / winget app as Required or
    Available (self-service) to a pilot group. THE ONLY STATE-CHANGER — defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Adds a group assignment to an existing Store (new) / winget app in Intune:
          * -Intent required   -> Intune installs the app automatically on the group's devices, or
          * -Intent available  -> the app appears in Company Portal for on-demand self-service install.
        SAFETY: this is the only script that changes tenant state, and it DEFAULTS TO -WhatIf — it will
        only PREVIEW the change and print what it would do. Re-run with -WhatIf:$false to apply. Existing
        assignments are read first and preserved; this call adds one assignment, it does not replace the
        set.
    HOW TO RUN
        # Preview (default, no change):
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Set-Assignment.ps1 `
            -AppName "VLC media player – Winget – Available" `
            -GroupName "Store & Winget Apps – Pilot – Ring 1" -Intent available
        # Apply for real:
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Set-Assignment.ps1 `
            -AppName "Adobe Acrobat Reader – Store – Required" `
            -GroupName "Store & Winget Apps – Pilot – Ring 1" -Intent required -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementApps.ReadWrite.All   (add the app assignment)
        Group.Read.All                       (resolve the target group id from its name)
    EXPECTED RESULTS
        In preview (default): a "What if:" line describing the assignment that WOULD be added — no change.
        When applied: the assignment is added and the app's assignment list is re-printed.
.NOTES
    Intune Solutions — state-changing, ShouldProcess-gated, DEFAULTS TO -WhatIf. New Store app Graph
    type = 'microsoft.graph.winGetApp' (verify-with-Microsoft).
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$AppName,
    [Parameter(Mandatory)] [string]$GroupName,
    [ValidateSet('required','available','uninstall')] [string]$Intent = 'available'
)

# Default to preview: if the caller did not pass -WhatIf explicitly, force it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All','Group.Read.All' -NoWelcome

# Resolve app
$escA = $AppName.Replace("'","''")
$app = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$filter=displayName eq '$escA'").value | Select-Object -First 1
if (-not $app) { Write-Host "App '$AppName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# Resolve group
$escG = $GroupName.Replace("'","''")
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$escG'").value | Select-Object -First 1
if (-not $grp) { Write-Host "Group '$GroupName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

Write-Host ("App:   {0} ({1})" -f $app.displayName, $app.id) -ForegroundColor Cyan
Write-Host ("Group: {0} ({1})" -f $grp.displayName, $grp.id) -ForegroundColor Cyan
Write-Host ("Intent: {0}{1}" -f $Intent, $(if ($Intent -eq 'available') { ' (self-service via Company Portal)' } else { '' })) -ForegroundColor Cyan

$body = @{
    mobileAppAssignments = @(
        @{
            '@odata.type' = '#microsoft.graph.mobileAppAssignment'
            intent        = $Intent
            target        = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id }
            settings      = @{ '@odata.type' = '#microsoft.graph.winGetAppAssignmentSettings' }
        }
    )
} | ConvertTo-Json -Depth 6

$action = "Add '$Intent' assignment to group '$($grp.displayName)'"
if ($PSCmdlet.ShouldProcess($app.displayName, $action)) {
    Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceAppManagement/mobileApps/$($app.id)/assign" -Body $body -ContentType 'application/json'
    Write-Host "  Applied. Current assignments:" -ForegroundColor Green
    (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments").value |
        ForEach-Object { Write-Host ("    {0} -> group {1}" -f $_.intent, $_.target.groupId) }
} else {
    Write-Host "  Preview only (default -WhatIf). Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
