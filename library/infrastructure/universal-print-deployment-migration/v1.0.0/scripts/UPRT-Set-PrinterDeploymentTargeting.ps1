<#
.SYNOPSIS
    UPRT-Set-PrinterDeploymentTargeting.ps1 - build the printer-deployment groups.
.DESCRIPTION
    PURPOSE
        Creates the Entra ID security groups used to target Universal Print printer deployment, using
        the solution naming convention, and optionally stages initial members. These groups are then
        assigned to printer deployments in Intune (or granted to printer shares in Graph).
        Default object names:
          UniversalPrint - Printers - Pilot
          UniversalPrint - Printers - Broad
    HOW TO RUN
        Create both groups (idempotent - reuses any group that already exists):
          powershell -ExecutionPolicy Bypass -File .\UPRT-Set-PrinterDeploymentTargeting.ps1
        Create and add pilot members:
          ... -PilotMemberIds @('<entra-object-id-1>','<entra-object-id-2>')
        Requires Group.ReadWrite.All (delegated). Sign in when prompted.
    EXPECTED RESULTS
        The two security groups exist (created or found) and any supplied pilot members are added;
        the script prints each group's object id for use in Intune assignment / Graph share grants.
.NOTES
    Infrastructure solution - the repeatable way. Creates groups only; does not assign printers.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$PilotGroupName = 'UniversalPrint - Printers - Pilot',
    [string]$BroadGroupName = 'UniversalPrint - Printers - Broad',
    [string[]]$PilotMemberIds = @()
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

function Get-OrNewGroup([string]$Name) {
    # Look for an existing group by exact display name (idempotent).
    $filter = "displayName eq '$($Name.Replace("'","''"))'"
    $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$([uri]::EscapeDataString($filter))").value | Select-Object -First 1
    if ($existing) {
        Write-Host "  Found existing group '$Name' (id=$($existing.id))." -ForegroundColor DarkGray
        return $existing.id
    }
    if ($PSCmdlet.ShouldProcess($Name, "Create Entra ID security group")) {
        $mailNick = ($Name -replace '[^a-zA-Z0-9]', '')
        $body = @{
            displayName     = $Name
            mailEnabled     = $false
            mailNickname    = $mailNick
            securityEnabled = $true
        } | ConvertTo-Json
        $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
        Write-Host "  Created group '$Name' (id=$($g.id))." -ForegroundColor Green
        return $g.id
    }
    return $null
}

Write-Host "`n=== Build printer-deployment groups ===" -ForegroundColor Cyan
$pilotId = Get-OrNewGroup $PilotGroupName
$broadId = Get-OrNewGroup $BroadGroupName

# Stage pilot members, if provided.
foreach ($id in $PilotMemberIds) {
    if ($pilotId -and $PSCmdlet.ShouldProcess("$id -> $PilotGroupName", "Add member to group")) {
        try {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" } | ConvertTo-Json
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body $ref -ContentType 'application/json'
            Write-Host "  Added $id to '$PilotGroupName'." -ForegroundColor Green
        } catch {
            Write-Host "  Could not add $id (already a member?): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nGroups ready:" -ForegroundColor Green
Write-Host ("  Pilot: {0}  ->  {1}" -f $PilotGroupName, $pilotId)
Write-Host ("  Broad: {0}  ->  {1}" -f $BroadGroupName, $broadId)
Write-Host "Use these group ids in the Intune Universal Print printer deployment assignment." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
