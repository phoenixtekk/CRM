<#
.SYNOPSIS
    DGGLOSS-Report.ps1 — Stewardship report: term status mix, unowned terms, and stale Published terms (read-only).
.DESCRIPTION
    PURPOSE
        Produces the recurring stewardship report that evidences the upkeep cadence: term counts by
        status (Draft/Approved/Published/Expired), UNOWNED Published terms (a defect), and STALE
        Published terms whose last update is older than the re-certification interval. Read-only — it
        makes NO change; run it on a monthly cadence and keep the output as program evidence. Optionally
        exports a CSV.
    HOW TO RUN
        .\DGGLOSS-Report.ps1 -PurviewAccount contoso-purview -RecertifyMonths 3
        Export a CSV of the term inventory:
          .\DGGLOSS-Report.ps1 -PurviewAccount contoso-purview -RecertifyMonths 3 -CsvOut .\DGGLOSS-report.csv
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the domain. A data-plane
        token is acquired from your sign-in; no secret is stored in the script.
    EXPECTED RESULTS
        A status breakdown, an "unowned Published terms" count (target zero), a "stale Published terms"
        list (past the re-certification interval), and per-glossary coverage — the evidence the program
        is being maintained. Non-zero unowned/stale counts are the steward's work list.
.NOTES
    Purview — Data Governance. Read-only reporting. Verify current Atlas glossary API versions for your
    tenant. Retiring a superseded term to Expired and re-certifying Published terms are stewardship
    actions; regulatory/records determinations remain with the relevant governance functions.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [int]$RecertifyMonths = 3,
    [string]$CsvOut,
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token" }
$api = 'api-version=2022-03-01-preview'   # Atlas glossary — verify current version for your tenant
$staleBefore = (Get-Date).AddMonths(-1 * $RecertifyMonths)

Write-Host "`n=== Purview — glossary stewardship report ===" -ForegroundColor Cyan
Write-Host ("Re-certify interval : every {0} month(s) (stale if not updated since {1:yyyy-MM-dd})" -f $RecertifyMonths, $staleBefore)

$rows = @()
try {
    $glossaries = @(Invoke-RestMethod -Method GET -Uri "$Endpoint/catalog/api/atlas/v2/glossary?$api" -Headers $headers -ErrorAction Stop)
    foreach ($g in $glossaries) {
        $terms = @(Invoke-RestMethod -Method GET -Uri "$Endpoint/catalog/api/atlas/v2/glossary/$($g.guid)/terms?$api" -Headers $headers -ErrorAction Stop)
        foreach ($t in $terms) {
            $updateMs = [double]("$($t.updateTime)" -replace '[^\d]','')
            $updated = $null
            if ($updateMs -gt 0) { $updated = [DateTimeOffset]::FromUnixTimeMilliseconds([long]$updateMs).UtcDateTime }
            $rows += [pscustomobject]@{
                Glossary  = $g.name
                Term      = $t.name
                Status    = "$($t.status)"
                Owner     = "$($t.additionalAttributes.owner)"
                Steward   = "$($t.additionalAttributes.steward)"
                Updated   = $updated
            }
        }
    }
} catch {
    Write-Host ("Could not read glossary/terms: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Verify your role and the current Atlas glossary API version for your tenant." -ForegroundColor DarkGray
    return
}

if ($rows.Count -eq 0) { Write-Host "No terms found." -ForegroundColor Yellow; return }

# Status breakdown
Write-Host "`nStatus breakdown:" -ForegroundColor Cyan
$rows | Group-Object Status | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-12}: {1}" -f $_.Name, $_.Count)
}

# Unowned Published terms (defect)
$unowned = @($rows | Where-Object { $_.Status -eq 'Published' -and [string]::IsNullOrWhiteSpace($_.Owner) })
Write-Host ("`nUnowned Published terms : {0}" -f $unowned.Count) -ForegroundColor ($(if($unowned.Count -eq 0){'Green'}else{'Red'}))
foreach ($u in $unowned) { Write-Host ("  - {0} ({1})" -f $u.Term, $u.Glossary) -ForegroundColor Yellow }

# Stale Published terms
$stale = @($rows | Where-Object { $_.Status -eq 'Published' -and $_.Updated -and $_.Updated -lt $staleBefore })
Write-Host ("`nStale Published terms   : {0} (past re-certification interval)" -f $stale.Count) -ForegroundColor ($(if($stale.Count -eq 0){'Green'}else{'Yellow'}))
foreach ($s in $stale) { Write-Host ("  - {0} (last updated {1:yyyy-MM-dd})" -f $s.Term, $s.Updated) -ForegroundColor Yellow }

# Coverage per glossary
Write-Host "`nCoverage per glossary:" -ForegroundColor Cyan
$rows | Group-Object Glossary | ForEach-Object {
    $pub = @($_.Group | Where-Object { $_.Status -eq 'Published' }).Count
    Write-Host ("  {0,-24}: {1} term(s), {2} Published" -f $_.Name, $_.Count, $pub)
}

if ($CsvOut) {
    $rows | Export-Csv -Path $CsvOut -NoTypeInformation -Encoding utf8
    Write-Host ("`nCSV written        : {0}" -f (Resolve-Path $CsvOut)) -ForegroundColor Cyan
}

Write-Host "`nSteward work list: assign owners to any unowned Published term, then re-certify or Expire stale terms." -ForegroundColor Cyan
Write-Host "Note: retiring/re-certifying is stewardship; records/legal determinations remain with the governance functions." -ForegroundColor DarkGray
