<#
.SYNOPSIS
    DELOPT-Remediation.ps1 — guarded fixes for common Delivery Optimization blockers (preview by default).
.DESCRIPTION
    PURPOSE
        Safely corrects the most common local blockers that stop peering: the Delivery Optimization
        service (DoSvc) not running, and the peer listening port (TCP 7680) not allowed on the local
        Windows Firewall. It can also stamp a Download Mode into the DO policy registry as a stop-gap
        where an Intune policy is not yet applied. Defaults to -WhatIf (shows actions, changes nothing).
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\DELOPT-Remediation.ps1
        Apply:             .\DELOPT-Remediation.ps1 -Apply
        Optional:          -SetDownloadMode 2   (only as a local stop-gap; the Intune policy is authoritative)
    EXPECTED RESULTS
        A list of intended actions in preview; with -Apply, DoSvc set Automatic + started, an inbound
        allow rule for TCP 7680, and (if requested) the DODownloadMode value written.
.NOTES
    White-label — Intune Solutions. Guarded: no changes unless -Apply is passed. Run elevated to change
    service/firewall/registry. The Intune Settings Catalog policy is the authoritative configuration.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch] $Apply,
    [ValidateSet(0,1,2,3,99)]
    [int]    $SetDownloadMode = -1
)

# Default to preview unless -Apply is explicitly given.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== Delivery Optimization — remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "PREVIEW MODE (-WhatIf) — no changes will be made. Re-run with -Apply to enact." -ForegroundColor Yellow }

# 1) DoSvc running + Automatic
$svc = Get-Service DoSvc -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.StartType -ne 'Automatic') {
        if ($PSCmdlet.ShouldProcess('DoSvc','Set start type = Automatic')) { Set-Service DoSvc -StartupType Automatic }
    }
    if ($svc.Status -ne 'Running') {
        if ($PSCmdlet.ShouldProcess('DoSvc','Start service')) { Start-Service DoSvc }
    } else { Write-Host "DoSvc already running." -ForegroundColor Green }
} else { Write-Host "DoSvc not found on this device." -ForegroundColor Yellow }

# 2) Inbound firewall allow for TCP 7680 (peer listening port)
$rule = Get-NetFirewallRule -DisplayName 'Delivery Optimization (DELOPT) - Peer TCP 7680' -ErrorAction SilentlyContinue
if (-not $rule) {
    if ($PSCmdlet.ShouldProcess('Windows Firewall','Add inbound allow rule for TCP 7680 (Domain,Private)')) {
        New-NetFirewallRule -DisplayName 'Delivery Optimization (DELOPT) - Peer TCP 7680' `
            -Direction Inbound -Action Allow -Protocol TCP -LocalPort 7680 -Profile Domain,Private | Out-Null
    }
} else { Write-Host "Firewall rule for TCP 7680 already present." -ForegroundColor Green }

# 3) Optional local stop-gap Download Mode (Intune policy remains authoritative)
if ($SetDownloadMode -ge 0) {
    $do = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
    if ($PSCmdlet.ShouldProcess($do,"Set DODownloadMode = $SetDownloadMode (local stop-gap)")) {
        if (-not (Test-Path $do)) { New-Item -Path $do -Force | Out-Null }
        New-ItemProperty -Path $do -Name 'DODownloadMode' -Value $SetDownloadMode -PropertyType DWord -Force | Out-Null
    }
    Write-Host "NOTE: prefer the Intune Settings Catalog policy over a local registry value." -ForegroundColor Yellow
}

Write-Host "`nRemediation routine complete." -ForegroundColor Cyan
