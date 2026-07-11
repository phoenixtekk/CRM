<#
.SYNOPSIS
    POCMDC-Validate.ps1 — demo/validate that the benign test signal produced real Defender-for-Cloud detections. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation and live-demo helper for the Defender for Cloud proof of concept.
        Using Az.Security, it confirms the benign test signal surfaced as:
          - recommendations (assessments) — CSPM saw the benign misconfiguration
          - Secure Score                  — posture score present
          - security alerts               — sample + EICAR alerts fired
        It also points to the portal Regulatory compliance view for the demo. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDC-Validate.ps1 -SubscriptionId <guid>
        Requires Az.Accounts + Az.Security and Security Reader on the subscription.
    EXPECTED RESULTS
        A pass/fail line per capability (recommendations, Secure Score, alerts), plus the portal
        path for the regulatory-compliance demo.
.NOTES
    White-label. Read-only. Az.Security reads posture/alerts only; it changes nothing.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Security -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

Write-Host "`n=== POCMDC validation — benign-signal detections (read-only) ===" -ForegroundColor Cyan
$pass = 0; $total = 3

# 1) Recommendations / assessments (CSPM).
try {
    $tasks = Get-AzSecurityTask -ErrorAction SilentlyContinue
    $assess = Get-AzSecurityAssessment -ErrorAction SilentlyContinue
    $recCount = (@($tasks).Count + @($assess | Where-Object { $_.Status.Code -ne 'Healthy' }).Count)
    if ($recCount -gt 0) { Write-Host ("  PASS — CSPM recommendations present ({0})" -f $recCount) -ForegroundColor Green; $pass++ }
    else { Write-Host "  FAIL — no recommendations yet (allow CSPM warm-up)." -ForegroundColor Yellow }
} catch { Write-Host ("  ERROR — recommendations: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# 2) Secure Score.
try {
    $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue
    if ($score) { Write-Host ("  PASS — Secure Score present ({0})" -f (($score | Select-Object -First 1).Score.Percentage)) -ForegroundColor Green; $pass++ }
    else { Write-Host "  FAIL — no Secure Score yet (allow warm-up)." -ForegroundColor Yellow }
} catch { Write-Host ("  ERROR — Secure Score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# 3) Security alerts.
try {
    $alerts = Get-AzSecurityAlert -ErrorAction SilentlyContinue
    if (@($alerts).Count -gt 0) { Write-Host ("  PASS — security alerts present ({0})" -f @($alerts).Count) -ForegroundColor Green; $pass++ }
    else { Write-Host "  FAIL — no security alerts yet (create sample alerts / allow propagation)." -ForegroundColor Yellow }
} catch { Write-Host ("  ERROR — alerts: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n[Demo the headline capabilities in the portal]" -ForegroundColor Cyan
Write-Host "  Recommendations : portal.azure.com -> Microsoft Defender for Cloud -> Recommendations." -ForegroundColor Gray
Write-Host "  Secure Score    : Microsoft Defender for Cloud -> Secure Score." -ForegroundColor Gray
Write-Host "  Security alerts : Microsoft Defender for Cloud -> Security alerts (sample + EICAR)." -ForegroundColor Gray
Write-Host "  Compliance      : Microsoft Defender for Cloud -> Regulatory compliance." -ForegroundColor Gray

Write-Host ("`nSummary: {0}/{1} capability checks passing (also confirm Regulatory compliance in the portal)." -f $pass, $total) -ForegroundColor Cyan
Write-Host "Next: POCMDC-Scorecard.ps1" -ForegroundColor Cyan
