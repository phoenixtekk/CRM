<#
.SYNOPSIS
    NSSSL-Set-ScopeTargeting.ps1 — build/populate the pilot + production scope groups (Graph).
.DESCRIPTION
    PURPOSE
        Ensures the Entra security groups used to scope SSL inspection exist and, optionally, adds
        members to the pilot group — so certificate trust and the decryption policy can be assigned
        to a controlled scope first. This script manages GROUPS only; the Netskope decryption policy
        and bypass list are configured in the Netskope console (deferred).
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\NSSSL-Set-ScopeTargeting.ps1
        Create groups + add pilot members:
          powershell -ExecutionPolicy Bypass -File .\NSSSL-Set-ScopeTargeting.ps1 -Execute -PilotMemberUpns user1@contoso.com,user2@contoso.com
        Requires Microsoft Graph SDK and Group.ReadWrite.All + User.Read.All.
    EXPECTED RESULTS
        In preview: prints whether each group exists and what would be created/added. With -Execute:
        creates any missing group and adds the supplied UPNs to the pilot group.
.NOTES
    Workplace Marketplace — Network Solutions. Default preview (no changes without -Execute).
#>
[CmdletBinding()] param(
    [string]$PilotGroupName      = 'SSL Inspection – Pilot Users – Pilot',
    [string]$ProductionGroupName = 'SSL Inspection – All Users – Production',
    [string[]]$PilotMemberUpns   = @(),
    [switch]$Execute
)
$WhatIf = -not $Execute
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome
Write-Host ("Mode: {0}" -f ($(if($WhatIf){'PREVIEW (pass -Execute to apply)'}else{'EXECUTE'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Green'}))

function Get-OrShow-Group([string]$name) {
    $f = [uri]::EscapeDataString("displayName eq '$name'")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value | Select-Object -First 1
    if ($g) { Write-Host ("Group exists : {0}  (id {1})" -f $name, $g.id) -ForegroundColor Green; return $g }
    if ($WhatIf) { Write-Host ("WOULD CREATE : security group '{0}'" -f $name) -ForegroundColor Yellow; return $null }
    $mailNick = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true } | ConvertTo-Json
    $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
    Write-Host ("Created group: {0}  (id {1})" -f $name, $g.id) -ForegroundColor Green
    return $g
}

$pilot = Get-OrShow-Group $PilotGroupName
$null  = Get-OrShow-Group $ProductionGroupName

foreach ($upn in $PilotMemberUpns) {
    $u = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/users/{0}" -f [uri]::EscapeDataString($upn)) -ErrorAction SilentlyContinue)
    if (-not $u) { Write-Host ("  User not found: {0}" -f $upn) -ForegroundColor Yellow; continue }
    if ($WhatIf -or -not $pilot) { Write-Host ("  WOULD ADD to pilot: {0}" -f $upn) -ForegroundColor Yellow; continue }
    $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
    try { Invoke-MgGraphRequest -Method POST -Uri ("/v1.0/groups/{0}/members/`$ref" -f $pilot.id) -Body $ref -ContentType 'application/json'; Write-Host ("  Added to pilot: {0}" -f $upn) -ForegroundColor Green }
    catch { Write-Host ("  Add skipped ({0}): {1}" -f $upn, $_.Exception.Message) -ForegroundColor Yellow }
}
Write-Host "`nNote: assign the trusted-cert profile and decryption policy to these groups per the Implementation Guide." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
