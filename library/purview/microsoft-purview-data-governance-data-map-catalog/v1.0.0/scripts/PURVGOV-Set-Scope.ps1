<#
.SYNOPSIS
    PURVGOV-Set-Scope.ps1 — Record the Purview Data Governance pilot/expansion scope (read-only helper).
.DESCRIPTION
    PURPOSE
        Captures and writes a scope manifest for the pilot (or an expansion wave): the target
        collection, the governance domain, the data-source set to register, and the intended data
        product and initial glossary terms. Read-only against the tenant — it writes only a local
        JSON manifest you register and curate against; it does not change the Purview account.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVGOV-Set-Scope.ps1 -Collection DG-Collection-Pilot `
            -Domain DG-Domain-Pilot -DataProduct DG-DataProduct-Pilot `
            -Source @('sql-fin-01.contoso.com/FinanceDB','adls-fin/finance-extracts') `
            -GlossaryTerm @('Customer ID','Invoice Amount') -OutFile .\pilot-scope.json
    EXPECTED RESULTS
        A pilot-scope.json manifest listing the collection, governance domain, sources, data product,
        and glossary terms, plus a printed summary — used as the input to PURVGOV-Register-Source.ps1
        and PURVGOV-Curate-Catalog.ps1.
.NOTES
    Purview — Data Governance. Local manifest only; no tenant change. Names are white-label placeholders.
#>
[CmdletBinding()]
param(
    [string]$Collection   = 'DG-Collection-Pilot',
    [string]$Domain       = 'DG-Domain-Pilot',
    [string]$DataProduct  = 'DG-DataProduct-Pilot',
    [string[]]$Source     = @('sql-fin-01.contoso.com/FinanceDB'),
    [string[]]$GlossaryTerm = @('Customer ID','Invoice Amount'),
    [string]$ScanRuleSet  = 'DG-ScanRuleSet-Pilot',
    [string]$OutFile      = '.\pilot-scope.json'
)

if (-not $Source -or $Source.Count -eq 0) {
    Write-Host "No sources supplied. Provide at least one -Source (host/database or container path)." -ForegroundColor Yellow
    return
}

$scope = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    collection   = $Collection
    governanceDomain = $Domain
    dataProduct  = $DataProduct
    scanRuleSet  = $ScanRuleSet
    sources      = @($Source | ForEach-Object { [ordered]@{ name = $_; owner = '<assign owner>'; steward = '<assign steward>' } })
    glossaryTerms = @($GlossaryTerm)
}

$scope | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "`n=== Purview Data Governance — pilot scope recorded ===" -ForegroundColor Cyan
Write-Host ("Collection       : {0}" -f $Collection)
Write-Host ("Governance domain: {0}" -f $Domain)
Write-Host ("Data product     : {0}" -f $DataProduct)
Write-Host ("Scan rule set    : {0}" -f $ScanRuleSet)
Write-Host  "Sources          :"
$scope.sources | ForEach-Object { Write-Host ("    - {0}" -f $_.name) }
Write-Host ("Glossary terms   : {0}" -f ($GlossaryTerm -join ', '))
Write-Host ("`nManifest written : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "Assign an owner and steward to each source before registering. Feed this manifest to PURVGOV-Register-Source.ps1." -ForegroundColor Cyan
