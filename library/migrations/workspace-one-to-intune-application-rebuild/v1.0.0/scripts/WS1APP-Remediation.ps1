<#
.SYNOPSIS
    WS1APP-Remediation.ps1 — safely re-drive a failed app install on this device (default -WhatIf).
.DESCRIPTION
    PURPOSE
        For a pilot/broad device where a rebuilt app shows Failed or Pending, this forces an MDM
        sync so Intune re-evaluates app assignments and re-attempts the install, then restarts the
        Intune Management Extension service that drives Win32 app delivery. SAFE BY DEFAULT: runs in
        -WhatIf mode and only reports the actions; pass -WhatIf:$false to actually run them.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\WS1APP-Remediation.ps1
        Execute          : powershell -ExecutionPolicy Bypass -File .\WS1APP-Remediation.ps1 -WhatIf:$false
        Run elevated to restart the Intune Management Extension service.
    EXPECTED RESULTS
        In preview, the actions it WOULD take. When executed, an MDM sync is requested and the
        Intune Management Extension re-attempts delivery; re-run WS1APP-Validation.ps1 after a cycle.
.NOTES
    Workplace Marketplace — Migrations.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

# Honour -WhatIf by default: if the caller did not specify -WhatIf, default it to $true.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== App install remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "(preview mode — pass -WhatIf:`$false to execute)" -ForegroundColor Yellow }

# 1) Request an MDM sync so Intune re-evaluates app assignments.
if ($PSCmdlet.ShouldProcess('this device', 'Request MDM sync (deviceenroller /c /AutoEnrollMDM)')) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList '/c /AutoEnrollMDM' -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

# 2) Restart the Intune Management Extension so Win32 app delivery re-attempts.
$svc = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if ($svc) {
    if ($PSCmdlet.ShouldProcess('IntuneManagementExtension service', 'Restart')) {
        try { Restart-Service -Name IntuneManagementExtension -Force -ErrorAction Stop; Write-Host "  Intune Management Extension restarted." -ForegroundColor Green }
        catch { Write-Host "  Could not restart the Intune Management Extension (run elevated): $($_.Exception.Message)" -ForegroundColor Yellow }
    }
} else {
    Write-Host "  Intune Management Extension service not found (expected on Win32-targeted devices)." -ForegroundColor Yellow
}

Write-Host "`nRe-run WS1APP-Validation.ps1 after a policy cycle to confirm the app installs and is detected." -ForegroundColor Green
