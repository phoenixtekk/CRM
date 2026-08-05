<#
.SYNOPSIS
    WIFIMGT-Remediation.ps1 — safely add a missing pilot/production group assignment to the named Wi-Fi profiles (guarded; -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Closes assignment gaps found by WIFIMGT-Validate-Assignment.ps1 by ensuring each named Wi-Fi
        profile is assigned to the intended target group. It ONLY adds a group assignment where one is
        missing; it never deletes an assignment, never edits Wi-Fi settings (SSID/security/proxy), and
        never touches any other profile. Runs in preview (-WhatIf) by default — pass -Apply to commit.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Remediation.ps1 -TargetGroup 'WIFIMGT - Pilot Devices'
        Apply:             powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Remediation.ps1 -TargetGroup 'WIFIMGT - Pilot Devices' -Apply
        Sovereign cloud:   add  -Environment USGov   (or USGovDoD)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All
    EXPECTED RESULTS
        A list of profiles that are missing the target-group assignment and, when -Apply is set,
        confirmation that the assignment was added. Existing assignments are preserved.
.NOTES
    White-label — Intune Solutions. Guarded write against Microsoft Graph (default preview / -WhatIf).
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [Parameter(Mandatory)][string] $TargetGroup,
    [string[]] $ProfileNames = @(
        'WIFIMGT - Corp WiFi - Windows - Pilot',
        'WIFIMGT - Corp WiFi - iOS - Pilot',
        'WIFIMGT - Corp WiFi - Android - Pilot'
    ),
    [switch] $Apply
)

$ErrorActionPreference = 'Stop'
if (-not $Apply) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.ReadWrite.All','Group.Read.All' -NoWelcome
Write-Host "Connected to Graph ($Environment) tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan

function Get-All($uri) {
    $out = @(); $next = $uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}

if (-not $Apply) {
    Write-Host "`n*** PREVIEW MODE (-WhatIf) — no changes will be made. Re-run with -Apply to commit. ***`n" -ForegroundColor Yellow
}

# Resolve target group
$grp = Get-All "/v1.0/groups?`$filter=displayName eq '$($TargetGroup.Replace("'","''"))'&`$select=id,displayName"
if (-not $grp) { throw "Target group '$TargetGroup' not found in Entra. Create it first (Entra > Groups > New group)." }
$groupId = $grp[0].id
Write-Host "Target group: $TargetGroup ($groupId)" -ForegroundColor Cyan

$allDc = Get-All "/beta/deviceManagement/deviceConfigurations?`$select=id,displayName"

foreach ($pname in $ProfileNames) {
    $p = $allDc | Where-Object { $_.displayName -eq $pname }
    if (-not $p) {
        Write-Host "  [MISSING PROFILE] '$pname' does not exist in Intune — build it per the Implementation guide." -ForegroundColor Red
        continue
    }
    $pid = $p[0].id
    $assignments = Get-All "/beta/deviceManagement/deviceConfigurations/$pid/assignments"
    if ($assignments | Where-Object { $_.target.groupId -eq $groupId }) {
        Write-Host "  [OK]  '$pname' already assigned to '$TargetGroup'." -ForegroundColor Green
        continue
    }
    Write-Host "  [GAP] '$pname' is NOT assigned to '$TargetGroup'." -ForegroundColor DarkYellow
    if ($PSCmdlet.ShouldProcess($pname, "Add group assignment '$TargetGroup'")) {
        $targets = @()
        foreach ($a in $assignments) { $targets += @{ target = $a.target } }
        $targets += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $groupId } }
        $body = @{ assignments = $targets } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST -Uri "/beta/deviceManagement/deviceConfigurations/$pid/assign" -Body $body | Out-Null
        Write-Host "        -> assignment added." -ForegroundColor Green
    }
}

Write-Host "`nDone. Re-run WIFIMGT-Validate-Assignment.ps1 to confirm." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
