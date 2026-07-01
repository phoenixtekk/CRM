<#
.SYNOPSIS
    PFXMOB-Validation.ps1 — per-device check that the trusted chain + identity are present and the
    delivery profile applied. READ-ONLY.
.DESCRIPTION
    PURPOSE
        For a target iOS device, confirms (via Microsoft Graph) that:
          1. The device exists and is enrolled/managed.
          2. The trusted certificate profile (Trusted Root - Org CA - iOS) reports Succeeded.
          3. The delivery profile (PFX Imported - iOS App Cert - Pilot, OR
             Custom PKCS12 - iOS App Cert - Pilot) reports Succeeded for the device.
        This validates the Intune DELIVERY only. Whether the target app can READ the identity from the
        keychain is governed by the app vendor (keychain access group / App Configuration) and is
        confirmed by opening the app — see the Troubleshooting Guide, section E.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PFXMOB-Validation.ps1 -DeviceName 'iPad-Pilot-01'
        (Or pass -DeviceId for an exact Intune managed-device id.)
    EXPECTED RESULTS
        Per-profile deployment status for the device; a clear PASS when both the chain profile and the
        delivery profile show Succeeded.
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only. Documented Graph endpoints
    (deviceManagement/managedDevices and per-device configuration state).
#>
[CmdletBinding(DefaultParameterSetName='ByName')] param(
    [Parameter(ParameterSetName='ByName', Mandatory)] [string] $DeviceName,
    [Parameter(ParameterSetName='ById',   Mandatory)] [string] $DeviceId,
    [string] $ChainProfileName    = 'Trusted Root - Org CA - iOS',
    [string[]] $DeliveryProfileNames = @('PFX Imported - iOS App Cert - Pilot','Custom PKCS12 - iOS App Cert - Pilot')
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

# 1. Resolve the managed device.
if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    $enc = [uri]::EscapeDataString($DeviceName)
    $dev = (Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$enc'").value | Select-Object -First 1
} else {
    $dev = Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceId"
}
if (-not $dev) { Write-Host "Device not found / not enrolled. Confirm enrollment first." -ForegroundColor Red; return }

Write-Host ("`n=== Validation — {0} ({1}) ===" -f $dev.deviceName, $dev.operatingSystem) -ForegroundColor Cyan
$id = $dev.id

# 2 & 3. Per-device configuration profile states.
$states = (Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id/deviceConfigurationStates").value

function Show-ProfileState($name) {
    $s = $states | Where-Object { $_.displayName -eq $name } | Select-Object -First 1
    if (-not $s) { Write-Host ("  [{0}] not assigned to this device" -f $name) -ForegroundColor Yellow; return $false }
    $ok = ($s.state -eq 'compliant' -or $s.state -eq 'succeeded')
    Write-Host ("  [{0}] {1}" -f $name, $s.state) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    return $ok
}

Write-Host "`nTrusted chain:" -ForegroundColor Cyan
$chainOk = Show-ProfileState $ChainProfileName

Write-Host "`nDelivery profile (identity):" -ForegroundColor Cyan
$deliveryOk = $false
foreach ($n in $DeliveryProfileNames) { if (Show-ProfileState $n) { $deliveryOk = $true } }

Write-Host ""
if ($chainOk -and $deliveryOk) {
    Write-Host "PASS — chain + identity delivered. Now open the target app to confirm it can USE the certificate." -ForegroundColor Green
} else {
    Write-Host "INCOMPLETE — see Troubleshooting (missing assignment, connector health, or chain)." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
