<#
.SYNOPSIS
    CUSTCOMP-Set-ScopeTargeting.ps1 — create the custom-compliance pilot/broad device groups (Graph).
.DESCRIPTION
    PURPOSE
        Ensures the scope groups used to stage custom compliance exist in Microsoft Entra ID:
        'CustomCompliance - Devices - Pilot' and 'CustomCompliance - Devices - Broad'. Creates them
        if missing. Optionally adds a named device (by device name) to the pilot group.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CUSTCOMP-Set-ScopeTargeting.ps1 `
            [-PilotDeviceName "PC-001"]
        Requires Microsoft Graph SDK and Group.ReadWrite.All (+ Device.Read.All for -PilotDeviceName).
    EXPECTED RESULTS
        Both groups exist (created or already present); their object IDs are printed for assignment.
.NOTES
    White-label — Intune Solutions. Creates groups when missing.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param([string]$PilotDeviceName)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','Device.Read.All' -NoWelcome

function Ensure-Group($name) {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $name)).value
    if ($existing) { Write-Host ("  Exists: {0}  ({1})" -f $name, $existing[0].id) -ForegroundColor Green; return $existing[0].id }
    if ($PSCmdlet.ShouldProcess($name, "Create security group")) {
        $mailNick = ($name -replace '[^a-zA-Z0-9]','')
        $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true }
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  Created: {0}  ({1})" -f $name, $g.id) -ForegroundColor Green; return $g.id
    }
}

Write-Host "=== Custom Compliance — scope groups ===" -ForegroundColor Cyan
$pilotId = Ensure-Group 'CustomCompliance - Devices - Pilot'
$broadId = Ensure-Group 'CustomCompliance - Devices - Broad'

if ($PilotDeviceName -and $pilotId) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/devices?`$filter=displayName eq '{0}'" -f $PilotDeviceName)).value | Select-Object -First 1
    if ($dev -and $PSCmdlet.ShouldProcess($PilotDeviceName, "Add to pilot group")) {
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($dev.id)" }
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body ($ref | ConvertTo-Json); Write-Host ("  Added {0} to pilot group." -f $PilotDeviceName) -ForegroundColor Green }
        catch { Write-Host ("  Could not add {0}: {1}" -f $PilotDeviceName, $_.Exception.Message) -ForegroundColor Yellow }
    }
    elseif (-not $dev) { Write-Host ("  Device not found: {0}" -f $PilotDeviceName) -ForegroundColor Yellow }
}
Write-Host "`nAssign the detection script, config item, and custom compliance policy to these groups." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
