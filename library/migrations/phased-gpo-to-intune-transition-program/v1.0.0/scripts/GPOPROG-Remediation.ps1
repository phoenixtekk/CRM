<#
.SYNOPSIS
    GPOPROG-Remediation.ps1 — safely resolve a precedence conflict (-WhatIf default).
.DESCRIPTION
    PURPOSE
        Resolves the most common transition conflict: Group Policy still winning over migrated Intune
        settings (the precedence fight behind same-setting conflicts and evaluation loops). It sets
        the local MDMWinsOverGP (ControlPolicyConflict) value so MDM/Intune wins, then requests an MDM
        sync so policy re-evaluates. Runs in -WhatIf mode by DEFAULT and changes nothing until you
        pass -Apply. The durable fix is the Intune policy 'Coexistence Policy - MDM Wins Over GP - All
        Migrated' plus scoping the legacy GPO away for the affected area; this script unblocks a device
        for per-phase testing.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Remediation.ps1
        Apply on a phase-scope pilot device (elevated):
            powershell -ExecutionPolicy Bypass -File .\GPOPROG-Remediation.ps1 -Apply
    EXPECTED RESULTS
        In preview: prints what WOULD change (MDMWinsOverGP -> 1) and exits. With -Apply: sets
        MDMWinsOverGP=1, requests an MDM sync, and advises re-running GPOPROG-Validation.ps1 and
        scoping the legacy GPO away for the conflicting area.
.NOTES
    Workplace Marketplace — Migrations. -WhatIf by default; -Apply makes changes.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch] $Apply
)

# Default to preview/WhatIf unless -Apply is explicitly passed.
if (-not $Apply) { $WhatIfPreference = $true }

Write-Host "`n=== Precedence conflict remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "MODE: PREVIEW (-WhatIf) — no changes will be made. Re-run with -Apply to change." -ForegroundColor Yellow }

$key = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict'
$cur = (Get-ItemProperty $key -ErrorAction SilentlyContinue).MDMWinsOverGP
Write-Host ("Current MDMWinsOverGP : {0}" -f ($(if ($null -ne $cur) { $cur } else { 'not set' })))

if ($cur -eq 1) {
    Write-Host "Already set to MDM-wins — no precedence change needed. If a conflict/loop persists, the legacy GPO for that area is still linked; scope it away." -ForegroundColor Green
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

Write-Host "`nThe durable fix is the Intune policy 'Coexistence Policy - MDM Wins Over GP - All Migrated' PLUS scoping the legacy GPO away for the conflicting area (one authority per setting)." -ForegroundColor Gray
Write-Host "After a policy cycle, re-run GPOPROG-Validation.ps1 -Phase '<Phase>' to confirm the conflict/loop is resolved." -ForegroundColor Green
