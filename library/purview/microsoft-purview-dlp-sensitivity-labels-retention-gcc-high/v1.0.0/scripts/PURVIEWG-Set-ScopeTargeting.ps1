<#
.SYNOPSIS
    PURVIEWG-Set-ScopeTargeting.ps1 — build/adjust the Purview protection-scope group for staged expansion (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Manages membership of the protection-scope group (SG-Purview-Pilot by default) so you can
        stage a Purview rollout from pilot to production a batch at a time. It adds the users or
        groups you pass in AddMembers to the scope group. It DEFAULTS TO -WhatIf (preview only) and
        changes nothing until you re-run with -WhatIf:$false. It does not remove members and does not
        retarget policies directly — expansion stays deliberate and reversible. Pass member object ids
        or user principal names such as pilot-user@your-agency.gov (no angle brackets).
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Set-ScopeTargeting.ps1 -AddMembers user1@your-agency.gov,user2@your-agency.gov
        Apply (after review + change approval):
          powershell -ExecutionPolicy Bypass -File .\PURVIEWG-Set-ScopeTargeting.ps1 -AddMembers user1@your-agency.gov -WhatIf:$false

        Required Graph scopes (delegated): Group.ReadWrite.All, User.Read.All, Directory.Read.All.
        GCC High: connects with Connect-MgGraph -Environment USGov (graph.microsoft.us). Because the
        label/DLP/retention policies target this group, growing the group expands protection scope
        without editing each policy. For DoD change USGov to USGovDoD.
    EXPECTED RESULTS
        In preview: the members that WOULD be added, with no change. With -WhatIf:$false: the members
        are added and a summary lists the new count. PASS = the operation previews/applies without
        error. FAIL = wrong cloud, group missing, or a member cannot be resolved (named in the output).
.NOTES
    White-label — the repeatable way. Change tool — defaults to -WhatIf. US Gov Graph endpoints for GCC High.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]   $ScopeGroupName   = 'SG-Purview-Pilot',
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
    else                   { Write-Host 'MODE: APPLY — membership WILL change.' -ForegroundColor Red }
}
catch {
    Write-Error ("Graph connect (US Gov) failed: {0}" -f $_.Exception.Message)
    return
}

# Resolve the scope group
$grp = Get-MgGroup -Filter "displayName eq '$ScopeGroupName'" -ConsistencyLevel eventual -CountVariable c -All -ErrorAction SilentlyContinue
if (-not $grp) {
    Write-Error ("Scope group '{0}' not found. Create it first (PURVIEWG-Remediation.ps1 or entra.microsoft.us)." -f $ScopeGroupName)
    return
}
$groupId = $grp[0].Id
Write-Host ("Scope group '{0}' (Id {1})." -f $ScopeGroupName, $groupId)

$existing = @()
try { $existing = (Get-MgGroupMember -GroupId $groupId -All).Id } catch {}
Write-Host ("Current member count: {0}" -f $existing.Count)

if (-not $AddMembers -or $AddMembers.Count -eq 0) {
    Write-Host ''
    Write-Host 'No -AddMembers supplied. Nothing to stage. Pass user principal names or object ids to expand scope.' -ForegroundColor Yellow
    return
}

$added = 0; $skipped = 0; $failed = 0
foreach ($m in $AddMembers) {
    $user = $null
    try {
        if ($m -match '@') { $user = Get-MgUser -UserId $m -ErrorAction Stop }
        else               { $user = Get-MgUser -UserId $m -ErrorAction Stop }
    }
    catch {
        Write-Warning ("Could not resolve member '{0}': {1}" -f $m, $_.Exception.Message)
        $failed++; continue
    }

    if ($existing -contains $user.Id) {
        Write-Host ("  already a member: {0}" -f $m) -ForegroundColor DarkGray
        $skipped++; continue
    }

    if ($PSCmdlet.ShouldProcess($m, "Add to $ScopeGroupName")) {
        try {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id -ErrorAction Stop
            Write-Host ("  added: {0}" -f $m) -ForegroundColor Green
            $added++
        }
        catch {
            Write-Warning ("Failed to add '{0}': {1}" -f $m, $_.Exception.Message)
            $failed++
        }
    }
    else {
        Write-Host ("  WOULD add: {0}" -f $m) -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host ("Summary — added {0}, already-member {1}, failed {2}." -f $added, $skipped, $failed)
if ($WhatIfPreference) { Write-Host 'PREVIEW complete — re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else                   { Write-Host 'Scope targeting update complete.' -ForegroundColor Green }
Write-Host 'Because labels/DLP/retention target this group, expanding it expands protection scope.'
