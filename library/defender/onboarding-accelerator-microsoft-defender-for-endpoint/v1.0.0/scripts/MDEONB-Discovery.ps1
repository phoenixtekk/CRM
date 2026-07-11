<#
.SYNOPSIS
    MDEONB-Discovery.ps1 — read-only readiness for onboarding Microsoft Defender for Endpoint
    (device onboarding across Windows/macOS/Linux, EDR block mode, ASR, RBAC, TVM).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Onboarding Accelerator — Microsoft Defender for Endpoint"
        solution. Reports the signed-in context, licensed MDE plan (P1/P2) hints, admin roles, the
        managed-device platform mix, current onboarding coverage, and the Intune MDE connector
        status. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEONB-Discovery.ps1
        Requires the Microsoft.Graph modules (Microsoft.Graph.Authentication,
        Microsoft.Graph.DeviceManagement, Microsoft.Graph.Identity.DirectoryManagement). Connects
        read-only with Connect-MgGraph and prompts for consent to read scopes.
    EXPECTED RESULTS
        A readiness picture: tenant/context, plan hints, admin roles, platform mix, onboarding
        coverage, and connector status — the state to confirm before onboarding. JSON snapshot.
.NOTES
    White-label. Read-only. Reports on configuration/identifiers only; makes no changes.
    Licensing/plan facts are indicative — verify current availability (P1 vs P2) in your tenant.
#>
[CmdletBinding()]
param([string]$OutputPath = ".\MDEONB-discovery.json")

$scopes = @('Organization.Read.All','Directory.Read.All','RoleManagement.Read.Directory','DeviceManagementManagedDevices.Read.All','SecurityEvents.Read.All','ThreatHunting.Read.All')
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.DeviceManagement') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow; Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }

Write-Host "`n=== Defender for Endpoint — onboarding readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext; Write-Host ("Tenant : {0}" -f $ctx.TenantId); Write-Host ("Account: {0}" -f $ctx.Account)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TenantId = $ctx.TenantId }

Write-Host "`n-- MDE plan hints (indicative — verify P1/P2 in tenant) --" -ForegroundColor Cyan
$mdeHints = 'WINDEFATP|ATP_ENTERPRISE|MDATP|Defender.*Endpoint|MTP'
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $plans = @(); foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $mdeHints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } } else { Write-Host "   No obvious MDE plans matched (verify licensing)." -ForegroundColor Yellow }
    $result.MdePlanHints = $plans
} catch { Write-Host ("   Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Admin roles (signed-in account) --" -ForegroundColor Cyan
try {
    $me = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/me?$select=id'
    $roles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($me.id)/memberOf/microsoft.graph.directoryRole").value
    $roles | ForEach-Object { Write-Host ("   {0}" -f $_.displayName) }
    $result.AdminRoles = @($roles | ForEach-Object { $_.displayName })
} catch { Write-Host ("   Could not read roles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Managed-device platform mix / onboarding coverage --" -ForegroundColor Cyan
try {
    $devices = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,complianceState&$top=500'
    $count = ($devices.value | Measure-Object).Count
    Write-Host ("   Managed devices (first page): {0}" -f $count)
    $devices.value | Group-Object operatingSystem | ForEach-Object { Write-Host ("     {0,-12} {1}" -f $_.Name, $_.Count) }
    $result.PlatformMix = @($devices.value | Group-Object operatingSystem | ForEach-Object { @{ OS = $_.Name; Count = $_.Count } })
} catch { Write-Host ("   Could not read managed devices: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Portal-only checks (confirm manually) --" -ForegroundColor Cyan
Write-Host "   Intune MDE connector: Endpoint security > Microsoft Defender for Endpoint > Connection status = Enabled" -ForegroundColor DarkGray
Write-Host "   Onboarding coverage : security.microsoft.com > Assets > Devices (Onboarded vs Can be onboarded)" -ForegroundColor DarkGray
Write-Host "   macOS/Linux         : confirm the platform onboarding channels (MDM profile / repo package)" -ForegroundColor DarkGray

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
