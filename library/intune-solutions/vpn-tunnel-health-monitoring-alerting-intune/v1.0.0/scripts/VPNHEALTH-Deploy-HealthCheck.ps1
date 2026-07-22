<#
.SYNOPSIS
    VPNHEALTH-Deploy-HealthCheck.ps1 — create + assign the tunnel-health MONITORING package (Proactive Remediations detection). DEFAULTS TO -WhatIf.

.DESCRIPTION
    PURPOSE
        The ONE state-changing script in this package. Via Microsoft Graph it creates the Proactive
        Remediations DETECTION-ONLY package 'VPNHEALTH - Tunnel Health - Detect - Pilot' from the local
        VPNHEALTH-Detect-TunnelHealth.ps1 and assigns it to the pilot group 'PILOT - VPN Health -
        Devices' on a daily schedule.

        *** IT DEPLOYS THE MONITORING PACKAGE ONLY. IT NEVER MODIFIES A VPN. *** The package it creates
        is a READ-ONLY health check with NO remediation script attached. This script changes only Intune
        objects (the health-check package + its assignment) — it does not touch any tunnel, gateway,
        certificate, or device VPN configuration.

        *** DEFAULTS TO -WhatIf (dry-run). *** With no switch it PREVIEWS exactly what it would create
        and assign, and changes nothing. Re-run with -Execute to actually create/assign.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\VPNHEALTH-Deploy-HealthCheck.ps1                    # DRY-RUN (default) — shows the plan, no changes
        .\VPNHEALTH-Deploy-HealthCheck.ps1 -Execute           # actually create + assign the monitor
        .\VPNHEALTH-Deploy-HealthCheck.ps1 -Execute -PilotGroupId <entra-group-guid>

    GRAPH SCOPES
        Dry-run (default): DeviceManagementConfiguration.Read.All, Group.Read.All
        -Execute:          DeviceManagementConfiguration.ReadWrite.All, Group.Read.All

    EXPECTED RESULTS
        Dry-run: prints the package it WOULD create (detection-only, RunAs, schedule) and the group it
        WOULD assign to — no changes. -Execute: creates the package and the assignment, then prints the
        new package id. (deviceHealthScripts + assignments are BETA — verify the current schema/endpoint
        against Microsoft documentation; property names may change.)

.NOTES
    White-label — Intune Solutions. State-changer for INTUNE OBJECTS ONLY (the monitoring package) —
    NEVER modifies a VPN/tunnel. Defaults to -WhatIf. Deploys a READ-ONLY, detection-only health check.
#>
[CmdletBinding()]
param(
    [switch]$Execute,                                             # omit = dry-run (-WhatIf default)
    [string]$PackageName   = 'VPNHEALTH - Tunnel Health - Detect - Pilot',
    [string]$DetectScript  = "$PSScriptRoot\VPNHEALTH-Detect-TunnelHealth.ps1",
    [string]$PilotGroupName = 'PILOT - VPN Health - Devices',
    [string]$PilotGroupId,                                        # optional: pass the group's object id directly
    [ValidateSet('system','user')] [string]$RunAs = 'system',
    [string]$Publisher = 'IT Operations'                          # white-label — your team name
)

$ErrorActionPreference = 'Stop'
$dryRun = -not $Execute
$mode   = if ($dryRun) { 'DRY-RUN (-WhatIf default — no changes)' } else { 'EXECUTE (will create + assign)' }
Write-Host "VPNHEALTH-Deploy-HealthCheck — $mode" -ForegroundColor Cyan
Write-Host 'This deploys the MONITORING package only. It never modifies a VPN/tunnel.' -ForegroundColor DarkGray

if (-not (Test-Path $DetectScript)) { throw "Detection script not found: $DetectScript" }
$scriptB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content $DetectScript -Raw)))

$scopes = if ($dryRun) { 'DeviceManagementConfiguration.Read.All','Group.Read.All' }
          else         { 'DeviceManagementConfiguration.ReadWrite.All','Group.Read.All' }
Connect-MgGraph -Scopes $scopes | Out-Null

function GraphGet($uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $uri; $i+=$r.value; $uri=$r.'@odata.nextLink' } while ($uri); return $i }

$base = 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts'

# Resolve pilot group
if (-not $PilotGroupId) {
    $g = GraphGet "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$PilotGroupName'&`$select=id,displayName"
    if (-not $g) { throw "Pilot group '$PilotGroupName' not found — create it (Implementation Step 3) or pass -PilotGroupId." }
    $PilotGroupId = $g[0].id
}
Write-Host "Pilot group: $PilotGroupName ($PilotGroupId)" -ForegroundColor Gray

# Does the package already exist?
$existing = $null
try { $existing = (GraphGet "$base`?`$select=id,displayName") | Where-Object { $_.displayName -eq $PackageName } | Select-Object -First 1 } catch {}

# Build the DETECTION-ONLY package body (NO remediationScriptContent — read-only monitor)
$body = @{
    displayName            = $PackageName
    description            = 'READ-ONLY VPN tunnel health check (monitoring only — makes no tunnel changes). Detection-only Proactive Remediation.'
    publisher             = $Publisher
    runAsAccount          = $RunAs
    runAs32Bit            = $false
    enforceSignatureCheck = $false
    detectionScriptContent = $scriptB64
    # remediationScriptContent intentionally OMITTED — this is a detection-only monitor.
}

if ($dryRun) {
    Write-Host ''
    Write-Host 'WOULD create/update this DETECTION-ONLY package:' -ForegroundColor Yellow
    [pscustomobject]@{
        Name          = $PackageName
        Exists        = [bool]$existing
        RunAs         = $RunAs
        Remediation   = 'NONE (read-only monitor)'
        DetectScript  = $DetectScript
    } | Format-List
    Write-Host "WOULD assign to: $PilotGroupName ($PilotGroupId) on a DAILY schedule." -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Dry-run complete — no changes made. Re-run with -Execute to apply.' -ForegroundColor Green
    return
}

# EXECUTE
if ($existing) {
    Invoke-MgGraphRequest -Method PATCH -Uri "$base/$($existing.id)" -Body ($body | ConvertTo-Json -Depth 5)
    $pkgId = $existing.id
    Write-Host "Updated existing package ($pkgId)." -ForegroundColor Green
} else {
    $created = Invoke-MgGraphRequest -Method POST -Uri $base -Body ($body | ConvertTo-Json -Depth 5)
    $pkgId = $created.id
    Write-Host "Created package ($pkgId)." -ForegroundColor Green
}

# Assign to the pilot group with a daily schedule (schema is BETA — verify against Microsoft docs)
$assignBody = @{
    deviceHealthScriptAssignments = @(
        @{
            target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $PilotGroupId }
            runRemediationScript = $false   # read-only monitor — no remediation to run
            runSchedule = @{ '@odata.type' = '#microsoft.graph.deviceHealthScriptDailySchedule'; interval = 1; time = '03:00:00'; useUtc = $false }
        }
    )
}
Invoke-MgGraphRequest -Method POST -Uri "$base/$pkgId/assign" -Body ($assignBody | ConvertTo-Json -Depth 8)
Write-Host "Assigned '$PackageName' to '$PilotGroupName' (daily). Read-only monitor is live." -ForegroundColor Green
Write-Host 'Validate with VPNHEALTH-Validate.ps1 after a schedule cycle.' -ForegroundColor Gray
