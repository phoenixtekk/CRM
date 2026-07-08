<#
.SYNOPSIS
    DGSNOW-Register-Source.ps1 — Register the Snowflake source and create/run/delete its scan in the Purview
    Data Map, referencing a Key Vault-backed credential BY NAME (-WhatIf by default; no secret in code).
.DESCRIPTION
    PURPOSE
        Automates Snowflake onboarding SAFELY via the Purview Data Map REST API. -Action RegisterSource
        registers 'Snowflake - Source' under the collection. -Action CreateScan creates 'Snowflake - Scan'
        referencing the Key Vault-backed credential BY NAME and scoped to the pilot database. -Action RunScan
        triggers a run; -Action DeleteScan removes a scan. DEFAULTS TO -WhatIf: prints exactly what it would
        do (the REST call + reverse action) and changes nothing; applies only with -Commit. The Snowflake
        secret is NEVER passed here — it lives in Azure Key Vault, referenced by the Purview credential.
    HOW TO RUN
        .\DGSNOW-Register-Source.ps1 -Action RegisterSource -PurviewAccount "<acct>" -Collection "Snowflake - Collection" -SnowflakeServer "<account>.snowflakecomputing.com" -WhatIf
        .\DGSNOW-Register-Source.ps1 -Action RegisterSource -PurviewAccount "<acct>" -Collection "Snowflake - Collection" -SnowflakeServer "<account>.snowflakecomputing.com" -Commit
        .\DGSNOW-Register-Source.ps1 -Action CreateScan -PurviewAccount "<acct>" -SnowflakeServer "<account>.snowflakecomputing.com" -CredentialName "Snowflake - Scan Credential" -PilotDatabase "PILOT_DB" -Commit
        .\DGSNOW-Register-Source.ps1 -Action RunScan -PurviewAccount "<acct>" -Commit
        PowerShell 5.1+/7+. Connect first with Connect-AzAccount (modern-auth/MFA admin).
    EXPECTED RESULTS
        -WhatIf: the planned REST body + reverse action, no change. -Commit: the source/scan exists or the
        run is triggered (verify with DGSNOW-Discover.ps1 / the portal). No secret is stored or transmitted
        by this script.
.NOTES
    Purview — Snowflake Data Governance. Safe-by-default; no secret in code. Verify your licensing/tenant:
    the Snowflake connector schema, scan-rule-set, and API version evolve — confirm the current REST shape.
#>
[CmdletBinding()]
param(
    [ValidateSet('RegisterSource','CreateScan','RunScan','DeleteScan')]
    [string]$Action = 'RegisterSource',
    [Parameter(Mandatory)] [string]$PurviewAccount,
    [string]$SourceName = 'Snowflake - Source',
    [string]$ScanName   = 'Snowflake - Scan',
    [string]$Collection,
    [string]$SnowflakeServer,                     # e.g. <account>.snowflakecomputing.com
    [string]$CredentialName = 'Snowflake - Scan Credential',   # Purview credential (Key Vault-backed) — name only
    [string]$ScanRuleSet = 'Snowflake - Scan Rule Set',
    [string]$PilotDatabase,
    [string]$ApiVersion = '2022-07-01-preview',
    [switch]$WhatIf,
    [switch]$Commit
)

if (-not $Commit) { $WhatIf = $true }
if ($WhatIf -and $Commit) { Write-Host "Specify either -WhatIf or -Commit, not both." -ForegroundColor Yellow; return }

function Get-PurviewToken {
    try { return (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net' -ErrorAction Stop).Token }
    catch { Write-Host "Could not acquire a Purview token. Run Connect-AzAccount first." -ForegroundColor Yellow; return $null }
}

$token = Get-PurviewToken
if (-not $token) { return }
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$base = "https://$PurviewAccount.purview.azure.com"
$mode = $(if ($Commit) { 'COMMIT' } else { 'WHATIF (no changes)' })
Write-Host "`n=== Snowflake onboarding — Action: $Action — Mode: $mode ===" -ForegroundColor Cyan

function Send-Pv([string]$Method, [string]$Path, $Body) {
    $uri = "{0}{1}" -f $base, $Path
    if ($WhatIf) {
        Write-Host ("  WOULD {0} {1}" -f $Method, $Path) -ForegroundColor Yellow
        if ($Body) { Write-Host ("    body: {0}" -f ($Body | ConvertTo-Json -Depth 8 -Compress)) -ForegroundColor DarkGray }
        return $null
    }
    try {
        $json = if ($Body) { $Body | ConvertTo-Json -Depth 8 } else { $null }
        return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json -ErrorAction Stop
    } catch {
        Write-Host ("  ERROR {0} {1}: {2}" -f $Method, $Path, $_.Exception.Message) -ForegroundColor Red
        Write-Host "  Verify the current connector/scan REST schema + API version for your account." -ForegroundColor Yellow
        return $null
    }
}

switch ($Action) {
    'RegisterSource' {
        if (-not $SnowflakeServer) { Write-Host "Provide -SnowflakeServer." -ForegroundColor Yellow; return }
        $body = @{
            kind = 'Snowflake'
            properties = @{
                serverName = $SnowflakeServer
                collection = @{ referenceName = $Collection; type = 'CollectionReference' }
            }
        }
        Send-Pv 'PUT' ("/scan/datasources/{0}?api-version={1}" -f $SourceName, $ApiVersion) $body | Out-Null
        if ($WhatIf) { Write-Host ("        reverse: DELETE /scan/datasources/{0}" -f $SourceName) -ForegroundColor DarkGray }
        else         { Write-Host ("  Registered (or updated) source '{0}'. Verify with DGSNOW-Discover.ps1." -f $SourceName) -ForegroundColor Green }
    }
    'CreateScan' {
        if (-not $CredentialName) { Write-Host "Provide -CredentialName (Key Vault-backed Purview credential). NO secret is passed here." -ForegroundColor Yellow; return }
        $body = @{
            kind = 'SnowflakeCredential'
            properties = @{
                serverEndpoint = $SnowflakeServer
                credential     = @{ referenceName = $CredentialName; credentialType = 'SqlAuth' }  # references Key Vault secret by name
                scanRulesetName = $ScanRuleSet
                scanRulesetType = 'Custom'
            }
        }
        if ($PilotDatabase) { $body.properties['databaseName'] = $PilotDatabase }
        Write-Host "  NOTE: the credential is referenced BY NAME (Key Vault-backed). No Snowflake secret is in this call." -ForegroundColor DarkGray
        Send-Pv 'PUT' ("/scan/datasources/{0}/scans/{1}?api-version={2}" -f $SourceName, $ScanName, $ApiVersion) $body | Out-Null
        if ($WhatIf) { Write-Host ("        reverse: DELETE /scan/datasources/{0}/scans/{1}" -f $SourceName, $ScanName) -ForegroundColor DarkGray }
        else         { Write-Host ("  Created scan '{0}' scoped to {1}. Trigger with -Action RunScan." -f $ScanName, $(if($PilotDatabase){$PilotDatabase}else{'(all in scope)'})) -ForegroundColor Green }
    }
    'RunScan' {
        $runId = [guid]::NewGuid().ToString()
        Send-Pv 'PUT' ("/scan/datasources/{0}/scans/{1}/runs/{2}?api-version={3}" -f $SourceName, $ScanName, $runId, $ApiVersion) $null | Out-Null
        if ($WhatIf) { Write-Host "        reverse: (a run cannot be un-done; cancel in the portal if needed)" -ForegroundColor DarkGray }
        else         { Write-Host ("  Triggered scan run {0} for '{1}'. Watch status in the portal / DGSNOW-Validate.ps1." -f $runId, $ScanName) -ForegroundColor Green }
    }
    'DeleteScan' {
        Send-Pv 'DELETE' ("/scan/datasources/{0}/scans/{1}?api-version={2}" -f $SourceName, $ScanName, $ApiVersion) $null | Out-Null
        if (-not $WhatIf) { Write-Host ("  Deleted scan '{0}'. The already-cataloged assets remain until removed." -f $ScanName) -ForegroundColor Green }
    }
}
