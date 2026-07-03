<#
.SYNOPSIS
    HIPAACOMPG-Report.ps1 — read-only, audit-ready compliance + exposure evidence report (CSV) for a GCC High tenant.
.DESCRIPTION
    PURPOSE
        Produces a consolidated, date-stamped evidence report for the HIPAA/HITRUST endpoint control
        set on GCC High: per-device Intune compliance state and key safeguard status, plus best-effort
        tenant exposure/Secure-Score context. Output is CSV for the sovereign evidence repository.
        Captures configuration/compliance metadata only — never ePHI. Makes no changes. Replace values
        like your-evidence-path only when you set -OutputCsv. Connects to Microsoft Graph US Gov
        (graph.microsoft.us).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HIPAACOMPG-Report.ps1 -OutputCsv .\HIPAACOMPG-Report.csv
        (Graph scopes: DeviceManagementManagedDevices.Read.All,
         DeviceManagementConfiguration.Read.All, Group.Read.All, SecurityEvents.Read.All;
         connects with -Environment USGov)
    EXPECTED RESULTS
        A CSV plus a small summary CSV written to the evidence path, and a console summary
        (Windows devices, Compliant, Encrypted, exposure note). PASS = files written with device
        rows. An empty result or a Commercial-authority error means the session did not reach the
        US Gov cloud — see 06-troubleshooting.md, section F. Some Secure Score recommendations are
        omitted in Gov (expected parity gap).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string] $TenantId,
    [string] $GroupName = 'HIPAA - Clinical Endpoints',
    [string] $OutputCsv = ("HIPAACOMPG-Report-{0}.csv" -f (Get-Date -Format 'yyyyMMdd'))
)

$ErrorActionPreference = 'Stop'
$GraphBase = 'https://graph.microsoft.us/beta'

function Connect-UsGovGraph {
    param([string] $TenantId)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $p = @{ Environment = 'USGov'; Scopes = @(
        'DeviceManagementManagedDevices.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'Group.Read.All',
        'SecurityEvents.Read.All'
    ) }
    if ($TenantId) { $p.TenantId = $TenantId }
    Write-Host "Connecting to Microsoft Graph (US Government cloud, -Environment USGov)..." -ForegroundColor Cyan
    Connect-MgGraph @p | Out-Null
    $ctx = Get-MgContext
    Write-Host ("Connected. Environment: {0} | Tenant: {1}" -f $ctx.Environment, $ctx.TenantId) -ForegroundColor Green
    if ($ctx.Environment -ne 'USGov') {
        Write-Warning "Graph environment is '$($ctx.Environment)', not 'USGov'. On GCC High this is WRONG — reconnect with -Environment USGov (06-troubleshooting.md, F)."
    }
}

try {
    Connect-UsGovGraph -TenantId $TenantId
    $reportDate = (Get-Date).ToString('s')

    # --- Per-device compliance + safeguard metadata ---
    $select = 'deviceName,operatingSystem,osVersion,complianceState,isEncrypted,managementState,lastSyncDateTime'
    $rows = New-Object System.Collections.Generic.List[object]
    $devices = @()
    try {
        $devices = @((Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/managedDevices?`$select={1}" -f $GraphBase, $select) -ErrorAction Stop).value) |
                   Where-Object { $_.operatingSystem -match 'Windows' }
    } catch { Write-Warning "Could not read managed devices: $($_.Exception.Message)" }

    foreach ($d in $devices) {
        $rows.Add([pscustomobject]@{
            ReportDate      = $reportDate
            ScopeGroup      = $GroupName
            DeviceName      = $d.deviceName
            OS              = $d.operatingSystem
            OsVersion       = $d.osVersion
            ComplianceState = $d.complianceState
            Encrypted       = [bool]$d.isEncrypted
            ManagementState = $d.managementState
            LastSync        = $d.lastSyncDateTime
            Cloud           = 'USGov (GCC High)'
            ExposureNote    = 'See Defender dashboard (security.microsoft.us) for device exposure level'
        })
    }

    # --- Tenant exposure / Secure Score context (best-effort via US Gov Graph security) ---
    $exposureSummary = "Capture Exposure score + Secure Score for Devices from security.microsoft.us > Vulnerability management > Dashboard (compare to baseline per Implementation Step 10). Note: some Secure Score recommendations are omitted in GCC High (expected parity gap)."
    try {
        $sec = (Invoke-MgGraphRequest -Method GET -Uri ("{0}/security/secureScores?`$top=1" -f $GraphBase) -ErrorAction Stop).value
        if ($sec -and $sec.Count -ge 1) {
            $s = $sec[0]
            $exposureSummary = ("Tenant Secure Score {0}/{1} as of {2} (USGov). Confirm device-level exposure in security.microsoft.us. Some Gov recommendations may be absent." -f $s.currentScore, $s.maxScore, $s.createdDateTime)
        }
    } catch { Write-Verbose "Secure Score not available via US Gov Graph: $($_.Exception.Message)" }

    # --- Summary ---
    $total     = $rows.Count
    $compliant = @($rows | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
    $encrypted = @($rows | Where-Object { $_.Encrypted }).Count

    Write-Host ("`nHIPAACOMPG evidence report (GCC High) - {0}" -f $reportDate) -ForegroundColor Yellow
    Write-Host ("Windows devices: {0} | Compliant: {1} | Encrypted: {2}" -f $total, $compliant, $encrypted)
    Write-Host $exposureSummary

    if ($total -eq 0) {
        Write-Warning "No Windows devices in the report. On GCC High confirm Environment: USGov above (06-troubleshooting.md, F)."
    }

    # --- Write CSV evidence ---
    $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    $summaryPath = [System.IO.Path]::ChangeExtension($OutputCsv, $null) + 'summary.csv'
    [pscustomobject]@{
        ReportDate     = $reportDate
        Cloud          = 'USGov (GCC High)'
        ScopeGroup     = $GroupName
        WindowsDevices = $total
        Compliant      = $compliant
        Encrypted      = $encrypted
        ExposureNote   = $exposureSummary
    } | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8

    Write-Host ("`nEvidence written: {0}" -f $OutputCsv) -ForegroundColor Green
    Write-Host ("Summary written:  {0}" -f $summaryPath) -ForegroundColor Green
    Write-Host "Store in the secured, retained SOVEREIGN evidence repository (Requirement R11). Metadata only - no ePHI."
}
catch {
    Write-Error ("Report failed: {0}" -f $_.Exception.Message)
    Write-Host "If this is an authority/authentication error, you may be on the Commercial cloud. Disconnect-MgGraph and retry (this script uses -Environment USGov)." -ForegroundColor Yellow
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
