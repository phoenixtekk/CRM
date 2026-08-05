<#
.SYNOPSIS
    DELOPT-Report-Savings.ps1 — aggregate Delivery Optimization savings across a set of devices.
.DESCRIPTION
    PURPOSE
        Collects the Delivery Optimization source breakdown (peer / HTTP / cache bytes) from one or
        more devices and produces a combined savings report — the bandwidth NOT pulled from the
        internet because it came from peers or an on-network cache. Use it to prove savings vs. the
        pre-deployment baseline.
    HOW TO RUN
        Local only:   powershell -ExecutionPolicy Bypass -File .\DELOPT-Report-Savings.ps1
        Multi-device: .\DELOPT-Report-Savings.ps1 -ComputerName PC1,PC2,PC3   (uses WinRM/PS remoting)
        Optional:     -CsvPath .\delopt-savings.csv   to also write a CSV.
    EXPECTED RESULTS
        A per-device table (peer/cache/HTTP MB) plus a fleet total and the percentage of downloaded
        bytes saved from the internet. Read-only.
.NOTES
    White-label — Intune Solutions. Read-only. Remoting requires WinRM enabled + rights on targets.
#>
[CmdletBinding()]
param(
    [string[]] $ComputerName = @($env:COMPUTERNAME),
    [string]   $CsvPath
)

function Get-LocalSavings {
    if (-not (Get-Command Get-DeliveryOptimizationStatus -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ Computer=$env:COMPUTERNAME; PeerMB=0; CacheMB=0; HttpMB=0; Note='DO cmdlets unavailable' }
    }
    $r = Get-DeliveryOptimizationStatus -ErrorAction SilentlyContinue
    $peer  = ($r | Measure-Object BytesFromPeers -Sum).Sum
    $http  = ($r | Measure-Object BytesFromHttp -Sum).Sum
    $cache = ($r | Measure-Object BytesFromCacheServer -Sum).Sum
    [pscustomobject]@{
        Computer = $env:COMPUTERNAME
        PeerMB   = [math]::Round(($peer/1MB),1)
        CacheMB  = [math]::Round(($cache/1MB),1)
        HttpMB   = [math]::Round(($http/1MB),1)
        Note     = ''
    }
}

Write-Host "`n=== Delivery Optimization — savings report ($(Get-Date -Format u)) ===" -ForegroundColor Cyan
$results = foreach ($c in $ComputerName) {
    if ($c -eq $env:COMPUTERNAME -or $c -eq 'localhost') { Get-LocalSavings }
    else {
        try { Invoke-Command -ComputerName $c -ScriptBlock ${function:Get-LocalSavings} -ErrorAction Stop }
        catch { [pscustomobject]@{ Computer=$c; PeerMB=0; CacheMB=0; HttpMB=0; Note="unreachable: $($_.Exception.Message)" } }
    }
}

$results | Format-Table Computer, PeerMB, CacheMB, HttpMB, Note -AutoSize

$peer  = ($results | Measure-Object PeerMB  -Sum).Sum
$cache = ($results | Measure-Object CacheMB -Sum).Sum
$http  = ($results | Measure-Object HttpMB  -Sum).Sum
$tot = [double]($peer + $cache + $http); if ($tot -le 0) { $tot = 1 }
Write-Host ("`nFleet totals  Peer: {0:N1} MB  |  Cache: {1:N1} MB  |  HTTP: {2:N1} MB" -f $peer, $cache, $http)
Write-Host ("Bandwidth saved from the internet (peer+cache): {0:N1} MB = {1:P1} of downloaded bytes." -f ($peer+$cache), (($peer+$cache)/$tot)) -ForegroundColor Green
Write-Host "Compare this figure against your pre-deployment baseline to quantify the improvement." -ForegroundColor Cyan

if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "CSV written: $CsvPath" }
