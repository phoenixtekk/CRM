<#
.SYNOPSIS
    SCCMAPP-Validation.ps1 — confirm a migrated app installed and its detection rule matches (parity).
.DESCRIPTION
    PURPOSE
        Post-migration parity check for one app: verifies the on-device install evidence (MSI product
        code / file+version / registry value) that the Intune Win32 detection rule relies on, so you
        can confirm Intune will report Installed the same way SCCM detected it.
    HOW TO RUN
        On a pilot device, elevated. Provide the same detection evidence you configured in Intune:
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Validation.ps1 -DetectionType MSI -ProductCode "{PRODUCT-GUID}"
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Validation.ps1 -DetectionType File -Path "C:\Program Files\LOB\Reader\LOBReader.exe" -MinVersion 4.2.0
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Validation.ps1 -DetectionType Registry -RegPath "HKLM:\SOFTWARE\LOB\Reader" -RegValue Version
    EXPECTED RESULTS
        "DETECTION PARITY: PASS" when the on-device evidence matches the rule; "FAIL" if it does not.
.NOTES
    White-label — Migrations. Read-only on the device.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][ValidateSet('MSI','File','Registry')][string]$DetectionType,
    [string]$ProductCode,
    [string]$Path,
    [string]$MinVersion,
    [string]$RegPath,
    [string]$RegValue
)
Write-Host "=== SCCMAPP Validation — $($env:COMPUTERNAME) ($DetectionType) ===" -ForegroundColor Cyan
$pass = $false
switch ($DetectionType) {
    'MSI' {
        if (-not $ProductCode) { throw 'Provide -ProductCode for MSI detection.' }
        $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        $found = Get-ItemProperty $keys -ErrorAction SilentlyContinue |
                 Where-Object { $_.PSChildName -eq $ProductCode }
        if ($found) { Write-Host ("Found MSI product {0} ({1})" -f $ProductCode, $found.DisplayVersion) -ForegroundColor Green; $pass = $true }
        else { Write-Host "MSI product code not present." -ForegroundColor Yellow }
    }
    'File' {
        if (-not $Path) { throw 'Provide -Path for File detection.' }
        if (Test-Path $Path) {
            $ver = (Get-Item $Path).VersionInfo.FileVersion
            if ($MinVersion -and $ver) { $pass = [version]$ver -ge [version]$MinVersion }
            else { $pass = $true }
            Write-Host ("File present: {0} (version {1}; min {2})" -f $Path, $ver, ($MinVersion ? $MinVersion : 'n/a')) -ForegroundColor ($(if($pass){'Green'}else{'Yellow'}))
        } else { Write-Host "File not present." -ForegroundColor Yellow }
    }
    'Registry' {
        if (-not $RegPath) { throw 'Provide -RegPath for Registry detection.' }
        $p = Get-ItemProperty $RegPath -ErrorAction SilentlyContinue
        if ($p -and ((-not $RegValue) -or ($null -ne $p.$RegValue))) {
            Write-Host ("Registry present: {0}\{1} = {2}" -f $RegPath, $RegValue, ($RegValue ? $p.$RegValue : '(key exists)')) -ForegroundColor Green; $pass = $true
        } else { Write-Host "Registry evidence not present." -ForegroundColor Yellow }
    }
}
if ($pass) { Write-Host "`nResult: DETECTION PARITY: PASS" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: DETECTION PARITY: FAIL — the Intune detection rule will not match; re-check install + rule." -ForegroundColor Yellow; exit 1 }
