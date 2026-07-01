<#
.SYNOPSIS
    SPMAM-Set-ScopeTargeting.ps1 — build/maintain the SharePoint Online mobile-access scope groups
    and add users to them (Microsoft Graph). Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Creates the pilot/prod scope groups used to assign the App Protection Policies and the
        Conditional Access policy, and adds the supplied users to the chosen group — the repeatable
        way to control who is in scope for mobile access. PREVIEWS by default (-WhatIf); pass
        -WhatIf:$false to apply.
    HOW TO RUN
        Preview: powershell -ExecutionPolicy Bypass -File .\SPMAM-Set-ScopeTargeting.ps1 -Stage Pilot -Users user1@contoso.com,user2@contoso.com
        Apply  : powershell -ExecutionPolicy Bypass -File .\SPMAM-Set-ScopeTargeting.ps1 -Stage Prod -Users user@contoso.com -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK. Consented scopes:
        Group.ReadWrite.All, User.Read.All.
    EXPECTED RESULTS
        The scope group (SPO Mobile - Users - Pilot / - Prod) is created if missing, and each supplied
        user is added (idempotent — skips users already members). With -WhatIf it only prints intent.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Writes only when -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [ValidateSet('Pilot','Prod')][string]$Stage = 'Pilot',
    [string[]]$Users = @()
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

$groupName = "SPO Mobile – Users – $Stage"
$mailNick  = "spo-mobile-users-$($Stage.ToLower())"

# Find or create the group
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$groupName'&`$select=id,displayName").value | Select-Object -First 1
if (-not $grp) {
    if ($PSCmdlet.ShouldProcess($groupName, 'Create security group')) {
        $body = @{ displayName=$groupName; mailEnabled=$false; mailNickname=$mailNick; securityEnabled=$true; description='SharePoint Online mobile access scope (Phoenixtekk SPMAM)' } | ConvertTo-Json
        $grp = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body $body -ContentType 'application/json'
        Write-Host ("  CREATED group: {0}" -f $groupName) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would create group {0}" -f $groupName) -ForegroundColor Cyan
    }
} else {
    Write-Host ("  OK: group exists — {0}" -f $groupName) -ForegroundColor Green
}

# Add users
foreach ($upn in $Users) {
    try { $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn`?`$select=id,userPrincipalName" }
    catch { Write-Host ("  SKIP: user not found — {0}" -f $upn) -ForegroundColor Yellow; continue }

    $isMember = $false
    if ($grp -and $grp.id) {
        try { $isMember = [bool]((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value | Where-Object { $_.id -eq $u.id }) } catch {}
    }
    if ($isMember) { Write-Host ("  OK: {0} already in {1}" -f $upn, $groupName) -ForegroundColor Green; continue }

    if ($PSCmdlet.ShouldProcess($upn, "Add to $groupName")) {
        if (-not ($grp -and $grp.id)) { Write-Host ("  WHATIF: group not yet created — would add {0} after creation" -f $upn) -ForegroundColor Cyan; continue }
        $ref = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($u.id)" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body $ref -ContentType 'application/json'
        Write-Host ("  ADDED: {0} -> {1}" -f $upn, $groupName) -ForegroundColor Green
    } else {
        Write-Host ("  WHATIF: would add {0} -> {1}" -f $upn, $groupName) -ForegroundColor Cyan
    }
}

Write-Host "`nAssign this group to the App Protection Policies and the CA policy (see 03-implementation)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
