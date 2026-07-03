<#
.SYNOPSIS
    HYBIDG-Validation.ps1 — verify the hybrid identity deployment targets the US Gov (GCC High) cloud.
.DESCRIPTION
    PURPOSE
        Asserts that an existing Hybrid Identity deployment is configured correctly for a GCC High
        tenant: connected to the US Gov Graph instance, a verified public domain exists, directory
        synchronization is enabled, and the sign-in method is readable. Read-only — no changes.
        Use it at the Configure gate and after any change.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HYBIDG-Validation.ps1
        (Graph scopes: Directory.Read.All, Domain.Read.All, Organization.Read.All; -Environment USGov)
    EXPECTED RESULTS
        A pass/fail list. All applicable checks should PASS before you move from Configure to Pilot.
        Any FAIL points to a wrong-cloud or misconfiguration issue to fix first.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov','USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$OutputPath = ".\HYBIDG-Validation-Report.txt"
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param([string]$Check,[bool]$Passed,[string]$Detail)
    $results.Add([pscustomobject]@{
        Check  = $Check
        Status = if ($Passed) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    })
    Write-Host ("[{0}] {1} — {2}" -f ($(if($Passed){'PASS'}else{'FAIL'}), $Check, $Detail)) -ForegroundColor ($(if($Passed){'Green'}else{'Red'}))
}

Write-Host "=== HYBIDG Validation (Government / GCC High) — Environment: $Environment ===" -ForegroundColor Cyan

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment $Environment `
        -Scopes 'Directory.Read.All','Domain.Read.All','Organization.Read.All' -NoWelcome

    $ctx = Get-MgContext
    # Confirm we are genuinely on the US Gov Graph environment, not Commercial.
    $graphEnv = ($ctx.Environment)
    $onGov = ($graphEnv -like '*USGov*')
    Add-Result 'Connected to US Gov Graph environment' $onGov "Environment: $graphEnv, Tenant: $($ctx.TenantId)"

    $domains = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/domains'
    $verified = @($domains.value | Where-Object { $_.isVerified -and $_.id -notlike '*.onmicrosoft.us' })
    Add-Result 'Verified public domain present' ($verified.Count -gt 0) `
        $(if($verified.Count -gt 0){($verified.id -join ', ')}else{'Only onmicrosoft.us / unverified domains'})

    $org = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/organization').value[0]
    Add-Result 'Directory synchronization enabled' ([bool]$org.onPremisesSyncEnabled) "onPremisesSyncEnabled: $($org.onPremisesSyncEnabled)"

    if ($org.onPremisesLastSyncDateTime) {
        $age = (New-TimeSpan -Start ([datetime]$org.onPremisesLastSyncDateTime) -End (Get-Date)).TotalHours
        Add-Result 'Recent sync (< 24h)' ($age -lt 24) "Last sync: $($org.onPremisesLastSyncDateTime) ($([math]::Round($age,1))h ago)"
    } else {
        Add-Result 'Recent sync (< 24h)' $false 'No onPremisesLastSyncDateTime reported'
    }

    # Sign-in method (informational): read domain authentication type where available.
    $fed = @($domains.value | Where-Object { $_.authenticationType -eq 'Federated' })
    Add-Result 'Sign-in method readable' $true `
        $(if($fed.Count -gt 0){"Federated domains: $($fed.id -join ', ')"}else{'Managed (PHS/PTA) — confirm method in Connect'})

    Disconnect-MgGraph | Out-Null
} catch {
    Add-Result 'Microsoft Graph US Gov validation' $false $_.Exception.Message
}

$fail = @($results | Where-Object Status -eq 'FAIL').Count
Write-Host "`n=== Summary: $($results.Count) checks, $fail FAIL ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$results | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Report written to $OutputPath"
if ($fail -gt 0) { exit 1 } else { exit 0 }
