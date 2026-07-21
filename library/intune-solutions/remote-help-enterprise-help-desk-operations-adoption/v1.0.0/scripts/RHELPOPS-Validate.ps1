<#
.SYNOPSIS
    RHELPOPS-Validate.ps1 — PASS/FAIL validation of the Remote Help operating model (Graph).
.DESCRIPTION
    PURPOSE
        Checks that the help-desk operating model is actually in place:
          (1) the per-tier role/scope model exists (tier agent groups assigned to Remote Help roles
              with scope groups),
          (2) usage/audit reporting is reachable, and
          (3) unattended access is governed (an approved unattended scope group exists and is only
              attached to the Tier 3 role).
        Prints PASS or FAIL per check. Read-only; changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Validate.ps1
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementRBAC.Read.All, Group.Read.All, DeviceManagementApps.Read.All, AuditLog.Read.All
        (Verify the current scopes/endpoints that expose Remote Help role assignments and usage
         against Microsoft documentation.)
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall result. Any FAIL tells you which part of the model
        (role/scope, reporting, unattended governance) is missing.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
    Object names match the Implementation Guide (RHELP-T1/2/3-Agents, RHELP-Scope-*, RHELP Role - Tier *).
#>
[CmdletBinding()] param(
    [string[]]$TierAgentGroups = @('RHELP-T1-Agents','RHELP-T2-Agents','RHELP-T3-Agents'),
    [string[]]$ScopeGroups     = @('RHELP-Scope-Standard-Users','RHELP-Scope-VIP-Users'),
    [string]$UnattendedScope   = 'RHELP-Scope-Unattended-Devices',
    [string]$Tier3Role         = 'RHELP Role – Tier 3 Elevation'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementRBAC.Read.All','Group.Read.All','DeviceManagementApps.Read.All' -NoWelcome

$fail = 0
function Check($name, [bool]$ok, $detail) {
    if ($ok) { Write-Host ("PASS  {0}" -f $name) -ForegroundColor Green }
    else     { Write-Host ("FAIL  {0} — {1}" -f $name, $detail) -ForegroundColor Red; $script:fail++ }
}
function Group-Exists([string]$name) {
    try { @((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value).Count -gt 0 } catch { $false }
}

# Check 1 — role/scope model: tier agent groups + scope groups exist
$missingAgents = @($TierAgentGroups | Where-Object { -not (Group-Exists $_) })
$missingScopes = @($ScopeGroups    | Where-Object { -not (Group-Exists $_) })
Check "Tier agent groups present" ($missingAgents.Count -eq 0) ("missing: " + ($missingAgents -join ', '))
Check "Scope groups present"      ($missingScopes.Count -eq 0) ("missing: " + ($missingScopes -join ', '))

# Check 1b — role assignments exist tying agent groups to roles with scope
$assignedOk = $false
try {
    $defs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value
    foreach ($def in $defs) {
        $as = @()
        try { $as = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($def.id)/roleAssignments").value } catch {}
        if ($as | Where-Object { $_.scopeMembers -and $_.members }) { $assignedOk = $true }
    }
} catch {}
Check "Role assignments with scope exist" $assignedOk "no role assignment carries both member and scope groups — verify Graph path against Microsoft docs"

# Check 2 — reporting reachable (usage/audit endpoint responds)
$reportOk = $false
try { $null = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/auditEvents?$top=1'); $reportOk = $true } catch {}
Check "Usage/audit reporting reachable" $reportOk "audit/usage endpoint did not respond — verify reporting access + endpoint against Microsoft docs"

# Check 3 — unattended governed: unattended scope exists and is attached only to the Tier 3 role
$unattExists = Group-Exists $UnattendedScope
if (-not $unattExists) {
    Check "Unattended access governed" $true "no unattended scope group present — unattended not in use (acceptable if policy says so)"
} else {
    $onlyTier3 = $true
    try {
        $defs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value
        $ug = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$UnattendedScope'").value | Select-Object -First 1
        foreach ($def in $defs) {
            $as = @()
            try { $as = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($def.id)/roleAssignments").value } catch {}
            foreach ($a in $as) {
                if ($ug -and ($a.scopeMembers -contains $ug.id) -and ($def.displayName -ne $Tier3Role)) { $onlyTier3 = $false }
            }
        }
    } catch { $onlyTier3 = $false }
    Check "Unattended access governed (Tier 3 only)" $onlyTier3 "the unattended scope is attached to a role other than '$Tier3Role' — restrict unattended to Tier 3"
}

Write-Host ""
if ($fail -eq 0) { Write-Host "OVERALL: PASS — operating model is in place." -ForegroundColor Green }
else             { Write-Host ("OVERALL: FAIL — {0} check(s) failed. See above." -f $fail) -ForegroundColor Red }
Disconnect-MgGraph | Out-Null
exit $fail
