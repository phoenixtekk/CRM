<#
.SYNOPSIS
    MSEDISC-Report.ps1 — search / hold / export status report (read-only evidence pack).
.DESCRIPTION
    Summarizes the state of a matter for the defensibility evidence pack: Content Search statistics
    and search actions (preview/export) with status, case-hold policy/rule status, and — where the
    Microsoft.Graph.Security module is available — eDiscovery (Premium) case and export status. Makes
    NO changes. Filter to one matter with -Matter, or omit to report across all searches/holds.
.EXAMPLE
    .\MSEDISC-Report.ps1 -Matter "Matter-A"        # one matter
    .\MSEDISC-Report.ps1                            # everything
    (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect with Connect-IPPSSession)
.NOTES
    Expected results: per-search item/size/status, hold enabled state, export action status, and
    (if Graph present) Premium case/export status — the evidence that collection is complete.
    White-label — Security Solutions. Read-only. Uses Get-ComplianceSearch /
    Get-ComplianceSearchAction / Get-CaseHoldPolicy / Get-CaseHoldRule (+ optional Get-MgSecurityCaseEdiscoveryCase).
#>
[CmdletBinding()] param(
    [string]$Matter
)
$nameFilter = if ($Matter) { "*$Matter*" } else { "*" }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

Write-Host "`n=== eDiscovery status report ===" -ForegroundColor Cyan
if ($Matter) { Write-Host ("  Matter filter: {0}" -f $Matter) -ForegroundColor DarkGray }

Write-Host "`n--- Content Search statistics ---" -ForegroundColor Cyan
$searches = Get-ComplianceSearch -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $nameFilter }
if ($searches) {
    $searches | Select-Object Name, Status, Items, Size, LastRunFinishedTime | Format-Table -AutoSize
} else { Write-Host "  No matching Content Searches." -ForegroundColor Yellow }

Write-Host "`n--- Search actions (preview / export) ---" -ForegroundColor Cyan
$actions = Get-ComplianceSearchAction -ErrorAction SilentlyContinue | Where-Object { $_.SearchName -like $nameFilter }
if ($actions) {
    $actions | Select-Object Name, SearchName, Action, Status | Format-Table -AutoSize
    $incomplete = @($actions | Where-Object { $_.Status -notmatch 'Completed' })
    if ($incomplete) { Write-Host ("  NOTE: {0} action(s) not Completed — export not yet defensible." -f $incomplete.Count) -ForegroundColor Yellow }
} else { Write-Host "  No search actions (no preview/export run yet)." -ForegroundColor Yellow }

Write-Host "`n--- Case holds (preservation) ---" -ForegroundColor Cyan
$holds = Get-CaseHoldPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $nameFilter }
if ($holds) {
    foreach ($h in $holds) {
        $flag = if ($h.Enabled) { 'Green' } else { 'Yellow' }
        Write-Host ("  {0} — Enabled={1} Mode={2}" -f $h.Name, $h.Enabled, $h.Mode) -ForegroundColor $flag
        Get-CaseHoldRule -Policy $h.Name -ErrorAction SilentlyContinue |
            Select-Object Name, Disabled | Format-Table -AutoSize
    }
} else { Write-Host "  No matching case-hold policies." -ForegroundColor Yellow }

Write-Host "`n--- eDiscovery (Premium) cases + exports (Graph, if available) ---" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name Microsoft.Graph.Security) {
    try {
        Import-Module Microsoft.Graph.Security -ErrorAction Stop
        Connect-MgGraph -Scopes 'eDiscovery.Read.All' -NoWelcome
        $pcases = Get-MgSecurityCaseEdiscoveryCase -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $nameFilter }
        if ($pcases) { $pcases | Select-Object DisplayName, Status, CreatedDateTime | Format-Table -AutoSize }
        else { Write-Host "  No matching Premium cases." -ForegroundColor Yellow }
        Write-Host "  (Export job status: review-set exports are per-case — verify exact Graph cmdlet/params in your tenant.)" -ForegroundColor DarkGray
    } catch {
        Write-Host "  Graph eDiscovery not queried (sign-in/permission). Verify Premium status in the Purview portal." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Microsoft.Graph.Security not installed — skipping Premium. Install-Module Microsoft.Graph.Security to include it." -ForegroundColor Yellow
}

Write-Host "`nReport complete. Keep this output + the export report/load file as the matter's evidence pack." -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
