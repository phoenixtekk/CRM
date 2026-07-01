<#
.SYNOPSIS
    NSSSO-Remediation.ps1 — safely close common provisioning-scope gaps (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Ensures the identity scope group(s) are assigned to the Netskope enterprise application so
        SSO and SCIM provisioning cover the intended population. By default it runs in -WhatIf mode
        and only reports the changes it would make; pass -Apply to make the assignment. It does NOT
        configure SAML or the SCIM endpoint/token — those are Netskope-side and deferred.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\NSSSO-Remediation.ps1
        Apply changes:      powershell -ExecutionPolicy Bypass -File .\NSSSO-Remediation.ps1 -Apply
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All, Group.Read.All.
    EXPECTED RESULTS
        In preview: a list of group-to-app assignments that are missing. With -Apply: the missing
        assignments are created. Re-run NSSSO-Validation.ps1 / NSSSO-Report.ps1 afterward.
.NOTES
    Network Solutions — Netskope + Entra ID SSO. Default -WhatIf. Netskope console specifics deferred.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$AppDisplayName = 'Netskope SSO - Corp - Prod',
    [string[]]$ScopeGroups  = @('Netskope Identity - Pilot - Stage'),
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.ReadWrite.All','AppRoleAssignment.ReadWrite.All','Group.Read.All' -NoWelcome

Write-Host "=== Netskope SSO/SCIM scope remediation ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to make changes)" -ForegroundColor Yellow }

$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) { Write-Host ("App '{0}' not found — create it first (Implementation Step 1)." -f $AppDisplayName) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

# Existing assignments on the app
$existing = @()
try { $existing = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo").value } catch {}
$assignedIds = $existing | ForEach-Object { $_.principalId }

# Default app role (0-GUID = default access) — use the app's first available role if defined
$roleId = '00000000-0000-0000-0000-000000000000'
if ($sp.appRoles -and $sp.appRoles.Count -gt 0) {
    $userRole = $sp.appRoles | Where-Object { $_.isEnabled -and ($_.allowedMemberTypes -contains 'User') } | Select-Object -First 1
    if ($userRole) { $roleId = $userRole.id }
}

foreach ($g in $ScopeGroups) {
    $ge = $g.Replace("'","''")
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
    if (-not $grp) { Write-Host ("  Group '{0}' missing — create it with NSSSO-Set-IdentityScopeTargeting.ps1" -f $g) -ForegroundColor Yellow; continue }

    if ($assignedIds -contains $grp.id) {
        Write-Host ("  OK   : '{0}' already assigned to the app." -f $g) -ForegroundColor Green
        continue
    }

    if ($PSCmdlet.ShouldProcess($g, "Assign group to '$AppDisplayName'")) {
        $body = @{ principalId = $grp.id; resourceId = $sp.id; appRoleId = $roleId } | ConvertTo-Json
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo" -Body $body -ContentType 'application/json' | Out-Null
            Write-Host ("  DONE : assigned '{0}' to the app." -f $g) -ForegroundColor Green
        } catch { Write-Host ("  FAIL : could not assign '{0}': {1}" -f $g, $_.Exception.Message) -ForegroundColor Yellow }
    } else {
        Write-Host ("  WOULD: assign '{0}' to the app." -f $g) -ForegroundColor Cyan
    }
}

Write-Host "`nSAML config and the SCIM tenant URL/secret token are Netskope-side and deferred to the Netskope documentation." -ForegroundColor DarkGray
Write-Host "Re-run NSSSO-Validation.ps1 / NSSSO-Report.ps1 to confirm." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
