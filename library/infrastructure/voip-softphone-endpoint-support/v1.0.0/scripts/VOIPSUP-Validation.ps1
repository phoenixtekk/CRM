<#
.SYNOPSIS
    VOIPSUP-Validation.ps1 — validate the selected audio device and measure the endpoint network path.
.DESCRIPTION
    PURPOSE
        Read-only validation for a VOIP/softphone endpoint. Confirms audio endpoints are present and
        healthy, reports the active network adapter and connection type, and measures latency, jitter,
        and packet loss to a media-edge target so you can judge call quality against thresholds. Marks
        each measured item PASS/FAIL. Changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Validation.ps1 -Target media-edge-host-or-ip
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Validation.ps1 -Target media-edge-host-or-ip -MaxLatencyMs 150 -MaxJitterMs 30 -MaxLossPercent 1 -PingCount 30
    EXPECTED RESULTS
        A device-health line per audio endpoint, the active adapter/connection type, and measured
        latency/jitter/loss with PASS or FAIL against the supplied thresholds. Use with
        VOIPSUP-Report.ps1 to build the escalation package.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    # Media-edge host or IP to measure the call path against, e.g. media-edge-host-or-ip.
    [Parameter(Mandatory)] [string] $Target,
    [int]    $PingCount     = 20,
    [double] $MaxLatencyMs  = 150,
    [double] $MaxJitterMs   = 30,
    [double] $MaxLossPercent = 1
)

$ErrorActionPreference = 'Stop'
function Write-Gate([string]$Name,[bool]$Pass,[string]$Detail){
    $tag = if($Pass){'PASS'}else{'FAIL'}
    $col = if($Pass){'Green'}else{'Red'}
    Write-Host ("[{0}] {1} — {2}" -f $tag,$Name,$Detail) -ForegroundColor $col
}

Write-Host '=== VOIPSUP Validation — audio device + network (read-only) ===' -ForegroundColor Cyan
Write-Host ("Device: {0}    Target: {1}    {2}" -f $env:COMPUTERNAME, $Target, (Get-Date))
Write-Host ''

# ---- Audio endpoint health ----
Write-Host '--- Audio endpoint health ---' -ForegroundColor Yellow
try {
    $eps = Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction Stop
    if (-not $eps) { Write-Gate 'Audio endpoints present' $false 'no audio endpoints found' }
    foreach ($e in $eps) {
        Write-Gate ("Device: {0}" -f $e.FriendlyName) ($e.Status -eq 'OK') ("status={0}" -f $e.Status)
    }
} catch {
    Write-Gate 'Audio endpoints present' $false $_.Exception.Message
}
Write-Host ''

# ---- Active network adapter / connection type ----
Write-Host '--- Network adapter / connection type ---' -ForegroundColor Yellow
$wired = $false
try {
    $up = Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' }
    foreach ($a in $up) {
        $isWired = $a.MediaType -match '802.3' -or $a.Name -match 'Ethernet'
        if ($isWired) { $wired = $true }
        Write-Host ("  {0}  [{1}]  LinkSpeed={2}" -f $a.Name, $a.MediaType, $a.LinkSpeed)
    }
    Write-Gate 'Connection type' $wired ($(if($wired){'wired adapter up (preferred for calls)'}else{'no wired adapter up — Wi-Fi in use, prefer wired for calls'}))
} catch {
    Write-Warning "Could not read network adapters: $($_.Exception.Message)"
}
Write-Host ''

# ---- QoS policy presence (endpoint DSCP marking) ----
Write-Host '--- QoS / DSCP marking on endpoint ---' -ForegroundColor Yellow
try {
    $qos = Get-NetQosPolicy -ErrorAction SilentlyContinue
    if ($qos) {
        Write-Host '  QoS policies present:'
        $qos | Select-Object Name, DSCPAction, IPProtocol | Format-Table -AutoSize
    } else {
        Write-Host '  No policy-based QoS found on this endpoint (deploy via Intune/GPO if the platform expects DSCP marking).'
    }
} catch { }
Write-Host ''

# ---- Latency / jitter / packet loss to the media edge ----
Write-Host ("--- Network quality to {0} ({1} probes) ---" -f $Target, $PingCount) -ForegroundColor Yellow
$rtts = New-Object System.Collections.Generic.List[double]
$sent = 0; $recv = 0
for ($i = 0; $i -lt $PingCount; $i++) {
    $sent++
    try {
        $r = Test-Connection -ComputerName $Target -Count 1 -ErrorAction Stop
        $ms = $null
        if ($r.PSObject.Properties.Name -contains 'Latency')      { $ms = [double]$r.Latency }
        elseif ($r.PSObject.Properties.Name -contains 'ResponseTime') { $ms = [double]$r.ResponseTime }
        if ($null -ne $ms) { $rtts.Add($ms); $recv++ }
    } catch { }
    Start-Sleep -Milliseconds 200
}

if ($recv -gt 0) {
    $avg = [math]::Round(($rtts | Measure-Object -Average).Average, 1)
    # jitter = mean absolute difference between consecutive round-trips
    $diffs = for ($j = 1; $j -lt $rtts.Count; $j++) { [math]::Abs($rtts[$j] - $rtts[$j-1]) }
    $jitter = if ($diffs) { [math]::Round((($diffs | Measure-Object -Average).Average), 1) } else { 0 }
    $loss = [math]::Round(((($sent - $recv) / $sent) * 100), 1)

    Write-Gate 'Latency' ($avg -le $MaxLatencyMs) ("avg {0} ms (max {1} ms)" -f $avg, $MaxLatencyMs)
    Write-Gate 'Jitter'  ($jitter -le $MaxJitterMs) ("{0} ms (max {1} ms)" -f $jitter, $MaxJitterMs)
    Write-Gate 'Packet loss' ($loss -le $MaxLossPercent) ("{0}% ({1}/{2} lost, max {3}%)" -f $loss, ($sent-$recv), $sent, $MaxLossPercent)
} else {
    Write-Gate 'Network reachability' $false ("no replies from {0} — check target, firewall/ICMP, or connection" -f $Target)
}

Write-Host ''
Write-Host 'Validation complete. If audio device + network all PASS but calls still fail, the endpoint is' -ForegroundColor Cyan
Write-Host 'clean — run VOIPSUP-Report.ps1 and escalate to the telephony team with the output.' -ForegroundColor Cyan
