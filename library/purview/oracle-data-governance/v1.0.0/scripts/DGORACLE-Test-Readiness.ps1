<#
.SYNOPSIS
    DGORACLE-Test-Readiness.ps1 — Consolidated PASS/GAP pilot-gate check for Oracle governance (read-only).
.DESCRIPTION
    PURPOSE
        Runs the pilot gate in one view: is the Purview account reachable, are the least-privilege
        roles present on the pilot collection, is a self-hosted integration runtime registered, is the
        Oracle source registered (and does it have a scan that Succeeded), and is there classification +
        owner coverage on the scanned assets. Read-only — it only reads the Purview data-plane REST API
        and prints a PASS/GAP summary; it changes nothing and holds no secret.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGORACLE-Test-Readiness.ps1 -PurviewAccount contoso-purview `
            -Collection DGORACLE-Collection-Pilot
        Requires Az.Accounts and Connect-AzAccount with at least Data reader on the collection.
    EXPECTED RESULTS
        A single PASS/GAP block: account reachable, Data source admin present on the collection, a SHIR
        registered, at least one Oracle source registered, at least one scan Succeeded, classification
        coverage > 0, and owners assigned — the pilot gate. Any GAP names what to remediate before you
        widen scope.
.NOTES
    Purview — Oracle Data Governance. Read-only. Verify current API versions and search fields for your
    tenant. This is a readiness gate, not a compliance determination — sensitivity/retention/access
    determinations stay with the data owners, compliance, records, privacy, and legal functions.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Collection = 'DGORACLE-Collection-Pilot',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body) {
    $u = ("{0}{1}" -f $Endpoint, $Path)
    if ($Body) { Invoke-RestMethod -Method $Method -Uri $u -Headers $headers -Body $Body -ErrorAction Stop }
    else       { Invoke-RestMethod -Method $Method -Uri $u -Headers $headers -ErrorAction Stop }
}
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result($name, $ok, $detail) { $results.Add([pscustomobject]@{ Check = $name; State = ($(if($ok){'PASS'}else{'GAP'})); Detail = $detail }) }

Write-Host "`n=== Purview Oracle Data Governance — consolidated readiness gate ===" -ForegroundColor Cyan

# 1) Account reachable + collection present
$collFound = $false
try {
    $cols = @((Invoke-Purview '/account/collections?api-version=2019-11-01-preview').value)
    Add-Result 'Account endpoint reachable' $true ("{0} collection(s)" -f $cols.Count)
    $collFound = [bool]@($cols | Where-Object { $_.name -eq $Collection -or $_.friendlyName -eq $Collection }).Count
    Add-Result 'Pilot collection present' $collFound $Collection
} catch {
    Add-Result 'Account endpoint reachable' $false $_.Exception.Message
}

# 2) Data source admin role present on the collection
try {
    $pol = Invoke-Purview ("/policystore/metadataPolicies?collectionName={0}&api-version=2021-07-01-preview" -f $Collection)
    $hasDsa = $false
    foreach ($p in @($pol.values)) { foreach ($att in @($p.properties.attributeRules)) { if ($att.id -match 'data-source-administrator') { $hasDsa = $true } } }
    Add-Result 'Data source admin on collection' $hasDsa 'needed to register/scan'
} catch {
    Add-Result 'Data source admin on collection' $false ("role read failed: {0}" -f $_.Exception.Message)
}

# 3) A self-hosted integration runtime is registered
try {
    $irs = @((Invoke-Purview '/scan/integrationruntimes?api-version=2018-12-01-preview').value)
    $shir = @($irs | Where-Object { $_.properties.type -match 'SelfHosted' })
    Add-Result 'Self-hosted IR (SHIR) registered' ([bool]$shir.Count) ("{0} SHIR of {1} IR(s)" -f $shir.Count, $irs.Count)
} catch {
    Add-Result 'Self-hosted IR (SHIR) registered' $false $_.Exception.Message
}

# 4) Oracle source registered + at least one scan Succeeded
$oracle = @()
try {
    $all = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $oracle = @($all | Where-Object { $_.kind -match 'Oracle' })
    Add-Result 'Oracle source registered' ([bool]$oracle.Count) ("{0} Oracle source(s)" -f $oracle.Count)
} catch {
    Add-Result 'Oracle source registered' $false $_.Exception.Message
}
$anySucceeded = $false
foreach ($s in $oracle) {
    try {
        $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
        foreach ($sc in $scans) {
            $runs = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
            if (@($runs | Where-Object { $_.status -eq 'Succeeded' }).Count -gt 0) { $anySucceeded = $true }
        }
    } catch {}
}
Add-Result 'At least one scan Succeeded' $anySucceeded 'run Test connection, then trigger a scoped scan'

# 5) Classification + owner coverage (verify search API/fields)
try {
    $searchBody = @{ keywords = $null; filter = @{ 'and' = @(@{ 'assetType' = 'Oracle' }) }; limit = 100 } | ConvertTo-Json -Depth 6
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-08-01-preview' 'POST' $searchBody
    $assets = @($res.value)
    $classified = @($assets | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count
    $owned      = @($assets | Where-Object { $_.owner -or $_.contact -or $_.ownerId }).Count
    Add-Result 'Classification coverage > 0' ($classified -gt 0) ("{0} classified of {1} sampled" -f $classified, $assets.Count)
    Add-Result 'Every scanned asset owned'  ($assets.Count -gt 0 -and $owned -eq $assets.Count) ("{0} owned of {1} sampled" -f $owned, $assets.Count)
} catch {
    Add-Result 'Classification coverage > 0' $false ("search skipped: {0}" -f $_.Exception.Message)
    Add-Result 'Every scanned asset owned'  $false 'verify the catalog search API/fields for your tenant'
}

# --- Summary --------------------------------------------------------------------------------------
Write-Host ""
foreach ($r in $results) {
    $col = if ($r.State -eq 'PASS') { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1,-34} {2}" -f $r.State, $r.Check, $r.Detail) -ForegroundColor $col
}
$gaps = @($results | Where-Object { $_.State -eq 'GAP' }).Count
Write-Host ""
if ($gaps -eq 0) { Write-Host "PILOT GATE: PASS — all checks green. You may expand scope (keep scans one-time until each new scope validates)." -ForegroundColor Green }
else { Write-Host ("PILOT GATE: {0} GAP(s) — remediate the items above before widening scope. Do NOT enable scheduled scans until the gate is green." -f $gaps) -ForegroundColor Yellow }
Write-Host "Note: this is a technical readiness gate — sensitivity/retention/access determinations remain with the data owners, compliance, records, privacy, and legal functions." -ForegroundColor DarkGray
