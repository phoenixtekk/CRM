<#
.SYNOPSIS
    SASE-Discovery.ps1 - Read-only current-state edge/identity inventory for a SASE/SSE design.

    PURPOSE:
        Produces the design baseline for a SASE/SSE Architecture & Design Blueprint engagement. Uses
        Microsoft Graph to inventory the identity control-plane inputs the design depends on: the
        tenant, the phase-scope targeting groups (named "SASE Phase Scope - ..."), enrolled/compliant
        managed devices, and conditional-access policy signals. It also records placeholders for the
        non-discoverable current-state context (existing third-party SWG / VPN / CASB) that the
        architect must capture manually. The output CSV is the read-only baseline (Requirement R6)
        that drives the gap analysis and roadmap sequencing.

        Netskope tenant internals (SWG/ZTNA/CASB/SSL-inspection configuration) are NOT queried here -
        Netskope module/API specifics are deferred to the official Netskope documentation. This script
        covers the Microsoft Graph identity/edge-readiness side only.

    HOW TO RUN:
        1. Install the module (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Run (read-only; consents the read scopes interactively):
             .\SASE-Discovery.ps1 -OutputCsv ".\SASE Current State - Edge - Discovery.csv"
        3. Sign in when prompted. A global-reader / read-only admin is sufficient.

    EXPECTED RESULTS:
        A CSV (default ".\SASE Current State - Edge - Discovery.csv") with one row per discovered
        object (Area, ObjectType, Name, Detail) plus manual-capture rows for third-party SWG/VPN/CASB,
        and a console summary by area. No changes are made to any tenant - this script is strictly
        read-only.

.NOTES
    Network Solutions - read-only. The repeatable way.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv = ".\SASE Current State - Edge - Discovery.csv",
    [string]$GroupNamePrefix = "SASE Phase Scope"
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Item {
    param($Area, $Type, $Name, $Detail = '')
    $results.Add([pscustomobject]@{
        Area       = $Area
        ObjectType = $Type
        Name       = $Name
        Detail     = $Detail
    })
}

Write-Host "=== SASE/SSE current-state discovery (read-only, Microsoft Graph) ===" -ForegroundColor Cyan

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# Read-only scopes only.
Connect-MgGraph -Scopes @(
    "Organization.Read.All",
    "Group.Read.All",
    "Device.Read.All",
    "DeviceManagementManagedDevices.Read.All",
    "Policy.Read.All"
) -NoWelcome

# --- Tenant / identity control plane ---
try {
    $org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
    Add-Item -Area 'Identity' -Type 'Tenant' -Name $org.DisplayName `
             -Detail ("TenantId={0}" -f $org.Id)
} catch {
    Write-Warning "Could not read organization: $($_.Exception.Message)"
}

# --- Phase-scope targeting groups (the named SASE groups) ---
Write-Host "Enumerating phase-scope targeting groups..."
try {
    $groups = Get-MgGroup -Filter "startswith(displayName,'$GroupNamePrefix')" -All -ErrorAction Stop
    if (-not $groups) {
        Add-Item -Area 'Identity' -Type 'TargetingGroup' -Name '(none found)' `
                 -Detail "No groups starting with '$GroupNamePrefix' - build with SASE-Set-PhaseScopeTargeting.ps1"
    }
    foreach ($g in $groups) {
        $count = (Get-MgGroupMember -GroupId $g.Id -All -ErrorAction SilentlyContinue).Count
        Add-Item -Area 'Identity' -Type 'TargetingGroup' -Name $g.DisplayName `
                 -Detail ("Members={0}; Id={1}" -f $count, $g.Id)
    }
} catch {
    Write-Warning "Group enumeration failed: $($_.Exception.Message)"
}

# --- Managed devices (steering / certificate delivery readiness) ---
Write-Host "Summarizing managed devices..."
try {
    $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop
    $total     = $devices.Count
    $compliant = ($devices | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
    Add-Item -Area 'Endpoints' -Type 'ManagedDeviceSummary' -Name 'All managed devices' `
             -Detail ("Total={0}; Compliant={1}" -f $total, $compliant)
} catch {
    Write-Warning "Managed device read failed (Intune licensing/scope?): $($_.Exception.Message)"
    Add-Item -Area 'Endpoints' -Type 'ManagedDeviceSummary' -Name '(unavailable)' `
             -Detail "Could not read managed devices - confirm Intune + scope (R4)"
}

# --- Conditional access signals (identity-as-control-plane inputs) ---
Write-Host "Summarizing conditional access policies..."
try {
    $ca = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
    Add-Item -Area 'Identity' -Type 'ConditionalAccessSummary' -Name 'CA policies' `
             -Detail ("Count={0}; Enabled={1}" -f $ca.Count, (($ca | Where-Object { $_.State -eq 'enabled' }).Count))
} catch {
    Write-Warning "Conditional access read failed: $($_.Exception.Message)"
}

Disconnect-MgGraph | Out-Null

# --- Manual-capture placeholders (not discoverable via Graph) ---
Add-Item -Area 'Edge (manual)' -Type 'ThirdPartySWG'  -Name '(capture manually)' -Detail 'Record any existing proxy/SWG to be unified/retired'
Add-Item -Area 'Edge (manual)' -Type 'VPN/RemoteAccess' -Name '(capture manually)' -Detail 'Record current VPN/remote-access for ZTNA displacement planning'
Add-Item -Area 'Edge (manual)' -Type 'ThirdPartyCASB' -Name '(capture manually)' -Detail 'Record any existing CASB/cloud-app discovery in use'
Add-Item -Area 'Edge (manual)' -Type 'SSLInspectionState' -Name '(capture manually)' -Detail 'Record where SSL inspection is currently enabled/disabled'

# --- Export + summary ---
$results | Sort-Object Area, ObjectType, Name | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nExported {0} rows to {1}" -f $results.Count, $OutputCsv) -ForegroundColor Green
Write-Host "`n=== Summary by area ===" -ForegroundColor Cyan
$results | Group-Object Area | ForEach-Object {
    Write-Host ("  {0,-16} Rows={1}" -f $_.Name, $_.Count)
}
Write-Host "`nNote: Netskope tenant configuration is deferred to Netskope documentation; capture the 'Edge (manual)' rows by hand." -ForegroundColor Yellow
