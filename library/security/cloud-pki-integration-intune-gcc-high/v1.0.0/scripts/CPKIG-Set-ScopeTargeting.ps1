<#
.SYNOPSIS
    CPKIG-Set-ScopeTargeting.ps1 — build/adjust the certificate pilot-scope group for staged expansion (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Manages membership of the certificate scope group (SG-CPKI-Pilot by default) so you can stage
        a certificate rollout from pilot to production a batch at a time. It adds the users or devices
        you pass in AddMembers to the scope group. It DEFAULTS TO -WhatIf (preview only) and changes
        nothing until you re-run with -WhatIf:$false. It does not remove members and does not retarget
        profiles directly — expansion stays deliberate and reversible. Pass member object ids or user
        principal names such as pilot-user@your-agency.gov (no angle brackets).
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\CPKIG-Set-ScopeTargeting.ps1 -AddMembers user1@your-agency.gov,user2@your-agency.gov
        Apply (after review + change approval):
          powershell -ExecutionPolicy Bypass -File .\CPKIG-Set-ScopeTargeting.ps1 -AddMembers user1@your-agency.gov -WhatIf:$false

        Required Graph scopes (delegated): Group.ReadWrite.All, User.Read.All, Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). Because the
        certificate / Wi-Fi / VPN profiles target this group, growing the group expands certificate
        scope without editing each profile. For DoD change USGov to USGovDoD.
    EXPECTED RESULTS
        In preview: the members that WOULD be added, with no change. With -WhatIf:$false: the members
        are added and a summary lists the new count. PASS = the operation previews/applies without
        error. FAIL = wrong cloud, group missing, or a member cannot be resolved (named in the output).
.NOTES
    White-label — the repeatable way. Change tool — defaults to -WhatIf. US Gov Graph endpoints for GCC High.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $ScopeGroupName   = 'SG-CPKI-Pilot',
    [string[]] $AddMembers       = @(),
    [ValidateSet('USGov','USGovDoD')]
    [string]   $GraphEnvironment = 'USGov'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'

try {
    Connect-MgGraph -Environment $GraphEnvironment -Scopes @('Group.ReadWrite.All','User.Read.All','Directory.Read.All') | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Environment : {0}" -f $ctx.Environment)
    if ($ctx.Environment -notin @('USGov','USGovDoD')) {
        Write-Error 'Not connected to a US Gov cloud (GCC High). Aborting. Reconnect with -Environment USGov.'
        return
    }
    if ($WhatIfPreference) { Write-Host 'MODE: PREVIEW (-WhatIf) — no changes will be made.' -ForegroundColor Yellow }
    else                   { Write-Host 'MODE: APPLY — changes WILL be made.' -ForegroundColor Red }
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

# Resolve the scope group.
$grp = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -All -ErrorAction SilentlyContinue
if (-not $grp) {
    Write-Error ("Scope group '{0}' not found. Create it first (see CPKIG-Remediation.ps1 or entra.microsoft.us)." -f $ScopeGroupName)
    return
}
$groupId = $grp[0].Id
Write-Host ("Scope group '{0}' (Id {1})." -f $ScopeGroupName, $groupId) -ForegroundColor Green

if ($AddMembers.Count -eq 0) {
    Write-Host 'No -AddMembers supplied. Nothing to add. Pass user principal names or object ids.' -ForegroundColor Yellow
    return
}

$added = 0
foreach ($m in $AddMembers) {
    $memberId = $null
    try {
        if ($m -match '@') {
            $u = Get-MgUser -Filter "userPrincipalName eq '$m'" -ErrorAction Stop
            if ($u) { $memberId = $u.Id }
        } else {
            $memberId = $m  # treat as an object id
        }
    }
    catch {
        Write-Warning ("Could not resolve member '{0}': {1}" -f $m, $_.Exception.Message)
        continue
    }
    if (-not $memberId) { Write-Warning ("Member '{0}' not found." -f $m); continue }

    if ($PSCmdlet.ShouldProcess($m, ("Add to group '{0}'" -f $ScopeGroupName))) {
        try {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $memberId -ErrorAction Stop
            Write-Host ("Added '{0}'." -f $m) -ForegroundColor Green
            $added++
        }
        catch {
            Write-Warning ("Failed to add '{0}': {1}" -f $m, $_.Exception.Message)
        }
    }
    else {
        Write-Host ("WOULD add '{0}' to '{1}'." -f $m, $ScopeGroupName) -ForegroundColor Yellow
    }
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host ("PREVIEW complete — {0} member(s) would be added. Re-run with -WhatIf:`$false to apply." -f $AddMembers.Count) -ForegroundColor Yellow
} else {
    Write-Host ("Done — {0} member(s) added to '{1}'." -f $added, $ScopeGroupName) -ForegroundColor Green
}
