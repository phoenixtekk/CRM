<#
.SYNOPSIS
    CPLTREADY-Report.ps1 — readiness-and-adoption report for the Copilot rollout.
.DESCRIPTION
    PURPOSE
        Compiles the value view leadership needs: cohort license coverage, and Copilot activation /
        active-usage pulled from the Microsoft 365 usage reports (Graph reports API), summarized against
        the pilot success metrics. Read-only — makes no changes.
    HOW TO RUN
        Connect-MgGraph -Scopes "Reports.Read.All","Group.Read.All","User.Read.All","Organization.Read.All"
        powershell -ExecutionPolicy Bypass -File .\CPLTREADY-Report.ps1 [-CohortGroupId <id>] [-Period D30]
        Requires module: Microsoft.Graph.
    EXPECTED RESULTS
        Cohort license coverage (licensed / total) and a Copilot usage summary (enabled vs active users)
        for the period. Note: the Copilot usage report endpoint may be in beta and its availability can
        vary — verify current availability in your tenant; the M365 admin center usage report is the
        portal equivalent.
.NOTES
    Copilot. White-label. Read-only. Reporting endpoints/preview: verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$CohortGroupId,
    [ValidateSet('D7','D30','D90','D180')] [string]$Period = 'D30',
    [string]$CopilotSkuPartNumber = 'Microsoft_365_Copilot'
)

Write-Host "=== CPLTREADY Report — readiness & adoption ===" -ForegroundColor Cyan
if (-not (Get-MgContext)) { Write-Host "Run Connect-MgGraph first (see header)." -ForegroundColor Yellow; return }

# --- Cohort license coverage ---
if ($CohortGroupId) {
    $copilot = Get-MgSubscribedSku -All | Where-Object { $_.SkuPartNumber -eq $CopilotSkuPartNumber -or $_.SkuPartNumber -match 'Copilot' }
    $copilotSkuIds = @($copilot.SkuId)
    $members = Get-MgGroupMember -GroupId $CohortGroupId -All -ErrorAction SilentlyContinue
    $total = ($members|Measure-Object).Count; $lic = 0
    foreach ($m in $members) {
        $u = Get-MgUser -UserId $m.Id -Property "assignedLicenses" -ErrorAction SilentlyContinue
        if ($u -and @($u.AssignedLicenses.SkuId | Where-Object { $copilotSkuIds -contains $_ }).Count -gt 0) { $lic++ }
    }
    Write-Host ("`nCohort license coverage : {0}/{1} members Copilot-licensed" -f $lic, $total) -ForegroundColor Green
}

# --- Copilot usage (Graph reports API; may be beta — verify availability) ---
Write-Host "`n--- Copilot usage summary ($Period) ---" -ForegroundColor Cyan
$uri = "https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')"
try {
    $csv = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType HttpResponseMessage -ErrorAction Stop
    $text = $csv.Content.ReadAsStringAsync().Result
    $rows = $text | ConvertFrom-Csv
    if ($rows) {
        $enabled = ($rows | Measure-Object).Count
        # Column names in the report can vary; check for a "last activity" style column to infer active users.
        $activeCol = ($rows[0].PSObject.Properties.Name | Where-Object { $_ -match 'Last activity|LastActivity' } | Select-Object -First 1)
        $active = if ($activeCol) { ($rows | Where-Object { $_.$activeCol -and $_.$activeCol.Trim() -ne '' }).Count } else { 'n/a' }
        Write-Host ("  Enabled users : {0}" -f $enabled) -ForegroundColor Green
        Write-Host ("  Active users  : {0}  (by '{1}')" -f $active, $activeCol) -ForegroundColor Green
    } else {
        Write-Host "  Report returned no rows yet (allow usage/reporting latency)." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not read the Copilot usage report: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  This endpoint may be beta/unavailable in your tenant — verify availability, or use admin.microsoft.com -> Reports -> Usage -> Microsoft 365 Copilot." -ForegroundColor Yellow
}

Write-Host "`nCompare against the pilot success metrics (Requirement 2.7). Re-run each wave to keep value visible." -ForegroundColor Cyan
