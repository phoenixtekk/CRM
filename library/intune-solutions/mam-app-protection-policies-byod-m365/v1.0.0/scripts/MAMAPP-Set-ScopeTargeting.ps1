<#
.SYNOPSIS
    MAMAPP-Set-ScopeTargeting.ps1 — create/verify the BYOD MAM scope groups and preview membership.
.DESCRIPTION
    PURPOSE
        Ensures the two Entra security groups this solution assigns policies to exist:
        "MAM Users - BYOD - Pilot" and "MAM Users - BYOD - Production". Optionally adds a supplied list
        of user principal names to the pilot group. SAFE BY DEFAULT (-WhatIf); only writes with -Execute.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\MAMAPP-Set-ScopeTargeting.ps1
        Add pilot users:    powershell ... -File .\MAMAPP-Set-ScopeTargeting.ps1 -PilotUsers user1@contoso.com,user2@contoso.com -Execute
        Requires the Microsoft Graph SDK and scopes Group.ReadWrite.All and User.Read.All.
    EXPECTED RESULTS
        Confirms (or, with -Execute, creates) both scope groups and reports their object IDs; with
        -PilotUsers, previews or performs the pilot-group membership additions.
.NOTES
    Intune Solutions — MAM App Protection Policies for BYOD. Write actions gated behind -Execute.
#>
[CmdletBinding()] param(
    [string]$PilotGroupName = 'MAM Users - BYOD - Pilot',
    [string]$ProductionGroupName = 'MAM Users - BYOD - Production',
    [string[]]$PilotUsers,
    [switch]$Execute
)
$WhatIf = -not $Execute
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

function Get-OrCreateGroup([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  Group exists: {0}  [{1}]" -f $name, $g.id) -ForegroundColor Green; return $g.id }
    if ($WhatIf) { Write-Host ("  [WhatIf] Would create security group: {0}" -f $name) -ForegroundColor Cyan; return $null }
    $mailNick = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true } | ConvertTo-Json
    $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
    Write-Host ("  Created group: {0}  [{1}]" -f $name, $new.id) -ForegroundColor Green; return $new.id
}

Write-Host "=== Scope groups ===" -ForegroundColor Cyan
$pilotId = Get-OrCreateGroup $PilotGroupName
$prodId  = Get-OrCreateGroup $ProductionGroupName

if ($PilotUsers) {
    Write-Host "=== Pilot membership ===" -ForegroundColor Cyan
    foreach ($upn in $PilotUsers) {
        $u = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn" -ErrorAction SilentlyContinue)
        if (-not $u) { Write-Host ("  User not found: {0}" -f $upn) -ForegroundColor Yellow; continue }
        if ($WhatIf -or -not $pilotId) { Write-Host ("  [WhatIf] Would add {0} to {1}" -f $upn, $PilotGroupName) -ForegroundColor Cyan; continue }
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
        try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body $ref -ContentType 'application/json' | Out-Null; Write-Host ("  Added {0}" -f $upn) -ForegroundColor Green }
        catch { Write-Host ("  Could not add {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
    }
}
if ($WhatIf) { Write-Host "`nPreview only. Re-run with -Execute to apply." -ForegroundColor Cyan }
Disconnect-MgGraph | Out-Null
