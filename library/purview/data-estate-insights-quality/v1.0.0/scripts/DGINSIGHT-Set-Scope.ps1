<#
.SYNOPSIS
    DGINSIGHT-Set-Scope.ps1 — Record the Insights & Data Quality pilot/expansion scope (read-only).
.DESCRIPTION
    PURPOSE
        Captures the pilot scope as a local manifest you configure against: the governance domain, the
        data product, its critical data elements (CDEs), and per-CDE the quality dimension, rule intent,
        and pass threshold. Writes a JSON manifest to disk only — it changes NOTHING in Purview. Use it
        in Implementation Step 3 so rule authoring binds to exactly what the data owner agreed.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGINSIGHT-Set-Scope.ps1 `
            -Domain DGI-Domain-Pilot -DataProduct DGI-DataProduct-Pilot `
            -Cde @('DGI-CDE-CustomerID','DGI-CDE-Email') -OutFile .\DGI-scope.json
        No Purview connection and no credentials are required — this only records intent.
    EXPECTED RESULTS
        A DGI-scope.json manifest listing the domain, data product, and CDEs (with placeholders for
        dimension/rule/threshold to complete with the owner), plus a printed summary. Feed this file to
        DGINSIGHT-Configure-Quality.ps1 and DGINSIGHT-Report.ps1.
.NOTES
    Purview — Data Estate Insights & Data Quality. Read-only (writes a local manifest only). Thresholds
    are a business determination set by the data owner — this tool records them, it does not decide them.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Domain,
    [Parameter(Mandatory = $true)][string]$DataProduct,
    [Parameter(Mandatory = $true)][string[]]$Cde,
    [string]$OutFile = ".\DGI-scope.json"
)

# Standard, Microsoft-documented quality dimensions (owner picks which apply per CDE)
$dimensions = @('Completeness', 'Conformity', 'Consistency', 'Accuracy', 'Uniqueness', 'Timeliness')

$manifest = [ordered]@{
    generatedUtc         = (Get-Date).ToUniversalTime().ToString('o')
    governanceDomain     = $Domain
    dataProduct          = $DataProduct
    availableDimensions  = $dimensions
    criticalDataElements = @()
}

foreach ($c in $Cde) {
    # Emit one rule placeholder per CDE for the owner to complete (dimension / rule / threshold).
    $manifest.criticalDataElements += [ordered]@{
        cde   = $c
        rules = @(
            [ordered]@{
                ruleName  = ("DGI-DQ-Rule-Completeness-{0}" -f ($c -replace '^DGI-CDE-', ''))
                dimension = 'Completeness'      # confirm with owner; one of $dimensions above
                intent    = 'TODO: describe the rule (e.g. value is not null/blank)'
                threshold = 'TODO: owner-set pass threshold, e.g. 98'
            }
        )
    }
}

$json = $manifest | ConvertTo-Json -Depth 8
Set-Content -Path $OutFile -Value $json -Encoding UTF8

Write-Host "`n=== Pilot scope recorded (local manifest only) ===" -ForegroundColor Cyan
Write-Host ("Governance domain : {0}" -f $Domain)
Write-Host ("Data product      : {0}" -f $DataProduct)
Write-Host ("Critical elements : {0}" -f ($Cde -join ', '))
Write-Host ("Dimensions avail. : {0}" -f ($dimensions -join ', '))
Write-Host ("Manifest written  : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "`nNext: complete each rule's dimension / intent / threshold WITH THE DATA OWNER, then run DGINSIGHT-Configure-Quality.ps1 -WhatIf against this manifest." -ForegroundColor Yellow
