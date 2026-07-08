<#
.SYNOPSIS
    DGDBX-Register-DatabricksSource.ps1 — Register an Azure Databricks (Unity Catalog / lakehouse) source + configure a scoped scan (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Registers an Azure Databricks data source (Unity Catalog, or Hive metastore) into a Data Map
        collection and (with -ConfigureScan) prepares a scoped, one-time scan using a named scan rule set.
        SAFE BY DEFAULT: with no -Commit it runs in -WhatIf mode and only prints the exact
        registration/scan payload it WOULD send — it changes nothing. Pass -Commit to apply. No Databricks
        secret is ever placed in this script: the scan credential (a service principal or PAT) is stored in
        Azure Key Vault and referenced as a Purview credential BY NAME.
    HOW TO RUN
        Preview a Unity Catalog registration (default, no change):
          powershell -ExecutionPolicy Bypass -File .\DGDBX-Register-DatabricksSource.ps1 -PurviewAccount contoso-purview `
            -Collection DGDBX-Collection-Pilot -SourceName dbx-lakehouse-01 `
            -WorkspaceUrl https://adb-1234567890123456.7.azuredatabricks.net -Metastore contoso-uc-metastore `
            -Credential DGDBX-Cred-Databricks-KV
        Apply + configure a scoped scan of one catalog/schema:
          ... same args ... -ConfigureScan -Catalog contoso_prod -Schema finance -ScanRuleSet DGDBX-ScanRuleSet-Pilot -Commit
        For a legacy workspace use -Kind AzureDatabricksHiveMetastore (verify the exact connector name).
        Requires Az.Accounts and Connect-AzAccount with Data source admin on the collection.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would register / would configure scan" plan and NO change.
        With -Commit: the source is registered (HTTP 200/201) and, with -ConfigureScan, a one-time scan
        definition is created scoped to the given catalog/schema; the script prints the resulting object
        names. Run Test connection in the portal, then trigger/monitor the scan; review with DGDBX-Report.ps1.
.NOTES
    Purview — Databricks Data Governance. Writes gated behind -Commit; -WhatIf is the default. Verify the
    exact source "kind" (Azure Databricks Unity Catalog vs. Hive metastore), the credentialType the
    connector accepts, the scan-scope shape, and the current scan API versions for your tenant in
    Microsoft's docs — the Data Governance connectors are evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$SourceName,
    [Parameter(Mandatory = $true)][string]$WorkspaceUrl,                        # e.g. https://adb-xxxx.NN.azuredatabricks.net
    [ValidateSet('AzureDatabricksUnityCatalog','AzureDatabricksHiveMetastore')]
    [string]$Kind = 'AzureDatabricksUnityCatalog',                             # verify the exact connector kind for your tenant
    [string]$Metastore,                                                        # Unity Catalog metastore (name/id) — verify
    [Parameter(Mandatory = $true)][string]$Credential,                         # NAME of the Purview credential (Key Vault-backed) — no secret here
    [switch]$ConfigureScan,
    [string]$Catalog,                                                          # bounded scan scope: one catalog ...
    [string]$Schema,                                                           # ... and one schema (pilot-first)
    [string]$ScanRuleSet = 'DGDBX-ScanRuleSet-Pilot',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

if ($Kind -eq 'AzureDatabricksUnityCatalog' -and -not $Metastore) {
    Write-Host "Unity Catalog registration expects -Metastore (the Unity Catalog metastore). Verify the required value for your connector." -ForegroundColor Yellow
}

$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

Write-Host "`n=== Purview — register Azure Databricks source + scan ($tag) ===" -ForegroundColor Cyan

# --- Build the data-source registration payload ---------------------------------------------------
# NOTE: exact property names for the Databricks connector are tenant-/version-dependent — verify against
# Microsoft's current docs. The workspace URL and (for Unity Catalog) the metastore identify the source.
$sourceProps = [ordered]@{ collection = @{ referenceName = $Collection; type = 'CollectionReference' } }
$sourceProps.workspaceUrl = $WorkspaceUrl
if ($Kind -eq 'AzureDatabricksUnityCatalog' -and $Metastore) { $sourceProps.metastore = $Metastore }
$sourceBody = @{ kind = $Kind; properties = $sourceProps } | ConvertTo-Json -Depth 6
$sourceUri  = "$Endpoint/scan/datasources/$SourceName`?api-version=2018-12-01-preview"

Write-Host ("Register source  : {0} (kind {1}) workspace '{2}' into collection {3}" -f $SourceName, $Kind, $WorkspaceUrl, $Collection)
if ($Metastore) { Write-Host ("Metastore        : {0}" -f $Metastore) }
Write-Host ("Credential       : {0} (referenced BY NAME — no Databricks token/secret in this script)" -f $Credential) -ForegroundColor DarkGray
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

# --- Optionally configure a scoped, one-time scan -------------------------------------------------
if ($ConfigureScan) {
    if (-not $Catalog) { Write-Host "  -ConfigureScan without -Catalog would scan the whole metastore. Provide -Catalog (and -Schema) to stay bounded (pilot-first)." -ForegroundColor Yellow }
    $scanName = "$SourceName-scan-pilot"
    # The Databricks connector credential is Key Vault-backed; verify the exact credentialType name for your tenant.
    $scanProps = [ordered]@{
        scanRulesetName = $ScanRuleSet
        scanRulesetType = 'Custom'          # 'System' to use the built-in default rule set — verify
        collection      = @{ referenceName = $Collection; type = 'CollectionReference' }
        credential      = @{ referenceName = $Credential; credentialType = 'DatabricksAccessToken' }   # verify current credentialType; BY NAME only
    }
    # Bound the scan to one catalog/schema (pilot-first). The exact scope property is connector-specific — verify.
    if ($Catalog) {
        $scope = @($Catalog); if ($Schema) { $scope = @("$Catalog/$Schema") }
        $scanProps.scanScope = $scope
    }
    $scanBody = @{ kind = ("{0}Credential" -f $Kind); properties = $scanProps } | ConvertTo-Json -Depth 6
    $scanUri  = "$Endpoint/scan/datasources/$SourceName/scans/$scanName`?api-version=2018-12-01-preview"

    Write-Host ("Configure scan   : {0} using rule set {1} (scoped, one-time){2}" -f $scanName, $ScanRuleSet, ($(if($Catalog){" — scope $Catalog$(if($Schema){"/$Schema"})"}else{''})))
    if ($whatIf) {
        Write-Host "  $tag PUT $scanUri" -ForegroundColor Yellow
        Write-Host "  $tag body:" -ForegroundColor Yellow
        Write-Host $scanBody
        Write-Host "  $tag (would leave the scan on a one-time trigger — enable a schedule only after the scope validates, via DGDBX-Set-Scope.ps1 -Commit)" -ForegroundColor Yellow
    } else {
        try {
            Invoke-RestMethod -Method PUT -Uri $scanUri -Headers $headers -Body $scanBody -ErrorAction Stop | Out-Null
            Write-Host ("  Scan configured: {0}. Run Test connection, then trigger it; keep it one-time until validated." -f $scanName) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED to configure scan: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

if ($whatIf) {
    Write-Host "`nNo change made. Re-run with -Commit to apply. First confirm the source 'kind', the credentialType, the scan-scope shape, the API version, and the credential name for your tenant." -ForegroundColor Cyan
} else {
    Write-Host "`nRun Test connection in the portal, then trigger the scan and review with DGDBX-Report.ps1." -ForegroundColor Cyan
}
