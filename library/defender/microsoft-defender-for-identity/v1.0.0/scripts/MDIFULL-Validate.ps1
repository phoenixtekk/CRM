<#
.SYNOPSIS
    MDIFULL-Validate.ps1 — targeted validation of Defender for Identity across the lifecycle
    (DSA, sensor health, sensitive-entity tags, honeytoken tags, and identity signal / detections).
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Microsoft Defender for Identity" solution. Confirms the piece
        named by -Check: the Directory Service Account, pilot sensor health, sensitive-entity
        tagging, honeytoken tagging, or the identity signal (that the Identity* tables stream and a
        controlled/benign test detection is visible). Maps to the Testing Guide gates for all three
        phases (Deploy, Enable, Prove).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Validate.ps1 -Check Sensor
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Validate.ps1 -Check Signal -HoneytokenSam 'svc-legacy-backup'
        -Check accepts: DSA | Sensor | Sensitive | Honeytoken | Signal | All (default All).
        Uses Microsoft.Graph.Authentication and the Microsoft 365 Defender / Graph Security APIs.
        Reads the MDI profile and runs read-only advanced hunting; makes no changes.
    EXPECTED RESULTS
        PASS/REVIEW lines per check with the object names from the Implementation Guide, plus row
        counts per identity table and any recent honeytoken activity — so you can confirm each
        Testing Guide gate before expanding beyond the pilot domain controller.
.NOTES
    White-label. Read-only. Some MDI settings are portal-only — where an API read is unavailable
    the script prints the exact portal path to confirm manually.
#>
[CmdletBinding()]
param(
    [ValidateSet('DSA','Sensor','Sensitive','Honeytoken','Signal','All')]
    [string]$Check = 'All',
    [string]$HoneytokenSam = 'REPLACE-with-honeytoken-samAccountName',
    [int]$LookbackDays = 1
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'SecurityIdentitiesSensors.Read.All','SecurityIdentitiesHealth.Read.All','ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null
}
Write-Host "`n=== Defender for Identity — validation ($Check) ===" -ForegroundColor Cyan

function Test-DSA {
    Write-Host "`n[DSA] Directory Service Account 'MDI Directory Service Account - Tenant - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm registration in: Settings > Identities > Directory Service accounts" -ForegroundColor DarkGray
    Write-Host "   REVIEW: verify the gMSA is listed and sensors can retrieve its password." -ForegroundColor Yellow
}

function Test-Sensor {
    Write-Host "`n[Sensor] Pilot sensor 'MDI Sensor Host - Pilot DC - Pilot'" -ForegroundColor Cyan
    try {
        $sensors = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/identities/sensors' -ErrorAction Stop).value
        if ($sensors) {
            foreach ($s in $sensors) { Write-Host ("   {0,-40} health={1} type={2}" -f $s.displayName, $s.healthStatus, $s.sensorType) }
            $healthy = @($sensors | Where-Object { $_.healthStatus -eq 'healthy' }).Count
            Write-Host ("   PASS if healthy sensors > 0. Healthy: {0}/{1}" -f $healthy, $sensors.Count) -ForegroundColor $(if ($healthy -gt 0) { 'Green' } else { 'Yellow' })
        } else { Write-Host "   No sensors returned — confirm in Settings > Identities > Sensors." -ForegroundColor Yellow }
    } catch {
        Write-Host ("   Sensor API read unavailable ({0})." -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "   REVIEW manually: Settings > Identities > Sensors — pilot DC shows Running/Healthy." -ForegroundColor DarkGray
    }
}

function Test-Tags($kind) {
    $obj = if ($kind -eq 'Sensitive') { 'MDI Sensitive Entities - Tier0 - Prod' } else { 'MDI Honeytoken - Decoy Identity - Pilot' }
    Write-Host "`n[$kind] Entity tags '$obj'" -ForegroundColor Cyan
    Write-Host "   Confirm in: Settings > Identities > Entity tags > $kind" -ForegroundColor DarkGray
    Write-Host "   REVIEW: verify each planned entity appears under the $kind tag." -ForegroundColor Yellow
}

function Invoke-Hunt($kql, $label) {
    Write-Host "`n-- $label --" -ForegroundColor Cyan
    $body = @{ Query = $kql } | ConvertTo-Json
    try {
        $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
        if ($resp.results) { $resp.results | ForEach-Object { Write-Host ("   {0}" -f ($_ | ConvertTo-Json -Compress)) } }
        else { Write-Host "   (no rows — allow sensor warm-up, then re-run)" -ForegroundColor Yellow }
    } catch { Write-Host ("   Hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

function Test-Signal {
    Write-Host "`n[Signal] Detection validation 'MDI Detection Validation - Tenant - Validate'" -ForegroundColor Cyan
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
    $honeyKql = @"
// MDI Detection Validation - Tenant - Validate  (honeytoken / test-signal activity)
let since = ago($($LookbackDays)d);
let honey = '$HoneytokenSam';
union IdentityLogonEvents, IdentityQueryEvents, IdentityDirectoryEvents
| where Timestamp > since
| where AccountName =~ honey or TargetAccountUpn has honey or AdditionalFields has honey
| project Timestamp, ActionType, AccountName, DeviceName, IPAddress, ReportId
| order by Timestamp desc
| take 50
"@
    $alertKql = @"
// MDI Detection Validation - Tenant - Validate  (recent MDI alerts)
AlertInfo
| where Timestamp > ago($($LookbackDays)d)
| where ServiceSource has 'Identity' or Title has_any('reconnaissance','honeytoken','enumeration')
| project Timestamp, Title, Severity, Category
| order by Timestamp desc
| take 25
"@
    Invoke-Hunt $coverageKql 'Identity table coverage'
    Invoke-Hunt $honeyKql   'Honeytoken / test-signal activity'
    Invoke-Hunt $alertKql   'Recent MDI alerts'
    Write-Host "`n   Empty coverage => fix sensor onboarding first (Testing Guide A2)." -ForegroundColor DarkGray
}

switch ($Check) {
    'DSA'        { Test-DSA }
    'Sensor'     { Test-Sensor }
    'Sensitive'  { Test-Tags 'Sensitive' }
    'Honeytoken' { Test-Tags 'Honeytoken' }
    'Signal'     { Test-Signal }
    'All'        { Test-DSA; Test-Sensor; Test-Tags 'Sensitive'; Test-Tags 'Honeytoken'; Test-Signal }
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW items before expanding." -ForegroundColor Green
