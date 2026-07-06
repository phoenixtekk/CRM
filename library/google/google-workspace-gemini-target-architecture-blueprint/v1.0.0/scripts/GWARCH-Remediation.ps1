<#
.SYNOPSIS
    GWARCH-Remediation.ps1 — safe, guidance-first remediation for architecture-conformance gaps (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Turns the FAIL findings from GWARCH-Validation.ps1 into ordered, safe remediation guidance for
        closing target-architecture conformance gaps (single identity source, break-glass admin,
        scope-based targeting, bounded coexistence). It defaults to -WhatIf and PRINTS the recommended
        steps and any candidate source-side action without changing anything. Most fixes are design or
        target-side decisions and are deliberately surfaced as guidance for ARB action, never auto-applied.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Remediation.ps1
        powershell -ExecutionPolicy Bypass -File .\GWARCH-Remediation.ps1 -ValidationPath .\gwarch-validation.json
        By default nothing is changed (-WhatIf on). To allow any explicitly supported source-side action,
        re-run with -WhatIf:$false AFTER ARB review. Graph scopes only needed if you opt into an action.
    EXPECTED RESULTS
        A prioritized remediation plan per FAIL. In default -WhatIf mode: guidance only, no changes.
        pass = every referenced gap has an owner and a recorded next step (ADR or fix).
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$ValidationPath = ".\gwarch-validation.json"
)

# Default to -WhatIf unless the caller explicitly turned it off.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
$ErrorActionPreference = 'Stop'

Write-Host "GWARCH-Remediation — guidance-first (defaults to -WhatIf; no changes unless -WhatIf:`$false)" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  Mode: WhatIf (guidance only, no changes)" -ForegroundColor Yellow }
else { Write-Host "  Mode: LIVE — supported source-side actions may be attempted after your confirmation." -ForegroundColor Red }

if (-not (Test-Path $ValidationPath)) {
    Write-Host "Validation report not found at $ValidationPath — run GWARCH-Validation.ps1 first." -ForegroundColor Yellow
    return
}
$val = Get-Content $ValidationPath -Raw | ConvertFrom-Json
$fails = @($val.checks | Where-Object { $_.status -eq 'FAIL' })

# Remediation playbook keyed by check id — deliberately guidance, not silent automation.
$playbook = @{
    'C1' = @{
        title = 'Collapse competing identity sources (GWARCH-ID-1)'
        steps = @(
            'Record ADR GWARCH-ADR-ID-01 naming the single authoritative source of truth.',
            'Map every cloud-only account to the authoritative source or formally exempt it (service accounts).',
            'Route all provisioning through one pipeline (SCIM/GCDS/Admin SDK); remove shadow provisioning.',
            'Re-run GWARCH-Validation.ps1 until C1 = PASS.'
        )
        action = 'Design/target-side decision — no source-side auto-change.'
    }
    'C2' = @{
        title = 'Establish break-glass admin independent of the federated IdP (GWARCH-ID-2)'
        steps = @(
            'Create/confirm a cloud-only privileged emergency account not dependent on the federated IdP.',
            'Store its credentials under break-glass controls; exclude it from federation/Conditional Access that could lock it out.',
            'Test the break-glass sign-in after every federation change.',
            'Re-run GWARCH-Validation.ps1 until C2 = PASS.'
        )
        action = 'Privileged change — perform manually under change control; not auto-applied.'
    }
    'C3' = @{
        title = 'Define the GWARCH-Scope taxonomy (GWARCH-P3)'
        steps = @(
            'Record ADR GWARCH-ADR-SCOPE-01 with the OU/group taxonomy (pilot, per-wave, regulated scopes).',
            'Create the control groups; align source groups so GWARCH-Set-ScopeTargeting.ps1 maps cleanly.',
            'Bind all policy (sharing, DLP, retention, Gemini access) to scopes, not individuals.'
        )
        action = 'Design decision — author the taxonomy; no source-side auto-change.'
    }
}

if ($fails.Count -eq 0) {
    Write-Host ""
    Write-Host "No FAILs in the validation report. Remaining coverage is ARB design-review (Gates 3-7)." -ForegroundColor Green
    return
}

$order = 0
foreach ($f in $fails) {
    $order++
    $p = $playbook[$f.id]
    Write-Host ""
    Write-Host ("[{0}] Gap: {1} ({2})" -f $order, $f.check, $f.principle) -ForegroundColor Red
    Write-Host ("     Finding: {0}" -f $f.detail)
    if ($p) {
        Write-Host ("     Remediation: {0}" -f $p.title) -ForegroundColor Cyan
        $n = 0; foreach ($s in $p.steps) { $n++; Write-Host ("       {0}. {1}" -f $n, $s) }
        Write-Host ("     Action class: {0}" -f $p.action) -ForegroundColor Yellow
        # Even for any "supported" action, gate behind ShouldProcess so -WhatIf blocks it by default.
        if ($PSCmdlet.ShouldProcess($f.check, "Apply remediation guidance action")) {
            Write-Host "       (LIVE) This gap requires a human design/privileged decision — no automatic change is performed by this script." -ForegroundColor Magenta
        } else {
            Write-Host "       (WhatIf) Would surface the above steps for ARB action; no change made." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "     No scripted playbook for this check id — resolve as an ARB design decision and record an ADR." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host ("Remediation guidance produced for {0} gap(s)." -f $fails.Count) -ForegroundColor Green
Write-Host "Every gap must end as either a recorded fix or an ARB exception ADR (GWARCH-P1)."
if ($WhatIfPreference) { Write-Host "No changes were made (WhatIf mode)." -ForegroundColor Yellow }
