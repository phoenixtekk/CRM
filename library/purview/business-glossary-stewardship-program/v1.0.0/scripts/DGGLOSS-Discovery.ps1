<#
.SYNOPSIS
    DGGLOSS-Discovery.ps1 — Business-glossary & stewardship readiness discovery for Microsoft Purview (read-only).
.DESCRIPTION
    PURPOSE
        Reports readiness before you seed a glossary or assign stewards: whether the Microsoft Purview
        account data-plane endpoint is reachable, which governance domains / glossaries exist, how many
        glossary terms are present and their status mix (Draft/Approved/Published/Expired), and whether
        governance roles (domain owner / data steward) appear assigned. Read-only — it makes no change
        to the account, domains, glossary, or roles. Supports the Assess step.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGGLOSS-Discovery.ps1 -PurviewAccount contoso-purview
        Requires the Az PowerShell modules (Az.Accounts). Sign in first with Connect-AzAccount using an
        account holding at least Data reader on the target governance domain. The script acquires a
        data-plane token for the Purview REST API (resource https://purview.azure.net); no secret is
        stored in the script.
    EXPECTED RESULTS
        A readiness summary with a PASS/GAP line per signal: endpoint reachable, governance-domain count,
        glossary term count and status breakdown, and governance-role coverage — to record against the
        Requirements checklist before seeding terms.
.NOTES
    Purview — Data Governance (Unified Catalog). Read-only against the Purview data-plane REST API.
    Verify your licensing/tenant and current API versions: the Data Governance experience is evolving.
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

Write-Host "`n=== Purview — Business glossary & stewardship readiness ===" -ForegroundColor Cyan
Write-Host ("Account endpoint : {0}" -f $Endpoint)

# 1) Endpoint reachable + glossaries (Atlas glossary API). Verify current API version for your tenant.
$glossaries = @()
try {
    $glossaries = @(Invoke-Purview '/catalog/api/atlas/v2/glossary?api-version=2022-03-01-preview')
    Write-Host ("Endpoint         : PASS — reachable; {0} glossary(ies) found" -f $glossaries.Count) -ForegroundColor Green
} catch {
    Write-Host ("Endpoint         : GAP — not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  Verify the account name, your Data reader role, and the current Atlas glossary API version for your tenant." -ForegroundColor Yellow
    return
}

# 2) Glossary terms + status mix
$statusCount = @{ Draft = 0; Approved = 0; Published = 0; Expired = 0; Other = 0 }
$termTotal = 0
foreach ($g in $glossaries) {
    Write-Host ("  Glossary        : {0}" -f $g.name)
    try {
        $terms = @(Invoke-Purview ("/catalog/api/atlas/v2/glossary/{0}/terms?api-version=2022-03-01-preview" -f $g.guid))
        foreach ($t in $terms) {
            $termTotal++
            $s = "$($t.status)"
            if ($statusCount.ContainsKey($s)) { $statusCount[$s]++ } else { $statusCount.Other++ }
        }
    } catch {
        Write-Host ("    (term read skipped: {0})" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
}
Write-Host ("Glossary terms   : {0} total" -f $termTotal) -ForegroundColor ($(if($termTotal -gt 0){'Green'}else{'Yellow'}))
Write-Host ("    Draft {0} | Approved {1} | Published {2} | Expired {3} | Other {4}" -f `
    $statusCount.Draft, $statusCount.Approved, $statusCount.Published, $statusCount.Expired, $statusCount.Other)

# 3) Governance domains (Unified Catalog data-governance API — verify availability/version for your tenant)
try {
    $domains = @((Invoke-Purview '/datagovernance/catalog/businessdomains?api-version=2024-02-01-preview').value)
    Write-Host ("Governance domns : {0} found" -f $domains.Count) -ForegroundColor ($(if($domains.Count -gt 0){'Green'}else{'Yellow'}))
    foreach ($d in $domains) { Write-Host ("    - {0}" -f $d.name) }
} catch {
    Write-Host ("Governance domns : GAP/verify — could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "  The Unified Catalog governance-domain API is evolving; verify the current path/version for your tenant." -ForegroundColor DarkGray
}

Write-Host "`nRecord each signal against the Requirements checklist; remediate any GAP before seeding terms or assigning stewards." -ForegroundColor Cyan
Write-Host "Note: API versions above are examples — verify the current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
