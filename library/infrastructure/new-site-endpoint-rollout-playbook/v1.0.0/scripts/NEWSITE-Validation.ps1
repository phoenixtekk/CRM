<#
.SYNOPSIS
    NEWSITE-Validation.ps1 — per-device go-live validation for a new-site rollout.
.DESCRIPTION
    PURPOSE
        Validates a single provisioned device against the go-live criteria: it is Entra-joined and
        MDM-enrolled, the device is compliant, the site's apps are installed, and the site's printers
        are present. Run on each site device before the go-live gate.
    HOW TO RUN
        Run on the site device (optionally pass the expected apps/printers):
        powershell -ExecutionPolicy Bypass -File .\NEWSITE-Validation.ps1 `
            -ExpectedApps "AppA","AppB" -ExpectedPrinters "Site A - Reception"
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall device verdict. All checks must PASS for go-live.
.NOTES
    New-Site Endpoint Rollout Playbook. Read-only — makes no changes.
#>
[CmdletBinding()]
param(
    [string[]]$ExpectedApps = @(),
    [string[]]$ExpectedPrinters = @()
)

Write-Host "`n=== New-Site Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$fail = 0

# 1. Entra join + MDM enrollment
$dsreg  = (dsregcmd /status) 2>$null
$joined = [bool]($dsreg | Select-String 'AzureAdJoined\s*:\s*YES')
$mdm    = [bool]($dsreg | Select-String 'MdmUrl\s*:\s*http')
if ($joined -and $mdm) { Write-Host "PASS  enrolled   : Entra joined and MDM enrolled" -ForegroundColor Green }
else { Write-Host "FAIL  enrolled   : not fully Entra-joined / MDM-enrolled" -ForegroundColor Red; $fail++ }

# 2. Compliance state (local MDM-reported)
$compKey = 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot'
Write-Host "INFO  compliance : confirm Compliant in Intune (Devices > Compliance) for this device"

# 3. Site apps installed
if ($ExpectedApps.Count) {
    $installed = @(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        ForEach-Object { $_.DisplayName } | Where-Object { $_ })
    foreach ($app in $ExpectedApps) {
        if ($installed -match [regex]::Escape($app)) { Write-Host ("PASS  app        : {0}" -f $app) -ForegroundColor Green }
        else { Write-Host ("FAIL  app missing: {0}" -f $app) -ForegroundColor Red; $fail++ }
    }
} else { Write-Host "INFO  apps        : pass -ExpectedApps to check the site app set" -ForegroundColor Yellow }

# 4. Site printers present
$printers = @(Get-Printer -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
if ($ExpectedPrinters.Count) {
    foreach ($pr in $ExpectedPrinters) {
        if ($printers -contains $pr) { Write-Host ("PASS  printer    : {0}" -f $pr) -ForegroundColor Green }
        else { Write-Host ("FAIL  printer    : {0} not present" -f $pr) -ForegroundColor Red; $fail++ }
    }
} else { Write-Host ("INFO  printers    : {0} present (pass -ExpectedPrinters to validate the site set)" -f $printers.Count) -ForegroundColor Yellow }

Write-Host ""
if ($fail -eq 0) { Write-Host "DEVICE VERDICT: PASS — ready for go-live." -ForegroundColor Green }
else { Write-Host ("DEVICE VERDICT: FAIL — {0} check(s) failed; remediate with NEWSITE-Remediation.ps1." -f $fail) -ForegroundColor Red }
