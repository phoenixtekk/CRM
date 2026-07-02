<#
.SYNOPSIS
    BITLK-Get-RecoveryKey.ps1 — retrieve a device's BitLocker recovery key from Entra ID (Graph).
.DESCRIPTION
    PURPOSE
        For an authorized admin, returns the escrowed BitLocker recovery password(s) for a device,
        for help-desk recovery scenarios.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\BITLK-Get-RecoveryKey.ps1 -DeviceName LT-0042
        Requires Microsoft Graph SDK and BitlockerKey.Read.All (admin consent; privileged).
    EXPECTED RESULTS
        The recovery key ID(s) and recovery password(s) for the named device.
.NOTES
    White-label — Intune Solutions. Read-only but PRIVILEGED — log access per policy.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string]$DeviceName)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'BitlockerKey.Read.All','Device.Read.All' -NoWelcome
$dev = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/devices?`$filter=displayName eq '$DeviceName'").value | Select-Object -First 1
if (-not $dev) { Write-Host "Device '$DeviceName' not found in Entra." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; exit 1 }
$keys = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId eq '$($dev.deviceId)'").value
if (-not $keys) { Write-Host "No escrowed recovery keys for $DeviceName." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
foreach ($k in $keys) {
    $full = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/informationProtection/bitlocker/recoveryKeys/$($k.id)?`$select=key"
    Write-Host ("KeyId: {0}" -f $k.id) -ForegroundColor Cyan
    Write-Host ("  Recovery password: {0}" -f $full.key) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
