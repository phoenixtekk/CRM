<#
.SYNOPSIS
    ODFB-Remediation.ps1 — safe remediation for OneDrive for Business configuration/sync issues.

.DESCRIPTION
    PURPOSE
        Resolves the common causes of OneDrive not configuring or not syncing: forces an MDM
        policy sync, restarts the OneDrive client, and — only when explicitly requested — runs a
        OneDrive sync reset (re-links the account; does not delete cloud files).

    HOW TO RUN
        Standard (safe) — MDM sync + restart OneDrive, no reset:
            powershell -ExecutionPolicy Bypass -File .\ODFB-Remediation.ps1
        Force a OneDrive sync reset (re-initializes the local sync; cloud files are NOT deleted,
        but re-sync may take time). Gated behind a switch + confirmation:
            .\ODFB-Remediation.ps1 -ResetSync

    EXPECTED RESULTS
        Standard: policy re-syncs and OneDrive restarts; configuration should apply at next cycle.
        -ResetSync: OneDrive re-initializes and signs in fresh.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. The reset path does not delete cloud data.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param([switch]$ResetSync)

Write-Host "=== OneDrive Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# locate OneDrive.exe
$od = @("$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe") |
      Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $od) { Write-Host "OneDrive client not found — deploy it via Intune first." -ForegroundColor Yellow; exit 1 }

# 1) force MDM sync (safe)
Write-Host "Triggering Intune/MDM policy sync..."
try {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
} catch { Write-Host "  Sync step skipped: $($_.Exception.Message)" -ForegroundColor Yellow }

# 2) restart OneDrive (safe)
Write-Host "Restarting OneDrive client..."
Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Process $od

if (-not $ResetSync) {
    Write-Host "`nStandard remediation complete. Allow a policy cycle, then re-run ODFB-Validation.ps1." -ForegroundColor Green
    Write-Host "If sync is still broken, re-run with -ResetSync." -ForegroundColor Gray
    return
}

# 3) sync reset (explicit + confirmed; does NOT delete cloud files)
Write-Host "`n-ResetSync requested. This re-initializes the local OneDrive sync (cloud files are NOT deleted)." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess("$env:COMPUTERNAME OneDrive", "Run OneDrive.exe /reset")) {
    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
    & $od /reset
    Start-Sleep 5
    Start-Process $od
    Write-Host "OneDrive sync reset issued; it will re-sign in and rebuild the sync." -ForegroundColor Green
}
