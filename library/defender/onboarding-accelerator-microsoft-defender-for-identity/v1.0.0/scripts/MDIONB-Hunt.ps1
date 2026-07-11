<#
.SYNOPSIS
    MDIONB-Hunt.ps1 — run the identity-detection validation KQL to confirm MDI sensors stream
    signal and a controlled test detection is visible.
.DESCRIPTION
    PURPOSE
        Read-only advanced-hunting for the "Onboarding Accelerator — Microsoft Defender for
        Identity" solution. Executes the saved query 'MDI Detection Validation - Tenant - Validate'
        via Microsoft Graph Security advanced hunting to confirm the identity tables are populated
        from the pilot sensor, and to show recent activity against the honeytoken account so you can
        confirm a test detection fired (Testing Guide Tests 5 and 6).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDIONB-Hunt.ps1 -HoneytokenSam 'svc-legacy-bak'
        Uses Microsoft.Graph.Authentication and the ThreatHunting.Read.All scope. Read-only.
    EXPECTED RESULTS
        Row counts per identity table and any recent events touching the honeytoken — proof that
        the sensor is streaming and that a controlled honeytoken touch produced signal.
.NOTES
    White-label. Read-only (advanced hunting). Embedded KQL below is the delivered query.
#>
[CmdletBinding()]
param(
    [string]$HoneytokenSam = 'REPLACE-with-honeytoken-samAccountName',
    [int]$LookbackDays = 1
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== MDI detection validation hunt (read-only) ===" -ForegroundColor Cyan

# --- 1) Confirm identity tables stream from the sensor(s) ---
$coverageKql = @"
// MDI Detection Validation - Tenant - Validate  (table coverage)
let since = ago($($LookbackDays)d);
union
 (IdentityInfo | where Timestamp > since | summarize Rows=count() | extend Table='IdentityInfo'),
 (IdentityLogonEvents | where Timestamp > since | summarize Rows=count() | extend Table='IdentityLogonEvents'),
 (IdentityDirectoryEvents | where Timestamp > since | summarize Rows=count() | extend Table='IdentityDirectoryEvents'),
 (IdentityQueryEvents | where Timestamp > since | summarize Rows=count() | extend Table='IdentityQueryEvents')
| project Table, Rows
"@

# --- 2) Confirm a controlled honeytoken touch produced signal ---
$honeyKql = @"
// MDI Detection Validation - Tenant - Validate  (honeytoken activity)
let since = ago($($LookbackDays)d);
let honey = '$HoneytokenSam';
union IdentityLogonEvents, IdentityQueryEvents, IdentityDirectoryEvents
| where Timestamp > since
| where AccountName =~ honey or TargetAccountUpn has honey or AdditionalFields has honey
| project Timestamp, ActionType, AccountName, DeviceName, IPAddress, ReportId
| order by Timestamp desc
| take 50
"@

function Invoke-Hunt($kql, $label) {
    Write-Host "`n-- $label --" -ForegroundColor Cyan
    $body = @{ Query = $kql } | ConvertTo-Json
    try {
        $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
        if ($resp.results) { $resp.results | ForEach-Object { Write-Host ("   {0}" -f ($_ | ConvertTo-Json -Compress)) } }
        else { Write-Host "   (no rows — allow sensor warm-up, then re-run)" -ForegroundColor Yellow }
    } catch { Write-Host ("   Hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Invoke-Hunt $coverageKql 'Identity table coverage'
Invoke-Hunt $honeyKql   'Honeytoken activity (controlled test)'
Write-Host "`nHunt complete (read-only). Empty coverage => fix sensor onboarding first (Testing Guide Test 2)." -ForegroundColor Green
