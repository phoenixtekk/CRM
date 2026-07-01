<#
.SYNOPSIS
    MSPSTACK-Report — Export stack-coverage and onboarding status to CSV.

    PURPOSE:
        Produces operating/validation evidence: a per-client view of stack coverage
        (PSA company present, RMM site present, agent count, patch ring bound,
        integration mapped) and overall onboarding status. Pulls from vendor REST
        APIs where supplied; otherwise emits a template CSV the practice can complete
        manually from the consoles.

    HOW TO RUN:
        .\MSPSTACK-Report.ps1 -PsaBaseUri 'https://psa.example' -PsaToken $psa `
            -RmmBaseUri 'https://rmm.example' -RmmToken $rmm -OutputPath .\mspstack-coverage.csv

        # Template only (no APIs):
        .\MSPSTACK-Report.ps1 -OutputPath .\mspstack-coverage.csv

    EXPECTED RESULTS:
        A CSV of per-client coverage and onboarding status, plus a console summary of
        how many clients are fully onboarded. Read-only — no changes are made.

.NOTES
    Managed — read-only.
#>

[CmdletBinding()]
param(
    [string]$PsaBaseUri,
    [string]$PsaToken,
    [string]$RmmBaseUri,
    [string]$RmmToken,
    [string]$OutputPath = ".\mspstack-coverage.csv"
)

$ErrorActionPreference = 'Stop'

function Invoke-Api {
    param([string]$Uri, [string]$Token)
    $headers = @{ Authorization = "Bearer $Token"; Accept = 'application/json' }
    return Invoke-RestMethod -Uri $Uri -Headers $headers -Method Get -TimeoutSec 30
}

Write-Host "=== MSPSTACK Report (read-only) ===" -ForegroundColor Cyan

$rows = New-Object System.Collections.Generic.List[object]

if ($PsaBaseUri -and $PsaToken -and $RmmBaseUri -and $RmmToken) {
    try {
        $companies = Invoke-Api -Uri "$($PsaBaseUri.TrimEnd('/'))/companies" -Token $PsaToken
        $sites     = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/sites" -Token $RmmToken
        $devices   = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/devices" -Token $RmmToken

        foreach ($c in $companies) {
            $expectedSite = "Client Site - $($c.name) - Production"
            $site = $sites | Where-Object { $_.name -eq $expectedSite }
            $agentCount = @($devices | Where-Object { $_.siteName -eq $expectedSite }).Count
            $hasSite = [bool]$site
            $onboarded = $hasSite -and $agentCount -gt 0

            $rows.Add([pscustomobject]@{
                Client            = $c.name
                PsaCompany        = $true
                RmmSite           = $hasSite
                ExpectedSiteName  = $expectedSite
                AgentCount        = $agentCount
                PatchRingBound    = if ($site) { [bool]$site.patchPolicyBound } else { $false }
                IntegrationMapped = $hasSite
                OnboardingStatus  = if ($onboarded) { 'Onboarded' } elseif ($hasSite) { 'Partial' } else { 'Not started' }
            })
        }
    } catch {
        Write-Warning "API query failed: $($_.Exception.Message). Emitting template instead."
    }
}

if ($rows.Count -eq 0) {
    Write-Host "No API data — emitting a template row to complete manually from the consoles." -ForegroundColor Yellow
    $rows.Add([pscustomobject]@{
        Client            = '<ClientName>'
        PsaCompany        = '<true/false>'
        RmmSite           = '<true/false>'
        ExpectedSiteName  = 'Client Site - <ClientName> - Production'
        AgentCount        = '<n>'
        PatchRingBound    = '<true/false>'
        IntegrationMapped = '<true/false>'
        OnboardingStatus  = '<Not started/Partial/Onboarded>'
    })
}

$rows | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

$onboarded = @($rows | Where-Object { $_.OnboardingStatus -eq 'Onboarded' }).Count
Write-Host ""
Write-Host "Clients reported : $($rows.Count)"
Write-Host "Fully onboarded  : $onboarded"
Write-Host "Saved to         : $OutputPath" -ForegroundColor Cyan
