<#
.SYNOPSIS
    SCCMAPP-Remediation.ps1 — safely remediate a migrated Win32 app that failed to install.
.DESCRIPTION
    PURPOSE
        For a device where the migrated app reports Failed: triggers an Intune/MDM sync so the Win32
        app re-evaluates, and re-runs the Intune Management Extension detection cycle. Reports what it
        would do; makes changes only when -WhatIf is turned off with -Execute.
    HOW TO RUN
        Elevated, on the affected device. Preview (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Remediation.ps1
        Apply the sync/re-evaluate:
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Remediation.ps1 -Execute
    EXPECTED RESULTS
        In preview: the actions that would run. With -Execute: an MDM sync requested and the IME
        service restarted so the app re-evaluates. Re-run SCCMAPP-Validation.ps1 after a policy cycle.
.NOTES
    White-label — Migrations. Default is preview (-WhatIf); -Execute to apply.
#>
[CmdletBinding()] param([switch]$Execute)
$whatIf = -not $Execute
Write-Host "=== SCCMAPP Remediation — $($env:COMPUTERNAME) ($(if($whatIf){'PREVIEW / -WhatIf'}else{'EXECUTE'})) ===" -ForegroundColor Cyan

# 1. MDM sync so the Win32 assignment re-applies
if ($whatIf) { Write-Host "  [WhatIf] Would request an MDM sync (deviceenroller.exe /c /AutoEnrollMDM)." -ForegroundColor Yellow }
else {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

# 2. Restart the Intune Management Extension so Win32 apps re-evaluate
$svc = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if (-not $svc) { Write-Host "  Intune Management Extension service not found (is the device enrolled?)." -ForegroundColor Yellow }
elseif ($whatIf) { Write-Host "  [WhatIf] Would restart the IntuneManagementExtension service to force Win32 re-evaluation." -ForegroundColor Yellow }
else { Restart-Service -Name IntuneManagementExtension -Force; Write-Host "  IntuneManagementExtension restarted; Win32 apps will re-evaluate." -ForegroundColor Green }

Write-Host "`nRe-run SCCMAPP-Validation.ps1 after a policy cycle to confirm install + detection parity." -ForegroundColor Green
if ($whatIf) { Write-Host "No changes made (preview). Re-run with -Execute to apply." -ForegroundColor Cyan }
