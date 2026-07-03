<#
.SYNOPSIS
    CUSTCOMPG-Discovery.ps1 — Inventory the GCC High custom-compliance objects (scripts, policies, groups) via US Gov Graph.
.DESCRIPTION
    PURPOSE
        Read-only recon for the Government (GCC High) edition of Intune Custom Compliance
        & Configuration Items. Lists device-compliance discovery scripts, custom-compliance
        policies, and the pilot/production target groups so an admin can confirm what exists
        before configuring or expanding. Because Graph Explorer is not supported for
        graph.microsoft.us, this script is the API-recon tool for GCC High.
        Replace the placeholder names with your own, e.g. 'CUSTCOMPG-Discovery-Win'.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CUSTCOMPG-Discovery.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All, Group.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A printed inventory of discovery scripts, custom-compliance policies, and matching
        groups in the GCC High tenant. Pass = objects you expect are listed; Fail = missing
        objects or a connection whose environment is not USGov.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $ScriptNameFilter   = 'CUSTCOMPG',
    [string] $PolicyNameFilter   = 'CUSTCOMPG',
    [string[]] $GroupNames       = @('CUSTCOMPG-Pilot-Devices','CUSTCOMPG-Prod-Devices')
)

$ErrorActionPreference = 'Stop'

function Connect-UsGovGraph {
    param([string[]] $Scopes)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or $ctx.Environment -ne 'USGov') {
        Write-Host "Connecting to Microsoft Graph US Gov (GCC High) — Environment USGov..." -ForegroundColor Cyan
        Connect-MgGraph -Environment USGov -Scopes $Scopes | Out-Null
    }
    $ctx = Get-MgContext
    if ($ctx.Environment -ne 'USGov') {
        throw "Connected environment is '$($ctx.Environment)', not 'USGov'. Reconnect with: Connect-MgGraph -Environment USGov"
    }
    Write-Host "Connected. Environment=$($ctx.Environment) Tenant=$($ctx.TenantId)" -ForegroundColor Green
}

function Invoke-UsGovGraphGet {
    # Uses the beta device-management surface; graph.microsoft.us root is applied automatically by -Environment USGov.
    param([string] $RelativeUri)
    return Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.us/beta/$RelativeUri"
}

Connect-UsGovGraph -Scopes @('DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All')

Write-Host "`n=== Device compliance discovery scripts (filter: '$ScriptNameFilter') ===" -ForegroundColor Yellow
try {
    $scripts = (Invoke-UsGovGraphGet -RelativeUri "deviceManagement/deviceComplianceScripts").value
    $scripts |
        Where-Object { $_.displayName -like "*$ScriptNameFilter*" } |
        Select-Object displayName, id, @{n='lastModified';e={$_.lastModifiedDateTime}} |
        Format-Table -AutoSize
    if (-not ($scripts | Where-Object { $_.displayName -like "*$ScriptNameFilter*" })) {
        Write-Host "  (none found — create 'CUSTCOMPG-Discovery-Win' per 03-implementation.md Step 1.4)" -ForegroundColor DarkYellow
    }
} catch {
    Write-Warning "Could not read discovery scripts: $($_.Exception.Message)"
}

Write-Host "`n=== Custom compliance policies (filter: '$PolicyNameFilter') ===" -ForegroundColor Yellow
try {
    $policies = (Invoke-UsGovGraphGet -RelativeUri "deviceManagement/deviceCompliancePolicies").value
    $policies |
        Where-Object { $_.displayName -like "*$PolicyNameFilter*" } |
        Select-Object displayName, id, '@odata.type' |
        Format-Table -AutoSize
    if (-not ($policies | Where-Object { $_.displayName -like "*$PolicyNameFilter*" })) {
        Write-Host "  (none found — create 'CUSTCOMPG-Compliance-Baseline' per 03-implementation.md Step 1.5)" -ForegroundColor DarkYellow
    }
} catch {
    Write-Warning "Could not read compliance policies: $($_.Exception.Message)"
}

Write-Host "`n=== Target groups ===" -ForegroundColor Yellow
foreach ($name in $GroupNames) {
    try {
        $g = (Invoke-UsGovGraphGet -RelativeUri "groups?`$filter=displayName eq '$name'").value
        if ($g) {
            Write-Host ("  FOUND  {0}  (id {1})" -f $name, $g[0].id) -ForegroundColor Green
        } else {
            Write-Host ("  MISSING {0}  — create in entra.microsoft.us per 03-implementation.md Step 1.1" -f $name) -ForegroundColor DarkYellow
        }
    } catch {
        Write-Warning "Could not query group '$name': $($_.Exception.Message)"
    }
}

Write-Host "`nDiscovery recon complete. This was read-only." -ForegroundColor Cyan
