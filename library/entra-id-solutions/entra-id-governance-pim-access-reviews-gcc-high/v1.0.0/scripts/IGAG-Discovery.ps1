<#
.SYNOPSIS
    IGAG-Discovery.ps1 — GCC High Entra ID Governance posture: PIM roles/eligibility, access reviews, access packages.
.DESCRIPTION
    PURPOSE
        Reports the current governance posture in a US Government (GCC High/DoD) tenant: PIM Entra-role
        eligible vs active assignments, configured access reviews, and entitlement-management access
        packages. Flags break-glass accounts (permanent active Global Administrator) so their exclusion
        is visible. Read-only. Use -Environment USGovDoD on the DoD cloud.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IGAG-Discovery.ps1
        Connects to US Gov Graph (-Environment USGov). Read-only scopes:
        RoleManagement.Read.Directory, AccessReview.Read.All, EntitlementManagement.Read.All, User.Read.All.
    EXPECTED RESULTS
        Counts of eligible vs active privileged assignments, a list of access reviews and access
        packages, and a break-glass (standing Global Administrator) callout. Pass = posture printed
        against graph.microsoft.us; fail = a connection/redirect error means -Environment was omitted.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()] param([ValidateSet('USGov','USGovDoD')][string]$Environment = 'USGov')
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All','User.Read.All' -NoWelcome

Write-Host "`n=== Entra ID Governance — GCC High posture (env: $Environment) ===" -ForegroundColor Cyan

# PIM Entra-role assignments (eligible vs active)
$elig  = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances').value)
$activ = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignmentScheduleInstances').value)
Write-Host ("PIM eligible role assignments : {0}" -f $elig.Count)
Write-Host ("PIM active role assignments   : {0}" -f $activ.Count)
$standing = @($activ | Where-Object { $_.assignmentType -eq 'Assigned' -and $_.memberType -eq 'Direct' })
Write-Host ("Standing (permanent) active   : {0}" -f $standing.Count) -ForegroundColor ($(if($standing.Count -gt 2){'Yellow'}else{'Green'}))

# Break-glass callout: permanent active Global Administrator
$gaRole = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/roleManagement/directory/roleDefinitions?`$filter=displayName eq 'Global Administrator'").value | Select-Object -First 1
if ($gaRole) {
    $ga = @($activ | Where-Object { $_.roleDefinitionId -eq $gaRole.id })
    Write-Host ("Standing Global Administrators : {0} (expect your documented break-glass accounts)" -f $ga.Count) -ForegroundColor Cyan
}

# Access reviews
$reviews = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/accessReviews/definitions').value)
Write-Host ("Access review definitions     : {0}" -f $reviews.Count)
$reviews | Select-Object -First 20 | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }

# Entitlement-management access packages
$pkgs = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/entitlementManagement/accessPackages').value)
Write-Host ("Access packages               : {0}" -f $pkgs.Count)
$pkgs | Select-Object -First 20 | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }

Disconnect-MgGraph | Out-Null
