<#
.SYNOPSIS
    CMPPCI-Set-Scope.ps1 — manage least-privilege role membership (Req 7) and the deliberate DLP simulation→enforce flip (Req 3). -WhatIf by default.
.DESCRIPTION
    PURPOSE
        The governed change tool for two high-impact PCI actions: (1) role-group membership for
        least-privilege separation — composes Add-RoleGroupMember / Remove-RoleGroupMember for the
        Compliance Manager role groups; (2) moving DLP-PCI-CardholderData from SIMULATION to ENFORCE
        (Set-DlpCompliancePolicy -Mode Enable), or back to simulation for rollback. SAFE BY DEFAULT: runs
        in -WhatIf and prints exactly what it would change; -Commit is required to apply, and the DLP
        enforce path additionally requires -ConfirmEnforce so it is never bundled with a membership edit.
    HOW TO RUN
        Connect first: Connect-IPPSSession (a role able to manage role groups / DLP, e.g. Compliance Admin).
        # Role membership (dry-run then commit):
        .\CMPPCI-Set-Scope.ps1 -RoleGroup "ComplianceAdministrator" -Add user@contoso.com -WhatIf
        .\CMPPCI-Set-Scope.ps1 -RoleGroup "ComplianceAdministrator" -Remove old@contoso.com -Commit
        # Enforce the validated DLP (deliberate, gated):
        .\CMPPCI-Set-Scope.ps1 -EnforceDlp -PolicyName "DLP-PCI-CardholderData" -WhatIf
        .\CMPPCI-Set-Scope.ps1 -EnforceDlp -PolicyName "DLP-PCI-CardholderData" -Commit -ConfirmEnforce
        # Roll DLP back to simulation:
        .\CMPPCI-Set-Scope.ps1 -SimulateDlp -PolicyName "DLP-PCI-CardholderData" -Commit
    EXPECTED RESULTS
        -WhatIf: one line per intended change, nothing applied. -Commit: the membership change is applied,
        or (with -ConfirmEnforce) the DLP policy Mode moves to Enable. Enforcement is a separate step done
        only after 05-testing.md passes.
.NOTES
    White-label. -WhatIf by default; enforcement double-gated (-Commit + -ConfirmEnforce). Security &
    Compliance PowerShell. No credentials in code. CDE scope / SAQ / attestation adequacy are QSA/
    compliance determinations — this tool applies the approved change, it does not decide it. No cmdlets invented.
#>
[CmdletBinding()]
param(
    # Role membership
    [string]   $RoleGroup,
    [string[]] $Add,
    [string[]] $Remove,

    # DLP mode
    [switch]   $EnforceDlp,
    [switch]   $SimulateDlp,
    [string]   $PolicyName = 'DLP-PCI-CardholderData',
    [switch]   $ConfirmEnforce,

    [switch]   $Commit
)

$ErrorActionPreference = 'Stop'
$WhatIf = -not $Commit
Write-Host ("=== CMPPCI Set-Scope [{0}] ===" -f ($(if ($WhatIf) { 'DRY-RUN (-WhatIf)' } else { 'COMMIT' }))) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

try {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession | Out-Null }
} catch { Write-Error ("Connect-IPPSSession failed: {0}" -f $_.Exception.Message); return }

# ---- Role-group membership (Req 7 least privilege) ------------------------------------------------
if ($RoleGroup -and ($Add -or $Remove)) {
    Write-Host ("--- Role group: {0} ---" -f $RoleGroup) -ForegroundColor Cyan
    $rg = Get-RoleGroup -Identity $RoleGroup -ErrorAction SilentlyContinue
    if (-not $rg) { Write-Host ("  Role group '{0}' not found — verify the exact name in Roles & scopes." -f $RoleGroup) -ForegroundColor Yellow }
    else {
        foreach ($u in @($Add)) {
            if (-not $u) { continue }
            Write-Host ("  ADD    {0} -> {1}" -f $u, $RoleGroup) -ForegroundColor Yellow
            if (-not $WhatIf) {
                try { Add-RoleGroupMember -Identity $RoleGroup -Member $u -ErrorAction Stop; Write-Host "    [DONE] added" -ForegroundColor Green }
                catch { Write-Warning ("    could not add {0}: {1}" -f $u, $_.Exception.Message) }
            }
        }
        foreach ($u in @($Remove)) {
            if (-not $u) { continue }
            Write-Host ("  REMOVE {0} from {1}" -f $u, $RoleGroup) -ForegroundColor Yellow
            if (-not $WhatIf) {
                try { Remove-RoleGroupMember -Identity $RoleGroup -Member $u -Confirm:$false -ErrorAction Stop; Write-Host "    [DONE] removed" -ForegroundColor Green }
                catch { Write-Warning ("    could not remove {0}: {1}" -f $u, $_.Exception.Message) }
            }
        }
        Write-Host '  Grant the minimum role each person needs; keep administrators separated from contributors, QSA read-only.' -ForegroundColor DarkGray
    }
}

# ---- DLP simulation -> enforce (Req 3, deliberate) -----------------------------------------------
if ($EnforceDlp -or $SimulateDlp) {
    $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if (-not $pol) { Write-Host ("  DLP policy '{0}' not found — create it in simulation first (CMPPCI-Configuration.ps1)." -f $PolicyName) -ForegroundColor Yellow }
    else {
        if ($SimulateDlp) {
            Write-Host ("--- DLP '{0}' Mode: {1} -> TestWithNotifications (rollback to simulation) ---" -f $PolicyName, $pol.Mode) -ForegroundColor Yellow
            if (-not $WhatIf) { Set-DlpCompliancePolicy -Identity $PolicyName -Mode TestWithNotifications; Write-Host '    [DONE] back in simulation' -ForegroundColor Green }
        }
        elseif ($EnforceDlp) {
            Write-Host ("--- DLP '{0}' Mode: {1} -> Enable (ENFORCE) ---" -f $PolicyName, $pol.Mode) -ForegroundColor Red
            Write-Host '    HIGH-IMPACT: only after 05-testing.md Tests 1-10 pass. Enforcing blocks/acts on cardholder data.' -ForegroundColor Yellow
            if (-not $WhatIf) {
                if (-not $ConfirmEnforce) {
                    Write-Host '    REFUSED: enforcement requires -ConfirmEnforce in addition to -Commit (double-gated). Nothing changed.' -ForegroundColor Red
                } else {
                    Set-DlpCompliancePolicy -Identity $PolicyName -Mode Enable
                    Write-Host '    [DONE] policy is now ENFORCING — watch the first enforcement window for legitimate-workflow impact.' -ForegroundColor Green
                }
            }
        }
    }
}

if (-not ($RoleGroup -or $EnforceDlp -or $SimulateDlp)) {
    Write-Host 'No action specified. Provide -RoleGroup with -Add/-Remove, or -EnforceDlp/-SimulateDlp.' -ForegroundColor Yellow
    Write-Host 'This safe default (no switches) makes no change — matches 05-testing.md Test 10.'
}

Write-Host ("=== Set-Scope complete [{0}] ===" -f ($(if ($WhatIf) { 'DRY-RUN' } else { 'COMMIT' }))) -ForegroundColor Cyan
if ($WhatIf) { Write-Host 'Re-run with -Commit to apply (enforcement also needs -ConfirmEnforce). Nothing was changed.' -ForegroundColor Yellow }
