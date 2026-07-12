<#
.SYNOPSIS
    ENTARCH-Validate.ps1 — check the tenant against the target-state reference-architecture blueprint.
.DESCRIPTION
    PURPOSE
        Read-only validation used in Stage 4 (Validate). It compares the tenant to the blueprint's
        target-state assumptions and prints PASS / WARN per check:
          • Break-glass — two cloud-only *.onmicrosoft.com emergency accounts present (anti-lockout, G4).
          • Mandated design groups — the '<Purpose> - <Scope> - <Stage>' groups the design names exist
            yet, OR are correctly deferred to the roadmap (distinguishes "missing (roadmap)" from
            "missing (should exist)").
          • Licensing — the licenses the design assumes (P1/P2, Governance, GSA, Verified ID) are
            actually present (*verify* — feature detection is a signal only).
          • Lock-out sweep — any existing All-users CA policy with NO exclusions the Zero Trust domain
            must reconcile.
        It changes NOTHING. It does not create groups, policies, or accounts — it only reports gaps for
        the Decision Record / roadmap.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTARCH-Validate.ps1 `
            -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com `
            -DesignGroup 'CA Persona - Admins - Steady','CA Exclusion - Break-Glass - Steady'
        Optional: -RequireP2   -RequireGovernance   (assert the design's license assumptions)
        Consents to Directory.Read.All, Policy.Read.All, User.Read.All, Group.Read.All (read-only).
    EXPECTED RESULTS
        PASS/WARN lines for break-glass, design groups, licensing, and the lock-out sweep. Every WARN is
        either resolved or captured as a roadmap prerequisite. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only. Design/assessment helper (not a deployment script).
#>
[CmdletBinding()]
param(
    [string[]]$BreakGlassUpn,
    [string[]]$DesignGroup = @('CA Exclusion - Break-Glass - Steady','CA Persona - Admins - Steady'),
    [switch]$RequireP2,
    [switch]$RequireGovernance
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Blueprint Validation (tenant vs. target state) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# --- Break-glass presence ---
Write-Host "`n-- Break-glass accounts (anti-lockout prerequisite, G4) --" -ForegroundColor Cyan
if ($BreakGlassUpn) {
    $found = 0
    foreach ($upn in $BreakGlassUpn) {
        $u = $null
        try { $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id,userPrincipalName,accountEnabled" -ErrorAction SilentlyContinue } catch {}
        if ($u.id) {
            $cloudOnly = ($u.userPrincipalName -like '*.onmicrosoft.com')
            Write-Host ("  PASS: {0} exists (enabled={1}, cloud-only={2})" -f $u.userPrincipalName, $u.accountEnabled, $cloudOnly) -ForegroundColor Green
            $found++
        } else {
            Write-Host ("  WARN: {0} NOT found." -f $upn) -ForegroundColor Red
        }
    }
    if ($found -lt 2) { Write-Host "  WARN: fewer than 2 break-glass accounts confirmed — record creation as 'Phase 0 - Foundation'." -ForegroundColor Red }
} else {
    Write-Host "  WARN: no -BreakGlassUpn supplied — cannot confirm. The design mandates two cloud-only accounts." -ForegroundColor Yellow
}

# --- Mandated design groups (present vs roadmap) ---
Write-Host "`n-- Mandated design groups (present, or deferred to roadmap) --" -ForegroundColor Cyan
foreach ($name in $DesignGroup) {
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$([uri]::EscapeDataString($name).Replace('%20',' '))'").value | Select-Object -First 1
    if ($g) { Write-Host ("  PASS: '{0}' exists" -f $name) -ForegroundColor Green }
    else    { Write-Host ("  INFO: '{0}' not present — expected if it is a roadmap item (built by ENTZTCA etc.)." -f $name) -ForegroundColor Yellow }
}

# --- Licensing assumptions ---
Write-Host "`n-- Licensing the design assumes (verify — detection is a signal only) --" -ForegroundColor Cyan
$plans = @()
try { $plans = ((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName } catch {}
$hasP1  = $plans -contains 'AAD_PREMIUM'
$hasP2  = $plans -contains 'AAD_PREMIUM_P2'
$hasGov = [bool]($plans -match 'Governance|IGA')
Write-Host ("  Entra ID P1: {0}   Entra ID P2: {1}   Governance: {2}" -f $hasP1, $hasP2, $hasGov) -ForegroundColor White
if ($RequireP2 -and -not $hasP2) { Write-Host "  WARN: design assumes P2 (risk CA / PIM) but P2 not detected — make license acquisition a Phase 0 prerequisite." -ForegroundColor Red }
if ($RequireGovernance -and -not $hasGov) { Write-Host "  WARN: design assumes Entra ID Governance but it is not detected — roadmap prerequisite before Phase 4." -ForegroundColor Red }

# --- Lock-out sweep on existing CA ---
Write-Host "`n-- Existing All-users CA policies with no exclusions (Zero Trust domain must reconcile) --" -ForegroundColor Cyan
$ca = @(); try { $ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value } catch {}
$flagged = 0
foreach ($p in $ca) {
    $allUsers = ($p.conditions.users.includeUsers -contains 'All')
    $excl = @($p.conditions.users.excludeUsers).Count + @($p.conditions.users.excludeGroups).Count
    if ($allUsers -and $excl -eq 0) { Write-Host ("  RED FLAG: '{0}' targets All users with NO exclusions." -f $p.displayName) -ForegroundColor Red; $flagged++ }
}
if (-not $flagged) { Write-Host "  none — no existing All-users lock-out risk detected." -ForegroundColor Green }

Write-Host "`nResolve every WARN, or capture it as an explicit roadmap prerequisite in 'Roadmap - Identity Foundation - Phased'." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
