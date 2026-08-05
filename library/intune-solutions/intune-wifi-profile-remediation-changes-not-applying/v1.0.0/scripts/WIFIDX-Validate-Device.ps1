<#
.SYNOPSIS
    WIFIDX-Validate-Device.ps1 — read the LIVE saved Wi-Fi network and effective proxy on a Windows device.
.DESCRIPTION
    PURPOSE
        The applied-state ground truth for Branch A/B/E. Run locally on an affected Windows device to
        read what the device ACTUALLY has for an SSID — the saved (known) network and its effective
        proxy — so you can compare it to what Intune reports. This is how you catch a profile that says
        "Succeeded" while the device is unchanged. Read-only (no changes to the device).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Validate-Device.ps1 -Ssid CORP-WIFI
        Run in an elevated PowerShell ON the affected device. No Graph/cloud connection needed.
    EXPECTED RESULTS
        The saved profile details for the SSID (security/auth), whether it is a known network, and the
        effective WinHTTP/user proxy. Also lists ALL saved Wi-Fi profiles so a duplicate/stale one is
        visible. Prints "SSID not saved on this device" if the device never joined it.
.NOTES
    Intune Solutions — read-only, on-device. No cloud connection. Compares APPLIED vs REPORTED state.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Ssid
)

Write-Host "`n=== WIFIDX Device Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# 1. All saved Wi-Fi profiles (spot duplicates / a stale copy)
Write-Host "`n[1] Saved Wi-Fi profiles on this device:" -ForegroundColor Cyan
$profiles = (netsh wlan show profiles) 2>$null | Select-String 'All User Profile\s*:\s*(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() }
if (-not $profiles) { Write-Host "  (none — no WLAN adapter, or no saved networks)" -ForegroundColor Yellow }
else { $profiles | ForEach-Object { $mark = if ($_ -eq $Ssid) { '  <-- target SSID' } else { '' }; Write-Host ("  - {0}{1}" -f $_, $mark) } }

# 2. Detail for the target SSID
Write-Host ("`n[2] Saved network detail for '{0}':" -f $Ssid) -ForegroundColor Cyan
if ($profiles -contains $Ssid) {
    $detail = netsh wlan show profile name="$Ssid" key=clear
    ($detail | Select-String 'SSID name|Authentication|Cipher|Security key|Key Content|Connection mode|Cost') | ForEach-Object { Write-Host ("  {0}" -f $_.ToString().Trim()) }
    Write-Host "  [applied] This SSID IS a known/saved network on the device." -ForegroundColor Green
    Write-Host "  If Intune reports Succeeded but the values above are the OLD ones -> Branch A (stale saved network)." -ForegroundColor Yellow
} else {
    Write-Host ("  SSID '{0}' is NOT saved on this device." -f $Ssid) -ForegroundColor Yellow
    Write-Host "  (A never-joined device is your control case for Branch A — it should show the NEW settings.)" -ForegroundColor Gray
}

# 3. Effective proxy (Branch B)
Write-Host "`n[3] Effective proxy on this device:" -ForegroundColor Cyan
Write-Host "  WinHTTP (system) proxy:" -ForegroundColor Gray
(netsh winhttp show proxy) | ForEach-Object { if ($_.Trim()) { Write-Host ("    {0}" -f $_.Trim()) } }
try {
    $ie = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
    Write-Host "  Per-user (WinINET) proxy:" -ForegroundColor Gray
    Write-Host ("    ProxyEnable : {0}" -f $ie.ProxyEnable)
    if ($ie.ProxyServer)  { Write-Host ("    ProxyServer : {0}   (should be HOST:PORT — no http:// , no /path)" -f $ie.ProxyServer) }
    if ($ie.AutoConfigURL){ Write-Host ("    AutoConfigURL (PAC): {0}   (should be a full http://host/..pac URL)" -f $ie.AutoConfigURL) }
} catch {}

Write-Host "`n  Compare the values above with your intended settings. Applied != Reported is the whole point." -ForegroundColor Cyan
