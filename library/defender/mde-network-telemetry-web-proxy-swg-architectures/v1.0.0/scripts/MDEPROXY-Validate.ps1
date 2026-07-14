<#
.SYNOPSIS
    MDEPROXY-Validate.ps1 — read-only measurement of DeviceNetworkEvents destination obfuscation and
    completeness for endpoints behind a loopback/forward SWG proxy.
.DESCRIPTION
    PURPOSE
        Measures, over a device sample and window, HOW MUCH of the endpoint's destination telemetry
        the SWG proxy is obscuring: the share of outbound DeviceNetworkEvents whose RemoteIP falls in
        the loopback/proxy address set (obscured) vs a true remote, the count of connections with
        missing/empty RemoteUrl, and DeviceNetworkEvents completeness (network-to-process event ratio).
        Writes a telemetry baseline. Read-only advanced hunting only — changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEPROXY-Validate.ps1 `
          -Sample @('AERO-WKS-01','AERO-WKS-02') `
          -ProxyAddressSet @('127.0.0.0/8','::1','10.10.10.5') -Days 7
        -Sample accepts device names (array) OR a device-group/tag name resolved in DeviceInfo.
        -Check Obfuscation | Completeness | All (default All). Government cloud: -Environment.
    EXPECTED RESULTS
        MDEPROXY-telemetry-baseline.json — obfuscation %, missing-RemoteUrl count, per-device
        distribution, and completeness metrics. The script ECHOES the proxy address set it used so the
        classification is reviewable. A true 0% is a valid finding (no obfuscation), not an error.
.NOTES
    White-label. Read-only. The finding is only as complete as the -ProxyAddressSet you supply —
    document every address (R5). Advanced-hunting retention is limited — verify current retention.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string[]]$Sample,
    [string[]]$ProxyAddressSet = @('127.0.0.0/8','::1','169.254.0.0/16'),
    [int]$Days = 7,
    [ValidateSet('Obfuscation','Completeness','All')] [string]$Check = 'All',
    [string]$OutputPath = ".\MDEPROXY-telemetry-baseline.json",
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes @('ThreatHunting.Read.All','SecurityEvents.Read.All') -Environment $Environment -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' `
        -Body (@{ Query = $Query } | ConvertTo-Json) -ContentType 'application/json'
}

Write-Host "`n=== MDEPROXY — destination-obfuscation measurement (read-only) ===" -ForegroundColor Cyan
Write-Host  "Sample devices     : $($Sample -join ', ')"
Write-Host  "Proxy address set  : $($ProxyAddressSet -join ', ')   <-- classification basis (review this)" -ForegroundColor Yellow
Write-Host  "Window             : last $Days day(s)"

# Split the address set into CIDR ranges (ipv4_is_in_range) and exact literals (e.g. ::1)
$cidrs    = @($ProxyAddressSet | Where-Object { $_ -match '/' })
$literals = @($ProxyAddressSet | Where-Object { $_ -notmatch '/' })
$deviceList = ($Sample | ForEach-Object { "'" + ($_ -replace "'","''") + "'" }) -join ','
$cidrList   = ($cidrs    | ForEach-Object { "'" + $_ + "'" }) -join ','
$litList    = ($literals | ForEach-Object { "'" + $_ + "'" }) -join ','

# KQL: classify each outbound connection's RemoteIP as obscured (loopback/proxy) vs true remote.
# isObscured = RemoteIP is a literal in the set, OR (IPv4 and) falls in one of the CIDR ranges.
$isObscuredExpr = @"
let litSet = dynamic([$litList]);
let cidrSet = dynamic([$cidrList]);
let obscured = (ip:string) {
    iff(set_has_element(litSet, ip)
        or (ip matches regex @'^\d{1,3}(\.\d{1,3}){3}$'
            and array_length(cidrSet) > 0
            and toscalar(range i from 0 to array_length(cidrSet)-1 step 1
                         | summarize any(ipv4_is_in_range(ip, tostring(cidrSet[i]))) ) )
    , true, false)
};
"@

$result = [ordered]@{
    Timestamp = (Get-Date).ToString('s'); ReadOnly = $true; WindowDays = $Days
    Sample = $Sample; ProxyAddressSet = $ProxyAddressSet
}

if ($Check -in 'Obfuscation','All') {
    Write-Host "`n-- Destination obfuscation (RemoteIP in proxy set vs true remote) --" -ForegroundColor Cyan
    $obfKql = @"
$isObscuredExpr
DeviceNetworkEvents
| where Timestamp > ago(${Days}d)
| where DeviceName in ($deviceList)
| where ActionType in ('ConnectionSuccess','ConnectionAttempt','ConnectionFound','InboundConnectionAccepted') or isnotempty(RemoteIP)
| extend IsObscured = obscured(RemoteIP)
| extend MissingUrl = isempty(RemoteUrl)
| summarize Total=count(),
            Obscured=countif(IsObscured),
            TrueRemote=countif(not(IsObscured)),
            MissingRemoteUrl=countif(MissingUrl)
| extend ObscuredPct = round(100.0 * Obscured / Total, 2),
         MissingUrlPct = round(100.0 * MissingRemoteUrl / Total, 2)
"@
    try {
        $o = Invoke-Hunt $obfKql
        if ($o.results) {
            $row = $o.results[0]
            Write-Host ("   Total connections : {0}" -f $row.Total)
            Write-Host ("   Obscured (proxy)  : {0}  ({1}%)" -f $row.Obscured, $row.ObscuredPct) -ForegroundColor Yellow
            Write-Host ("   True remote       : {0}" -f $row.TrueRemote) -ForegroundColor Green
            Write-Host ("   Missing RemoteUrl : {0}  ({1}%)" -f $row.MissingRemoteUrl, $row.MissingUrlPct)
            $result.Obfuscation = $row
        } else { Write-Host "   No connection rows in window/sample — confirm the sample and window (a true 0 is a valid finding)." -ForegroundColor Yellow }
    } catch { Write-Host ("   Obfuscation hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Red }

    Write-Host "`n-- Per-device obscured share --" -ForegroundColor Cyan
    $perDevKql = @"
$isObscuredExpr
DeviceNetworkEvents
| where Timestamp > ago(${Days}d)
| where DeviceName in ($deviceList)
| where isnotempty(RemoteIP)
| extend IsObscured = obscured(RemoteIP)
| summarize Total=count(), Obscured=countif(IsObscured) by DeviceName
| extend ObscuredPct = round(100.0 * Obscured / Total, 2)
| order by ObscuredPct desc
"@
    try {
        $p = Invoke-Hunt $perDevKql
        if ($p.results) { $p.results | ForEach-Object { Write-Host ("   {0,-32} {1,6}% obscured ({2}/{3})" -f $_.DeviceName, $_.ObscuredPct, $_.Obscured, $_.Total) }; $result.PerDevice = $p.results }
    } catch { Write-Host ("   Per-device hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

if ($Check -in 'Completeness','All') {
    Write-Host "`n-- DeviceNetworkEvents completeness (network-to-process ratio) --" -ForegroundColor Cyan
    $compKql = @"
let dl = dynamic([$deviceList]);
let net = DeviceNetworkEvents | where Timestamp > ago(${Days}d) | where DeviceName in ($deviceList) | summarize NetEvents=count() by DeviceName;
let proc = DeviceProcessEvents | where Timestamp > ago(${Days}d) | where DeviceName in ($deviceList) | summarize ProcEvents=count() by DeviceName;
net
| join kind=fullouter proc on DeviceName
| extend DeviceName = coalesce(DeviceName, DeviceName1)
| project DeviceName, NetEvents=coalesce(NetEvents,0), ProcEvents=coalesce(ProcEvents,0)
| extend NetToProcRatio = iff(ProcEvents > 0, round(1.0 * NetEvents / ProcEvents, 3), real(null))
| order by NetToProcRatio asc
"@
    try {
        $c = Invoke-Hunt $compKql
        if ($c.results) {
            $c.results | ForEach-Object {
                $flag = if ($_.NetEvents -eq 0) { ' <- NO network events' } elseif ($_.NetToProcRatio -ne $null -and $_.NetToProcRatio -lt 0.1) { ' <- low ratio' } else { '' }
                Write-Host ("   {0,-32} net={1,-8} proc={2,-8} ratio={3}{4}" -f $_.DeviceName, $_.NetEvents, $_.ProcEvents, $_.NetToProcRatio, $flag)
            }
            $result.Completeness = $c.results
        } else { Write-Host "   No rows — confirm the sample and window." -ForegroundColor Yellow }
    } catch { Write-Host ("   Completeness hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nMeasurement complete (read-only). Baseline: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host  "Reminder: the obscured share is only as complete as the -ProxyAddressSet above. Document it (R5)." -ForegroundColor DarkGray
