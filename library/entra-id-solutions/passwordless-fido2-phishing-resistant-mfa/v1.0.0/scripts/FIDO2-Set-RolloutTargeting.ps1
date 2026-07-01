<#
.SYNOPSIS
    FIDO2-Set-RolloutTargeting.ps1 — build the pilot and rollout Entra groups for staged targeting.
.DESCRIPTION
    PURPOSE
        Creates (if missing) the security groups used to scope the authentication-method policy, the
        registration campaign, and the Conditional Access authentication strength, following the
        <Purpose> - <Scope> - <Stage> naming convention. Optionally seeds the pilot group from a
        list of user principal names.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\FIDO2-Set-RolloutTargeting.ps1 -PilotMembers user1@contoso.com,user2@contoso.com
        Requires Microsoft Graph SDK; Group.ReadWrite.All + GroupMember.ReadWrite.All (+ User.Read.All to resolve members).
    EXPECTED RESULTS
        The pilot and all-staff groups exist; pilot members (if supplied) are added. Object IDs printed.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Additive; does not delete groups or members.
#>
[CmdletBinding()] param([string[]]$PilotMembers)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','GroupMember.ReadWrite.All','User.Read.All' -NoWelcome
function Get-OrNewGroup($name) {
    $f = "displayName eq '$($name -replace "'","''")'"
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value | Select-Object -First 1
    if ($g) { Write-Host ("  exists : {0}  ({1})" -f $name, $g.id); return $g.id }
    $mail = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mail; securityEnabled=$true }
    $new = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body
    Write-Host ("  created: {0}  ({1})" -f $name, $new.id) -ForegroundColor Green
    return $new.id
}
Write-Host "=== Rollout targeting groups ===" -ForegroundColor Cyan
$pilotId = Get-OrNewGroup 'Phishing-Resistant - Pilot - Users'
$allId   = Get-OrNewGroup 'Phishing-Resistant - All Staff - Users'
foreach ($upn in ($PilotMembers | Where-Object { $_ })) {
    try {
        $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn"
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" }
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$pilotId/members/`$ref" -Body $ref
        Write-Host ("  pilot += {0}" -f $upn) -ForegroundColor Green
    } catch { Write-Host ("  skip {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
}
Write-Host ("`nPilot group id   : {0}" -f $pilotId)
Write-Host ("All-staff group id: {0}" -f $allId)
Disconnect-MgGraph | Out-Null
