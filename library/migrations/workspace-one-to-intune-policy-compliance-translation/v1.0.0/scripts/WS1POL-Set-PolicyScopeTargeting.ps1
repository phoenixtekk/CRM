<#
.SYNOPSIS
    WS1POL-Set-PolicyScopeTargeting.ps1 — create/populate the policy-scope Entra groups for staged assignment.
.DESCRIPTION
    PURPOSE
        Creates the Microsoft Entra security groups that scope mapped-policy assignment by stage —
        'Policy Scope - Pilot - Stage' and 'Policy Scope - Production - Stage' — and optionally adds
        device object IDs to the pilot group, so the Pilot-then-Expand model is concrete and
        reversible. Idempotent: existing groups are reused, not duplicated.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1POL-Set-PolicyScopeTargeting.ps1
        powershell -ExecutionPolicy Bypass -File .\WS1POL-Set-PolicyScopeTargeting.ps1 -PilotDeviceIds id1,id2
        Requires Microsoft Graph SDK with Group.ReadWrite.All (and GroupMember.ReadWrite.All to add members).
    EXPECTED RESULTS
        Both policy-scope groups exist (created if missing); any supplied device object IDs are added
        to 'Policy Scope - Pilot - Stage'. Prints each group's object ID for use in policy assignment.
.NOTES
    Workspace ONE to Intune migration — creates/updates Entra groups (write). Membership add is opt-in.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$PilotDeviceIds
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','GroupMember.ReadWrite.All' -NoWelcome

function Get-OrNew-Group([string]$name) {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $name)).value
    if ($existing) { Write-Host ("  exists : {0}  ({1})" -f $name, $existing[0].id) -ForegroundColor Green; return $existing[0] }
    if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]', '')
        $body = @{ displayName = $name; description = 'Workspace ONE to Intune policy translation scope'; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true } | ConvertTo-Json
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
        Write-Host ("  created: {0}  ({1})" -f $name, $g.id) -ForegroundColor Green
        return $g
    }
}

Write-Host "`n=== Policy-scope groups ===" -ForegroundColor Cyan
$pilot = Get-OrNew-Group 'Policy Scope - Pilot - Stage'
$prod  = Get-OrNew-Group 'Policy Scope - Production - Stage'

if ($PilotDeviceIds -and $pilot) {
    foreach ($id in $PilotDeviceIds) {
        if ($PSCmdlet.ShouldProcess($id, "Add device to 'Policy Scope - Pilot - Stage'")) {
            try {
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" } | ConvertTo-Json
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($pilot.id)/members/`$ref" -Body $ref -ContentType 'application/json'
                Write-Host ("  added device {0} to pilot group" -f $id) -ForegroundColor Green
            } catch { Write-Host ("  could not add {0}: {1}" -f $id, $_.Exception.Message) -ForegroundColor Yellow }
        }
    }
}

Write-Host "`nAssign these groups to 'Mapped Config - <Platform> - Pilot' and 'Mapped Compliance - <Platform> - Pilot'." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
