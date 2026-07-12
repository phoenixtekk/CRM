<#
.SYNOPSIS
    ENTARCH-PrivilegedAccessReview.ps1 — assess privileged access to inform the admin-tiering/PIM model.
.DESCRIPTION
    PURPOSE
        Read-only review that grounds the privileged-access domain (Domain 4) of the architecture. It
        enumerates:
          • Directory role assignments that are PERMANENT (active) vs. PIM-ELIGIBLE (just-in-time).
          • The Global Administrator population (Microsoft guidance: keep this small — a design driver).
          • Highly-privileged SERVICE PRINCIPALS holding sensitive app roles (e.g. directory write).
          • Whether cloud-only BREAK-GLASS accounts appear to exist (anti-lockout prerequisite, G4).
        Findings drive ADR-009..012 (tiering, PIM eligibility/activation, break-glass, PAW). It changes
        NOTHING. PIM eligibility reads require Entra ID P2 — *verify availability in your tenant*.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTARCH-PrivilegedAccessReview.ps1
        Optional: -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com
        Consents to RoleManagement.Read.Directory, Directory.Read.All, User.Read.All (all read-only).
        No changes are made.
    EXPECTED RESULTS
        Printed counts of permanent vs. eligible privileged assignments, the GA count, privileged
        service principals, and a break-glass presence check. Nothing is modified.
.NOTES
    White-label — Entra ID Solutions. Read-only. Design/assessment helper (not a deployment script).
#>
[CmdletBinding()]
param(
    [string[]]$BreakGlassUpn
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','Directory.Read.All','User.Read.All' -NoWelcome

Write-Host "`n=== Privileged Access Review — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Role definitions (id -> displayName)
$roleDefs = @{}
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleDefinitions?$select=id,displayName').value |
    ForEach-Object { $roleDefs[$_.id] = $_.displayName }

# --- Permanent (active) directory role assignments ---
Write-Host "`n-- Permanent (active) privileged assignments --" -ForegroundColor Cyan
$active = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignments?$top=999').value
$activeByRole = $active | Group-Object roleDefinitionId | Sort-Object Count -Descending
foreach ($g in $activeByRole) {
    $name = $roleDefs[$g.Name]; if (-not $name) { $name = $g.Name }
    Write-Host ("  • {0,-45} {1} permanent" -f $name, $g.Count) -ForegroundColor White
}
Write-Host ("  TOTAL permanent role assignments: {0}" -f $active.Count) -ForegroundColor White
if ($active.Count -gt 0) { Write-Host "     → permanent standing admin is a Zero Trust anti-pattern; ADR-010 designs PIM eligibility instead." -ForegroundColor DarkGray }

# --- PIM-eligible assignments (P2) ---
Write-Host "`n-- PIM-eligible (just-in-time) assignments (requires Entra ID P2) --" -ForegroundColor Cyan
try {
    $elig = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances?$top=999').value
    Write-Host ("  eligible assignments: {0}" -f $elig.Count) -ForegroundColor ($(if($elig.Count){'Green'}else{'Yellow'}))
    if (-not $elig.Count) { Write-Host "     NOTE: no eligible assignments found — either PIM not in use or no P2. Verify licensing; design ADR-010." -ForegroundColor Yellow }
} catch {
    Write-Host "  (could not read eligibility schedules — likely no Entra ID P2 / PIM. Verify availability.)" -ForegroundColor Yellow
}

# --- Global Administrator population ---
Write-Host "`n-- Global Administrator population --" -ForegroundColor Cyan
$gaRoleId = ($roleDefs.GetEnumerator() | Where-Object { $_.Value -eq 'Global Administrator' } | Select-Object -First 1).Key
$gaCount = @($active | Where-Object { $_.roleDefinitionId -eq $gaRoleId }).Count
Write-Host ("  permanent Global Administrators: {0}" -f $gaCount) -ForegroundColor ($(if($gaCount -gt 5){'Red'}elseif($gaCount -lt 2){'Yellow'}else{'Green'}))
if ($gaCount -gt 5) { Write-Host "     WARN: more than 5 permanent GAs — Microsoft guidance is to keep this small. Design driver for ADR-009/010." -ForegroundColor Red }
if ($gaCount -lt 2) { Write-Host "     WARN: fewer than 2 GAs — confirm break-glass coverage (G4)." -ForegroundColor Yellow }

# --- Highly-privileged service principals ---
Write-Host "`n-- Highly-privileged service principals (directory roles held by SPs) --" -ForegroundColor Cyan
$spAssignments = $active | Where-Object { $_.principalId } | ForEach-Object {
    $p = $null
    try { $p = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/directoryObjects/$($_.principalId)?`$select=id" -ErrorAction SilentlyContinue } catch {}
    $odataType = $p.'@odata.type'
    if ($odataType -eq '#microsoft.graph.servicePrincipal') { [pscustomobject]@{ Role=$roleDefs[$_.roleDefinitionId]; Sp=$_.principalId } }
}
Write-Host ("  service principals holding directory roles: {0}" -f @($spAssignments).Count) -ForegroundColor ($(if(@($spAssignments).Count){'Yellow'}else{'Green'}))
if (@($spAssignments).Count) { Write-Host "     → informs ADR-004 (workload identity) — govern privileged SPs; prefer least privilege." -ForegroundColor DarkGray }

# --- Break-glass presence ---
Write-Host "`n-- Break-glass (emergency access) presence --" -ForegroundColor Cyan
if ($BreakGlassUpn) {
    foreach ($upn in $BreakGlassUpn) {
        $u = $null
        try { $u = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$upn?`$select=id,userPrincipalName,accountEnabled" -ErrorAction SilentlyContinue } catch {}
        if ($u.id) { Write-Host ("  PASS: {0} exists (enabled={1})" -f $u.userPrincipalName, $u.accountEnabled) -ForegroundColor Green }
        else       { Write-Host ("  WARN: {0} NOT found — break-glass is a design prerequisite (G4)." -f $upn) -ForegroundColor Red }
    }
} else {
    Write-Host "  (no -BreakGlassUpn supplied) The design mandates two cloud-only *.onmicrosoft.com accounts;" -ForegroundColor Yellow
    Write-Host "  re-run with -BreakGlassUpn to confirm, or record their creation as 'Phase 0 - Foundation'." -ForegroundColor Yellow
}

Write-Host "`nRecord these findings in Domain 4 (Privileged Access) — they drive ADR-009..012." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
