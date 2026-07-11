<#
.SYNOPSIS
    SOAMDE-Validate.ps1 — self-check that the assessor has the READ access needed and NO write access.
.DESCRIPTION
    PURPOSE
        The read-only guarantee of the assessment. Confirms the current identity can (a) connect to
        Microsoft Graph with read scopes, (b) read the Defender for Endpoint machine list, and (c) run a
        trivial advanced-hunting query — and asserts that NO write/manage scope is present on the token.
        If any read fails, fix access before running the rest of the assessment. If a write scope is
        found, the assessor is over-privileged for an assessment and must be reduced to Security Reader.
    HOW TO RUN
        pwsh -File .\SOAMDE-Validate.ps1
        Requires the Microsoft.Graph modules. It prompts for interactive read-only consent if needed.
        For MDE-API checks over REST, sign in so a delegated token for the Defender API is available.
        *Verify current Graph/Defender scope names and RBAC model (unified Defender RBAC vs legacy).*
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. Read-only — makes no changes.
.NOTES
    White-label. Read-only. Makes no changes. Assessment access self-check.
#>
[CmdletBinding()]
param(
    [string[]]$ReadScopes = @(
        'SecurityEvents.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementManagedDevices.Read.All'
    ),
    # Write scopes that must NOT be present — an assessment must be read-only.
    [string[]]$ForbiddenScopePatterns = @('ReadWrite', 'Write', '.Manage', 'FullControl')
)

$ErrorActionPreference = 'Stop'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$Check, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Check; Result = ($(if ($Pass) { 'PASS' } else { 'FAIL' })); Detail = $Detail })
}

Write-Host "SOAMDE access validation (read-only)`n" -ForegroundColor Cyan

# --- Check 1: Graph connect with read scopes ---------------------------------
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes $ReadScopes -NoWelcome -ErrorAction Stop
    $ctx = Get-MgContext
    Add-Result 'Graph connect (read scopes)' $true "Connected as $($ctx.Account); scopes: $($ctx.Scopes -join ', ')"
} catch {
    Add-Result 'Graph connect (read scopes)' $false $_.Exception.Message
    $ctx = $null
}

# --- Check 2: NO write/manage scope present ----------------------------------
if ($ctx) {
    $granted = @($ctx.Scopes)
    $writeHits = $granted | Where-Object { $s = $_; $ForbiddenScopePatterns | Where-Object { $s -like "*$_*" } }
    if ($writeHits) {
        Add-Result 'No write scope (least privilege)' $false "Over-privileged: $($writeHits -join ', '). Reduce to Security Reader."
    } else {
        Add-Result 'No write scope (least privilege)' $true 'Only read scopes present.'
    }
}

# --- Check 3: MDE machine list readable (Defender API) ------------------------
# Uses the Defender for Endpoint API via Invoke-MgGraphRequest against the security API surface, or the
# WindowsDefenderATP REST endpoint if a delegated token is available. *Verify current API host.*
try {
    $machines = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/security/microsoftDefenderForEndpoint/machines?$top=1' -ErrorAction Stop
    $ok = $null -ne $machines
    Add-Result 'MDE machine list readable' $ok 'Machine query returned successfully.'
} catch {
    # Fallback note: some tenants expose machines only via api.securitycenter.microsoft.com (Machine.Read.All).
    Add-Result 'MDE machine list readable' $false "Could not read machines via Graph: $($_.Exception.Message). Confirm Security Reader / Machine.Read.All. *Verify API host.*"
}

# --- Check 4: Advanced hunting query returns ---------------------------------
try {
    $body = @{ Query = 'DeviceInfo | take 1' } | ConvertTo-Json
    $hunt = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json' -ErrorAction Stop
    Add-Result 'Advanced hunting query' $true 'Hunting query executed (DeviceInfo | take 1).'
} catch {
    Add-Result 'Advanced hunting query' $false "Hunting query failed: $($_.Exception.Message). Confirm AdvancedHunting.Read.All and hunting availability."
}

# --- Verdict -----------------------------------------------------------------
Write-Host "`n--- Validation results ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$failed = @($results | Where-Object Result -eq 'FAIL')
if ($failed.Count -eq 0) {
    Write-Host "`nALL CHECKS PASSED — assessor has read-only access. Proceed to SOAMDE-Discovery.ps1." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n$($failed.Count) check(s) FAILED — resolve before running the assessment (see Troubleshooting)." -ForegroundColor Yellow
    exit 1
}
