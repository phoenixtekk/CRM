<#
.SYNOPSIS
    SOAREM-Remediate.ps1 — the GATED change helper. Defaults to a safe -WhatIf preview (touches
    nothing); applies a remediation to the named pilot scope ONLY on explicit -Apply, and refuses to
    enforce approval-gated/disruptive categories without -ConfirmDisruptive.
.DESCRIPTION
    PURPOSE
        Applies a single mapped remediation from the remediation plan to a PILOT scope, pilot-first and
        preview-gated. Safety model (do not weaken):
          * Default = PREVIEW. With no -Apply, the script only prints what WOULD change. No writes.
          * -Apply is required to make any change, and the change is confined to -PilotScope.
          * Approval-gated / disruptive categories (blocking policies, response actions, paid plans,
            RBAC/onboarding) additionally require -ConfirmDisruptive, and apply in MONITOR/AUDIT mode
            first where the control supports it.
          * A break-glass account must be excluded from any access/CA/session/RBAC tightening (caller's
            responsibility per Requirements R3) — the script warns if -BreakGlassUpn is not supplied.
        The per-finding write calls are provided as GUARDED STUBS (commented real calls) so this
        white-label template never performs an unexpected change; an operator fills in / confirms the
        exact call for their finding inside the gated block before enabling it.
    HOW TO RUN
        # Preview (safe, default) — touches nothing:
        .\SOAREM-Remediate.ps1 -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" `
            -FindingId "<finding id>" -PilotScope "Pilot Group - Defender SOA" -WhatIf
        # Apply to pilot (non-disruptive category):
        .\SOAREM-Remediate.ps1 -RemediationPlanPath "..." -FindingId "<id>" -PilotScope "..." -Apply
        # Apply an approval-gated/disruptive category (monitor/audit first):
        .\SOAREM-Remediate.ps1 -RemediationPlanPath "..." -FindingId "<id>" -PilotScope "..." `
            -Apply -ConfirmDisruptive -BreakGlassUpn "breakglass@contoso.onmicrosoft.com"
    EXPECTED RESULTS
        Preview: a printed description of the intended change; nothing altered.
        Apply: the change made ONLY within the pilot scope, in monitor/audit mode where supported, with
        a change record returned for the evidence report.
.NOTES
    White-label. WRITE occurs ONLY on -Apply. Production change-approval is the customer's decision.
    Keep this gating intact — weakening it defeats the purpose. Verify current cmdlets/scopes.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$RemediationPlanPath,
    [Parameter(Mandatory)][string]$FindingId,
    [Parameter(Mandatory)][string]$PilotScope,
    [switch]$Apply,
    [switch]$ConfirmDisruptive,
    [string]$BreakGlassUpn,
    [string]$OutputPath = ".\SOAREM-change-record.json"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $RemediationPlanPath)) { throw "Remediation plan not found: $RemediationPlanPath. Run SOAREM-Discovery.ps1 first." }
$plan = Get-Content $RemediationPlanPath -Raw | ConvertFrom-Json
$item = $plan.plan | Where-Object { $_.findingId -eq $FindingId } | Select-Object -First 1
if (-not $item) { throw "Finding id '$FindingId' not found in the remediation plan." }

Write-Host "SOAREM-Remediate — finding: $FindingId" -ForegroundColor Cyan
Write-Host ("  domain={0}  control={1}" -f $item.domain, $item.control)
Write-Host ("  remediation: {0}" -f $item.remediation)
Write-Host ("  gate={0}  disruptive={1}  monitorFirst={2}" -f $item.gate, $item.disruptive, $item.monitorFirst)
Write-Host ("  pilot scope: {0}" -f $PilotScope)

# --- SAFETY GATES ---------------------------------------------------------------------------------
if (-not $Apply) {
    Write-Host "`nPREVIEW MODE (no -Apply): nothing will be changed." -ForegroundColor Green
    Write-Host "WOULD apply the remediation above to the pilot scope only." -ForegroundColor Green
    if ($item.disruptive) {
        Write-Host "This is an APPROVAL-GATED/DISRUPTIVE category — enforcing it will additionally require -ConfirmDisruptive and would apply in monitor/audit first." -ForegroundColor Yellow
    }
    return
}

if ($item.disruptive -and -not $ConfirmDisruptive) {
    throw "Finding '$FindingId' is approval-gated/disruptive. Re-run with -ConfirmDisruptive (and change-approval per Requirements R2). It will apply in monitor/audit first where supported."
}
if ($item.disruptive -and -not $BreakGlassUpn) {
    Write-Warning "No -BreakGlassUpn supplied. Ensure a break-glass account is EXCLUDED from any access/CA/session/RBAC tightening (Requirements R3) before proceeding."
}

# --- GATED APPLY (pilot scope only) ---------------------------------------------------------------
# The exact write call is finding-specific. Below is the guarded dispatch: real calls are provided as
# COMMENTED STUBS so this template never performs an unexpected change. An operator uncomments/fills
# the correct call for their finding, confined to $PilotScope and (for disruptive) monitor/audit mode.
$changeMade = $false
$changeDetail = "No write performed (stub not enabled)."

if ($PSCmdlet.ShouldProcess("$PilotScope", "Apply remediation '$($item.remediation)' for finding $FindingId")) {
    switch ($item.domain) {
        'appGovernanceOAuth' {
            # STUB (Graph write scope required, e.g. Policy.ReadWrite.*). Create OAuth-app policy scoped to pilot.
            # Example (enable after review, confine to pilot):
            #   Connect-MgGraph -Scopes "Policy.ReadWrite.PermissionGrant"
            #   New-MgPolicyPermissionGrantPolicy -DisplayName "SOAREM OAuth pilot" ...
            $changeDetail = "STUB: would create OAuth-app policy scoped to '$PilotScope'. Enable the guarded call after review."
        }
        'sessionAccessPolicies' {
            # STUB: create Conditional Access App Control session/access policy in MONITOR mode for the pilot group.
            $changeDetail = "STUB: would create session/access policy in MONITOR for '$PilotScope'. Move to enforce only after a clean pilot."
        }
        'planCoverage' {
            # STUB (Az, Contributor at pilot subscription). Enable the workload plan on the pilot subscription only.
            #   Set-AzSecurityPricing -Name '<plan>' -PricingTier 'Standard'   # confine to pilot subscription context
            $changeDetail = "STUB: would enable the workload plan on pilot subscription '$PilotScope' (has cost — approval required)."
        }
        'agentCoverage' {
            # STUB: enable agentless scanning / onboard agent on the pilot scope.
            $changeDetail = "STUB: would enable agentless scanning / onboard agent for '$PilotScope'."
        }
        'unifiedRbac' {
            # STUB: activate unified RBAC / assign least-privilege role to a pilot principal. Exclude break-glass.
            $changeDetail = "STUB: would assign least-privilege unified-RBAC role within '$PilotScope' (exclude $BreakGlassUpn)."
        }
        default {
            $changeDetail = "STUB: would apply '$($item.remediation)' scoped to '$PilotScope'. Fill the guarded call for this domain."
        }
    }
    # $changeMade stays $false until an operator enables a real guarded call above — deliberate safety default.
    Write-Host "`nAPPLY (gated): $changeDetail" -ForegroundColor Yellow
    Write-Host "NOTE: real write calls are commented stubs in this template — enable the correct one for your finding, confined to the pilot scope, before it takes effect." -ForegroundColor Yellow
}

$appliedBy = $env:USERNAME
try { $mgCtx = Get-MgContext; if ($mgCtx) { $appliedBy = $mgCtx.Account } } catch { }

$record = [ordered]@{
    solution     = "SOAREM"
    findingId    = $FindingId
    domain       = $item.domain
    control      = $item.control
    remediation  = $item.remediation
    pilotScope   = $PilotScope
    applyRequested = [bool]$Apply
    confirmDisruptive = [bool]$ConfirmDisruptive
    breakGlassExcluded = $BreakGlassUpn
    changeMade   = $changeMade
    changeDetail = $changeDetail
    whatIf       = -not $Apply
    appliedBy    = $appliedBy
    appliedUtc   = (Get-Date).ToUniversalTime().ToString("o")
}
$record | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Change record written: $OutputPath (feeds the evidence report)." -ForegroundColor Green
