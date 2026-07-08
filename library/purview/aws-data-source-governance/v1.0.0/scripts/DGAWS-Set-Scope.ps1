<#
.SYNOPSIS
    DGAWS-Set-Scope.ps1 — Record the AWS (S3/RDS) pilot/expansion scope for Purview governance (read-only helper).
.DESCRIPTION
    PURPOSE
        Captures and writes a scope manifest for the AWS pilot (or an expansion wave): the target
        collection, the S3 buckets and/or RDS databases to register (with region/owner/steward and the
        credential name each uses), and the scan-rule-set intent. Read-only against the tenant — it
        writes only a local JSON manifest you register and scan against; it does not change the Purview
        account or any AWS resource, and it holds NO AWS secret (credentials are referenced by name).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGAWS-Set-Scope.ps1 -Collection DGAWS-Collection-Pilot `
            -S3Bucket @('contoso-fin-extracts','contoso-customer-exports') `
            -RdsDatabase @('fin-rds-01.contoso.example/FinanceDB') `
            -S3Credential DGAWS-Cred-S3-Role -RdsCredential DGAWS-Cred-RDS-KV `
            -OutFile .\aws-pilot-scope.json
    EXPECTED RESULTS
        An aws-pilot-scope.json manifest listing the collection, the S3 buckets and RDS databases (each
        with owner/steward placeholders and the credential name), and the scan rule set, plus a printed
        summary — used as the input to DGAWS-Register-AwsSource.ps1.
.NOTES
    Purview — AWS Data-Source Governance. Local manifest only; no tenant or AWS change; no secrets.
    Names are white-label placeholders (contoso.example). Assign a real owner/steward before registering.
#>
[CmdletBinding()]
param(
    [string]$Collection    = 'DGAWS-Collection-Pilot',
    [string[]]$S3Bucket    = @(),                            # bucket names, e.g. 'contoso-fin-extracts'
    [string[]]$RdsDatabase = @(),                            # 'endpoint/Database', e.g. 'fin-rds-01.contoso.example/FinanceDB'
    [string]$S3Credential  = 'DGAWS-Cred-S3-Role',           # NAME of the Purview credential referencing the IAM role ARN
    [string]$RdsCredential = 'DGAWS-Cred-RDS-KV',            # NAME of the Purview credential referencing the Key Vault secret
    [string]$ScanRuleSet   = 'DGAWS-ScanRuleSet-Pilot',
    [string]$OutFile       = '.\aws-pilot-scope.json'
)

if ((-not $S3Bucket -or $S3Bucket.Count -eq 0) -and (-not $RdsDatabase -or $RdsDatabase.Count -eq 0)) {
    Write-Host "No sources supplied. Provide at least one -S3Bucket and/or one -RdsDatabase (endpoint/Database)." -ForegroundColor Yellow
    return
}

$scope = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    collection   = $Collection
    scanRuleSet  = $ScanRuleSet
    s3Sources    = @($S3Bucket    | ForEach-Object { [ordered]@{ bucket = $_; region = '<verify region>'; credential = $S3Credential; owner = '<assign owner>'; steward = '<assign steward>' } })
    rdsSources   = @($RdsDatabase | ForEach-Object { [ordered]@{ endpointDatabase = $_; credential = $RdsCredential; owner = '<assign owner>'; steward = '<assign steward>' } })
}

$scope | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "`n=== Purview AWS Data-Source Governance — pilot scope recorded ===" -ForegroundColor Cyan
Write-Host ("Collection       : {0}" -f $Collection)
Write-Host ("Scan rule set    : {0}" -f $ScanRuleSet)
Write-Host  "S3 buckets       :"
if ($scope.s3Sources.Count -eq 0) { Write-Host "    (none)" -ForegroundColor DarkGray }
$scope.s3Sources | ForEach-Object { Write-Host ("    - {0} (cred {1})" -f $_.bucket, $_.credential) }
Write-Host  "RDS databases    :"
if ($scope.rdsSources.Count -eq 0) { Write-Host "    (none)" -ForegroundColor DarkGray }
$scope.rdsSources | ForEach-Object { Write-Host ("    - {0} (cred {1})" -f $_.endpointDatabase, $_.credential) }
Write-Host ("`nManifest written : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "Assign an owner and steward to each source and verify each region before registering." -ForegroundColor Cyan
Write-Host "Credentials are referenced BY NAME only — no AWS key or DB secret is ever written to this manifest." -ForegroundColor DarkGray
Write-Host "Feed this manifest to DGAWS-Register-AwsSource.ps1." -ForegroundColor Cyan
