<#
.SYNOPSIS
    MDCWP-Hunt.ps1 — run the workload-alert validation KQL to confirm Defender for Cloud alerts
    stream to the export workspace (and that a benign test alert is visible).
.DESCRIPTION
    PURPOSE
        Read-only hunting for the "Microsoft Defender for Cloud — Workload Protection Plans"
        solution. Runs the query 'MDC Workload Alert Validation - Tenant - Validate' against the
        Log Analytics workspace that receives continuous export (the SecurityAlert table) to confirm
        workload alerts are streaming and to surface any recent benign/sample alert (Testing Guide
        Tests 6 and 7).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCWP-Hunt.ps1 -WorkspaceId <log-analytics-workspace-guid>
        Requires Az.Accounts and Az.OperationalInsights. Sign in with Connect-AzAccount first.
        Read-only. The workspace GUID is the 'Workspace ID' from the Log Analytics overview blade.
    EXPECTED RESULTS
        Alert counts by severity/type from continuous export — proof workload alerts are streaming.
        Empty results => confirm plans are On and continuous export is flowing first.
.NOTES
    White-label. Read-only. The embedded KQL below is the delivered query. If you export to Sentinel
    or Graph Security instead, run the same KQL there.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WorkspaceId,
    [int]$LookbackDays = 1
)

foreach ($m in 'Az.Accounts','Az.OperationalInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow; Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Import-Module Az.OperationalInsights -ErrorAction Stop
Write-Host "`n=== MDC workload-alert validation hunt (read-only) ===" -ForegroundColor Cyan

$kql = @"
// MDC Workload Alert Validation - Tenant - Validate
// Defender for Cloud alerts arriving via continuous export.
SecurityAlert
| where TimeGenerated > ago($($LookbackDays)d)
| where ProductName has 'Azure Security Center' or ProductName has 'Microsoft Defender for Cloud'
| summarize Count=count() by AlertSeverity, AlertName
| order by Count desc
| take 50
"@

try {
    $res = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $kql -ErrorAction Stop
    if ($res.Results) {
        $res.Results | ForEach-Object { Write-Host ("   [{0}] {1}  x{2}" -f $_.AlertSeverity, $_.AlertName, $_.Count) }
        Write-Host ("`n   Rows: {0} — workload alerts are streaming via export." -f ($res.Results | Measure-Object).Count) -ForegroundColor Green
    } else {
        Write-Host "   (no rows — confirm plans On + continuous export flowing, then trigger a sample alert)" -ForegroundColor Yellow
    }
} catch {
    Write-Host ("   Query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "   Confirm the workspace receives Defender for Cloud continuous export (Implementation Step 4)." -ForegroundColor DarkGray
}
Write-Host "`nHunt complete (read-only). Empty => fix plan enablement/export first (Testing Guide Tests 1-3)." -ForegroundColor Green
