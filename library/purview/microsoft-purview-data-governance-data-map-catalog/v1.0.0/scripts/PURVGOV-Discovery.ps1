<#
.SYNOPSIS
    PURVGOV-Discovery.ps1 — Purview Data Governance readiness, collection, and role discovery (read-only).
.DESCRIPTION
    PURPOSE
        Reports data-governance readiness so you can assess current state before registering sources
        or scanning: whether the Microsoft Purview account data-plane endpoint is reachable, which
        collections exist and their role-assignment coverage, which integration runtimes are
        registered, and a high-level count of registered data sources. Read-only — it makes no change
        to the account, sources, or catalog. Supports the Assess step.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVGOV-Discovery.ps1 -PurviewAccount contoso-purview
        Requires the Az PowerShell modules (Az.Accounts). Sign in first with Connect-AzAccount using an
        account holding at least Data reader on the collections. The script acquires a data-plane token
        for the Purview REST API (resource https://purview.azure.net); no secret is stored in the script.
    EXPECTED RESULTS
        A readiness summary: endpoint reachable (PASS/GAP), collection count and per-collection role
        coverage, registered integration runtimes, and registered data-source count — with a PASS/GAP
        line per signal to record against the Requirements checklist.
.NOTES
    Purview — Data Governance. Read-only against the Purview data-plane REST API. Verify your
    licensing/tenant: the Data Governance experience and its endpoints are evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PurviewAccount,                                  # short account name, e.g. contoso-purview
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

# --- Acquire a data-plane token safely (no secrets in code) ---------------------------------------
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host "Az.Accounts module not found. Install with: Install-Module Az.Accounts -Scope CurrentUser" -ForegroundColor Yellow
    return
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }

try {
    $token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
} catch {
    Write-Host ("Could not acquire a Purview data-plane token: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    return
}
$headers = @{ Authorization = "Bearer $token" }

function Invoke-Purview([string]$Path, [string]$Method = 'GET') {
    # Path is relative to the account endpoint; api-version is verified per your tenant's current API.
    Invoke-RestMethod -Method $Method -Uri ("{0}{1}" -f $Endpoint, $Path) -Headers $headers -ErrorAction Stop
}

Write-Host "`n=== Purview Data Governance — readiness discovery ===" -ForegroundColor Cyan
Write-Host ("Account endpoint : {0}" -f $Endpoint)

# 1) Endpoint reachable + collections
$collections = @()
try {
    $resp = Invoke-Purview '/account/collections?api-version=2019-11-01-preview'
    $collections = @($resp.value)
    Write-Host ("Endpoint         : PASS — reachable; {0} collection(s) found" -f $collections.Count) -ForegroundColor Green
} catch {
    Write-Host ("Endpoint         : GAP — not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Verify the account name, the current account API version for your tenant, and your Data reader role." -ForegroundColor Yellow
    return
}

# 2) Per-collection role coverage (metadata roles). Verify the current metadata-policy API for your tenant.
$rolesSeen = @{}
foreach ($c in $collections) {
    $name = $c.name; $friendly = $c.friendlyName
    Write-Host ("  Collection      : {0} ({1})" -f $friendly, $name)
    try {
        $policies = Invoke-Purview ("/policystore/metadataPolicies?collectionName={0}&api-version=2021-07-01-preview" -f $name)
        foreach ($p in @($policies.values)) {
            foreach ($att in @($p.properties.attributeRules)) {
                if ($att.id -match 'purviewmetadatarole_builtin_(?<r>[a-z-]+)') { $rolesSeen[$Matches.r] = $true }
            }
        }
    } catch {
        Write-Host ("    (role read skipped: {0})" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
}
$expected = 'collection-administrator','data-source-administrator','data-curator','data-reader'
foreach ($r in $expected) {
    $ok = $rolesSeen.ContainsKey($r)
    Write-Host ("  Role {0,-28}: {1}" -f $r, ($(if($ok){'PASS — assigned'}else{'GAP — verify assignment'}))) -ForegroundColor ($(if($ok){'Green'}else{'Yellow'}))
}

# 3) Registered integration runtimes
try {
    $irs = @((Invoke-Purview '/scan/integrationruntimes?api-version=2018-12-01-preview').value)
    Write-Host ("Integration RTs  : {0} registered" -f $irs.Count) -ForegroundColor ($(if($irs.Count -gt 0){'Green'}else{'Yellow'}))
    foreach ($ir in $irs) { Write-Host ("    - {0} ({1})" -f $ir.name, $ir.properties.type) }
} catch {
    Write-Host ("Integration RTs  : GAP — could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 4) Registered data sources
try {
    $sources = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    Write-Host ("Data sources     : {0} registered" -f $sources.Count) -ForegroundColor ($(if($sources.Count -gt 0){'Green'}else{'Yellow'}))
} catch {
    Write-Host ("Data sources     : GAP — could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`nRecord each signal against the Requirements checklist; remediate any GAP before registering sources or scanning." -ForegroundColor Cyan
Write-Host "Note: API versions above are examples — verify the current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
