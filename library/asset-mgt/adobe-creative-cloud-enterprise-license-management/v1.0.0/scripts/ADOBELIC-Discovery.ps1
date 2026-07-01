<#
.SYNOPSIS
    ADOBELIC-Discovery.ps1 — inventory Adobe Creative Cloud for Enterprise seat assignments.
.DESCRIPTION
    PURPOSE
        Reads the named users assigned to each Adobe product profile so you can build the seat
        inventory. Where the Adobe User Management API (REST) is available it reads users and
        product assignments via the API; otherwise it reads an Admin Console CSV export.
        Read-only — it never changes an assignment.
    HOW TO RUN
        API mode (where available):
          powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Discovery.ps1 -UseApi
        CSV mode (Admin Console export):
          powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Discovery.ps1 -CsvPath .\admin-console-export.csv
    EXPECTED RESULTS
        A table of users by product profile and a per-profile seat count, written to the output CSV
        (default .\Seat-Inventory-Pilot-Assess.csv) for the Seat Inventory artifact.
.NOTES
    White-label SAM tooling. Read-only.
    Adobe specifics: the exact Adobe User Management API base URL, authentication flow, and response
    shape are deferred to Adobe's official developer documentation. Fill in Invoke-AdobeApi below per
    that documentation; do not store secrets in this file — read them from the environment.
#>
[CmdletBinding()]
param(
    [switch]$UseApi,
    [string]$CsvPath,
    [string]$OutPath = ".\Seat-Inventory-Pilot-Assess.csv"
)

function Invoke-AdobeApi {
    <#
      ADOBE-SPECIFIC: implement the Adobe User Management API call here per Adobe's official
      developer documentation. Read credentials from the environment, e.g.:
        $clientId  = $env:ADOBE_CLIENT_ID
        $clientSecret = $env:ADOBE_CLIENT_SECRET
        $orgId     = $env:ADOBE_ORG_ID
      Obtain an access token per Adobe's documented flow, then page the users/product-assignment
      endpoint with Invoke-RestMethod. Return objects with: User, ProductProfile, Product.
      This stub intentionally does not invent an endpoint URL.
    #>
    param()
    if (-not $env:ADOBE_CLIENT_ID -or -not $env:ADOBE_ORG_ID) {
        throw "Adobe API credentials not found in environment (ADOBE_CLIENT_ID / ADOBE_ORG_ID). See requirement 2.6, or use -CsvPath for CSV mode."
    }
    throw "API mode requires the Adobe User Management API call to be completed per Adobe's official documentation (see Invoke-AdobeApi). Use -CsvPath for CSV mode in the meantime."
}

Write-Host "=== ADOBELIC Discovery — Adobe seat inventory ===" -ForegroundColor Cyan

$rows = @()
if ($UseApi) {
    Write-Host "Mode: Adobe User Management API" -ForegroundColor Cyan
    $rows = Invoke-AdobeApi
}
elseif ($CsvPath) {
    Write-Host "Mode: Admin Console CSV export ($CsvPath)" -ForegroundColor Cyan
    if (-not (Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }
    # ADOBE-SPECIFIC: column names depend on the Admin Console export. Adjust the property map below
    # to match your export's headers (e.g. 'Email'/'Username', 'Product Profile', 'Product').
    $raw = Import-Csv -Path $CsvPath
    foreach ($r in $raw) {
        $rows += [pscustomobject]@{
            User           = $r.User           ?? $r.Email    ?? $r.Username
            ProductProfile = $r.ProductProfile ?? $r.'Product Profile' ?? $r.Profile
            Product        = $r.Product        ?? $r.'Product'
        }
    }
}
else {
    throw "Specify -UseApi or -CsvPath. See the script header."
}

$rows = $rows | Where-Object { $_.User -and $_.ProductProfile }
Write-Host ("Assignments read : {0}" -f $rows.Count)

Write-Host "`n=== Seats per product profile ===" -ForegroundColor Cyan
$rows | Group-Object ProductProfile | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  {0,-40} {1} seats" -f $_.Name, $_.Count)
}

$rows | Sort-Object ProductProfile, User | Export-Csv -Path $OutPath -NoTypeInformation
Write-Host ("`nSeat inventory written to {0}  (Seat Inventory - Pilot Scope - Assess)" -f $OutPath) -ForegroundColor Green
