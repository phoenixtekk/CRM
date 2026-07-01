<#
.SYNOPSIS
    EPICCLIENT-Remediation.ps1 — Safely re-triggers install/uninstall of the named Epic client app for a device.

.DESCRIPTION
    PURPOSE
        Recovers a single device whose Epic client deployment is stuck: it forces an Intune MDM sync
        (so the assigned Win32 app and its detection re-evaluate and install/uninstall actions reach
        the device) and reports the current Epic client state. With -Apply it triggers the sync; by
        default it runs read-only / -WhatIf so you can preview. It does NOT silently push installers
        on its own — the actual install/uninstall is performed by the Intune-assigned named app
        ("Epic Hyperdrive - <EPIC_VERSION>"); this script nudges the device to act on that assignment.

    HOW TO RUN
        On the affected device. Preview first (no changes):
            powershell -ExecutionPolicy Bypass -File .\EPICCLIENT-Remediation.ps1 -AppName "Epic Hyperdrive - <EPIC_VERSION>"
        Then act (triggers an MDM sync; run elevated):
            .\EPICCLIENT-Remediation.ps1 -AppName "Epic Hyperdrive - <EPIC_VERSION>" -Apply

    EXPECTED RESULTS
        A summary of the current Epic client state and, with -Apply, a triggered MDM sync. Wait a few
        minutes for Intune to re-evaluate the assignment, then re-run EPICCLIENT-Validation.ps1.

.NOTES
    Healthcare Solutions — read-only by default (-WhatIf). The only change -Apply makes is triggering
    an Intune MDM sync; it does not alter the Epic client, user data, or assignments. Reports
    device/app state only; never captures patient data.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The exact Intune Win32 app display name this device should converge to.
    [Parameter(Mandatory)][string]$AppName,
    [switch]$Apply
)

Write-Host "=== Epic Client Remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
Write-Host "Target assigned app: '$AppName'" -ForegroundColor Cyan

# 1) Report current state (read-only)
Write-Host "[1/2] Current Epic client state..." -ForegroundColor Cyan
$found = $false
foreach ($root in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
    Get-ItemProperty $root -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Epic|Hyperdrive|Hyperspace' } |
        ForEach-Object { Write-Host "   present: $($_.DisplayName) $($_.DisplayVersion)"; $found = $true }
}
if (-not $found) { Write-Host "   no Epic client currently registered on this device." }

# 2) Trigger an Intune MDM sync so the assignment re-evaluates
Write-Host "[2/2] Trigger Intune MDM sync (re-evaluate the assigned app)..." -ForegroundColor Cyan
$doIt = $Apply -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Trigger Intune MDM sync')
if (-not $Apply) {
    Write-Host "   (preview) would trigger an MDM sync. Re-run with -Apply to act." -ForegroundColor Yellow
} elseif ($doIt) {
    $pushTasks = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -match 'PushLaunch|Schedule.*created by enrollment' }
    if ($pushTasks) {
        foreach ($t in $pushTasks) {
            try { Start-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop; Write-Host "   triggered: $($t.TaskName)" }
            catch { Write-Warning "   could not start $($t.TaskName): $($_.Exception.Message)" }
        }
    } else {
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList '/o','/c','/AutoEnrollMDM' -WindowStyle Hidden -ErrorAction SilentlyContinue
        Write-Host "   triggered MDM sync via deviceenroller.exe"
    }
}

Write-Host "`nDone. Wait a few minutes for Intune to re-evaluate '$AppName', then run EPICCLIENT-Validation.ps1." -ForegroundColor Green
Write-Host "If the app still won't install/uninstall, check the version-pinned detection rule and the app's install/uninstall command (Troubleshooting Section 6)." -ForegroundColor Yellow
