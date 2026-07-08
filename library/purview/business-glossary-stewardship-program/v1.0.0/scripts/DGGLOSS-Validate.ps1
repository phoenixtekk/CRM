<#
.SYNOPSIS
    DGGLOSS-Validate.ps1 — Validate glossary terms against the pilot stewardship gate (read-only).
.DESCRIPTION
    PURPOSE
        Checks the glossary against the pilot pass/fail gate: every term has a non-empty definition, a
        named owner and steward, and a valid status; and every PUBLISHED term is fully complete (the
        outward-facing bar). Optionally validates only the terms named in a scope manifest. Read-only —
        it makes NO change; it reports PASS/FAIL per check so you can record the validation evidence.
    HOW TO RUN
        .\DGGLOSS-Validate.ps1 -PurviewAccount contoso-purview
        Scope to the pilot's terms only:
          .\DGGLOSS-Validate.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGGLOSS-scope.json
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the domain. A data-plane
        token is acquired from your sign-in; no secret is stored in the script.
    EXPECTED RESULTS
        A per-term PASS/FAIL table (definition / owner / steward / status) plus a Published-completeness
        summary and an overall gate verdict. Any FAIL identifies exactly which property to fix before the
        pilot can pass.
.NOTES
    Purview — Data Governance. Read-only validation. Verify current Atlas glossary API versions for your
    tenant. This tool tests COMPLETENESS of stewardship metadata, not the correctness of a definition —
    the authoritative meaning remains the data owner's determination.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$ScopeFile,
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token" }
$api = 'api-version=2022-03-01-preview'   # Atlas glossary — verify current version for your tenant

$onlyTerms = $null
if ($ScopeFile -and (Test-Path $ScopeFile)) {
    $onlyTerms = (Get-Content $ScopeFile -Raw | ConvertFrom-Json).terms.termName
}

Write-Host "`n=== Purview — glossary stewardship validation ===" -ForegroundColor Cyan

# Gather terms across all glossaries
$allTerms = @()
try {
    $glossaries = @(Invoke-RestMethod -Method GET -Uri "$Endpoint/catalog/api/atlas/v2/glossary?$api" -Headers $headers -ErrorAction Stop)
    foreach ($g in $glossaries) {
        $terms = @(Invoke-RestMethod -Method GET -Uri "$Endpoint/catalog/api/atlas/v2/glossary/$($g.guid)/terms?$api" -Headers $headers -ErrorAction Stop)
        $allTerms += $terms
    }
} catch {
    Write-Host ("Could not read glossary/terms: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Verify your role and the current Atlas glossary API version for your tenant." -ForegroundColor DarkGray
    return
}

if ($onlyTerms) { $allTerms = $allTerms | Where-Object { $onlyTerms -contains $_.name } }
if (-not $allTerms -or $allTerms.Count -eq 0) { Write-Host "No terms found to validate." -ForegroundColor Yellow; return }

$fail = 0; $publishedIncomplete = 0
Write-Host ("{0,-28} {1,-10} {2,-6} {3,-6} {4,-6}" -f 'Term','Status','Def','Owner','Steward')
Write-Host ("{0}" -f ('-' * 62))
foreach ($t in $allTerms) {
    $def     = -not [string]::IsNullOrWhiteSpace($t.shortDescription) -or -not [string]::IsNullOrWhiteSpace($t.longDescription)
    $owner   = -not [string]::IsNullOrWhiteSpace("$($t.additionalAttributes.owner)")
    $steward = -not [string]::IsNullOrWhiteSpace("$($t.additionalAttributes.steward)")
    $status  = "$($t.status)"
    $rowFail = -not ($def -and $owner -and $steward)
    if ($rowFail) { $fail++ }
    if ($status -eq 'Published' -and $rowFail) { $publishedIncomplete++ }
    $mark = { param($b) if ($b) { 'PASS' } else { 'FAIL' } }
    $color = if ($rowFail) { 'Yellow' } else { 'Green' }
    Write-Host ("{0,-28} {1,-10} {2,-6} {3,-6} {4,-6}" -f `
        ($t.name.Substring(0,[Math]::Min(27,$t.name.Length))), $status, (& $mark $def), (& $mark $owner), (& $mark $steward)) -ForegroundColor $color
}

Write-Host ("`nTerms checked        : {0}" -f $allTerms.Count)
Write-Host ("Incomplete terms     : {0}" -f $fail) -ForegroundColor ($(if($fail -eq 0){'Green'}else{'Yellow'}))
Write-Host ("Published-incomplete : {0}" -f $publishedIncomplete) -ForegroundColor ($(if($publishedIncomplete -eq 0){'Green'}else{'Red'}))

if ($publishedIncomplete -gt 0) {
    Write-Host "`nGATE: FAIL — a Published term is missing definition/owner/steward. Return it to Draft, fix, re-approve." -ForegroundColor Red
} elseif ($fail -gt 0) {
    Write-Host "`nGATE: PARTIAL — Published terms are complete, but some Draft/Review terms need definition/owner/steward before publishing." -ForegroundColor Yellow
} else {
    Write-Host "`nGATE: PASS — every term has a definition, owner, and steward." -ForegroundColor Green
}
Write-Host "Note: completeness only — the authoritative correctness of a definition is the data owner's determination." -ForegroundColor DarkGray
