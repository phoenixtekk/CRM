<#
.SYNOPSIS
    CPLTADOPT-Report.ps1 — Copilot adoption metrics: active usage, usage by app, trend, and coverage.
.DESCRIPTION
    PURPOSE
        Read-only adoption-metrics report to steer the program and prove the return. From the Microsoft
        365 Copilot usage reports it summarizes: active users in the window, usage broken out by app
        (Teams, Outlook, Word, Excel, PowerPoint, etc.), and — with -ByDepartment — coverage by
        department so you can target lagging cohorts and under-used surfaces. Compare its numbers to the
        CPLTADOPT-Discovery.ps1 baseline to show movement.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPLTADOPT-Report.ps1
        Optional: -Period D7|D30|D90     look-back window (default D30)
        Optional: -ByDepartment          add a per-department coverage breakdown
        Optional: -CsvPath .\cpltadopt-report.csv
        Consents to Reports.Read.All, User.Read.All, Organization.Read.All (read-only).
    EXPECTED RESULTS
        Active-user total, a usage-by-app table, and (optional) per-department coverage — the signals
        that tell you which apps and cohorts need more champion/training attention. No changes are made.
        NOTE: Copilot usage-report endpoint/metric availability VARIES by tenant and licensing —
        *verify current availability in your tenant*; where unavailable, fall back to the admin-center
        report or the Viva Insights Copilot Dashboard.
.NOTES
    White-label — Copilot. Read-only.
#>
[CmdletBinding()]
param(
    [ValidateSet('D7','D30','D90','D180')][string]$Period = 'D30',
    [switch]$ByDepartment,
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Reports.Read.All','User.Read.All','Organization.Read.All' -NoWelcome

Write-Host "`n=== Copilot Adoption Report ($Period) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$csv = $null
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365CopilotUsageUserDetail(period='$Period')" -ErrorAction Stop
    $csv = $resp | ConvertFrom-Csv -ErrorAction Stop
} catch {
    Write-Warning "Copilot usage report unavailable: $($_.Exception.Message)"
    Write-Warning "*Verify the Copilot usage-report endpoint in your tenant.* Use admin-center Reports or the Viva Copilot Dashboard instead."
    Disconnect-MgGraph | Out-Null
    return
}

# Active = has a Last Activity Date within the window
$active = @($csv | Where-Object { $_.'Last Activity Date' })
Write-Host ("Active Copilot users: {0} of {1} reported" -f $active.Count, $csv.Count) -ForegroundColor Green

# Usage-by-app: the per-app "Last Activity Date" columns indicate which surfaces users touched
$appColumns = @($csv | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match 'Last Activity Date' -and $_.Name -notmatch '^Report' -and $_.Name -ne 'Last Activity Date' } | Select-Object -ExpandProperty Name)
if ($appColumns) {
    Write-Host "`n--- Active users by app ---" -ForegroundColor Cyan
    $appRows = foreach ($col in $appColumns) {
        $n = @($csv | Where-Object { $_.$col }).Count
        $label = $col -replace ' Last Activity Date',''
        [pscustomobject]@{ App=$label; ActiveUsers=$n }
    }
    $appRows | Sort-Object ActiveUsers -Descending | ForEach-Object {
        Write-Host ("  {0,-28} {1}" -f $_.App, $_.ActiveUsers)
    }
} else {
    Write-Host "Per-app columns not present in this report shape — reporting total active only. *Verify report schema in your tenant.*" -ForegroundColor Yellow
}

if ($ByDepartment) {
    Write-Host "`n--- Coverage by department ---" -ForegroundColor Cyan
    $deptMap = @{}
    Get-MgUser -All -Property 'userPrincipalName','department' | ForEach-Object { $deptMap[$_.UserPrincipalName] = $_.Department }
    $grp = $active | Group-Object { $deptMap[$_.'User Principal Name'] }
    foreach ($g in ($grp | Sort-Object Count -Descending)) {
        Write-Host ("  {0,-28} active users: {1}" -f ($(if($g.Name){$g.Name}else{'<unknown>'})), $g.Count)
    }
}

if ($CsvPath) {
    $active | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported active-user detail to {0}" -f $CsvPath) -ForegroundColor Green
}
Write-Host "`nCompare active-user totals to your CPLTADOPT-Discovery.ps1 baseline to show adoption movement."
Disconnect-MgGraph | Out-Null
