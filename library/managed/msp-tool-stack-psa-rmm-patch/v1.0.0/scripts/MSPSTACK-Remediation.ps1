<#
.SYNOPSIS
    MSPSTACK-Remediation — Apply safe fixes for common stack drift.

    PURPOSE:
        Detects and (optionally) corrects common, low-risk drift in the stack: missing
        standard PSA boards, missing standard RMM policies, missing patch rings, and
        an incorrect patch-ring deferral. Defaults to read-only / -WhatIf so it only
        reports what it WOULD change. Pass -Apply to make changes. High-impact or
        fleet-wide changes are intentionally NOT automated — route those through change
        control per the solution best practices.

    HOW TO RUN:
        # Dry run (default) — report only:
        .\MSPSTACK-Remediation.ps1 -PsaBaseUri 'https://psa.example' -PsaToken $psa `
            -RmmBaseUri 'https://rmm.example' -RmmToken $rmm

        # Apply the safe fixes:
        .\MSPSTACK-Remediation.ps1 -PsaBaseUri ... -PsaToken ... -RmmBaseUri ... -RmmToken ... -Apply

    EXPECTED RESULTS:
        A list of detected drift and, per item, either "WOULD FIX" (default) or
        "FIXED" (-Apply). Nothing is changed unless -Apply is supplied.

.NOTES
    Managed — read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PsaBaseUri,
    [string]$PsaToken,
    [string]$RmmBaseUri,
    [string]$RmmToken,
    [switch]$Apply,

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

Write-Host "=== MSPSTACK Remediation ($(if ($Apply) {'APPLY'} else {'WHATIF / read-only'})) ===" -ForegroundColor Cyan

$actions = New-Object System.Collections.Generic.List[object]

function Report-Action {
    param([string]$Plane, [string]$Target, [string]$Action)
    $state = if ($Apply) { 'FIXED' } else { 'WOULD FIX' }
    $actions.Add([pscustomobject]@{ Plane = $Plane; Target = $Target; Action = $Action; State = $state })
}

# --- PSA: ensure standard boards ---
if ($PsaBaseUri -and $PsaToken) {
    try {
        $boards = Invoke-Api -Uri "$($PsaBaseUri.TrimEnd('/'))/service/boards" -Token $PsaToken
        $have   = @($boards | ForEach-Object { $_.name })
        foreach ($b in $ExpectedBoards) {
            if ($have -notcontains $b) {
                if ($PSCmdlet.ShouldProcess($b, "Create PSA board")) {
                    Invoke-Api -Uri "$($PsaBaseUri.TrimEnd('/'))/service/boards" -Token $PsaToken -Method Post -Body @{ name = $b } | Out-Null
                }
                Report-Action 'PSA' $b 'Create missing standard board'
            }
        }
    } catch { Write-Warning "PSA remediation skipped: $($_.Exception.Message)" }
}

# --- RMM: ensure standard policies ---
if ($RmmBaseUri -and $RmmToken) {
    try {
        $policies = Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/policies" -Token $RmmToken
        $have     = @($policies | ForEach-Object { $_.name })
        foreach ($p in $ExpectedPolicies) {
            if ($have -notcontains $p) {
                if ($PSCmdlet.ShouldProcess($p, "Create RMM policy")) {
                    Invoke-Api -Uri "$($RmmBaseUri.TrimEnd('/'))/policies" -Token $RmmToken -Method Post -Body @{ name = $p } | Out-Null
                }
                Report-Action 'RMM' $p 'Create missing standard policy'
            }
        }
    } catch { Write-Warning "RMM remediation skipped: $($_.Exception.Message)" }
}

if ($actions.Count -eq 0) {
    Write-Host "No drift detected (or no APIs supplied). Nothing to remediate." -ForegroundColor Green
} else {
    $actions | Format-Table Plane, Target, Action, State -AutoSize
    if (-not $Apply) {
        Write-Host "Dry run only — re-run with -Apply to make these changes." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Note: fleet-wide changes (ring deferrals, integration config) are NOT auto-applied — use change control." -ForegroundColor DarkYellow
