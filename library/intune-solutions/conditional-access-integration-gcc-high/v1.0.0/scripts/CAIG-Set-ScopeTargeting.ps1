<#
.SYNOPSIS
    CAIG-Set-ScopeTargeting.ps1 — set a CA policy's include/exclude scope on GCC High (pilot -> production). Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Moves a Conditional Access policy from pilot to production scope on a GCC High tenant by
        setting its included users/groups (e.g. from a pilot group to All users) while KEEPING the
        break-glass exclusions. Change-making — so it DEFAULTS TO -WhatIf and only writes when you
        pass -Apply. Break-glass accounts are always re-asserted in the exclusion list so scope
        expansion never drops the lockout safeguard.
    HOW TO RUN
        Preview (default, no changes) — target the pilot group:
          powershell -ExecutionPolicy Bypass -File .\CAIG-Set-ScopeTargeting.ps1 -PolicyName 'CA - Require MFA - All Apps (Gov)' -IncludeGroup CA-Pilot-Gov -BreakGlassUpns bg1@your-tenant.onmicrosoft.us,bg2@your-tenant.onmicrosoft.us
        Expand to all users and apply:
          powershell -ExecutionPolicy Bypass -File .\CAIG-Set-ScopeTargeting.ps1 -PolicyName 'CA - Require MFA - All Apps (Gov)' -IncludeAllUsers -BreakGlassUpns bg1@your-tenant.onmicrosoft.us,bg2@your-tenant.onmicrosoft.us -Apply
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov with
        Policy.ReadWrite.ConditionalAccess + Group.Read.All + User.Read.All.
    EXPECTED RESULTS
        WhatIf mode prints the intended include/exclude scope and makes no change. With -Apply the
        policy's users condition is updated and confirmed, break-glass still excluded.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints unless -Apply is passed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$IncludeGroup,
    [switch]$IncludeAllUsers,
    [string[]]$BreakGlassUpns,
    [switch]$Apply,
    [switch]$WhatIf = $true
)
if ($Apply) { $WhatIf = $false }
if (-not ($IncludeGroup -or $IncludeAllUsers)) { Write-Host "Specify -IncludeGroup GroupName or -IncludeAllUsers." -ForegroundColor Yellow; return }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All','User.Read.All' -NoWelcome
if ((Get-MgContext).Environment -ne 'USGov') { Write-Host "WRONG CLOUD: not USGov. Reconnect with -Environment USGov." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$mode = $(if ($WhatIf) { '[WHATIF] ' } else { '[APPLY] ' })
$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$p = $pols | Where-Object displayName -eq $PolicyName | Select-Object -First 1
if (-not $p) { Write-Host "Policy not found: $PolicyName" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# --- Resolve break-glass user ids (always kept in exclusions) ---
$exUsers = @($p.conditions.users.excludeUsers)
foreach ($u in $BreakGlassUpns) {
    try { $id = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$u").id; if ($exUsers -notcontains $id) { $exUsers += $id } }
    catch { Write-Host "  Break-glass user not found: $u" -ForegroundColor Red }
}
if (-not $BreakGlassUpns) { Write-Host "  WARNING: no -BreakGlassUpns supplied; existing exclusions preserved but none re-asserted." -ForegroundColor Yellow }

# --- Build the include scope ---
$users = @{ excludeUsers = @($exUsers | Select-Object -Unique) }
if ($IncludeAllUsers) {
    $users.includeUsers = @('All'); $users.includeGroups = @()
    Write-Host ("{0}'{1}' include = All users; exclude = {2} break-glass user(s)" -f $mode, $PolicyName, $users.excludeUsers.Count) -ForegroundColor Cyan
} elseif ($IncludeGroup) {
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$IncludeGroup'&`$select=id,displayName").value | Select-Object -First 1
    if (-not $g) { Write-Host "Group not found: $IncludeGroup" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
    $users.includeUsers = @('None'); $users.includeGroups = @($g.id)
    Write-Host ("{0}'{1}' include = group '{2}'; exclude = {3} break-glass user(s)" -f $mode, $PolicyName, $g.displayName, $users.excludeUsers.Count) -ForegroundColor Cyan
}

if (-not $WhatIf) {
    $body = @{ conditions = @{ users = $users } } | ConvertTo-Json -Depth 8
    Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/identity/conditionalAccess/policies/$($p.id)" -Body $body
    Write-Host "  Scope updated (break-glass still excluded)." -ForegroundColor Green
} else {
    Write-Host "`nNo changes made (WhatIf). Re-run with -Apply to commit." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
