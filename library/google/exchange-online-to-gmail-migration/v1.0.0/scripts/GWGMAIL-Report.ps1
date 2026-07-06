<#
.SYNOPSIS
    GWGMAIL-Report.ps1 — render migration coverage and exceptions for the Exchange-to-Gmail move.
.DESCRIPTION
    PURPOSE
        Produces the standing coverage report: per-user mail, calendar, and contacts coverage and the
        exception list (users missing a data type), plus overall coverage against the source
        population. It reads a per-user coverage CSV (one row per user with Mail/Calendar/Contacts
        status) and cross-checks the total population against the Microsoft 365 source through
        Microsoft Graph. Read-only against Graph — it modifies nothing and moves no mail.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWGMAIL-Report.ps1 `
            -CoverageCsv .\gwgmail-coverage.csv -CsvPath .\gwgmail-report.csv
        The coverage CSV should include columns: Upn, Mail, Calendar, Contacts (each Yes/No/Pending).
        Requires the Microsoft Graph PowerShell SDK and User.Read.All (used only to read the total
        source-user count for the coverage denominator).
    EXPECTED RESULTS
        A per-data-type coverage summary, an exception list of users missing a data type, an overall
        coverage percentage vs the source total, and an optional CSV export. No source data is modified.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CoverageCsv,
    [string]$CsvPath
)

if (-not (Test-Path $CoverageCsv)) { throw "Coverage CSV not found: $CoverageCsv" }
$rows = @(Import-Csv -Path $CoverageCsv | Where-Object { $_.Upn })
if ($rows.Count -eq 0) { throw "Coverage CSV has no usable rows (need a 'Upn' column): $CoverageCsv" }

function Test-Yes { param($v) return ($v -and ($v.Trim().ToLower() -in @('yes','y','true','1','complete','done'))) }

# Total source population (coverage denominator) from Microsoft Graph.
$sourceTotal = $null
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome
    $count = 0
    $next = "/v1.0/users?`$select=id&`$top=999"
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $next; $count += @($r.value).Count; $next = $r.'@odata.nextLink' } while ($next)
    $sourceTotal = $count
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Host ("Could not read source total from Graph ({0}); using coverage-row count as denominator." -f $_.Exception.Message) -ForegroundColor Yellow
}

$mailOk     = @($rows | Where-Object { Test-Yes $_.Mail }).Count
$calOk      = @($rows | Where-Object { Test-Yes $_.Calendar }).Count
$contactsOk = @($rows | Where-Object { Test-Yes $_.Contacts }).Count
$fullyOk    = @($rows | Where-Object { (Test-Yes $_.Mail) -and (Test-Yes $_.Calendar) -and (Test-Yes $_.Contacts) }).Count
$exceptions = $rows | Where-Object { -not ((Test-Yes $_.Mail) -and (Test-Yes $_.Calendar) -and (Test-Yes $_.Contacts)) }

Write-Host "`n=== Exchange to Gmail — migration coverage ===" -ForegroundColor Cyan
Write-Host ("Users in coverage set  : {0}" -f $rows.Count)
Write-Host ("Mail migrated          : {0} of {1}" -f $mailOk, $rows.Count)
Write-Host ("Calendar migrated      : {0} of {1}" -f $calOk, $rows.Count)
Write-Host ("Contacts migrated      : {0} of {1}" -f $contactsOk, $rows.Count)
Write-Host ("Fully migrated (all 3) : {0} of {1}" -f $fullyOk, $rows.Count) -ForegroundColor ($(if($fullyOk -eq $rows.Count){'Green'}else{'Cyan'}))

$denominator = if ($sourceTotal) { $sourceTotal } else { $rows.Count }
$overallPct  = if ($denominator -gt 0) { [math]::Round(100 * $fullyOk / $denominator, 1) } else { 0 }
Write-Host ("Overall coverage       : {0}% ({1})" -f $overallPct, ($(if($sourceTotal){'vs source total from Graph'}else{'vs coverage-row count — Graph unavailable'}))) -ForegroundColor ($(if($overallPct -ge 100){'Green'}else{'Cyan'}))

if (@($exceptions).Count -gt 0) {
    Write-Host "`n=== Exceptions (missing a data type) ===" -ForegroundColor Yellow
    $exceptions | Select-Object Upn, Mail, Calendar, Contacts | Format-Table -AutoSize
} else {
    Write-Host "`nNo exceptions — every user in the coverage set has mail, calendar, and contacts." -ForegroundColor Green
}

if ($CsvPath) {
    $rows | Select-Object Upn, Mail, Calendar, Contacts | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved {0}" -f $CsvPath)
}
