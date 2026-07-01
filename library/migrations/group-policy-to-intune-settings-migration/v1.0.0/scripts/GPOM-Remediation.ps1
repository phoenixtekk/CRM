<#
.SYNOPSIS
    GPOM-Remediation.ps1 — safely resolve conflicting GPO/Intune policy precedence (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Resolves the most common migration conflict: Group Policy still winning over migrated Intune
        settings. It sets the local MDMWinsOverGP (ControlPolicyConflict) value so MDM/Intune wins,
        then requests an MDM sync so policy re-evaluates. Runs in -WhatIf mode by DEFAULT and changes
        nothing until you pass -Apply. The durable fix is the Intune coexistence policy
        'GPO Migration - MDM Wins Over GP - All Migrated'; this script unblocks a device for testing.
    HOW TO RUN
        Preview (default, no changes):  powershell -ExecutionPolicy Bypass -File .\GPOM-Remediation.ps1
        Apply on a pilot device (elevated): powershell -ExecutionPolicy Bypass -File .\GPOM-Remediation.ps1 -Apply
    EXPECTED RESULTS
        In preview: prints what WOULD change (MDMWinsOverGP -> 1) and exits. With -Apply: sets
        MDMWinsOverGP=1, requests an MDM sync, and advises re-running GPOM-Validation.ps1.
.NOTES
    Workplace Marketplace — Intune Solutions. -WhatIf by default; -Apply makes changes.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $Apply
)

# Default to preview/WhatIf unless -Apply is explicitly passed.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== GPO/Intune precedence remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf) — no changes will be made. Re-run with -Apply to change." -ForegroundColor Yellow }

$key  = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict'
$cur  = (Get-ItemProperty $key -ErrorAction SilentlyContinue).MDMWinsOverGP
Write-Host ("Current MDMWinsOverGP : {0}" -f ($(if ($null -ne $cur) { $cur } else { 'not set' })))

if ($cur -eq 1) {
    Write-Host "Already set to MDM-wins — no precedence change needed." -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($key, "Set MDMWinsOverGP = 1 (Intune wins over GPO)")) {
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        New-ItemProperty -Path $key -Name 'MDMWinsOverGP' -PropertyType DWord -Value 1 -Force | Out-Null
        Write-Host "Set MDMWinsOverGP = 1." -ForegroundColor Green
    }
}

# Request an MDM sync so policy re-evaluates (also gated by ShouldProcess).
if ($PSCmdlet.ShouldProcess("$env:COMPUTERNAME", "Request MDM/Intune sync")) {
    try {
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden -ErrorAction Stop
        Write-Host "MDM sync requested." -ForegroundColor Green
    } catch {
        Write-Host "Could not request sync automatically: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`nThe durable fix is the Intune policy 'GPO Migration - MDM Wins Over GP - All Migrated'." -ForegroundColor Gray
Write-Host "After a policy cycle, re-run GPOM-Validation.ps1 to confirm parity." -ForegroundColor Green
