<#
.SYNOPSIS
    MSPSTACK-Validation — Verify PSA / RMM / patch and integration health (PASS/FAIL).

    PURPOSE:
        Evaluates the machine-checkable validation items from the solution's Stage
        Validate: presence of the standard named objects, RMM agent check-in, patch
        ring deferrals, and PSA<->RMM integration connectivity. Emits a PASS/FAIL
        result per check and an overall verdict. Vendor REST endpoints are probed
        where supplied; Microsoft Graph is used when Intune is the patch engine.

    HOW TO RUN:
        # With vendor REST APIs:
        .\MSPSTACK-Validation.ps1 -PsaBaseUri 'https://psa.example' -PsaToken $psa `
            -RmmBaseUri 'https://rmm.example' -RmmToken $rmm

        # With Intune (Microsoft Graph) as the patch engine:
        .\MSPSTACK-Validation.ps1 -UseGraph -GraphToken $graph

    EXPECTED RESULTS:
        A table of checks each marked PASS or FAIL, plus an overall PASS only when
        every check passes. Read-only — no configuration is changed.

.NOTES
    Managed — read-only.
#>

[CmdletBinding()]
param(
    [string]$PsaBaseUri,
    [string]$PsaToken,
    [string]$RmmBaseUri,
    [string]$RmmToken,
    [switch]$UseGraph,
    [string]$GraphToken,
    [string]$GraphBaseUri = 'https://graph.microsoft.com/v1.0',

    [string[]]$ExpectedBoards = @(
        'Service Desk - Reactive - Triage',
        'Service Desk - Reactive - Dispatch',
        'Projects - Onboarding - Delivery',
        'NOC - Alerts - Automated'
    ),
    [string[]]$ExpectedPolicies = @(
        'Monitoring Policy - Workstation - Standard',
        'Monitoring Policy - Server - Standard',
        'Automation Policy - Maintenance - Nightly'
    ),
    [hashtable]$ExpectedRingDeferral = @{
        'Patch Ring - Pilot - Stage0'            = 0
        'Patch Ring - Early - Stage1'            = 3
        'Patch Ring - Broad - Stage2'            = 7
        'Patch Ring - Critical Servers - Stage3' = 7
    },
    [string]$IntegrationName = 'Integration - PSA-RMM - Bi-Directional'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Plane, [string]$Check, [bool]$Pass, [string]$Detail)
    $results.Add([pscustomobject]@{
        Plane  = $Plane
        Check  = $Check
        Result = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
}

function Invoke-Api {
    param([string]$Uri, [string]$Token, [string]$Scheme = 'Bearer')
    $headers = @{ Authorization = "$Scheme $Token"; Accept = 'application/json' }
    return Invoke-RestMethod -Uri $Uri -Headers $headers -Method Get -TimeoutSec 30
}

Write-Host "=== MSPSTACK Validation (read-only) ===" -ForegroundColor Cyan

# --- PSA: expected boards present ---
if ($PsaBaseUri -and $PsaToken) {
    try {
        $boards = Invoke-Api -Uri "$($PsaBaseUri.TrimEnd('/'))/service/boards" -Token $PsaToken
        $names  = @($boards | ForEach-Object { $_.name })
        foreach ($b in $ExpectedBoards) {
            Add-Result 'PSA' "Board '$b' present" ($names -contains $b) ("found: " + ($names -join ', '))
        }
    } catch {
        Add-Result 'PSA' 'Board query' $false $_.Exception.Message
    }
} else {
    Add-Result 'PSA' 'Board check' $false 'PSA API not supplied — verify manually per 05-testing.md V1.'
}

# --- RMM: expected policies + agent check-in ---
if ($RmmBaseUri -and $RmmToken) {
    try {
        $policies = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/policies" -Token $RmmToken
        $pnames   = @($policies | ForEach-Object { $_.name })
        foreach ($p in $ExpectedPolicies) {
            Add-Result 'RMM' "Policy '$p' present" ($pnames -contains $p) ''
        }
    } catch {
        Add-Result 'RMM' 'Policy query' $false $_.Exception.Message
    }
    try {
        $devices = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/devices" -Token $RmmToken
        $online  = @($devices | Where-Object { $_.online -eq $true }).Count
        Add-Result 'RMM' 'At least one device checking in' ($online -gt 0) "$online online"
    } catch {
        Add-Result 'RMM' 'Device query' $false $_.Exception.Message
    }
    try {
        $integrations = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/integrations" -Token $RmmToken
        $match = $integrations | Where-Object { $_.name -eq $IntegrationName -and $_.connected -eq $true }
        Add-Result 'Integration' "'$IntegrationName' connected" ([bool]$match) ''
    } catch {
        Add-Result 'Integration' 'Integration query' $false $_.Exception.Message
    }
} else {
    Add-Result 'RMM' 'Policy/agent check' $false 'RMM API not supplied — verify manually per 05-testing.md V2/V4.'
}

# --- Patch: ring deferrals via Intune/Graph ---
if ($UseGraph -and $GraphToken) {
    try {
        $uri = "$($GraphBaseUri.TrimEnd('/'))/deviceManagement/deviceConfigurations"
        $cfg = Invoke-Api -Uri $uri -Token $GraphToken
        $rings = $cfg.value | Where-Object { $_.displayName -like 'Patch Ring -*' }
        foreach ($name in $ExpectedRingDeferral.Keys) {
            $ring = $rings | Where-Object { $_.displayName -eq $name }
            if (-not $ring) { Add-Result 'Patch' "Ring '$name' present" $false 'not found'; continue }
            $expected = $ExpectedRingDeferral[$name]
            $actual   = $ring.qualityUpdatesDeferralPeriodInDays
            Add-Result 'Patch' "Ring '$name' deferral=$expected" ($actual -eq $expected) "actual=$actual"
        }
    } catch {
        Add-Result 'Patch' 'Graph update-ring query' $false $_.Exception.Message
    }
} else {
    Add-Result 'Patch' 'Ring check' $false 'Graph not supplied — verify manually per 05-testing.md V3.'
}

# --- Output ---
$results | Format-Table Plane, Check, Result, Detail -AutoSize

$failures = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
Write-Host ""
if ($failures -eq 0) {
    Write-Host "OVERALL: PASS — all checks passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — $failures check(s) failed. See 06-troubleshooting.md." -ForegroundColor Red
    exit 1
}
