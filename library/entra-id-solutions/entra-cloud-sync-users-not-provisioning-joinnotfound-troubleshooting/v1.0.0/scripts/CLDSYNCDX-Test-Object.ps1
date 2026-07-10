<#
.SYNOPSIS
    CLDSYNCDX-Test-Object.ps1 — is this AD user even a cloud sync create candidate? (read-only)
.DESCRIPTION
    PURPOSE
        Read-only Active Directory check for ONE user, to catch the "excluded / out-of-scope /
        already-exists" reasons behind a JoinNotFound / skipped object. Reports: IsCriticalSystemObject
        (excluded by design if true); whether the object's OU is UNDER one of the operator-supplied
        in-scope OU DNs (out of scope for the scheduled cycle if not); whether the UPN suffix is a
        routable domain (and, if -VerifiedDomains is supplied, whether it is one of them); and an
        ADVISORY on other AD objects sharing the same userPrincipalName or proxyAddresses (a possible
        existing/duplicate target). Makes NO changes.
    HOW TO RUN
        Run on the agent host or a domain member with the ActiveDirectory module:
            powershell -File .\CLDSYNCDX-Test-Object.ps1 -Identity jsmith
            powershell -File .\CLDSYNCDX-Test-Object.ps1 -Identity jsmith `
                -InScopeOU 'OU=Cloud Sync - In-Scope Users - OU,DC=contoso,DC=com' `
                -VerifiedDomains contoso.com,contoso.onmicrosoft.com
        No Microsoft Graph scopes needed — this inspects Active Directory only.
    EXPECTED RESULTS
        A PASS/FAIL/ADVISORY line per condition. Critical object, out-of-scope OU, a non-routable UPN,
        or a duplicate advisory each map to a cause in 06-troubleshooting.md (Scope & matching /
        Already-exists / the core JoinNotFound symptom).
.NOTES
    White-label — the repeatable way. Read-only against Active Directory. Cloud sync service internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $Identity,

    [string[]] $InScopeOU = @(),

    [string[]] $VerifiedDomains = @()
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module ActiveDirectory -ListAvailable)) {
    throw "ActiveDirectory module not found. Install RSAT / the AD DS tools, then re-run on a domain member."
}
Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "=== Cloud Sync — Object Candidate Test ===" -ForegroundColor Cyan

$props = 'IsCriticalSystemObject', 'userPrincipalName', 'proxyAddresses', 'distinguishedName', 'objectGUID', 'sAMAccountName'
try {
    $u = Get-ADUser -Identity $Identity -Properties $props -ErrorAction Stop
} catch {
    try { $u = Get-ADUser -Filter "userPrincipalName -eq '$Identity'" -Properties $props -ErrorAction Stop } catch {}
    if (-not $u) { throw "Could not find an AD user for '$Identity' (tried sAMAccountName/DN and userPrincipalName)." }
}

Write-Host ("`nUser         : {0}" -f $u.Name)
Write-Host ("sAMAccount   : {0}" -f $u.sAMAccountName)
Write-Host ("ObjectGuid   : {0}" -f $u.objectGUID)
Write-Host ("UPN          : {0}" -f $u.userPrincipalName)
Write-Host ("DN           : {0}" -f $u.distinguishedName)
Write-Host ""

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string]$Name, [string]$Verdict, [string]$Detail, [string]$Remedy)
    $results.Add([pscustomobject]@{ Check = $Name; Verdict = $Verdict; Detail = $Detail; Remedy = $Remedy })
}

# 1. IsCriticalSystemObject (excluded by design).
$isCritical = [bool]$u.IsCriticalSystemObject
Add-Result 'Not a critical system object' $(if ($isCritical) { 'FAIL' } else { 'PASS' }) `
    ("IsCriticalSystemObject = {0}" -f $isCritical) `
    'Built-in accounts/groups are excluded by design; test provisioning with an ordinary user in an in-scope OU.'

# 2. OU under an in-scope OU DN.
if ($InScopeOU.Count) {
    $dn = $u.distinguishedName
    $inScope = $false; $matched = $null
    foreach ($ou in $InScopeOU) {
        $ouTrim = $ou.Trim()
        if ($dn -like "*$ouTrim") { $inScope = $true; $matched = $ouTrim; break }
    }
    Add-Result 'OU is within the configured scope' $(if ($inScope) { 'PASS' } else { 'FAIL' }) `
        $(if ($inScope) { "under: $matched" } else { "DN not under any supplied in-scope OU" }) `
        'Add the user''s OU to the cloud sync scoping filters (or move the user into an in-scope OU), then RESTART provisioning to clear watermarks.'
} else {
    Add-Result 'OU is within the configured scope' 'ADVISORY' `
        'no -InScopeOU supplied; cannot judge scope' `
        'Re-run with -InScopeOU set to the DN(s) the cloud sync configuration synchronizes.'
}

# 3. UPN suffix routable / verified.
$upnSuffix = $null
if ($u.userPrincipalName -and $u.userPrincipalName.Contains('@')) { $upnSuffix = $u.userPrincipalName.Split('@')[-1] }
$nonRoutable = ($null -eq $upnSuffix) -or ($upnSuffix -match '\.local$|\.internal$') -or ($upnSuffix -notmatch '\.')
if ($VerifiedDomains.Count -and $upnSuffix) {
    $isVerified = $VerifiedDomains -contains $upnSuffix
    Add-Result 'UPN suffix is a verified/routable domain' $(if ($isVerified) { 'PASS' } else { 'FAIL' }) `
        ("suffix: {0}; verified list: {1}" -f $upnSuffix, ($VerifiedDomains -join ', ')) `
        'Add/verify the public domain in Entra and set the user''s UPN suffix to a verified, routable domain.'
} else {
    Add-Result 'UPN suffix is a verified/routable domain' $(if ($nonRoutable) { 'FAIL' } else { 'ADVISORY' }) `
        ("suffix: {0}{1}" -f $(if ($upnSuffix) { $upnSuffix } else { '(none)' }), $(if ($VerifiedDomains.Count) { '' } else { '  (pass -VerifiedDomains to confirm against the tenant)' })) `
        'Ensure the UPN suffix is a public, verified, routable domain in Entra (not .local / single-label).'
}

# 4. Duplicate UPN / proxyAddresses advisory.
$dupDetail = @()
if ($u.userPrincipalName) {
    $dupUpn = @(Get-ADUser -Filter "userPrincipalName -eq '$($u.userPrincipalName)'" -Properties userPrincipalName -ErrorAction SilentlyContinue |
        Where-Object { $_.objectGUID -ne $u.objectGUID })
    if ($dupUpn.Count) { $dupDetail += ("same UPN as: {0}" -f (($dupUpn | ForEach-Object { $_.sAMAccountName }) -join ', ')) }
}
foreach ($pa in @($u.proxyAddresses)) {
    if (-not $pa) { continue }
    $dupPa = @(Get-ADUser -Filter "proxyAddresses -eq '$pa'" -Properties proxyAddresses -ErrorAction SilentlyContinue |
        Where-Object { $_.objectGUID -ne $u.objectGUID })
    if ($dupPa.Count) { $dupDetail += ("proxyAddress '{0}' also on: {1}" -f $pa, (($dupPa | ForEach-Object { $_.sAMAccountName }) -join ', ')) }
}
Add-Result 'No duplicate UPN / proxyAddress in AD (advisory)' $(if ($dupDetail.Count) { 'ADVISORY' } else { 'PASS' }) `
    $(if ($dupDetail.Count) { ($dupDetail -join ' | ') } else { 'no in-AD duplicates found' }) `
    'Also check Entra ID for a CLOUD-ONLY object with the same UPN/proxyAddress (prior sync method / manual create) — the most common JoinNotFound cause.'

# --- Report ------------------------------------------------------------------
$results | Format-Table Check, Verdict, Detail -AutoSize -Wrap
$fails = @($results | Where-Object { $_.Verdict -eq 'FAIL' })
Write-Host ""
if ($fails.Count -eq 0) {
    Write-Host "No hard FAILs on the AD object. If it still skips (JoinNotFound), suspect an EXISTING Entra target (already-exists) or a stalled/quarantined job — see 06-troubleshooting.md." -ForegroundColor Yellow
} else {
    Write-Host "Address each FAIL below, then re-run provision on demand:" -ForegroundColor Red
    foreach ($f in $fails) { Write-Host ("  [{0}] {1}" -f $f.Check, $f.Remedy) -ForegroundColor Yellow }
}
Write-Host "Read-only: no changes were made to Active Directory." -ForegroundColor Green
