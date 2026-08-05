<#
.SYNOPSIS
    AGBGOV-Report.ps1 — Governance scorecard for the agent estate (trendable). READ-ONLY.

.DESCRIPTION
    Purpose:
        Produces the "AGBGOV - Agent Governance Scorecard" - the coverage, flow, quality, and risk
        metrics that prove the operating model is working. Run it monthly; the output is designed to
        be appended over time so you can trend it. It changes nothing.

        Metric families:
          Coverage - % of agents with an owner, with a sponsor, with an approval, with a review date.
          Sharing  - count shared org-wide, count published to "Built by your org".
          Risk     - ownerless agents, agents overdue for review, sensitive agents lacking a reviewer.
          Flow     - (optional) average intake-to-decision days if a decision-record CSV is supplied.

    How to run:
        # Export "AGBGOV - Agent Register" to CSV (or use an Agent Registry export), then:
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Report.ps1 -RegisterCsv .\AGBGOV-Register-Export.csv -CsvPath .\Scorecard.csv

        # Optionally add flow metrics from the decision record:
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Report.ps1 -RegisterCsv .\reg.csv -DecisionCsv .\decisions.csv -CsvPath .\Scorecard.csv

    Expected results:
        A one-row scorecard CSV at -CsvPath (with a RunDate column) and a console table. Append the
        row to a running history to trend governance maturity over time.

.NOTES
    Copilot category - governance - READ-ONLY. Operates on CSV exports; no tenant connection needed.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RegisterCsv,

    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$DecisionCsv
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $RegisterCsv)) { throw "Register CSV not found: $RegisterCsv" }
$rows = Import-Csv -Path $RegisterCsv

function Val($row, [string[]]$names) {
    foreach ($n in $names) { if ($row.PSObject.Properties[$n]) { return "$($row.$n)".Trim() } }
    return ''
}
function Pct($num, $den) { if ($den -eq 0) { return 0 } [math]::Round(100.0 * $num / $den, 1) }

$total = @($rows).Count
$withOwner    = @($rows | Where-Object { Val $_ @('Agent Owner','AgentOwner','Owner') }).Count
$withSponsor  = @($rows | Where-Object { Val $_ @('Business Sponsor','BusinessSponsor','Sponsor') }).Count
$withApproval = @($rows | Where-Object { (Val $_ @('ARB Decision Reference','ARBDecisionReference')) -match '^AGBARB-' }).Count
$withReview   = @($rows | Where-Object { Val $_ @('Next Review Date','NextReviewDate') }).Count
$orgWide      = @($rows | Where-Object { (Val $_ @('Sharing Scope','SharingScope','AvailableTo')) -match 'Anyone in org|all' }).Count
$published    = @($rows | Where-Object { (Val $_ @('Published To Store','PublishedToStore')) -match 'Built by your org' }).Count
$ownerless    = $total - $withOwner

$sensitive    = @($rows | Where-Object { (Val $_ @('Data Classification','DataClassification')) -match 'Confidential|Restricted' })
$sensNoRev    = @($sensitive | Where-Object { -not (Val $_ @('Data & Security Reviewer','DataSecurityReviewer','Reviewer')) }).Count

$overdue = 0
foreach ($r in $rows) {
    $nr = Val $r @('Next Review Date','NextReviewDate')
    if ($nr) { $dt = $null; if ([datetime]::TryParse($nr, [ref]$dt) -and $dt -lt (Get-Date)) { $overdue++ } }
}

# Optional flow metric from the decision record.
$avgDecisionDays = ''
if ($DecisionCsv -and (Test-Path $DecisionCsv)) {
    $d = Import-Csv -Path $DecisionCsv
    $spans = foreach ($x in $d) {
        $req = Val $x @('Request Date','RequestDate','Created')
        $dec = Val $x @('Decision Date','DecisionDate')
        if ($req -and $dec) {
            $r1 = $null; $d1 = $null
            if ([datetime]::TryParse($req, [ref]$r1) -and [datetime]::TryParse($dec, [ref]$d1)) {
                ($d1 - $r1).TotalDays
            }
        }
    }
    if (@($spans).Count -gt 0) { $avgDecisionDays = [math]::Round((@($spans) | Measure-Object -Average).Average, 1) }
}

$scorecard = [pscustomobject]@{
    RunDate                     = (Get-Date).ToString('yyyy-MM-dd')
    TotalAgents                 = $total
    PctWithOwner                = Pct $withOwner $total
    PctWithSponsor              = Pct $withSponsor $total
    PctWithApproval             = Pct $withApproval $total
    PctWithReviewDate           = Pct $withReview $total
    SharedOrgWide               = $orgWide
    PublishedToStore            = $published
    OwnerlessAgents             = $ownerless
    OverdueReviews              = $overdue
    SensitiveAgentsNoReviewer   = $sensNoRev
    AvgIntakeToDecisionDays     = $avgDecisionDays
}

$scorecard | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "Scorecard written to: $CsvPath" -ForegroundColor Green
Write-Host "`n===== AGBGOV Governance Scorecard =====" -ForegroundColor Cyan
$scorecard.PSObject.Properties | ForEach-Object { Write-Host ("{0,-28} {1}" -f $_.Name, $_.Value) }
Write-Host "=======================================`n"
Write-Host "Tip: append this row to a running history CSV to trend governance maturity month over month."
