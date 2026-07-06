<#
.SYNOPSIS
    MACMDE-Discovery.ps1 — MDE-for-macOS deployment readiness (tenant/device, management plane, Graph).
.DESCRIPTION
    PURPOSE
        Reports whether the tenant and its Macs are ready to deploy and onboard Microsoft Defender
        for Endpoint on macOS: that an Apple MDM Push (APNs) certificate exists and is not near
        expiry, how many managed Macs are enrolled, the macOS version spread, and whether any
        existing macOS configuration profiles already deliver Defender/security payloads (potential
        conflicts). Read-only against Microsoft Graph (Intune).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACMDE-Discovery.ps1
        Requires the Microsoft Graph SDK and these read scopes (consented on first sign-in):
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All, DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        APNs certificate presence/expiry, count of enrolled Macs, a macOS-version breakdown, and a
        list of existing macOS configuration profiles / Defender apps to review before you build.
        PASS when APNs is present and Macs are enrolled on a supported macOS version.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All' -NoWelcome

Write-Host "`n=== MDE for macOS — deployment/onboarding readiness ===" -ForegroundColor Cyan

# Apple MDM Push (APNs) certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/applePushNotificationCertificate"
    if ($apns -and $apns.expirationDateTime) {
        $days = [int]([datetime]$apns.expirationDateTime - (Get-Date)).TotalDays
        $col  = if ($days -lt 30) { 'Yellow' } else { 'Green' }
        Write-Host ("APNs cert      : present (AppleID {0}, expires {1}, {2} days)" -f $apns.appleIdentifier, $apns.expirationDateTime, $days) -ForegroundColor $col
        if ($days -lt 30) { Write-Host "  WARNING: APNs certificate expires soon — renew before it lapses or macOS management (and MDE profiles) stop." -ForegroundColor Yellow }
    } else { Write-Host "APNs cert      : NOT configured — macOS management will not work until this is set." -ForegroundColor Yellow }
} catch { Write-Host "APNs cert      : NOT configured (no Apple MDM Push certificate found)." -ForegroundColor Yellow }

# Enrolled Macs + macOS version spread
$macs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,osVersion,complianceState").value
Write-Host ("Enrolled Macs  : {0}" -f ($macs | Measure-Object).Count) -ForegroundColor ($(if($macs){'Green'}else{'Yellow'}))
if ($macs) {
    Write-Host "macOS versions :" -ForegroundColor Cyan
    $macs | Group-Object osVersion | Sort-Object Name | Select-Object Count, @{n='osVersion';e={$_.Name}} | Format-Table -AutoSize
    $noncompliant = $macs | Where-Object { $_.complianceState -ne 'compliant' }
    Write-Host ("Non-compliant  : {0} of {1}" -f ($noncompliant | Measure-Object).Count, ($macs | Measure-Object).Count)
} else {
    Write-Host "  No enrolled Macs found — configure macOS enrollment (Requirement 2.3) before deploying MDE." -ForegroundColor Yellow
}

# Existing macOS configuration profiles (Settings catalog) — review for Defender/security conflicts
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=platforms has 'macOS'").value
Write-Host ("`nExisting macOS settings-catalog policies (review for conflicts): {0}" -f ($cps | Measure-Object).Count) -ForegroundColor Cyan
$cps | ForEach-Object { Write-Host ("  - {0}" -f $_.name) }

# Existing macOS template/custom profiles (deviceConfigurations) — extensions/PPPC/onboarding
$dcs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations").value | Where-Object { $_.'@odata.type' -match 'macOS' -or $_.displayName -match 'macOS|Defender|MDE' }
Write-Host ("`nExisting macOS template/custom profiles (review for conflicts): {0}" -f ($dcs | Measure-Object).Count) -ForegroundColor Cyan
$dcs | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }

# Existing Microsoft Defender / macOS app deployments
$apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.macOSMicrosoftDefenderApp')").value
Write-Host ("`nExisting Microsoft Defender (macOS) app deployments: {0}" -f ($apps | Measure-Object).Count) -ForegroundColor Cyan
$apps | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }

Write-Host "`nReadiness scan complete. Build the five capability profiles BEFORE the onboarding profile (03-implementation)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
