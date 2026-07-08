<#
.SYNOPSIS
    PURVIRM-Set-Scope.ps1 — stage IRM pilot/scope-group membership for deliberate expansion (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Manages membership of the IRM pilot/scope group (SG-IRM-Pilot by default) so you can expand an
        Insider Risk Management rollout from pilot to production a batch at a time, and reversibly.
        Because policies are scoped to this group, growing the group expands detection scope without
        editing each policy. It DEFAULTS TO -WhatIf (preview only) and changes nothing until you re-run
        with -WhatIf:$false. It only ADDS the members you pass and never retargets policies directly, so
        expansion stays deliberate. Scoping people into IRM is privacy-sensitive — do it only within the
        HR/legal-agreed scope.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\PURVIRM-Set-Scope.ps1 -AddMembers user1@contoso.com,user2@contoso.com
        Apply (after review + change approval + HR/legal-agreed scope):
          powershell -ExecutionPolicy Bypass -File .\PURVIRM-Set-Scope.ps1 -AddMembers user1@contoso.com -WhatIf:$false

        Required Graph scopes (delegated): Group.ReadWrite.All, User.Read.All, Directory.Read.All.
        Connects with Connect-MgGraph. Pass user principal names or object ids (no angle brackets).
    EXPECTED RESULTS
        In preview: the members that WOULD be added, with no change. With -WhatIf:$false: the members are
        added and a summary lists the new count. PASS = the operation previews/applies without error.
        FAIL = the group is missing or a member cannot be resolved (named in the output).
.NOTES
    White-label. Change tool — defaults to -WhatIf. Microsoft Graph. No credentials in code. Scope only within HR/legal agreement.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $ScopeGroupName = 'SG-IRM-Pilot',
    [string[]] $AddMembers     = @(),
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]   $GraphEnvironment = 'Global'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Group.ReadWrite.All','User.Read.All','Directory.Read.All') | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    Write-Host ("Tenant      : {0}" -f $ctx.TenantId)
    if ($WhatIfPreference) { Write-Host 'MODE: PREVIEW (-WhatIf) — no changes will be made.' -ForegroundColor Yellow }
    else                   { Write-Host 'MODE: APPLY — membership WILL change.' -ForegroundColor Red }
}
catch {
    Write-Error ("Graph connect failed: {0}" -f $_.Exception.Message)
    return
}

Write-Section ("Resolving scope group '{0}'" -f $ScopeGroupName)
$grp = $null
try {
    $grp = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -All
}
catch {
    Write-Error ("Could not query the scope group: {0}" -f $_.Exception.Message)
    return
}
if (-not $grp) {
    Write-Error ("Scope group '{0}' not found. Create it (Entra -> Groups) and scope the IRM policies to it first." -f $ScopeGroupName)
    return
}
$groupId = $grp[0].Id
Write-Host ("Found group (Id {0})." -f $groupId) -ForegroundColor Green

if ($AddMembers.Count -eq 0) {
    Write-Host 'No -AddMembers supplied; nothing to stage. Re-run with -AddMembers to add pilot/expansion users.'
    return
}

Write-Section 'Staging members'
$added = 0
foreach ($m in $AddMembers) {
    $user = $null
    try {
        if ($m -match '@') { $user = Get-MgUser -Filter "userPrincipalName eq '$m'" -All | Select-Object -First 1 }
        else               { $user = Get-MgUser -UserId $m -ErrorAction Stop }
    }
    catch {}
    if (-not $user) { Write-Warning ("Could not resolve member '{0}' — skipped." -f $m); continue }

    if ($PSCmdlet.ShouldProcess($ScopeGroupName, ("Add member {0}" -f $user.UserPrincipalName))) {
        try {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id -ErrorAction Stop
            Write-Host ("Added {0}" -f $user.UserPrincipalName) -ForegroundColor Green
            $added++
        }
        catch {
            if ("$($_.Exception.Message)" -match 'already exist') { Write-Host ("Already a member: {0}" -f $user.UserPrincipalName) }
            else { Write-Warning ("Failed to add {0}: {1}" -f $user.UserPrincipalName, $_.Exception.Message) }
        }
    } else {
        Write-Host ("WOULD add {0}" -f $user.UserPrincipalName) -ForegroundColor Yellow
    }
}

Write-Section 'Result'
if ($WhatIfPreference) {
    Write-Host 'Preview complete — no changes made. Re-run with -WhatIf:$false to apply (within HR/legal-agreed scope).'
} else {
    $count = @(Get-MgGroupMember -GroupId $groupId -All).Count
    Write-Host ("Applied. Members added this run: {0}. Group '{1}' now has {2} member(s)." -f $added, $ScopeGroupName, $count) -ForegroundColor Green
    Write-Host 'Re-run the testing gates (05-testing.md) after each expansion. Keep anonymization ON and role separation intact.'
}
