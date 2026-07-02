<#
.SYNOPSIS
    NETDX-Validation.ps1 — per-target reachability validation (name, IP, port, URL) from the endpoint.
.DESCRIPTION
    PURPOSE
        For each target in a CSV, tests the layers from the endpoint: does the NAME resolve, does the
        IP:PORT open, and does the URL return an allowed response. Produces a per-target pass/fail
        with the first-failing layer so you know which layer blocks each target. Read-only; opens no
        write operations on the endpoint or the network.
        CSV columns: Name,Host,Port,Url  (Url optional; Port optional, defaults to 443).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NETDX-Validation.ps1 -TargetCsv .\targets.csv
        powershell -ExecutionPolicy Bypass -File .\NETDX-Validation.ps1 -TargetCsv .\targets.csv -OutputPath C:\Temp\netdx
        (no special scopes)
    EXPECTED RESULTS
        A console table of each target with DNS/Port/Url results and the first failing layer, plus a
        results file (netdx-validation-TIMESTAMP.json/csv) for NETDX-Report.ps1.
        Pass = all applicable checks succeed for a target. Any fail names the responsible layer
        (DNS / Port / Url).
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetCsv,

    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath 'netdx'),

    [int]$TimeoutSeconds = 10
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path -Path $TargetCsv)) {
    throw "Target CSV not found: $TargetCsv"
}
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$targets = Import-Csv -Path $TargetCsv
if (-not $targets) { throw "Target CSV '$TargetCsv' is empty or has no rows." }

$results = New-Object System.Collections.Generic.List[object]

foreach ($t in $targets) {
    $name = $t.Name
    $hostName = $t.Host
    $port = if ($t.Port) { [int]$t.Port } else { 443 }
    $url = $t.Url

    if (-not $hostName) { Write-Warning "Row '$name' has no Host; skipping."; continue }

    Write-Host ("Testing {0} ({1}:{2}) ..." -f $name, $hostName, $port) -ForegroundColor Cyan

    $r = [ordered]@{
        Name         = $name
        Host         = $hostName
        Port         = $port
        Url          = $url
        ResolvedIP   = $null
        DnsResult    = 'SKIP'
        PortResult   = 'SKIP'
        UrlResult    = 'SKIP'
        FirstFail    = $null
        Detail       = ''
    }

    # --- Layer 1: DNS ---
    try {
        $resolved = Resolve-DnsName -Name $hostName -Type A -ErrorAction Stop |
            Where-Object { $_.IPAddress } | Select-Object -First 1
        if ($resolved) {
            $r.ResolvedIP = $resolved.IPAddress
            $r.DnsResult = 'PASS'
        }
        else { $r.DnsResult = 'FAIL'; $r.FirstFail = 'DNS'; $r.Detail = 'No A record returned' }
    }
    catch {
        $r.DnsResult = 'FAIL'; $r.FirstFail = 'DNS'; $r.Detail = $_.Exception.Message
    }

    # --- Layer 4: IP:Port (only if DNS passed) ---
    if ($r.DnsResult -eq 'PASS') {
        try {
            $tnc = Test-NetConnection -ComputerName $hostName -Port $port -WarningAction SilentlyContinue -ErrorAction Stop
            if ($tnc.TcpTestSucceeded) { $r.PortResult = 'PASS' }
            else {
                $r.PortResult = 'FAIL'
                if (-not $r.FirstFail) { $r.FirstFail = 'Port'; $r.Detail = "TCP to ${hostName}:$port failed (timeout/refused)" }
            }
        }
        catch {
            $r.PortResult = 'FAIL'
            if (-not $r.FirstFail) { $r.FirstFail = 'Port'; $r.Detail = $_.Exception.Message }
        }
    }

    # --- Layer 5: URL (only if port passed and a URL was given) ---
    if ($r.PortResult -eq 'PASS' -and $url) {
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $TimeoutSeconds -MaximumRedirection 0 -ErrorAction Stop
            if ([int]$resp.StatusCode -ge 200 -and [int]$resp.StatusCode -lt 400) { $r.UrlResult = 'PASS' }
            else {
                $r.UrlResult = 'FAIL'
                if (-not $r.FirstFail) { $r.FirstFail = 'Url'; $r.Detail = "HTTP $($resp.StatusCode)" }
            }
        }
        catch {
            # A 3xx with -MaximumRedirection 0 or a block/403 surfaces here; capture the status.
            $status = $null
            if ($_.Exception.Response) { try { $status = [int]$_.Exception.Response.StatusCode } catch { } }
            if ($status -and $status -ge 200 -and $status -lt 400) {
                $r.UrlResult = 'PASS'
            }
            else {
                $r.UrlResult = 'FAIL'
                if (-not $r.FirstFail) { $r.FirstFail = 'Url'; $r.Detail = "HTTP $status $($_.Exception.Message)" }
            }
        }
    }

    $results.Add([pscustomobject]$r)
}

# --- output ---
$results |
    Select-Object Name, Host, Port, ResolvedIP, DnsResult, PortResult, UrlResult, FirstFail |
    Format-Table -AutoSize | Out-String | Write-Host

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$jsonFile = Join-Path -Path $OutputPath -ChildPath ("netdx-validation-{0}.json" -f $stamp)
$csvFile = Join-Path -Path $OutputPath -ChildPath ("netdx-validation-{0}.csv" -f $stamp)
$results | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonFile -Encoding UTF8
$results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host ''
Write-Host "Validation results saved to:" -ForegroundColor Green
Write-Host "  $jsonFile"
Write-Host "  $csvFile  (feed this to NETDX-Report.ps1)"
