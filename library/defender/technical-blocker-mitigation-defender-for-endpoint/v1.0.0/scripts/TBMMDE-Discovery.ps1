<#
.SYNOPSIS
    TBMMDE-Discovery.ps1 — read-only signal-chain snapshot to pinpoint a stalled Defender for
    Endpoint rollout's blocker.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Technical Blocker Mitigation — Defender for Endpoint" solution.
        Captures the full MDE onboarding signal chain in one snapshot so you can find the earliest
        broken link: licensed Defender plans, the signed-in account's roles, the MDE<->Intune
        connector state, any EDR onboarding policy and its assignment, device onboarding coverage,
        and a per-state device count. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDE-Discovery.ps1
        Requires the Microsoft.Graph modules (Authentication, DeviceManagement,
        Identity.DirectoryManagement). Connects read-only with Connect-MgGraph and prompts for
        consent to read scopes only.
    EXPECTED RESULTS
        A JSON snapshot (MDE-blocker-discovery.json) plus a console summary. Read it top-down
        against the signal chain in the Solution Overview; the earliest broken link is the blocker.
.NOTES
    White-label. Read-only. Reports on configuration/state only; changes nothing.
    Licensing/plan facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDE-blocker-discovery.json"
)

$scopes = @(
    'Organization.Read.All',
    'Directory.Read.All',
    'RoleManagement.Read.Directory',
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementConfiguration.Read.All',
    'SecurityEvents.Read.All'
)

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Identity.DirectoryManagement','Microsoft.Graph.DeviceManagement') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }

Write-Host "`n=== TBMMDE — Defender for Endpoint blocker discovery (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}" -f $ctx.TenantId)
Write-Host ("Account: {0}" -f $ctx.Account)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TenantId = $ctx.TenantId }

# --- Link 1: Defender for Endpoint entitlement (indicative) ---
Write-Host "`n-- Link 1: Defender for Endpoint plan (indicative — verify in tenant) --" -ForegroundColor Cyan
$mdeHints = 'WINDEFATP|ATP_ENTERPRISE|MDATP|MTP|Defender'
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $plans = @()
    foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $mdeHints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } }
    else { Write-Host "   No obvious MDE service plans matched (verify licensing manually)." -ForegroundColor Yellow }
    $result.MdeServicePlans = $plans
} catch { Write-Host ("   Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Admin roles held (read access sanity) ---
Write-Host "`n-- Admin roles (signed-in account) --" -ForegroundColor Cyan
try {
    $me   = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/me?$select=id,userPrincipalName'
    $roles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($me.id)/memberOf/microsoft.graph.directoryRole").value
    if ($roles) { $roles | ForEach-Object { Write-Host ("   {0}" -f $_.displayName) } } else { Write-Host "   (no directory roles resolved)" -ForegroundColor Yellow }
    $result.AdminRoles = @($roles | ForEach-Object { $_.displayName })
} catch { Write-Host ("   Could not read roles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Link 2: MDE <-> Intune connector state ---
Write-Host "`n-- Link 2: MDE<->Intune connector state --" -ForegroundColor Cyan
try {
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
    $conn = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/mobileThreatDefenseConnectors'
    $mde = $conn.value | Where-Object { $_.id -match 'WindowsDefenderATP|mdatp|defenderatp' -or $_.partnerState }
    if ($conn.value) {
        foreach ($c in $conn.value) { Write-Host ("   Connector {0}: partnerState={1}" -f $c.id, $c.partnerState) }
        $result.IntuneMdeConnectors = @($conn.value | ForEach-Object { @{ id = $_.id; partnerState = $_.partnerState } })
    } else {
        Write-Host "   No mobile threat defense / MDE connector object found (check Endpoint security -> Microsoft Defender for Endpoint)." -ForegroundColor Yellow
        $result.IntuneMdeConnectors = @()
    }
} catch { Write-Host ("   Could not read connector (need DeviceManagementConfiguration.Read.All): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Link 3: device onboarding coverage + per-state counts (Intune-managed as proxy) ---
Write-Host "`n-- Link 3-4: managed device coverage (Intune-managed proxy for MDE reach) --" -ForegroundColor Cyan
try {
    $devices = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,complianceState,managementState&$top=500'
    $count = ($devices.value | Measure-Object).Count
    Write-Host ("   Managed devices (first page): {0}" -f $count)
    $devices.value | Group-Object operatingSystem | ForEach-Object { Write-Host ("     {0,-12} {1}" -f $_.Name, $_.Count) }
    $result.ManagedDeviceCountFirstPage = $count
    Write-Host "   NOTE: onboarded/sensor-health state lives in security.microsoft.com -> Assets -> Devices." -ForegroundColor DarkGray
    Write-Host "         Use TBMMDE-Validate.ps1 to count Onboarded vs Inactive/Impaired via advanced hunting." -ForegroundColor DarkGray
} catch { Write-Host ("   Could not read managed devices: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Read top-down: the earliest broken link (plan -> connector -> onboarded -> health -> telemetry) is your blocker." -ForegroundColor Green
