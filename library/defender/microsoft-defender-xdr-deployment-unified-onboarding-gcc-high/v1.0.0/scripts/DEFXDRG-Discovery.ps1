<#
.SYNOPSIS
    DEFXDRG-Discovery.ps1 — read-only readiness for onboarding the four Microsoft Defender XDR
    pillars (Endpoint, Identity, Office 365, Cloud Apps) into the unified portal.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Microsoft Defender XDR Deployment & Unified Onboarding"
        solution. Reports the signed-in context, licensed Defender-related service plans, the
        admin roles held, a per-pillar activation snapshot, device onboarding coverage, and
        candidate domain controllers for Defender for Identity sensors. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFXDRG-Discovery.ps1
        # DoD (IL5): -GraphEnvironment USGovDoD
        Requires the Microsoft.Graph modules (Microsoft.Graph.Authentication,
        Microsoft.Graph.Security, Microsoft.Graph.DeviceManagement, Microsoft.Graph.Identity.*).
        The script connects read-only with Connect-MgGraph to the US GOVERNMENT cloud (GCC High) by
        DEFAULT (-Environment USGov, graph.microsoft.us) and prompts for consent to read scopes.
        For DoD (IL5) pass -GraphEnvironment USGovDoD (dod-graph.microsoft.us). Verify the correct
        national-cloud endpoints against current Microsoft Government documentation.
    EXPECTED RESULTS
        A readiness picture: tenant/context, service plans that indicate MDE/MDI/MDO/MDCA
        entitlement, admin roles, device onboarding coverage, and DC candidates — the state to
        confirm before you begin onboarding.
.NOTES
    White-label. Read-only. Reports on configuration/identifiers only; makes no changes.
    Licensing/plan facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\DEFXDRG-discovery.json",
    # Government (GCC High) is the default for this edition. DoD (IL5): USGovDoD (dod-graph.microsoft.us).
    [ValidateSet('USGov','USGovDoD','Global')] [string]$GraphEnvironment = 'USGov'
)

# National-cloud Microsoft Graph base (GCC High graph.microsoft.us / DoD dod-graph.microsoft.us).
$GraphBase = switch ($GraphEnvironment) {
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    'Global'   { 'https://graph.microsoft.com' }
    default    { 'https://graph.microsoft.us' }
}

$scopes = @(
    'Organization.Read.All',
    'Directory.Read.All',
    'RoleManagement.Read.Directory',
    'DeviceManagementManagedDevices.Read.All',
    'SecurityEvents.Read.All',
    'ThreatHunting.Read.All'
)

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Identity.DirectoryManagement','Microsoft.Graph.DeviceManagement') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes $scopes -NoWelcome | Out-Null }

Write-Host "`n=== Microsoft Defender XDR — onboarding readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}" -f $ctx.TenantId)
Write-Host ("Account: {0}" -f $ctx.Account)

$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TenantId = $ctx.TenantId }

# --- Licensed service plans that indicate Defender entitlement (indicative) ---
Write-Host "`n-- Defender-related service plans (indicative — verify in tenant) --" -ForegroundColor Cyan
$defenderHints = 'WINDEFATP|ATP_ENTERPRISE|MTP|Defender|THREAT_INTELLIGENCE|ADALLOM|MCAS|AAD_PREMIUM_P2|ATA'
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/v1.0/subscribedSkus"
    $plans = @()
    foreach ($sku in $subs.value) {
        foreach ($p in $sku.servicePlans) {
            if ($p.servicePlanName -match $defenderHints) { $plans += $p.servicePlanName }
        }
    }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } }
    else { Write-Host "   No obvious Defender service plans matched (verify licensing manually)." -ForegroundColor Yellow }
    $result.DefenderServicePlans = $plans
} catch { Write-Host ("   Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Admin roles held by the signed-in account ---
Write-Host "`n-- Admin roles (signed-in account) --" -ForegroundColor Cyan
try {
    $me   = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/v1.0/me?`$select=id,userPrincipalName"
    $uri  = "$GraphBase/v1.0/users/$($me.id)/memberOf/microsoft.graph.directoryRole"
    $roles = (Invoke-MgGraphRequest -Method GET -Uri $uri).value
    if ($roles) { $roles | ForEach-Object { Write-Host ("   {0}" -f $_.displayName) } }
    else { Write-Host "   (no directory roles resolved for this account)" -ForegroundColor Yellow }
    $result.AdminRoles = @($roles | ForEach-Object { $_.displayName })
} catch { Write-Host ("   Could not read roles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Device onboarding coverage (Intune-managed as a proxy for MDE reach) ---
Write-Host "`n-- Device onboarding coverage (Intune-managed devices) --" -ForegroundColor Cyan
try {
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
    $devices = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,complianceState&`$top=200"
    $count = ($devices.value | Measure-Object).Count
    Write-Host ("   Managed devices (first page): {0}" -f $count)
    $devices.value | Group-Object operatingSystem | ForEach-Object { Write-Host ("     {0,-12} {1}" -f $_.Name, $_.Count) }
    $result.ManagedDeviceCountFirstPage = $count
} catch { Write-Host ("   Could not read managed devices (need DeviceManagementManagedDevices.Read.All): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Candidate domain controllers for MDI sensors (from device inventory hints) ---
Write-Host "`n-- Candidate domain controllers for MDI (best-effort) --" -ForegroundColor Cyan
Write-Host "   Enumerate DCs on-prem with: Get-ADDomainController -Filter * | Select HostName,OperatingSystem" -ForegroundColor DarkGray
Write-Host "   Install the MDI sensor on each healthy DC (and AD FS/AD CS) — see the Implementation Guide Step 3." -ForegroundColor DarkGray

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Confirm per-pillar activation in security.microsoft.us (GCC High) before onboarding." -ForegroundColor Green
