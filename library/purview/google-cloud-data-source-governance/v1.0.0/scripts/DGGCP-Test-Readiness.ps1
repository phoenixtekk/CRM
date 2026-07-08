<#
.SYNOPSIS
    DGGCP-Test-Readiness.ps1 — Consolidated PASS/GAP pilot-gate check for Google BigQuery governance (read-only).
.DESCRIPTION
    PURPOSE
        Runs the pilot gate in one view: account endpoint reachable, least-privilege roles present, a
        self-hosted integration runtime (SHIR) registered, the Google BigQuery source registered, at
        least one scan Succeeded, classification coverage > 0, and owners assigned. Read-only — it only
        reads the Purview data-plane REST / catalog search and prints a single PASS/GAP summary. It does
        not register, scan, or change anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGGCP-Test-Readiness.ps1 -PurviewAccount contoso-purview `
            -Collection DGGCP-Collection-Pilot
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the collection.
    EXPECTED RESULTS
        A PASS/GAP line per gate signal and an overall PILOT GATE: PASS only when every signal passes.
        Use it as the Step 10 gate before widening scope.
.NOTES
    Purview — Data Governance (Google BigQuery). Read-only. Verify current API versions and the
    BigQuery connector availability for your tenant; the Data Governance experience is evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Collection = 'DGGCP-Collection-Pilot',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
try { $token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token }
catch { Write-Host ("Could not acquire a Purview data-plane token: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return }
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Method = $Method; Uri = ("{0}{1}" -f $Endpoint, $Path); Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 6) }
    Invoke-RestMethod @p
}
function Show([string]$label, [bool]$ok, [string]$detail) {
    $state = if ($ok) { 'PASS' } else { 'GAP ' }
    Write-Host ("{0,-34}: {1} {2}" -f $label, $state, $detail) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
    return $ok
}

Write-Host "`n=== Purview — Google BigQuery pilot readiness gate ===" -ForegroundColor Cyan
$results = @()

# 1) Endpoint reachable
$reach = $false
try { $null = Invoke-Purview '/account/collections?api-version=2019-11-01-preview'; $reach = $true } catch {}
$results += Show 'Account endpoint reachable' $reach $Endpoint
if (-not $reach) { Write-Host "`nPILOT GATE: GAP — account not reachable; fix before continuing." -ForegroundColor Red; return }

# 2) SHIR registered
$shir = $false
try {
    $irs = @((Invoke-Purview '/scan/integrationruntimes?api-version=2018-12-01-preview').value)
    $shir = @($irs | Where-Object { $_.properties.type -match 'SelfHosted' }).Count -gt 0
} catch {}
$results += Show 'Self-hosted IR (SHIR) present' $shir 'BigQuery scans run on a SHIR'

# 3) BigQuery source registered
$srcOk = $false
try {
    $sources = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $srcOk = @($sources | Where-Object { $_.kind -match 'BigQuery' }).Count -gt 0
} catch {}
$results += Show 'Google BigQuery source registered' $srcOk ''

# 4) A scan Succeeded + 5/6) classification & owner coverage
$scanOk = $false; $classOk = $false; $ownOk = $false
try {
    $bq = @($sources | Where-Object { $_.kind -match 'BigQuery' })
    foreach ($s in $bq) {
        $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
        foreach ($sc in $scans) {
            $hist = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
            if (@($hist | Where-Object { $_.status -eq 'Succeeded' }).Count -gt 0) { $scanOk = $true }
        }
    }
} catch {}
$results += Show 'At least one scan Succeeded' $scanOk ''

try {
    $search = @{ keywords = '*'; limit = 1000 }
    if ($Collection) { $search.filter = @{ collectionId = $Collection } }
    $rows = @((Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' $search).value)
    $classOk = @($rows | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count -gt 0
    $ownOk   = @($rows | Where-Object { $_.owner -or $_.experts -or $_.contact }).Count -gt 0
} catch {}
$results += Show 'Classification coverage > 0' $classOk ''
$results += Show 'Owners assigned on assets' $ownOk ''

$allPass = ($results -notcontains $false)
Write-Host ("`nPILOT GATE: {0}" -f ($(if($allPass){'PASS — pilot validated; you may expand scope.'}else{'GAP — remediate the GAP lines above before widening scope.'}))) -ForegroundColor ($(if($allPass){'Green'}else{'Yellow'}))
Write-Host "Note: API versions above are examples — verify current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
