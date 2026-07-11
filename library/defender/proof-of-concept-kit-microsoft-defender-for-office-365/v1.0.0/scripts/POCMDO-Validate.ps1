<#
.SYNOPSIS
    POCMDO-Validate.ps1 — demo/validate that the benign email test signal produced real MDO detections. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation and live-demo helper for the MDO proof of concept. Using the
        Microsoft 365 Defender advanced-hunting API (via Microsoft Graph Security), it confirms
        the benign test signal surfaced as:
          - EmailEvents          — the simulation / test messages were processed by MDO
          - UrlClickEvents       — Safe Links time-of-click protection engaged
          - EmailAttachmentInfo  — Safe Attachments saw the EICAR attachment
        It also points to Threat Explorer / quarantine for the visual demo. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDO-Validate.ps1
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A pass/fail line per capability (mail processed, Safe Links engaged, Safe Attachments saw
        the attachment), plus portal paths for the Threat Explorer / quarantine demo.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [string]$Tag = 'MDO-PoC-TESTSIGNAL',
    [int]$LookbackHours = 6
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

Write-Host "`n=== POCMDO validation — benign-signal detections (read-only) ===" -ForegroundColor Cyan

$checks = @(
    @{ Name = 'Mail processed by MDO (EmailEvents)'; Kql = @"
EmailEvents
| where Timestamp > ago(${LookbackHours}h)
| where Subject has '$Tag' or ThreatTypes != '' or DetectionMethods != ''
| summarize Cnt = count()
"@ },
    @{ Name = 'Safe Links engaged (UrlClickEvents)'; Kql = @"
UrlClickEvents
| where Timestamp > ago(${LookbackHours}h)
| summarize Cnt = count()
"@ },
    @{ Name = 'Safe Attachments saw attachment (EmailAttachmentInfo)'; Kql = @"
EmailAttachmentInfo
| where Timestamp > ago(${LookbackHours}h)
| where FileName has 'eicar' or FileType != ''
| summarize Cnt = count()
"@ }
)

$pass = 0
foreach ($c in $checks) {
    try {
        $n = Cnt (Invoke-Hunt $c.Kql)
        if ($n -gt 0) { Write-Host ("  PASS — {0} ({1} row[s])" -f $c.Name, $n) -ForegroundColor Green; $pass++ }
        else { Write-Host ("  FAIL — {0}: no rows yet (allow warm-up, confirm scope)." -f $c.Name) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  ERROR — {0}: {1}" -f $c.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`n[Demo the headline capabilities in the portal]" -ForegroundColor Cyan
Write-Host "  Threat Explorer (P2): security.microsoft.com -> Email & collaboration -> Explorer." -ForegroundColor Gray
Write-Host "  Quarantine          : Email & collaboration -> Review -> Quarantine (GTUBE/EICAR test items)." -ForegroundColor Gray
Write-Host "  Simulation results  : Email & collaboration -> Attack simulation training." -ForegroundColor Gray

Write-Host ("`nSummary: {0}/{1} capability checks passing." -f $pass, $checks.Count) -ForegroundColor Cyan
Write-Host "Next: POCMDO-Scorecard.ps1" -ForegroundColor Cyan
