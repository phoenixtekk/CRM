<#
.SYNOPSIS
    TBMMDO-Discovery.ps1 — read-only evaluation-chain snapshot to pinpoint a stalled Defender for
    Office 365 rollout's blocker.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Technical Blocker Mitigation — Defender for Office 365" solution.
        Captures the MDO evaluation chain in one snapshot so you can find the earliest broken link:
        licensed MDO plans, accepted domains, preset-security-policy state, and the custom Safe Links /
        Safe Attachments / anti-phishing policies with their PRIORITY order, ENABLE state, and recipient
        SCOPE (inclusions/exclusions). Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDO-Discovery.ps1
        Requires the ExchangeOnlineManagement module (v3+) and a View-Only Exchange / Reader role.
        Connects with Connect-ExchangeOnline (read-only cmdlets only). Graph is used only to read
        licensed plans.
    EXPECTED RESULTS
        A JSON snapshot (MDO-blocker-discovery.json) plus a console summary. Read it top-down against
        the evaluation chain in the Solution Overview; the earliest broken link is the blocker.
.NOTES
    White-label. Read-only — uses Get-* cmdlets only; changes no policy or mail flow.
    Licensing/plan facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDO-blocker-discovery.json"
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement (one-time)..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Get-AcceptedDomain -ErrorAction Stop | Out-Null } catch { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }

Write-Host "`n=== TBMMDO — Defender for Office 365 blocker discovery (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

# --- Link 1: MDO plan (indicative, via Graph) ---
Write-Host "`n-- Link 1: MDO plan (indicative — verify in tenant) --" -ForegroundColor Cyan
try {
    if (-not (Get-Module -ListAvailable Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome | Out-Null }
    $subs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'
    $mdoHints = 'ATP_ENTERPRISE|THREAT_INTELLIGENCE|MDO|Defender.*Office|EOP'
    $plans = @()
    foreach ($sku in $subs.value) { foreach ($p in $sku.servicePlans) { if ($p.servicePlanName -match $mdoHints) { $plans += $p.servicePlanName } } }
    $plans = $plans | Sort-Object -Unique
    if ($plans) { $plans | ForEach-Object { Write-Host ("   {0}" -f $_) -ForegroundColor Green } } else { Write-Host "   No obvious MDO plan matched (verify licensing manually)." -ForegroundColor Yellow }
    $result.MdoServicePlans = $plans
} catch { Write-Host ("   Could not read plans via Graph: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Link 2: accepted domains (routing anchor) ---
Write-Host "`n-- Link 2: accepted domains --" -ForegroundColor Cyan
try {
    $ad = Get-AcceptedDomain | Select-Object DomainName, DomainType, Default
    $ad | ForEach-Object { Write-Host ("   {0,-30} {1} {2}" -f $_.DomainName, $_.DomainType, $(if($_.Default){'(default)'}else{''})) }
    $result.AcceptedDomains = @($ad | ForEach-Object { @{ Domain=$_.DomainName; Type="$($_.DomainType)"; Default=[bool]$_.Default } })
} catch { Write-Host ("   Could not read accepted domains: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Link 3: preset security policies ---
Write-Host "`n-- Link 3: preset security policies --" -ForegroundColor Cyan
try {
    $preset = Get-EOPProtectionPolicyRule -ErrorAction SilentlyContinue
    $presetAtp = Get-ATPProtectionPolicyRule -ErrorAction SilentlyContinue
    Write-Host ("   EOP preset rules: {0}   ATP preset rules: {1}" -f (($preset|Measure-Object).Count), (($presetAtp|Measure-Object).Count))
    $result.PresetPolicies = @{ EOP = @($preset | ForEach-Object { @{ Name=$_.Name; State="$($_.State)" } }); ATP = @($presetAtp | ForEach-Object { @{ Name=$_.Name; State="$($_.State)" } }) }
} catch { Write-Host ("   Could not read preset policies: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Link 4: custom Safe Links / Safe Attachments / anti-phish with priority, state, scope ---
Write-Host "`n-- Link 4: custom policy inventory (priority / state / scope) --" -ForegroundColor Cyan
function Dump-Rules($rules, $label) {
    $out = @()
    foreach ($r in $rules) {
        Write-Host ("   [{0}] pri={1,-3} state={2,-8} name={3}" -f $label, $r.Priority, $r.State, $r.Name)
        $out += [ordered]@{ Type=$label; Name=$r.Name; Priority=$r.Priority; State="$($r.State)"; SentTo=$r.SentTo; SentToMemberOf=$r.SentToMemberOf; ExceptIfSentTo=$r.ExceptIfSentTo }
    }
    return $out
}
try {
    $result.SafeLinksRules      = Dump-Rules (Get-SafeLinksRule -ErrorAction SilentlyContinue)      'SafeLinks'
    $result.SafeAttachmentRules = Dump-Rules (Get-SafeAttachmentRule -ErrorAction SilentlyContinue) 'SafeAttachments'
    $result.AntiPhishRules      = Dump-Rules (Get-AntiPhishRule -ErrorAction SilentlyContinue)       'AntiPhish'
} catch { Write-Host ("   Could not read custom policy rules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Read top-down: plan -> routing -> precedence -> feature scope. The earliest broken link is your blocker." -ForegroundColor Green
Write-Host "NOTE: only the SINGLE highest-priority policy of each type applies per recipient (preset over custom)." -ForegroundColor DarkGray
