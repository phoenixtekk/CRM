<#
.SYNOPSIS
    DGAWS-Register-AwsSource.ps1 — Register an Amazon S3 or Amazon RDS source + configure a scoped scan (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Registers an AWS data source (-Kind AmazonS3 or AmazonRDS) into a Data Map collection and (with
        -ConfigureScan) prepares a scoped, one-time scan using a named scan rule set. SAFE BY DEFAULT:
        with no -Commit it runs in -WhatIf mode and only prints the exact registration/scan payload it
        WOULD send — it changes nothing. Pass -Commit to apply. No AWS secret is ever placed in this
        script: S3 uses a cross-account IAM role (ARN + external ID) referenced as a Purview credential
        BY NAME; RDS uses a Key Vault credential referenced BY NAME.
    HOW TO RUN
        Preview an S3 registration (default, no change):
          powershell -ExecutionPolicy Bypass -File .\DGAWS-Register-AwsSource.ps1 -PurviewAccount contoso-purview `
            -Collection DGAWS-Collection-Pilot -SourceName s3-fin-extracts -Kind AmazonS3 `
            -BucketOrEndpoint contoso-fin-extracts -Credential DGAWS-Cred-S3-Role
        Preview an RDS registration:
          ... -SourceName rds-fin-01 -Kind AmazonRDS -BucketOrEndpoint fin-rds-01.contoso.example `
            -Database FinanceDB -Credential DGAWS-Cred-RDS-KV
        Apply + configure scan:
          ... same args ... -ConfigureScan -ScanRuleSet DGAWS-ScanRuleSet-Pilot -Commit
        Requires Az.Accounts and Connect-AzAccount with Data source admin on the collection.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would register / would configure scan" plan and NO change.
        With -Commit: the source is registered (HTTP 200/201) and, with -ConfigureScan, a one-time scan
        definition is created; the script prints the resulting object names. Run Test connection in the
        portal, then trigger/monitor the scan; review with DGAWS-Report.ps1.
.NOTES
    Purview — AWS Data-Source Governance. Writes gated behind -Commit; -WhatIf is the default. Verify
    the exact source "kind" (AmazonS3 / AmazonRDS), the supported RDS engines, and the current scan API
    versions for your tenant in Microsoft's docs — the multicloud connectors are evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Collection,
    [Parameter(Mandatory = $true)][string]$SourceName,
    [Parameter(Mandatory = $true)][ValidateSet('AmazonS3','AmazonRDS')][string]$Kind,
    [Parameter(Mandatory = $true)][string]$BucketOrEndpoint,  # S3 bucket name, or RDS instance endpoint
    [string]$Database,                                        # RDS only: database name
    [Parameter(Mandatory = $true)][string]$Credential,        # NAME of the Purview credential (S3 role ARN, or RDS Key Vault secret)
    [switch]$ConfigureScan,
    [string]$ScanRuleSet = 'DGAWS-ScanRuleSet-Pilot',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

if ($Kind -eq 'AmazonRDS' -and -not $Database) {
    Write-Host "AmazonRDS requires -Database (the database name to scan)." -ForegroundColor Yellow; return
}

$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

Write-Host "`n=== Purview — register AWS source + scan ($tag) ===" -ForegroundColor Cyan

# --- Build the data-source registration payload ---------------------------------------------------
$sourceProps = [ordered]@{ collection = @{ referenceName = $Collection; type = 'CollectionReference' } }
if ($Kind -eq 'AmazonS3') {
    # S3: reach the bucket; the trust is the cross-account IAM role referenced BY the credential below.
    $sourceProps.bucketName = $BucketOrEndpoint
} else {
    # RDS: the instance endpoint + database name.
    $sourceProps.serverEndpoint = $BucketOrEndpoint
    $sourceProps.databaseName   = $Database
}
$sourceBody = @{ kind = $Kind; properties = $sourceProps } | ConvertTo-Json -Depth 6
$sourceUri  = "$Endpoint/scan/datasources/$SourceName`?api-version=2018-12-01-preview"

Write-Host ("Register source  : {0} (kind {1}) target '{2}' into collection {3}" -f $SourceName, $Kind, $BucketOrEndpoint, $Collection)
Write-Host ("Credential       : {0} (referenced BY NAME — no AWS key/DB secret in this script)" -f $Credential) -ForegroundColor DarkGray
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
    $scanName = "$SourceName-scan-pilot"
    # Credential type differs by connector: S3 assumes an IAM role (AmazonS3RoleARN); RDS uses SQL/DB auth.
    $credType = if ($Kind -eq 'AmazonS3') { 'AmazonS3RoleARN' } else { 'SqlAuth' }   # verify current credentialType names
    $scanProps = [ordered]@{
        scanRulesetName = $ScanRuleSet
        scanRulesetType = 'Custom'          # 'System' to use the built-in default rule set — verify
        collection      = @{ referenceName = $Collection; type = 'CollectionReference' }
        credential      = @{ referenceName = $Credential; credentialType = $credType }   # BY NAME only
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
            Write-Host ("  Scan configured: {0}. Run Test connection, then trigger it; keep it one-time until validated." -f $scanName) -ForegroundColor Green
        } catch {
            Write-Host ("  FAILED to configure scan: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
}

if ($whatIf) {
    Write-Host "`nNo change made. Re-run with -Commit to apply. First confirm the source 'kind', the credentialType, the API version, and the credential name for your tenant." -ForegroundColor Cyan
} else {
    Write-Host "`nRun Test connection in the portal, then trigger the scan and review with DGAWS-Report.ps1." -ForegroundColor Cyan
}
