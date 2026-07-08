<#
.SYNOPSIS
    AMAPIMIG-Config.ps1 — shared config + managed Google Play binding health summary for the AMAPI migration (read-only).
.DESCRIPTION
    Provides the shared connection helper, naming defaults, and constants used by the AMAPI
    migration tools, and (with -HealthSummary) reports the managed Google Play (Android Enterprise)
    binding state and last app-sync time so you can confirm the connection is healthy before
    migrating. Read-only against Microsoft Graph; makes no changes.
.EXAMPLE
    .\AMAPIMIG-Config.ps1 -HealthSummary
    (PowerShell 5.1+/7+, Microsoft.Graph SDK; connect with Connect-MgGraph)
.NOTES
    Expected results: binding bindStatus + lastAppSyncDateTime. Pass = bound/connected with a recent
    sync. Fail = unbound/stale — repair the binding before migrating. AMAPI state is evolving:
    verify legacy-vs-AMAPI status against current Microsoft guidance in the admin center.
    White-label. Read-only. No secrets.
#>

[CmdletBinding()]
param(
    [switch]$HealthSummary
)

$ErrorActionPreference = 'Stop'

# --- Shared constants / naming defaults (no secrets) -------------------------------------------
$script:AMAPIMIG = [pscustomobject]@{
    NamePrefix   = 'AMAPIMIG'
    Models       = @('WorkProfile','FullyManaged','CorpWorkProfile','Dedicated')
    Stages       = @('Pilot','Wave1','Wave2','Prod')
    # Documented Intune Android enrollment types (Graph deviceEnrollmentType values).
    EnrollmentTypeMap = @{
        'androidEnterpriseDedicatedDevice'      = 'Dedicated'
        'androidEnterpriseFullyManaged'         = 'FullyManaged'
        'androidEnterpriseCorporateWorkProfile' = 'CorpWorkProfile'
        'androidWorkProfile'                    = 'WorkProfile'
    }
}

function Connect-AmapiGraph {
    param([string[]]$Scopes = @('DeviceManagementServiceConfig.Read.All'))
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or ($Scopes | Where-Object { $ctx.Scopes -notcontains $_ })) {
        Connect-MgGraph -Scopes $Scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-AmapiGraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($null -ne $resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

if ($HealthSummary) {
    Connect-AmapiGraph -Scopes @('DeviceManagementServiceConfig.Read.All')
    Write-Host "`n=== Managed Google Play (Android Enterprise) binding health ===" -ForegroundColor Cyan
    try {
        # Beta surface — the schema for the Android Enterprise binding is version-dependent; verify
        # the property names in Graph Explorer for your tenant if a field returns null.
        $b = Invoke-MgGraphRequest -Method GET `
            -Uri 'https://graph.microsoft.com/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
        [pscustomobject]@{
            BindStatus          = $b.bindStatus
            OwnerUPN            = $b.ownerUserPrincipalName
            EnrollmentTarget    = $b.enrollmentTarget
            LastAppSyncDateTime = $b.lastAppSyncDateTime
            LastAppSyncStatus   = $b.lastAppSyncStatus
        } | Format-List
        $ok = ($b.bindStatus -and ($b.bindStatus -match 'bound|success|connected'))
        if ($ok) {
            Write-Host "RESULT: Binding appears healthy. Confirm lastAppSyncDateTime is recent before migrating." -ForegroundColor Green
        } else {
            Write-Host "RESULT: Binding NOT clearly healthy (bindStatus='$($b.bindStatus)'). Repair the managed Google Play connection before migrating." -ForegroundColor Red
        }
    } catch {
        Write-Warning "Could not read androidManagedStoreAccountEnterpriseSettings: $($_.Exception.Message)"
        Write-Host "Verify the binding manually: Intune admin center > Devices > Android > Android enterprise." -ForegroundColor Yellow
    }
    Write-Host "`nNOTE: The authoritative legacy-Play-EMM vs AMAPI status is what Microsoft surfaces in the" -ForegroundColor DarkYellow
    Write-Host "admin center / current guidance. Verify it there — it is evolving and not a single Graph field." -ForegroundColor DarkYellow
}
