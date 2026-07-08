<#
.SYNOPSIS
    DLPCJIS-Report.ps1 — read-only CJI DLP evidence report: summarizes DLP alerts/matches from Microsoft Graph by workload and severity. Makes no changes.
.DESCRIPTION
    PURPOSE
        Produces the ongoing evidence artifact for the CJI DLP control — the record you show a CJIS assessor:
        which DLP alerts fired, on which workload/service, at what severity, and their status. Reads triggered
        DLP alerts via Microsoft Graph (/security/alerts_v2, filtered to DLP), summarizes them, and writes a
        CSV/console report. Read-only (Graph read scope only). Works for both the SIMULATION pilot (what would
        have matched) and post-enforcement (what was acted on).
    HOW TO RUN
        Connect-MgGraph -Scopes 'SecurityEvents.Read.All'     # (or SecurityAlert.Read.All) — read-only, no secrets
        .\DLPCJIS-Report.ps1                                   # last 30 days to console
        .\DLPCJIS-Report.ps1 -DaysBack 7 -CsvPath .\CJI-DLP-Evidence.csv
        PowerShell 5.1+/7+; requires the Microsoft.Graph PowerShell SDK (Connect-MgGraph). DLP alert
        surfacing can lag events by minutes.
    EXPECTED RESULTS
        A summary of DLP alerts by service/severity/status plus a per-alert table, and (with -CsvPath) the
        evidence CSV 'CJI DLP Evidence - CJIS - Report'. Zero alerts during an active simulation may mean
        detection is under-matching (see the Testing guide) — not necessarily that no CJI moved.
.NOTES
    CJIS DLP Pack — read-only evidence. Matched CJI content is sensitive: restrict who runs/reads this to the
    least-privilege reviewer role, separate from the DLP administrator. Verify licensing/tenant; Graph
    security alerts availability depends on your plan.
#>
[CmdletBinding()]
param(
    [int]$DaysBack = 30,
    [string]$CsvPath,
    [string]$TitleFilter = 'DLP'   # keep alerts whose category/title indicate Data Loss Prevention
)

if (-not (Get-Command Get-MgSecurityAlertV2 -ErrorAction SilentlyContinue) -and -not (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
    Write-Error "Microsoft Graph SDK not available. Install Microsoft.Graph and run Connect-MgGraph -Scopes 'SecurityEvents.Read.All'."
    return
}
try { $ctx = Get-MgContext } catch { $ctx = $null }
if (-not $ctx) {
    Write-Error "Not connected to Graph. Run: Connect-MgGraph -Scopes 'SecurityEvents.Read.All'"
    return
}

$since = (Get-Date).ToUniversalTime().AddDays(-1 * [math]::Abs($DaysBack)).ToString('yyyy-MM-ddTHH:mm:ssZ')
Write-Host ("=== CJI DLP Evidence - CJIS - Report (since {0}) ===" -f $since) -ForegroundColor Cyan

# Pull alerts_v2 since the window; filter client-side to DLP-related alerts (category/title varies by tenant).
$alerts = @()
try {
    if (Get-Command Get-MgSecurityAlertV2 -ErrorAction SilentlyContinue) {
        $alerts = Get-MgSecurityAlertV2 -Filter "createdDateTime ge $since" -All -ErrorAction Stop
    } else {
        $uri = "https://graph.microsoft.com/v1.0/security/alerts_v2?`$filter=createdDateTime ge $since"
        do {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($resp.value) { $alerts += $resp.value }
            $uri = $resp.'@odata.nextLink'
        } while ($uri)
    }
} catch {
    Write-Error ("Could not read security alerts (scope/licensing?): {0}" -f $_.Exception.Message)
    return
}

# Keep DLP-related alerts (match on category/title/detectionSource text).
$dlp = @($alerts | Where-Object {
    ("$($_.category) $($_.title) $($_.detectionSource) $($_.serviceSource)") -match $TitleFilter
})

Write-Host ("Total alerts in window: {0}  |  DLP-related: {1}" -f @($alerts).Count, $dlp.Count) -ForegroundColor Green

if ($dlp.Count -eq 0) {
    Write-Host "No DLP alerts in the window. During an active simulation this can indicate under-matching detection — see the Testing guide (Test 3/5)." -ForegroundColor Yellow
    return
}

# Normalize to a flat evidence row per alert.
$rows = foreach ($a in $dlp) {
    [pscustomobject]@{
        Created   = $a.createdDateTime
        Service   = $a.serviceSource
        Severity  = $a.severity
        Status    = $a.status
        Title     = $a.title
        AlertId   = $a.id
    }
}

Write-Host "`n-- By service --" -ForegroundColor Cyan
$rows | Group-Object Service | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "-- By severity --" -ForegroundColor Cyan
$rows | Group-Object Severity | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "-- By status --" -ForegroundColor Cyan
$rows | Group-Object Status | Sort-Object Count -Descending | Select-Object Name, Count | Format-Table -AutoSize

Write-Host "`n-- Alert detail --" -ForegroundColor Cyan
$rows | Sort-Object Created -Descending | Format-Table -AutoSize

if ($CsvPath) {
    $rows | Sort-Object Created -Descending | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("`nEvidence CSV written to {0}." -f $CsvPath) -ForegroundColor Green
}
