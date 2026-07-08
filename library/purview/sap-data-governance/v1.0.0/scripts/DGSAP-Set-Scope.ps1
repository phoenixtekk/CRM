<#
.SYNOPSIS
    DGSAP-Set-Scope.ps1 — Record the SAP pilot/expansion scope for Purview governance (read-only helper).
.DESCRIPTION
    PURPOSE
        Captures and writes a scope manifest for the SAP pilot (or an expansion wave): the target
        collection, the SAP system(s) to register (type, connection details, owner/steward, the SHIR to
        scan through, and the credential name each uses), and the scan-rule-set intent. Read-only against
        the tenant — it writes only a local JSON manifest you register and scan against; it does not
        change the Purview account or any SAP system, and it holds NO SAP secret (credentials are
        referenced by name).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGSAP-Set-Scope.ps1 -Collection DGSAP-Collection-Pilot `
            -SapSystem @('ECC:erp-app-01.contoso.example:00:100','HANA:hana-01.contoso.example:30015:HDB') `
            -Shir DGSAP-SHIR-01 -Credential DGSAP-Cred-SAP-KV `
            -OutFile .\sap-pilot-scope.json
        Each -SapSystem entry is 'TYPE:host:instanceOrPort:clientOrTenant'
        (TYPE = ECC | S4HANA | BW | HANA — verify the exact source kind for your connector).
    EXPECTED RESULTS
        A sap-pilot-scope.json manifest listing the collection, the SAP systems (each with type,
        connection details, owner/steward placeholders, the SHIR, and the credential name), and the scan
        rule set, plus a printed summary — used as the input to DGSAP-Register-SapSource.ps1.
.NOTES
    Purview — SAP Data Governance. Local manifest only; no tenant or SAP change; no secrets.
    Names are white-label placeholders (contoso.example). Assign a real owner/steward before registering.
#>
[CmdletBinding()]
param(
    [string]$Collection  = 'DGSAP-Collection-Pilot',
    [string[]]$SapSystem = @(),                              # 'TYPE:host:instanceOrPort:clientOrTenant'
    [string]$Shir        = 'DGSAP-SHIR-01',                  # NAME of the self-hosted integration runtime to scan through
    [string]$Credential  = 'DGSAP-Cred-SAP-KV',             # NAME of the Purview credential referencing the Key Vault secret
    [string]$ScanRuleSet = 'DGSAP-ScanRuleSet-Pilot',
    [string]$OutFile     = '.\sap-pilot-scope.json'
)

if (-not $SapSystem -or $SapSystem.Count -eq 0) {
    Write-Host "No SAP systems supplied. Provide at least one -SapSystem 'TYPE:host:instanceOrPort:clientOrTenant'." -ForegroundColor Yellow
    return
}

$sources = @()
foreach ($s in $SapSystem) {
    $parts = $s -split ':'
    $sources += [ordered]@{
        type             = $(if ($parts.Count -ge 1) { $parts[0] } else { '<verify type>' })   # ECC | S4HANA | BW | HANA
        host             = $(if ($parts.Count -ge 2) { $parts[1] } else { '<host>' })
        instanceOrPort   = $(if ($parts.Count -ge 3) { $parts[2] } else { '<instance/port>' })
        clientOrTenant   = $(if ($parts.Count -ge 4) { $parts[3] } else { '<client/tenant>' })
        shir             = $Shir
        credential       = $Credential
        owner            = '<assign owner>'
        steward          = '<assign steward>'
    }
}

$scope = [ordered]@{
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    collection   = $Collection
    scanRuleSet  = $ScanRuleSet
    sapSources   = $sources
}

$scope | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8

Write-Host "`n=== Purview SAP Data-Source Governance — pilot scope recorded ===" -ForegroundColor Cyan
Write-Host ("Collection       : {0}" -f $Collection)
Write-Host ("Scan rule set    : {0}" -f $ScanRuleSet)
Write-Host ("SHIR             : {0}" -f $Shir)
Write-Host  "SAP systems      :"
$scope.sapSources | ForEach-Object { Write-Host ("    - {0} {1}:{2}/{3} (cred {4})" -f $_.type, $_.host, $_.instanceOrPort, $_.clientOrTenant, $_.credential) }
Write-Host ("`nManifest written : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
Write-Host "Assign an owner and steward to each system and verify each connection detail before registering." -ForegroundColor Cyan
Write-Host "Credentials are referenced BY NAME only — no SAP password is ever written to this manifest." -ForegroundColor DarkGray
Write-Host "Feed this manifest to DGSAP-Register-SapSource.ps1." -ForegroundColor Cyan
