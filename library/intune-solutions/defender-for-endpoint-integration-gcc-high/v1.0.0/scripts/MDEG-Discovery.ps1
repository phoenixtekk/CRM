<#
.SYNOPSIS
    MDEG-Discovery.ps1 — inventory Intune-managed devices and MDE onboarding readiness on a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Read-only inventory of your GCC High tenant's managed devices, OS build, join type,
        and the Intune-to-Defender connector state, so you know your starting point before
        configuring the integration. Connects to the US Government Microsoft Graph
        (graph.microsoft.us). Replace values like your-tenant-id only if you script -TenantId.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEG-Discovery.ps1
        (Graph scopes: DeviceManagementManagedDevices.Read.All,
         DeviceManagementConfiguration.Read.All; connects with -Environment USGov)
    EXPECTED RESULTS
        A table of managed Windows devices (name, OS, build, join type, compliance) plus a
        summary line. PASS = your tenant's devices are listed with no authority error.
        FAIL = empty result or a Commercial-authority error means the session did not reach
        the US Gov cloud — see 06-troubleshooting.md, section F.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $scopes = @(
        'DeviceManagementManagedDevices.Read.All',
        'DeviceManagementConfiguration.Read.All'
    )
    # GCC High MUST use the US Gov Graph environment, otherwise the session talks to Commercial.
    $connectParams = @{ Environment = 'USGov'; Scopes = $scopes }
    if ($TenantId) { $connectParams.TenantId = $TenantId }

    Write-Host "Connecting to Microsoft Graph (US Government cloud, -Environment USGov)..." -ForegroundColor Cyan
    Connect-MgGraph @connectParams | Out-Null

    $ctx = Get-MgContext
    Write-Host ("Connected. Environment: {0} | Tenant: {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Green
    if ($ctx.Environment -ne 'USGov') {
        Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov'. On GCC High this is wrong — disconnect and reconnect with -Environment USGov."
    }
}

try {
    Connect-UsGovGraph -TenantId $TenantId

    Write-Host "`nEnumerating managed devices..." -ForegroundColor Cyan
    $devices = Get-MgDeviceManagementManagedDevice -All -ErrorAction Stop

    if (-not $devices) {
        Write-Warning "No managed devices returned. If you expected devices, confirm you connected to the US Gov cloud (see 06-troubleshooting.md, F)."
        return
    }

    $report = $devices | ForEach-Object {
        [pscustomobject]@{
            DeviceName     = $_.DeviceName
            OS             = $_.OperatingSystem
            OSVersion      = $_.OsVersion
            JoinType       = $_.JoinType
            Ownership      = $_.ManagedDeviceOwnerType
            Compliance     = $_.ComplianceState
            LastCheckIn    = $_.LastSyncDateTime
            AadDeviceId    = $_.AzureAdDeviceId
        }
    }

    $windows = $report | Where-Object { $_.OS -match 'Windows' }

    Write-Host "`n=== Managed device inventory (GCC High) ===" -ForegroundColor Yellow
    $report | Sort-Object OS, DeviceName | Format-Table -AutoSize

    Write-Host "`n=== Summary ===" -ForegroundColor Yellow
    Write-Host ("Total managed devices : {0}" -f $report.Count)
    Write-Host ("Windows devices       : {0}" -f $windows.Count)
    Write-Host ("Compliant             : {0}" -f ($report | Where-Object { $_.Compliance -eq 'compliant' }).Count)
    $notJoined = $windows | Where-Object { $_.JoinType -notmatch 'Joined' }
    if ($notJoined) {
        Write-Warning ("{0} Windows device(s) are not Entra (hybrid) joined — required for the Windows MDE compliance integration (see 02-requirements.md R5)." -f $notJoined.Count)
    }

    if ($OutputCsv) {
        $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host ("`nSaved inventory to {0}" -f $OutputCsv) -ForegroundColor Green
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
