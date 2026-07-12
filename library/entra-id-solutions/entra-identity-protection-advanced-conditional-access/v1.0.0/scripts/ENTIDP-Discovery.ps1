<#
.SYNOPSIS
    ENTIDP-Discovery.ps1 — inventory Conditional Access, Identity Protection, named locations, auth strengths, and auth contexts.
.DESCRIPTION
    PURPOSE
        Records the current advanced-access posture before any change: all Conditional Access policies
        and their state (report-only / enabled / disabled), whether Identity Protection risk signal is
        available, named locations, authentication strengths, and authentication contexts. This is the
        before-state you keep for rollback.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTIDP-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Read-only scopes:
        Policy.Read.All, IdentityRiskyUser.Read.All, IdentityRiskEvent.Read.All.
    EXPECTED RESULTS
        A printed inventory: CA policy names + state, count of risky users/detections (P2 signal),
        named locations, authentication strengths, and authentication contexts.
.NOTES
    White-label — Entra ID Solutions. Read-only against Graph. Verify Entra ID P2 availability.
#>
[CmdletBinding()] param()
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','IdentityRiskyUser.Read.All','IdentityRiskEvent.Read.All' -NoWelcome

Write-Host "`n=== ENTIDP — advanced-access posture (before-state) ===" -ForegroundColor Cyan

# Conditional Access policies + state
$cap = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value)
Write-Host ("Conditional Access policies    : {0}" -f $cap.Count)
$cap | Sort-Object state | ForEach-Object { Write-Host ("  [{0,-12}] {1}" -f $_.state, $_.displayName) }
$reportOnly = @($cap | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' })
Write-Host ("Report-only policies           : {0}" -f $reportOnly.Count) -ForegroundColor Green

# Identity Protection signal (P2)
try {
    $ru = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityProtection/riskyUsers?$top=50').value)
    $rd = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityProtection/riskDetections?$top=50').value)
    Write-Host ("Risky users (sample)           : {0}" -f $ru.Count)
    Write-Host ("Risk detections (sample)       : {0}" -f $rd.Count)
    if ($ru.Count -eq 0 -and $rd.Count -eq 0) { Write-Host "  No risk signal — verify Entra ID P2 is assigned to in-scope users." -ForegroundColor Yellow }
} catch { Write-Host "  Identity Protection query failed — verify Entra ID P2 licensing/permissions." -ForegroundColor Yellow }

# Named locations
$nl = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/namedLocations').value)
Write-Host ("Named locations                : {0}" -f $nl.Count)
$nl | ForEach-Object { Write-Host ("  - {0}" -f $_.displayName) }

# Authentication strengths
$as = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationStrengthPolicies').value)
Write-Host ("Authentication strengths       : {0}" -f $as.Count)
$as | ForEach-Object { Write-Host ("  - {0} [{1}]" -f $_.displayName, $_.policyType) }

# Authentication contexts
$ac = @((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/authenticationContextClassReferences').value)
Write-Host ("Authentication contexts        : {0}" -f $ac.Count)
$ac | ForEach-Object { Write-Host ("  - {0} ({1}) published={2}" -f $_.displayName, $_.id, $_.isAvailable) }

Write-Host "`nKeep this output as your before-state for rollback." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
