<#
.SYNOPSIS
    EHEM-Remediation.ps1 — safely remediate common endpoint-health degradations (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Fixes the most common, low-risk causes of poor endpoint health and missing analytics data:
        forces an MDM/Intune sync so policy and data collection re-apply, ensures diagnostic data is
        at the Required level, and restarts a device that has not rebooted in -StaleRestartDays days
        (a frequent cause of slow, flaky endpoints). SAFE BY DEFAULT: runs in -WhatIf preview mode
        and changes nothing until you pass -WhatIf:$false.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\EHEM-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\EHEM-Remediation.ps1 -WhatIf:$false
        Optional:           -StaleRestartDays 7   (override the restart threshold; 0 = never restart)
    EXPECTED RESULTS
        In preview: a list of the actions that WOULD run. When applied: MDM sync requested, diagnostic
        data set to Required if it was lower, and an optional scheduled restart of a stale device.
.NOTES
    Endpoint Health & Digital Experience Monitoring — Infrastructure. Default -WhatIf (preview).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param([int]$StaleRestartDays = 0)

# Default to preview unless the caller explicitly turns -WhatIf off
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== Endpoint health remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  (preview mode — no changes will be made; pass -WhatIf:`$false to apply)" -ForegroundColor Yellow }

# 1) Force MDM / Intune sync so policy + data collection re-apply
if ($PSCmdlet.ShouldProcess('this device', 'Request MDM/Intune sync')) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
}

# 2) Ensure diagnostic data is at least Required (1) for Endpoint analytics
$dc = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
$tel = (Get-ItemProperty $dc -ErrorAction SilentlyContinue).AllowTelemetry
if ($null -ne $tel -and $tel -lt 1) {
    if ($PSCmdlet.ShouldProcess("AllowTelemetry ($tel -> 1)", 'Raise diagnostic data to Required')) {
        if (-not (Test-Path $dc)) { New-Item -Path $dc -Force | Out-Null }
        New-ItemProperty -Path $dc -Name AllowTelemetry -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Host "  Diagnostic data raised to Required (1)." -ForegroundColor Green
    }
} else {
    Write-Host "  Diagnostic data already sufficient (no change needed)." -ForegroundColor Green
}

# 3) Restart a stale device (opt-in via -StaleRestartDays)
if ($StaleRestartDays -gt 0) {
    $boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime
    if ($boot) {
        $age = [int]((New-TimeSpan -Start $boot -End (Get-Date)).TotalDays)
        if ($age -ge $StaleRestartDays) {
            if ($PSCmdlet.ShouldProcess("this device (last restart $age days ago)", 'Schedule a restart in 10 minutes')) {
                & shutdown.exe /r /t 600 /c "Scheduled restart to maintain endpoint health (no restart in $age days)."
                Write-Host "  Restart scheduled in 10 minutes (cancel with: shutdown /a)." -ForegroundColor Green
            }
        } else { Write-Host "  Restart age OK ($age days < $StaleRestartDays)." -ForegroundColor Green }
    }
}

Write-Host "`nRe-run EHEM-Validation.ps1 after a policy cycle." -ForegroundColor Green
