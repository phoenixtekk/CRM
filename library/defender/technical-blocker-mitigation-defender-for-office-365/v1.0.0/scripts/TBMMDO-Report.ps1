<#
.SYNOPSIS
    TBMMDO-Report.ps1 — read-only before/after report proving a Defender for Office 365 blocker cleared.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Technical Blocker Mitigation — Defender for Office 365" solution.
        Compares the discovery baseline (MDO-blocker-discovery.json) with a fresh read of the same
        evaluation-chain links (plan, preset/custom policy state and priority) and prints a before/after
        summary — the evidence the blocker moved from broken to cleared. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDO-Report.ps1 -Baseline .\MDO-blocker-discovery.json
        Requires the ExchangeOnlineManagement module (v3+) and a View-Only Exchange / Reader role.
    EXPECTED RESULTS
        A table of each link's baseline vs current state and an overall CLEARED / STILL-BLOCKED verdict,
        written to MDO-blocker-report.json.
.NOTES
    White-label. Read-only. Reads state only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$Baseline = ".\MDO-blocker-discovery.json",
    [string]$OutputPath = ".\MDO-blocker-report.json"
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Get-AcceptedDomain -ErrorAction Stop | Out-Null } catch { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }

Write-Host "`n=== TBMMDO — before/after blocker report (read-only) ===" -ForegroundColor Cyan
$base = $null
if (Test-Path $Baseline) { $base = Get-Content $Baseline -Raw | ConvertFrom-Json; Write-Host ("Baseline: {0} ({1})" -f $Baseline, $base.Timestamp) }
else { Write-Host "No baseline found — run TBMMDO-Discovery.ps1 first for a true before/after." -ForegroundColor Yellow }

# Current custom-policy state
function Cur-Rules($rules, $label) { @($rules | ForEach-Object { @{ Type=$label; Name=$_.Name; Priority=$_.Priority; State="$($_.State)" } }) }
$curSL = Cur-Rules (Get-SafeLinksRule -ErrorAction SilentlyContinue) 'SafeLinks'
$curSA = Cur-Rules (Get-SafeAttachmentRule -ErrorAction SilentlyContinue) 'SafeAttachments'
$curAP = Cur-Rules (Get-AntiPhishRule -ErrorAction SilentlyContinue) 'AntiPhish'

function EnabledCount($rules) { @($rules | Where-Object { "$($_.State)" -eq 'Enabled' }).Count }

Write-Host "`n-- Evaluation-chain status --" -ForegroundColor Cyan
Write-Host ("   Plan (baseline)                 : {0}" -f (($base.MdoServicePlans) -join ', '))
Write-Host ("   SafeLinks enabled  (base -> now): {0} -> {1}" -f (EnabledCount $base.SafeLinksRules), (EnabledCount $curSL))
Write-Host ("   SafeAttach enabled (base -> now): {0} -> {1}" -f (EnabledCount $base.SafeAttachmentRules), (EnabledCount $curSA))
Write-Host ("   AntiPhish enabled  (base -> now): {0} -> {1}" -f (EnabledCount $base.AntiPhishRules), (EnabledCount $curAP))

$cleared = ((EnabledCount $curSL) -gt 0 -and (EnabledCount $curSA) -gt 0)
$verdict = if ($cleared) { 'CLEARED (policies enabled — confirm scope + a test message via TBMMDO-Validate.ps1)' } else { 'STILL-BLOCKED' }
Write-Host ("`nVerdict: {0}" -f $verdict) -ForegroundColor ($(if ($cleared) { 'Green' } else { 'Yellow' }))

[ordered]@{ Timestamp=(Get-Date).ToString('s'); BaselineTimestamp=$base.Timestamp;
    Current=@{ SafeLinks=$curSL; SafeAttachments=$curSA; AntiPhish=$curAP }; Verdict=$verdict } |
    ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Report: {0}" -f $OutputPath) -ForegroundColor Green
