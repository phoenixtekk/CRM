<#
.SYNOPSIS
    RHELPG-Discovery.ps1 — GCC High/DoD read-only Remote Help posture: cloud context, feature presence, RBAC.
.DESCRIPTION
    PURPOSE
        Read-only discovery for a US Government (GCC High/DoD) tenant. Reports the sovereign-cloud
        context the SDK connected to, whether a Remote Help (remote assistance) tenant configuration is
        present, and which Intune RBAC roles carry Remote Help permissions. Because Remote Help is NOT
        offered on GCC High/DoD at authoring time (verify against current Microsoft documentation), a
        "not present" result here is the EXPECTED, correct finding for those tiers — not a fault to fix.
        For a GCC tenant (which is the commercial Intune instance) use -Environment Global instead.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Discovery.ps1                 # GCC High (default)
        powershell -ExecutionPolicy Bypass -File .\RHELPG-Discovery.ps1 -Environment USGovDoD   # DoD
        Connects to US Gov Graph (-Environment USGov/USGovDoD). Read-only scopes:
        DeviceManagementConfiguration.Read.All, DeviceManagementRBAC.Read.All.
    GRAPH SCOPES
        DeviceManagementConfiguration.Read.All, DeviceManagementRBAC.Read.All
    EXPECTED RESULTS
        The connected environment; Remote Help settings state IF the feature exists in the tenant
        (expected ABSENT on GCC High/DoD); and any RBAC roles that include Remote Help permissions.
        PASS = posture printed against the sovereign endpoint. A connection/redirect error means
        -Environment was omitted (the SDK hit the Commercial endpoint) — see RHELPG-Test-Endpoints.ps1.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
    All sovereign availability/endpoints are "verify against current Microsoft documentation".
#>
[CmdletBinding()] param([ValidateSet('USGov','USGovDoD','Global')][string]$Environment = 'USGov')
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementRBAC.Read.All' -NoWelcome

$ctx = Get-MgContext
Write-Host "`n=== Remote Help discovery — Government edition (env: $Environment) ===" -ForegroundColor Cyan
Write-Host ("Connected environment          : {0}" -f $ctx.Environment)
if ($Environment -eq 'Global') { Write-Host "Note: -Environment Global = Commercial/GCC plane. GCC uses the commercial Intune instance." -ForegroundColor DarkCyan }
else { Write-Host "Note: GCC High/DoD sovereign plane. Remote Help is NOT offered here at authoring time (verify)." -ForegroundColor Yellow }

# Remote Help tenant settings (present only where the feature exists)
Write-Host "`nRemote Help tenant configuration:" -ForegroundColor Cyan
try {
    $s = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/remoteAssistanceSettings' -ErrorAction Stop
    Write-Host ("  State                        : {0}" -f $s.remoteAssistanceState) -ForegroundColor ($(if($s.remoteAssistanceState -eq 'enabled'){'Green'}else{'Yellow'}))
    Write-Host ("  Allow session to unenrolled  : {0}" -f $s.allowSessionsToUnenrolledDevices)
    Write-Host ("  Block chat                   : {0}" -f $s.blockChat)
} catch {
    Write-Host "  Remote Help configuration NOT present in this tenant." -ForegroundColor Yellow
    Write-Host "  On GCC High/DoD this is EXPECTED — Remote Help is 'planned, not available'." -ForegroundColor Yellow
    Write-Host "  Verify against current Microsoft documentation; if GCC, retry with -Environment Global." -ForegroundColor DarkCyan
}

# RBAC roles carrying Remote Help permissions
Write-Host "`nIntune RBAC roles with Remote Help permissions:" -ForegroundColor Cyan
try {
    $roles = @((Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value)
    $rh = $roles | Where-Object {
        $perms = @()
        if ($_.rolePermissions) { $perms = $_.rolePermissions.resourceActions.allowedResourceActions }
        ($perms -join ';') -match 'RemoteAssistance|RemoteHelp|RemoteTasks'
    }
    if ($rh) { $rh | ForEach-Object { Write-Host ("  - {0} (builtIn={1})" -f $_.displayName, $_.isBuiltIn) } }
    else     { Write-Host "  No roles surfaced with Remote Help permissions (expected if the feature is absent on this tier)." -ForegroundColor Yellow }
} catch { Write-Host ("  Could not read role definitions: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nReminder: availability, endpoints, licensing, and platform limits are all" -ForegroundColor DarkCyan
Write-Host "'verify against current Microsoft documentation'. GCC = commercial instance; GCC High/DoD = *.us plane." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null
