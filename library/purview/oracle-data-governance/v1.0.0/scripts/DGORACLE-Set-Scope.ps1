<#
.SYNOPSIS
    DGORACLE-Set-Scope.ps1 — Record the Oracle pilot/expansion scope for Purview governance (read-only helper).
.DESCRIPTION
    PURPOSE
        Captures and writes a scope manifest for the Oracle pilot (or an expansion wave): the target
        collection, the Oracle source (host, service/SID, listener port, version) and the schemas to
        scan (with owner/steward and the credential name it uses), and the scan-rule-set intent.
        Read-only against the tenant — it writes only a local JSON manifest you register and scan
        against; it does not change the Purview account or the Oracle database, and it holds NO secret
        (the credential is referenced by name).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGORACLE-Set-Scope.ps1 -Collection DGORACLE-Collection-Pilot `
            -Host oradb01.contoso.example -Service ORCLPDB1 -Port 1521 `
            -Schema @('HR','FINANCE') -Credential DGORACLE-Cred-Oracle-KV `
            -IntegrationRuntime DGORACLE-SHIR -OutFile .\oracle-pilot-scope.json
    EXPECTED RESULTS
        An oracle-pilot-scope.json manifest listing the collection, the Oracle source (host/service/port),
        the in-scope schemas, owner/steward placeholders, the credential name, the SHIR, and the scan
        rule set, plus a printed summary — used as the input to DGORACLE-Register-OracleSource.ps1.
.NOTES
    Purview — Oracle Data Governance. Local manifest only; no tenant or Oracle change; no secrets.
    Names are white-label placeholders (contoso.example). Assign a real owner/steward before registering.
#>
[CmdletBinding()]
param(
    [string]$Collection         = 'DGORACLE-Collection-Pilot',
    [Parameter(Mandatory = $true)][string]$Host,             # Oracle host, e.g. oradb01.contoso.example
    [Parameter(Mandatory = $true)][string]$Service,          # service name or SID, e.g. ORCLPDB1
    [int]$Port                  = 1521,                       # listener port (verify your instance)
    [string[]]$Schema           = @(),                        # in-scope schemas, e.g. 'HR','FINANCE'
    [string]$Credential         = 'DGORACLE-Cred-Oracle-KV',  # NAME of the Purview credential (Key Vault secret, Basic auth)
    [string]$IntegrationRuntime = 'DGORACLE-SHIR',
    [string]$ScanRuleSet        = 'DGORACLE-ScanRuleSet-Pilot',
    [string]$OutFile            = '.\oracle-pilot-scope.json'
)

if (-not $Schema -or $Schema.Count -eq 0) {
    Write-Host "No schemas supplied. Provide at least one -Schema to bound the pilot scan (do not scan the whole instance)." -ForegroundColor Yellow
    return
}

$scope = [ordered]@{
    generatedUtc       = (Get-Date).ToUniversalTime().ToString('o')
    collection         = $Collection
    integrationRuntime = $IntegrationRuntime
    scanRuleSet        = $ScanRuleSet
    credential         = $Credential
    oracleSource       = [ordered]@{
        host    = $Host
        service = $Service
        port    = $Port
        version = '<verify version>'
        owner   = '<assign owner>'
        steward = '<assign steward>'
    }
    schemas            = @($Schema | ForEach-Object { [ordered]@{ schema = $_; owner = '<assign owner>'; steward = '<assign steward>' } })
}

$scope | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "`n=== Purview Oracle Data Governance — pilot scope recorded ===" -ForegroundColor Cyan
Write-Host ("Collection       : {0}" -f $Collection)
Write-Host ("Integration RT   : {0}" -f $IntegrationRuntime)
Write-Host ("Scan rule set    : {0}" -f $ScanRuleSet)
Write-Host ("Oracle source    : {0}:{1}/{2}" -f $Host, $Port, $Service)
Write-Host  "In-scope schemas :"
$scope.schemas | ForEach-Object { Write-Host ("    - {0}" -f $_.schema) }
Write-Host ("Credential       : {0} (referenced BY NAME — no Oracle password in this manifest)" -f $Credential) -ForegroundColor DarkGray
Write-Host ("`nManifest written : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "Assign an owner and steward to the source and each schema, and verify the version/port before registering." -ForegroundColor Cyan
Write-Host "Feed this manifest to DGORACLE-Register-OracleSource.ps1." -ForegroundColor Cyan
