<#
.SYNOPSIS
    W11HC-Set-BaselineTargeting.ps1 - create the baseline targeting device groups (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Creates the four Entra security groups the baseline assigns to, using the exact naming
        convention from the Implementation Guide, and optionally adds device object IDs to a group.
        This lets you build clinical/corporate and pilot/production targeting once, the repeatable way.
        Group creation/membership changes only run when -Confirm:$false is supplied (defaults to
        -WhatIf preview).
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\W11HC-Set-BaselineTargeting.ps1
        Create groups:     powershell -ExecutionPolicy Bypass -File .\W11HC-Set-BaselineTargeting.ps1 -Confirm:$false
        Add devices:       ... -AddToGroup 'W11 Baseline - Clinical - Pilot' -DeviceIds id1,id2 -Confirm:$false
        Requires the Microsoft Graph PowerShell SDK and the scope Group.ReadWrite.All.
    EXPECTED RESULTS
        In preview, the groups it would create. When applied, the four groups exist (idempotent), and
        any -DeviceIds are added to -AddToGroup.
.NOTES
    Healthcare Solutions - Windows 11 endpoint baseline. Defaults to -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$AddToGroup,
    [string[]]$DeviceIds
)
$PSDefaultParameterValues['*:WhatIf'] = $true
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

$groups = @(
    'W11 Baseline - Clinical - Pilot',
    'W11 Baseline - Clinical - Production',
    'W11 Baseline - Corporate - Pilot',
    'W11 Baseline - Corporate - Production'
)
function Get-GroupId([string]$name) {
    $enc = [uri]::EscapeDataString($name)
    (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$enc'").value | Select-Object -First 1 -ExpandProperty id
}
Write-Host "=== W11HC baseline targeting groups ===" -ForegroundColor Cyan
foreach ($g in $groups) {
    $id = Get-GroupId $g
    if ($id) { Write-Host ("  exists: {0}" -f $g) -ForegroundColor Green; continue }
    if ($PSCmdlet.ShouldProcess($g, "Create security group")) {
        $body = @{ displayName=$g; mailEnabled=$false; mailNickname=($g -replace '[^a-zA-Z0-9]',''); securityEnabled=$true }
        $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
        Write-Host ("  created: {0}  ({1})" -f $g, $new.id) -ForegroundColor Green
    } else { Write-Host ("  [WhatIf] would create: {0}" -f $g) -ForegroundColor Yellow }
}
if ($AddToGroup -and $DeviceIds) {
    $gid = Get-GroupId $AddToGroup
    if (-not $gid) { Write-Host "Target group '$AddToGroup' not found - create it first." -ForegroundColor Yellow }
    else {
        foreach ($d in $DeviceIds) {
            if ($PSCmdlet.ShouldProcess($d, "Add device to $AddToGroup")) {
                $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$d" }
                try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$gid/members/`$ref" -Body ($ref | ConvertTo-Json); Write-Host "  added $d" -ForegroundColor Green }
                catch { Write-Host "  skip $d : $($_.Exception.Message)" -ForegroundColor Yellow }
            } else { Write-Host "  [WhatIf] would add $d to $AddToGroup" -ForegroundColor Yellow }
        }
    }
}
Disconnect-MgGraph | Out-Null
