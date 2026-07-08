<#
.SYNOPSIS
    PURVGOV-Curate-Catalog.ps1 — Unified Catalog curation: glossary term, classification, or data product (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Curates the Unified Catalog for the pilot: create a business-glossary term (-Glossary),
        associate a classification with an asset (-Classify), or create a data product with an owner
        (-DataProduct). SAFE BY DEFAULT: with no -Commit it runs in -WhatIf mode and prints the exact
        payload it WOULD send, changing nothing. Pass -Commit to write. No secrets in code.
    HOW TO RUN
        Glossary term (preview by default):
          .\PURVGOV-Curate-Catalog.ps1 -PurviewAccount contoso-purview -Glossary -TermName "Customer ID" `
            -TermDefinition "The unique enterprise identifier for a customer."
        Data product (apply):
          .\PURVGOV-Curate-Catalog.ps1 -PurviewAccount contoso-purview -DataProduct `
            -DataProductName DG-DataProduct-Pilot -Domain DG-Domain-Pilot -Owner "owner@contoso.com" -Commit
        Requires Az.Accounts + Connect-AzAccount with Data curator / governance domain owner as appropriate.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would create/associate ..." plan and NO change. With -Commit the
        catalog object is created/updated and the script prints its name/GUID. Verify the current
        Unified Catalog / Atlas glossary API versions for your tenant — the experience is evolving.
.NOTES
    Purview — Data Governance. Writes gated behind -Commit; -WhatIf default. Determinations (what a
    term MEANS, who OWNS an asset) are the data owners' — this tool records their decisions, not makes them.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [switch]$Glossary,
    [switch]$Classify,
    [switch]$DataProduct,
    # glossary
    [string]$TermName,
    [string]$TermDefinition,
    [string]$GlossaryName = 'DG-Glossary-Pilot',
    # classify
    [string]$AssetGuid,
    [string]$Classification,           # e.g. MICROSOFT.GOVERNMENT.US.SOCIAL_SECURITY_NUMBER or a custom name
    # data product
    [string]$DataProductName = 'DG-DataProduct-Pilot',
    [string]$Domain = 'DG-Domain-Pilot',
    [string]$Owner,
    [string]$UsePurpose = 'Pilot data product for governed discovery.',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

if (-not ($Glossary -or $Classify -or $DataProduct)) {
    Write-Host "Choose one action: -Glossary, -Classify, or -DataProduct." -ForegroundColor Yellow; return
}
$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Send-Curation([string]$Method, [string]$Uri, [string]$Body) {
    if ($whatIf) {
        Write-Host "  $tag $Method $Uri" -ForegroundColor Yellow
        Write-Host "  $tag body:" -ForegroundColor Yellow; Write-Host $Body
    } else {
        try {
            $r = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body $Body -ErrorAction Stop
            Write-Host "  Applied." -ForegroundColor Green
            if ($r.guid) { Write-Host ("  guid: {0}" -f $r.guid) }
        } catch { Write-Host ("  FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    }
}

Write-Host "`n=== Purview — Unified Catalog curation ($tag) ===" -ForegroundColor Cyan

if ($Glossary) {
    if (-not $TermName) { Write-Host "-Glossary requires -TermName." -ForegroundColor Yellow; return }
    Write-Host ("Glossary term    : '{0}' in {1}" -f $TermName, $GlossaryName)
    $body = @{ name = $TermName; shortDescription = $TermDefinition; status = 'Draft' } | ConvertTo-Json -Depth 5
    # Atlas glossary term endpoint — verify current API version for your tenant.
    Send-Curation 'POST' "$Endpoint/catalog/api/atlas/v2/glossary/term?api-version=2022-03-01-preview" $body
}

if ($Classify) {
    if (-not $AssetGuid -or -not $Classification) { Write-Host "-Classify requires -AssetGuid and -Classification." -ForegroundColor Yellow; return }
    Write-Host ("Classify asset   : {0} += {1}" -f $AssetGuid, $Classification)
    $body = @{ classifications = @(@{ typeName = $Classification }) } | ConvertTo-Json -Depth 5
    Send-Curation 'POST' "$Endpoint/catalog/api/atlas/v2/entity/guid/$AssetGuid/classifications?api-version=2022-03-01-preview" $body
}

if ($DataProduct) {
    if (-not $Owner) { Write-Host "-DataProduct requires -Owner." -ForegroundColor Yellow; return }
    Write-Host ("Data product     : '{0}' in domain {1}, owner {2}" -f $DataProductName, $Domain, $Owner)
    $body = @{ name = $DataProductName; domain = $Domain; owner = $Owner; description = $UsePurpose; status = 'Draft' } | ConvertTo-Json -Depth 5
    # Unified Catalog data-product endpoint — verify the current data-governance API for your tenant.
    Send-Curation 'POST' "$Endpoint/datagovernance/catalog/dataProducts?api-version=2023-09-01-preview" $body
}

if ($whatIf) {
    Write-Host "`nNo change made. Re-run with -Commit to write. Confirm the current Unified Catalog / Atlas API versions for your tenant first." -ForegroundColor Cyan
}
