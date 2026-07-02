<#
.SYNOPSIS
    SCCMAPP-Set-AppRingTargeting.ps1 — build the pilot/broad app-assignment ring groups (Graph).
.DESCRIPTION
    PURPOSE
        Creates (idempotently) the Entra security groups used to assign migrated Win32 apps by ring,
        following the <Purpose> - <Scope> - <Stage> convention:
        "App Migration - Pilot Devices - Ring 1" and "App Migration - Broad Devices - Ring 2".
        Optionally adds device object IDs to the pilot ring so the same devices that received the
        SCCM deployment get the migrated app first.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Set-AppRingTargeting.ps1
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Set-AppRingTargeting.ps1 -PilotDeviceIds id1,id2
        Requires the Microsoft Graph SDK and Group.ReadWrite.All (+ Device.Read.All to add members).
    EXPECTED RESULTS
        Both ring groups exist (created if missing) and their object IDs are printed; any supplied
        pilot device IDs are added to the pilot ring.
.NOTES
    White-label — Migrations. Creates/updates Entra groups.
#>
[CmdletBinding()] param([string[]]$PilotDeviceIds)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

function Get-OrNew-Group([string]$Name) {
    $filter = "displayName eq '$($Name.Replace("'","''"))'"
    $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$filter").value | Select-Object -First 1
    if ($found) { Write-Host ("Exists: {0}  [{1}]" -f $Name, $found.id) -ForegroundColor Green; return $found.id }
    $body = @{
        displayName     = $Name
        mailEnabled     = $false
        mailNickname    = ($Name -replace '[^a-zA-Z0-9]','')
        securityEnabled = $true
    }
    $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("Created: {0}  [{1}]" -f $Name, $new.id) -ForegroundColor Cyan
    return $new.id
}

$pilotId = Get-OrNew-Group 'App Migration - Pilot Devices - Ring 1'
$broadId = Get-OrNew-Group 'App Migration - Broad Devices - Ring 2'

foreach ($devId in $PilotDeviceIds) {
    try {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$devId" }
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body ($ref | ConvertTo-Json)
        Write-Host ("  Added device {0} to pilot ring." -f $devId) -ForegroundColor Green
    } catch { Write-Host ("  Skipped {0}: {1}" -f $devId, $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`nPilot ring: $pilotId" -ForegroundColor Cyan
Write-Host "Broad ring: $broadId" -ForegroundColor Cyan
Write-Host "Assign the migrated Win32 app to the pilot ring first; expand to broad after the pilot gate passes." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
