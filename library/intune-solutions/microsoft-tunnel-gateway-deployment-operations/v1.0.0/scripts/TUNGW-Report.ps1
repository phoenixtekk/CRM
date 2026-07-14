<#
.SYNOPSIS
    TUNGW-Report.ps1 — fleet-wide Microsoft Tunnel VPN-profile deployment status plus a per-server
    health rollup for a Site. READ-ONLY.
.DESCRIPTION
    PURPOSE
        The operations "one page" for the Tunnel deployment:
          1. For each Tunnel VPN profile, rolls up per-device apply state (Succeeded / Error / Pending)
             across all assigned devices.
          2. For each Site, rolls up server health (healthy vs unhealthy, last check-in).
          3. Prints a KQL query (see EXPECTED RESULTS) you can paste into a Log Analytics / monitoring
             workspace for Tunnel connection + health telemetry, if you route Intune/Tunnel signals
             there.
        Run it at the Pilot gate, before Expand, and on a schedule for ongoing operations.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNGW-Report.ps1
        Optional:  -CsvPath .\tungw-report.csv   (writes the per-device rows to CSV)
        Sign in when prompted (read scopes only).
    EXPECTED RESULTS
        A summary table per VPN profile (Succeeded/Error/Pending counts), a server-health rollup per
        Site, and a ready-to-paste KQL monitoring query. No changes are made.
.NOTES
    White-label. Read-only. Documented Microsoft Graph deviceManagement endpoints; Tunnel Site/server
    resources on Graph BETA (noted). Verify current Graph coverage for your cloud.
#>
[CmdletBinding()] param(
    [string] $CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','DeviceManagementServiceConfig.Read.All' -NoWelcome

function Get-Graph($uri) {
    try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }
    catch { Write-Host ("  Query failed: {0}`n    {1}" -f $uri, $_.Exception.Message) -ForegroundColor Yellow; $null }
}
$beta = 'https://graph.microsoft.com/beta/deviceManagement'
$v1   = 'https://graph.microsoft.com/v1.0/deviceManagement'

Write-Host "`n=== Microsoft Tunnel Gateway — Fleet & Health Report (read-only) ===" -ForegroundColor Cyan

# 1. Per-profile deployment rollup.
Write-Host "`n[1] Tunnel VPN profile deployment status:" -ForegroundColor Cyan
$rows = @()
$vpn = (Get-Graph "$v1/deviceConfigurations") | Where-Object { $_.'@odata.type' -match 'Vpn' }
foreach ($p in $vpn) {
    $statuses = Get-Graph "$v1/deviceConfigurations/$($p.id)/deviceStatuses"
    if (-not $statuses) { continue }
    $succeeded = ($statuses | Where-Object { $_.status -match 'compliant|succeeded' }).Count
    $error     = ($statuses | Where-Object { $_.status -match 'error|nonCompliant|failed' }).Count
    $pending   = ($statuses | Where-Object { $_.status -match 'pending|notApplicable|unknown' }).Count
    Write-Host ("  - {0}: Succeeded={1}  Error={2}  Pending={3}" -f $p.displayName, $succeeded, $error, $pending) `
        -ForegroundColor ($(if ($error -gt 0) { 'Yellow' } else { 'Green' }))
    foreach ($s in $statuses) {
        $rows += [pscustomobject]@{ Profile = $p.displayName; Device = $s.deviceDisplayName; Status = $s.status; LastReport = $s.lastReportedDateTime }
    }
}
if (-not $vpn) { Write-Host "  (no VPN profiles found)" -ForegroundColor Yellow }

# 2. Server-health rollup per Site.
Write-Host "`n[2] Tunnel server health by Site:" -ForegroundColor Cyan
$sites = Get-Graph "$beta/microsoftTunnelSites"
foreach ($s in ($sites | Where-Object { $_ })) {
    $servers = Get-Graph "$beta/microsoftTunnelSites/$($s.id)/microsoftTunnelServers"
    $healthy = ($servers | Where-Object { $_.tunnelServerHealthStatus -match 'healthy|up' }).Count
    $total   = ($servers | Measure-Object).Count
    $col = if ($total -gt 0 -and $healthy -eq $total) { 'Green' } else { 'Yellow' }
    Write-Host ("  - Site '{0}' (FQDN {1}): {2}/{3} servers healthy" -f $s.displayName, $s.publicAddress, $healthy, $total) -ForegroundColor $col
    foreach ($sv in ($servers | Where-Object { $_ })) {
        Write-Host ("      {0} | {1} | last check-in {2}" -f $sv.displayName, $sv.tunnelServerHealthStatus, $sv.lastCheckinDateTime) -ForegroundColor DarkGray
    }
}
if (-not $sites) { Write-Host "  (no Sites found or resource unavailable)" -ForegroundColor Yellow }

# 3. Optional CSV.
if ($CsvPath -and $rows.Count -gt 0) {
    $rows | Export-Csv -NoTypeInformation -Path $CsvPath
    Write-Host ("`nPer-device rows written to {0}" -f $CsvPath) -ForegroundColor Green
}

# 4. KQL monitoring query (paste into your Log Analytics / monitoring workspace if you route signals there).
Write-Host "`n[4] KQL — Tunnel VPN sign-in / health telemetry (verify table names for your workspace):" -ForegroundColor Cyan
@'
// Tunnel-related sign-ins over the last 24h, by result and device compliance.
// Requires Entra sign-in logs routed to Log Analytics. Adjust AppDisplayName to your Tunnel-fronted app.
SigninLogs
| where TimeGenerated > ago(24h)
| where AppDisplayName has "Tunnel" or ResourceDisplayName has "Tunnel"
| extend Compliant = tostring(DeviceDetail.isCompliant)
| summarize Attempts = count() by ResultType, ResultDescription, Compliant, UserPrincipalName
| order by Attempts desc

// Conditional Access (report-only) outcomes for the Tunnel policy.
SigninLogs
| where TimeGenerated > ago(24h)
| mv-expand ca = ConditionalAccessPolicies
| where tostring(ca.displayName) == "Tunnel Access - Compliant Devices - Report-Only"
| summarize count() by CAResult = tostring(ca.result), UserPrincipalName
'@ | Write-Host -ForegroundColor Gray

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
