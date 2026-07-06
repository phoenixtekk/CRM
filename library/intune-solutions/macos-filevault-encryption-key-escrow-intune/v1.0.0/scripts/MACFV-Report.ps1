<#
.SYNOPSIS
    MACFV-Report.ps1 — fleet FileVault encryption + escrow coverage, and personal recovery-key retrieval (Graph).
.DESCRIPTION
    PURPOSE
        Two modes, both read-only against Microsoft Graph (Intune):
        1. Fleet report (default): summarizes managed Macs by encryption state and flags any Mac
           reported as encrypted but with NO escrowed personal recovery key — the recovery risk.
        2. Key retrieval: with -DeviceName, retrieves that Mac's escrowed personal FileVault recovery
           key for an authorized admin (the help-desk recovery workflow).
    HOW TO RUN
        Fleet:  powershell -ExecutionPolicy Bypass -File .\MACFV-Report.ps1 -CsvPath C:\Temp\filevault.csv
        Key:    powershell -ExecutionPolicy Bypass -File .\MACFV-Report.ps1 -DeviceName "MAC-001"
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All +
        DeviceManagementManagedDevices.PrivilegedOperations.All (to read escrowed FileVault keys).
    EXPECTED RESULTS
        Fleet mode: an encrypted/not-encrypted breakdown, a count of encrypted-without-escrow Macs,
        and an optional per-device CSV. Key mode: the personal recovery key for that Mac.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Treat retrieved keys as secrets.
#>
[CmdletBinding()] param(
    [string]$DeviceName,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All' -NoWelcome

function Get-FvKey([string]$id) {
    try { $k = Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/managedDevices/{0}/getFileVaultKey" -f $id); return $k.value } catch { return $null }
}

# --- Key-retrieval mode ---
if ($DeviceName) {
    $dev = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}' and operatingSystem eq 'macOS'" -f $DeviceName)).value | Select-Object -First 1
    if (-not $dev) { Write-Host "Mac not found in Intune (check -DeviceName)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 2 }
    $key = Get-FvKey $dev.id
    if ($key) { Write-Host ("Personal recovery key for {0}:" -f $DeviceName) -ForegroundColor Cyan; Write-Host ("  {0}" -f $key) -ForegroundColor Green; Write-Host "  (Treat as a secret. Intune rotates the key after use if rotation is enabled.)" -ForegroundColor DarkGray }
    else { Write-Host "No escrowed FileVault key found for this Mac (not escrowed yet, or insufficient permission)." -ForegroundColor Yellow }
    Disconnect-MgGraph | Out-Null
    exit ($(if($key){0}else{1}))
}

# --- Fleet report mode ---
$macs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=id,deviceName,osVersion,isEncrypted").value
$report = foreach ($m in $macs) {
    $hasKey = [bool](Get-FvKey $m.id)
    [pscustomobject]@{ Device=$m.deviceName; OSVersion=$m.osVersion; Encrypted=[bool]$m.isEncrypted; HasRecoveryKey=$hasKey }
}

Write-Host "=== FileVault fleet posture ===" -ForegroundColor Cyan
$report | Group-Object Encrypted | Select-Object @{n='Encrypted';e={$_.Name}}, Count | Format-Table -AutoSize
$noKey = ($report | Where-Object { $_.Encrypted -and -not $_.HasRecoveryKey }).Count
Write-Host ("Encrypted: {0}/{1} | Encrypted WITHOUT escrowed key: {2}" -f ($report | Where-Object Encrypted).Count, ($report | Measure-Object).Count, $noKey) -ForegroundColor ($(if($noKey){'Yellow'}else{'Green'}))
if ($noKey) { Write-Host "  Run MACFV-Remediation.ps1 for the un-escrowed Macs (recovery risk)." -ForegroundColor Yellow }
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null
