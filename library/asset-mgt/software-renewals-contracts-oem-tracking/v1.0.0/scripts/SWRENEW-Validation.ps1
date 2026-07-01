<#
.SYNOPSIS
    SWRENEW-Validation.ps1 — confirm the renewal repository has the fields the lifecycle needs.
.DESCRIPTION
    PURPOSE
        Checks every record in the Contract & Entitlement Repository CSV for the required fields
        (RenewalDate, NoticePeriodDays, AutoRenew, Quantity, AnnualCost) and valid ISO dates, and
        reports which contracts are incomplete. Read-only: it never edits the repository.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SWRENEW-Validation.ps1 -CsvPath .\repository.csv
    EXPECTED RESULTS
        "REPOSITORY COMPLETE" (exit 0) when every record has all required fields and valid dates;
        otherwise a per-contract list of what is missing (exit 1).
.NOTES
    Software Asset Management — repeatable renewal/contract process. Read-only.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$CsvPath
)

Write-Host "=== Software Renewals — Validation ===" -ForegroundColor Cyan
if (-not (Test-Path $CsvPath)) { Write-Host "Repository not found: $CsvPath" -ForegroundColor Red; exit 1 }

$required = 'RenewalDate','NoticePeriodDays','AutoRenew','Quantity','AnnualCost'
$rows = @(Import-Csv $CsvPath)
$problems = @()

foreach ($r in $rows) {
    $missing = foreach ($f in $required) { if (-not $r.$f) { $f } }
    if ($r.RenewalDate) {
        $d = [datetime]::MinValue
        if (-not [datetime]::TryParse($r.RenewalDate, [ref]$d)) { $missing += 'RenewalDate(bad-format)' }
    }
    if ($r.AutoRenew -and $r.AutoRenew -notin 'Yes','No') { $missing += 'AutoRenew(must be Yes/No)' }
    if ($missing) {
        $problems += [pscustomobject]@{
            ContractId = $r.ContractId
            Product    = $r.Product
            Missing    = ($missing -join ', ')
        }
    }
}

Write-Host ("Records checked : {0}" -f $rows.Count)
Write-Host ("Incomplete      : {0}" -f $problems.Count) -ForegroundColor ($(if($problems.Count){'Yellow'}else{'Green'}))

if ($problems.Count) {
    $problems | Format-Table -AutoSize
    Write-Host "`nResult: INCOMPLETE — fill the missing fields, then re-run." -ForegroundColor Yellow
    exit 1
}
Write-Host "`nResult: REPOSITORY COMPLETE" -ForegroundColor Green
exit 0
