<#
.SYNOPSIS
    ENTAPPCAT-Set-Assignment.ps1 — assign a catalog app to a pilot group (the only state-changer).
.DESCRIPTION
    PURPOSE
        Creates (or reuses) the pilot Entra security group and assigns an existing Enterprise App
        Catalog app to it as Required, so you can pilot the app before broad rollout. This is the ONLY
        script in the set that changes state.
        DEFAULTS TO -WhatIf: it PREVIEWS the group create + assignment and changes NOTHING until you
        explicitly pass -WhatIf:$false. Run the preview first, confirm the target, then apply.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Set-Assignment.ps1 `
            -AppName "Catalog App – Sample App – Prod"
        Apply:
          powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Set-Assignment.ps1 `
            -AppName "Catalog App – Sample App – Prod" -WhatIf:$false
    GRAPH SCOPES
        DeviceManagementApps.ReadWrite.All, Group.ReadWrite.All   (delegated; write)
    EXPECTED RESULTS
        In preview: the group and assignment that WOULD be created. When applied: the pilot group
        exists and the app is assigned Required to it. Re-check with ENTAPPCAT-Validate.ps1.
.NOTES
    Intune Solutions. Default -WhatIf; supports ShouldProcess. Assigns to the PILOT ring only — expand
    to the broad ring from the Intune portal after the pilot passes (see the Implementation Guide).
    Enterprise App Catalog Graph type is verify-with-Microsoft.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)] [string]$AppName,
    [string]$PilotGroupName = 'Catalog Apps – Pilot Devices – Ring 1',
    [string]$GraphEnvironment = 'Global'
)
# Make -WhatIf the default unless the caller explicitly turns it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All','Group.ReadWrite.All' -Environment $GraphEnvironment -NoWelcome

Write-Host "=== Assign catalog app to pilot ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (PREVIEW MODE — no changes will be made. Pass -WhatIf:`$false to apply.)" -ForegroundColor Yellow }

# Resolve the app
$aesc = $AppName.Replace("'","''")
$app  = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=displayName eq '$aesc'").value | Select-Object -First 1
if (-not $app) { Write-Host "  App '$AppName' not found — add it from the Enterprise App Catalog first." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
Write-Host ("  App: {0} ({1})" -f $app.displayName, $app.id) -ForegroundColor Green

# Resolve or create the pilot group
$gesc = $PilotGroupName.Replace("'","''")
$grp  = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$gesc'").value | Select-Object -First 1
if ($grp) {
    Write-Host ("  Reusing pilot group: {0} ({1})" -f $PilotGroupName, $grp.id) -ForegroundColor Green
    $groupId = $grp.id
} else {
    if ($PSCmdlet.ShouldProcess($PilotGroupName, "Create Entra security group")) {
        $nick = ($PilotGroupName -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{ displayName=$PilotGroupName; mailEnabled=$false; mailNickname=$nick; securityEnabled=$true } | ConvertTo-Json
        $new  = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $body -ContentType 'application/json'
        $groupId = $new.id
        Write-Host ("  Created pilot group: {0} ({1})" -f $PilotGroupName, $groupId) -ForegroundColor Green
    } else {
        Write-Host "  Would create pilot group '$PilotGroupName'." -ForegroundColor Yellow
        $groupId = '<new-group-id>'
    }
}

# Assign the app Required to the pilot group
if ($PSCmdlet.ShouldProcess("$AppName -> $PilotGroupName", "Assign app Required to pilot group")) {
    $assignBody = @{
        mobileAppAssignments = @(
            @{
                '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                intent        = 'required'
                target        = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $groupId }
            }
        )
    } | ConvertTo-Json -Depth 6
    Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceAppManagement/mobileApps/$($app.id)/assign" -Body $assignBody -ContentType 'application/json'
    Write-Host "  Assigned '$AppName' Required to '$PilotGroupName'." -ForegroundColor Green
} else {
    Write-Host "  Would assign '$AppName' Required to '$PilotGroupName'." -ForegroundColor Yellow
}

Write-Host "`nNext: validate with ENTAPPCAT-Validate.ps1, then expand to the broad ring from the portal." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
