<#
.SYNOPSIS
    ISEPOST-Validation.ps1 — confirm THIS device's compliance + enrollment state exactly as Cisco ISE would read it from Intune.
.DESCRIPTION
    PURPOSE
        Read-only per-device check. Looks up the machine it runs on (by Entra device id,
        or a device name you pass) in Intune via Microsoft Graph and reports the enrollment
        and compliance state ISE would consume for its access decision, plus a conceptual
        grant/deny verdict. Confirms the positive and negative test gates from the device side.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\ISEPOST-Validation.ps1 -DeviceName your-device-name

        Required Graph scopes: DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        Prints enrollment (managed yes/no), compliance state (compliant/noncompliant/inGracePeriod),
        last sync, and a conceptual verdict: compliant+enrolled = ACCESS GRANTED, else DENIED.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string]$DeviceName
)

$ErrorActionPreference = 'Stop'

function Connect-GraphSafe {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) {
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome | Out-Null
    }
}

Write-Host "=== ISEPOST Validation — this device's posture as ISE reads it ===" -ForegroundColor Cyan
Connect-GraphSafe

# --- Resolve which device to look up ----------------------------------------
if (-not $DeviceName) { $DeviceName = $env:COMPUTERNAME }
Write-Host "Looking up device: $DeviceName" -ForegroundColor Cyan

# Try to match by the local Entra device id first (most precise), else by name.
$managed = $null
$localAadId = $null
try {
    $dsreg = dsregcmd /status 2>$null
    if ($dsreg) {
        $line = ($dsreg | Select-String -Pattern 'DeviceId\s*:\s*(.+)$' | Select-Object -First 1)
        if ($line) { $localAadId = ($line.Matches.Groups[1].Value).Trim() }
    }
} catch {}

if ($localAadId) {
    $managed = Get-MgDeviceManagementManagedDevice -Filter "azureADDeviceId eq '$localAadId'" -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $managed) {
    $managed = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" -ErrorAction SilentlyContinue | Select-Object -First 1
}

if (-not $managed) {
    Write-Host "`n  RESULT: NOT FOUND in Intune (unmanaged as ISE sees it)." -ForegroundColor Red
    Write-Host "  Conceptual verdict: ACCESS DENIED / enrollment redirect (device not enrolled)." -ForegroundColor Red
    Write-Host "`nIf this device should be managed, enroll it in Intune (Requirements R1)."
    return
}

# --- Report the state ISE consumes ------------------------------------------
$enrolled   = $true
$compliance = $managed.ComplianceState        # compliant | noncompliant | inGracePeriod | ...
$mgmtAgent  = $managed.ManagementAgent
$lastSync   = $managed.LastSyncDateTime

Write-Host "`n--- State ISE would read from Intune ---" -ForegroundColor Cyan
Write-Host ("  Device name      : {0}" -f $managed.DeviceName)
Write-Host ("  Enrolled (MDM)   : {0}  (agent: {1})" -f $enrolled, $mgmtAgent)
Write-Host ("  Compliance state : {0}" -f $compliance)
Write-Host ("  OS / version     : {0} {1}" -f $managed.OperatingSystem, $managed.OsVersion)
Write-Host ("  Last Intune sync : {0}" -f $lastSync)

# --- Conceptual access verdict (the mapping this solution standardizes) ------
Write-Host "`n--- Conceptual ISE access verdict ---" -ForegroundColor Cyan
if ($compliance -eq 'compliant') {
    Write-Host "  PASS  Enrolled + compliant  ->  ACCESS GRANTED (full network / VPN)." -ForegroundColor Green
} elseif ($compliance -eq 'inGracePeriod') {
    Write-Host "  WARN  Enrolled + in grace period -> access still GRANTED, user is being warned to remediate." -ForegroundColor Yellow
} else {
    Write-Host "  FAIL  Enrolled but NON-COMPLIANT ($compliance) -> ACCESS DENIED / quarantine." -ForegroundColor Red
}

Write-Host "`nNote: the actual enforcement is performed by Cisco ISE using these signals; ISE authorization policy is deferred to Cisco documentation."
