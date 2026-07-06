<#
.SYNOPSIS
    MACFV-Discovery.ps1 — tenant/device FileVault readiness for macOS (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Reports whether the tenant and its Macs are ready to receive a FileVault disk-encryption
        policy: that an Apple MDM Push (APNs) certificate exists and is not near expiry, how many
        managed Macs are enrolled, the macOS-version spread, how many Macs already report as
        encrypted, and whether any existing macOS disk-encryption/FileVault policies are present
        (potential conflicts). Read-only against Microsoft Graph (Intune).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACFV-Discovery.ps1
        Requires the Microsoft Graph SDK and these read scopes (consented on first sign-in):
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        APNs certificate presence/expiry, count of enrolled Macs, a macOS-version breakdown, an
        encrypted-vs-not count, and a list of existing macOS disk-encryption policies to review
        before you build. PASS/FAIL readiness signals for the FileVault rollout.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== FileVault (macOS) — tenant/device readiness ===" -ForegroundColor Cyan

# Apple MDM Push (APNs) certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/applePushNotificationCertificate"
    if ($apns -and $apns.expirationDateTime) {
        $days = [int]([datetime]$apns.expirationDateTime - (Get-Date)).TotalDays
        $col  = if ($days -lt 30) { 'Yellow' } else { 'Green' }
        Write-Host ("APNs cert      : PASS — present (AppleID {0}, expires {1}, {2} days)" -f $apns.appleIdentifier, $apns.expirationDateTime, $days) -ForegroundColor $col
        if ($days -lt 30) { Write-Host "  WARNING: APNs certificate expires soon — renew before it lapses or Mac management stops." -ForegroundColor Yellow }
    } else { Write-Host "APNs cert      : FAIL — NOT configured; macOS management will not work until this is set." -ForegroundColor Yellow }
} catch { Write-Host "APNs cert      : FAIL — NOT configured (no Apple MDM Push certificate found)." -ForegroundColor Yellow }

# Enrolled Macs + macOS version spread + encryption state
$macs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,osVersion,isEncrypted,complianceState").value
Write-Host ("Enrolled Macs  : {0}" -f ($macs | Measure-Object).Count) -ForegroundColor ($(if($macs){'Green'}else{'Yellow'}))
if ($macs) {
    Write-Host "macOS versions :" -ForegroundColor Cyan
    $macs | Group-Object osVersion | Sort-Object Name | Select-Object Count, @{n='osVersion';e={$_.Name}} | Format-Table -AutoSize
    $enc = ($macs | Where-Object { $_.isEncrypted }).Count
    Write-Host ("Encrypted Macs : {0} of {1} report isEncrypted=true" -f $enc, ($macs | Measure-Object).Count) -ForegroundColor ($(if($enc){'Green'}else{'Yellow'}))
    Write-Host "  (FileVault must still be validated per device — isEncrypted is the Intune signal, not proof of escrow.)" -ForegroundColor DarkGray
}

# Existing macOS disk-encryption / FileVault policies (review for conflicts)
$dep = @()
try { $dep = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/intents?`$filter=templateId ne null").value | Where-Object { $_.displayName -match 'FileVault|Disk encryption' } } catch {}
$cps = @()
try { $cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=platforms has 'macOS'").value | Where-Object { $_.name -match 'FileVault|Disk|Encrypt' } } catch {}
$existing = @($dep) + @($cps)
Write-Host ("`nExisting macOS disk-encryption/FileVault policies (review for conflicts): {0}" -f ($existing | Measure-Object).Count) -ForegroundColor Cyan
$existing | ForEach-Object { Write-Host ("  - {0}" -f ($_.displayName ?? $_.name)) }

Write-Host "`nReadiness scan complete. Confirm SecureToken/bootstrap token on the pilot Macs before enabling (see Requirements 2.5)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
