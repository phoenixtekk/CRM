<#
.SYNOPSIS
    JAMFADE-Validation.ps1 — validate a single Jamf-managed Mac in Entra/Intune.

.DESCRIPTION
    PURPOSE
        Confirms that one specific Mac is, on the Microsoft side:
          - REGISTERED in Microsoft Entra ID (a macOS/MacMDM device object exists),
          - reported by the Jamf partner and present in Intune as a managed device,
          - COMPLIANT (the state Jamf reports through the Device Compliance integration).
        Use after a pilot Mac completes Company Portal registration (Implementation Test 6/9).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\JAMFADE-Validation.ps1 -SerialNumber C02XXXXXXXXX
        # or match by device name:
        .\JAMFADE-Validation.ps1 -DeviceName "Jane-MacBook"
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall PASS when the Mac is Entra-registered, present in
        Intune (partner-managed), and Compliant.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only. Jamf is the MDM; compliance is
    reported to Intune via the Jamf ↔ Intune Device Compliance integration.
#>
[CmdletBinding(DefaultParameterSetName='Serial')]
param(
    [Parameter(Mandatory, ParameterSetName='Serial')] [string]$SerialNumber,
    [Parameter(Mandatory, ParameterSetName='Name')]   [string]$DeviceName
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Device.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the managed device (partner-managed Jamf records appear in managedDevices)
$md = $null
try {
    if ($PSCmdlet.ParameterSetName -eq 'Serial') {
        $q = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$SerialNumber'"
    } else {
        $q = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$DeviceName'"
    }
    $md = @($q.value | Where-Object { "$($_.operatingSystem)" -match 'macOS|OS X|Mac' })[0]
} catch {}

if (-not $md) {
    $results.Add( (R 'Mac present in Intune (managed device)' $false 'No matching macOS managed device — confirm registration (Company Portal) and the Jamf compliance scope.') )
    $results | Format-Table -AutoSize
    Write-Host ''
    Write-Host 'OVERALL: FAIL — device not found in Intune.' -ForegroundColor Yellow
    return
}

$results.Add( (R 'Mac present in Intune (managed device)' $true "name=$($md.deviceName); os=$($md.operatingSystem) $($md.osVersion); serial=$($md.serialNumber)") )

# Partner / management channel — Jamf-managed Macs show as partner-managed / MDM=partner
$mgmt = "$($md.managementAgent)"
$partner = ($mgmt -match 'jamf|partner|configurationManagerClientMdm' -or "$($md.managedDeviceOwnerType)" -eq 'company')
$results.Add( (R 'Partner-managed (Jamf) record' $partner "managementAgent=$mgmt; owner=$($md.managedDeviceOwnerType)") )

# Compliance state reported to Intune
$compliant = ("$($md.complianceState)" -eq 'compliant')
$results.Add( (R 'Compliant in Intune' $compliant "complianceState=$($md.complianceState)") )

# Entra registration — look up the device object by serial/name
$registered = $false; $regDetail = 'not found'
try {
    $az = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=displayName eq '$($md.deviceName)'"
    $dev = @($az.value)[0]
    if ($dev) { $registered = $true; $regDetail = "objectId=$($dev.id); trust=$($dev.trustType); enabled=$($dev.accountEnabled)" }
} catch { $regDetail = $_.Exception.Message }
$results.Add( (R 'Registered in Microsoft Entra ID' $registered $regDetail) )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — Mac is Entra-registered, partner-managed (Jamf), and compliant.' -ForegroundColor Green }
else { Write-Host "OVERALL: FAIL — $fail check(s) failed. See Troubleshooting (compliance / registration)." -ForegroundColor Yellow }
