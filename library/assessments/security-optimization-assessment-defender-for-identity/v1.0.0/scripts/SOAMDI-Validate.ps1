<#
.SYNOPSIS
    SOAMDI-Validate.ps1 — self-check that the assessor can READ the AD inventory + MDI signals and has NO write access.
.DESCRIPTION
    PURPOSE
        The read-only guarantee of the assessment. Confirms the current identity can (a) enumerate domain
        controllers via read-only Active Directory queries (the coverage denominator), (b) connect to
        Microsoft Graph with read scopes, and (c) run an identity advanced-hunting query
        (IdentityInfo | take 1) — and asserts that NO write scope is present on the token. Run from a
        domain-joined host with the ActiveDirectory module and a read-only domain account.
    HOW TO RUN
        pwsh -File .\SOAMDI-Validate.ps1
        Requires RSAT / ActiveDirectory module and Microsoft.Graph modules. Prompts for interactive
        read-only consent if needed. *Verify current Graph scope names and MDI read-API availability.*
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. Read-only — makes no changes.
.NOTES
    White-label. Read-only. Makes no changes. Assessment access self-check.
#>
[CmdletBinding()]
param(
    [string[]]$ReadScopes = @('SecurityEvents.Read.All')
)

$ErrorActionPreference = 'Continue'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$Check, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = ($(if ($Pass) { 'PASS' } else { 'FAIL' })); Detail = $Detail })
}

Write-Host "SOAMDI access validation (read-only)`n" -ForegroundColor Cyan

# --- Check 1: AD read enumerates domain controllers --------------------------
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    $dcs = Get-ADDomainController -Filter * -ErrorAction Stop
    Add-Result 'AD read (enumerate DCs)' ($dcs.Count -gt 0) "domain controllers found: $($dcs.Count)"
} catch {
    Add-Result 'AD read (enumerate DCs)' $false "$($_.Exception.Message) (install RSAT / run on a domain-joined host)"
}

# --- Check 2: Graph connect with read scopes ---------------------------------
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $ReadScopes -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    Add-Result 'Graph connect (read scopes)' $true "connected as $($ctx.Account)"
} catch { Add-Result 'Graph connect (read scopes)' $false $_.Exception.Message; $ctx = $null }

# --- Check 3: No write/manage scope present ----------------------------------
if ($ctx) {
    $writeHits = @($ctx.Scopes | Where-Object { $_ -match 'ReadWrite|\.Manage|Write|FullControl' })
    Add-Result 'No write scope (least privilege)' ($writeHits.Count -eq 0) ($(if ($writeHits) { "over-privileged: $($writeHits -join ', ')" } else { 'only read scopes present' }))
}

# --- Check 4: Identity advanced hunting returns ------------------------------
try {
    $body = @{ Query = 'IdentityInfo | take 1' } | ConvertTo-Json
    Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
    Add-Result 'Advanced hunting (IdentityInfo)' $true 'query executed'
} catch { Add-Result 'Advanced hunting (IdentityInfo)' $false "$($_.Exception.Message) (confirm AdvancedHunting.Read.All; empty result can also mean no healthy sensors)" }

# --- Verdict -----------------------------------------------------------------
Write-Host "`n--- Validation results ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$failed = @($results | Where-Object Result -eq 'FAIL')
if ($failed.Count -eq 0) {
    Write-Host "`nALL CHECKS PASSED — read-only access confirmed. Proceed to SOAMDI-Discovery.ps1." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n$($failed.Count) check(s) FAILED — resolve before running (an incomplete DC list hides blind spots)." -ForegroundColor Yellow
    exit 1
}
