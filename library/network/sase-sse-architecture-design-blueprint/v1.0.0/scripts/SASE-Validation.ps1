<#
.SYNOPSIS
    SASE-Validation.ps1 - Read-only architecture-readiness validation for a SASE/SSE rollout.

    PURPOSE:
        Validates the readiness prerequisites a SASE/SSE phase depends on, using Microsoft Graph, and
        emits PASS/FAIL per check for the readiness gate (Testing Group 0) and the per-phase pilot
        gates. Checks cover: the identity tenant/SSO readiness signals, the presence and correct
        naming of the per-phase targeting groups (Requirement R8), and device/certificate-trust
        readiness signals (managed/compliant device coverage, Requirement R4/R9). It is strictly
        read-only - it asserts state, it does not change it.

        Netskope tenant-side validation (actual SWG/ZTNA/CASB/SSL-inspection state) is deferred to the
        Netskope console / official Netskope documentation. This script validates the Graph/identity/
        endpoint-readiness side.

    HOW TO RUN:
        1. Install the module (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Run (read-only):
             .\SASE-Validation.ps1 -Phase SWG
           Valid -Phase values: Baseline, SWG, CASB, ZTNA, DataHook (or All).
        3. Sign in with a read-only / global-reader account when prompted.

    EXPECTED RESULTS:
        A console list of checks, each marked [PASS] or [FAIL], and a final summary line with the
        pass/fail count. A non-zero exit code if any check FAILS (useful for gate automation). No
        tenant changes are made.

.NOTES
    Network Solutions - read-only. The repeatable way.
#>

[CmdletBinding()]
param(
    [ValidateSet('Baseline','SWG','CASB','ZTNA','DataHook','All')]
    [string]$Phase = 'All',
    [string]$GroupNamePrefix = "SASE Phase Scope"
)

$ErrorActionPreference = 'Stop'
$pass = 0; $fail = 0

function Test-Check {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host ("[PASS] {0}" -f $Name) -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host ("[FAIL] {0} :: {1}" -f $Name, $Detail) -ForegroundColor Red
        $script:fail++
    }
}

# Phase -> expected group scopes the phase targets.
$phaseScopes = @{
    Baseline = @('Baseline')
    SWG      = @('SWG')
    CASB     = @('CASB')
    ZTNA     = @('ZTNA')
    DataHook = @('DataHook')
}
$scopesToCheck = if ($Phase -eq 'All') { $phaseScopes.Keys } else { @($Phase) }

Write-Host "=== SASE/SSE architecture-readiness validation (read-only) ===" -ForegroundColor Cyan
Write-Host ("Phase: {0}" -f $Phase) -ForegroundColor Cyan

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes @(
    "Organization.Read.All",
    "Group.Read.All",
    "Device.Read.All",
    "DeviceManagementManagedDevices.Read.All"
) -NoWelcome

# --- Identity control plane present ---
$org = $null
try { $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1 } catch {}
Test-Check -Name "Identity tenant reachable (control plane)" -Condition ([bool]$org) `
           -Detail "Could not read organization - confirm Entra access (R3)"

# --- Per-phase targeting groups exist (Pilot + Broad), correctly named ---
$allGroups = @()
try { $allGroups = Get-MgGroup -Filter "startswith(displayName,'$GroupNamePrefix')" -All -ErrorAction Stop } catch {}

foreach ($scope in $scopesToCheck) {
    foreach ($stage in @('Pilot','Broad')) {
        $expected = "$GroupNamePrefix - $scope - $stage"
        $exists = [bool]($allGroups | Where-Object { $_.DisplayName -eq $expected })
        Test-Check -Name "Targeting group present: $expected" -Condition $exists `
                   -Detail "Create with SASE-Set-PhaseScopeTargeting.ps1 (R8)"
    }
}

# --- Pilot group has members (a pilot needs a population) ---
foreach ($scope in $scopesToCheck) {
    $pilotName = "$GroupNamePrefix - $scope - Pilot"
    $pilot = $allGroups | Where-Object { $_.DisplayName -eq $pilotName } | Select-Object -First 1
    if ($pilot) {
        $members = (Get-MgGroupMember -GroupId $pilot.Id -All -ErrorAction SilentlyContinue).Count
        Test-Check -Name "Pilot group populated: $pilotName" -Condition ($members -gt 0) `
                   -Detail "Pilot group has no members - add pilot users/devices (G6)"
    }
}

# --- Endpoint / certificate-trust readiness signal: compliant managed devices present ---
try {
    $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop
    $compliant = ($devices | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
    Test-Check -Name "Managed devices available for client + cert delivery (R4)" -Condition ($devices.Count -gt 0) `
               -Detail "No managed devices - confirm Intune enrollment (R4)"
    Test-Check -Name "At least one compliant device (cert-trust delivery readiness)" -Condition ($compliant -gt 0) `
               -Detail "No compliant devices - SSL inspection cert trust depends on managed delivery (R4/R9)"
} catch {
    Test-Check -Name "Managed device readiness readable (R4)" -Condition $false `
               -Detail "Could not read managed devices - confirm Intune + scope: $($_.Exception.Message)"
}

Disconnect-MgGraph | Out-Null

Write-Host ("`n=== Validation summary [{0}] - PASS: {1}  FAIL: {2} ===" -f $Phase, $pass, $fail) -ForegroundColor Cyan
Write-Host "Reminder: Netskope-side state (SWG/ZTNA/CASB/SSL inspection) is verified in the Netskope console per Netskope docs." -ForegroundColor Yellow
if ($fail -gt 0) { exit 1 } else { exit 0 }
