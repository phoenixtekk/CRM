<#
.SYNOPSIS
    NEWSITE-Discovery.ps1 — new-site readiness check (network, identity, and time).
.DESCRIPTION
    PURPOSE
        Confirms a new site is ready for endpoint rollout: reachability of the Microsoft sign-in and
        enrollment endpoints, DNS resolution, Entra join / MDM enrollment state, and time sync. This
        is the first dependency in the playbook — provisioning and everything after it fail if the
        site cannot reach Microsoft cloud services.
    HOW TO RUN
        Run on a device on the new site network:
        powershell -ExecutionPolicy Bypass -File .\NEWSITE-Discovery.ps1
    EXPECTED RESULTS
        PASS/FAIL lines for each reachability and identity check; any FAIL must be fixed before you
        start provisioning the site.
.NOTES
    New-Site Endpoint Rollout Playbook. Read-only — makes no changes.
#>
[CmdletBinding()] param()

Write-Host "`n=== New-Site Readiness — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

$endpoints = @(
    'login.microsoftonline.com',
    'enrollment.manage.microsoft.com',
    'device.login.microsoftonline.com'
)
foreach ($ep in $endpoints) {
    $r = Test-NetConnection -ComputerName $ep -Port 443 -WarningAction SilentlyContinue
    if ($r.TcpTestSucceeded) { Write-Host ("PASS  reachable : {0}:443" -f $ep) -ForegroundColor Green }
    else { Write-Host ("FAIL  blocked   : {0}:443 — allow Microsoft 365 / Intune ranges" -f $ep) -ForegroundColor Red }
}

# DNS
try {
    $null = Resolve-DnsName 'login.microsoftonline.com' -ErrorAction Stop
    Write-Host "PASS  DNS resolves Microsoft endpoints" -ForegroundColor Green
} catch { Write-Host "FAIL  DNS cannot resolve Microsoft endpoints" -ForegroundColor Red }

# Entra join + MDM enrollment state
$dsreg = (dsregcmd /status) 2>$null
$joined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES')
$mdm    = ($dsreg | Select-String 'MdmUrl\s*:\s*http')
if ($joined) { Write-Host "PASS  device is Entra ID joined" -ForegroundColor Green }
else { Write-Host "INFO  device not yet Entra ID joined (expected before provisioning)" -ForegroundColor Yellow }
if ($mdm) { Write-Host "PASS  MDM enrollment present" -ForegroundColor Green }
else { Write-Host "INFO  no MDM enrollment yet (expected before provisioning)" -ForegroundColor Yellow }

# Time sync (skew breaks auth)
$skew = (w32tm /stripchart /computer:time.windows.com /samples:1 /dataonly 2>$null) | Select-Object -Last 1
Write-Host ("INFO  time sample : {0}" -f ($skew -as [string]))

Write-Host "`nResolve any FAIL above before provisioning the site." -ForegroundColor Cyan
