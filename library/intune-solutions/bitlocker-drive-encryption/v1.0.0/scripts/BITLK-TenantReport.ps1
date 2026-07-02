<#
.SYNOPSIS
    BITLK-TenantReport.ps1 — tenant-wide BitLocker encryption status report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes managed-device encryption state (encrypted / not encrypted) and flags devices
        that have no escrowed recovery key — the key recovery risk.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\BITLK-TenantReport.ps1 -CsvPath C:\Temp\bitlocker.csv
        Requires Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All +
        BitlockerKey.ReadBasic.All.
    EXPECTED RESULTS
        Encryption breakdown and a per-device CSV (device, OS, isEncrypted, hasRecoveryKey).
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','BitlockerKey.ReadBasic.All' -NoWelcome
$devs = @(); $uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,isEncrypted,azureADDeviceId'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
# recovery keys present (basic listing)
$keys = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/informationProtection/bitlocker/recoveryKeys').value
$keyDevs = $keys.deviceId | Sort-Object -Unique
$report = $devs | Where-Object operatingSystem -eq 'Windows' | ForEach-Object {
    [pscustomobject]@{ Device=$_.deviceName; Encrypted=$_.isEncrypted; HasRecoveryKey=($keyDevs -contains $_.azureADDeviceId) }
}
$report | Group-Object Encrypted | Select-Object Name, Count | Format-Table -AutoSize
$noKey = ($report | Where-Object { $_.Encrypted -and -not $_.HasRecoveryKey }).Count
Write-Host ("Encrypted: {0}/{1} | Encrypted WITHOUT escrowed key: {2}" -f ($report | Where-Object Encrypted).Count, $report.Count, $noKey) -ForegroundColor ($(if($noKey){'Yellow'}else{'Cyan'}))
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
