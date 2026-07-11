<#
.SYNOPSIS
    TBMMDO-MailFlow.ps1 — read-only mail-routing analysis to spot a Defender for Office 365 routing
    conflict (mail bypassing EOP).
.DESCRIPTION
    PURPOSE
        The top MDO blocker is inbound mail that does not reach Exchange Online Protection (EOP) first,
        so Safe Attachments / anti-phish never act. This script reports accepted domains, inbound
        connectors, and public MX resolution for each domain, and flags routing that could bypass
        filtering (a gateway in front of EOP, an inbound connector, or an MX that does not point to
        EOP). Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDO-MailFlow.ps1
        Requires the ExchangeOnlineManagement module (v3+) and a View-Only Exchange / Reader role.
    EXPECTED RESULTS
        A per-domain routing verdict (reaches EOP / possible bypass) and a connector inventory, written
        to MDO-mailflow.json. A possible-bypass verdict points the fix at routing, NOT at MDO policy.
.NOTES
    White-label. Read-only — Get-* and DNS lookups only; changes no mail flow.
    MX/EOP host patterns evolve — verify the current EOP MX target for your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDO-mailflow.json"
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Get-AcceptedDomain -ErrorAction Stop | Out-Null } catch { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }

Write-Host "`n=== TBMMDO — mail-routing analysis (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp=(Get-Date).ToString('s'); Domains=@(); InboundConnectors=@() }

# --- Inbound connectors (a connector can route mail past filtering) ---
Write-Host "`n-- Inbound connectors --" -ForegroundColor Cyan
try {
    $conn = Get-InboundConnector -ErrorAction SilentlyContinue
    if ($conn) { $conn | ForEach-Object { Write-Host ("   {0}  enabled={1}  type={2}" -f $_.Name, $_.Enabled, $_.ConnectorType) } }
    else { Write-Host "   (none — direct MX->EOP is the likely path)" -ForegroundColor DarkGray }
    $result.InboundConnectors = @($conn | ForEach-Object { @{ Name=$_.Name; Enabled=[bool]$_.Enabled; Type="$($_.ConnectorType)"; SenderDomains=$_.SenderDomains } })
} catch { Write-Host ("   Could not read inbound connectors: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Per-domain MX resolution vs EOP ---
Write-Host "`n-- Domain MX vs EOP --" -ForegroundColor Cyan
try {
    $domains = Get-AcceptedDomain | Select-Object -ExpandProperty DomainName
    foreach ($d in $domains) {
        $verdict = 'UNKNOWN'; $mx = @()
        try {
            $mx = (Resolve-DnsName -Name $d -Type MX -ErrorAction Stop | Sort-Object Preference | ForEach-Object { $_.NameExchange })
            if ($mx -match 'mail\.protection\.outlook\.com') { $verdict = 'REACHES_EOP' }
            elseif ($mx.Count -gt 0) { $verdict = 'POSSIBLE_BYPASS (MX not EOP — verify a gateway forwards to EOP)' }
        } catch { $verdict = 'MX_LOOKUP_FAILED' }
        $color = if ($verdict -eq 'REACHES_EOP') { 'Green' } elseif ($verdict -like 'POSSIBLE_BYPASS*') { 'Yellow' } else { 'DarkGray' }
        Write-Host ("   {0,-30} {1}" -f $d, $verdict) -ForegroundColor $color
        $result.Domains += [ordered]@{ Domain=$d; MX=@($mx); Verdict=$verdict }
    }
} catch { Write-Host ("   Could not enumerate domains: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

$anyBypass = @($result.Domains | Where-Object { $_.Verdict -like 'POSSIBLE_BYPASS*' }).Count
Write-Host ("`nRouting verdict: {0} domain(s) may bypass EOP." -f $anyBypass) -ForegroundColor ($(if ($anyBypass -eq 0) { 'Green' } else { 'Yellow' }))
if ($anyBypass -gt 0) { Write-Host "Fix belongs to mail routing (MX/connector/gateway), not MDO policy. See Troubleshooting 'Mail bypasses filtering'." -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Mail-flow snapshot: {0}" -f $OutputPath) -ForegroundColor Green
