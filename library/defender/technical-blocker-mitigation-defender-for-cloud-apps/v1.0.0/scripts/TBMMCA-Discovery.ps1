<#
.SYNOPSIS
    TBMMCA-Discovery.ps1 — read-only signal-chain snapshot to pinpoint a stalled Defender for Cloud
    Apps rollout's blocker.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Technical Blocker Mitigation — Defender for Cloud Apps" solution.
        Captures the MDCA signal chain: the licensed plan (indicative), whether cloud-app activity
        signal is arriving (CloudAppEvents presence — a proxy for working connectors), a device-based
        discovery hint (DeviceNetworkEvents presence), and a summary of Conditional Access policies that
        use App Control. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMCA-Discovery.ps1
        Requires the Microsoft.Graph modules. Connects read-only with Connect-MgGraph and prompts for
        consent to read scopes only (ThreatHunting.Read.All, Policy.Read.All, Organization.Read.All).
    EXPECTED RESULTS
        A JSON snapshot (MDCA-blocker-discovery.json) plus a console summary. Read it top-down against
        the signal chain; the earliest broken link is the blocker.
.NOTES
    White-label. Read-only. Reports on state/telemetry only; changes nothing.
    Connector status and Cloud Discovery dashboards are authoritative in security.microsoft.com.
    Licensing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDCA-blocker-discovery.json",
    [int]$LookbackHours = 24
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Policy.Read.All','Organization.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Count-Table([string]$table) {
    try { $r = Invoke-Hunt "$table | where Timestamp > ago(${LookbackHours}h) | summarize c=count()"; if ($r.results -and $r.results.Count -gt 0) { return [int]$r.results[0].c } } catch { }
    return -1
}

Write-Host "`n=== TBMMCA — Defender for Cloud Apps blocker discovery (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}`nAccount: {1}" -f $ctx.TenantId, $ctx.Account)
$result = [ordered]@{ Timestamp=(Get-Date).ToString('s'); TenantId=$ctx.TenantId; LookbackHours=$LookbackHours }

# --- Link 1: MDCA plan (indicative) ---
Write-Host "`n-- Link 1: MDCA plan (indicative — verify in tenant) --" -ForegroundColor Cyan
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $hints = 'ADALLOM|MCAS|Defender.*Cloud.*App|CLOUDAPP'
    $plans = @()
    foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $hints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } } else { Write-Host "   No obvious MDCA plan matched (verify licensing manually)." -ForegroundColor Yellow }
    $result.McaServicePlans = $plans
} catch { Write-Host ("   Could not read plans: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Link 2: connector/activity signal (CloudAppEvents) ---
Write-Host "`n-- Link 2: cloud-app activity signal (connector proxy) --" -ForegroundColor Cyan
$cae = Count-Table 'CloudAppEvents'
Write-Host ("   CloudAppEvents rows: {0}" -f $cae)
if ($cae -le 0) { Write-Host "   No activity signal — connectors may be disconnected (confirm in Cloud apps -> App connectors)." -ForegroundColor Yellow }
$result.CloudAppEventsRows = $cae

# --- Link 3: device-based discovery hint ---
Write-Host "`n-- Link 3: device-based discovery hint (DeviceNetworkEvents) --" -ForegroundColor Cyan
$dne = Count-Table 'DeviceNetworkEvents'
Write-Host ("   DeviceNetworkEvents rows: {0} (present => MDE integration can feed discovery)" -f $dne)
$result.DeviceNetworkEventsRows = $dne

# --- Link 4: Conditional Access App Control policy summary ---
Write-Host "`n-- Link 4: Conditional Access App Control policies --" -ForegroundColor Cyan
try {
    $pol = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
    $appControl = @()
    foreach ($p in $pol.value) {
        $sc = $p.sessionControls
        if ($sc -and $sc.cloudAppSecurity -and $sc.cloudAppSecurity.isEnabled) {
            Write-Host ("   [{0}] state={1}  type={2}" -f $p.displayName, $p.state, $sc.cloudAppSecurity.cloudAppSecurityType) -ForegroundColor Green
            $appControl += [ordered]@{ Name=$p.displayName; State=$p.state; Type=$sc.cloudAppSecurity.cloudAppSecurityType }
        }
    }
    if (-not $appControl) { Write-Host "   No CA policy with Conditional Access App Control found (session controls may not route to MDCA)." -ForegroundColor Yellow }
    $result.AppControlPolicies = $appControl
} catch { Write-Host ("   Could not read Conditional Access policies (need Policy.Read.All): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Earliest broken link (plan -> connector -> discovery -> session/CA App Control) is your blocker." -ForegroundColor Green
