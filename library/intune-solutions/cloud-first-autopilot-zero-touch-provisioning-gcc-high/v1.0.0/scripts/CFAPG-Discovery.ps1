<#
.SYNOPSIS
    CFAPG-Discovery.ps1 — read-only inventory of the current GCC High provisioning posture.
.DESCRIPTION
    PURPOSE
        Connects to Microsoft Graph US Gov and reports the current state relevant to
        Cloud-First Autopilot Zero-Touch Provisioning on a GCC High / DoD tenant:
        the tenant/environment, Autopilot device preparation profiles, the named CFAPG
        groups, and the Intune Provisioning Client service principal. Read-only. It
        changes nothing; it only describes what exists so you can plan the build.
        Placeholders use hyphenated names such as your-tenant-id and your-group-name.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CFAPG-Discovery.ps1
        (Graph scopes; -Environment USGov)
        Scopes requested: Directory.Read.All, Group.Read.All,
        DeviceManagementServiceConfig.Read.All, DeviceManagementConfiguration.Read.All,
        Application.Read.All
    EXPECTED RESULTS
        A printed summary. PASS when the connected environment prints as USGov and the
        report renders. FAIL (stop and re-check the tenant/cloud) if the environment is
        not USGov or connection fails.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    # Optional tenant id, e.g. your-tenant-id. If omitted, interactive sign-in chooses it.
    [string]$TenantId,

    # The Graph national cloud environment. Keep USGov for GCC High; USGovDoD for DoD.
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',

    # The Intune Provisioning Client service principal AppId (a.k.a. Intune Autopilot
    # ConfidentialClient). This is a fixed Microsoft first-party AppId, not a placeholder.
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c',

    # Names of the CFAPG groups to look for.
    [string[]]$GroupNames = @('CFAPG-Provisioning-Users','CFAPG-Pilot','CFAPG-Autopilot-Devices')
)

$ErrorActionPreference = 'Stop'

function Connect-CfapgGraph {
    param([string]$TenantId,[string]$Environment,[string[]]$Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $connect = @{ Environment = $Environment; Scopes = $Scopes }
    if ($TenantId) { $connect['TenantId'] = $TenantId }
    Connect-MgGraph @connect | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Connected. Environment = {0} | Tenant = {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Cyan
    if ($ctx.Environment -notmatch 'USGov') {
        Write-Warning "Connected environment is NOT a US Gov cloud. This solution targets GCC High/DoD. Verify the tenant."
    }
    return $ctx
}

$scopes = @(
    'Directory.Read.All','Group.Read.All',
    'DeviceManagementServiceConfig.Read.All','DeviceManagementConfiguration.Read.All',
    'Application.Read.All'
)

Write-Host "== CFAPG Discovery (read-only) ==" -ForegroundColor Green
$ctx = Connect-CfapgGraph -TenantId $TenantId -Environment $Environment -Scopes $scopes
$baseUri = 'https://graph.microsoft.us/beta'

# --- Groups ---
Write-Host "`n-- Named CFAPG groups --" -ForegroundColor Yellow
foreach ($name in $GroupNames) {
    try {
        $esc = [uri]::EscapeDataString($name)
        $resp = Invoke-MgGraphRequest -Method GET -Uri "$baseUri/groups?`$filter=displayName eq '$esc'&`$select=id,displayName,membershipRule,groupTypes,securityEnabled"
        $g = $resp.value | Select-Object -First 1
        if ($g) {
            $type = if ($g.membershipRule) { 'Dynamic' } else { 'Assigned' }
            Write-Host ("  [FOUND] {0} | membership={1} | id={2}" -f $g.displayName, $type, $g.id)
        } else {
            Write-Host ("  [MISSING] {0}" -f $name) -ForegroundColor DarkYellow
        }
    } catch {
        Write-Warning ("  Error querying group {0}: {1}" -f $name, $_.Exception.Message)
    }
}

# --- Intune Provisioning Client service principal ---
Write-Host "`n-- Intune Provisioning Client service principal --" -ForegroundColor Yellow
try {
    $sp = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/servicePrincipals?`$filter=appId eq '$ProvisioningClientAppId'&`$select=id,displayName,appId").value | Select-Object -First 1
    if ($sp) {
        Write-Host ("  [FOUND] {0} | appId={1} | objectId={2}" -f $sp.displayName, $sp.appId, $sp.id)
    } else {
        Write-Host "  [MISSING] Provisioning Client not present. Enrollment Time Grouping cannot work until it exists and owns the device group." -ForegroundColor DarkYellow
    }
} catch { Write-Warning ("  Error: {0}" -f $_.Exception.Message) }

# --- Autopilot device preparation profiles ---
Write-Host "`n-- Autopilot device preparation profiles --" -ForegroundColor Yellow
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/deviceManagement/configurationPolicies?`$filter=templateReference/templateFamily eq 'enrollmentConfiguration'&`$select=id,name").value
    if ($profiles) { $profiles | ForEach-Object { Write-Host ("  {0} | id={1}" -f $_.name, $_.id) } }
    else { Write-Host "  (none returned via configurationPolicies; check Devices > Windows > Enrollment in intune.microsoft.us)" -ForegroundColor DarkGray }
} catch { Write-Warning ("  Error: {0} (device preparation surfaces vary by API version; confirm in portal)" -f $_.Exception.Message) }

# --- Windows enrollment configurations (ESP etc.) ---
Write-Host "`n-- Windows enrollment configurations (ESP, restrictions) --" -ForegroundColor Yellow
try {
    $ecs = (Invoke-MgGraphRequest -Method GET -Uri "$baseUri/deviceManagement/deviceEnrollmentConfigurations?`$select=id,displayName,deviceEnrollmentConfigurationType").value
    if ($ecs) { $ecs | ForEach-Object { Write-Host ("  {0} | type={1}" -f $_.displayName, $_.deviceEnrollmentConfigurationType) } }
} catch { Write-Warning ("  Error: {0}" -f $_.Exception.Message) }

Write-Host "`n== Discovery complete (nothing was changed). ==" -ForegroundColor Green
Write-Host "Reminder: classic Windows Autopilot is not available in GCC High; this reports the device-preparation path only." -ForegroundColor DarkCyan
