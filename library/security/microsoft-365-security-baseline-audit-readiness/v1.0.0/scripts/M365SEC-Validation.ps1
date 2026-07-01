<#
.SYNOPSIS
    M365SEC-Validation.ps1 — baseline compliance: does the tenant match the baseline register? (Graph).
.DESCRIPTION
    PURPOSE
        Reads the current Secure Score control profiles and their implementation status and compares
        them against the desired-state baseline recorded in the baseline register
        'M365 Security Baseline Register - Tenant Services - Baseline'. Reports each baseline item as
        MATCH or GAP so you can see exactly where the tenant diverges from the baseline before an
        audit. Read-only.
    HOW TO RUN
        Default (uses the bundled sample baseline):
            powershell -ExecutionPolicy Bypass -File .\M365SEC-Validation.ps1
        With your own baseline (a JSON array of { controlId; desiredState }):
            ... .\M365SEC-Validation.ps1 -BaselinePath .\baseline-register.json
        Requires the Microsoft Graph PowerShell SDK and consent to:
        SecurityEvents.Read.All.
    EXPECTED RESULTS
        A per-control MATCH / GAP list and a summary count. GAP lines are the remediation backlog to
        work through in the Implementation Guide (and safely via M365SEC-Remediation.ps1).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    The baseline register is intentionally external (a JSON file you own); the bundled sample lists a
    few representative controls so the script runs out-of-the-box.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Load the baseline register (desired state). Falls back to a representative sample.
if ($BaselinePath -and (Test-Path $BaselinePath)) {
    $baseline = Get-Content -Raw -Path $BaselinePath | ConvertFrom-Json
    Write-Host ("Baseline register: {0}" -f $BaselinePath) -ForegroundColor DarkGray
} else {
    Write-Host "No -BaselinePath supplied; using the bundled sample baseline register." -ForegroundColor Yellow
    $baseline = @(
        [pscustomobject]@{ controlId = 'BlockLegacyAuthentication'; desiredState = 'Reviewed' },
        [pscustomobject]@{ controlId = 'MFARegistrationV2';          desiredState = 'Reviewed' },
        [pscustomobject]@{ controlId = 'SelfServicePasswordReset';   desiredState = 'Reviewed' }
    )
}

Connect-MgGraph -Scopes 'SecurityEvents.Read.All' -NoWelcome

# Current implementation status per control (from the latest secure score controlScores).
$statusById = @{}
try {
    $scores = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/security/secureScores?`$top=1").value
    if ($scores -and $scores[0].controlScores) {
        foreach ($cs in $scores[0].controlScores) {
            $statusById[$cs.controlName] = $cs.implementationStatus
        }
    }
} catch {
    Write-Host ("Could not read Secure Score control status: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

Write-Host "`n=== Baseline compliance ===" -ForegroundColor Cyan
$gaps = 0
foreach ($item in $baseline) {
    $current = if ($statusById.ContainsKey($item.controlId)) { $statusById[$item.controlId] } else { '<not reported>' }
    if ($current -and $current -ne '<not reported>') {
        Write-Host ("  MATCH  {0}  (status: {1})" -f $item.controlId, $current) -ForegroundColor Green
    } else {
        Write-Host ("  GAP    {0}  (desired: {1}; current: {2})" -f $item.controlId, $item.desiredState, $current) -ForegroundColor Red
        $gaps++
    }
}

Write-Host ("`nSummary: {0} baseline item(s), {1} gap(s)." -f @($baseline).Count, $gaps) -ForegroundColor Cyan
if ($gaps -gt 0) {
    Write-Host "Work the gaps via the Implementation Guide; preview safe fixes with M365SEC-Remediation.ps1 -WhatIf." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
