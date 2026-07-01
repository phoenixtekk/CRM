<#
.SYNOPSIS
    Get-AutopilotHash.ps1 — collect a device's Windows Autopilot hardware hash to a CSV.

.DESCRIPTION
    PURPOSE
        Captures the local device's Autopilot hardware identity (4K HH) and writes a CSV ready
        to import into Intune (Devices > Enrollment > Devices > Import).

    HOW TO RUN
        In an elevated PowerShell window on the device:
            powershell -ExecutionPolicy Bypass -File .\Get-AutopilotHash.ps1 -OutFile C:\Temp\AutopilotHWID.csv
        Collect multiple devices by appending to the same CSV with -Append.

    EXPECTED RESULTS
        A CSV with Device Serial Number, Windows Product ID, and Hardware Hash columns. Import it
        in Intune to register the device for Autopilot.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Uses Microsoft's Get-WindowsAutopilotInfo.
#>
[CmdletBinding()]
param([string]$OutFile = ".\AutopilotHWID.csv", [switch]$Append)

if (-not (Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Get-WindowsAutopilotInfo..." -ForegroundColor Yellow
    Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
}
$env:Path += ";$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Scripts"

$args = @{ OutputFile = $OutFile }
if ($Append) { $args['Append'] = $true }
Get-WindowsAutopilotInfo @args

if (Test-Path $OutFile) {
    Write-Host "Hardware hash written to $OutFile" -ForegroundColor Green
    Write-Host "Import it in Intune: Devices > Enrollment > Devices > Import."
} else {
    Write-Host "Failed to produce $OutFile — run elevated and retry." -ForegroundColor Red; exit 1
}
