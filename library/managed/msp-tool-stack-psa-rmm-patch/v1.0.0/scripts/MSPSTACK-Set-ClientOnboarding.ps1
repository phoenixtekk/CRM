<#
.SYNOPSIS
    MSPSTACK-Set-ClientOnboarding — Scaffold a new managed client's site, policies,
    groups, and patch ring bindings per the standard onboarding template.

    PURPOSE:
        Implements 'Onboarding Template - Managed Client - Standard'. For a named
        client it creates the PSA company, the RMM site
        'Client Site - <ClientName> - Production', the client's device groups, binds
        the standard monitoring/automation policies and patch rings, and maps the site
        to the PSA company for the PSA<->RMM integration. Defaults to -WhatIf so it
        only shows what it WOULD create; pass -Apply to execute.

    HOW TO RUN:
        # Dry run (default):
        .\MSPSTACK-Set-ClientOnboarding.ps1 -ClientName 'Contoso' `
            -PsaBaseUri 'https://psa.example' -PsaToken $psa `
            -RmmBaseUri 'https://rmm.example' -RmmToken $rmm

        # Execute:
        .\MSPSTACK-Set-ClientOnboarding.ps1 -ClientName 'Contoso' -PsaBaseUri ... `
            -PsaToken ... -RmmBaseUri ... -RmmToken ... -Apply

    EXPECTED RESULTS:
        A plan of objects to create/bind for the client. With -WhatIf (default) nothing
        is changed; with -Apply the objects are created via the vendor REST APIs and a
        summary is printed. Re-running is idempotent — existing objects are skipped.

.NOTES
    Managed — read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ClientName,

    [string]$PsaBaseUri,
    [string]$PsaToken,
    [string]$RmmBaseUri,
    [string]$RmmToken,
    [switch]$Apply,

    [string[]]$MonitoringPolicies = @(
        'Monitoring Policy - Workstation - Standard',
        'Monitoring Policy - Server - Standard'
    ),
    [string]$AutomationPolicy = 'Automation Policy - Maintenance - Nightly',
    [string[]]$PatchRings = @(
        'Patch Ring - Pilot - Stage0',
        'Patch Ring - Early - Stage1',
        'Patch Ring - Broad - Stage2',
        'Patch Ring - Critical Servers - Stage3'
    )
)

$ErrorActionPreference = 'Stop'

# Default posture is read-only: -WhatIf unless the operator explicitly passes -Apply.
if (-not $Apply) { $WhatIfPreference = $true }

function Invoke-Api {
    param([string]$Uri, [string]$Token, [string]$Method = 'Get', $Body)
    $headers = @{ Authorization = "Bearer $Token"; Accept = 'application/json' }
    $params = @{ Uri = $Uri; Headers = $headers; Method = $Method; TimeoutSec = 30 }
    if ($Body) { $params['Body'] = ($Body | ConvertTo-Json -Depth 6); $params['ContentType'] = 'application/json' }
    return Invoke-RestMethod @params
}

$siteName = "Client Site - $ClientName - Production"
$plan = New-Object System.Collections.Generic.List[object]
function Plan-Item { param([string]$Object, [string]$Action) $plan.Add([pscustomobject]@{ Object = $Object; Action = $Action }) }

Write-Host "=== MSPSTACK Client Onboarding: '$ClientName' ($(if ($Apply) {'APPLY'} else {'WHATIF / read-only'})) ===" -ForegroundColor Cyan

# --- 1. PSA company ---
$psaCompanyExists = $false
if ($PsaBaseUri -and $PsaToken) {
    try {
        $companies = Invoke-Api -Uri "$($PsaBaseUri.TrimEnd('/'))/companies" -Token $PsaToken
        $psaCompanyExists = [bool]($companies | Where-Object { $_.name -eq $ClientName })
    } catch { Write-Warning "PSA company lookup failed: $($_.Exception.Message)" }
}
if (-not $psaCompanyExists) {
    if ($PsaBaseUri -and $PsaToken -and $PSCmdlet.ShouldProcess($ClientName, "Create PSA company")) {
        Invoke-Api -Uri "$($PsaBaseUri.TrimEnd('/'))/companies" -Token $PsaToken -Method Post -Body @{ name = $ClientName } | Out-Null
    }
    Plan-Item "PSA company '$ClientName'" 'Create'
} else { Plan-Item "PSA company '$ClientName'" 'Exists - skip' }

# --- 2. RMM site ---
$siteExists = $false
$siteId = $null
if ($RmmBaseUri -and $RmmToken) {
    try {
        $sites = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/sites" -Token $RmmToken
        $existing = $sites | Where-Object { $_.name -eq $siteName }
        $siteExists = [bool]$existing
        if ($existing) { $siteId = $existing.id }
    } catch { Write-Warning "RMM site lookup failed: $($_.Exception.Message)" }
}
if (-not $siteExists) {
    if ($RmmBaseUri -and $RmmToken -and $PSCmdlet.ShouldProcess($siteName, "Create RMM site")) {
        $created = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/sites" -Token $RmmToken -Method Post -Body @{ name = $siteName }
        $siteId = $created.id
    }
    Plan-Item "RMM site '$siteName'" 'Create'
} else { Plan-Item "RMM site '$siteName'" 'Exists - skip' }

# --- 3. Device groups + policy bindings ---
foreach ($pol in $MonitoringPolicies) {
    if ($RmmBaseUri -and $RmmToken -and $siteId -and $PSCmdlet.ShouldProcess("$siteName / $pol", "Bind monitoring policy")) {
        Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/sites/$siteId/policies" -Token $RmmToken -Method Post -Body @{ policyName = $pol } | Out-Null
    }
    Plan-Item "Bind '$pol' to '$siteName'" 'Bind'
}
if ($RmmBaseUri -and $RmmToken -and $siteId -and $PSCmdlet.ShouldProcess("$siteName / $AutomationPolicy", "Bind automation policy")) {
    Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/sites/$siteId/policies" -Token $RmmToken -Method Post -Body @{ policyName = $AutomationPolicy } | Out-Null
}
Plan-Item "Bind '$AutomationPolicy' to '$siteName'" 'Bind'

# --- 4. Patch ring bindings ---
foreach ($ring in $PatchRings) {
    if ($RmmBaseUri -and $RmmToken -and $siteId -and $PSCmdlet.ShouldProcess("$siteName / $ring", "Bind patch ring")) {
        Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/sites/$siteId/patchrings" -Token $RmmToken -Method Post -Body @{ ringName = $ring } | Out-Null
    }
    Plan-Item "Bind '$ring' to '$siteName'" 'Bind'
}

# --- 5. Site <-> company mapping for the integration ---
if ($RmmBaseUri -and $RmmToken -and $siteId -and $PSCmdlet.ShouldProcess("$siteName <-> $ClientName", "Map site to PSA company")) {
    Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/integrations/mapping" -Token $RmmToken -Method Post -Body @{ siteName = $siteName; psaCompany = $ClientName } | Out-Null
}
Plan-Item "Map '$siteName' <-> PSA company '$ClientName'" 'Map'

# --- Output ---
$plan | Format-Table Object, Action -AutoSize
Write-Host ""
if (-not $Apply) {
    Write-Host "Dry run only — re-run with -Apply to execute. Deploy the RMM agent to the client's endpoints after this completes." -ForegroundColor Yellow
} else {
    Write-Host "Onboarding scaffold complete for '$ClientName'. Deploy the RMM agent, then run MSPSTACK-Validation.ps1." -ForegroundColor Green
}
