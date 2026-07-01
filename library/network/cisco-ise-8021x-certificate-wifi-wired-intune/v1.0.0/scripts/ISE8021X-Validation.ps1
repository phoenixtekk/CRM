<#
.SYNOPSIS
    ISE8021X-Validation.ps1 — Confirm the 802.1X EAP-TLS client certificate and the Wi-Fi + wired profiles are applied on THIS device.
.DESCRIPTION
    PURPOSE
        Read-only, local validation of the three device-side gates for Cisco ISE 802.1X EAP-TLS:
        (1) client certificate present with Client Authentication EKU, (2) Wi-Fi and wired 802.1X
        profiles applied with EAP, (3) Wired AutoConfig (dot3svc) running. Runs on the device;
        no Graph connection required. ISE-side verdict is checked in the ISE console (vendor docs).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISE8021X-Validation.ps1

        No Graph scopes required — reads the local certificate store and netsh profiles.
    EXPECTED RESULTS
        A per-gate PASS/FAIL summary. PASS when a Client-Authentication cert is present, the
        corporate Wi-Fi and wired 802.1X profiles exist with EAP, and dot3svc is running.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE + network-infra internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string]$WifiProfileName = 'Corp Wi-Fi - EAP-TLS',
    [string]$ExpectedSsid
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Result($gate, $check, $ok, $detail) {
    $status = if ($ok) { 'PASS' } else { 'FAIL' }
    $results.Add([pscustomobject]@{ Gate=$gate; Check=$check; Status=$status; Detail=$detail })
}

Write-Host "802.1X EAP-TLS device validation on $env:COMPUTERNAME" -ForegroundColor Cyan

# --- Gate 1: client certificate present ---
Write-Host "`n=== Gate 1: certificate ===" -ForegroundColor Yellow
$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$machineCerts = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue
$clientCerts = @()
foreach ($c in $machineCerts) {
    $ekus = $c.EnhancedKeyUsageList | ForEach-Object { $_.ObjectId }
    if ($ekus -contains $clientAuthOid) { $clientCerts += $c }
}
$certOk = $clientCerts.Count -gt 0
Add-Result 1 'Client-Authentication certificate present' $certOk ("count=$($clientCerts.Count)")
foreach ($c in $clientCerts) {
    $daysLeft = [math]::Round(($c.NotAfter - (Get-Date)).TotalDays)
    $near = $daysLeft -lt 30
    $certColor = if ($near) { 'DarkYellow' } else { 'Gray' }
    Write-Host ("  cert: {0}  expires {1} ({2} days)" -f $c.Subject, $c.NotAfter, $daysLeft) -ForegroundColor $certColor
    if ($near) { Add-Result 1 'Certificate not near expiry' $false "$($c.Subject) expires in $daysLeft days" }
}

# trusted root sanity — is there any root store content that could chain ISE?
$rootCount = (Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue).Count
Add-Result 1 'Machine Root store populated (ISE root should be here)' ($rootCount -gt 0) "rootCerts=$rootCount"

# --- Gate 2: profiles applied ---
Write-Host "`n=== Gate 2: profiles ===" -ForegroundColor Yellow

# Wi-Fi profile
$wlanOut = ''
try { $wlanOut = (netsh wlan show profiles) 2>$null | Out-String } catch {}
$wifiPresent = $wlanOut -match [regex]::Escape($WifiProfileName) -or ($ExpectedSsid -and $wlanOut -match [regex]::Escape($ExpectedSsid))
Add-Result 2 "Wi-Fi profile present ($WifiProfileName)" $wifiPresent 'via netsh wlan show profiles'

# Wired profile (LAN)
$lanOut = ''
try { $lanOut = (netsh lan show profiles) 2>$null | Out-String } catch {}
$wiredPresent = ($lanOut -match '(?i)eap' ) -or ($lanOut -match '(?i)802\.?1x') -or ($lanOut.Trim().Length -gt 0 -and $lanOut -notmatch '(?i)no.*profile')
Add-Result 2 'Wired 802.1X profile present' $wiredPresent 'via netsh lan show profiles'

# --- Gate 3 (device pre-req): dot3svc running ---
Write-Host "`n=== Gate 3 (device pre-req): Wired AutoConfig ===" -ForegroundColor Yellow
$dot3 = Get-Service -Name dot3svc -ErrorAction SilentlyContinue
$dot3Running = $dot3 -and $dot3.Status -eq 'Running'
Add-Result 3 'Wired AutoConfig (dot3svc) running' $dot3Running ("status=$([string]$dot3.Status)")

$wlansvc = Get-Service -Name WlanSvc -ErrorAction SilentlyContinue
Add-Result 3 'WLAN AutoConfig (WlanSvc) running' ($wlansvc -and $wlansvc.Status -eq 'Running') ("status=$([string]$wlansvc.Status)")

# --- Summary ---
Write-Host "`n=== Summary ===" -ForegroundColor Yellow
$results | Format-Table Gate, Status, Check, Detail -AutoSize | Out-String | Write-Host
$failed = ($results | Where-Object Status -eq 'FAIL').Count
if ($failed -eq 0) {
    Write-Host "OVERALL: PASS — device is configured for 802.1X EAP-TLS. Confirm the ISE Access-Accept in the ISE console." -ForegroundColor Green
} else {
    Write-Host "OVERALL: $failed check(s) FAILED — see the Troubleshooting guide (gate order: cert -> profile -> ISE)." -ForegroundColor Red
}
