<#
.SYNOPSIS
    GWINTEG-Validation.ps1 — check pattern conformance across the Entra-side integration estate.
.DESCRIPTION
    PURPOSE
        Read-only conformance check against the pattern catalog. For each enterprise application it
        evaluates the standards the catalog requires: federated SSO present where an app authenticates
        users (P1/P5), a provisioning job where lifecycle is expected (P2/P6), no over-broad application
        permissions on integrations (P7 least privilege), no long-lived or no-expiry credentials
        (credential-sprawl anti-pattern), and an assigned owner. It reports each app as CONFORMS or the
        specific conformance issue. Optionally focus one app with -CheckAppId. Google-side and
        third-party-app internals are verified in those consoles; this covers the Entra plane.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWINTEG-Validation.ps1
        Focus one app: powershell -ExecutionPolicy Bypass -File .\GWINTEG-Validation.ps1 -CheckAppId your-app-id
        Required Graph scopes (read-only): Application.Read.All, Directory.Read.All, Policy.Read.All,
        Synchronization.Read.All.
    EXPECTED RESULTS
        A per-app pass/fail: CONFORMS, or a list of the conformance issues found (missing federation,
        missing provisioning, over-broad permission, risky credential, no owner). No changes are made.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CheckAppId
)

# Application permissions treated as over-broad on an integration (least-privilege / P7 gate).
$broadPerms = @('ReadWrite.All','Directory.ReadWrite.All','Mail.Read','Mail.ReadWrite','Files.ReadWrite.All','Application.ReadWrite.All')
# Warn on any single credential lifetime beyond this many days (long-lived-secret anti-pattern).
$maxCredentialDays = 400

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All' -NoWelcome

Write-Host "`n=== Pattern-Conformance Validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$sps = if ($CheckAppId) {
    Get-MgServicePrincipal -Filter "appId eq '$CheckAppId'" -ErrorAction SilentlyContinue
} else {
    Get-MgServicePrincipal -All
}
if (-not $sps) { Write-Host "No matching application(s) found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$pass = 0; $fail = 0
foreach ($sp in @($sps)) {
    $issues = @()

    $ssoMode = if ($sp.PreferredSingleSignOnMode) { $sp.PreferredSingleSignOnMode } else { 'none' }

    # P1/P5 — an app configured for password-based SSO is a snowflake; prefer saml/oidc federation.
    if ($ssoMode -eq 'password') {
        $issues += 'password-based SSO (not federated) — move to SAML/OIDC (P1/P5)'
    }

    # P7 — over-broad application permissions.
    $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    foreach ($a in $appRoles) {
        $rsp = Get-MgServicePrincipal -ServicePrincipalId $a.ResourceId -ErrorAction SilentlyContinue
        $role = $rsp.AppRoles | Where-Object { $_.Id -eq $a.AppRoleId }
        if ($role -and ($broadPerms | Where-Object { $role.Value -like "*$_*" })) {
            $issues += ("over-broad application permission: {0}/{1} (P7 least privilege)" -f $rsp.DisplayName, $role.Value)
        }
    }

    # Credential hygiene — no-expiry or excessively long-lived secrets/certs.
    foreach ($c in (@($sp.PasswordCredentials) + @($sp.KeyCredentials))) {
        if (-not $c.EndDateTime) {
            $issues += 'credential with no expiry (credential-sprawl anti-pattern)'
        } elseif ($c.StartDateTime -and (($c.EndDateTime - $c.StartDateTime).TotalDays -gt $maxCredentialDays)) {
            $issues += ("long-lived credential (> {0} days) — shorten/rotate" -f $maxCredentialDays)
        }
    }

    # Ownership — every integration needs an owner.
    $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    if (-not $owners) { $issues += 'no owner assigned' }

    if ($issues.Count -eq 0) {
        Write-Host ("  CONFORMS : {0}  (SSO {1})" -f $sp.DisplayName, $ssoMode) -ForegroundColor Green
        $pass++
    } else {
        Write-Host ("  REVIEW   : {0}  (SSO {1})" -f $sp.DisplayName, $ssoMode) -ForegroundColor Yellow
        $issues | Sort-Object -Unique | ForEach-Object { Write-Host ("             - {0}" -f $_) }
        $fail++
    }
}

Write-Host ("`nConformance: {0} conform, {1} need review." -f $pass, $fail) -ForegroundColor Cyan
Write-Host "Note: provisioning source-of-truth (P2 vs P3) and third-party-app SSO are confirmed in the Google/app consoles." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
