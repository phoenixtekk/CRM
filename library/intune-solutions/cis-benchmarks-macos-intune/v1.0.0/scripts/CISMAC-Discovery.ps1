<#
.SYNOPSIS
    CISMAC-Discovery.ps1 — tenant/device CIS-Benchmark readiness for macOS (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Reports whether the tenant and its Macs are ready to receive a CIS macOS baseline: that an
        Apple MDM Push (APNs) certificate exists and is not near expiry, how many managed Macs are
        enrolled, the macOS version spread across the fleet, and whether any existing macOS
        configuration policies already target the same area (potential conflicts). Read-only against
        Microsoft Graph (Intune).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISMAC-Discovery.ps1
        Requires the Microsoft Graph SDK and these read scopes (consented on first sign-in):
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        APNs certificate presence/expiry, count of enrolled Macs, a macOS-version breakdown, and a
        list of existing macOS configuration policies to review for conflicts before you build.
.NOTES
    Intune Solutions — CIS macOS. Read-only against Graph. CIS control values are deferred to the benchmark.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== CIS macOS — tenant/device readiness ===" -ForegroundColor Cyan

# Apple MDM Push (APNs) certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/applePushNotificationCertificate"
    if ($apns -and $apns.expirationDateTime) {
        $days = [int]([datetime]$apns.expirationDateTime - (Get-Date)).TotalDays
        $col  = if ($days -lt 30) { 'Yellow' } else { 'Green' }
        Write-Host ("APNs cert      : present (AppleID {0}, expires {1}, {2} days)" -f $apns.appleIdentifier, $apns.expirationDateTime, $days) -ForegroundColor $col
        if ($days -lt 30) { Write-Host "  WARNING: APNs certificate expires soon — renew before it lapses or management stops." -ForegroundColor Yellow }
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
}

# Existing macOS configuration policies (review for conflicts)
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=platforms has 'macOS'").value
Write-Host ("`nExisting macOS settings-catalog policies (review for conflicts): {0}" -f ($cps | Measure-Object).Count) -ForegroundColor Cyan
$cps | ForEach-Object { Write-Host ("  - {0}" -f $_.name) }

Write-Host "`nReadiness scan complete." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
