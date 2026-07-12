<#
.SYNOPSIS
    ENTAPPMIG-Cutover.ps1 — pre-cutover readiness summary for a migrated app; preview-only by default.
.DESCRIPTION
    PURPOSE
        Before you repoint an app's federation from AD FS to Entra, run this to confirm the Entra side is
        ready and to see exactly what a cutover touches. It reports the migrated app's SSO configuration
        (identifier / reply URLs / SSO mode), its user/group assignments, whether a Conditional Access
        policy covers it, and — as a REMINDER checklist — the manual cutover + rollback steps (repoint the
        app to Entra; keep the AD FS relying party DISABLED, not deleted, as the rollback).
        This script does NOT change federation or AD FS. The only optional write action is toggling the
        Entra app's user-visibility/enabled flag, which is gated behind -Commit with a -WhatIf preview.
    HOW TO RUN
        Readiness:    .\ENTAPPMIG-Cutover.ps1 -AppName 'ENTAPPMIG - App - LOBSaml - Pilot'
        Preview flag: .\ENTAPPMIG-Cutover.ps1 -AppName '...' -EnableForAllUsers -WhatIf
        Apply flag:   .\ENTAPPMIG-Cutover.ps1 -AppName '...' -EnableForAllUsers -Commit
    EXPECTED RESULTS
        A readiness report + a printed cutover/rollback checklist. PASS = SSO configured, pilot validated,
        and CA covers the app — proceed with the manual federation repoint in a change window.
.NOTES
    White-label — Entra ID Solutions. Read-only by default; the only write (visibility flag) is gated behind
    -Commit with a -WhatIf preview. Federation repoint + AD FS changes are performed MANUALLY, not here.
    No credentials stored.
.EXAMPLE
    .\ENTAPPMIG-Cutover.ps1 -AppName 'ENTAPPMIG - App - LOBSaml - Pilot'
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)][string]$AppName,
    [switch]$EnableForAllUsers,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('Application.Read.All','Directory.Read.All','Policy.Read.All')
if ($Commit) { $scopes += 'Application.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

function Get-AllPages([string]$Uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $i+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $i }

$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$AppName'").value | Select-Object -First 1
if (-not $sp) { Write-Host "App '$AppName' not found." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
$app = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/applications?`$filter=displayName eq '$AppName'").value | Select-Object -First 1

Write-Host "`n=== Cutover readiness: $AppName ===" -ForegroundColor Cyan
Write-Host "  SSO mode        : $($sp.preferredSingleSignOnMode)"
Write-Host "  Identifier(s)   : $((@($app.identifierUris) -join '; '))"
Write-Host "  Reply URLs      : $((@($app.web.redirectUris + $sp.replyUrls) | Where-Object { $_ } | Select-Object -Unique) -join '; ')"
Write-Host "  App enabled     : $($sp.accountEnabled)"

Write-Host "`n  Assignments:" -ForegroundColor White
$assign = Get-AllPages "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo"
if ($assign) { $assign | ForEach-Object { "    - $($_.principalDisplayName) [$($_.principalType)]" } } else { Write-Host "    (none — nobody assigned yet)" -ForegroundColor Yellow }

Write-Host "`n  Conditional Access coverage:" -ForegroundColor White
$ca = Get-AllPages "/v1.0/identity/conditionalAccess/policies"
$covering = $ca | Where-Object {
    $inc = $_.conditions.applications.includeApplications
    ($inc -contains $sp.appId) -or ($inc -contains 'All')
}
if ($covering) { $covering | ForEach-Object { "    - $($_.displayName) [$($_.state)]" } } else { Write-Host "    [WARN] no CA policy covers this app — add it to ENTAPPMIG - CA - MigratedApps before cutover" -ForegroundColor Yellow }

# --- Optional gated visibility flag -------------------------------------------
if ($EnableForAllUsers) {
    if (-not $Commit) {
        Write-Host "`n[WhatIf] Would set app '$AppName' visible/enabled for all users. Add -Commit to apply." -ForegroundColor Magenta
    }
    elseif ($PSCmdlet.ShouldProcess($AppName, "Set service principal visible/enabled for all users")) {
        Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/servicePrincipals/$($sp.id)" -Body @{ accountEnabled = $true } | Out-Null
        Write-Host "  app enabled for sign-in." -ForegroundColor Green
    }
}

Write-Host "`n=== MANUAL cutover + rollback checklist (performed outside this script) ===" -ForegroundColor Cyan
Write-Host @"
  1. In a CHANGE WINDOW, repoint the application's federation/IdP endpoint from AD FS to Entra
     (use the Entra SAML metadata/OIDC values from 03-implementation Step 2).
  2. Validate real users sign in through Entra (ENTAPPMIG-Report.ps1 shows sign-ins + CA status).
  3. DISABLE the AD FS relying party (do NOT delete) — this is your instant rollback.
  4. Soak. If issues: re-enable the AD FS relying party and repoint the app back to AD FS.
  5. After a clean soak period, remove the AD FS relying party.
"@ -ForegroundColor Gray
Disconnect-MgGraph | Out-Null
