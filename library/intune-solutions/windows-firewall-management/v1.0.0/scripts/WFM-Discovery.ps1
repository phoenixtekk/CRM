<#
.SYNOPSIS
    WFM-Discovery.ps1 — report Windows Defender Firewall state and rule counts.
.DESCRIPTION
    PURPOSE
        Shows the enabled state and default actions for each firewall profile, plus the count of
        enabled inbound/outbound rules — a quick pre-deployment snapshot.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WFM-Discovery.ps1
    EXPECTED RESULTS
        A per-profile table and rule counts.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== Firewall State ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table -AutoSize
$inb = (Get-NetFirewallRule -Direction Inbound -Enabled True -ErrorAction SilentlyContinue).Count
$out = (Get-NetFirewallRule -Direction Outbound -Enabled True -ErrorAction SilentlyContinue).Count
Write-Host ("Enabled rules — Inbound: {0}  Outbound: {1}" -f $inb, $out) -ForegroundColor Cyan
$disabled = (Get-NetFirewallProfile | Where-Object Enabled -eq $false).Name
if ($disabled) { Write-Host ("Profiles OFF: {0}" -f ($disabled -join ', ')) -ForegroundColor Yellow }
else { Write-Host "All profiles enabled." -ForegroundColor Green }
