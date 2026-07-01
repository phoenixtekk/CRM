<#
.SYNOPSIS
    GPOM-Set-MigrationRingTargeting.ps1 — build the migration ring groups in Microsoft Entra (Graph).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the two Entra security groups used for the ringed cutover, named to
        the solution convention, and optionally seeds the pilot ring with device members:
            'GPO Migration - Devices - Pilot Ring'
            'GPO Migration - Devices - Broad Ring'
        Existing groups with the same name are reused, not duplicated.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPOM-Set-MigrationRingTargeting.ps1
        Seed pilot members: ... -PilotDeviceIds 'objId1','objId2'
        Requires the Microsoft.Graph module and Group.ReadWrite.All (admin consent).
    EXPECTED RESULTS
        Both groups exist (created or found) with their object IDs printed; any supplied pilot device
        object IDs are added to the pilot ring. Use these group names verbatim in the Intune
        assignments from the Implementation Guide.
.NOTES
    Workplace Marketplace — Intune Solutions. Creates/updates Entra groups only.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string[]] $PilotDeviceIds = @()
)

$pilotName = 'GPO Migration - Devices - Pilot Ring'
$broadName = 'GPO Migration - Devices - Broad Ring'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Get-OrNewGroup {
    param([string] $Name)
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$Name'").value
    if ($existing) { Write-Host ("  Found : {0}  ({1})" -f $Name, $existing[0].id) -ForegroundColor Green; return $existing[0].id }
    if ($PSCmdlet.ShouldProcess($Name, "Create Entra security group")) {
        $body = @{
            displayName     = $Name
            mailEnabled     = $false
            mailNickname    = ($Name -replace '[^a-zA-Z0-9]', '')
            securityEnabled = $true
        }
        $g = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body ($body | ConvertTo-Json)
        Write-Host ("  Created: {0}  ({1})" -f $Name, $g.id) -ForegroundColor Green
        return $g.id
    }
}

Write-Host "`n=== Building migration ring groups ===" -ForegroundColor Cyan
$pilotId = Get-OrNewGroup -Name $pilotName
$broadId = Get-OrNewGroup -Name $broadName

foreach ($id in $PilotDeviceIds) {
    if ($PSCmdlet.ShouldProcess($id, "Add device to '$pilotName'")) {
        try {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/devices/$id" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body ($ref | ConvertTo-Json)
            Write-Host ("  Added device {0} to pilot ring." -f $id) -ForegroundColor Green
        } catch {
            Write-Host ("  Could not add {0}: {1}" -f $id, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
}

Write-Host "`nUse these names verbatim in your Intune assignments:" -ForegroundColor Cyan
Write-Host ("  {0}" -f $pilotName)
Write-Host ("  {0}" -f $broadName)
Disconnect-MgGraph | Out-Null
