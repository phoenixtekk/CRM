<#
.SYNOPSIS
    HIPAACOMPG-Discovery.ps1 — read-only tenant-readiness check for the HIPAA/HITRUST endpoint control set on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Confirms the PowerShell session is on the US Government cloud (USGov), then inventories
        the named HIPAA/HITRUST objects on your GCC High tenant: the clinical scope group, the
        compliance policy, the BitLocker/lock/AV/firewall/access configuration baselines, the
        Update ring, and the Conditional Access gate. Read-only — makes no changes. Replace
        values like your-tenant-id only if you script -TenantId. Connects to Microsoft Graph
        US Gov (graph.microsoft.us).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Discovery.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All,
         DeviceManagementManagedDevices.Read.All, Group.Read.All, Policy.Read.All;
         connects with -Environment USGov)
    EXPECTED RESULTS
        A banner showing Environment: USGov, then a present/missing line per named object and a
        managed-device count. PASS = Environment is USGov and the expected objects are found and
        assigned to 'HIPAA - Clinical Endpoints'. FAIL = a Commercial-authority error or empty
        result means the session did not reach the US Gov cloud — see 06-troubleshooting.md,
        section F.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $GroupName            = 'HIPAA - Clinical Endpoints',
    [string] $CompliancePolicyName = 'HIPAA Compliance - Clinical Endpoints - Policy',
    [string] $CaPolicyName         = 'Require Compliance - Clinical Endpoints - Gate',
    [string[]] $BaselineNames      = @(
        'Encryption - Clinical Endpoints - Baseline',
        'Lock - Clinical Endpoints - Baseline',
        'Antivirus - Clinical Endpoints - Baseline',
        'Firewall - Clinical Endpoints - Baseline',
        'Patch - Clinical Endpoints - Baseline',
        'Access - Clinical Endpoints - Baseline'
    ),
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'
$GraphBase = 'https://graph.microsoft.us/beta'

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All',
        'Group.Read.All',
        'Policy.Read.All'
    )
    # GCC High MUST use the US Gov Graph environment, otherwise the session talks to Commercial.
    $p = @{ Environment = 'USGov'; Scopes = $scopes }
    if ($TenantId) { $p.TenantId = $TenantId }

    Write-Host "Connecting to Microsoft Graph (US Government cloud, -Environment USGov)..." -ForegroundColor Cyan
    Connect-MgGraph @p | Out-Null

    $ctx = Get-MgContext
    Write-Host ("Connected. Environment: {0} | Tenant: {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Green
    if ($ctx.Environment -ne 'USGov') {
        Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov'. On GCC High this is WRONG — Disconnect-MgGraph and reconnect with -Environment USGov (see 06-troubleshooting.md, F)."
    }
}

function Get-GraphValue {
    param([string] $Uri)
    (Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop).value
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Result {
    param([string] $Item, [bool] $Found, [string] $Detail)
    $results.Add([pscustomobject]@{ Item = $Item; Status = ($(if ($Found) { 'PRESENT' } else { 'MISSING' })); Detail = $Detail })
    $color = if ($Found) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1} {2}" -f $(if ($Found) { 'OK' } else { '--' }), $Item, $(if ($Detail) { "- $Detail" } else { '' })) -ForegroundColor $color
}

try {
    Connect-UsGovGraph -TenantId $TenantId

    # --- Scope group ---
    Write-Host "`nChecking scope group..." -ForegroundColor Cyan
    $grp = @(Get-GraphValue ("{0}/groups?`$filter=displayName eq '{1}'" -f $GraphBase, $GroupName)) | Select-Object -First 1
    Add-Result "Group: $GroupName" ([bool]$grp) $(if ($grp) { "id $($grp.id)" } else { 'create per 02-requirements.md R5' })

    # --- Compliance policy ---
    Write-Host "`nChecking compliance policy..." -ForegroundColor Cyan
    $cp = @(Get-GraphValue "$GraphBase/deviceManagement/deviceCompliancePolicies") | Where-Object { $_.displayName -eq $CompliancePolicyName } | Select-Object -First 1
    Add-Result "Compliance policy: $CompliancePolicyName" ([bool]$cp) $(if ($cp) { 'found' } else { 'create per 03-implementation.md Step 3' })

    # --- Configuration baselines (settings catalog + templates) ---
    Write-Host "`nChecking configuration baselines..." -ForegroundColor Cyan
    $confCfg  = @(Get-GraphValue "$GraphBase/deviceManagement/deviceConfigurations")
    $confSc   = @(Get-GraphValue "$GraphBase/deviceManagement/configurationPolicies")
    $intents  = @(Get-GraphValue "$GraphBase/deviceManagement/intents")
    foreach ($name in $BaselineNames) {
        $hit = ($confCfg | Where-Object { $_.displayName -eq $name }) -or
               ($confSc  | Where-Object { $_.name        -eq $name }) -or
               ($intents | Where-Object { $_.displayName -eq $name })
        Add-Result "Baseline: $name" ([bool]$hit) $(if ($hit) { 'found' } else { 'create per 03-implementation.md Steps 4-8' })
    }

    # --- Conditional Access gate ---
    Write-Host "`nChecking Conditional Access gate..." -ForegroundColor Cyan
    try {
        $ca = @(Get-GraphValue "$GraphBase/identity/conditionalAccess/policies") | Where-Object { $_.displayName -eq $CaPolicyName } | Select-Object -First 1
        Add-Result "CA gate: $CaPolicyName" ([bool]$ca) $(if ($ca) { "state $($ca.state)" } else { 'create per 03-implementation.md Step 9' })
    } catch {
        Add-Result "CA gate: $CaPolicyName" $false "could not read CA policies (needs Policy.Read.All): $($_.Exception.Message)"
    }

    # --- Managed device count (readiness signal) ---
    Write-Host "`nChecking managed devices..." -ForegroundColor Cyan
    $devices = @(Get-GraphValue "$GraphBase/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,complianceState")
    $win     = @($devices | Where-Object { $_.operatingSystem -match 'Windows' })
    Write-Host ("  Managed devices: {0} | Windows: {1} | Compliant: {2}" -f $devices.Count, $win.Count, (@($devices | Where-Object { $_.complianceState -eq 'compliant' }).Count)) -ForegroundColor Gray
    if ($devices.Count -eq 0) {
        Write-Warning "No managed devices returned. On GCC High this usually means the session reached the Commercial cloud — confirm Environment: USGov above (06-troubleshooting.md, F)."
    }

    # --- Summary ---
    $missing = @($results | Where-Object { $_.Status -eq 'MISSING' })
    Write-Host "`n=== Readiness summary (GCC High) ===" -ForegroundColor Yellow
    Write-Host ("Present: {0} | Missing: {1}" -f (@($results | Where-Object { $_.Status -eq 'PRESENT' }).Count), $missing.Count)
    if ($missing.Count -gt 0) {
        Write-Warning "Missing objects — build them per 02-requirements.md / 03-implementation.md before validating."
    } else {
        Write-Host "All named objects present. Proceed to HIPAACOMPG-Validation.ps1." -ForegroundColor Green
    }

    if ($OutputCsv) {
        $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host ("`nSaved discovery report to {0} (store per R11)." -f $OutputCsv) -ForegroundColor Green
    }
}
catch {
    Write-Error ("Discovery failed: {0}" -f $_.Exception.Message)
    Write-Host "If this is an authority/authentication error, you may be on the Commercial cloud. Run Disconnect-MgGraph and retry (this script uses -Environment USGov)." -ForegroundColor Yellow
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
