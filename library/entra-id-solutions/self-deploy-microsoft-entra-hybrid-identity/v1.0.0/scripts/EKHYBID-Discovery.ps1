<#
.SYNOPSIS
    EKHYBID-Discovery.ps1 — Read-only baseline of the hybrid-identity estate.
.DESCRIPTION
    PURPOSE
        Assess the current hybrid configuration before the labs: directory-sync state and last sync
        time, sync engine hint (Connect Sync vs Cloud Sync), federated vs managed domains, and
        UPN-hygiene flags (non-routable .local UPNs, duplicate hints). This is the "Assess" baseline.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\EKHYBID-Discovery.ps1
        Sign in when prompted (read-only scopes). No changes are made. Some AD-side flags require the
        ActiveDirectory (RSAT) module on a domain-joined host.
    EXPECTED RESULTS
        A printed baseline: sync enabled + last sync time, domains (managed/federated), and UPN-hygiene
        hints. Nothing is modified.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param()

$ErrorActionPreference = 'Stop'
Write-Host "`n=== Hybrid Identity — Discovery (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'Directory.Read.All','Domain.Read.All','Organization.Read.All','AuditLog.Read.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

# --- Directory sync state / last sync time ---
try {
    $org = Get-MgOrganization
    $syncEnabled = $org.OnPremisesSyncEnabled
    $lastSync    = $org.OnPremisesLastSyncDateTime
    Write-Host ("Directory sync    : {0}" -f $(if($syncEnabled){'ENABLED'}else{'not enabled (cloud-only?)'})) -ForegroundColor $(if($syncEnabled){'Green'}else{'Yellow'})
    if ($lastSync) {
        $age = (New-TimeSpan -Start $lastSync -End (Get-Date).ToUniversalTime())
        Write-Host ("Last sync (UTC)   : {0}  ({1:n0} min ago)" -f $lastSync, $age.TotalMinutes) -ForegroundColor $(if($age.TotalMinutes -le 120){'Green'}else{'Yellow'})
    }
} catch { Write-Host "  (could not read organization sync state: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- Domains: managed vs federated (auth method hint) ---
try {
    $domains = Get-MgDomain -All
    $fed = @($domains | Where-Object { $_.AuthenticationType -eq 'Federated' })
    Write-Host ("Domains           : {0} total, {1} federated (AD FS)" -f $domains.Count, $fed.Count)
    foreach ($d in $fed) { Write-Host ("  FEDERATED        : {0}  -> plan migration to cloud auth (staged rollout)" -f $d.Id) -ForegroundColor Yellow }
    $unverified = @($domains | Where-Object { -not $_.IsVerified })
    if ($unverified.Count) { Write-Host ("  UNVERIFIED domains: {0}" -f (($unverified.Id) -join ', ')) -ForegroundColor Yellow }
} catch { Write-Host "  (could not read domains: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- UPN hygiene (cloud side): count users with non-routable/onmicrosoft UPN issues ---
try {
    $initial = ($domains | Where-Object { $_.IsInitial }).Id
    $onmicro = Get-MgUser -Filter "endsWith(userPrincipalName,'$initial')" -ConsistencyLevel eventual -CountVariable c -All -ErrorAction SilentlyContinue
    Write-Host ("Users on {0}: {1} (should be low — mostly break-glass/service)" -f $initial, @($onmicro).Count)
} catch { Write-Host "  (UPN cloud-side hint unavailable: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- AD-side UPN hygiene (optional; requires RSAT on a domain-joined host) ---
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $forest = Get-ADForest; $domain = Get-ADDomain
        Write-Host ("AD forest/domain  : {0} / {1}" -f $forest.Name, $domain.DNSRoot)
        Write-Host ("AD UPN suffixes   : {0}" -f (@($domain.DNSRoot + $forest.UPNSuffixes) -join ', '))
        $localUpn = @(Get-ADUser -Filter 'UserPrincipalName -like "*.local"')
        Write-Host ("Users with .local UPN: {0}" -f $localUpn.Count) -ForegroundColor $(if($localUpn.Count){'Yellow'}else{'Green'})
    } catch { Write-Host "  (AD read skipped: $($_.Exception.Message))" -ForegroundColor Yellow }
} else {
    Write-Host "ActiveDirectory module not present — run on a domain-joined host with RSAT for AD-side flags." -ForegroundColor Yellow
}

Write-Host "`nBaseline captured. Next: EKHYBID-Validate.ps1, then EKHYBID-HealthCheck.ps1." -ForegroundColor Cyan
