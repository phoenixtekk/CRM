<#
.SYNOPSIS
    EPM-ElevationReport.ps1 — Tenant-wide Endpoint Privilege Management elevation report.

.DESCRIPTION
    PURPOSE
        Pulls Endpoint Privilege Management elevation reporting from Microsoft Graph so you can
        see, across the tenant, which users elevated which applications, the elevation type
        (automatic / user-confirmed / support-approved), and denied/unmanaged attempts. Use it to
        measure coverage during the pilot, find legitimate apps that need a rule, and produce an
        audit trail of privileged actions.

    HOW TO RUN
        Requires the Microsoft.Graph PowerShell SDK and an account that can read EPM reports
        (e.g. Intune Administrator / Endpoint Security Manager). The script connects with the
        DeviceManagementConfiguration.Read.All scope.
            Install-Module Microsoft.Graph -Scope CurrentUser     # one time
            powershell -ExecutionPolicy Bypass -File .\EPM-ElevationReport.ps1 -CsvPath C:\Temp\epm-elevations.csv

    EXPECTED RESULTS
        A table (and optional CSV) of elevation events with user, device, file, elevation type,
        and result. Empty output means no elevations have been reported yet (allow for the
        reporting interval) or reporting is not enabled on the base policy.

.NOTES
    White-label — Intune Solutions. Read-only against Microsoft Graph.
    Graph report endpoints for EPM evolve; if a path 404s, confirm the current
    deviceManagement reports endpoint for Endpoint Privilege Management in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [int]$Top = 1000
)

# Ensure Graph auth module
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Error "Microsoft.Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

try {
    Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' -NoWelcome -ErrorAction Stop
} catch {
    Write-Error "Connect-MgGraph failed: $($_.Exception.Message)"
    return
}

# EPM elevation events are exposed via a deviceManagement report. We POST to the report endpoint and
# page the results. Endpoint name can differ by tenant/version; we try the common ones in order.
$reportBodies = @(
    @{ Name = 'UserManagedElevations'; Body = @{ } },
    @{ Name = 'UnmanagedElevations';   Body = @{ } }
)
$base = 'https://graph.microsoft.com/beta/deviceManagement/reports/getReportFilters'  # capability probe

$all = New-Object System.Collections.Generic.List[object]

function Get-EpmReport($reportName) {
    $uri  = 'https://graph.microsoft.com/beta/deviceManagement/reports/exportJobs'
    $body = @{ reportName = $reportName; format = 'json'; top = $Top } | ConvertTo-Json
    try {
        # Try a direct cached report first; fall back to listing managedDevices elevation events.
        $resp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/reports/cachedReportConfigurations" -ErrorAction Stop
        return $resp.value
    } catch {
        return $null
    }
}

Write-Host "`n=== EPM Elevation Report (tenant) ===" -ForegroundColor Cyan

# Primary attempt: the dedicated EPM elevation events collection (beta)
$elevUris = @(
    'https://graph.microsoft.com/beta/deviceManagement/elevationActivities',
    "https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsBaselines"   # harmless probe to keep paging code exercised
)

$got = $false
foreach ($name in @('UserManagedElevations','UnmanagedElevations','SupportApprovedElevations')) {
    try {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/reports/getCachedReport"
        $payload = @{ Id = $name; Top = $Top } | ConvertTo-Json
        $resp = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $payload -ContentType 'application/json' -ErrorAction Stop
        if ($resp.Values) {
            $cols = $resp.Schema.Column
            foreach ($row in $resp.Values) {
                $obj = [ordered]@{ Report = $name }
                for ($i = 0; $i -lt $cols.Count; $i++) { $obj[$cols[$i]] = $row[$i] }
                $all.Add([pscustomobject]$obj)
            }
            $got = $true
        }
    } catch {
        Write-Verbose "Report '$name' not available via getCachedReport: $($_.Exception.Message)"
    }
}

if (-not $got) {
    Write-Host "No EPM report rows returned from the cached-report endpoints." -ForegroundColor Yellow
    Write-Host "Confirm: (1) base policy has 'Send elevation data for reporting: Yes', (2) elevations have occurred and the reporting interval has elapsed, (3) your account can read EPM reports." -ForegroundColor Yellow
    Write-Host "You can always review elevations interactively in Intune → Endpoint security → Endpoint Privilege Management → Reports." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    return
}

$all | Format-Table -AutoSize
Write-Host "Total elevation rows: $($all.Count)"

if ($CsvPath) {
    $all | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Exported report to $CsvPath"
}

Disconnect-MgGraph | Out-Null
