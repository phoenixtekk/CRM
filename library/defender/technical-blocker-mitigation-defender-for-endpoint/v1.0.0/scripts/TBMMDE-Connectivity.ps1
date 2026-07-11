<#
.SYNOPSIS
    TBMMDE-Connectivity.ps1 — read-only reachability test from an affected device to the documented
    Defender for Endpoint service endpoints.
.DESCRIPTION
    PURPOSE
        The most common cause of a sensor that onboards but reports Inactive / Impaired communication
        is a proxy or firewall blocking the Defender service endpoints. This script tests outbound
        HTTPS reachability from the machine it runs on (a sample device from
        'MDE Blocker Triage - Affected Ring - Diagnose') to a set of documented Defender endpoints and
        reports each as reachable or blocked. Makes NO changes.
    HOW TO RUN
        Run locally on a sample affected Windows device:
        powershell -ExecutionPolicy Bypass -File .\TBMMDE-Connectivity.ps1
        Optionally pass your tenant's current endpoint list:
        .\TBMMDE-Connectivity.ps1 -EndpointFile .\mde-endpoints.txt
    EXPECTED RESULTS
        A pass/fail line per endpoint and an overall verdict. Any blocked endpoint points the fix at
        the proxy/firewall (allow the documented Defender endpoints), NOT at MDE configuration.
.NOTES
    White-label. Read-only — performs connectivity probes only; changes nothing.
    The built-in list is a STARTING POINT — verify the current Defender endpoint URL/IP list for your
    tenant and geography (it changes) and pass it with -EndpointFile.
#>
[CmdletBinding()]
param(
    [string]$EndpointFile,
    [string]$OutputPath = ".\MDE-connectivity.json",
    [int]$TimeoutSeconds = 10
)

# Representative Defender service endpoints. VERIFY the current list for your tenant/geo and override
# with -EndpointFile (one host[:port] per line). These are common commercial-cloud hosts.
$defaultEndpoints = @(
    'winatp-gw-cus.microsoft.com',
    'winatp-gw-eus.microsoft.com',
    'events.data.microsoft.com',
    'x.cp.wd.microsoft.com',
    'cdn.x.cp.wd.microsoft.com',
    'go.microsoft.com',
    'login.microsoftonline.com',
    'securitycenter.windows.com',
    'security.microsoft.com'
)

$endpoints = if ($EndpointFile -and (Test-Path $EndpointFile)) {
    Get-Content $EndpointFile | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
} else {
    Write-Host "Using built-in representative endpoint list (verify the current list for your tenant)." -ForegroundColor Yellow
    $defaultEndpoints
}

Write-Host "`n=== TBMMDE — Defender service endpoint connectivity (read-only) ===" -ForegroundColor Cyan
Write-Host ("Device : {0}" -f $env:COMPUTERNAME)
$results = @()
$blocked = 0
foreach ($ep in $endpoints) {
    $hostName = $ep.Split(':')[0]
    $port = if ($ep -match ':') { [int]$ep.Split(':')[1] } else { 443 }
    $ok = $false
    try {
        $t = Test-NetConnection -ComputerName $hostName -Port $port -WarningAction SilentlyContinue
        $ok = [bool]$t.TcpTestSucceeded
    } catch { $ok = $false }
    if ($ok) { Write-Host ("   PASS  {0}:{1}" -f $hostName, $port) -ForegroundColor Green }
    else     { Write-Host ("   FAIL  {0}:{1}  (blocked or unreachable)" -f $hostName, $port) -ForegroundColor Red; $blocked++ }
    $results += [ordered]@{ Endpoint = $hostName; Port = $port; Reachable = $ok }
}

$verdict = if ($blocked -eq 0) { 'ALL_REACHABLE' } else { "$blocked BLOCKED" }
Write-Host ("`nVerdict: {0}" -f $verdict) -ForegroundColor ($(if ($blocked -eq 0) { 'Green' } else { 'Yellow' }))
if ($blocked -gt 0) {
    Write-Host "Fix: allow the blocked Defender endpoints at the proxy/firewall (global-requirements G5)." -ForegroundColor Yellow
    Write-Host "This is a networking fix, not an MDE change. Re-test after the allow-list is updated." -ForegroundColor Yellow
}

[ordered]@{ Timestamp=(Get-Date).ToString('s'); Device=$env:COMPUTERNAME; Verdict=$verdict; Results=$results } |
    ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Connectivity snapshot: {0}" -f $OutputPath) -ForegroundColor Green
