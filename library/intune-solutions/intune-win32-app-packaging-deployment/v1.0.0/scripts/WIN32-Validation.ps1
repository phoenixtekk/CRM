<#
.SYNOPSIS
    WIN32-Validation.ps1 — validate a Win32 app install + detection rule on a device.
.DESCRIPTION
    PURPOSE
        Read-only check, run on a target device, that confirms (a) the Intune Management Extension is
        present and (b) the app's detection rule matches — i.e. the app is actually detectable the way
        Intune will test for it. Mirror the detection rule you configured in Intune.
    HOW TO RUN
        MSI product code:
          powershell -ExecutionPolicy Bypass -File .\WIN32-Validation.ps1 -DetectionType MSI -ProductCode "{PRODUCT-GUID}"
        File + version:
          powershell -ExecutionPolicy Bypass -File .\WIN32-Validation.ps1 -DetectionType File `
            -FilePath "C:\Program Files\Contoso\LOB\ContosoLOB.exe" -MinVersion 4.2.0
        Registry value:
          powershell -ExecutionPolicy Bypass -File .\WIN32-Validation.ps1 -DetectionType Registry `
            -RegPath "HKLM:\SOFTWARE\Contoso\LOB" -RegName "Version" -RegValue "4.2.0"
    EXPECTED RESULTS
        IME service status, and DETECTED / NOT DETECTED for the chosen rule. No changes are made.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only; no system changes.
#>
[CmdletBinding()]
param(
    [ValidateSet('MSI','File','Registry')] [string]$DetectionType = 'MSI',
    [string]$ProductCode,
    [string]$FilePath,
    [string]$MinVersion,
    [string]$RegPath,
    [string]$RegName,
    [string]$RegValue
)

Write-Host "=== Win32 App Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

$ime = Get-Service -Name 'Microsoft Intune Management Extension' -ErrorAction SilentlyContinue
if ($ime) { Write-Host ("  IME service: {0}" -f $ime.Status) -ForegroundColor Green }
else      { Write-Host "  IME service: NOT FOUND — Win32 apps will not install until it is present." -ForegroundColor Yellow }

$detected = $false
switch ($DetectionType) {
    'MSI' {
        if (-not $ProductCode) { throw "Provide -ProductCode for MSI detection." }
        $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
        $key6432 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
        $detected = (Test-Path $key) -or (Test-Path $key6432)
        Write-Host ("  MSI product code {0}: {1}" -f $ProductCode, ($detected ? 'DETECTED' : 'NOT DETECTED'))
    }
    'File' {
        if (-not $FilePath) { throw "Provide -FilePath for File detection." }
        if (Test-Path $FilePath) {
            if ($MinVersion) {
                $ver = (Get-Item $FilePath).VersionInfo.FileVersion
                $detected = [version]$ver -ge [version]$MinVersion
                Write-Host ("  File {0} version {1} (need >= {2}): {3}" -f $FilePath, $ver, $MinVersion, ($detected ? 'DETECTED' : 'NOT DETECTED'))
            } else {
                $detected = $true
                Write-Host ("  File {0}: DETECTED" -f $FilePath)
            }
        } else { Write-Host ("  File {0}: NOT DETECTED" -f $FilePath) }
    }
    'Registry' {
        if (-not $RegPath -or -not $RegName) { throw "Provide -RegPath and -RegName for Registry detection." }
        $val = (Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction SilentlyContinue).$RegName
        if ($null -ne $val) {
            $detected = (-not $RegValue) -or ("$val" -eq "$RegValue")
            Write-Host ("  Registry {0}\{1} = '{2}': {3}" -f $RegPath, $RegName, $val, ($detected ? 'DETECTED' : 'NOT DETECTED'))
        } else { Write-Host ("  Registry {0}\{1}: NOT DETECTED" -f $RegPath, $RegName) }
    }
}

if ($detected) { Write-Host "`nRESULT: App is DETECTED — Intune should report Installed." -ForegroundColor Green }
else           { Write-Host "`nRESULT: App is NOT DETECTED — Intune will report Failed or reinstall. Fix the detection rule." -ForegroundColor Yellow }
