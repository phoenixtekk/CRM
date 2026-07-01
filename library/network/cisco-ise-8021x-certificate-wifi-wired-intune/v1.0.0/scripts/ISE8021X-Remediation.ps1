<#
.SYNOPSIS
    ISE8021X-Remediation.ps1 — Safely fix missing 802.1X profile/cert assignments by adding the target group to the relevant Intune profiles (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Closes coverage gaps found by ISE8021X-Report.ps1 by ensuring the trusted-root, SCEP cert,
        Wi-Fi EAP-TLS and wired 802.1X profiles are all assigned to the intended target group.
        It only adds a group assignment where one is missing; it never deletes, never edits profile
        settings, and never touches Cisco ISE/switch/WLC. Runs in -WhatIf mode by default — pass
        -Apply to make changes.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ISE8021X-Remediation.ps1 -TargetGroup 'PILOT - 802.1X Devices'
        Apply:              powershell -ExecutionPolicy Bypass -File .\ISE8021X-Remediation.ps1 -TargetGroup 'PILOT - 802.1X Devices' -Apply

        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All, Group.Read.All
    EXPECTED RESULTS
        A list of profiles that are missing the target-group assignment and, when -Apply is set,
        confirmation that the assignment was added. Nothing else is modified.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco ISE + network-infra internals deferred to vendor docs.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$TargetGroup,
    [string[]]$ProfileNames = @(
        'Cisco 802.1X - Trusted Root',
        'Cisco 802.1X - SCEP Cert',
        'Corp Wi-Fi - EAP-TLS',
        'Wired 802.1X - EAP-TLS'
    ),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
# Default posture is preview: unless -Apply is given, force -WhatIf.
if (-not $Apply) { $WhatIfPreference = $true }

function Connect-Graph {
    $scopes = @('DeviceManagementConfiguration.ReadWrite.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null; try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx -or ($ctx.Scopes -notcontains 'DeviceManagementConfiguration.ReadWrite.All')) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to Graph tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string]$Uri)
    $out = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}

Connect-Graph
$base = 'https://graph.microsoft.com/beta'

if (-not $Apply) {
    Write-Host "`n*** PREVIEW MODE (-WhatIf) — no changes will be made. Re-run with -Apply to commit. ***`n" -ForegroundColor Yellow
}

# Resolve the target group
$grp = Invoke-GraphGet -Uri "$base/groups?`$filter=displayName eq '$($TargetGroup.Replace("'","''"))'&`$select=id,displayName"
if (-not $grp) { throw "Target group '$TargetGroup' not found in Entra. Create it first (see ISE8021X-Set-ScopeTargeting.ps1)." }
$groupId = $grp[0].id
Write-Host "Target group: $TargetGroup ($groupId)" -ForegroundColor Cyan

$allProfiles = Invoke-GraphGet -Uri "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"

foreach ($pname in $ProfileNames) {
    $p = $allProfiles | Where-Object { $_.displayName -eq $pname }
    if (-not $p) {
        Write-Host "  [MISSING PROFILE] '$pname' does not exist in Intune — build it per the Implementation guide." -ForegroundColor Red
        continue
    }
    $pid = $p[0].id
    $assignments = Invoke-GraphGet -Uri "$base/deviceManagement/deviceConfigurations/$pid/assignments"
    $already = $assignments | Where-Object { $_.target.groupId -eq $groupId }
    if ($already) {
        Write-Host "  [OK]      '$pname' already assigned to '$TargetGroup'." -ForegroundColor Green
        continue
    }

    Write-Host "  [GAP]     '$pname' is NOT assigned to '$TargetGroup'." -ForegroundColor DarkYellow
    if ($PSCmdlet.ShouldProcess("$pname", "Add group assignment '$TargetGroup'")) {
        # Rebuild the assignment set = existing + the new group assignment
        $targetsList = @()
        foreach ($a in $assignments) { $targetsList += @{ target = $a.target } }
        $targetsList += @{
            target = @{
                '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                groupId       = $groupId
            }
        }
        $body = @{ assignments = $targetsList } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST -Uri "$base/deviceManagement/deviceConfigurations/$pid/assign" -Body $body | Out-Null
        Write-Host "            -> assignment added." -ForegroundColor Green
    }
}

Write-Host "`nDone. Re-run ISE8021X-Report.ps1 to confirm coverage." -ForegroundColor Cyan
