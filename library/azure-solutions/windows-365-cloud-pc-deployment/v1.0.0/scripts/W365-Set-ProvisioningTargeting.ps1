<#
.SYNOPSIS
    W365-Set-ProvisioningTargeting.ps1 — create/populate the Cloud PC targeting groups.
.DESCRIPTION
    PURPOSE
        Builds the Entra ID security groups the Windows 365 provisioning policy is assigned to —
        'W365 - Users - Pilot' and 'W365 - Users - Production' — and optionally adds members from a
        list of user principal names. Creating a group makes no Cloud PCs by itself; assigning the
        provisioning policy to the group (Implementation Step 4/9) is what triggers provisioning.
    HOW TO RUN
        Create the groups only:
            powershell -ExecutionPolicy Bypass -File .\W365-Set-ProvisioningTargeting.ps1
        Create + add pilot members:
            powershell -ExecutionPolicy Bypass -File .\W365-Set-ProvisioningTargeting.ps1 -Stage Pilot -Upns user1@contoso.com,user2@contoso.com
        Requires the Microsoft Graph PowerShell SDK and Group.ReadWrite.All + User.Read.All.
    EXPECTED RESULTS
        The named group exists (created if missing); any supplied UPNs are added as members. Prints
        the group object id for use in the Intune assignment.
.NOTES
    Workplace Marketplace — Azure Solutions. Creates/updates groups only (no Cloud PC changes).
    Group naming uses the en-dash convention 'W365 - <Scope> - <Stage>' to match the docs.
#>
[CmdletBinding()]
param(
    [ValidateSet('Pilot','Production','Both')] [string]$Stage = 'Both',
    [string[]]$Upns
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrNew-Group([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  Exists : {0}  ({1})" -f $name, $g.id) -ForegroundColor Green; return $g.id }
    $mailNick = ($name -replace '[^a-zA-Z0-9]','')
    $body = @{ displayName = $name; mailEnabled = $false; mailNickname = $mailNick; securityEnabled = $true }
    $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("  Created: {0}  ({1})" -f $name, $new.id) -ForegroundColor Green
    return $new.id
}

function Add-Members([string]$groupId, [string[]]$upnList) {
    foreach ($upn in $upnList) {
        try {
            $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn"
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$groupId/members/`$ref" -Body ($ref | ConvertTo-Json)
            Write-Host ("    + added {0}" -f $upn) -ForegroundColor Green
        } catch { Write-Host ("    ! could not add {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
    }
}

Write-Host "`n=== Windows 365 targeting groups ===" -ForegroundColor Cyan
$targets = @()
if ($Stage -in 'Pilot','Both')      { $targets += @{ Stage='Pilot';      Name='W365 - Users - Pilot' } }
if ($Stage -in 'Production','Both') { $targets += @{ Stage='Production'; Name='W365 - Users - Production' } }

foreach ($t in $targets) {
    $id = Get-OrNew-Group $t.Name
    # Only add members to the stage explicitly requested (avoid putting pilot users into production).
    if ($Upns -and $Stage -ne 'Both' -and $t.Stage -eq $Stage) { Add-Members $id $Upns }
}
if ($Upns -and $Stage -eq 'Both') { Write-Host "  Note: -Upns ignored with -Stage Both; re-run with -Stage Pilot or Production to add members." -ForegroundColor Yellow }

Write-Host "`nAssign the provisioning policy to these groups in Intune (Devices > Windows 365)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
