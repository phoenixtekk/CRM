<#
.SYNOPSIS
    IMGLIFE-Remediation.ps1 - safe retire/wipe helper for end-of-life devices.
.DESCRIPTION
    PURPOSE
        Performs the secure end-of-life action on a managed device via Microsoft Graph: either Retire
        (remove company data and management, leave the OS) or Wipe (full factory reset - the secure
        wipe). It looks the device up by serial number, shows exactly what it WOULD do, and - because
        a wipe is irreversible - defaults to -WhatIf so it makes NO changes until you pass
        -WhatIf:$false. Optionally de-registers the device from Windows Autopilot afterwards so
        inventory stays clean.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\IMGLIFE-Remediation.ps1 `
            -SerialNumber "<device-serial>" -Action Wipe
        Apply the action:
          ... -SerialNumber "<device-serial>" -Action Wipe -WhatIf:$false
        Also de-register from Autopilot after the action:
          ... -SerialNumber "<serial>" -Action Wipe -RemoveAutopilot -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK and consent for
        DeviceManagementManagedDevices.PrivilegedOperations.All and
        DeviceManagementManagedDevices.ReadWrite.All (and DeviceManagementServiceConfig.ReadWrite.All
        for -RemoveAutopilot), all delegated. Sign in when prompted.
    EXPECTED RESULTS
        With -WhatIf (default): a plan of the retire/wipe (and optional Autopilot removal) that would
        occur, with the matched device's name/model for confirmation.
        With -WhatIf:$false: the chosen action is issued to the device and, if requested, the device
        is de-registered from Autopilot.
.NOTES
    Infrastructure solution - the repeatable way. Default -WhatIf; irreversible action only when disabled.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][string]$SerialNumber,
    [Parameter(Mandatory = $true)][ValidateSet('Retire', 'Wipe')][string]$Action,
    [switch]$RemoveAutopilot
)

# Default to -WhatIf unless the caller explicitly turned it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('DeviceManagementManagedDevices.PrivilegedOperations.All', 'DeviceManagementManagedDevices.ReadWrite.All')
if ($RemoveAutopilot) { $scopes += 'DeviceManagementServiceConfig.ReadWrite.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "`n=== End-of-life remediation ($Action) ===" -ForegroundColor Cyan

# Find the managed device by serial.
$esc = [uri]::EscapeDataString("serialNumber eq '$SerialNumber'")
$device = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=$esc").value | Select-Object -First 1
if (-not $device) {
    Write-Host "  No Intune managed device with serial '$SerialNumber'. Confirm the serial." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}
Write-Host ("  Matched: {0}  model={1}  id={2}" -f $device.deviceName, $device.model, $device.id) -ForegroundColor DarkGray

# Issue the retire or wipe action.
$verb = $Action.ToLower()   # 'retire' or 'wipe' are the Graph managedDevice action names
$target = "device '$($device.deviceName)' (serial $SerialNumber)"
if ($PSCmdlet.ShouldProcess($target, "$Action (secure end-of-life)")) {
    if ($Action -eq 'Wipe') {
        # keepEnrollmentData/keepUserData false => full secure wipe to factory state.
        $body = @{ keepEnrollmentData = $false; keepUserData = $false } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$($device.id)/wipe" -Body $body -ContentType 'application/json'
    } else {
        Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$($device.id)/retire"
    }
    Write-Host "  $Action issued to $target." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would $Action $target." -ForegroundColor DarkGray
}

# Optionally de-register from Autopilot so inventory stays clean.
if ($RemoveAutopilot) {
    $ap = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/deviceManagement/windowsAutopilotDeviceIdentities').value |
          Where-Object { $_.serialNumber -eq $SerialNumber } | Select-Object -First 1
    if ($ap) {
        if ($PSCmdlet.ShouldProcess("Autopilot identity for $SerialNumber", "Delete Autopilot registration")) {
            Invoke-MgGraphRequest -Method DELETE -Uri "/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/$($ap.id)"
            Write-Host "  Removed Autopilot registration for $SerialNumber." -ForegroundColor Green
        } else {
            Write-Host "  [WhatIf] Would remove Autopilot registration for $SerialNumber." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  No Autopilot registration found for $SerialNumber." -ForegroundColor DarkGray
    }
}

Disconnect-MgGraph | Out-Null
Write-Host "`nRe-run IMGLIFE-Report.ps1 after the action completes to confirm the device left inventory." -ForegroundColor Green
