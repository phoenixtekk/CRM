<#
.SYNOPSIS
    ENTPIMG-Set-EligibleAssignments.ps1 — safely remove standing (active) role assignments once an
    eligible assignment exists. -WhatIf by default. Always excludes break-glass accounts.
.DESCRIPTION
    PURPOSE
        The one script that CHANGES the tenant — and it is gated. For a set of accounts (a pilot
        cohort, then batches), it finds the ACTIVE (standing) privileged directory-role assignments
        that can be removed BECAUSE the same account already holds an ELIGIBLE assignment for that
        role. It never removes an active assignment that has no matching eligible assignment, and it
        NEVER touches accounts on the break-glass exclusion list. By default it only previews
        (-WhatIf); you must pass -WhatIf:$false to apply.
    HOW TO RUN
        # 1) Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\ENTPIMG-Set-EligibleAssignments.ps1 -PrincipalUpns 'ada@contoso.com','sam@contoso.com'
        # 2) Apply to the confirmed accounts:
        powershell -ExecutionPolicy Bypass -File .\ENTPIMG-Set-EligibleAssignments.ps1 -PrincipalUpns 'ada@contoso.com' -WhatIf:$false
        Optional: -BreakGlassUpns 'bg-admin-01@contoso.onmicrosoft.com','bg-admin-02@contoso.onmicrosoft.com' (default)
        Consents to RoleManagement.ReadWrite.Directory, Directory.Read.All.
        GCC High / US Gov: Connect-MgGraph uses -Environment USGov (login.microsoftonline.us / graph.microsoft.us).
        For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us). *Verify the correct cloud for your tenant.*
    EXPECTED RESULTS
        Preview: a list of the standing assignments it WOULD remove (each with a confirmed eligible
        assignment), break-glass accounts explicitly skipped. Apply: those assignments removed; run
        ENTPIMG-Discovery.ps1 to confirm the accounts now hold the roles as eligible only.
.NOTES
    White-label — Entra ID Solutions. Change script — preview-first, break-glass-safe.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string[]]$PrincipalUpns,
    [string[]]$BreakGlassUpns = @('bg-admin-01@contoso.onmicrosoft.com','bg-admin-02@contoso.onmicrosoft.com')
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'RoleManagement.ReadWrite.Directory','Directory.Read.All' -NoWelcome

Write-Host "`n=== Convert Standing -> Eligible (preview unless -WhatIf:`$false) — $(Get-Date -Format s) ===" -ForegroundColor Cyan
Write-Host ("Break-glass accounts (never touched): {0}`n" -f ($BreakGlassUpns -join ', ')) -ForegroundColor Yellow

$roleDefs = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object { $roleDefs[$_.Id] = $_.DisplayName }

# Pre-load eligible assignments so we only remove an active one that has a matching eligible one
$eligible = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All -ErrorAction SilentlyContinue
$eligibleKey = @{}
foreach ($e in $eligible) { $eligibleKey["$($e.PrincipalId)|$($e.RoleDefinitionId)"] = $true }

$removed = 0; $skipped = 0
foreach ($upn in $PrincipalUpns) {
    if ($BreakGlassUpns -contains $upn) {
        Write-Host ("SKIP (break-glass): {0}" -f $upn) -ForegroundColor Yellow; $skipped++; continue
    }
    $user = Get-MgUser -UserId $upn -ErrorAction SilentlyContinue
    if (-not $user) { Write-Warning "User not found: $upn"; continue }

    $active = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All -Filter "principalId eq '$($user.Id)'" -ErrorAction SilentlyContinue
    foreach ($a in $active) {
        $roleName = $roleDefs[$a.RoleDefinitionId]
        $hasEligible = $eligibleKey.ContainsKey("$($a.PrincipalId)|$($a.RoleDefinitionId)")
        if (-not $hasEligible) {
            Write-Host ("SKIP (no matching eligible assignment): {0} / {1}" -f $upn,$roleName) -ForegroundColor DarkYellow
            $skipped++; continue
        }
        if ($PSCmdlet.ShouldProcess("$upn / $roleName", "Remove standing (active) assignment")) {
            $body = @{
                action           = 'adminRemove'
                principalId      = $a.PrincipalId
                roleDefinitionId = $a.RoleDefinitionId
                directoryScopeId = $a.DirectoryScopeId
                justification    = 'ENTPIMG: convert to eligible-only (standing access removed; eligible assignment exists)'
            }
            New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $body -ErrorAction Stop | Out-Null
            Write-Host ("REMOVED standing: {0} / {1}" -f $upn,$roleName) -ForegroundColor Green
            $removed++
        } else {
            Write-Host ("WOULD REMOVE: {0} / {1}  (eligible assignment confirmed)" -f $upn,$roleName) -ForegroundColor Cyan
        }
    }
}

Write-Host ("`nRemoved: {0}   Skipped: {1}" -f $removed, $skipped)
Write-Host "Run ENTPIMG-Discovery.ps1 to confirm these accounts now hold the roles as ELIGIBLE only."
Disconnect-MgGraph | Out-Null
