<#
.SYNOPSIS
    IMGLIFE-Validation.ps1 - confirm a device is provisioned, Autopilot-registered, enrolled, and inventoried.
.DESCRIPTION
    PURPOSE
        Validates that a device is correctly through the deploy stage of the lifecycle: locally it
        confirms Entra join + MDM enrollment (dsregcmd) and that hardware identity is present; via
        Microsoft Graph it confirms the device exists in Intune managed devices (reporting hardware)
        and, if a serial is supplied, that it is registered to Windows Autopilot. PASS/WARN lines
        make readiness obvious before you move the device into the Deployed stage.
    HOW TO RUN
        Local checks only:
          powershell -ExecutionPolicy Bypass -File .\IMGLIFE-Validation.ps1
        Include cloud checks (Intune + Autopilot) for a specific serial:
          ... -SerialNumber "<device-serial>"
        Cloud checks require the Microsoft Graph PowerShell SDK and consent for
        DeviceManagementManagedDevices.Read.All and DeviceManagementServiceConfig.Read.All (delegated).
    EXPECTED RESULTS
        PASS/WARN lines for Entra join, MDM enrollment, local hardware identity, Intune managed-device
        presence, and Autopilot registration (when a serial is supplied).
.NOTES
    Infrastructure solution - the repeatable way. Read-only (GET only against Graph).
#>
[CmdletBinding()]
param(
    [string]$SerialNumber
)

function Result($ok, $msg) {
    if ($ok) { Write-Host "  PASS  $msg" -ForegroundColor Green }
    else     { Write-Host "  WARN  $msg" -ForegroundColor Yellow }
}

Write-Host "`n=== Provisioning + enrollment validation - $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# Local: Entra join + MDM enrollment.
$ds = (dsregcmd /status) 2>$null
$aadJoined = ($ds | Where-Object { $_ -match '^\s*AzureAdJoined\s*:\s*YES' }).Count -gt 0
$mdm       = ($ds | Where-Object { $_ -match '^\s*MDMUrl\s*:\s*\S' }).Count -gt 0
Result $aadJoined "Entra joined"
Result $mdm       "MDM (Intune) enrolled"

# Local: hardware identity present.
$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
$localSerial = $bios.SerialNumber
Result ([string]::IsNullOrWhiteSpace($localSerial) -eq $false) ("Local hardware serial: {0}" -f $localSerial)
if (-not $SerialNumber -and $localSerial) { $SerialNumber = $localSerial }

# Cloud checks (optional).
if ($SerialNumber) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All', 'DeviceManagementServiceConfig.Read.All' -NoWelcome

    # Intune managed device present + reporting hardware?
    try {
        $esc = [uri]::EscapeDataString("serialNumber eq '$SerialNumber'")
        $md = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=$esc").value | Select-Object -First 1
        Result ($null -ne $md) ("Intune managed device present (serial $SerialNumber)")
        if ($md) { Write-Host ("        model={0}  os={1}  lastSync={2}" -f $md.model, $md.operatingSystem, $md.lastSyncDateTime) -ForegroundColor DarkGray }
    } catch {
        Result $false "Could not query Intune managed devices: $($_.Exception.Message)"
    }

    # Autopilot registration present?
    try {
        $ap = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities').value |
              Where-Object { $_.serialNumber -eq $SerialNumber } | Select-Object -First 1
        Result ($null -ne $ap) ("Registered to Windows Autopilot (serial $SerialNumber)")
    } catch {
        Result $false "Could not query Autopilot device identities: $($_.Exception.Message)"
    }

    Disconnect-MgGraph | Out-Null
} else {
    Write-Host "  (No serial available; skipped Intune + Autopilot cloud checks.)" -ForegroundColor DarkGray
}

Write-Host "`nValidation complete." -ForegroundColor Green
