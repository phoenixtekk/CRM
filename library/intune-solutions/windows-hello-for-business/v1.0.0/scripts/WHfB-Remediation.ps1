<#
.SYNOPSIS
    WHfB-Remediation.ps1 — safe remediation for stalled Windows Hello for Business enrollment.

.DESCRIPTION
    PURPOSE
        Resolves the common causes of a device that will not provision WHfB: forces an MDM
        policy sync, restarts the enrollment, and — only when explicitly requested — resets the
        user's NGC (Hello) container to force a clean re-enrollment.

    HOW TO RUN
        Standard (safe) remediation — sync + restart provisioning, no data reset:
            powershell -ExecutionPolicy Bypass -File .\WHfB-Remediation.ps1
        Force a full container reset (DESTRUCTIVE to existing Hello keys on THIS device; user
        must re-enroll PIN/biometrics). Gated behind an explicit switch and confirmation:
            .\WHfB-Remediation.ps1 -ResetContainer

    EXPECTED RESULTS
        Standard: an MDM sync is triggered; the device should provision WHfB at next sign-in.
        -ResetContainer: the NGC container is cleared; the user is prompted to set up a PIN again.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions.
    The reset path is intentionally hard to trigger by accident.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$ResetContainer
)

Write-Host "=== WHfB Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# 1) Force MDM sync (safe, always)
Write-Host "Triggering Intune/MDM policy sync..."
try {
    $enrollKey = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction Stop |
        Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).EnrollmentState -eq 1 } |
        Select-Object -First 1
    if ($enrollKey) {
        $deviceId = Split-Path $enrollKey.PSPath -Leaf
        Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
        Write-Host "  MDM sync requested (enrollment $deviceId)." -ForegroundColor Green
    } else {
        Write-Host "  No active MDM enrollment found — confirm the device is enrolled in Intune." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Sync step failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2) Restart the provisioning task
try {
    Start-ScheduledTask -TaskPath '\Microsoft\Windows\NGC\' -TaskName 'WAM Sync*' -ErrorAction SilentlyContinue
} catch {}

if (-not $ResetContainer) {
    Write-Host "`nStandard remediation complete. Sign out and back in to trigger WHfB enrollment." -ForegroundColor Green
    Write-Host "If it still fails, re-run with -ResetContainer (forces a clean re-enrollment)." -ForegroundColor Gray
    return
}

# 3) DESTRUCTIVE: reset NGC container (explicit + confirmed)
Write-Host "`n-ResetContainer requested. This clears the local Hello container; the user must re-enroll PIN/biometrics on THIS device." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess("$env:COMPUTERNAME NGC container", "Reset Windows Hello container (certutil -deletehellocontainer)")) {
    try {
        & certutil.exe -deletehellocontainer
        Write-Host "NGC container reset. Sign out and back in; Windows will prompt to set up a PIN." -ForegroundColor Green
    } catch {
        Write-Host "Reset failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
