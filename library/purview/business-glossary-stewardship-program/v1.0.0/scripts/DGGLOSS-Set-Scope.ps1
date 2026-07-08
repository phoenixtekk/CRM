<#
.SYNOPSIS
    DGGLOSS-Set-Scope.ps1 — Record the pilot glossary/stewardship scope manifest (read-only).
.DESCRIPTION
    PURPOSE
        Captures and validates the pilot scope you will configure against: the governance domain, the
        5-10 candidate terms / critical data elements, the owner/steward mapping, and the
        re-certification interval. Reads an optional CSV of candidate terms, checks each row is complete
        (name, definition, owner, steward), and writes a scope manifest JSON. Read-only with respect to
        Purview — it makes NO change to any domain, glossary, term, or role.
    HOW TO RUN
        .\DGGLOSS-Set-Scope.ps1 -Domain DGGLOSS-Domain-Pilot -TermCsv .\pilot-terms.csv `
            -RecertifyMonths 3 -OutFile .\DGGLOSS-scope.json
        pilot-terms.csv columns: TermName,Definition,Owner,Steward,CriticalDataElement
        (No Purview sign-in is required — this step only assembles and checks the local scope manifest.)
    EXPECTED RESULTS
        A printed per-term completeness check (OK / MISSING ...), a summary count, and a scope-manifest
        JSON written to -OutFile for the Configure/Validate/Report steps to consume. Non-zero MISSING
        rows are flagged so you complete them with the data owner before configuring.
.NOTES
    Purview — Data Governance. Read-only planning helper; assembles the scope manifest only. The
    authoritative MEANING/ownership of each term is the business data owner's decision, not this tool's.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Domain,          # e.g. DGGLOSS-Domain-Pilot
    [string]$TermCsv,                                        # optional CSV of candidate terms
    [int]$RecertifyMonths = 3,                               # re-certification interval for Published terms
    [string]$OutFile = ".\DGGLOSS-scope.json"
)

Write-Host "`n=== Purview — pilot glossary/stewardship scope ===" -ForegroundColor Cyan
Write-Host ("Governance domain   : {0}" -f $Domain)
Write-Host ("Re-certify interval : every {0} month(s)" -f $RecertifyMonths)

$terms = @()
$missing = 0

if ($TermCsv) {
    if (-not (Test-Path $TermCsv)) { Write-Host ("Term CSV not found: {0}" -f $TermCsv) -ForegroundColor Yellow; return }
    $rows = Import-Csv -Path $TermCsv
    Write-Host ("Candidate terms     : {0} row(s) from {1}" -f $rows.Count, $TermCsv)
    foreach ($r in $rows) {
        $gaps = @()
        if ([string]::IsNullOrWhiteSpace($r.TermName))   { $gaps += 'TermName' }
        if ([string]::IsNullOrWhiteSpace($r.Definition)) { $gaps += 'Definition' }
        if ([string]::IsNullOrWhiteSpace($r.Owner))      { $gaps += 'Owner' }
        if ([string]::IsNullOrWhiteSpace($r.Steward))    { $gaps += 'Steward' }
        if ($gaps.Count -eq 0) {
            Write-Host ("  OK      : {0}" -f $r.TermName) -ForegroundColor Green
        } else {
            $missing++
            Write-Host ("  MISSING : {0}  -> {1}" -f $r.TermName, ($gaps -join ', ')) -ForegroundColor Yellow
        }
        $terms += [pscustomobject]@{
            termName            = $r.TermName
            definition          = $r.Definition
            owner               = $r.Owner
            steward             = $r.Steward
            criticalDataElement = $r.CriticalDataElement
            initialStatus       = 'Draft'
        }
    }
} else {
    Write-Host "No -TermCsv supplied. The manifest will record the domain and interval only;" -ForegroundColor DarkGray
    Write-Host "add the 5-10 candidate terms (name/definition/owner/steward) before configuring." -ForegroundColor DarkGray
}

$manifest = [pscustomobject]@{
    generatedUtc     = (Get-Date).ToUniversalTime().ToString('o')
    governanceDomain = $Domain
    recertifyMonths  = $RecertifyMonths
    termCount        = $terms.Count
    incompleteTerms  = $missing
    terms            = $terms
}
$manifest | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutFile -Encoding utf8

Write-Host ""
Write-Host ("Terms captured      : {0} (incomplete: {1})" -f $terms.Count, $missing) -ForegroundColor ($(if($missing -eq 0){'Green'}else{'Yellow'}))
Write-Host ("Scope manifest      : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Cyan
if ($missing -gt 0) {
    Write-Host "Complete the MISSING rows with the data owner before running DGGLOSS-Configure-Glossary.ps1." -ForegroundColor Yellow
}
Write-Host "Note: this tool only assembles the scope; term MEANING and ownership are the business owner's determination." -ForegroundColor DarkGray
