<#
.SYNOPSIS
    ADEMAC-Validation.ps1 — validate a single enrolled Mac against the solution's acceptance gate.

.DESCRIPTION
    PURPOSE
        For one macOS device (by serial number or device name), confirms it is: enrolled in
        Intune, ADE/DEP-enrolled, supervised, corporate-owned, compliant, and that a Platform
        SSO configuration profile is applied. Produces a clear PASS/FAIL verdict.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ADEMAC-Validation.ps1 -Serial C02XXXXXXXXX
        .\ADEMAC-Validation.ps1 -DeviceName "Jane-MacBook"

    EXPECTED RESULTS
        A per-check PASS/FAIL table and an overall verdict. A fully validated Mac passes every
        check; investigate any FAIL using the Troubleshooting guide.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$Serial,
    [string]$DeviceName
)

if (-not $Serial -and -not $DeviceName) { throw 'Provide -Serial or -DeviceName.' }
$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' | Out-Null

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
$results.Add( (R 'OS is macOS 13+'    ([version]($dev.osVersion -replace '[^0-9.].*$') -ge [version]'13.0') "macOS $($dev.osVersion)") )
$results.Add( (R 'ADE / DEP enrolled' ($dev.deviceEnrollmentType -match 'depDeviceEnrollment|appleBulkWithUser|appleBulkWithoutUser') "EnrollmentType=$($dev.deviceEnrollmentType)") )
$results.Add( (R 'Supervised'         ([bool]$dev.isSupervised) "isSupervised=$($dev.isSupervised)") )
$results.Add( (R 'Corporate-owned'    ($dev.managedDeviceOwnerType -eq 'company') "Ownership=$($dev.managedDeviceOwnerType)") )
$results.Add( (R 'Compliant'          ($dev.complianceState -eq 'compliant') "ComplianceState=$($dev.complianceState)") )

# Platform SSO profile applied to this device?
$ssoApplied = $false; $detail = 'no SSO config state found'
try {
    $states = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($dev.id)/deviceConfigurationStates"
    $hit = @($states.value | Where-Object { $_.displayName -match 'SSO|Single Sign' -and $_.state -in @('compliant','configured','succeeded') })
    if ($hit.Count -gt 0) { $ssoApplied = $true; $detail = ($hit[0].displayName + ' = ' + $hit[0].state) }
} catch { $detail = $_.Exception.Message }
$results.Add( (R 'Platform SSO profile applied' $ssoApplied $detail) )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — device meets the acceptance gate.' -ForegroundColor Green }
else { Write-Host "OVERALL: FAIL — $fail check(s) failed. See the Troubleshooting guide." -ForegroundColor Yellow }
