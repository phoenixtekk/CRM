<#
.SYNOPSIS
    EKHYBID-HealthCheck.ps1 — Read-only hybrid-identity health check (the health-check lab routine).
.DESCRIPTION
    PURPOSE
        The routine from the health-check lab: report the signals that catch a drifting hybrid setup
        before users do — directory-sync enabled, last sync time within a threshold, federated-domain
        count, PTA / Seamless SSO hints, and UPN-hygiene issues. Prints OK / ATTENTION per signal.
    HOW TO RUN
        .\EKHYBID-HealthCheck.ps1 -MaxSyncAgeMinutes 120
        Sign in when prompted (read-only scopes). No changes are made. Optionally run on the Entra
        Connect host to also read local sync scheduler status (read-only).
    EXPECTED RESULTS
        A per-signal health list with an overall verdict. Nothing is modified.
.NOTES
    White-label. Read-only.
#>
[CmdletBinding()] param(
    [int]$MaxSyncAgeMinutes = 120
)

$ErrorActionPreference = 'Stop'
$attention = 0
function Signal($ok,$msg){ if($ok){Write-Host "  OK         $msg" -ForegroundColor Green}else{Write-Host "  ATTENTION  $msg" -ForegroundColor Yellow; $script:attention++} }

Write-Host "`n=== Hybrid Identity — Health Check (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'Directory.Read.All','Domain.Read.All','Organization.Read.All' -NoWelcome } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Red; return }

# Sync enabled + last sync age
try {
    $org = Get-MgOrganization
    Signal ($org.OnPremisesSyncEnabled -eq $true) ("Directory synchronization enabled")
    if ($org.OnPremisesLastSyncDateTime) {
        $age = (New-TimeSpan -Start $org.OnPremisesLastSyncDateTime -End (Get-Date).ToUniversalTime()).TotalMinutes
        Signal ($age -le $MaxSyncAgeMinutes) ("Last sync {0:n0} min ago (threshold {1})" -f $age, $MaxSyncAgeMinutes)
    } else { Signal $false "No last-sync timestamp (sync may never have run)" }
} catch { Signal $false "Could not read organization sync state: $($_.Exception.Message)" }

# Federated domains
try {
    $fed = @((Get-MgDomain -All) | Where-Object { $_.AuthenticationType -eq 'Federated' })
    Signal ($fed.Count -eq 0) ("Federated (AD FS) domains: {0}" -f $fed.Count)
} catch { Signal $false "Could not read domains: $($_.Exception.Message)" }

# AD-side UPN hygiene (optional)
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $localUpn = @(Get-ADUser -Filter 'UserPrincipalName -like "*.local"').Count
        Signal ($localUpn -eq 0) ("AD users with non-routable .local UPN: {0}" -f $localUpn)
    } catch { Write-Host "  INFO       AD UPN check skipped: $($_.Exception.Message)" -ForegroundColor Cyan }
} else { Write-Host "  INFO       ActiveDirectory module absent — .local UPN check skipped (run on a domain-joined host)." -ForegroundColor Cyan }

# Local Connect Sync scheduler (only if run on the Connect host)
if (Get-Module -ListAvailable -Name ADSync) {
    try {
        Import-Module ADSync -ErrorAction Stop
        $sch = Get-ADSyncScheduler
        Signal ($sch.SyncCycleEnabled -eq $true) ("Connect Sync cycle enabled (staging mode: {0})" -f $sch.StagingModeEnabled)
    } catch { Write-Host "  INFO       ADSync present but not readable: $($_.Exception.Message)" -ForegroundColor Cyan }
} else { Write-Host "  INFO       Not on the Entra Connect host (ADSync module absent) — local scheduler status skipped." -ForegroundColor Cyan }

Write-Host ""
if ($attention -eq 0) { Write-Host "Hybrid health: no attention items." -ForegroundColor Green }
else { Write-Host "Hybrid health: $attention signal(s) need attention (see 06-troubleshooting.md; remediate in HYBID)." -ForegroundColor Yellow }
