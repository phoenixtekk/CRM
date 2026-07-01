<#
.SYNOPSIS
    TPP-Discovery.ps1 — inventory installed third-party applications and versions on this device.
.DESCRIPTION
    PURPOSE
        Reads the Windows uninstall registry keys (both 64-bit and 32-bit hives) to list every
        installed application with its DisplayVersion and Publisher, so you can see which
        third-party apps and versions are present and decide what to manage in Intune.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\TPP-Discovery.ps1
        Optional: -CsvPath C:\Temp\tpp-installed.csv   to export the inventory.
        Optional: -ExcludeMicrosoft                    to hide Microsoft-published apps.
    EXPECTED RESULTS
        A table of installed apps (Name, Version, Publisher) and an optional CSV. Read-only.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only (no changes are made).
#>
[CmdletBinding()] param([string]$CsvPath, [switch]$ExcludeMicrosoft)

Write-Host "`n=== Installed third-party applications ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

$keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$apps = Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
    ForEach-Object {
        [pscustomobject]@{
            Name      = $_.DisplayName
            Version   = $_.DisplayVersion
            Publisher = $_.Publisher
        }
    } | Sort-Object Name -Unique

if ($ExcludeMicrosoft) {
    $apps = $apps | Where-Object { $_.Publisher -notmatch 'Microsoft' }
}

$apps | Format-Table -AutoSize
Write-Host ("Total applications: {0}" -f @($apps).Count) -ForegroundColor Cyan

if ($CsvPath) {
    $apps | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Saved $CsvPath" -ForegroundColor Green
}
