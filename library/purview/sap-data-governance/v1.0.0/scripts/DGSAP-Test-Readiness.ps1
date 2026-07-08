<#
.SYNOPSIS
    DGSAP-Test-Readiness.ps1 — Consolidated PASS/GAP pilot-gate check for SAP data governance (read-only).
.DESCRIPTION
    PURPOSE
        Runs the pilot gate in one view: confirms the Purview account endpoint is reachable, the named
        pilot collection exists with least-privilege roles, a self-hosted integration runtime (SHIR) is
        registered (SAP scans need one), the SAP source is registered, at least one scan has Succeeded,
        classification coverage is > 0, and scanned SAP assets have owners. Read-only — it changes
        nothing. Use it as the Step 10 gate before widening scope.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGSAP-Test-Readiness.ps1 -PurviewAccount contoso-purview `
            -Collection DGSAP-Collection-Pilot
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the collection.
    EXPECTED RESULTS
        A single PASS/GAP summary across account reachability, roles, SHIR, SAP source registration, scan
        status, classification coverage, and ownership — plus an overall pilot-gate PASS/GAP line. Any GAP
        must be remediated before expanding beyond the pilot.
.NOTES
    Purview — SAP Data Governance. Read-only. Test connection on the SAP source is confirmed in the
    portal (driver/network/credential) — this script reports registration + scan + coverage signals.
    Verify current Purview data-plane API versions for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Collection = 'DGSAP-Collection-Pilot',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Method = $Method; Uri = ("{0}{1}" -f $Endpoint, $Path); Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 6) }
    Invoke-RestMethod @p
}
$gaps = 0
function Gate([string]$Label, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host ("  PASS  {0,-30} {1}" -f $Label, $Detail) -ForegroundColor Green }
    else     { Write-Host ("  GAP   {0,-30} {1}" -f $Label, $Detail) -ForegroundColor Yellow; $script:gaps++ }
}

Write-Host "`n=== Purview SAP Data Governance — consolidated readiness gate ===" -ForegroundColor Cyan
Write-Host ("Account          : {0}" -f $Endpoint)
Write-Host ("Pilot collection : {0}`n" -f $Collection)

# 1) Endpoint reachable + collection exists
$collections = @()
try {
    $collections = @((Invoke-Purview '/account/collections?api-version=2019-11-01-preview').value)
    Gate 'Endpoint reachable' $true ("{0} collection(s)" -f $collections.Count)
} catch {
    Gate 'Endpoint reachable' $false $_.Exception.Message
    Write-Host "`nCannot continue — resolve endpoint/access first." -ForegroundColor Yellow; return
}
$col = $collections | Where-Object { $_.name -eq $Collection -or $_.friendlyName -eq $Collection } | Select-Object -First 1
Gate 'Pilot collection exists' ([bool]$col) ($(if($col){$Collection}else{"'$Collection' not found"}))

# 2) Roles on the collection (Data source admin needed to register/scan)
$dsaOk = $false
if ($col) {
    try {
        $policies = Invoke-Purview ("/policystore/metadataPolicies?collectionName={0}&api-version=2021-07-01-preview" -f $col.name)
        foreach ($p in @($policies.values)) {
            foreach ($att in @($p.properties.attributeRules)) {
                if ($att.id -match 'purviewmetadatarole_builtin_data-source-administrator') { $dsaOk = $true }
            }
        }
    } catch {}
}
Gate 'Data source admin role' $dsaOk ($(if($dsaOk){'assigned'}else{'verify assignment (needed to register/scan)'}))

# 3) SHIR registered (SAP scans need a self-hosted integration runtime)
$shirOk = $false
try {
    $irs = @((Invoke-Purview '/scan/integrationruntimes?api-version=2018-12-01-preview').value)
    $shirOk = @($irs | Where-Object { $_.properties.type -match 'SelfHosted' }).Count -gt 0
} catch {}
Gate 'Self-hosted IR (SHIR)' $shirOk ($(if($shirOk){'registered'}else{'install a SHIR with line of sight to SAP + SAP driver/Java'}))

# 4) SAP source registered
$sap = @()
try {
    $sources = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $sap = @($sources | Where-Object { $_.kind -match 'Sap|SAPEcc|SAPS4Hana|SapBw|SapHana|Hana' })
} catch {}
Gate 'SAP source registered' ($sap.Count -gt 0) ("{0} SAP source(s)" -f $sap.Count)

# 5) At least one SAP scan Succeeded
$scanOk = $false
foreach ($s in $sap) {
    try {
        $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
        foreach ($sc in $scans) {
            $hist = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
            if (@($hist | Where-Object { $_.status -eq 'Succeeded' }).Count -gt 0) { $scanOk = $true }
        }
    } catch {}
}
Gate 'Scan Succeeded' $scanOk ($(if($scanOk){'at least one run Succeeded'}else{'no successful SAP scan yet'}))

# 6) Classification + ownership coverage
$total = 0; $classified = 0; $owned = 0
try {
    $search = @{ keywords = 'sap'; limit = 1000; filter = @{ collectionId = $Collection } }
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' $search
    $rows = @($res.value)
    $total = $rows.Count
    $classified = @($rows | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count
    $owned = @($rows | Where-Object { $_.owner -or $_.experts -or $_.contact }).Count
} catch {}
Gate 'Classification coverage' ($classified -gt 0) ("{0}/{1} classified" -f $classified, $total)
Gate 'Ownership assigned' ($total -gt 0 -and $owned -eq $total) ("{0}/{1} owned" -f $owned, $total)

# --- Overall ---
Write-Host ""
if ($gaps -eq 0) {
    Write-Host "PILOT GATE: PASS — SAP source registered, scanned, classified, and owned. Safe to expand one source at a time." -ForegroundColor Green
} else {
    Write-Host ("PILOT GATE: GAP — {0} item(s) to remediate before expanding beyond the pilot." -f $gaps) -ForegroundColor Yellow
}
Write-Host "Note: confirm Test connection passes in the portal (SHIR loads the SAP driver, reaches SAP, authenticates via Key Vault credential)." -ForegroundColor DarkGray
Write-Host "Note: API versions above are examples — verify current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
