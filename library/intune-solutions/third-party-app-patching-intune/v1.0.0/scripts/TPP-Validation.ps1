<#
.SYNOPSIS
    TPP-Validation.ps1 — validate that managed third-party apps on this device meet their target versions.
.DESCRIPTION
    PURPOSE
        Compares the installed version of each managed app (from the uninstall registry keys) against
        a target version you supply, and reports whether the device's third-party patch state is OK.
        This confirms a catalog auto-update or a packaged Win32 update actually reached the target.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\TPP-Validation.ps1
        Edit the $Targets table below (or pass -TargetsCsv with columns NameLike,MinVersion) to list
        the apps you manage and their required minimum versions.
        Example CSV row:  NameLike,MinVersion
                          *Reader*,24.1.0
    EXPECTED RESULTS
        Per-app PASS/FAIL and an overall result: "PATCH STATE OK" (exit 0) or "OUT OF DATE" (exit 1).
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only (no changes are made).
#>
[CmdletBinding()] param([string]$TargetsCsv)

# Default targets — substitute your real managed apps and target versions (placeholders shown).
$Targets = @(
    [pscustomobject]@{ NameLike = '*Reader*';  MinVersion = '0.0.0' },
    [pscustomobject]@{ NameLike = '*Browser*'; MinVersion = '0.0.0' }
)
if ($TargetsCsv) { $Targets = Import-Csv -Path $TargetsCsv }

$keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$installed = Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName }

Write-Host "=== Third-party patch-state validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$allOk = $true

foreach ($t in $Targets) {
    $match = $installed | Where-Object { $_.DisplayName -like $t.NameLike } |
        Sort-Object { try { [version]$_.DisplayVersion } catch { [version]'0.0' } } -Descending |
        Select-Object -First 1

    if (-not $match) {
        Write-Host ("  [n/a]  {0}  — not installed" -f $t.NameLike) -ForegroundColor DarkGray
        continue
    }

    $ok = $false
    try { $ok = [version]$match.DisplayVersion -ge [version]$t.MinVersion } catch { $ok = $false }
    if ($ok) {
        Write-Host ("  PASS   {0}  {1}  (target >= {2})" -f $match.DisplayName, $match.DisplayVersion, $t.MinVersion) -ForegroundColor Green
    } else {
        Write-Host ("  FAIL   {0}  {1}  (target >= {2})" -f $match.DisplayName, $match.DisplayVersion, $t.MinVersion) -ForegroundColor Yellow
        $allOk = $false
    }
}

if ($allOk) { Write-Host "`nResult: PATCH STATE OK" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: OUT OF DATE — run TPP-Remediation.ps1 / confirm assignment + detection" -ForegroundColor Yellow; exit 1 }
