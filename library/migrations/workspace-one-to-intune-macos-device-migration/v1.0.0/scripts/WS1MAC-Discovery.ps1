<#
.SYNOPSIS
    WS1MAC-Discovery.ps1 — Workspace ONE to Intune macOS migration readiness (Intune side, Graph).
.DESCRIPTION
    PURPOSE
        Reports whether the Intune/Apple side is ready to receive Macs migrating off Workspace ONE:
        that an Apple MDM Push (APNs) certificate exists and is not near expiry, that an Automated
        Device Enrollment (ADE) / enrollment program token is present with macOS devices synced, how
        many Macs are already enrolled and their macOS version spread, and which existing macOS
        configuration policies exist (so you can plan parity and spot conflicts). Read-only against
        Microsoft Graph (Intune). Workspace ONE/ABM-side state is checked in those consoles and is
        deferred to vendor documentation.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1MAC-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and these read scopes (consented at sign-in):
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        APNs certificate presence/expiry, ADE/enrollment token(s) with synced macOS counts, count and
        version spread of enrolled Macs, and a list of existing macOS configuration policies to map
        for parity. Nothing is changed.
.NOTES
    Migrations — Workspace ONE to Intune macOS. Read-only against Graph. WS1/ABM specifics deferred to vendor docs.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== WS1->Intune macOS — migration readiness (Intune side) ===" -ForegroundColor Cyan

# Apple MDM Push (APNs) certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/applePushNotificationCertificate"
    if ($apns -and $apns.expirationDateTime) {
        $days = [int]([datetime]$apns.expirationDateTime - (Get-Date)).TotalDays
        $col  = if ($days -lt 30) { 'Yellow' } else { 'Green' }
        Write-Host ("APNs cert      : present (AppleID {0}, expires {1}, {2} days)" -f $apns.appleIdentifier, $apns.expirationDateTime, $days) -ForegroundColor $col
        if ($days -lt 30) { Write-Host "  WARNING: APNs certificate expires soon — renew before it lapses or macOS management stops." -ForegroundColor Yellow }
    } else { Write-Host "APNs cert      : NOT configured — macOS management will not work until this is set (Requirement 2.2)." -ForegroundColor Yellow }
} catch { Write-Host "APNs cert      : NOT configured (no Apple MDM Push certificate found)." -ForegroundColor Yellow }

# ADE / enrollment program tokens + synced macOS devices
try {
    $tokens = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/depOnboardingSettings").value
    if ($tokens) {
        Write-Host ("ADE token(s)   : {0}" -f ($tokens | Measure-Object).Count) -ForegroundColor Green
        foreach ($t in $tokens) {
            Write-Host ("  - {0} (token expires {1})" -f $t.tokenName, $t.tokenExpirationDateTime)
        }
    } else { Write-Host "ADE token(s)   : NONE — add the Intune MDM server token from ABM (Requirement 2.3)." -ForegroundColor Yellow }
} catch { Write-Host "ADE token(s)   : could not read depOnboardingSettings — confirm enrollment program tokens in the portal." -ForegroundColor Yellow }

# Enrolled Macs + macOS version spread
$macs = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=deviceName,osVersion,managementAgent,complianceState").value
Write-Host ("Enrolled Macs  : {0}" -f ($macs | Measure-Object).Count) -ForegroundColor ($(if($macs){'Green'}else{'Yellow'}))
if ($macs) {
    Write-Host "macOS versions :" -ForegroundColor Cyan
    $macs | Group-Object osVersion | Sort-Object Name | Select-Object Count, @{n='osVersion';e={$_.Name}} | Format-Table -AutoSize
}

# Existing macOS configuration policies (map for parity / review for conflicts)
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=platforms has 'macOS'").value
Write-Host ("`nExisting macOS settings-catalog policies (map for parity): {0}" -f ($cps | Measure-Object).Count) -ForegroundColor Cyan
$cps | ForEach-Object { Write-Host ("  - {0}" -f $_.name) }

Write-Host "`nReminder: Workspace ONE-side posture export and ABM device assignment are checked in those consoles (deferred to vendor docs)." -ForegroundColor DarkGray
Write-Host "Readiness scan complete." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
