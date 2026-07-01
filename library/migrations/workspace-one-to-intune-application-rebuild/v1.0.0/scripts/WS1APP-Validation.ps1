<#
.SYNOPSIS
    WS1APP-Validation.ps1 — confirm a rebuilt app installed and its detection rule matches locally.
.DESCRIPTION
    PURPOSE
        Read-only. Checks that a rebuilt Win32 app is present on THIS device using the same
        authoritative detection signal you authored in Intune (MSI product code, installed file
        version, or registry uninstall key + DisplayVersion). Use it on a pilot device as the
        per-app validation gate before expanding to the broad ring.
    HOW TO RUN
        MSI      : powershell -ExecutionPolicy Bypass -File .\WS1APP-Validation.ps1 -DetectionType MSI -ProductCode "{PRODUCT-GUID}"
        File     : powershell -ExecutionPolicy Bypass -File .\WS1APP-Validation.ps1 -DetectionType File -FilePath "C:\Program Files\Acme\Field\AcmeField.exe" -MinVersion 4.2.0
        Registry : powershell -ExecutionPolicy Bypass -File .\WS1APP-Validation.ps1 -DetectionType Registry -DisplayName "Acme Field Suite" -MinVersion 4.2.0
    EXPECTED RESULTS
        "DETECTED" (exit 0) when the app matches the detection rule; "NOT DETECTED" (exit 1) otherwise.
.NOTES
    Workplace Marketplace — Migrations. Read-only.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][ValidateSet('MSI', 'File', 'Registry')][string]$DetectionType,
    [string]$ProductCode,
    [string]$FilePath,
    [string]$DisplayName,
    [string]$MinVersion
)

Write-Host "=== App detection validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$detected = $false

switch ($DetectionType) {
    'MSI' {
        if (-not $ProductCode) { throw 'Provide -ProductCode for DetectionType MSI.' }
        $pkg = Get-Package -ProviderName msi -ErrorAction SilentlyContinue |
            Where-Object { $_.FastPackageReference -like "*$ProductCode*" -or $_.Metadata['ProductCode'] -eq $ProductCode }
        if ($pkg) { $detected = $true; Write-Host ("Found MSI product: {0} {1}" -f $pkg.Name, $pkg.Version) }
    }
    'File' {
        if (-not $FilePath) { throw 'Provide -FilePath for DetectionType File.' }
        if (Test-Path $FilePath) {
            $ver = (Get-Item $FilePath).VersionInfo.FileVersion
            Write-Host ("Found file: {0} (version {1})" -f $FilePath, $ver)
            if (-not $MinVersion) { $detected = $true }
            elseif ($ver -and [version]($ver -replace '[^0-9.]', '') -ge [version]$MinVersion) { $detected = $true }
        }
    }
    'Registry' {
        if (-not $DisplayName) { throw 'Provide -DisplayName for DetectionType Registry.' }
        $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        $hit = Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$DisplayName*" } | Select-Object -First 1
        if ($hit) {
            Write-Host ("Found registry entry: {0} (version {1})" -f $hit.DisplayName, $hit.DisplayVersion)
            if (-not $MinVersion) { $detected = $true }
            elseif ($hit.DisplayVersion -and [version]($hit.DisplayVersion -replace '[^0-9.]', '') -ge [version]$MinVersion) { $detected = $true }
        }
    }
}

if ($detected) { Write-Host "`nResult: DETECTED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT DETECTED — confirm install, then re-check the detection rule in Intune" -ForegroundColor Yellow; exit 1 }
