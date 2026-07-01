<#
.SYNOPSIS
    SWRENEW-Discovery.ps1 — seed the contract/entitlement repository and report its current posture.
.DESCRIPTION
    PURPOSE
        Reads subscription/SKU data from Microsoft Graph where the product exposes it (e.g.
        Microsoft 365 subscribed SKUs) to seed a starter renewal repository CSV, and — when given an
        existing repository CSV — reports its posture (record count, how many are missing renewal
        dates, and the next renewals due). Read-only: it never edits an existing repository.
    HOW TO RUN
        Seed from Graph:   powershell -ExecutionPolicy Bypass -File .\SWRENEW-Discovery.ps1 -CsvPath .\renewals-seed.csv
        Report a CSV:      powershell -ExecutionPolicy Bypass -File .\SWRENEW-Discovery.ps1 -ExistingCsv .\repository.csv
        Graph seeding requires the Microsoft Graph PowerShell SDK and Organization.Read.All.
    EXPECTED RESULTS
        A starter CSV of subscribed SKUs (when -CsvPath is given) and/or a posture summary of an
        existing repository (record count, blank-renewal count, next renewals).
.NOTES
    Software Asset Management — repeatable renewal/contract process. Read-only.
#>
[CmdletBinding()] param(
    [string]$CsvPath,
    [string]$ExistingCsv
)

Write-Host "=== Software Renewals — Discovery ===" -ForegroundColor Cyan

# --- Posture of an existing repository (read-only) ---
if ($ExistingCsv) {
    if (-not (Test-Path $ExistingCsv)) { Write-Host "Repository not found: $ExistingCsv" -ForegroundColor Yellow }
    else {
        $rows = @(Import-Csv $ExistingCsv)
        $blank = @($rows | Where-Object { -not $_.RenewalDate })
        Write-Host ("Repository records   : {0}" -f $rows.Count)
        Write-Host ("Missing RenewalDate  : {0}" -f $blank.Count) -ForegroundColor ($(if($blank.Count){'Yellow'}else{'Green'}))
        Write-Host "Next renewals:" -ForegroundColor Cyan
        $rows | Where-Object { $_.RenewalDate } |
            Sort-Object { [datetime]$_.RenewalDate } |
            Select-Object Vendor, Product, RenewalDate, NoticePeriodDays -First 10 | Format-Table -AutoSize
    }
}

# --- Seed from Microsoft Graph subscribed SKUs (where available) ---
if ($CsvPath) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
    $skus = @()
    try { $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value } catch { Write-Host "Graph query failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    $seed = foreach ($s in $skus) {
        [pscustomobject]@{
            ContractId         = ('GRAPH-{0}' -f $s.skuPartNumber)
            Vendor             = 'Microsoft'
            Product            = $s.skuPartNumber
            Quantity           = $s.prepaidUnits.enabled
            UnitCost           = ''
            AnnualCost         = ''
            Currency           = 'USD'
            TermStart          = ''
            RenewalDate        = ''           # Graph does not expose renewal date — fill from contract
            NoticePeriodDays   = ''
            AutoRenew          = ''
            BundleId           = ''
            Owner              = ''
            ProcurementLiaison = ''
            DocumentLink       = ''
        }
    }
    if ($seed) {
        $seed | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Host ("Seeded {0} subscribed SKUs to {1} (renewal dates blank — fill from contracts)." -f @($seed).Count, $CsvPath) -ForegroundColor Green
    } else {
        Write-Host "No subscribed SKUs returned from Graph; populate the repository from contracts." -ForegroundColor Yellow
    }
    Disconnect-MgGraph | Out-Null
}

if (-not $CsvPath -and -not $ExistingCsv) {
    Write-Host "Provide -CsvPath to seed from Graph and/or -ExistingCsv to report an existing repository." -ForegroundColor Yellow
}
