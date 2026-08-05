<#
.SYNOPSIS
    DELOPT-Get-Status.ps1 — show Delivery Optimization source breakdown (peer / HTTP / cache bytes).
.DESCRIPTION
    PURPOSE
        Reads the local Delivery Optimization activity with Get-DeliveryOptimizationStatus and the
        rolled-up efficiency from Get-DeliveryOptimizationPerfSnap, and summarizes how many bytes came
        from peers vs. an HTTP source vs. a cache server (MCC) — the direct evidence that peering works.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\DELOPT-Get-Status.ps1
    EXPECTED RESULTS
        Per-download rows (file, status, BytesFromPeers / BytesFromHttp / BytesFromCacheServer) and a
        total peer-vs-HTTP-vs-cache summary. Non-zero BytesFromPeers proves peering. Read-only.
.NOTES
    White-label — Intune Solutions. Read-only (local DO cmdlets, no changes made).
#>
[CmdletBinding()] param()

Write-Host "`n=== Delivery Optimization — status ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

if (-not (Get-Command Get-DeliveryOptimizationStatus -ErrorAction SilentlyContinue)) {
    Write-Host "Get-DeliveryOptimizationStatus not available — is DoSvc present/running?" -ForegroundColor Yellow
    return
}

$rows = Get-DeliveryOptimizationStatus -ErrorAction SilentlyContinue
if (-not $rows) { Write-Host "No active/recent Delivery Optimization downloads to report." -ForegroundColor Yellow }
else {
    $rows | Select-Object FileId, Status,
        @{n='Peer(MB)'; e={[math]::Round(($_.BytesFromPeers/1MB),1)}},
        @{n='Http(MB)'; e={[math]::Round(($_.BytesFromHttp/1MB),1)}},
        @{n='Cache(MB)';e={[math]::Round(($_.BytesFromCacheServer/1MB),1)}},
        @{n='Total(MB)';e={[math]::Round(($_.TotalBytesDownloaded/1MB),1)}} |
        Format-Table -AutoSize

    $peer  = ($rows | Measure-Object BytesFromPeers -Sum).Sum
    $http  = ($rows | Measure-Object BytesFromHttp -Sum).Sum
    $cache = ($rows | Measure-Object BytesFromCacheServer -Sum).Sum
    $tot = [double]($peer + $http + $cache); if ($tot -le 0) { $tot = 1 }
    Write-Host ("`nTotals  Peer: {0:N1} MB  |  Cache: {1:N1} MB  |  HTTP: {2:N1} MB" -f ($peer/1MB), ($cache/1MB), ($http/1MB))
    Write-Host ("Saved from internet (peer+cache): {0:P1} of downloaded bytes." -f (($peer + $cache)/$tot)) -ForegroundColor Green
    if ($peer -gt 0) { Write-Host "PASS: peering is occurring (BytesFromPeers > 0)." -ForegroundColor Green }
    else { Write-Host "REVIEW: no peer bytes yet — see troubleshooting (mode/group/port 7680/shared content)." -ForegroundColor Yellow }
}

# Rolled-up efficiency snapshot
if (Get-Command Get-DeliveryOptimizationPerfSnap -ErrorAction SilentlyContinue) {
    Write-Host "`n--- PerfSnap (rolled-up) ---" -ForegroundColor Cyan
    try { Get-DeliveryOptimizationPerfSnap -ErrorAction SilentlyContinue | Format-List `
        DownloadHttpBytes, DownloadLanBytes, DownloadGroupBytes, DownloadCacheHostBytes, UploadLanBytes, UploadGroupBytes } catch {}
}
Write-Host "`nStatus complete (read-only)." -ForegroundColor Cyan
