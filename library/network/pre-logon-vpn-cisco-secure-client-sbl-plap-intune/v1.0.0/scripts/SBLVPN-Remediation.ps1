<#
.SYNOPSIS
    SBLVPN-Remediation.ps1 — safely fix failed pre-logon (SBL) installs / missing profile assignments.
.DESCRIPTION
    PURPOSE
        Safe remediation for the Cisco Secure Client Start Before Logon (SBL/PLAP) pre-logon VPN
        deployment. Finds devices where the Secure Client Win32 app failed to install and finds the
        expected app/profiles (VPN, trusted root, SCEP device cert) that are NOT assigned to the
        pilot/production group, then (1) triggers a device sync to retry failed installs and (2) adds
        the missing Required assignment to the target group. Defaults to preview only (-WhatIf): it
        PRINTS what it would do and changes nothing until you re-run with -WhatIf:$false.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\SBLVPN-Remediation.ps1
        Apply changes:
            powershell -ExecutionPolicy Bypass -File .\SBLVPN-Remediation.ps1 -WhatIf:$false
        Required Microsoft Graph scopes (delegated):
            DeviceManagementApps.ReadWrite.All
            DeviceManagementConfiguration.ReadWrite.All
            DeviceManagementManagedDevices.ReadWrite.All   (for device sync)
            Group.Read.All
    EXPECTED RESULTS
        A plan listing each remediation action (retry-sync device X; assign object Y to the group).
        In preview every line is prefixed [WHATIF]. With -WhatIf:$false each action runs and prints
        [DONE]/[FAILED]. Cisco head-end/auth problems are NOT fixed here — see 06-troubleshooting.md.
.NOTES
    White-label — the repeatable way. Write actions gated behind -WhatIf (default ON). Cisco-specific internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [bool]   $WhatIf = $true,
    [string] $TargetGroupName = 'PILOT – Pre-Logon VPN (SBL) Users',
    [switch] $RetryFailedInstalls,
    [switch] $FixMissingAssignments
)

$ErrorActionPreference = 'Stop'

# If neither switch is given, do both.
if (-not $RetryFailedInstalls -and -not $FixMissingAssignments) {
    $RetryFailedInstalls = $true
    $FixMissingAssignments = $true
}

$ExpectedApps = @(
    'Cisco Secure Client – Pre-Logon (SBL) – Win32'
)
$ExpectedProfiles = @(
    'Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows',
    'Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows',
    'Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows'
)

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementApps.ReadWrite.All',
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
Write-Host "`n=== Pre-Logon VPN (Cisco SBL/PLAP) — Remediation [$mode] ===" -ForegroundColor Cyan

# Resolve target group
$enc = [uri]::EscapeDataString($TargetGroupName)
$grp = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName"
if (-not $grp) { throw "Target group '$TargetGroupName' not found. Create it first (SBLVPN-Set-ScopeTargeting.ps1)." }
$groupId = $grp[0].id
Write-Host "Target group: $TargetGroupName ($groupId)`n"

# --- 1. Retry failed installs (device sync) ----------------------------------
if ($RetryFailedInstalls) {
    Write-Host "[1] Retry failed Secure Client (SBL) installs" -ForegroundColor Cyan
    $allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
    foreach ($name in $ExpectedApps) {
        $app = $allApps | Where-Object { $_.displayName -eq $name }
        if (-not $app) { Write-Host "  (skip) $name not found." -ForegroundColor DarkGray; continue }
        try {
            $statuses = Invoke-Graph "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
        } catch { $statuses = @() }
        $failed = $statuses | Where-Object { $_.installState -eq 'failed' }
        if (-not $failed) { Write-Host "  $name — no failed devices." -ForegroundColor DarkGray; continue }
        foreach ($f in $failed) {
            $devId = $f.deviceId
            if ([string]::IsNullOrWhiteSpace($devId)) { continue }
            Do-Action "Sync device $($f.deviceDisplayName) ($devId) to retry '$name'" {
                Invoke-MgGraphRequest -Method POST -Uri "$base/deviceManagement/managedDevices/$devId/syncDevice" | Out-Null
            }
        }
    }
}

# --- 2. Fix missing assignments ----------------------------------------------
if ($FixMissingAssignments) {
    Write-Host "`n[2] Add missing Required assignments to '$TargetGroupName'" -ForegroundColor Cyan

    # App
    $allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
    foreach ($name in $ExpectedApps) {
        $app = $allApps | Where-Object { $_.displayName -eq $name }
        if (-not $app) { Write-Host "  (skip) app $name not found." -ForegroundColor DarkGray; continue }
        $assigns = Invoke-Graph "$base/deviceAppManagement/mobileApps/$($app.id)/assignments"
        $already = $assigns | Where-Object { $_.target.groupId -eq $groupId }
        if ($already) { Write-Host "  $name — already assigned." -ForegroundColor DarkGray; continue }
        $body = @{
            mobileAppAssignments = @(@{
                '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                intent        = 'required'
                target        = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $groupId }
            })
        } | ConvertTo-Json -Depth 6
        Do-Action "Assign app '$name' as Required to '$TargetGroupName'" {
            Invoke-MgGraphRequest -Method POST -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/assign" -Body $body -ContentType 'application/json' | Out-Null
        }
    }

    # Profiles (VPN + trusted root + SCEP device cert)
    $allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
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
    Write-Host "Actions applied. Re-run SBLVPN-Report.ps1 to confirm coverage improved." -ForegroundColor Green
}
Write-Host "Note: Cisco head-end / authentication failures are NOT remediated here — see 06-troubleshooting.md." -ForegroundColor DarkGray
