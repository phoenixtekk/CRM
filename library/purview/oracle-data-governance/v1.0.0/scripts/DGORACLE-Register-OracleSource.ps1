<#
.SYNOPSIS
    DGORACLE-Register-OracleSource.ps1 — Register an Oracle source + configure a scoped scan (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Registers an Oracle data source into a Data Map collection and (with -ConfigureScan) prepares a
        scoped, one-time scan using a named scan rule set and self-hosted integration runtime. SAFE BY
        DEFAULT: with no -Commit it runs in -WhatIf mode and only prints the exact registration/scan
        payload it WOULD send — it changes nothing. Pass -Commit to apply. No Oracle secret is ever
        placed in this script: authentication uses a Purview credential (Basic auth) that references an
        Azure Key Vault secret BY NAME.
    HOW TO RUN
        Preview an Oracle registration (default, no change):
          powershell -ExecutionPolicy Bypass -File .\DGORACLE-Register-OracleSource.ps1 -PurviewAccount contoso-purview `
            -Collection DGORACLE-Collection-Pilot -SourceName oracle-oradb01 `
            -OracleHost oradb01.contoso.example -Service ORCLPDB1 -Port 1521 `
            -Credential DGORACLE-Cred-Oracle-KV -IntegrationRuntime DGORACLE-SHIR
        Apply + configure a scoped scan:
          ... same args ... -ConfigureScan -ScanRuleSet DGORACLE-ScanRuleSet-Pilot -Schema HR,FINANCE -Commit
        Requires Az.Accounts and Connect-AzAccount with Data source admin on the collection.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would register / would configure scan" plan and NO change.
        With -Commit: the source is registered (HTTP 200/201) and, with -ConfigureScan, a one-time scan
        definition is created; the script prints the resulting object names. Run Test connection in the
        portal, then trigger/monitor the scan; review with DGORACLE-Report.ps1.
.NOTES
    Purview — Oracle Data Governance. Writes gated behind -Commit; -WhatIf is the default. Verify the
    exact source "kind" (Oracle), the connectionProperty/scan field names, the credentialType, and the
    current scan API versions for your tenant in Microsoft's docs — the connector is evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$SourceName,
    [Parameter(Mandatory = $true)][string]$OracleHost,        # Oracle host, e.g. oradb01.contoso.example
    [Parameter(Mandatory = $true)][string]$Service,           # service name or SID, e.g. ORCLPDB1
    [int]$Port = 1521,
    [Parameter(Mandatory = $true)][string]$Credential,        # NAME of the Purview credential (Key Vault secret, Basic auth)
    [string]$IntegrationRuntime = 'DGORACLE-SHIR',
    [switch]$ConfigureScan,
    [string]$ScanRuleSet = 'DGORACLE-ScanRuleSet-Pilot',
    [string[]]$Schema = @(),                                  # in-scope schemas to bound the scan
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

Write-Host "`n=== Purview — register Oracle source + scan ($tag) ===" -ForegroundColor Cyan

# --- Build the data-source registration payload ---------------------------------------------------
# Field names below are illustrative — verify the current Oracle source schema for your tenant's API.
$sourceProps = [ordered]@{
    collection = @{ referenceName = $Collection; type = 'CollectionReference' }
    host       = $OracleHost
    port       = $Port
    service    = $Service          # service name or SID (verify the exact property name)
}
$sourceBody = @{ kind = 'Oracle'; properties = $sourceProps } | ConvertTo-Json -Depth 6
$sourceUri  = "$Endpoint/scan/datasources/$SourceName`?api-version=2018-12-01-preview"

Write-Host ("Register source  : {0} (kind Oracle) {1}:{2}/{3} into collection {4}" -f $SourceName, $OracleHost, $Port, $Service, $Collection)
Write-Host ("Credential       : {0} (Basic auth, references a Key Vault secret BY NAME — no Oracle password in this script)" -f $Credential) -ForegroundColor DarkGray
Write-Host ("Integration RT   : {0} (self-hosted; needs line of sight to the listener + the Oracle JDBC driver)" -f $IntegrationRuntime) -ForegroundColor DarkGray
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
    if (-not $Schema -or $Schema.Count -eq 0) {
        Write-Host "  -ConfigureScan needs -Schema to bound the scan (do not scan the whole instance). Skipping scan config." -ForegroundColor Yellow
    } else {
        $scanName = "$SourceName-scan-pilot"
        $scanProps = [ordered]@{
            scanRulesetName          = $ScanRuleSet
            scanRulesetType          = 'Custom'      # 'System' to use the built-in default rule set — verify
            collection               = @{ referenceName = $Collection; type = 'CollectionReference' }
            credential               = @{ referenceName = $Credential; credentialType = 'BasicAuth' }  # BY NAME only; verify type
            connectedVia             = @{ referenceName = $IntegrationRuntime; type = 'IntegrationRuntimeReference' }
            schemaList               = @($Schema)    # bound the scan to these schemas (verify the property name)
        }
        $scanBody = @{ kind = 'OracleCredential'; properties = $scanProps } | ConvertTo-Json -Depth 6
        $scanUri  = "$Endpoint/scan/datasources/$SourceName/scans/$scanName`?api-version=2018-12-01-preview"

        Write-Host ("Configure scan   : {0} using rule set {1}, schemas {2} (scoped, one-time)" -f $scanName, $ScanRuleSet, ($Schema -join ','))
        if ($whatIf) {
            Write-Host "  $tag PUT $scanUri" -ForegroundColor Yellow
            Write-Host "  $tag body:" -ForegroundColor Yellow
            Write-Host $scanBody
            Write-Host "  $tag (would leave the scan on a one-time trigger — enable a schedule only after the scope validates)" -ForegroundColor Yellow
        } else {
            try {
                Invoke-RestMethod -Method PUT -Uri $scanUri -Headers $headers -Body $scanBody -ErrorAction Stop | Out-Null
                Write-Host ("  Scan configured: {0}. Run Test connection, then trigger it; keep it one-time until validated." -f $scanName) -ForegroundColor Green
            } catch {
                Write-Host ("  FAILED to configure scan: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
        }
    }
}

if ($whatIf) {
    Write-Host "`nNo change made. Re-run with -Commit to apply. First confirm the source 'kind', the property/credentialType names, the API version, and the credential name for your tenant." -ForegroundColor Cyan
} else {
    Write-Host "`nRun Test connection in the portal (SHIR + JDBC driver + Key Vault credential), then trigger the scan and review with DGORACLE-Report.ps1." -ForegroundColor Cyan
}
