<#
.SYNOPSIS
    INTBASE-Get-AutopilotHash.ps1 — collect a Windows device's Autopilot hardware hash to a CSV.

.DESCRIPTION
    PURPOSE
        Captures the local device's Autopilot hardware identity (4K HH) and writes a CSV ready to import
        into Intune (Devices > Enrollment > Windows > Devices > Import), so the device can be registered
        for basic Entra-joined Autopilot.

    HOW TO RUN
        In an elevated PowerShell window on the device:
            powershell -ExecutionPolicy Bypass -File .\INTBASE-Get-AutopilotHash.ps1 -OutFile C:\Temp\INTBASE-AutopilotHWID.csv
        Collect multiple devices by appending to the same CSV with -Append.

    EXPECTED RESULTS
        A CSV with Device Serial Number, Windows Product ID, and Hardware Hash columns. Import it in
        Intune to register the device for Autopilot.

.NOTES
    Intune Solutions — uses Microsoft's Get-WindowsAutopilotInfo. Local device only; no Graph writes.
#>
[CmdletBinding()]
param([string]$OutFile = ".\INTBASE-AutopilotHWID.csv", [switch]$Append)

if (-not (Get-InstalledScript -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Get-WindowsAutopilotInfo..." -ForegroundColor Yellow
    Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser
}
$env:Path += ";$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Scripts"

$callArgs = @{ OutputFile = $OutFile }
if ($Append) { $callArgs['Append'] = $true }
Get-WindowsAutopilotInfo @callArgs

if (Test-Path $OutFile) {
    Write-Host "Hardware hash written to $OutFile" -ForegroundColor Green
    Write-Host "Import it in Intune: Devices > Enrollment > Windows > Devices > Import."
    Write-Host "Then add the device to the 'INTBASE - Autopilot Devices' group."
} else {
    Write-Host "Failed to produce $OutFile — run elevated and retry." -ForegroundColor Red; exit 1
}
