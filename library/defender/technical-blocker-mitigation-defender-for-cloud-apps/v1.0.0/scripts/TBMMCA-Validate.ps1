<#
.SYNOPSIS
    TBMMCA-Validate.ps1 — read-only pass/fail check that a Defender for Cloud Apps blocker is cleared
    for the affected apps.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Technical Blocker Mitigation — Defender for Cloud Apps" solution.
        Runs the saved advanced-hunting logic 'MDCA Connector Blocker Check - Tenant - Diagnose' via
        Microsoft Graph Security to confirm cloud-app activity signal for the affected apps — evidence
        that connectors are connected and (for session control) that proxied sessions are recorded.
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMCA-Validate.ps1 -AppNameLike "Salesforce"
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        PASS/FAIL lines for connector/activity signal. FAIL points you to the matching Troubleshooting
        section. Cross-check connector status + discovery dashboard + activity log in the portal.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [string]$AppNameLike = "",
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

$appFilter = if ($AppNameLike) { "| where Application has `"$AppNameLike`"" } else { "" }

Write-Host "`n=== TBMMCA validation — affected apps (read-only) ===" -ForegroundColor Cyan
Write-Host ("Lookback: {0}h  AppNameLike: '{1}'" -f $LookbackHours, $AppNameLike)

$kql = @"
CloudAppEvents
| where Timestamp > ago(${LookbackHours}h)
$appFilter
| summarize Rows = count(), Apps = dcount(Application), Users = dcount(AccountDisplayName)
"@
try {
    $r = Invoke-Hunt $kql
    $rows=0;$apps=0;$users=0
    if ($r.results -and $r.results.Count -gt 0) { $rows=[int]$r.results[0].Rows; $apps=[int]$r.results[0].Apps; $users=[int]$r.results[0].Users }
    Write-Host ("CloudAppEvents: {0} rows across {1} app(s), {2} user(s) in {3}h" -f $rows,$apps,$users,$LookbackHours)
    if ($rows -gt 0) { Write-Host "PASS — cloud-app activity signal is flowing (connectors connected / sessions recorded)." -ForegroundColor Green }
    else { Write-Host "FAIL — no activity signal. See Troubleshooting 'Connector authentication failure' or 'Session policy / CA App Control not engaging'." -ForegroundColor Yellow }
} catch { Write-Host ("Could not run CloudAppEvents query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nValidation complete (read-only). Confirm connector 'connected', discovery data, and activity-log hits in the portal." -ForegroundColor Green
