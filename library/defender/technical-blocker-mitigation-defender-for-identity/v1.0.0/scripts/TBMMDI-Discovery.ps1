<#
.SYNOPSIS
    TBMMDI-Discovery.ps1 — read-only cloud-side snapshot to pinpoint a stalled Defender for Identity
    rollout's blocker.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Technical Blocker Mitigation — Defender for Identity" solution.
        Captures the cloud side of the MDI signal chain: the licensed MDI plan (indicative), whether
        identity signal is arriving (IdentityInfo / IdentityLogonEvents presence), and identity-query
        signal (IdentityQueryEvents) as a proxy for a working Directory Service Account. Pair it with
        TBMMDI-AuditPolicy.ps1 run ON the affected DC for the on-prem links. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDI-Discovery.ps1
        Requires the Microsoft.Graph modules. Connects read-only with Connect-MgGraph and prompts for
        consent to read scopes only.
    EXPECTED RESULTS
        A JSON snapshot (MDI-blocker-discovery.json) plus a console summary. Read it with the DC audit
        output top-down against the signal chain; the earliest broken link is the blocker.
.NOTES
    White-label. Read-only. Reports on state/telemetry only; changes nothing.
    Sensor health and DSA config live in security.microsoft.com -> Settings -> Identities (portal).
    Licensing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDI-blocker-discovery.json",
    [int]$LookbackHours = 24
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Organization.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Count-Table([string]$table) {
    try { $r = Invoke-Hunt "$table | where Timestamp > ago(${LookbackHours}h) | summarize c=count()"; if ($r.results -and $r.results.Count -gt 0) { return [int]$r.results[0].c } } catch { }
    return -1
}

Write-Host "`n=== TBMMDI — Defender for Identity blocker discovery (read-only) ===" -ForegroundColor Cyan
$ctx = Get-MgContext
Write-Host ("Tenant : {0}`nAccount: {1}" -f $ctx.TenantId, $ctx.Account)
$result = [ordered]@{ Timestamp=(Get-Date).ToString('s'); TenantId=$ctx.TenantId; LookbackHours=$LookbackHours }

# --- Link 1: MDI plan (indicative) ---
Write-Host "`n-- Link 1: MDI plan (indicative — verify in tenant) --" -ForegroundColor Cyan
try {
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $hints = 'ATA|AATP|Defender.*Identity|IDENTITY_THREAT'
    $plans = @()
    foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $hints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } } else { Write-Host "   No obvious MDI plan matched (verify licensing manually)." -ForegroundColor Yellow }
    $result.MdiServicePlans = $plans
} catch { Write-Host ("   Could not read plans: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Links 2/5: identity signal presence (sensor + events) ---
Write-Host "`n-- Links 2/5: identity signal presence (sensor + events) --" -ForegroundColor Cyan
$idInfo   = Count-Table 'IdentityInfo'
$idLogon  = Count-Table 'IdentityLogonEvents'
$idDir    = Count-Table 'IdentityDirectoryEvents'
Write-Host ("   IdentityInfo rows            : {0}" -f $idInfo)
Write-Host ("   IdentityLogonEvents rows     : {0}" -f $idLogon)
Write-Host ("   IdentityDirectoryEvents rows : {0}" -f $idDir)
$result.IdentityInfoRows = $idInfo; $result.IdentityLogonRows = $idLogon; $result.IdentityDirectoryRows = $idDir

# --- Link 3: DSA proxy (query signal) ---
Write-Host "`n-- Link 3: DSA working proxy (IdentityQueryEvents) --" -ForegroundColor Cyan
$idQuery = Count-Table 'IdentityQueryEvents'
Write-Host ("   IdentityQueryEvents rows     : {0}" -f $idQuery)
if ($idQuery -le 0) { Write-Host "   No AD-query signal — DSA may be missing/under-permissioned (confirm in portal)." -ForegroundColor Yellow }
$result.IdentityQueryRows = $idQuery

Write-Host "`n   Sensor health + DSA config are authoritative in security.microsoft.com -> Settings -> Identities." -ForegroundColor DarkGray
Write-Host "   Run TBMMDI-AuditPolicy.ps1 ON the affected DC for the on-prem audit/NNR links." -ForegroundColor DarkGray

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Earliest broken link (plan -> sensor -> DSA -> traffic/NNR -> events) is your blocker." -ForegroundColor Green
