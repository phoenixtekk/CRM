<#
.SYNOPSIS
    VOIPSUP-Report.ps1 — produce a VOIP-readiness / call-quality summary for the endpoint.
.DESCRIPTION
    PURPOSE
        Read-only reporting that rolls the three call-quality gates into one summary: correct/healthy
        audio device, healthy softphone client (version vs a supplied minimum), and network within
        thresholds. Emits a console summary and an optional HTML/CSV report you can attach to a
        telephony-team escalation. Changes nothing on the endpoint.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Report.ps1 -Target media-edge-host-or-ip -MinClientVersion 1.0.0.0 -ClientNameFilter softphone-client-name
        powershell -ExecutionPolicy Bypass -File .\VOIPSUP-Report.ps1 -Target media-edge-host-or-ip -HtmlPath .\voipsup-report.html
    EXPECTED RESULTS
        A per-gate PASS/FAIL summary (device / client / network) and an OVERALL readiness verdict.
        Optional HTML and CSV files for the escalation package. All-PASS with failing calls means the
        endpoint is clean — escalate.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Target,
    [string[]] $ClientNameFilter = @('softphone','voip','phone','communicator','calling','meetings'),
    [string]   $MinClientVersion,
    [int]    $PingCount      = 20,
    [double] $MaxLatencyMs   = 150,
    [double] $MaxJitterMs    = 30,
    [double] $MaxLossPercent = 1,
    [string] $HtmlPath,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Result([string]$Gate,[string]$Check,[string]$Value,[bool]$Pass){
    $results.Add([pscustomobject]@{ Gate=$Gate; Check=$Check; Value=$Value; Result=$(if($Pass){'PASS'}else{'FAIL'}) })
}

Write-Host '=== VOIPSUP Report — VOIP readiness / call quality (read-only) ===' -ForegroundColor Cyan
Write-Host ("Device: {0}    User: {1}    Target: {2}    {3}" -f $env:COMPUTERNAME,$env:USERNAME,$Target,(Get-Date))
Write-Host ''

# ---- GATE 1: audio device ----
try {
    $eps = @(Get-PnpDevice -Class 'AudioEndpoint' -ErrorAction Stop)
    $okEps = @($eps | Where-Object { $_.Status -eq 'OK' })
    Add-Result 'Device' 'Audio endpoints present' ("{0} endpoint(s)" -f $eps.Count) ($eps.Count -gt 0)
    Add-Result 'Device' 'Audio endpoints healthy' ("{0} of {1} OK" -f $okEps.Count,$eps.Count) ($eps.Count -gt 0 -and $okEps.Count -eq $eps.Count)
} catch {
    Add-Result 'Device' 'Audio endpoints present' $_.Exception.Message $false
}

# ---- GATE 2: softphone client ----
$pattern = ($ClientNameFilter | ForEach-Object { [regex]::Escape($_) }) -join '|'
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$installed = foreach ($k in $uninstallKeys) {
    try { Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } } catch { }
}
$client = $installed | Where-Object { $_.DisplayName -match $pattern } | Sort-Object DisplayVersion -Descending | Select-Object -First 1
if ($client) {
    Add-Result 'Client' 'Client installed' ("{0} {1}" -f $client.DisplayName,$client.DisplayVersion) $true
    if ($MinClientVersion) {
        $meets = $false
        try {
            $have = [version]([regex]::Match([string]$client.DisplayVersion,'\d+(\.\d+){0,3}').Value)
            $min  = [version]$MinClientVersion
            $meets = $have -ge $min
        } catch { $meets = $false }
        Add-Result 'Client' 'Version >= minimum' ("have {0}, min {1}" -f $client.DisplayVersion,$MinClientVersion) $meets
    }
} else {
    Add-Result 'Client' 'Client installed' 'no matching client found' $false
}
# client running & responding
$proc = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match $pattern })
if ($proc.Count -gt 0) {
    $hung = @($proc | Where-Object { -not $_.Responding })
    Add-Result 'Client' 'Process responding' ("{0} running, {1} not responding" -f $proc.Count,$hung.Count) ($hung.Count -eq 0)
} else {
    Add-Result 'Client' 'Process running' 'client not currently running (start it to test a call)' $true
}

# ---- GATE 3: network ----
$wired = $false
try {
    $wired = [bool](@(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' -and ($_.MediaType -match '802.3' -or $_.Name -match 'Ethernet') }).Count)
} catch { }
Add-Result 'Network' 'Wired connection' ($(if($wired){'wired up'}else{'Wi-Fi / no wired — prefer wired'})) $wired

$rtts = New-Object System.Collections.Generic.List[double]; $sent=0;$recv=0
for ($i=0;$i -lt $PingCount;$i++){
    $sent++
    try {
        $r = Test-Connection -ComputerName $Target -Count 1 -ErrorAction Stop
        $ms=$null
        if ($r.PSObject.Properties.Name -contains 'Latency'){$ms=[double]$r.Latency}
        elseif ($r.PSObject.Properties.Name -contains 'ResponseTime'){$ms=[double]$r.ResponseTime}
        if ($null -ne $ms){$rtts.Add($ms);$recv++}
    } catch { }
    Start-Sleep -Milliseconds 200
}
if ($recv -gt 0){
    $avg=[math]::Round(($rtts|Measure-Object -Average).Average,1)
    $diffs = for ($j=1;$j -lt $rtts.Count;$j++){[math]::Abs($rtts[$j]-$rtts[$j-1])}
    $jitter = if($diffs){[math]::Round((($diffs|Measure-Object -Average).Average),1)}else{0}
    $loss=[math]::Round((($sent-$recv)/$sent*100),1)
    Add-Result 'Network' 'Latency'     ("{0} ms (max {1})" -f $avg,$MaxLatencyMs)     ($avg -le $MaxLatencyMs)
    Add-Result 'Network' 'Jitter'      ("{0} ms (max {1})" -f $jitter,$MaxJitterMs)   ($jitter -le $MaxJitterMs)
    Add-Result 'Network' 'Packet loss' ("{0}% (max {1}%)" -f $loss,$MaxLossPercent)   ($loss -le $MaxLossPercent)
} else {
    Add-Result 'Network' 'Reachability' ("no replies from {0}" -f $Target) $false
}

# ---- Summary ----
Write-Host '--- Readiness summary ---' -ForegroundColor Yellow
$results | Format-Table Gate,Check,Value,Result -AutoSize
$fails = @($results | Where-Object { $_.Result -eq 'FAIL' })
$overall = ($fails.Count -eq 0)
Write-Host ''
if ($overall) {
    Write-Host 'OVERALL: PASS — endpoint is VOIP-ready. If calls still fail, escalate: the endpoint is clean.' -ForegroundColor Green
} else {
    Write-Host ("OVERALL: FAIL — {0} check(s) failed. Remediate per the Diagnostic Playbook, then re-run." -f $fails.Count) -ForegroundColor Red
}

# ---- Optional exports ----
if ($CsvPath) {
    try { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("CSV: {0}" -f $CsvPath) -ForegroundColor Green } catch { Write-Warning $_.Exception.Message }
}
if ($HtmlPath) {
    try {
        $head = "<style>body{font-family:Segoe UI,Arial,sans-serif}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px}</style>"
        $title = "VOIPSUP Readiness Report — $($env:COMPUTERNAME) — $(Get-Date) — Overall: $(if($overall){'PASS'}else{'FAIL'})"
        $results | ConvertTo-Html -Title $title -PreContent "<h2>$title</h2>" -Head $head | Out-File -FilePath $HtmlPath -Encoding UTF8
        Write-Host ("HTML: {0}" -f $HtmlPath) -ForegroundColor Green
    } catch { Write-Warning $_.Exception.Message }
}
