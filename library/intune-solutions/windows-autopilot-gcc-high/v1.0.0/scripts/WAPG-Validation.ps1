<#
.SYNOPSIS
    WAPG-Validation.ps1 — read-only pass/fail checks of the GCC High Autopilot build.
.DESCRIPTION
    PURPOSE
        Connects to Microsoft Graph US Gov and validates the Windows Autopilot device
        preparation configuration on a GCC High / DoD tenant against explicit pass/fail gates:
        the named WAPG groups exist, the device group is Assigned (not Dynamic), and the
        Intune Provisioning Client service principal OWNS the device group (the requirement
        that makes Enrollment Time Grouping work). Read-only. Placeholders use hyphenated
        names such as your-tenant-id.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WAPG-Validation.ps1
        (Graph scopes; -Environment USGov)
        Scopes requested: Directory.Read.All, Group.Read.All, Application.Read.All,
        DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall result. Overall PASS means the build is
        ready to pilot. Any FAIL prints the fix location in 03-implementation.md.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$TenantId,
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',
    [string]$DeviceGroupName = 'WAPG-Autopilot-Devices',
    [string[]]$RequiredGroups = @('WAPG-Provisioning-Users','WAPG-Pilot','WAPG-Autopilot-Devices'),
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'
)

$ErrorActionPreference = 'Stop'
$baseUri = 'https://graph.microsoft.us/beta'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result { param($Name,$Pass,$Detail)
    $results.Add([pscustomobject]@{ Check=$Name; Result=($(if($Pass){'PASS'}else{'FAIL'})); Detail=$Detail })
}

function Connect-WapgGraph {
    param([string]$TenantId,[string]$Environment,[string[]]$Scopes)
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $connect = @{ Environment = $Environment; Scopes = $Scopes }
    if ($TenantId) { $connect['TenantId'] = $TenantId }
    Connect-MgGraph @connect | Out-Null
    return (Get-MgContext)
}

Write-Host "== WAPG Validation (read-only) ==" -ForegroundColor Green
$ctx = Connect-WapgGraph -TenantId $TenantId -Environment $Environment -Scopes @(
    'Directory.Read.All','Group.Read.All','Application.Read.All','DeviceManagementConfiguration.Read.All')
Write-Host ("Connected. Environment = {0} | Tenant = {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Cyan

# Gate 0: US Gov cloud
Add-Result 'Connected to US Gov cloud (USGov/USGovDoD)' ($ctx.Environment -match 'USGov') ("Environment=$($ctx.Environment)")

# Gate 1: required groups exist
$groupCache = @{}
foreach ($name in $RequiredGroups) {
    $esc = [uri]::EscapeDataString($name)
    $g = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups?`$filter=displayName eq '$esc'&`$select=id,displayName,membershipRule").value | Select-Object -First 1
    if ($g) { $groupCache[$name] = $g }
    Add-Result ("Group exists: $name") ([bool]$g) ($(if($g){"id=$($g.id)"}else{'not found — 03-implementation Step 1'}))
}

# Gate 2: device group is Assigned (not Dynamic)
$dg = $groupCache[$DeviceGroupName]
if ($dg) {
    $isAssigned = [string]::IsNullOrEmpty($dg.membershipRule)
    Add-Result ("Device group is Assigned (not Dynamic): $DeviceGroupName") $isAssigned `
        ($(if($isAssigned){'membershipType=Assigned'}else{'Dynamic group breaks Enrollment Time Grouping — recreate as Assigned (Step 1)'}))
} else {
    Add-Result ("Device group is Assigned: $DeviceGroupName") $false 'device group not found'
}

# Gate 3: Provisioning Client SP exists
$sp = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/servicePrincipals?`$filter=appId eq '$ProvisioningClientAppId'&`$select=id,displayName,appId").value | Select-Object -First 1
Add-Result 'Intune Provisioning Client service principal present' ([bool]$sp) `
    ($(if($sp){"$($sp.displayName) ($($sp.appId))"}else{"appId $ProvisioningClientAppId not found — open Intune once as Global Admin to provision it (R6)"}))

# Gate 4 (highest value): Provisioning Client OWNS the device group
if ($dg -and $sp) {
    $owners = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups/$($dg.id)/owners?`$select=id").value
    $isOwner = @($owners | Where-Object { $_.id -eq $sp.id }).Count -gt 0
    Add-Result ("Provisioning Client OWNS $DeviceGroupName") $isOwner `
        ($(if($isOwner){'owner present — Enrollment Time Grouping enabled'}else{'MISSING OWNER — nothing deploys during OOBE. Add owner: 03-implementation Step 2'}))
} else {
    Add-Result ("Provisioning Client OWNS $DeviceGroupName") $false 'cannot check (group or SP missing)'
}

# --- Report ---
Write-Host "`n-- Results --" -ForegroundColor Yellow
$results | Format-Table -AutoSize | Out-String | Write-Host
$fail = @($results | Where-Object Result -eq 'FAIL').Count
if ($fail -eq 0) {
    Write-Host "OVERALL: PASS — build is ready to pilot (see 05-testing.md T4)." -ForegroundColor Green
    exit 0
} else {
    Write-Host ("OVERALL: FAIL — {0} check(s) failed. Fix per 03-implementation.md, then re-run." -f $fail) -ForegroundColor Red
    exit 1
}
