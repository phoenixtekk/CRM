<#
.SYNOPSIS
    DELOPT-Preflight.ps1 — verify Delivery Optimization readiness on this device.
.DESCRIPTION
    PURPOSE
        Confirms the device can participate in Delivery Optimization: supported Windows
        edition/version, the Delivery Optimization service (DoSvc) running, the peer listening
        port (TCP 7680) open locally, and the effective on-device DO Download Mode / group config.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\DELOPT-Preflight.ps1
    EXPECTED RESULTS
        Edition/build, DoSvc state, port 7680 listening status, and the applied Download Mode /
        GroupID source — with a PASS/REVIEW verdict per check. Read-only.
.NOTES
    White-label — Intune Solutions. Read-only (no changes made).
#>
[CmdletBinding()] param()

Write-Host "`n=== Delivery Optimization — preflight ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# --- Edition / version ---
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion,OsProductType -ErrorAction SilentlyContinue
$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID
Write-Host ("OS               : {0}  (build {1}, {2}, edition {3})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion, $edition)
if ($edition -match 'Core|Home') { Write-Host "  REVIEW: Home edition supports only consumer peering, not enterprise DO policy." -ForegroundColor Yellow }
else { Write-Host "  PASS  : Supported edition for enterprise Delivery Optimization." -ForegroundColor Green }

# --- DoSvc ---
$svc = Get-Service DoSvc -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq 'Running') { Write-Host ("DoSvc            : Running (StartType {0})  PASS" -f $svc.StartType) -ForegroundColor Green }
else { Write-Host ("DoSvc            : {0}  REVIEW — start the Delivery Optimization service." -f ($(if($svc){$svc.Status}else{'not found'}))) -ForegroundColor Yellow }

# --- Peer port 7680 ---
$listen = Get-NetTCPConnection -LocalPort 7680 -State Listen -ErrorAction SilentlyContinue
if ($listen) { Write-Host "Peer port 7680   : Listening  PASS" -ForegroundColor Green }
else { Write-Host "Peer port 7680   : not listening  REVIEW — DoSvc opens 7680 when peering is enabled; check firewall/mode." -ForegroundColor Yellow }

# --- Effective DO config ---
Write-Host "`n--- Effective Delivery Optimization config ---" -ForegroundColor Cyan
try {
    if (Get-Command Get-DOConfig -ErrorAction SilentlyContinue) {
        $cfg = Get-DOConfig -Verbose:$false
        $modeMap = @{0='HTTP Only';1='LAN';2='Group';3='Internet';99='Simple';100='Bypass(deprecated)'}
        $mode = $cfg.DownloadMode
        Write-Host ("Download Mode    : {0} ({1})" -f $mode, $(if($modeMap.ContainsKey([int]$mode)){$modeMap[[int]$mode]}else{'unknown'}))
        Write-Host ("GroupID          : {0}" -f $cfg.GroupID)
        Write-Host ("GroupIDSource    : {0}" -f $cfg.GroupIDSrc)
        Write-Host ("Max cache size   : {0}%   AbsMaxCache(GB): {1}" -f $cfg.MaxCacheSize, $cfg.MaxCacheSizeGB)
    } else {
        # Fallback: read the policy registry
        $do = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
        $p = Get-ItemProperty $do -ErrorAction SilentlyContinue
        Write-Host ("Download Mode    : {0}" -f ($(if($p){$p.DODownloadMode}else{'not set (default LAN/1)'})))
        Write-Host ("GroupIDSource    : {0}" -f ($(if($p){$p.DOGroupIdSource}else{'not set'})))
    }
} catch { Write-Host "  Could not read DO config: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`nPreflight complete (read-only)." -ForegroundColor Cyan
