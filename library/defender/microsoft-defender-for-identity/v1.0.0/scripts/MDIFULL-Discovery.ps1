<#
.SYNOPSIS
    MDIFULL-Discovery.ps1 — read-only readiness for the complete Microsoft Defender for Identity
    lifecycle (deploy the sensors, enable the team, prove the value).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Microsoft Defender for Identity" solution. Reports the signed-in
        context, licensed Defender-for-Identity plan hints, the admin roles held, every domain
        controller (and AD FS/AD CS candidate) with its OS, Directory Service Account readiness,
        existing sensor health, and candidate no-activity accounts you could designate as honeytokens.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Discovery.ps1
        Requires the Microsoft.Graph modules (Microsoft.Graph.Authentication,
        Microsoft.Graph.Identity.DirectoryManagement). The AD inventory portion uses the RSAT
        ActiveDirectory module and should run from a domain-joined host. Connects read-only with
        Connect-MgGraph and prompts for consent to read scopes.
    EXPECTED RESULTS
        A readiness picture — tenant/context, plan hints that indicate MDI entitlement, admin roles,
        the domain-controller inventory to sensor, DSA notes, sensor health, and honeytoken
        candidates — the state to confirm before you begin. Written to a JSON snapshot.
.NOTES
    White-label. Read-only. Reports on configuration/identifiers only; makes no changes.
    Licensing/plan facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDIFULL-discovery.json"
)

$scopes = @(
    'Organization.Read.All',
    'Directory.Read.All',
    'RoleManagement.Read.Directory',
    'AuditLog.Read.All',
    'SecurityEvents.Read.All',
    'ThreatHunting.Read.All'
)

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Identity.DirectoryManagement') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }

Write-Host "`n=== Defender for Identity — lifecycle readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}" -f $ctx.TenantId)
Write-Host ("Account: {0}" -f $ctx.Account)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TenantId = $ctx.TenantId }

# --- Licensed service plans that indicate MDI entitlement (indicative) ---
Write-Host "`n-- Defender-for-Identity plan hints (indicative — verify in tenant) --" -ForegroundColor Cyan
$mdiHints = 'ATA|Defender.*Identity|MDI|AAD_PREMIUM_P2|MTP'
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $plans = @()
    foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $mdiHints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } }
    else { Write-Host "   No obvious MDI service plans matched (verify licensing manually)." -ForegroundColor Yellow }
    $result.MdiPlanHints = $plans
} catch { Write-Host ("   Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Admin roles held by the signed-in account ---
Write-Host "`n-- Admin roles (signed-in account) --" -ForegroundColor Cyan
try {
    $me   = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/me?$select=id,userPrincipalName'
    $roles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($me.id)/memberOf/microsoft.graph.directoryRole").value
    if ($roles) { $roles | ForEach-Object { Write-Host ("   {0}" -f $_.displayName) } } else { Write-Host "   (no directory roles resolved)" -ForegroundColor Yellow }
    $result.AdminRoles = @($roles | ForEach-Object { $_.displayName })
} catch { Write-Host ("   Could not read roles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Domain controllers / AD FS / AD CS to sensor (on-prem, best-effort) ---
Write-Host "`n-- Domain controllers to sensor (from Active Directory) --" -ForegroundColor Cyan
$dcs = @()
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $dcs = Get-ADDomainController -Filter * | Select-Object HostName, OperatingSystem, Site, IPv4Address
        foreach ($dc in $dcs) { Write-Host ("   {0,-40} {1}" -f $dc.HostName, $dc.OperatingSystem) }
        Write-Host ("   Total domain controllers: {0}" -f ($dcs | Measure-Object).Count) -ForegroundColor Green
        Write-Host "   NOTE: also inventory AD FS and AD CS servers — they carry MDI sensors too." -ForegroundColor DarkGray
    } catch { Write-Host ("   AD query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
} else {
    Write-Host "   ActiveDirectory module not present. Run from a domain-joined host with RSAT:" -ForegroundColor Yellow
    Write-Host "   Get-ADDomainController -Filter * | Select HostName,OperatingSystem,Site" -ForegroundColor DarkGray
}
$result.DomainControllers = @($dcs | ForEach-Object { @{ Host = $_.HostName; OS = $_.OperatingSystem; Site = $_.Site } })

# --- Directory Service Account (DSA) note ---
Write-Host "`n-- Directory Service Account (DSA) --" -ForegroundColor Cyan
Write-Host "   Prepare a read-only gMSA 'MDI Directory Service Account - Tenant - Prod' and register it under" -ForegroundColor DarkGray
Write-Host "   Settings > Identities > Directory Service accounts (Implementation Step 2). Verify current MDI DSA requirements." -ForegroundColor DarkGray

# --- Existing sensor health (best-effort) ---
Write-Host "`n-- Existing MDI sensors --" -ForegroundColor Cyan
try {
    $sensors = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/identities/sensors' -ErrorAction Stop).value
    if ($sensors) {
        foreach ($s in $sensors) { Write-Host ("   {0,-40} health={1}" -f $s.displayName, $s.healthStatus) }
        $healthy = @($sensors | Where-Object { $_.healthStatus -eq 'healthy' }).Count
        Write-Host ("   Sensors: {0}  Healthy: {1}" -f ($sensors | Measure-Object).Count, $healthy) -ForegroundColor Green
        $result.SensorCount = ($sensors | Measure-Object).Count; $result.HealthySensors = $healthy
    } else { Write-Host "   No sensors returned — confirm in Settings > Identities > Sensors (or MDI not yet activated)." -ForegroundColor Yellow }
} catch { Write-Host "   Sensor API read unavailable — confirm in Settings > Identities > Sensors." -ForegroundColor Yellow }

# --- Candidate honeytoken accounts (no recent sign-in; read-only) ---
Write-Host "`n-- Candidate honeytoken accounts (dormant / no sign-in — read-only) --" -ForegroundColor Cyan
try {
    $users = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users?`$select=userPrincipalName,accountEnabled,signInActivity&`$top=200").value
    $cands = $users | Where-Object { $_.accountEnabled -and (-not $_.signInActivity -or -not $_.signInActivity.lastSignInDateTime) } | Select-Object -First 15
    if ($cands) { $cands | ForEach-Object { Write-Host ("   {0}" -f $_.userPrincipalName) -ForegroundColor Gray } }
    else { Write-Host "   No clear no-sign-in candidates (signInActivity needs Entra ID P1/P2 + AuditLog.Read.All)." -ForegroundColor Yellow }
    Write-Host "   Facilitator PICKS a genuinely dormant decoy — this list is a hint; nothing is tagged here." -ForegroundColor DarkGray
    $result.HoneytokenCandidates = @($cands | ForEach-Object { $_.userPrincipalName })
} catch { Write-Host ("   Could not read users: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Confirm MDI activation in security.microsoft.com > Settings > Identities before deploying." -ForegroundColor Green
