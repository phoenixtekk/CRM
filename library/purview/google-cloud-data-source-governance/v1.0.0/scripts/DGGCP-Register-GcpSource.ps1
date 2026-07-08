<#
.SYNOPSIS
    DGGCP-Register-GcpSource.ps1 — Register a Google BigQuery source and configure a scoped scan (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Registers a Google BigQuery data source into a Data Map collection and (with -ConfigureScan)
        prepares a scoped, one-time scan using a named scan rule set. SAFE BY DEFAULT: with no -Commit
        it runs in -WhatIf mode and only prints the exact registration/scan payload it WOULD send — it
        changes nothing. Pass -Commit to apply. No credential is ever placed in this script; BigQuery
        authentication uses a Google Cloud service-account key stored in Azure Key Vault and referenced
        by name, and the scan runs on a self-hosted integration runtime (SHIR).
    HOW TO RUN
        Preview (default, no change):
          powershell -ExecutionPolicy Bypass -File .\DGGCP-Register-GcpSource.ps1 -PurviewAccount contoso-purview `
            -Collection DGGCP-Collection-Pilot -SourceName bq-analytics -ProjectId my-gcp-project
        Apply (register + configure scan):
          ... same args ... -ConfigureScan -ScanRuleSet DGGCP-ScanRuleSet-Pilot `
            -KeyVaultCredential DGGCP-Cred-BQ-KV -IntegrationRuntime my-shir -Commit
        Requires Az.Accounts and Connect-AzAccount with Data source admin on the collection.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would register / would configure scan" plan and NO change.
        With -Commit: the source is registered (HTTP 200/201) and, with -ConfigureScan, a scan
        definition is created; the script prints the resulting object names. Trigger/monitor the scan
        run in the portal or with DGGCP-Report.ps1.
.NOTES
    Purview — Data Governance (Google BigQuery). Writes gated behind -Commit; -WhatIf is the default.
    Verify the exact BigQuery source "kind", the required credential type, and current scan API
    versions for your connector in Microsoft's docs — the multicloud connectors are evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$SourceName,
    [Parameter(Mandatory = $true)][string]$ProjectId,        # GCP project ID holding the BigQuery datasets
    [string]$Kind = 'GoogleBigQuery',                        # verify the exact connector kind for your tenant
    [switch]$ConfigureScan,
    [string]$ScanRuleSet = 'DGGCP-ScanRuleSet-Pilot',
    [string]$KeyVaultCredential,                             # NAME of a Key Vault credential already linked to the account
    [string]$IntegrationRuntime,                             # NAME of the self-hosted IR (SHIR) that runs the scan
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

Write-Host "`n=== Purview — register Google BigQuery source + scan ($tag) ===" -ForegroundColor Cyan

# --- Build the data-source registration payload ---------------------------------------------------
$sourceProps = [ordered]@{
    collection = @{ referenceName = $Collection; type = 'CollectionReference' }
    projectId  = $ProjectId
}
$sourceBody = @{ kind = $Kind; properties = $sourceProps } | ConvertTo-Json -Depth 6
$sourceUri  = "$Endpoint/scan/datasources/$SourceName`?api-version=2018-12-01-preview"

Write-Host ("Register source  : {0} (kind {1}) project {2} into collection {3}" -f $SourceName, $Kind, $ProjectId, $Collection)
if ($whatIf) {
    Write-Host "  $tag PUT $sourceUri" -ForegroundColor Yellow
    Write-Host "  $tag body:" -ForegroundColor Yellow
    Write-Host $sourceBody
} else {
    try {
        Invoke-RestMethod -Method PUT -Uri $sourceUri -Headers $headers -Body $sourceBody -ErrorAction Stop | Out-Null
        Write-Host ("  Registered: {0}" -f $SourceName) -ForegroundColor Green
    } catch {
        Write-Host ("  FAILED to register: {0}" -f $_.Exception.Message) -ForegroundColor Red
        return
    }
}

# --- Optionally configure a scoped scan -----------------------------------------------------------
if ($ConfigureScan) {
    $scanName = "$SourceName-scan-pilot"
    $scanProps = [ordered]@{
        scanRulesetName = $ScanRuleSet
        scanRulesetType = 'Custom'          # 'System' to use the built-in default rule set — verify
        collection      = @{ referenceName = $Collection; type = 'CollectionReference' }
    }
    # BigQuery scans run on a self-hosted integration runtime — reference it by NAME.
    if ($IntegrationRuntime) {
        $scanProps.connectedVia = @{ referenceName = $IntegrationRuntime; type = 'IntegrationRuntimeReference' }
    } else {
        Write-Host "  NOTE: no -IntegrationRuntime supplied. BigQuery scans require a Running self-hosted IR (SHIR)." -ForegroundColor Yellow
    }
    # Reference the Key Vault service-account credential BY NAME — never an inline secret / key.
    if ($KeyVaultCredential) {
        $scanProps.credential = @{ referenceName = $KeyVaultCredential; credentialType = 'ServicePrincipal' }
        Write-Host "  NOTE: verify the exact credentialType for the Google service-account credential in your tenant." -ForegroundColor DarkGray
    }
    $scanBody = @{ kind = ("{0}Credential" -f $Kind); properties = $scanProps } | ConvertTo-Json -Depth 6
    $scanUri  = "$Endpoint/scan/datasources/$SourceName/scans/$scanName`?api-version=2018-12-01-preview"

    Write-Host ("Configure scan   : {0} using rule set {1} (scoped, one-time)" -f $scanName, $ScanRuleSet)
    if ($whatIf) {
        Write-Host "  $tag PUT $scanUri" -ForegroundColor Yellow
        Write-Host "  $tag body:" -ForegroundColor Yellow
        Write-Host $scanBody
        Write-Host "  $tag (would leave the scan on a one-time trigger — enable a schedule only after the scope validates)" -ForegroundColor Yellow
    } else {
        try {
            Invoke-RestMethod -Method PUT -Uri $scanUri -Headers $headers -Body $scanBody -ErrorAction Stop | Out-Null
            Write-Host ("  Scan configured: {0}. Trigger it in the portal or via the scan run API; keep it one-time until validated." -f $scanName) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED to configure scan: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

if ($whatIf) {
    Write-Host "`nNo change made. Re-run with -Commit to apply. Confirm the BigQuery source 'kind', the credential type/name, the SHIR name, and the API version for your tenant first." -ForegroundColor Cyan
} else {
    Write-Host "`nRun Test connection on the source, then DGGCP-Report.ps1 after the scan completes to review classification coverage." -ForegroundColor Cyan
}
