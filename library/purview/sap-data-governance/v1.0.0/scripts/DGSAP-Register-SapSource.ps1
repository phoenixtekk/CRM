<#
.SYNOPSIS
    DGSAP-Register-SapSource.ps1 — Register an SAP source and configure a scoped scan (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Registers an SAP source (ECC / S/4HANA / BW / HANA) into a Data Map collection and (with
        -ConfigureScan) prepares a scoped, one-time scan through a self-hosted integration runtime
        (SHIR) using a named scan rule set. SAFE BY DEFAULT: with no -Commit it runs in -WhatIf mode and
        only prints the exact registration/scan payload it WOULD send — it changes nothing. Pass -Commit
        to apply. No credential is ever placed in this script; SAP authentication uses an Azure Key Vault
        credential referenced by name.
    HOW TO RUN
        Preview (default, no change):
          powershell -ExecutionPolicy Bypass -File .\DGSAP-Register-SapSource.ps1 -PurviewAccount contoso-purview `
            -Collection DGSAP-Collection-Pilot -SourceName sap-ecc-01 -Kind SapEcc `
            -SapHost erp-app-01.contoso.example -SystemNumber 00 -Client 100 -Shir DGSAP-SHIR-01
        Apply:
          ... same args ... -ConfigureScan -ScanRuleSet DGSAP-ScanRuleSet-Pilot `
            -KeyVaultCredential DGSAP-Cred-SAP-KV -Commit
        Requires Az.Accounts and Connect-AzAccount with Data source admin on the collection.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would register / would configure scan" plan and NO change.
        With -Commit: the source is registered (HTTP 200/201) and, with -ConfigureScan, a scan
        definition is created through the named SHIR; the script prints the resulting object names.
        Trigger/monitor the scan run in the portal or with DGSAP-Report.ps1.
.NOTES
    Purview — SAP Data Governance. Writes gated behind -Commit; -WhatIf is the default. Verify the exact
    source "kind" (e.g. SapEcc / SapS4Hana / SapBw / SapHana), the scan API version, the SHIR
    requirement, and the SAP driver/Java prerequisites for your connector in Microsoft's current docs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$SourceName,
    [Parameter(Mandatory = $true)][string]$Kind,             # SapEcc | SapS4Hana | SapBw | SapHana — verify per connector
    [string]$SapHost,                                         # application-server host (ECC/S4/BW) or HANA host
    [string]$SystemNumber,                                    # SAP instance/system number, e.g. 00 (ECC/S4/BW)
    [string]$Client,                                          # SAP client, e.g. 100 (ECC/S4/BW)
    [string]$HanaPort,                                        # HANA SQL port, e.g. 30015 (HANA)
    [string]$Shir,                                            # NAME of the self-hosted integration runtime to scan through
    [switch]$ConfigureScan,
    [string]$ScanRuleSet = 'DGSAP-ScanRuleSet-Pilot',
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

Write-Host "`n=== Purview — register SAP source + scan ($tag) ===" -ForegroundColor Cyan

# --- Build the data-source registration payload ---------------------------------------------------
# Property names below are illustrative — verify the exact property schema for your SAP connector kind.
$sourceProps = [ordered]@{ collection = @{ referenceName = $Collection; type = 'CollectionReference' } }
if ($SapHost)      { $sourceProps.applicationServer = $SapHost }
if ($SystemNumber) { $sourceProps.systemNumber      = $SystemNumber }
if ($Client)       { $sourceProps.client            = $Client }
if ($HanaPort)     { $sourceProps.port              = $HanaPort }
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

# --- Optionally configure a scoped scan through the SHIR ------------------------------------------
if ($ConfigureScan) {
    if (-not $Shir) { Write-Host "  A -Shir (self-hosted integration runtime) is required to scan SAP. Aborting scan config." -ForegroundColor Yellow; return }
    $scanName = "$SourceName-scan-pilot"
    $scanProps = [ordered]@{
        scanRulesetName        = $ScanRuleSet
        scanRulesetType        = 'Custom'          # 'System' to use the built-in default rule set — verify
        collection             = @{ referenceName = $Collection; type = 'CollectionReference' }
        connectedVia           = @{ referenceName = $Shir; type = 'IntegrationRuntimeReference' }
    }
    if ($KeyVaultCredential) {
        # Reference a Key Vault credential BY NAME — never an inline secret.
        $scanProps.credential = @{ referenceName = $KeyVaultCredential; credentialType = 'BasicAuth' }
    } else {
        Write-Host "  NOTE: no -KeyVaultCredential given. SAP scans authenticate with a Key Vault credential referenced by name." -ForegroundColor Yellow
    }
    $scanBody = @{ kind = ("{0}Credential" -f $Kind); properties = $scanProps } | ConvertTo-Json -Depth 6
    $scanUri  = "$Endpoint/scan/datasources/$SourceName/scans/$scanName`?api-version=2018-12-01-preview"

    Write-Host ("Configure scan   : {0} via SHIR {1} using rule set {2} (scoped, one-time)" -f $scanName, $Shir, $ScanRuleSet)
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
    Write-Host "`nNo change made. Re-run with -Commit to apply. Confirm the SAP source 'kind', property schema, API version," -ForegroundColor Cyan
    Write-Host "the SHIR name, and the Key Vault credential name for your tenant first — and that the SAP driver + Java are on the SHIR." -ForegroundColor Cyan
} else {
    Write-Host "`nRun Test connection on the source, then DGSAP-Report.ps1 after the scan completes to review classification coverage." -ForegroundColor Cyan
}
