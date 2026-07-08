<#
.SYNOPSIS
    AOVUT-Remediation.ps1 — safely fix errored user-tunnel profiles / missing profile assignments.
.DESCRIPTION
    PURPOSE
        Safe remediation for the Always On VPN user-tunnel deployment. Finds devices where the VPN or
        user-certificate profile is in an error state and finds expected profiles that are NOT assigned
        to the pilot/production USER group, then (1) triggers a device sync to retry errored devices and
        (2) adds the missing assignment to the target USER group. Defaults to preview only (-WhatIf): it
        PRINTS what it would do and changes nothing until you re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\AOVUT-Remediation.ps1
        Apply changes:
            powershell -ExecutionPolicy Bypass -File .\AOVUT-Remediation.ps1 -WhatIf:$false
        Required Microsoft Graph scopes (delegated):
            DeviceManagementConfiguration.ReadWrite.All
            DeviceManagementManagedDevices.ReadWrite.All   (for device sync)
            Group.Read.All
    EXPECTED RESULTS
        A plan listing each remediation action (retry-sync device X; assign profile Y to the group).
        In preview every line is prefixed [WHATIF]. With -WhatIf:$false each action runs and prints
        [DONE]/[FAILED]. VPN gateway / Conditional Access problems are NOT fixed here — see 06-troubleshooting.md.
.NOTES
    White-label — the repeatable way. Write actions gated behind -WhatIf (default ON). VPN gateway / head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [bool]   $WhatIf = $true,
    [string] $TargetGroupName = 'PILOT – AOVPN User Tunnel Users',
    [switch] $RetryErroredDevices,
    [switch] $FixMissingAssignments
)

$ErrorActionPreference = 'Stop'

# If neither switch is given, do both.
if (-not $RetryErroredDevices -and -not $FixMissingAssignments) {
    $RetryErroredDevices = $true
    $FixMissingAssignments = $true
}

$ExpectedProfiles = @(
    'AOVPN – User Tunnel – Trusted Root CA – Windows',
    'AOVPN – User Tunnel – User Cert (SCEP) – Windows',
    'AOVPN – User Tunnel – Profile – Windows'
)

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementConfiguration.ReadWrite.All',
        'DeviceManagementManagedDevices.ReadWrite.All',
        'Group.Read.All'
    )
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

function Do-Action {
    param([string] $Description, [scriptblock] $Action)
    if ($WhatIf) {
        Write-Host "[WHATIF] $Description" -ForegroundColor Yellow
    } else {
        try {
            & $Action
            Write-Host "[DONE]   $Description" -ForegroundColor Green
        } catch {
            Write-Host "[FAILED] $Description :: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

$mode = if ($WhatIf) { 'PREVIEW (-WhatIf) — no changes will be made' } else { 'APPLY — changes WILL be made' }
Write-Host "`n=== Always On VPN User Tunnel — Remediation [$mode] ===" -ForegroundColor Cyan

# Resolve target group
$enc = [uri]::EscapeDataString($TargetGroupName)
$grp = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName"
if (-not $grp) { throw "Target group '$TargetGroupName' not found. Create it first (AOVUT-Set-ScopeTargeting.ps1)." }
$groupId = $grp[0].id
Write-Host "Target group: $TargetGroupName ($groupId)`n"

$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"

# --- 1. Retry errored devices (device sync) ----------------------------------
if ($RetryErroredDevices) {
    Write-Host "[1] Retry devices with an errored user-tunnel/cert profile" -ForegroundColor Cyan
    foreach ($name in $ExpectedProfiles) {
        $prof = $allConfigs | Where-Object { $_.displayName -eq $name }
        if (-not $prof) { Write-Host "  (skip) $name not found." -ForegroundColor DarkGray; continue }
        try {
            $statuses = Invoke-Graph "$base/deviceManagement/deviceConfigurations/$($prof.id)/deviceStatuses"
        } catch { $statuses = @() }
        $errored = $statuses | Where-Object { $_.status -in @('error','conflict') }
        if (-not $errored) { Write-Host "  $name — no errored devices." -ForegroundColor DarkGray; continue }
        foreach ($e in $errored) {
            $devId = $e.deviceId
            if ([string]::IsNullOrWhiteSpace($devId)) { continue }
            Do-Action "Sync device $($e.deviceDisplayName) ($devId) to retry '$name'" {
                Invoke-MgGraphRequest -Method POST -Uri "$base/deviceManagement/managedDevices/$devId/syncDevice" | Out-Null
            }
        }
    }
}

# --- 2. Fix missing assignments ----------------------------------------------
if ($FixMissingAssignments) {
    Write-Host "`n[2] Add missing assignments to '$TargetGroupName'" -ForegroundColor Cyan
    foreach ($name in $ExpectedProfiles) {
        $prof = $allConfigs | Where-Object { $_.displayName -eq $name }
        if (-not $prof) { Write-Host "  (skip) profile $name not found." -ForegroundColor DarkGray; continue }
        $assigns = Invoke-Graph "$base/deviceManagement/deviceConfigurations/$($prof.id)/assignments"
        $already = $assigns | Where-Object { $_.target.groupId -eq $groupId }
        if ($already) { Write-Host "  $name — already assigned." -ForegroundColor DarkGray; continue }
        $body = @{
            assignments = @(@{
                target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $groupId }
            })
        } | ConvertTo-Json -Depth 6
        Do-Action "Assign profile '$name' to '$TargetGroupName'" {
            Invoke-MgGraphRequest -Method POST -Uri "$base/deviceManagement/deviceConfigurations/$($prof.id)/assign" -Body $body -ContentType 'application/json' | Out-Null
        }
    }
}

Write-Host "`n=== Remediation complete ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "This was a PREVIEW. Re-run with -WhatIf:`$false to apply the actions above." -ForegroundColor Yellow
} else {
    Write-Host "Actions applied. Re-run AOVUT-Report.ps1 to confirm coverage improved." -ForegroundColor Green
}
Write-Host "Note: VPN gateway / head-end and Conditional Access problems are NOT remediated here — see 06-troubleshooting.md." -ForegroundColor DarkGray
