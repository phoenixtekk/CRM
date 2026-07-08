<#
.SYNOPSIS
    DLPCLOUD-Report.ps1 — read-only cloud-app DLP match / false-positive tuning report.
.DESCRIPTION
    PURPOSE
        Exports Defender for Cloud Apps alerts so you can classify matches as true vs false positive and
        compute the false-positive rate during the test-mode dwell (Implementation Phase 4). Primary
        source is the Microsoft Graph security alerts API filtered to the Cloud Apps service source
        (microsoftCloudAppSecurity). If an MDCA REST API token is supplied via MDCA_API_TOKEN, it also
        pulls MDCA alerts/activities directly. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCLOUD-Report.ps1 -Days 14 -CsvPath .\DLPCLOUD-Matches.csv
        # Optional MDCA REST pull (never hardcode the token):
        #   $env:MDCA_API_TOKEN = '<token>'
        #   .\DLPCLOUD-Report.ps1 -Days 14 -McasUrl 'https://<tenant>.portal.cloudappsecurity.com'
        Requires Microsoft Graph PowerShell (Connect-MgGraph, SecurityEvents.Read.All).
    EXPECTED RESULTS
        A console summary + optional CSV of Cloud-Apps alerts (title, severity, app, created time). Use it
        to tag TP/FP and compute the rate. PASS signal (Gate B): after tuning, the FP proportion trends at
        or under your agreed threshold while true positives are still present.
.NOTES
    Purview — Cloud-App DLP. Read-only. No credentials in code; MDCA token read from env var only.
#>
[CmdletBinding()]
param(
    [int]$Days = 14,
    [string]$CsvPath,
    [string]$McasUrl
)

Write-Host ("=== Cloud-App DLP Match Report (last {0} days) — read-only ===" -f $Days) -ForegroundColor Cyan
$since = (Get-Date).AddDays(-$Days).ToUniversalTime()

# --- Cloud-Apps alerts via Microsoft Graph security alerts (alerts_v2) ---
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Security)) {
    Install-Module Microsoft.Graph.Security -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Security -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome }

$rows = @()
try {
    # serviceSource 'microsoftCloudAppSecurity' = Defender for Cloud Apps
    $filter = "createdDateTime ge $($since.ToString('yyyy-MM-ddTHH:mm:ssZ')) and serviceSource eq 'microsoftCloudAppSecurity'"
    $alerts = Get-MgSecurityAlertV2 -Filter $filter -All -ErrorAction Stop
    foreach ($a in $alerts) {
        $rows += [pscustomobject]@{
            Created  = $a.CreatedDateTime
            Title    = $a.Title
            Severity = $a.Severity
            Status   = $a.Status
            Category = $a.Category
            TP_or_FP = ''   # <-- tag each row as TP or FP for the rate calculation
        }
    }
} catch {
    Write-Host ("Could not read Graph security alerts (verify SecurityEvents.Read.All): {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($rows.Count -gt 0) {
    Write-Host ("Cloud-Apps alerts in window: {0}" -f $rows.Count) -ForegroundColor Green
    $rows | Sort-Object Created -Descending | Select-Object -First 25 | Format-Table -AutoSize
    $rows | Group-Object Severity | Sort-Object Name | ForEach-Object {
        Write-Host ("  Severity {0}: {1}" -f $_.Name, $_.Count)
    }
} else {
    Write-Host 'No Cloud-Apps alerts in the window — policies may still be dwelling, or audit latency. Widen -Days and re-run.' -ForegroundColor Yellow
}

# --- Optional: MDCA REST alerts/activities (richer file-policy match detail) ---
$token = $env:MDCA_API_TOKEN
if ($token -and $McasUrl) {
    $headers = @{ Authorization = "Token $token"; 'Content-Type' = 'application/json' }
    try {
        $body = @{ filters = @{ date = @{ gte = [int64]([datetimeoffset]$since).ToUnixTimeMilliseconds() } }; limit = 100 } | ConvertTo-Json -Depth 5
        $mdcaAlerts = Invoke-RestMethod -Method Post -Uri ("{0}/api/v1/alerts/" -f $McasUrl.TrimEnd('/')) -Headers $headers -Body $body -ErrorAction Stop
        Write-Host ("MDCA REST alerts returned: {0}" -f (@($mdcaAlerts.data).Count)) -ForegroundColor Green
    } catch {
        Write-Host ("MDCA REST alerts skipped/failed: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
}

if ($CsvPath -and $rows.Count -gt 0) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Exported to {0} — tag the TP_or_FP column, then compute FP rate = FP / (TP+FP)." -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Classify TP/FP, compute the rate against your Gate B threshold, then tune (Implementation Phase 4).' -ForegroundColor Cyan
