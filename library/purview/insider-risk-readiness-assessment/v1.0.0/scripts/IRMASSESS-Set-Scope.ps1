<#
.SYNOPSIS
    IRMASSESS-Set-Scope.ps1 — IRM readiness scope/health helper: report and (with -Commit) adjust the backing scope-group membership (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports the membership of the backing Entra security group that a Purview Insider Risk Management
        PRIORITY USER GROUP is bound to (the readiness scope), and — only with -Commit — ADD or REMOVE a
        single member so the readiness scope stays minimal. Safe by default: -WhatIf reports only; writes
        require -Commit. This helper adjusts SCOPE MEMBERSHIP only — it does NOT bind the priority-user group,
        does NOT create/enable an IRM policy, and never enables enforcement (those are portal-only steps;
        verify in the Purview portal). Keep the readiness scope test-accounts-only until HR/privacy/legal
        approve deployment.
    HOW TO RUN
        # Report current readiness-scope membership:
        powershell -File .\IRMASSESS-Set-Scope.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -WhatIf
        # Add a test account to the readiness scope:
        powershell -File .\IRMASSESS-Set-Scope.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' `
            -AddMember 'pilotuser@contoso.com' -Commit
        Requires Microsoft Graph (Connect-MgGraph -Scopes Group.ReadWrite.All,User.Read.All).
.EXAMPLE
    .\IRMASSESS-Set-Scope.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -WhatIf
    Prints the backing group's member count/list and the membership change it WOULD make.
.NOTES
    Purview — Insider Risk Readiness Assessment. Membership changes gated behind -Commit; never enables a policy.
    No credentials in code. Expected results: -Commit adjusts scope membership only; no IRM policy is touched (PASS).
#>
[CmdletBinding()]
param(
    [string]$ScopeGroupName = 'IRM Priority Users - Readiness - Scope',
    [string]$AddMember,
    [string]$RemoveMember,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Install-Module Microsoft.Graph.Groups -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue
$ctx = $null
try { $ctx = Get-MgContext } catch {}
if (-not $ctx) { Connect-MgGraph -Scopes 'Group.ReadWrite.All','User.Read.All' -NoWelcome }

$grp = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
if (-not $grp) {
    Write-Host ("Backing scope group '{0}' not found. Create it first: IRMASSESS-Config.ps1 -Commit" -f $ScopeGroupName) -ForegroundColor Yellow
    return
}

Write-Host ("=== Readiness scope '{0}' (Id={1}) ===" -f $grp.DisplayName, $grp.Id) -ForegroundColor Cyan
$members = @()
try { $members = @(Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue) } catch {}
Write-Host ("Current member count: {0} (keep minimal — readiness scope should be test-accounts-only)" -f $members.Count)
foreach ($m in $members) {
    $disp = $m.AdditionalProperties['userPrincipalName']
    if (-not $disp) { $disp = $m.AdditionalProperties['displayName'] }
    if (-not $disp) { $disp = $m.Id }
    Write-Host ("  - {0}" -f $disp) -ForegroundColor DarkCyan
}

if (-not $AddMember -and -not $RemoveMember) {
    Write-Host 'No -AddMember / -RemoveMember supplied — reporting only. Supply one (and -Commit) to adjust the scope.' -ForegroundColor Yellow
    return
}

# Resolve the target user id for the requested change.
$targetUpn = if ($AddMember) { $AddMember } else { $RemoveMember }
$user = $null
try { $user = Get-MgUser -UserId $targetUpn -ErrorAction Stop } catch {}
if (-not $user) {
    Write-Host ("Could not resolve user '{0}' in the directory — check the UPN." -f $targetUpn) -ForegroundColor Yellow
    return
}

$action = if ($AddMember) { 'ADD' } else { 'REMOVE' }
if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    if ($AddMember) { Write-Host ("New-MgGroupMember -GroupId {0} -DirectoryObjectId {1}   ({2} {3})" -f $grp.Id, $user.Id, $action, $targetUpn) }
    else { Write-Host ("Remove-MgGroupMemberByRef -GroupId {0} -DirectoryObjectId {1}   ({2} {3})" -f $grp.Id, $user.Id, $action, $targetUpn) }
    Write-Host 'Re-run with -Commit to apply. No IRM policy is bound or enabled from here (that is a portal/change-control step).' -ForegroundColor Yellow
    return
}

# --- Commit path: membership change only ---
if ($AddMember) {
    New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $user.Id -ErrorAction Stop
    Write-Host ("Added {0} to readiness scope '{1}'." -f $targetUpn, $ScopeGroupName) -ForegroundColor Green
} else {
    Remove-MgGroupMemberByRef -GroupId $grp.Id -DirectoryObjectId $user.Id -ErrorAction Stop
    Write-Host ("Removed {0} from readiness scope '{1}'." -f $targetUpn, $ScopeGroupName) -ForegroundColor Green
}

$after = @(Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue).Count
Write-Host ("PASS: scope membership adjusted (now {0} member(s)). No IRM policy touched; binding/enablement remain portal steps." -f $after) -ForegroundColor Green
