<#
.SYNOPSIS
    MDCAFULL-Discovery.ps1 — read-only readiness for Microsoft Defender for Cloud Apps
    (app connectors, Cloud Discovery source, app governance, session/access prerequisites, alerts).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the complete "Microsoft Defender for Cloud Apps" solution. Reports
        the signed-in context, licensed MDCA plan hints, admin roles, Conditional Access availability
        (for App Control), the MDCA alert count, and prints the portal paths for the connector /
        discovery / app-governance checks that are portal-only. Makes no changes. Use before Phase A
        onboarding and as the Lab 0 / PoC readiness check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-Discovery.ps1
        Requires the Microsoft.Graph modules (Authentication + Identity.SignIns for CA read).
        Connects read-only with Connect-MgGraph.
    EXPECTED RESULTS
        A readiness picture written to a JSON snapshot: tenant/context, MDCA plan hints, admin roles,
        CA availability, alert count — the state to confirm before onboarding, enabling, or a PoC.
.NOTES
    White-label. Read-only. Some MDCA settings surface through the portal only — the script prints
    the exact portal path where an API read is unavailable. Licensing facts are indicative — verify.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDCAFULL-discovery.json"
)

$scopes = @('Organization.Read.All','Directory.Read.All','RoleManagement.Read.Directory','Policy.Read.All','SecurityEvents.Read.All')
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Identity.SignIns') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null }

Write-Host "`n=== Defender for Cloud Apps — readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}" -f $ctx.TenantId); Write-Host ("Account: {0}" -f $ctx.Account)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TenantId = $ctx.TenantId }

Write-Host "`n-- MDCA plan hints (indicative — verify in tenant) --" -ForegroundColor Cyan
$mcaHints = 'ADALLOM|MCAS|Defender.*Cloud.*App|MDA_|MTP'
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $plans = @(); foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $mcaHints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } } else { Write-Host "   No obvious MDCA plans matched (verify licensing)." -ForegroundColor Yellow }
    $result.McaPlanHints = $plans
} catch { Write-Host ("   Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Admin roles (signed-in account) --" -ForegroundColor Cyan
try {
    $me = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/me?$select=id'
    $roles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($me.id)/memberOf/microsoft.graph.directoryRole").value
    $roles | ForEach-Object { Write-Host ("   {0}" -f $_.displayName) }
    $result.AdminRoles = @($roles | ForEach-Object { $_.displayName })
} catch { Write-Host ("   Could not read roles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Conditional Access availability (for App Control) --" -ForegroundColor Cyan
try {
    $ca = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?$top=5').value
    Write-Host ("   Conditional Access policies present: {0} (CA is available for App Control)" -f (($ca | Measure-Object).Count)) -ForegroundColor Green
    $result.ConditionalAccessAvailable = $true
} catch { Write-Host "   Could not read CA policies (need P1/P2 + Policy.Read.All). Verify CA availability." -ForegroundColor Yellow; $result.ConditionalAccessAvailable = $false }

Write-Host "`n-- MDCA alert signal (read-only) --" -ForegroundColor Cyan
try {
    $al = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=50&`$filter=serviceSource eq 'microsoftDefenderForCloudApps'").value
    Write-Host ("   Recent MDCA alerts (sample up to 50): {0}" -f (($al | Measure-Object).Count)) -ForegroundColor Green
    $result.McaAlertSample = (($al | Measure-Object).Count)
} catch { Write-Host ("   Could not read alerts_v2 (need SecurityEvents.Read.All): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Portal-only checks (confirm manually) --" -ForegroundColor Cyan
Write-Host "   App connectors : Cloud apps > Connected apps > App connectors (confirm Microsoft 365 + priority apps)" -ForegroundColor DarkGray
Write-Host "   Cloud Discovery: Cloud apps > Cloud discovery > Settings (MDE integration / log collector / SWG / sample log)" -ForegroundColor DarkGray
Write-Host "   App governance : Cloud apps > App governance (enabled? plan includes it? — verify)" -ForegroundColor DarkGray

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nReadiness complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
