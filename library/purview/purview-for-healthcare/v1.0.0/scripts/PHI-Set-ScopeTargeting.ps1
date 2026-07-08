<#
.SYNOPSIS
    PHI-Set-ScopeTargeting.ps1 — build the PHI pilot / care-team scope Entra security groups (-WhatIf aware).
.DESCRIPTION
    PURPOSE
        Creates (or updates) the Microsoft Entra security group this Healthcare solution targets its
        PHI labels, DLP, and retention at — the pilot scope 'Purview - PHI Pilot Users' (and,
        optionally, a narrower care-team / role group for the PHI-restricted label per the
        minimum-necessary principle) — and adds the supplied members. Use it to stand up Requirement
        2.5 before publishing any policy, and to widen scope during Expand.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser
        Preview:  powershell -ExecutionPolicy Bypass -File .\PHI-Set-ScopeTargeting.ps1 -Members user1@contoso.com,user2@contoso.com -WhatIf
        Apply:    powershell -ExecutionPolicy Bypass -File .\PHI-Set-ScopeTargeting.ps1 -Members user1@contoso.com,user2@contoso.com
        Sign in with rights to create groups (Groups Administrator) when prompted.
.EXAMPLE
    .\PHI-Set-ScopeTargeting.ps1 -GroupName 'Purview - PHI Pilot Users' -Members clinician1@contoso.com -WhatIf
    Previews creating the pilot group and adding the member without changing anything. Remove -WhatIf
    to apply. PowerShell 5.1+/7+; uses Microsoft Graph (Connect-MgGraph).
.NOTES
    Expected results: the group exists (created if missing) and the named members are added; -WhatIf
    previews without changing anything. White-label — no credentials in code.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param(
    [string]$GroupName = 'Purview - PHI Pilot Users',
    [string[]]$Members = @()
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Users  -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome

Write-Host ("`n=== Purview for Healthcare — scope targeting — group '{0}' ===" -f $GroupName) -ForegroundColor Cyan

# Find or create the security group
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) {
    if ($PSCmdlet.ShouldProcess($GroupName, 'Create security group')) {
        $mailNick = ($GroupName -replace '[^A-Za-z0-9]', '')
        $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false -MailNickname $mailNick `
                    -SecurityEnabled:$true -Description 'Microsoft Purview PHI pilot / care-team scope'
        Write-Host ("  Created group '{0}' (id {1})." -f $GroupName, $group.Id) -ForegroundColor Green
    } else { Write-Host ("  WOULD create group '{0}'." -f $GroupName) -ForegroundColor Yellow }
} else { Write-Host ("  Group '{0}' already exists (id {1})." -f $GroupName, $group.Id) -ForegroundColor Green }

# Add members
foreach ($m in $Members) {
    $user = Get-MgUser -Filter "userPrincipalName eq '$m'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $user) { Write-Host ("  User not found: {0}" -f $m) -ForegroundColor Yellow; continue }
    if ($group -and $PSCmdlet.ShouldProcess($m, "Add to $GroupName")) {
        try {
            New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)" } -ErrorAction Stop
            Write-Host ("  Added {0}." -f $m) -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match 'already exist') { Write-Host ("  {0} already a member." -f $m) -ForegroundColor Green }
            else { Write-Host ("  Could not add {0}: {1}" -f $m, $_.Exception.Message) -ForegroundColor Yellow }
        }
    } elseif (-not $group) { Write-Host ("  WOULD add {0} once the group exists." -f $m) -ForegroundColor Yellow }
}

Write-Host "`nScope targeting complete. Assign PHI policies to this group in the Purview portal." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
