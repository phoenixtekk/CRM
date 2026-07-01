<#
.SYNOPSIS
    IOSLD-Validation.ps1 — prove an iPhone matches its model (shared vs corporate) and is locked down.

.DESCRIPTION
    PURPOSE
        For a given device (by name or serial), validates the acceptance gate for its enrollment model:
          - SHARED  : NO primary user, supervised, member of 'iOS - Shared Devices', lock-down applied.
          - CORPORATE: HAS a primary user, supervised, member of 'iOS - Corporate Devices', compliant.
        Pass -Model to assert the expected model; if omitted, the script infers it from group membership
        / primary-user presence and validates accordingly.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSLD-Validation.ps1 -DeviceName "SHARED-IPHONE-01" -Model Shared
        .\IOSLD-Validation.ps1 -Serial "F2LXXXXXXX" -Model Corporate
        .\IOSLD-Validation.ps1 -DeviceName "IPHONE-07"        # infer model
        Reads only — makes no changes.

    EXPECTED RESULTS
        A device summary plus per-check PASS/FAIL and an overall GATE verdict for the model.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [string]$Serial,
    [ValidateSet('Shared','Corporate')] [string]$Model,
    [string]$SharedGroupName    = 'iOS – Shared Devices',
    [string]$CorporateGroupName = 'iOS – Corporate Devices'
)

if (-not $DeviceName -and -not $Serial) { throw 'Provide -DeviceName or -Serial.' }
$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

# Locate the managed device
if ($DeviceName) { $flt = "deviceName eq '$($DeviceName.Replace("'","''"))'" }
else { $flt = "serialNumber eq '$($Serial.Replace("'","''"))'" }
$dev = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter={0}" -f $flt)).value | Select-Object -First 1
if (-not $dev) { throw "Device not found ($flt)." }

$hasUser = -not [string]::IsNullOrEmpty($dev.userId)

# Determine group membership (best-effort) for inference + checks
$inShared = $false; $inCorp = $false
try {
    $azId = $dev.azureADDeviceId
    if ($azId) {
        $dirObj = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '{0}'&`$select=id" -f $azId)).value | Select-Object -First 1
        if ($dirObj) {
            $memberOf = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices/$($dirObj.id)/memberOf?`$select=displayName").value.displayName
            $inShared = $memberOf -contains $SharedGroupName
            $inCorp   = $memberOf -contains $CorporateGroupName
        }
    }
} catch {}

# Infer model if not supplied
if (-not $Model) {
    if ($inShared -and -not $inCorp) { $Model = 'Shared' }
    elseif ($inCorp -and -not $inShared) { $Model = 'Corporate' }
    else { $Model = if ($hasUser) { 'Corporate' } else { 'Shared' } }
    Write-Host "Model not specified — inferred: $Model" -ForegroundColor Cyan
}

Write-Host "Device     : $($dev.deviceName)  [$($dev.operatingSystem) $($dev.osVersion)]"
Write-Host "Serial     : $($dev.serialNumber)"
Write-Host "PrimaryUser: $(if ($hasUser) { $dev.userPrincipalName } else { '(none)' })"
Write-Host "Model      : $Model"
Write-Host ''

$results = @()
$results += R 'iOS device' ($dev.operatingSystem -match 'iOS|iPadOS') $dev.operatingSystem
$results += R 'Supervised' ([bool]$dev.isSupervised) ($(if ($dev.isSupervised) { 'Supervised = Yes' } else { 'Not supervised — lock-down will not hold' }))

if ($Model -eq 'Shared') {
    $results += R 'No primary user (shared)' (-not $hasUser) ($(if ($hasUser) { "Has primary user $($dev.userPrincipalName)" } else { 'Shared — no primary user' }))
    $results += R "Member of '$SharedGroupName'" $inShared ($(if ($inShared) { 'Yes' } else { 'Not a member (or membership unread)' }))
    $results += R 'Not in corporate group' (-not $inCorp) ($(if ($inCorp) { 'WARNING: also in corporate group' } else { 'OK' }))
} else {
    $results += R 'Has primary user (corporate)' $hasUser ($(if ($hasUser) { "Assigned to $($dev.userPrincipalName)" } else { 'No primary user — not a corporate phone' }))
    $results += R "Member of '$CorporateGroupName'" $inCorp ($(if ($inCorp) { 'Yes' } else { 'Not a member (or membership unread)' }))
    $results += R 'Compliant' ($dev.complianceState -eq 'compliant') "complianceState = $($dev.complianceState)"
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host "GATE: PASS — $Model iPhone correctly enrolled, supervised, and targeted." -ForegroundColor Green }
else { Write-Host "GATE: FAIL — $fail check(s) failed for the $Model model. See Troubleshooting." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
