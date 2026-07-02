<#
.SYNOPSIS
    EGRESS-Validation.ps1 — test per-endpoint reachability of the required IP/Port/URL set from behind the filter.
.DESCRIPTION
    PURPOSE
        Reads the required-set file produced by EGRESS-Discovery.ps1 and tests each required
        endpoint for reachability on its required port(s) using DNS resolution and TCP/TLS connect
        tests. Run it from a device that sits behind the same proxy/firewall as the managed fleet.
        Read-only: it makes no changes to any device or allow-list.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESS-Validation.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -OutputPath .\EGRESS-Output
        Run on a pilot device behind the filter. Needs the egress path under test; no admin rights required.
    EXPECTED RESULTS
        Writes egress-validation-results.json and prints a per-endpoint PASS/FAIL table. PASS = every
        required endpoint reachable on its required port(s); FAIL = one or more required endpoints unreachable.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredSetPath,

    [string]$OutputPath = '.\EGRESS-Output',

    [int]$TimeoutSeconds = 5
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $RequiredSetPath)) {
    throw "Required-set file not found: $RequiredSetPath. Run EGRESS-Discovery.ps1 first."
}
if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$requiredSet = Get-Content -LiteralPath $RequiredSetPath -Raw | ConvertFrom-Json

function Get-PortList {
    param($tcpPorts)
    if (-not $tcpPorts) { return @(443) }
    $text = "$tcpPorts"
    $ports = @()
    foreach ($chunk in ($text -split '[,\s]+')) {
        if ($chunk -match '^\d+$') { $ports += [int]$chunk }
        elseif ($chunk -match '^(\d+)-(\d+)$') { $ports += [int]$matches[1]; $ports += [int]$matches[2] }
    }
    if ($ports.Count -eq 0) { $ports = @(443) }
    return ($ports | Select-Object -Unique)
}

function Get-TestHost {
    param([string]$Url)
    # Turn a URL/host pattern into a resolvable host. Wildcards get a probe label.
    $h = $Url -replace '^https?://', ''
    $h = ($h -split '/')[0]
    if ($h -like '*`**') { $h = $h -replace '^\*\.', 'www.' ; $h = $h -replace '\*', 'www' }
    return $h
}

function Test-Endpoint {
    param([string]$TargetHost, [int]$Port, [int]$Timeout)

    $result = [ordered]@{ host = $TargetHost; port = $Port; dns = $false; tcp = $false; status = 'FAIL'; detail = '' }

    # DNS
    try {
        $null = [System.Net.Dns]::GetHostAddresses($TargetHost)
        $result.dns = $true
    }
    catch {
        $result.detail = "DNS resolution failed: $($_.Exception.Message)"
        return [pscustomobject]$result
    }

    # TCP connect
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
        if ($iar.AsyncWaitHandle.WaitOne([TimeSpan]::FromSeconds($Timeout))) {
            $client.EndConnect($iar)
            $result.tcp = $true
            $result.status = 'PASS'
        }
        else {
            $result.detail = "TCP connect timed out after ${Timeout}s"
        }
    }
    catch {
        $result.detail = "TCP connect failed: $($_.Exception.Message)"
    }
    finally {
        $client.Close()
    }
    return [pscustomobject]$result
}

Write-Host ''
Write-Host "EGRESS Validation — required set version $($requiredSet.webServiceVersion) (instance $($requiredSet.instance))" -ForegroundColor Cyan
Write-Host ('-' * 70)

$results = New-Object System.Collections.Generic.List[object]

# --- M365 required/Optimize/Allow endpoints (URLs) ---------------------------
$m365ToTest = $requiredSet.m365Endpoints | Where-Object { $_.required -or $_.category -in @('Optimize', 'Allow') }
foreach ($set in $m365ToTest) {
    $ports = Get-PortList $set.tcpPorts
    foreach ($u in $set.urls) {
        $th = Get-TestHost $u
        if (-not $th) { continue }
        foreach ($p in $ports) {
            $r = Test-Endpoint -TargetHost $th -Port $p -Timeout $TimeoutSeconds
            $r | Add-Member -NotePropertyName sourcePattern -NotePropertyValue $u -Force
            $r | Add-Member -NotePropertyName serviceArea -NotePropertyValue $set.serviceArea -Force
            $r | Add-Member -NotePropertyName category -NotePropertyValue $set.category -Force
            $results.Add($r)
        }
    }
}

# --- Device-management endpoints (Intune/Autopilot/Defender/Windows) ---------
foreach ($set in $requiredSet.deviceManagementEndpoints) {
    $ports = Get-PortList $set.tcpPorts
    foreach ($u in $set.urls) {
        $th = Get-TestHost $u
        if (-not $th) { continue }
        foreach ($p in $ports) {
            $r = Test-Endpoint -TargetHost $th -Port $p -Timeout $TimeoutSeconds
            $r | Add-Member -NotePropertyName sourcePattern -NotePropertyValue $u -Force
            $r | Add-Member -NotePropertyName serviceArea -NotePropertyValue $set.area -Force
            $r | Add-Member -NotePropertyName category -NotePropertyValue 'device-management' -Force
            $results.Add($r)
        }
    }
}

# --- Report -----------------------------------------------------------------
$results | Sort-Object status, serviceArea, host |
    Format-Table status, serviceArea, host, port, detail -AutoSize | Out-Host

$passCount = ($results | Where-Object { $_.status -eq 'PASS' }).Count
$failCount = ($results | Where-Object { $_.status -eq 'FAIL' }).Count

$out = [pscustomobject]@{
    generatedAt       = (Get-Date).ToString('o')
    testedFrom        = $env:COMPUTERNAME
    instance          = $requiredSet.instance
    webServiceVersion = $requiredSet.webServiceVersion
    totalTests        = $results.Count
    pass              = $passCount
    fail              = $failCount
    results           = $results
}
$resultsPath = Join-Path $OutputPath 'egress-validation-results.json'
$out | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resultsPath -Encoding UTF8

Write-Host ('-' * 70)
Write-Host "Tested $($results.Count) endpoint/port checks:  PASS=$passCount  FAIL=$failCount" -ForegroundColor Cyan
Write-Host "Results written: $resultsPath" -ForegroundColor Gray
if ($failCount -gt 0) {
    Write-Host "GATE T2: FAIL — one or more required endpoints unreachable. See the Troubleshooting Guide to map each failure to the missing endpoint." -ForegroundColor Red
    exit 2
}
else {
    Write-Host "GATE T2: PASS — every required endpoint reachable." -ForegroundColor Green
}
