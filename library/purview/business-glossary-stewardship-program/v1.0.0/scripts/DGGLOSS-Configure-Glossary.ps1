<#
.SYNOPSIS
    DGGLOSS-Configure-Glossary.ps1 — Seed glossary terms in Draft or set a term's status (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Configures the business glossary for the pilot from the scope manifest: creates each candidate
        term IN DRAFT status with its definition, owner, and steward (-SeedTerms), or moves a single
        approved term to a new status such as Published (-SetStatus). SAFE BY DEFAULT: with no -Commit it
        runs in -WhatIf mode and prints the exact payload it WOULD send, changing nothing. Pass -Commit to
        write. No secrets in code — a data-plane token is acquired from your interactive Azure sign-in.
    HOW TO RUN
        Seed candidate terms in Draft (preview, changes nothing):
          .\DGGLOSS-Configure-Glossary.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGGLOSS-scope.json -SeedTerms
        Seed for real:
          .\DGGLOSS-Configure-Glossary.ps1 -PurviewAccount contoso-purview -ScopeFile .\DGGLOSS-scope.json -SeedTerms -Commit
        Publish an approved term (owner-approved only):
          .\DGGLOSS-Configure-Glossary.ps1 -PurviewAccount contoso-purview -TermGuid <guid> -SetStatus Published -Commit
        Requires Az.Accounts + Connect-AzAccount with Data steward / governance domain owner as appropriate.
    EXPECTED RESULTS
        Default: a printed "[WhatIf] would create/update ..." plan and NO change. With -Commit each term
        is created in Draft (or the named term's status is updated) and the script prints its name/GUID.
        Verify the current Atlas glossary / Unified Catalog API versions for your tenant — evolving.
.NOTES
    Purview — Data Governance. Writes gated behind -Commit; -WhatIf default; new terms are always Draft.
    Determinations (what a term MEANS, who OWNS it, whether it may be Published) are the owner's — this
    tool records their approved decisions, it does not make them.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [switch]$SeedTerms,
    [string]$ScopeFile = ".\DGGLOSS-scope.json",
    [string]$GlossaryGuid,                                   # target glossary; if omitted, first glossary is used
    # status change (single term)
    [string]$TermGuid,
    [ValidateSet('Draft','Approved','Published','Expired')]
    [string]$SetStatus,
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com",
    [switch]$Commit
)

if (-not ($SeedTerms -or $SetStatus)) {
    Write-Host "Choose one action: -SeedTerms (from -ScopeFile) or -SetStatus <status> (with -TermGuid)." -ForegroundColor Yellow; return
}
$whatIf = -not $Commit
$tag = if ($whatIf) { '[WhatIf]' } else { '[Commit]' }

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
$api = 'api-version=2022-03-01-preview'   # Atlas glossary — verify current version for your tenant

function Send-Glossary([string]$Method, [string]$Uri, [string]$Body) {
    if ($whatIf) {
        Write-Host "  $tag $Method $Uri" -ForegroundColor Yellow
        Write-Host "  $tag body:" -ForegroundColor Yellow; Write-Host $Body
    } else {
        try {
            $r = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body $Body -ErrorAction Stop
            Write-Host "  Applied." -ForegroundColor Green
            if ($r.guid) { Write-Host ("  guid: {0}" -f $r.guid) }
        } catch { Write-Host ("  FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    }
}

Write-Host "`n=== Purview — glossary configuration ($tag) ===" -ForegroundColor Cyan

# Resolve target glossary if seeding and none supplied
if ($SeedTerms -and -not $GlossaryGuid) {
    try {
        $gl = @(Invoke-RestMethod -Method GET -Uri "$Endpoint/catalog/api/atlas/v2/glossary?$api" -Headers $headers -ErrorAction Stop)
        if ($gl.Count -gt 0) { $GlossaryGuid = $gl[0].guid; Write-Host ("Target glossary  : {0} ({1})" -f $gl[0].name, $GlossaryGuid) }
        else { Write-Host "No glossary found; create one in the Unified Catalog first (verify current path)." -ForegroundColor Yellow; return }
    } catch { Write-Host ("Could not list glossaries: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return }
}

if ($SeedTerms) {
    if (-not (Test-Path $ScopeFile)) { Write-Host ("Scope file not found: {0}" -f $ScopeFile) -ForegroundColor Yellow; return }
    $scope = Get-Content $ScopeFile -Raw | ConvertFrom-Json
    if ($scope.incompleteTerms -gt 0) {
        Write-Host ("Scope has {0} incomplete term(s); complete them (DGGLOSS-Set-Scope.ps1) before seeding." -f $scope.incompleteTerms) -ForegroundColor Yellow
        return
    }
    Write-Host ("Seeding {0} term(s) in Draft into domain '{1}'." -f $scope.termCount, $scope.governanceDomain)
    foreach ($t in $scope.terms) {
        Write-Host ("Term             : '{0}' (owner {1} / steward {2})" -f $t.termName, $t.owner, $t.steward)
        # New terms are ALWAYS created Draft; ownership/steward recorded as attributes.
        $payload = @{
            name             = $t.termName
            shortDescription = $t.definition
            longDescription  = $t.definition
            status           = 'Draft'
            anchor           = @{ glossaryGuid = $GlossaryGuid }
            additionalAttributes = @{
                owner   = $t.owner
                steward = $t.steward
                cde     = "$($t.criticalDataElement)"
            }
        } | ConvertTo-Json -Depth 6
        Send-Glossary 'POST' "$Endpoint/catalog/api/atlas/v2/glossary/term?$api" $payload
    }
}

if ($SetStatus) {
    if (-not $TermGuid) { Write-Host "-SetStatus requires -TermGuid." -ForegroundColor Yellow; return }
    if ($SetStatus -eq 'Published' -and $whatIf) {
        Write-Host "  Note: Publishing must be OWNER-APPROVED. This -WhatIf preview changes nothing." -ForegroundColor DarkGray
    }
    Write-Host ("Set status       : term {0} -> {1}" -f $TermGuid, $SetStatus)
    $body = @{ status = $SetStatus } | ConvertTo-Json
    Send-Glossary 'PUT' "$Endpoint/catalog/api/atlas/v2/glossary/term/$TermGuid/partial?$api" $body
}

if ($whatIf) {
    Write-Host "`nNo change made. Re-run with -Commit to write. New terms are created in Draft; Publish only after owner approval." -ForegroundColor Cyan
    Write-Host "Confirm the current Atlas glossary / Unified Catalog API versions for your tenant first." -ForegroundColor DarkGray
}
