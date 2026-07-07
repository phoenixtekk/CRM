<#
.SYNOPSIS
    TEAMSAPPS-Set-ScopeTargeting.ps1 — assign (or reset to Global) the Teams app permission + setup policies for a pilot group. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Scope/health helper for the rollout: assigns the app permission and app setup policies to each
        member of a pilot group (or an explicit UPN list) via Grant-CsTeamsAppPermissionPolicy /
        Grant-CsTeamsAppSetupPolicy, and can RESET a population back to the Global (Org-wide default)
        policies for rollback. SAFE BY DEFAULT — runs in -WhatIf mode (prints the assignments it WOULD
        make) unless -Commit is supplied.
    HOW TO RUN
        Dry-run (default, NO changes):
          .\TEAMSAPPS-Set-ScopeTargeting.ps1 -PolicyGroup 'App Governance Pilot - Users - Pilot'
        Apply:
          .\TEAMSAPPS-Set-ScopeTargeting.ps1 -PolicyGroup 'App Governance Pilot - Users - Pilot' -Commit
        Rollback a population to Global:
          .\TEAMSAPPS-Set-ScopeTargeting.ps1 -PolicyGroup 'App Governance Pilot - Users - Pilot' -Reset -Commit
        (PowerShell 5.1+/7+; MicrosoftTeams module + Microsoft Graph SDK for group expansion)
    EXPECTED RESULTS
        -WhatIf: one line per user showing the assignment (or reset) that WOULD be made; nothing
        changes. -Commit: the policies are granted (or reset to Global) for each user; a per-user result
        is printed.
.NOTES
    Teams — Microsoft Teams Apps & Integration Governance. Default mode makes NO changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyGroup,
    [string]$PermissionPolicyName = 'App Permission Policy - Pilot - Pilot',
    [string]$SetupPolicyName      = 'App Setup Policy - Standard - Prod',
    [switch]$Reset,                # assign $null (Global / Org-wide default) instead — rollback
    [switch]$Commit               # absent = -WhatIf (default, no changes)
)

$WhatIf = -not $Commit
$mode = if ($WhatIf) { 'WHATIF (no changes)' } else { 'COMMIT (applying changes)' }
$permTarget  = if ($Reset) { $null } else { $PermissionPolicyName }
$setupTarget = if ($Reset) { $null } else { $SetupPolicyName }

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) { Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module MicrosoftTeams -ErrorAction Stop
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MicrosoftTeams | Out-Null
Connect-MgGraph -Scopes 'GroupMember.Read.All','User.Read.All' -NoWelcome

Write-Host ("=== TEAMSAPPS Scope Targeting [{0}]{1} — group '{2}' ===" -f $mode, $(if($Reset){' RESET->Global'}else{''}), $PolicyGroup) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

# Resolve group members to UPNs.
$g = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f ($PolicyGroup -replace "'","''"))).value | Select-Object -First 1
if (-not $g) { Write-Warning ("Group '{0}' not found." -f $PolicyGroup); Disconnect-MgGraph | Out-Null; Disconnect-MicrosoftTeams | Out-Null; return }
$members = @()
$u = ("/v1.0/groups/{0}/members?`$select=userPrincipalName&`$top=999" -f $g.id)
do { $r = Invoke-MgGraphRequest -Method GET -Uri $u; $r.value | ForEach-Object { if ($_.userPrincipalName) { $members += $_.userPrincipalName } }; $u = $r.'@odata.nextLink' } while ($u)
if ($members.Count -eq 0) { Write-Warning 'Group has no user members — nothing to do.'; Disconnect-MgGraph | Out-Null; Disconnect-MicrosoftTeams | Out-Null; return }

foreach ($upn in $members) {
    $permDesc  = if ($Reset) { 'Global (Org-wide default)' } else { $PermissionPolicyName }
    $setupDesc = if ($Reset) { 'Global (Org-wide default)' } else { $SetupPolicyName }
    if ($WhatIf) {
        Write-Host ('WOULD assign {0}: permission="{1}", setup="{2}"' -f $upn, $permDesc, $setupDesc) -ForegroundColor Yellow
    } else {
        try {
            Grant-CsTeamsAppPermissionPolicy -Identity $upn -PolicyName $permTarget  -ErrorAction Stop
            Grant-CsTeamsAppSetupPolicy      -Identity $upn -PolicyName $setupTarget -ErrorAction Stop
            Write-Host ('OK    assigned {0}: permission="{1}", setup="{2}"' -f $upn, $permDesc, $setupDesc) -ForegroundColor Green
        } catch {
            Write-Host ('ERROR {0}: {1}' -f $upn, $_.Exception.Message) -ForegroundColor Red
        }
    }
}

Write-Host ("=== {0}: {1} user(s) processed ({2}) ===" -f $mode, $members.Count, $(if($WhatIf){'no changes made'}else{'applied'})) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
Disconnect-MicrosoftTeams | Out-Null
