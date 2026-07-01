<#
.SYNOPSIS
    DUALDEV-Validation.ps1 — prove one identity owns both a Corporate and a Personal device.

.DESCRIPTION
    PURPOSE
        For a given user (UPN), lists their Intune devices and validates the acceptance gate: the
        same account owns at least one Corporate device (compliant) and at least one Personal device,
        and an App Protection policy targets the user. Produces a clear PASS/FAIL verdict.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\DUALDEV-Validation.ps1 -User jane@contoso.com

    EXPECTED RESULTS
        A device table for the user plus per-check PASS/FAIL. A fully validated user shows one
        Corporate (compliant) device and one Personal device under a single UPN.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$User
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

# Devices owned by the user
$resp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=userPrincipalName eq '$User'"
$devices = @($resp.value)

if ($devices.Count -gt 0) {
    $devices | Select-Object deviceName, operatingSystem, managedDeviceOwnerType, complianceState, lastSyncDateTime | Format-Table -AutoSize
}

$corp = @($devices | Where-Object managedDeviceOwnerType -eq 'company')
$pers = @($devices | Where-Object managedDeviceOwnerType -eq 'personal')

$results = New-Object System.Collections.Generic.List[object]
$results.Add( (R 'Single identity resolves'        ($devices.Count -gt 0) "$($devices.Count) device(s) for $User") )
$results.Add( (R 'Owns a Corporate (COD) device'   ($corp.Count -gt 0) "$($corp.Count) corporate device(s)") )
$results.Add( (R 'Corporate device is Compliant'   (@($corp | Where-Object complianceState -eq 'compliant').Count -gt 0) "compliant corporate device present") )
$results.Add( (R 'Owns a Personal (BYOD) device'   ($pers.Count -gt 0) "$($pers.Count) personal device(s)") )

# App Protection targeting the user (MAM check-in records)
$mamApplied = $false; $detail = 'no MAM registration found'
try {
    $body = @{ user = @{ id = $User } } | ConvertTo-Json
    $st = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/managedAppStatuses(''userstatus'')' -ErrorAction SilentlyContinue
} catch {}
try {
    $reg = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/users/$User/managedAppRegistrations").value
    if (@($reg).Count -gt 0) { $mamApplied = $true; $detail = "$(@($reg).Count) managed-app registration(s)" }
} catch { $detail = $_.Exception.Message }
$results.Add( (R 'App Protection applies to user (BYOD)' $mamApplied $detail) )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host "OVERALL: PASS — $User uses one account across a Corporate and a Personal device." -ForegroundColor Green }
else { Write-Host "OVERALL: FAIL — $fail check(s) failed. See the Troubleshooting guide." -ForegroundColor Yellow }
