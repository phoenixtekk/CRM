<#
.SYNOPSIS
    MACBASE-Discovery.ps1 — tenant/device readiness for a macOS management baseline (management plane, Graph).
.DESCRIPTION
    PURPOSE
        Reports whether the tenant and its Macs are ready to receive the macOS baseline: that an
        Apple MDM Push (APNs) certificate exists and is not near expiry, how many managed Macs are
        enrolled, the macOS version spread across the fleet, and which existing macOS configuration,
        compliance, and update policies already exist (so you avoid creating a conflicting second
        authority). Read-only against Microsoft Graph (Intune).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACBASE-Discovery.ps1
        Requires the Microsoft Graph SDK and these read scopes (consented on first sign-in):
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        APNs certificate presence/expiry, count of enrolled Macs, a macOS-version breakdown, and a
        list of existing macOS configuration/compliance policies to review for conflicts before you
        build. Pass = APNs present and not expired, Macs enrolled, no surprise conflicting policies.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "`n=== macOS Baseline — tenant/device readiness ===" -ForegroundColor Cyan

# Apple MDM Push (APNs) certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/applePushNotificationCertificate"
    if ($apns -and $apns.expirationDateTime) {
        $days = [int]([datetime]$apns.expirationDateTime - (Get-Date)).TotalDays
        $col  = if ($days -lt 30) { 'Yellow' } else { 'Green' }
        Write-Host ("APNs cert      : present (AppleID {0}, expires {1}, {2} days)" -f $apns.appleIdentifier, $apns.expirationDateTime, $days) -ForegroundColor $col
        if ($days -lt 30) { Write-Host "  WARNING: APNs certificate expires soon — renew before it lapses or all Mac management stops." -ForegroundColor Yellow }
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

# Existing macOS settings-catalog configuration policies (review for conflicts)
$cps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=platforms has 'macOS'").value
Write-Host ("`nExisting macOS settings-catalog policies (review for conflicts): {0}" -f ($cps | Measure-Object).Count) -ForegroundColor Cyan
$cps | ForEach-Object { Write-Host ("  - {0}" -f $_.name) }

# Existing macOS compliance policies
try {
    $comp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceCompliancePolicies").value | Where-Object { $_.'@odata.type' -match 'macOS' }
    Write-Host ("`nExisting macOS compliance policies: {0}" -f ($comp | Measure-Object).Count) -ForegroundColor Cyan
    $comp | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }
} catch { Write-Host "  (Could not enumerate compliance policies.)" -ForegroundColor Yellow }

Write-Host "`nReadiness scan complete. Address any APNs/enrollment/conflict findings before you build the baseline." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
