<#
.SYNOPSIS
    INTCOMPDXG-Discovery.ps1 — snapshot Intune device compliance on GCC High (US Gov).
.DESCRIPTION
    PURPOSE
        Read-only starting point for the Diagnostic Playbook. For a device (by name) or a group,
        reports enrollment state, last check-in time, which compliance policies apply, the overall
        compliance state, and each failing setting — against Microsoft Graph US Gov endpoints.
        Pass your device name as -DeviceName 'your-device-name' or a group as -GroupName 'your-group'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDXG-Discovery.ps1 -DeviceName your-device-name
        (Graph scopes: DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All;
         connects with -Environment USGov. For DoD tenants pass -CloudEnvironment USGovDoD.)
    EXPECTED RESULTS
        A per-device table: enrollment/last-check-in, overall compliance state, and PASS/FAIL per
        applied compliance policy/setting. Empty output almost always means you connected to the
        Commercial cloud — confirm (Get-MgContext).Environment is USGov.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [string]$GroupName,
    [ValidateSet('USGov','USGovDoD')][string]$CloudEnvironment = 'USGov'
)

$ErrorActionPreference = 'Stop'
$scopes = @('DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All')

function Connect-UsGovGraph {
    param([string]$Env,[string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph modules not found. Install: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env) ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
    }
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. On GCC High you MUST use -Environment USGov (or USGovDoD)."
    }
    Write-Host ("Connected: tenant={0} environment={1}" -f $ctx.TenantId,$ctx.Environment) -ForegroundColor Green
}

function Invoke-Graph {
    param([string]$Uri)
    # $Uri is a relative Graph path (e.g. /deviceManagement/managedDevices). Invoke-MgGraphRequest
    # resolves it against the connected environment's base URL (graph.microsoft.us for USGov).
    Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
}

Connect-UsGovGraph -Env $CloudEnvironment -Scopes $scopes

# Resolve the set of managed devices to inspect.
$devices = @()
if ($DeviceName) {
    $enc = [uri]::EscapeDataString($DeviceName)
    $resp = Invoke-Graph "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$enc'"
    $devices = @($resp.value)
    if (-not $devices) { Write-Warning "No managed device named '$DeviceName' found in this tenant."; }
}
elseif ($GroupName) {
    $genc = [uri]::EscapeDataString($GroupName)
    $grp = Invoke-Graph "/v1.0/groups?`$filter=displayName eq '$genc'"
    $gid = @($grp.value)[0].id
    if (-not $gid) { throw "Group '$GroupName' not found." }
    $members = Invoke-Graph "/v1.0/groups/$gid/members?`$select=id,displayName"
    foreach ($m in $members.value) {
        $dn = [uri]::EscapeDataString($m.displayName)
        $d = Invoke-Graph "/beta/deviceManagement/managedDevices?`$filter=deviceName eq '$dn'"
        $devices += @($d.value)
    }
}
else {
    Write-Host "No -DeviceName/-GroupName given; sampling up to 50 managed devices." -ForegroundColor Yellow
    $resp = Invoke-Graph "/beta/deviceManagement/managedDevices?`$top=50"
    $devices = @($resp.value)
}

Write-Host "`n=== Compliance Discovery ($CloudEnvironment) — $($devices.Count) device(s) ===" -ForegroundColor Cyan

$out = New-Object System.Collections.Generic.List[object]
foreach ($dev in $devices) {
    $out.Add([pscustomobject]@{
        Device        = $dev.deviceName
        OS            = "$($dev.operatingSystem) $($dev.osVersion)"
        Ownership     = $dev.managedDeviceOwnerType
        Compliance    = $dev.complianceState
        LastCheckIn   = $dev.lastSyncDateTime
        EnrolledOn    = $dev.enrolledDateTime
        Id            = $dev.id
    })

    # Per-policy compliance state for this device.
    try {
        $states = Invoke-Graph "/beta/deviceManagement/managedDevices/$($dev.id)/deviceCompliancePolicyStates"
        foreach ($s in $states.value) {
            $flag = if ($s.state -eq 'compliant') { 'PASS' } else { 'FAIL' }
            Write-Host ("  [{0}] {1} : {2}" -f $flag,$dev.deviceName,("{0} = {1}" -f $s.displayName,$s.state)) `
                -ForegroundColor ($(if($flag -eq 'PASS'){'Green'}else{'Yellow'}))
        }
    } catch {
        Write-Host ("  [WARN] {0}: could not read compliance policy states ({1})" -f $dev.deviceName,$_.Exception.Message) -ForegroundColor DarkYellow
    }
}

$out | Format-Table -AutoSize
Write-Host "`nReminder: verify (Get-MgContext).Environment = '$CloudEnvironment'. Portals are *.us (intune.microsoft.us)." -ForegroundColor DarkCyan
Write-Host "Next: match the overall state to a branch in the Diagnostic Playbook (section 3)." -ForegroundColor DarkCyan
