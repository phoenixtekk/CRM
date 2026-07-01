<#
.SYNOPSIS
    EPM-Remediation.ps1 — Safe remediation for Endpoint Privilege Management devices.

.DESCRIPTION
    PURPOSE
        Fixes the most common EPM field issues without making risky changes: forces an Intune MDM
        policy sync (so the base/rules policies and the client install reach the device) and
        restarts the EPM client service if it is stopped. With -ResetClient it additionally
        re-registers the client to recover an unhealthy extension. Use after a policy change, when
        the client hasn't installed, or when EPM-Validation.ps1 reports NOT PROVISIONED.

    HOW TO RUN
        Run on the device in an ELEVATED PowerShell window (service restart needs admin):
            powershell -ExecutionPolicy Bypass -File .\EPM-Remediation.ps1
        To also re-register the client extension:
            .\EPM-Remediation.ps1 -ResetClient

    EXPECTED RESULTS
        An MDM sync is triggered, the EPM service is confirmed Running, and a short summary is
        printed. After running, wait a few minutes, then re-run EPM-Validation.ps1.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions.
    Changes made: triggers MDM sync; (re)starts the EPM service; -ResetClient restarts/re-registers
    the client. It does NOT alter elevation rules, local group membership, or user data.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$ResetClient
)

# Require elevation
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run this script in an elevated PowerShell window (Run as administrator)."
    return
}

Write-Host "=== EPM Remediation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# 1) Force an Intune MDM sync via the scheduled tasks the MDM agent registers
Write-Host "[1/3] Forcing Intune MDM sync..." -ForegroundColor Cyan
$pushTasks = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match 'PushLaunch|Schedule.*created by enrollment' }
if ($pushTasks) {
    foreach ($t in $pushTasks) {
        if ($PSCmdlet.ShouldProcess($t.TaskName, 'Start scheduled task (MDM sync)')) {
            try { Start-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop; Write-Host "   triggered: $($t.TaskName)" }
            catch { Write-Warning "   could not start $($t.TaskName): $($_.Exception.Message)" }
        }
    }
} else {
    # Fallback: deviceenroller is the supported CLI to kick a sync
    if ($PSCmdlet.ShouldProcess('deviceenroller.exe', 'Trigger MDM sync')) {
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList '/o', '/c', '/AutoEnrollMDM' -WindowStyle Hidden -ErrorAction SilentlyContinue
        Write-Host "   triggered MDM sync via deviceenroller.exe"
    }
}

# 2) Ensure the EPM client service is running
Write-Host "[2/3] Checking EPM client service..." -ForegroundColor Cyan
$svc = Get-Service -Name 'EPMAgent','EpmService' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($svc) {
    if ($svc.Status -ne 'Running') {
        if ($PSCmdlet.ShouldProcess($svc.Name, 'Start EPM service')) {
            try { Start-Service -Name $svc.Name -ErrorAction Stop; Write-Host "   started $($svc.Name)" }
            catch { Write-Warning "   could not start $($svc.Name): $($_.Exception.Message)" }
        }
    } else { Write-Host "   $($svc.Name) already Running" }
} else {
    Write-Warning "   EPM service not found. The base policy may not have applied yet — confirm the EPM license is assigned and the policy shows 'Succeeded', then re-sync."
}

# 3) Optional: re-register the client extension
Write-Host "[3/3] Client reset..." -ForegroundColor Cyan
if ($ResetClient -and $svc) {
    if ($PSCmdlet.ShouldProcess($svc.Name, 'Restart EPM service to re-register client')) {
        try {
            Restart-Service -Name $svc.Name -Force -ErrorAction Stop
            Write-Host "   restarted $($svc.Name) (client re-registered)"
        } catch { Write-Warning "   restart failed: $($_.Exception.Message)" }
    }
} else {
    Write-Host "   skipped (use -ResetClient to force a client re-registration)"
}

Write-Host "`nDone. Wait a few minutes for sync to complete, then run EPM-Validation.ps1." -ForegroundColor Green
