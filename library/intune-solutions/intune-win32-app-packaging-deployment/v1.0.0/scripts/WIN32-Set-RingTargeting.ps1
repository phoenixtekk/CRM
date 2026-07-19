<#
.SYNOPSIS
    WIN32-Set-RingTargeting.ps1 — build the pilot/broad ring groups for Win32 app rollout.
.DESCRIPTION
    PURPOSE
        Creates (or reuses) the two Microsoft Entra security groups used to ring Win32 app
        assignments, using the <Purpose> – <Scope> – <Stage> naming convention:
            "App Deployment – Pilot Devices – Ring 1"  (a few representative devices)
            "App Deployment – Broad Devices – Ring 2"  (the rest of the fleet)
        Optionally adds device objects (by Entra deviceId) to the pilot group. Assign the Win32 app to
        Ring 1 first, validate, then expand to Ring 2 (see the Implementation Guide).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIN32-Set-RingTargeting.ps1
        powershell -ExecutionPolicy Bypass -File .\WIN32-Set-RingTargeting.ps1 -PilotDeviceIds "id1","id2"
        Requires the Microsoft Graph SDK and Group.ReadWrite.All (+ Device.Read.All to add members).
    EXPECTED RESULTS
        The two ring groups exist (created if missing) and any supplied pilot devices are added to
        Ring 1. The script prints each group's object id for use in the app assignment.
.NOTES
    Intune Solutions. Creates Entra security groups; gated by ShouldProcess.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PilotGroupName = 'App Deployment – Pilot Devices – Ring 1',
    [string]$BroadGroupName = 'App Deployment – Broad Devices – Ring 2',
    [string[]]$PilotDeviceIds
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

function Get-OrNew-RingGroup {
    param([string]$Name)
    $esc = $Name.Replace("'","''")
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value
    if ($existing) { Write-Host ("  Reusing group: {0} ({1})" -f $Name, $existing[0].id) -ForegroundColor Green; return $existing[0].id }
    if ($PSCmdlet.ShouldProcess($Name, "Create Entra security group")) {
        $nick = ($Name -replace '[^a-zA-Z0-9]','').ToLower()
        $body = @{ displayName=$Name; mailEnabled=$false; mailNickname=$nick; securityEnabled=$true } | ConvertTo-Json
        $new = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $body -ContentType 'application/json'
        Write-Host ("  Created group: {0} ({1})" -f $Name, $new.id) -ForegroundColor Green
        return $new.id
    }
}

Write-Host "=== Win32 ring targeting ===" -ForegroundColor Cyan
$pilotId = Get-OrNew-RingGroup -Name $PilotGroupName
$broadId = Get-OrNew-RingGroup -Name $BroadGroupName

if ($PilotDeviceIds -and $pilotId) {
    foreach ($d in $PilotDeviceIds) {
        if ($PSCmdlet.ShouldProcess($d, "Add device to $PilotGroupName")) {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/devices/$d" } | ConvertTo-Json
            try {
                Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body $ref -ContentType 'application/json'
                Write-Host ("  Added device {0} to pilot." -f $d) -ForegroundColor Green
            } catch { Write-Host ("  Could not add {0}: {1}" -f $d, $_.Exception.Message) -ForegroundColor Yellow }
        }
    }
}

Write-Host "`nAssign the Win32 app to '$PilotGroupName' first; expand to '$BroadGroupName' after the pilot passes." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
