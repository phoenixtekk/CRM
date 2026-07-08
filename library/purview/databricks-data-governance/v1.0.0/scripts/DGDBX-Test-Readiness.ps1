<#
.SYNOPSIS
    DGDBX-Test-Readiness.ps1 — Consolidated PASS/GAP readiness + pilot-gate check for Databricks governance (read-only).
.DESCRIPTION
    PURPOSE
        Verifies prerequisites and the pilot gate in one view: the Purview account endpoint is reachable,
        the least-privilege roles (especially Data source admin) are present on the collection, an
        integration runtime is registered (managed or self-hosted for a private workspace), a Key Vault
        connection is present, the Azure Databricks source is registered and (where scanned) its last run
        Succeeded, classification coverage is > 0, and scanned assets have owners. Read-only — it makes no
        change. Use it to confirm readiness before registering, and again in the Validate step to decide
        whether the pilot passes before expanding.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGDBX-Test-Readiness.ps1 -PurviewAccount contoso-purview `
            -Collection DGDBX-Collection-Pilot
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the collection.
    EXPECTED RESULTS
        A single PASS/GAP table across the readiness/gate signals and an overall verdict (PILOT PASS only
        when all gate signals PASS). Any GAP names the requirement to remediate before expanding scope.
.NOTES
    Purview — Databricks Data Governance. Read-only gate check; no writes. Verify current Purview
    data-plane API versions for your tenant — the Data Governance experience and the Azure Databricks
    connector evolve.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Collection = 'DGDBX-Collection-Pilot',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
try { $token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token }
catch { Write-Host ("Could not acquire a Purview token: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return }
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Method = $Method; Uri = ("{0}{1}" -f $Endpoint, $Path); Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 6) }
    Invoke-RestMethod @p
}

$results = [ordered]@{}
function Set-Gate([string]$Name, [bool]$Pass, [string]$Detail) { $script:results[$Name] = [pscustomobject]@{ Pass = $Pass; Detail = $Detail } }

Write-Host "`n=== Purview Databricks Data Governance — readiness & pilot gate ===" -ForegroundColor Cyan

# 1) Endpoint reachable + collection present
$collOk = $false
try {
    $collections = @((Invoke-Purview '/account/collections?api-version=2019-11-01-preview').value)
    $collOk = ($collections | Where-Object { $_.name -eq $Collection -or $_.friendlyName -eq $Collection }).Count -gt 0
    Set-Gate 'Endpoint reachable' $true ("{0} collection(s)" -f $collections.Count)
    Set-Gate 'Pilot collection exists' $collOk ($(if($collOk){$Collection}else{"'$Collection' not found"}))
} catch {
    Set-Gate 'Endpoint reachable' $false $_.Exception.Message
    Set-Gate 'Pilot collection exists' $false 'endpoint unreachable'
}

# 2) Data source admin role coverage on the collection
$dsaOk = $false
try {
    $policies = Invoke-Purview ("/policystore/metadataPolicies?collectionName={0}&api-version=2021-07-01-preview" -f $Collection)
    foreach ($p in @($policies.values)) {
        foreach ($att in @($p.properties.attributeRules)) {
            if ($att.id -match 'purviewmetadatarole_builtin_data-source-administrator') { $dsaOk = $true }
        }
    }
} catch {}
Set-Gate 'Data source admin assigned' $dsaOk ($(if($dsaOk){'present'}else{'verify assignment (needed to register/scan)'}))

# 3) Integration runtime registered (network path)
$irOk = $false
try {
    $irs = @((Invoke-Purview '/scan/integrationruntimes?api-version=2018-12-01-preview').value)
    $irOk = $irs.Count -gt 0
    Set-Gate 'Integration runtime present' $irOk ("{0} runtime(s)" -f $irs.Count)
} catch { Set-Gate 'Integration runtime present' $false 'could not read runtimes' }

# 4) Key Vault connection present (scan credential is Key Vault-backed)
$kvOk = $false
try {
    $kvs = @((Invoke-Purview '/scan/azureKeyVaults?api-version=2018-12-01-preview').value)
    $kvOk = $kvs.Count -gt 0
    Set-Gate 'Key Vault connection present' $kvOk ($(if($kvOk){("{0} linked" -f $kvs.Count)}else{'link a Key Vault for the Databricks scan secret'}))
} catch { Set-Gate 'Key Vault connection present' $false 'could not read Key Vault connections (verify API version)' }

# 5) At least one Databricks source registered
$dbx = @()
try {
    $sources = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $dbx = @($sources | Where-Object { $_.kind -match 'Databricks|UnityCatalog|Hive' })
} catch {}
Set-Gate 'Databricks source registered' ($dbx.Count -gt 0) ("{0} Azure Databricks source(s)" -f $dbx.Count)

# 6) At least one Databricks scan Succeeded
$scanOk = $false
foreach ($s in $dbx) {
    try {
        $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
        foreach ($sc in $scans) {
            $runs = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
            if (($runs | Where-Object { $_.status -eq 'Succeeded' }).Count -gt 0) { $scanOk = $true }
        }
    } catch {}
}
Set-Gate 'Databricks scan Succeeded' $scanOk ($(if($scanOk){'at least one Succeeded run'}else{'no Succeeded scan run yet'}))

# 7) Classification + ownership coverage
$classOk = $false; $ownOk = $false
try {
    $search = @{ keywords = '*'; limit = 1000; filter = @{ collectionId = $Collection } }
    $rows = @((Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' $search).value)
    $total = $rows.Count
    if ($total -gt 0) {
        $classOk = @($rows | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count -gt 0
        $ownOk   = @($rows | Where-Object { $_.owner -or $_.experts -or $_.contact }).Count -eq $total
    }
    Set-Gate 'Classification coverage > 0' $classOk ("{0} asset(s) in scope" -f $total)
    Set-Gate 'Every scanned asset owned' $ownOk ($(if($ownOk){'all owned'}else{'some assets have no owner'}))
} catch {
    Set-Gate 'Classification coverage > 0' $false 'catalog search unavailable'
    Set-Gate 'Every scanned asset owned' $false 'catalog search unavailable'
}

# --- Print the gate table + verdict ---------------------------------------------------------------
Write-Host ""
$allPass = $true
foreach ($k in $results.Keys) {
    $r = $results[$k]
    if (-not $r.Pass) { $allPass = $false }
    $flag = if ($r.Pass) { 'PASS' } else { 'GAP ' }
    $col  = if ($r.Pass) { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1,-32} {2}" -f $flag, $k, $r.Detail) -ForegroundColor $col
}
Write-Host ""
if ($allPass) {
    Write-Host "VERDICT: PILOT PASS — all gate signals green. You may expand scope (enable scheduled scans only after each new scope validates)." -ForegroundColor Green
} else {
    Write-Host "VERDICT: NOT YET — remediate each GAP above and re-run before expanding scope." -ForegroundColor Yellow
}
Write-Host "Note: API versions above are examples — verify current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
