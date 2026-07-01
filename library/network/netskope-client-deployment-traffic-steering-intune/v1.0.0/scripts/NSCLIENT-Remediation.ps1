<#
.SYNOPSIS
    NSCLIENT-Remediation.ps1 — safe remediation for a failed/unhealthy Netskope client on this device.
.DESCRIPTION
    PURPOSE
        Safely nudges a device back toward a healthy client: triggers an Intune/MDM sync so the client
        app and certificate re-apply, and (if the client service exists but is stopped) attempts to
        start it. Defaults to -WhatIf: it PREVIEWS actions and changes nothing until you pass -Apply.
    HOW TO RUN
        Preview (default, no changes): powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Remediation.ps1
        Apply changes:                 powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Remediation.ps1 -Apply
    EXPECTED RESULTS
        In preview: a list of what would be done. With -Apply: MDM sync requested and the client
        service started if it was stopped. Re-run NSCLIENT-Validation.ps1 after a policy cycle.
.NOTES
    Network Solutions. Default is -WhatIf (preview). Reinstall/repair of the client itself is handled
    by re-pushing the Intune app; deep client repair is vendor-specific and DEFERRED to Netskope docs.
#>
[CmdletBinding()]
param(
    [switch]$Apply  # without this, the script runs in -WhatIf preview mode and changes nothing
)
$WhatIf = -not $Apply

Write-Host "=== Netskope client remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if($WhatIf){'PREVIEW (-WhatIf) — no changes'}else{'APPLY'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Green'}))

# 1) Trigger MDM sync so the app/cert re-apply
$deviceEnroller = "$env:WINDIR\System32\deviceenroller.exe"
if ($WhatIf) {
    Write-Host "  WOULD: request MDM sync (deviceenroller.exe /c /AutoEnrollMDM)" -ForegroundColor DarkGray
} else {
    if (Test-Path $deviceEnroller) {
        Start-Process -FilePath $deviceEnroller -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
        Write-Host "  MDM sync requested." -ForegroundColor Green
    } else {
        Write-Host "  deviceenroller.exe not found — sync via Settings -> Access work or school." -ForegroundColor Yellow
    }
}

# 2) Start the client service if present but stopped (service names DEFERRED to Netskope docs)
$svcNames = @('stagentsvc','nsclientservice','netskope')
$svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $svcNames -contains $_.Name.ToLower() -or $_.DisplayName -match 'Netskope' } | Select-Object -First 1
if ($svc) {
    if ($svc.Status -ne 'Running') {
        if ($WhatIf) { Write-Host ("  WOULD: start stopped client service '{0}'" -f $svc.Name) -ForegroundColor DarkGray }
        else {
            try { Start-Service $svc.Name -ErrorAction Stop; Write-Host ("  Started client service '{0}'." -f $svc.Name) -ForegroundColor Green }
            catch { Write-Host ("  Could not start '{0}': {1}" -f $svc.Name, $_.Exception.Message) -ForegroundColor Yellow }
        }
    } else {
        Write-Host ("  Client service '{0}' already running." -f $svc.Name) -ForegroundColor Green
    }
} else {
    Write-Host "  No Netskope client service found — re-push the Intune app to (re)install." -ForegroundColor Yellow
}

Write-Host "`nNext: after a policy cycle, re-run NSCLIENT-Validation.ps1." -ForegroundColor Green
if ($WhatIf) { Write-Host "Re-run with -Apply to perform the actions above." -ForegroundColor Yellow }
