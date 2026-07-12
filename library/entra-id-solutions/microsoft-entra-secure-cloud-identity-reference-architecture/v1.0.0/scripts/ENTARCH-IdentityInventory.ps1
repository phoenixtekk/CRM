<#
.SYNOPSIS
    ENTARCH-IdentityInventory.ps1 — profile the three identity types (human / workload / external).
.DESCRIPTION
    PURPOSE
        Read-only inventory that informs the identity-model domain (Domain 2) of the architecture. It
        profiles the three identity types the design must account for:
          • HUMAN    — member users, likely-stale accounts (no recent sign-in), and MFA registration.
          • WORKLOAD — service principals and managed identities, plus app credentials nearing expiry.
          • EXTERNAL — B2B guest users, guest account age, and the cross-tenant collaboration signal.
        The counts and highlights drive ADR-003/004/005 (human/workload/external identity decisions).
        It changes NOTHING.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTARCH-IdentityInventory.ps1
        Optional: -StaleDays 90   (sign-in age that flags a human account as likely-stale)
                  -CredExpiryDays 30   (app-credential expiry window to warn on)
        Consents to Directory.Read.All, User.Read.All, Application.Read.All, AuditLog.Read.All
        (all read-only). No changes are made.
    EXPECTED RESULTS
        Printed counts and highlights for human, workload, and external identities. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only. Design/assessment helper (not a deployment script).
#>
[CmdletBinding()]
param(
    [int]$StaleDays = 90,
    [int]$CredExpiryDays = 30
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Directory.Read.All','User.Read.All','Application.Read.All','AuditLog.Read.All' -NoWelcome

Write-Host "`n=== Identity Model Inventory (human / workload / external) — $(Get-Date -Format s) ===" -ForegroundColor Cyan
$staleCutoff = (Get-Date).AddDays(-$StaleDays)

# ---------------- HUMAN identities ----------------
Write-Host "`n-- HUMAN identities (member users) --" -ForegroundColor Cyan
$members = @(); $guests = @()
$uri = "/v1.0/users?`$select=id,userPrincipalName,userType,accountEnabled,signInActivity,createdDateTime&`$top=999"
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($u in $resp.value) { if ($u.userType -eq 'Guest') { $guests += $u } else { $members += $u } }
    $uri = $resp.'@odata.nextLink'
} while ($uri)

$staleMembers = $members | Where-Object {
    $last = $_.signInActivity.lastSignInDateTime
    (-not $last) -or ([datetime]$last -lt $staleCutoff)
}
Write-Host ("  member users        : {0}" -f $members.Count) -ForegroundColor White
Write-Host ("  disabled members    : {0}" -f (@($members | Where-Object { -not $_.accountEnabled }).Count)) -ForegroundColor White
Write-Host ("  likely-stale (> {0}d): {1}" -f $StaleDays, $staleMembers.Count) -ForegroundColor ($(if($staleMembers.Count){'Yellow'}else{'Green'}))
if ($staleMembers.Count) { Write-Host "     → informs ADR-013 (lifecycle/JML) — stale accounts are a governance driver." -ForegroundColor DarkGray }

# MFA registration signal (read-only reporting API)
try {
    $reg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/authenticationMethods/userRegistrationDetails?`$top=999").value
    $mfaCap = @($reg | Where-Object { $_.isMfaCapable }).Count
    Write-Host ("  MFA-capable (registered): {0} of {1} reported" -f $mfaCap, $reg.Count) -ForegroundColor White
} catch { Write-Host "  (MFA registration report unavailable — needs Entra ID P1+ and AuditLog.Read.All)" -ForegroundColor DarkGray }

# ---------------- WORKLOAD identities ----------------
Write-Host "`n-- WORKLOAD identities (service principals / managed identities) --" -ForegroundColor Cyan
$sps = @()
$uri = "/v1.0/servicePrincipals?`$select=id,displayName,servicePrincipalType,keyCredentials,passwordCredentials&`$top=999"
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    $sps += $resp.value
    $uri = $resp.'@odata.nextLink'
} while ($uri)
$managed = @($sps | Where-Object { $_.servicePrincipalType -eq 'ManagedIdentity' })
$apps    = @($sps | Where-Object { $_.servicePrincipalType -eq 'Application' })
Write-Host ("  service principals   : {0}  (Application={1}, ManagedIdentity={2})" -f $sps.Count, $apps.Count, $managed.Count) -ForegroundColor White

$expCutoff = (Get-Date).AddDays($CredExpiryDays)
$expiring = @()
foreach ($sp in $apps) {
    foreach ($c in @($sp.passwordCredentials) + @($sp.keyCredentials)) {
        if ($c.endDateTime -and [datetime]$c.endDateTime -lt $expCutoff) {
            $expiring += [pscustomobject]@{ App=$sp.displayName; Expires=$c.endDateTime }
        }
    }
}
Write-Host ("  app credentials expiring within {0}d: {1}" -f $CredExpiryDays, $expiring.Count) -ForegroundColor ($(if($expiring.Count){'Yellow'}else{'Green'}))
foreach ($e in $expiring | Select-Object -First 15) { Write-Host ("     • {0,-45} {1}" -f $e.App, $e.Expires) -ForegroundColor DarkGray }
if ($expiring.Count) { Write-Host "     → informs ADR-004 (workload identity strategy) — prefer managed identities / short-lived creds." -ForegroundColor DarkGray }

# ---------------- EXTERNAL identities ----------------
Write-Host "`n-- EXTERNAL identities (B2B guests) --" -ForegroundColor Cyan
$oldGuests = $guests | Where-Object { $_.createdDateTime -and ([datetime]$_.createdDateTime -lt (Get-Date).AddDays(-365)) }
Write-Host ("  guest users          : {0}" -f $guests.Count) -ForegroundColor White
Write-Host ("  guests older than 1yr: {0}" -f @($oldGuests).Count) -ForegroundColor ($(if(@($oldGuests).Count){'Yellow'}else{'Green'}))
if (@($oldGuests).Count) { Write-Host "     → informs ADR-005 (external posture) + ADR-015 (guest access reviews)." -ForegroundColor DarkGray }
try {
    $xt = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/default'
    Write-Host ("  cross-tenant inbound B2B default: {0}" -f $xt.b2bCollaborationInbound.usersAndGroups.accessType) -ForegroundColor White
} catch { Write-Host "  (cross-tenant access policy not read — optional signal)" -ForegroundColor DarkGray }

Write-Host "`nRecord these counts in Domain 2 (Identity Model) of the Design Document." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
