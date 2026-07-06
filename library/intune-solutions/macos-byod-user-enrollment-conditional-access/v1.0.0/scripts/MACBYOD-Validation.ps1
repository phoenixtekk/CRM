<#
.SYNOPSIS
    MACBYOD-Validation.ps1 — validate one BYOD Mac against the solution's acceptance gate.
.DESCRIPTION
    PURPOSE
        For a single macOS device (by serial number or device name), confirms it is: enrolled in Intune
        via account-driven USER enrollment, personally owned (not corporate/supervised), reporting a
        compliance state, and registered with Microsoft Entra ID. Produces a clear PASS/FAIL verdict.
        Reads only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACBYOD-Validation.ps1 -Serial C02XXXXXXXXX
        powershell -ExecutionPolicy Bypass -File .\MACBYOD-Validation.ps1 -DeviceName "Jane-MacBook"
        Requires the Microsoft Graph PowerShell SDK. Graph scopes (read-only):
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A per-check PASS/FAIL table and an overall verdict. A correctly onboarded BYOD Mac passes every
        check; a whole-device-managed or supervised Mac indicates the wrong enrollment model was used.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$Serial,
    [string]$DeviceName
)

if (-not $Serial -and -not $DeviceName) { throw 'Provide -Serial or -DeviceName.' }
$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

# Locate the device
$filter = if ($Serial) { "serialNumber eq '$Serial'" } else { "deviceName eq '$DeviceName'" }
$resp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=$filter"
$dev = @($resp.value | Where-Object { $_.operatingSystem -match 'macOS|OS X' })[0]
if (-not $dev) { throw "No macOS managed device found for $filter." }

$results = New-Object System.Collections.Generic.List[object]
$results.Add( (R 'Enrolled in Intune' $true "$($dev.deviceName) ($($dev.serialNumber))") )

# Account-driven USER enrollment: user-affinity, personally owned, NOT supervised.
$userEnroll = ($dev.deviceEnrollmentType -match 'userEnrollment|appleUserEnrollment') -or
              ($dev.managedDeviceOwnerType -eq 'personal' -and -not [bool]$dev.isSupervised)
$results.Add( (R 'Account-driven USER enrollment' $userEnroll "EnrollmentType=$($dev.deviceEnrollmentType)") )
$results.Add( (R 'Personally owned (BYOD)'      ($dev.managedDeviceOwnerType -eq 'personal') "Ownership=$($dev.managedDeviceOwnerType)") )
$results.Add( (R 'Not supervised (light footprint)' (-not [bool]$dev.isSupervised) "isSupervised=$($dev.isSupervised)") )
$results.Add( (R 'Compliance state present'      ($dev.complianceState -and $dev.complianceState -ne 'unknown') "ComplianceState=$($dev.complianceState)") )
$results.Add( (R 'Compliant'                     ($dev.complianceState -eq 'compliant') "ComplianceState=$($dev.complianceState)") )

# Entra device registration present?
$registered = [bool]$dev.azureADRegistered -or $dev.azureADDeviceId
$results.Add( (R 'Registered with Entra ID' ([bool]$registered) "azureADDeviceId=$($dev.azureADDeviceId)") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — BYOD Mac meets the acceptance gate.' -ForegroundColor Green }
else { Write-Host "OVERALL: FAIL — $fail check(s) failed. See the Troubleshooting guide." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
