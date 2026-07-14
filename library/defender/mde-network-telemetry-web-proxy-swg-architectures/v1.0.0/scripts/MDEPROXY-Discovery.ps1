<#
.SYNOPSIS
    MDEPROXY-Discovery.ps1 — read-only readiness for the Defender for Endpoint network-telemetry
    (web proxy / SWG) assessment: context, P2 hints, onboarded devices, and network-table freshness.
.DESCRIPTION
    PURPOSE
        Confirms the environment is ready to MEASURE proxy-induced network-telemetry obfuscation.
        Reports the signed-in context, indicative MDE plan (P1/P2) hints, the onboarded-device count,
        DeviceNetworkEvents freshness, and WHICH network Advanced Hunting tables are populated
        (DeviceNetworkEvents, DeviceEvents, DeviceInfo, DeviceProcessEvents). Lists the read-only
        portal/SWG checks to perform manually. Makes NO changes to the proxy, agent, or tenant.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEPROXY-Discovery.ps1
        Installs the Microsoft.Graph modules on first run. Connects read-only with Connect-MgGraph
        (scope ThreatHunting.Read.All + context scopes). Government cloud: pass -Environment.
    EXPECTED RESULTS
        A readiness snapshot (JSON) — tenant/context, plan hints, device count, table freshness, and
        the manual checks — confirming you can proceed to MDEPROXY-Validate.ps1. Read-only throughout.
.NOTES
    White-label. Read-only. Reports on configuration/telemetry only; changes nothing.
    Licensing/plan facts are indicative — verify current P1/P2 availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDEPROXY-discovery.json",
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global',
    [switch]$Sample
)

$scopes = @('Organization.Read.All','Directory.Read.All','SecurityEvents.Read.All','ThreatHunting.Read.All')
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -Environment $Environment -NoWelcome | Out-Null }

Write-Host "`n=== MDEPROXY — telemetry-assessment readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}" -f $ctx.TenantId); Write-Host ("Account: {0}" -f $ctx.Account)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); TenantId = $ctx.TenantId; ReadOnly = $true }

function Invoke-Hunt([string]$Query) {
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' `
        -Body (@{ Query = $Query } | ConvertTo-Json) -ContentType 'application/json'
}

Write-Host "`n-- MDE plan hints (indicative — verify P1/P2 in tenant) --" -ForegroundColor Cyan
$mdeHints = 'WINDEFATP|ATP_ENTERPRISE|MDATP|Defender.*Endpoint|MTP|TVM'
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $plans = @(); foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $mdeHints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } } else { Write-Host "   No obvious MDE plans matched (verify licensing — P2 needed for advanced hunting)." -ForegroundColor Yellow }
    $result.MdePlanHints = $plans
} catch { Write-Host ("   Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Onboarded devices (advanced hunting: DeviceInfo) --" -ForegroundColor Cyan
$devKql = @"
DeviceInfo
| where Timestamp > ago(1d)
| summarize arg_max(Timestamp, OnboardingStatus, OSPlatform) by DeviceId, DeviceName
| summarize Devices=count(), Onboarded=countif(OnboardingStatus == 'Onboarded')
"@
try {
    $d = Invoke-Hunt $devKql
    if ($d.results) { $d.results | ForEach-Object { Write-Host ("   Devices seen (24h): {0}   Onboarded: {1}" -f $_.Devices, $_.Onboarded) }; $result.DeviceSummary = $d.results }
    else { Write-Host "   No DeviceInfo rows in 24h — allow onboarding warm-up (R2)." -ForegroundColor Yellow }
} catch { Write-Host ("   DeviceInfo hunt failed ({0}). Confirm P2 + ThreatHunting.Read.All (R1/R3)." -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Network Advanced Hunting table population / freshness (24h) --" -ForegroundColor Cyan
$freshKql = @"
let since = ago(1d);
union
 (DeviceInfo          | where Timestamp > since | summarize Rows=count() | extend Table='DeviceInfo'),
 (DeviceNetworkEvents | where Timestamp > since | summarize Rows=count() | extend Table='DeviceNetworkEvents'),
 (DeviceProcessEvents | where Timestamp > since | summarize Rows=count() | extend Table='DeviceProcessEvents'),
 (DeviceEvents        | where Timestamp > since | summarize Rows=count() | extend Table='DeviceEvents')
| project Table, Rows
"@
try {
    $r = Invoke-Hunt $freshKql
    if ($r.results) {
        $r.results | ForEach-Object {
            $c = if ($_.Rows -gt 0) { 'Green' } else { 'Yellow' }
            Write-Host ("   {0,-22} {1} row(s) in 24h" -f $_.Table, $_.Rows) -ForegroundColor $c
        }
        $result.TableFreshness = $r.results
        $dne = ($r.results | Where-Object { $_.Table -eq 'DeviceNetworkEvents' }).Rows
        if (-not $dne -or $dne -eq 0) { Write-Host "   NOTE: DeviceNetworkEvents empty — cannot measure obfuscation yet (see Troubleshooting)." -ForegroundColor Red }
    } else { Write-Host "   No rows — allow warm-up before measuring." -ForegroundColor Yellow }
} catch { Write-Host ("   Freshness hunt unavailable ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

if ($Sample) {
    Write-Host "`n-- Device-sample helper (top talkers by DeviceNetworkEvents, to seed the ring) --" -ForegroundColor Cyan
    $sampleKql = @"
DeviceNetworkEvents
| where Timestamp > ago(1d)
| summarize Conns=count() by DeviceName
| top 15 by Conns desc
"@
    try {
        $s = Invoke-Hunt $sampleKql
        if ($s.results) { $s.results | ForEach-Object { Write-Host ("   {0,-32} {1} conn(s)/24h" -f $_.DeviceName, $_.Conns) }; $result.SampleCandidates = $s.results }
        else { Write-Host "   No connection rows to suggest a sample." -ForegroundColor Yellow }
    } catch { Write-Host ("   Sample hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Write-Host "`n-- Read-only checks to perform manually --" -ForegroundColor Cyan
Write-Host "   SWG steering mode  : from your endpoint/SWG config — 'netsh winhttp show proxy', the PAC URL," -ForegroundColor DarkGray
Write-Host "                        and the agent tunnel mode (route-based vs system-proxy/loopback) (Step 1.3)" -ForegroundColor DarkGray
Write-Host "   Proxy address set  : record loopback + local-listener + proxy IPs for classification (R5)" -ForegroundColor DarkGray
Write-Host "   Network Protection : security.microsoft.com > Settings > Endpoints > Advanced features (state only)" -ForegroundColor DarkGray
Write-Host "   Custom indicators  : Settings > Endpoints > Indicators (IP/URL/Domain inventory — read-only)" -ForegroundColor DarkGray

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
