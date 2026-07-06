<#
.SYNOPSIS
    MACFV-Validation.ps1 — per-device FileVault encryption + key-escrow check (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Checks one Mac in Intune for two things: that it reports as encrypted, and that a personal
        FileVault recovery key is actually escrowed to Intune for it. Reads the managed-device
        record (isEncrypted) and attempts to read the escrowed FileVault key via Graph. Reports
        PASS/FAIL for encryption and for escrow. Read-only — it changes nothing on the Mac.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACFV-Validation.ps1 -DeviceName "MAC-001"
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All +
        DeviceManagementManagedDevices.PrivilegedOperations.All (to read the escrowed FileVault key).
    EXPECTED RESULTS
        A PASS/FAIL line for encryption and for recovery-key escrow, and "DEVICE ENCRYPTED + ESCROWED"
        when both pass. Exit 0 = pass, 1 = encrypted but not escrowed, 2 = not found / not encrypted.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$DeviceName
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

Write-Host ("=== FileVault Validation — {0} ===" -f $DeviceName) -ForegroundColor Cyan

$dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $DeviceName)).value | Select-Object -First 1
if (-not $dev) { Write-Host "  Mac not found in Intune (check -DeviceName)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }

# 1) Encryption signal
$encrypted = [bool]$dev.isEncrypted
Write-Host ("  [{0}] Encryption — isEncrypted={1}" -f ($(if($encrypted){'PASS'}else{'FAIL'})), $dev.isEncrypted) -ForegroundColor ($(if($encrypted){'Green'}else{'Yellow'}))

# 2) Personal recovery key escrowed to Intune (getFileVaultKey returns the key when escrowed)
$escrowed = $false
try {
    $key = Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/managedDevices/{0}/getFileVaultKey" -f $dev.id)
    if ($key -and $key.value) { $escrowed = $true }
} catch { $escrowed = $false }
Write-Host ("  [{0}] Recovery key escrowed to Intune" -f ($(if($escrowed){'PASS'}else{'FAIL'}))) -ForegroundColor ($(if($escrowed){'Green'}else{'Yellow'}))
if (-not $escrowed) { Write-Host "    (No escrowed FileVault key returned. Confirm the policy hides the key from the user, then run MACFV-Remediation.ps1.)" -ForegroundColor DarkGray }

if ($encrypted -and $escrowed) { Write-Host "`nResult: DEVICE ENCRYPTED + ESCROWED" -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
elseif ($encrypted -and -not $escrowed) { Write-Host "`nResult: ENCRYPTED but NO ESCROWED KEY — recovery risk. Run MACFV-Remediation.ps1." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
else { Write-Host "`nResult: NOT ENCRYPTED — confirm SecureToken and that the FileVault policy is assigned/applied." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }
