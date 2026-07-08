<#
.SYNOPSIS
    DGGCP-Set-Scope.ps1 — Record the Google Cloud (BigQuery) pilot/expansion scope (read-only helper).
.DESCRIPTION
    PURPOSE
        Captures and writes a scope manifest for the pilot (or an expansion wave): the target
        collection, the BigQuery project/dataset source set to register (each with an owner and
        steward), the scan rule set to apply, and the credential name to reference. Read-only against
        the tenant — it writes only a local JSON manifest you register and scan against; it does not
        change the Purview account and stores no credential.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGGCP-Set-Scope.ps1 -Collection DGGCP-Collection-Pilot `
            -ProjectId my-gcp-project -Source @('my-gcp-project/analytics_ds','my-gcp-project/finance_ds') `
            -Credential DGGCP-Cred-BQ-KV -OutFile .\pilot-scope.json
    EXPECTED RESULTS
        A pilot-scope.json manifest listing the collection, GCP project, BigQuery dataset sources,
        scan rule set, and credential name, plus a printed summary — used as the input to
        DGGCP-Register-GcpSource.ps1.
.NOTES
    Purview — Data Governance (Google BigQuery). Local manifest only; no tenant change; no secrets.
    Names are white-label placeholders (contoso / example project IDs).
#>
[CmdletBinding()]
param(
    [string]$Collection   = 'DGGCP-Collection-Pilot',
    [Parameter(Mandatory = $true)][string]$ProjectId,        # GCP project ID holding the BigQuery datasets
    [string[]]$Source     = @('my-gcp-project/analytics_ds'),# project/dataset entries in scope
    [string]$ScanRuleSet  = 'DGGCP-ScanRuleSet-Pilot',
    [string]$Credential   = 'DGGCP-Cred-BQ-KV',               # NAME of the Key Vault credential (never a secret)
    [string]$OutFile      = '.\pilot-scope.json'
)

if (-not $Source -or $Source.Count -eq 0) {
    Write-Host "No sources supplied. Provide at least one -Source (project/dataset)." -ForegroundColor Yellow
    return
}

$scope = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    collection   = $Collection
    projectId    = $ProjectId
    scanRuleSet  = $ScanRuleSet
    credential   = $Credential          # name only — the private key lives in Azure Key Vault
    sources      = @($Source | ForEach-Object { [ordered]@{ name = $_; owner = '<assign owner>'; steward = '<assign steward>' } })
}

$scope | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "`n=== Purview — Google BigQuery pilot scope recorded ===" -ForegroundColor Cyan
Write-Host ("Collection       : {0}" -f $Collection)
Write-Host ("GCP project      : {0}" -f $ProjectId)
Write-Host ("Scan rule set    : {0}" -f $ScanRuleSet)
Write-Host ("Credential (name): {0}" -f $Credential)
Write-Host  "Sources          :"
$scope.sources | ForEach-Object { Write-Host ("    - {0}" -f $_.name) }
Write-Host ("`nManifest written : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "Assign an owner and steward to each source before registering. Feed this manifest to DGGCP-Register-GcpSource.ps1." -ForegroundColor Cyan
