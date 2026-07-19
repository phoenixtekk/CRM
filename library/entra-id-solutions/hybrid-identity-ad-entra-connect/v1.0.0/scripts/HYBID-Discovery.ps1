<#
.SYNOPSIS
    HYBID-Discovery.ps1 — Active Directory and identity readiness for hybrid identity.
.DESCRIPTION
    PURPOSE
        Read-only readiness check before installing Microsoft Entra Connect. Reports the Entra
        Connect host OS/TLS readiness, AD forest/domain and UPN suffixes, flags non-routable
        (.local) UPNs and duplicate UPN/proxyAddress values, and surfaces basic AD health hints.
    HOW TO RUN
        On the planned Connect host (domain-joined), elevated:
        powershell -ExecutionPolicy Bypass -File .\HYBID-Discovery.ps1
        Requires the ActiveDirectory PowerShell module (RSAT) to read directory objects.
    EXPECTED RESULTS
        Host/TLS summary, forest/domain + UPN suffixes, counts of .local UPNs and duplicate
        UPN/proxyAddress values, and any AD health warning. No changes are made.
.NOTES
    Entra ID Solutions. Read-only.
#>
[CmdletBinding()] param()

Write-Host "`n=== Hybrid Identity Discovery — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# Host / TLS readiness
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
Write-Host ("Host OS          : {0}" -f $os.Caption)
$tls = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name SchUseStrongCrypto -ErrorAction SilentlyContinue).SchUseStrongCrypto
Write-Host ("TLS 1.2 strong   : {0}" -f ($(if ($tls -eq 1) { 'enabled' } else { 'NOT confirmed — enable SchUseStrongCrypto' })))

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "ActiveDirectory module not found — install RSAT AD tools to inspect directory objects." -ForegroundColor Yellow
    return
}
Import-Module ActiveDirectory -ErrorAction Stop

# Forest / domain / UPN suffixes
$forest = Get-ADForest
$domain = Get-ADDomain
Write-Host ("Forest           : {0}  (mode {1})" -f $forest.Name, $forest.ForestMode)
Write-Host ("Domain           : {0}  (mode {1})" -f $domain.DNSRoot, $domain.DomainMode)
$suffixes = @($domain.DNSRoot) + @($forest.UPNSuffixes)
Write-Host ("UPN suffixes     : {0}" -f ($suffixes -join ', '))

# Non-routable (.local) UPNs
$users = Get-ADUser -Filter * -Properties UserPrincipalName, proxyAddresses
$localUpn = $users | Where-Object { $_.UserPrincipalName -and $_.UserPrincipalName -match '\.local$' }
Write-Host ("Non-routable UPNs: {0}" -f $localUpn.Count) -ForegroundColor ($(if ($localUpn.Count -gt 0) { 'Yellow' } else { 'Green' }))

# Duplicate UPNs
$dupUpn = $users | Where-Object { $_.UserPrincipalName } | Group-Object UserPrincipalName | Where-Object { $_.Count -gt 1 }
Write-Host ("Duplicate UPNs   : {0}" -f $dupUpn.Count) -ForegroundColor ($(if ($dupUpn.Count -gt 0) { 'Yellow' } else { 'Green' }))

# Duplicate proxyAddresses
$allProxy = foreach ($u in $users) { foreach ($p in $u.proxyAddresses) { ($p -replace '^smtp:', '').ToLower() } }
$dupProxy = $allProxy | Where-Object { $_ } | Group-Object | Where-Object { $_.Count -gt 1 }
Write-Host ("Dup proxyAddress : {0}" -f $dupProxy.Count) -ForegroundColor ($(if ($dupProxy.Count -gt 0) { 'Yellow' } else { 'Green' }))

if ($localUpn.Count -or $dupUpn.Count -or $dupProxy.Count) {
    Write-Host "`nResolve the flagged items (verify a public domain, fix UPNs/duplicates) before syncing." -ForegroundColor Yellow
} else {
    Write-Host "`nNo blocking UPN/duplicate issues detected." -ForegroundColor Green
}
Write-Host "Run AD health separately: dcdiag /q ; repadmin /replsummary"
