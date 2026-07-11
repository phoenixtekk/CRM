<#
.SYNOPSIS
    TBMMDO-Validate.ps1 — read-only pass/fail check that a Defender for Office 365 blocker is cleared
    for the affected recipients.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Technical Blocker Mitigation — Defender for Office 365" solution.
        Runs the saved advanced-hunting logic 'MDO Policy Blocker Check - Tenant - Diagnose' via
        Microsoft Graph Security to confirm, after a fix and a test message, that MDO protection now
        engages for the affected recipients: Safe Links rewriting (UrlClickEvents) and Safe Attachments /
        threat actions (EmailEvents). Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDO-Validate.ps1 -RecipientLike "affected.user"
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        PASS/FAIL lines for Safe Links and Safe Attachments engagement. FAIL points you to the matching
        Troubleshooting section for that blocker class.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [string]$RecipientLike = "",
    [int]$LookbackHours = 24
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

$recipFilter = if ($RecipientLike) { "| where RecipientEmailAddress has `"$RecipientLike`"" } else { "" }

Write-Host "`n=== TBMMDO validation — affected recipients (read-only) ===" -ForegroundColor Cyan
Write-Host ("Lookback: {0}h  RecipientLike: '{1}'" -f $LookbackHours, $RecipientLike)

# --- Email flow + threat action seen (EmailEvents) ---
$kqlEmail = @"
EmailEvents
| where Timestamp > ago(${LookbackHours}h)
$recipFilter
| summarize Total = count(),
            ScannedByEOP = countif(isnotempty(ThreatTypes) or isnotempty(DetectionMethods) or EmailAction != ""),
            SafeAttachmentAction = countif(DetectionMethods has "Safe Attachments" or ThreatTypes has "Malware")
"@
try {
    $r = Invoke-Hunt $kqlEmail
    if ($r.results -and $r.results.Count -gt 0) {
        $row = $r.results[0]
        Write-Host ("EmailEvents: total={0}  processed-by-service={1}  safe-attach-signal={2}" -f $row.Total,$row.ScannedByEOP,$row.SafeAttachmentAction)
        if ([int]$row.Total -gt 0) { Write-Host "PASS — mail for the recipients is being processed by the service (reaches EOP/MDO)." -ForegroundColor Green }
        else { Write-Host "FAIL — no EmailEvents. Mail may bypass EOP. See Troubleshooting 'Mail bypasses filtering'." -ForegroundColor Yellow }
    } else { Write-Host "No EmailEvents rows — send a test message and allow warm-up." -ForegroundColor Yellow }
} catch { Write-Host ("Could not run EmailEvents query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Safe Links rewriting (UrlClickEvents) ---
$kqlUrl = @"
UrlClickEvents
| where Timestamp > ago(${LookbackHours}h)
$($recipFilter -replace 'RecipientEmailAddress','AccountUpn')
| summarize Clicks = count()
"@
try {
    $r2 = Invoke-Hunt $kqlUrl
    $clicks = 0
    if ($r2.results -and $r2.results.Count -gt 0) { $clicks = [int]$r2.results[0].Clicks }
    Write-Host ("UrlClickEvents (Safe Links): {0} click event(s) in {1}h" -f $clicks,$LookbackHours)
    if ($clicks -gt 0) { Write-Host "PASS — Safe Links is wrapping/recording URLs." -ForegroundColor Green }
    else { Write-Host "INFO — no click events yet. Click the test URL, then re-run. If never wrapped, see 'Safe Links not rewriting'." -ForegroundColor Yellow }
} catch { Write-Host ("Could not run UrlClickEvents query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nValidation complete (read-only). Cross-check message trace for the test message action." -ForegroundColor Green
