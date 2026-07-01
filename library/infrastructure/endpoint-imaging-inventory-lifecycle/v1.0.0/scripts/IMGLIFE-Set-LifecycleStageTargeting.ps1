<#
.SYNOPSIS
    IMGLIFE-Set-LifecycleStageTargeting.ps1 - build the lifecycle-stage targeting groups.
.DESCRIPTION
    PURPOSE
        Creates the Entra ID security groups used to target each stage of the device lifecycle, using
        the solution naming convention, and optionally stages initial members in the Deployed group.
        These groups are then used for policy targeting and lifecycle reporting as devices move from
        procured to deployed to refresh-due to retired.
        Default object names (created if missing):
          Device Lifecycle - Procurement - Procured
          Device Lifecycle - Fleet - Deployed
          Device Lifecycle - Aging - Refresh-Due
          Device Lifecycle - End-of-Life - Retire
    HOW TO RUN
        Create all four groups (idempotent - reuses any that already exist):
          powershell -ExecutionPolicy Bypass -File .\IMGLIFE-Set-LifecycleStageTargeting.ps1
        Create and add members to the Deployed group:
          ... -DeployedMemberIds @('<entra-object-id-1>','<entra-object-id-2>')
        Requires the Microsoft Graph PowerShell SDK and consent for Group.ReadWrite.All (delegated).
    EXPECTED RESULTS
        The four lifecycle groups exist (created or found) and any supplied Deployed members are
        added; the script prints each group's object id for use in policy assignment and reporting.
.NOTES
    Infrastructure solution - the repeatable way. Creates groups only; does not move or wipe devices.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ProcuredGroupName   = 'Device Lifecycle - Procurement - Procured',
    [string]$DeployedGroupName   = 'Device Lifecycle - Fleet - Deployed',
    [string]$RefreshDueGroupName = 'Device Lifecycle - Aging - Refresh-Due',
    [string]$RetireGroupName     = 'Device Lifecycle - End-of-Life - Retire',
    [string[]]$DeployedMemberIds = @()
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

Write-Host "`n=== Build lifecycle-stage groups ===" -ForegroundColor Cyan
$procuredId   = Get-OrNewGroup $ProcuredGroupName
$deployedId   = Get-OrNewGroup $DeployedGroupName
$refreshDueId = Get-OrNewGroup $RefreshDueGroupName
$retireId     = Get-OrNewGroup $RetireGroupName

# Stage members into the Deployed group, if provided.
foreach ($id in $DeployedMemberIds) {
    if ($deployedId -and $PSCmdlet.ShouldProcess("$id -> $DeployedGroupName", "Add member to group")) {
        try {
            $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$id" } | ConvertTo-Json
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$deployedId/members/`$ref" -Body $ref -ContentType 'application/json'
            Write-Host "  Added $id to '$DeployedGroupName'." -ForegroundColor Green
        } catch {
            Write-Host "  Could not add $id (already a member?): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nLifecycle groups ready:" -ForegroundColor Green
Write-Host ("  Procured    : {0}  ->  {1}" -f $ProcuredGroupName, $procuredId)
Write-Host ("  Deployed    : {0}  ->  {1}" -f $DeployedGroupName, $deployedId)
Write-Host ("  Refresh-Due : {0}  ->  {1}" -f $RefreshDueGroupName, $refreshDueId)
Write-Host ("  Retire      : {0}  ->  {1}" -f $RetireGroupName, $retireId)
Write-Host "Use these group ids for policy targeting and lifecycle reporting." -ForegroundColor Green

Disconnect-MgGraph | Out-Null
