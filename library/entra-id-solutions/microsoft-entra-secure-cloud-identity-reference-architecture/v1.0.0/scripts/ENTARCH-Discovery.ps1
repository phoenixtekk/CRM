<#
.SYNOPSIS
    ENTARCH-Discovery.ps1 — inventory the current Entra identity posture to inform the architecture.
.DESCRIPTION
    PURPOSE
        Read-only assessment that grounds the reference architecture in the tenant's real current
        state: verified domains and topology signals, the identity source of authority (cloud-only vs.
        synced/hybrid), the true licensing position (Entra ID P1/P2, Governance, Global Secure Access,
        Verified ID — each flagged *verify current availability*), existing Conditional Access policies
        and their states, named locations, and external-collaboration (B2B) settings. This is the
        evidence base for the Decision Record — it changes NOTHING.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\ENTARCH-Discovery.ps1
        Optional: -CsvPath .\entra-posture.csv   to export the summary.
        Consents to Directory.Read.All, Policy.Read.All, Organization.Read.All, Domain.Read.All
        (all read-only). No changes are made.
    EXPECTED RESULTS
        A printed posture summary (domains, source of authority, licensing tier, CA policy inventory,
        named locations, external-collab posture). Optional CSV. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only. Design/assessment helper (not a deployment script).
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All','Organization.Read.All','Domain.Read.All' -NoWelcome

Write-Host "`n=== Entra Identity Posture Discovery — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# --- Verified domains / topology signals ---
Write-Host "`n-- Verified domains --" -ForegroundColor Cyan
$domains = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/domains').value
foreach ($d in $domains) {
    $tag = @()
    if ($d.isDefault)  { $tag += 'default' }
    if ($d.isInitial)  { $tag += 'onmicrosoft' }
    if (-not $d.isVerified) { $tag += 'UNVERIFIED' }
    Write-Host ("  • {0,-40} {1}" -f $d.id, ($tag -join ',')) -ForegroundColor White
}
if ($domains.Where({ $_.id -like '*.local' }).Count) {
    Write-Host "  WARN: a non-routable *.local domain is present — UPN hygiene finding (global req G7)." -ForegroundColor Red
}

# --- Identity source of authority (cloud-only vs synced) ---
Write-Host "`n-- Identity source of authority --" -ForegroundColor Cyan
$org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value | Select-Object -First 1
$syncEnabled = $org.onPremisesSyncEnabled
Write-Host ("  onPremisesSyncEnabled = {0}  →  {1}" -f $syncEnabled, ($(if($syncEnabled){'HYBRID (design Domain 6)'}else{'cloud-only'}))) -ForegroundColor White

# --- Licensing (feature detection — each flagged verify) ---
Write-Host "`n-- Licensing (verify current availability in your tenant) --" -ForegroundColor Cyan
$plans = @()
try { $plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName } catch {}
$feature = [ordered]@{
    'Entra ID P1'            = ($plans -contains 'AAD_PREMIUM')
    'Entra ID P2'            = ($plans -contains 'AAD_PREMIUM_P2')
    'Entra ID Governance'    = [bool]($plans -match 'Governance|IGA')
    'Global Secure Access'   = [bool]($plans -match 'GLOBAL_SECURE_ACCESS|Microsoft_Entra_Internet|Microsoft_Entra_Private')
    'Verified ID'            = [bool]($plans -match 'Verified|DECENTRALIZED')
}
foreach ($k in $feature.Keys) {
    $have = $feature[$k]
    Write-Host ("  {0,-22} {1}" -f $k, ($(if($have){'present'}else{'not detected'}))) -ForegroundColor ($(if($have){'Green'}else{'Yellow'}))
}
Write-Host "  NOTE: feature detection is a signal only — bundles/preview status change; confirm in M365 admin center." -ForegroundColor DarkGray

# --- Conditional Access inventory ---
Write-Host "`n-- Conditional Access policies --" -ForegroundColor Cyan
$caPolicies = @()
try { $caPolicies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value } catch {}
Write-Host ("  {0} CA policies found" -f $caPolicies.Count) -ForegroundColor White
foreach ($p in $caPolicies) {
    $allUsers = ($p.conditions.users.includeUsers -contains 'All')
    $excl = @($p.conditions.users.excludeUsers).Count + @($p.conditions.users.excludeGroups).Count
    Write-Host ("  • {0,-50} [{1}] allUsers={2} exclusions={3}" -f $p.displayName, $p.state, $allUsers, $excl) -ForegroundColor DarkGray
    if ($allUsers -and $excl -eq 0) { Write-Host "      WARN: All-users policy with NO exclusions — Zero Trust domain must reconcile (exclude break-glass)." -ForegroundColor Red }
}

# --- Named locations & external collaboration posture ---
Write-Host "`n-- Named locations --" -ForegroundColor Cyan
try {
    $locs = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/namedLocations').value
    Write-Host ("  {0} named locations defined" -f $locs.Count) -ForegroundColor White
} catch { Write-Host "  (could not read named locations)" -ForegroundColor DarkGray }

Write-Host "`n-- External collaboration (B2B) posture --" -ForegroundColor Cyan
try {
    $authPolicy = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authorizationPolicy'
    Write-Host ("  allowInvitesFrom = {0}" -f $authPolicy.allowInvitesFrom) -ForegroundColor White
    Write-Host ("  guest user role  = {0}" -f $authPolicy.guestUserRoleId) -ForegroundColor White
} catch { Write-Host "  (could not read authorizationPolicy — needs Policy.Read.All)" -ForegroundColor DarkGray }

if ($CsvPath) {
    $rows = $caPolicies | ForEach-Object { [pscustomobject]@{ Policy=$_.displayName; State=$_.state } }
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExported CA summary to $CsvPath" -ForegroundColor Green
}
Write-Host "`nSave this output as the Assess appendix of 'Identity Architecture - Enterprise - Design'." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
