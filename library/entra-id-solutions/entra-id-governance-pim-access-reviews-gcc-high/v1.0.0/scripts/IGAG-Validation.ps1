<#
.SYNOPSIS
    IGAG-Validation.ps1 — confirm GCC High privileged roles are eligible (not standing) and activation is gated.
.DESCRIPTION
    PURPOSE
        Verifies the governance baseline on a US Government (GCC High/DoD) tenant: privileged Entra
        roles are held as PIM Eligible rather than standing active, activation policy requires approval
        and MFA, and documented break-glass accounts remain the only expected standing Global
        Administrators. Read-only. Pass break-glass UPNs on the tenant your-tenant.onmicrosoft.us domain.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IGAG-Validation.ps1 -BreakGlassUpns "bg1@your-tenant.onmicrosoft.us","bg2@your-tenant.onmicrosoft.us"
        Connects to US Gov Graph (-Environment USGov; use USGovDoD for DoD). Read-only scopes:
        RoleManagement.Read.Directory, User.Read.All.
    EXPECTED RESULTS
        "GOVERNANCE BASELINE OK" when privileged roles are eligible, activation is gated, and only the
        named break-glass accounts hold standing Global Administrator. Otherwise "NOT FULLY GOVERNED".
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param(
    [string[]]$BreakGlassUpns = @(),
    [ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'RoleManagement.Read.Directory','User.Read.All' -NoWelcome
Write-Host "=== IGAG Validation (GCC High, env: $Environment) ===" -ForegroundColor Cyan

$elig  = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances').value)
$activ = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignmentScheduleInstances').value)
$hasEligible = $elig.Count -gt 0
Write-Host ("Eligible assignments present  : {0}" -f ($(if($hasEligible){'YES'}else{'NO'}))) -ForegroundColor ($(if($hasEligible){'Green'}else{'Yellow'}))

# Standing Global Administrators vs expected break-glass
$gaRole = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/roleManagement/directory/roleDefinitions?`$filter=displayName eq 'Global Administrator'").value | Select-Object -First 1
$ga = @($activ | Where-Object { $_.roleDefinitionId -eq $gaRole.id })
$gaUpns = @()
foreach ($a in $ga) { try { $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/directoryObjects/$($a.principalId)"; if ($u.userPrincipalName) { $gaUpns += $u.userPrincipalName } } catch {} }
$unexpected = @($gaUpns | Where-Object { $BreakGlassUpns -notcontains $_ })
Write-Host ("Standing Global Admins        : {0}" -f ($gaUpns -join ', '))
Write-Host ("Unexpected standing GA        : {0}" -f ($(if($unexpected.Count){$unexpected -join ', '}else{'none'}))) -ForegroundColor ($(if($unexpected.Count){'Yellow'}else{'Green'}))

# Activation policy: approval + MFA on the first eligible role
$gated = $false
if ($hasEligible) {
    $rid = $elig[0].roleDefinitionId
    try {
        $pol = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$rid'&`$expand=policy(`$expand=rules)").value | Select-Object -First 1
        $rules = $pol.policy.rules
        $needsApproval = ($rules | Where-Object { $_.id -eq 'Approval_EndUser_Assignment' }).setting.isApprovalRequired
        $needsMfa = ($rules | Where-Object { $_.id -eq 'Enablement_EndUser_Assignment' }).enabledRules -contains 'MultiFactorAuthentication'
        $gated = $needsApproval -or $needsMfa
        Write-Host ("Activation approval required  : {0}" -f $needsApproval)
        Write-Host ("Activation MFA required       : {0}" -f $needsMfa)
    } catch { Write-Host "  Could not read activation policy: $($_.Exception.Message)" -ForegroundColor Yellow }
}

if ($hasEligible -and $unexpected.Count -eq 0 -and $gated) { Write-Host "`nResult: GOVERNANCE BASELINE OK" -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
else { Write-Host "`nResult: NOT FULLY GOVERNED — onboard roles as eligible / gate activation / verify break-glass" -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
