<#
.SYNOPSIS
    PURVGOV-Register-Source.ps1 — Register a Data Map source and configure a scoped scan (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Registers a data source into a Data Map collection and (with -ConfigureScan) prepares a scoped,
        one-time scan using a named scan rule set. SAFE BY DEFAULT: with no -Commit it runs in -WhatIf
        mode and only prints the exact registration/scan payload it WOULD send — it changes nothing.
        Pass -Commit to apply. No credential is ever placed in this script; source authentication uses
        the account's managed identity or an Azure Key Vault credential referenced by name.
    HOW TO RUN
        Preview (default, no change):
          powershell -ExecutionPolicy Bypass -File .\PURVGOV-Register-Source.ps1 -PurviewAccount contoso-purview `
            -Collection DG-Collection-Pilot -SourceName sql-fin-01 -Kind AzureSqlDatabase `
            -ServerEndpoint sql-fin-01.contoso.com -Database FinanceDB
        Apply:
          ... same args ... -ConfigureScan -ScanRuleSet DG-ScanRuleSet-Pilot -Commit
        Requires Az.Accounts and Connect-AzAccount with Data source admin on the collection.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would register / would configure scan" plan and NO change.
        With -Commit: the source is registered (HTTP 200/201) and, with -ConfigureScan, a scan
        definition is created; the script prints the resulting object names. Trigger/monitor the scan
        run in the portal or with PURVGOV-Report.ps1.
.NOTES
    Purview — Data Governance. Writes gated behind -Commit; -WhatIf is the default. Verify current
    Purview scan API versions and the exact source "kind" for your connector in Microsoft's docs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$SourceName,
    [Parameter(Mandatory = $true)][string]$Kind,             # e.g. AzureSqlDatabase, AdlsGen2, AmazonS3 — verify per connector
    [string]$ServerEndpoint,
    [string]$Database,
    [switch]$ConfigureScan,
    [string]$ScanRuleSet = 'DG-ScanRuleSet-Pilot',
    [string]$KeyVaultCredential,                              # NAME of a Key Vault credential already linked to the account
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

Write-Host "`n=== Purview — register source + scan ($tag) ===" -ForegroundColor Cyan

# --- Build the data-source registration payload ---------------------------------------------------
$sourceProps = [ordered]@{ collection = @{ referenceName = $Collection; type = 'CollectionReference' } }
if ($ServerEndpoint) { $sourceProps.serverEndpoint = $ServerEndpoint }
if ($Database)       { $sourceProps.databaseName   = $Database }
$sourceBody = @{ kind = $Kind; properties = $sourceProps } | ConvertTo-Json -Depth 6
$sourceUri  = "$Endpoint/scan/datasources/$SourceName`?api-version=2018-12-01-preview"

Write-Host ("Register source  : {0} (kind {1}) into collection {2}" -f $SourceName, $Kind, $Collection)
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
    if ($KeyVaultCredential) {
        # Reference a Key Vault credential BY NAME — never an inline secret.
        $scanProps.credential = @{ referenceName = $KeyVaultCredential; credentialType = 'SqlAuth' }
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
    Write-Host "`nNo change made. Re-run with -Commit to apply. Confirm the source 'kind', API version, and Key Vault credential name for your tenant first." -ForegroundColor Cyan
} else {
    Write-Host "`nRun PURVGOV-Report.ps1 after the scan completes to review classification coverage." -ForegroundColor Cyan
}
