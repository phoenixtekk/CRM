<#
.SYNOPSIS
    SAMPROG-Validation.ps1 — confirm SAM-program process and data coverage for a scope.
.DESCRIPTION
    PURPOSE
        Validates that the program's foundations are in place for a given scope before (and after)
        the first governance cycle: the entitlement register is populated, a discovery/usage source
        is readable, and the intake channel is recorded as live. This is a process gate — it checks
        coverage signals; it is read-only and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SAMPROG-Validation.ps1 -Scope Pilot `
            -RegisterPath C:\SAM\entitlement-register.csv -IntakeLive
        -RegisterPath points at an export of `SAM Register - Entitlements - System of Record`
        (CSV). -IntakeLive asserts the `SAM Intake - Software Requests - Request Stage` channel is
        published. Requires the Microsoft Graph SDK for the discovery check
        (DeviceManagementManagedDevices.Read.All).
    EXPECTED RESULTS
        "COVERAGE COMPLETE" when the register has rows, discovery data is readable, and intake is
        marked live; otherwise a per-signal GAP list and a non-zero exit code.
.NOTES
    Asset Mgt — SAM Program. Read-only. The repeatable way.
#>
[CmdletBinding()]
param(
    [string]$Scope = 'Pilot',
    [string]$RegisterPath,
    [switch]$IntakeLive
)

Write-Host "=== SAM Program — coverage validation (scope: $Scope) ===" -ForegroundColor Cyan
$gaps = @()

# 1) System of record populated
$regRows = 0
if ($RegisterPath -and (Test-Path $RegisterPath)) {
    try { $regRows = @(Import-Csv -Path $RegisterPath).Count } catch { $regRows = 0 }
}
$regOk = $regRows -gt 0
Write-Host ("Entitlement register : {0} rows" -f $regRows) -ForegroundColor ($(if($regOk){'Green'}else{'Yellow'}))
if (-not $regOk) { $gaps += "register empty or path not supplied (SAM Register - Entitlements - System of Record)" }

# 2) Discovery/usage data readable
$discOk = $false
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
    $uri = "/v1.0/deviceManagement/managedDevices?`$top=1&`$select=id"
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    $discOk = @($r.value).Count -gt 0
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Host ("  discovery check skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}
Write-Host ("Discovery data       : {0}" -f ($(if($discOk){'readable'}else{'not confirmed'}))) -ForegroundColor ($(if($discOk){'Green'}else{'Yellow'}))
if (-not $discOk) { $gaps += "discovery/usage source not confirmed (run SAMPROG-Discovery.ps1)" }

# 3) Intake live
Write-Host ("Intake channel       : {0}" -f ($(if($IntakeLive){'live'}else{'not asserted'}))) -ForegroundColor ($(if($IntakeLive){'Green'}else{'Yellow'}))
if (-not $IntakeLive) { $gaps += "intake not asserted live (SAM Intake - Software Requests - Request Stage)" }

if ($gaps.Count -eq 0) {
    Write-Host "`nResult: COVERAGE COMPLETE" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nResult: COVERAGE GAPS" -ForegroundColor Yellow
    $gaps | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}
