<#
.SYNOPSIS
    STIGG-Discovery.ps1 — read-only inventory of existing Intune STIG-relevant objects in a US Gov (GCC High/DoD) tenant.
.DESCRIPTION
    PURPOSE
        Inventories existing configuration profiles, Administrative Template (ADMX) profiles, custom
        (OMA-URI) profiles, compliance policies, security baselines, and Entra device groups so you
        do not collide with or duplicate objects before configuring. Read-only: it changes nothing.
        Connects to Microsoft Graph US Gov endpoints. Replace placeholders like your-tenant-id inline.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\STIGG-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\STIGG-Discovery.ps1 -Environment USGovDoD
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All,
         Group.Read.All; -Environment USGov for GCC High or USGovDoD for DoD)
    EXPECTED RESULTS
        A console summary and an optional JSON export listing each object by name and id. Admin sees
        counts per object type and any names that match this solution's naming convention (STIG-Win-*,
        SG-STIG-*). PASS = inventory returns without error and no naming collisions with objects you
        intend to create. FAIL = connect error (wrong cloud/scopes) or an unexpected pre-existing STIG-Win-* object.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$NamePrefix = 'STIG-Win',
    [string]$GroupPrefix = 'SG-STIG',

    [string]$OutputJson
)

$ErrorActionPreference = 'Stop'

function Connect-StiggGraph {
    param([string]$Env)
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All',
        'Group.Read.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser (PowerShell 7+ recommended)."
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if (-not $ctx) { throw "Connect-MgGraph did not establish a context." }
    Write-Host ("Connected as {0} (tenant {1})." -f $ctx.Account, $ctx.TenantId) -ForegroundColor Green
}

function Invoke-StiggGet {
    param([string]$RelativeUri)
    # Graph host is resolved by the connected environment (graph.microsoft.us / dod-graph.microsoft.us).
    $results = @()
    $uri = "/beta/$RelativeUri"
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
    return $results
}

try {
    Connect-StiggGraph -Env $Environment

    Write-Host "`n== Discovery: existing Intune objects (US Gov) ==" -ForegroundColor Yellow

    $inventory = [ordered]@{}

    Write-Host "`n-- Device configuration profiles (Settings Catalog / templates) --"
    $configProfiles = Invoke-StiggGet 'deviceManagement/configurationPolicies?$select=id,name,description'
    $legacyProfiles = Invoke-StiggGet 'deviceManagement/deviceConfigurations?$select=id,displayName,description'
    $inventory.configurationPolicies = $configProfiles | Select-Object id, name, description
    $inventory.deviceConfigurations = $legacyProfiles | Select-Object id, displayName, description
    Write-Host ("  Settings Catalog policies : {0}" -f ($configProfiles | Measure-Object).Count)
    Write-Host ("  Legacy/template/custom    : {0}" -f ($legacyProfiles | Measure-Object).Count)

    Write-Host "`n-- Compliance policies --"
    $compliance = Invoke-StiggGet 'deviceManagement/deviceCompliancePolicies?$select=id,displayName,description'
    $inventory.compliancePolicies = $compliance | Select-Object id, displayName, description
    Write-Host ("  Compliance policies       : {0}" -f ($compliance | Measure-Object).Count)

    Write-Host "`n-- Security baselines (incl. STIG audit baseline if licensed via Advanced Analytics) --"
    try {
        $baselines = Invoke-StiggGet 'deviceManagement/intents?$select=id,displayName,description'
        $inventory.securityBaselines = $baselines | Select-Object id, displayName, description
        Write-Host ("  Security baseline instances: {0}" -f ($baselines | Measure-Object).Count)
    } catch {
        Write-Host "  Security baseline enumeration not available (may be unlicensed in this tenant). Verify for GCC High/DoD." -ForegroundColor DarkYellow
        $inventory.securityBaselines = @()
    }

    Write-Host "`n-- Entra security groups (device targeting) --"
    $groups = Invoke-StiggGet "groups?`$filter=securityEnabled eq true&`$select=id,displayName"
    $inventory.groups = $groups | Select-Object id, displayName
    Write-Host ("  Security groups           : {0}" -f ($groups | Measure-Object).Count)

    Write-Host "`n== Naming-collision check (this solution's convention) ==" -ForegroundColor Yellow
    $existingNames = @()
    $existingNames += ($configProfiles | ForEach-Object { $_.name })
    $existingNames += ($legacyProfiles | ForEach-Object { $_.displayName })
    $existingNames += ($compliance | ForEach-Object { $_.displayName })
    $existingNames += ($inventory.securityBaselines | ForEach-Object { $_.displayName })
    $profileCollisions = $existingNames | Where-Object { $_ -and $_ -like "$NamePrefix*" }
    $groupCollisions = $groups | Where-Object { $_.displayName -like "$GroupPrefix*" } | ForEach-Object { $_.displayName }

    if ($profileCollisions -or $groupCollisions) {
        Write-Host "  COLLISION: pre-existing objects match this solution's naming:" -ForegroundColor Red
        $profileCollisions | ForEach-Object { Write-Host "    profile/policy: $_" -ForegroundColor Red }
        $groupCollisions   | ForEach-Object { Write-Host "    group:         $_" -ForegroundColor Red }
        Write-Host "  Review before creating new objects to avoid duplicates." -ForegroundColor Red
    } else {
        Write-Host "  PASS: no pre-existing objects match '$NamePrefix*' or '$GroupPrefix*'." -ForegroundColor Green
    }

    if ($OutputJson) {
        $inventory | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputJson -Encoding utf8
        Write-Host "`nInventory written to $OutputJson" -ForegroundColor Cyan
    }

    Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
}
catch {
    Write-Error "Discovery failed: $($_.Exception.Message)"
    Write-Host "Check: PowerShell 7+, Microsoft.Graph installed, correct -Environment (USGov/USGovDoD), and read scopes consented." -ForegroundColor Yellow
    exit 1
}
finally {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
}
