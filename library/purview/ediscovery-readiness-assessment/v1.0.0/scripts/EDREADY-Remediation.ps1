<#
.SYNOPSIS
    EDREADY-Remediation.ps1 — gap remediation + readiness-proof builder, DRY-RUN (-WhatIf) by default.
.DESCRIPTION
    Closes assessed readiness gaps and stands up the NON-DESTRUCTIVE readiness proof on a dedicated
    TEST account: optionally enable the unified audit log, add named operators to the eDiscovery
    Manager / eDiscovery Administrator role groups, and create the proof case + case-hold policy/rule
    named to the reference design. DRY-RUN by default — every action is only PREVIEWED unless -Commit
    is supplied. Never removes holds or role members silently. No credentials or secrets in code.
.EXAMPLE
    .\EDREADY-Remediation.ps1 -WhatIf
    Preview every remediation/proof action without changing anything (default behaviour).
.EXAMPLE
    .\EDREADY-Remediation.ps1 -EnableAudit -AddManagers user1@contoso.com,user2@contoso.com -Commit
    Enable auditing and add two operators to eDiscovery Manager (requires -Commit to apply).
.EXAMPLE
    .\EDREADY-Remediation.ps1 -BuildProof -ProofMailbox readiness-pilot@contoso.com -Commit
    Create the readiness-proof case + hold on the TEST mailbox (remove the hold after the proof —
    see 03-implementation.md Step 13).
.NOTES
    Expected results: a preview of each action (dry-run), or confirmation of each applied change with
    -Commit. White-label. Safe-by-default. Uses Set-AdminAuditLogConfig / Add-RoleGroupMember /
    New-ComplianceCase / New-CaseHoldPolicy / New-CaseHoldRule. Regulatory/records/legal determinations
    are deferred to the relevant governance functions — the proof is a TEST-account rehearsal only.
#>
[CmdletBinding()]
param(
    [switch]$EnableAudit,
    [string[]]$AddManagers,
    [string[]]$AddAdministrators,
    [switch]$BuildProof,
    [string]$ProofMailbox,
    [string]$ProofCase       = 'eDiscovery Readiness – Proof – Pilot',
    [string]$ProofHoldPolicy = 'Readiness Hold Policy – Proof – Pilot',
    [string]$ProofHoldRule   = 'Readiness Hold Rule – Proof – Pilot',
    [switch]$Commit,
    [switch]$WhatIf
)

# Safe-by-default: anything other than an explicit -Commit is a dry-run.
$DryRun = -not $Commit
if ($DryRun) { Write-Host "`n*** DRY-RUN (no changes will be made). Re-run with -Commit to apply. ***" -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

function Invoke-Step {
    param([string]$Describe, [scriptblock]$Action)
    if ($DryRun) {
        Write-Host ("  WOULD: {0}" -f $Describe) -ForegroundColor Yellow
    } else {
        Write-Host ("  APPLY: {0}" -f $Describe) -ForegroundColor Green
        & $Action
    }
}

Write-Host "`n=== eDiscovery Readiness — remediation & proof builder ===" -ForegroundColor Cyan

# --- H: enable unified audit log ---
if ($EnableAudit) {
    Write-Host "`n--- Enable unified audit log (H) ---" -ForegroundColor Cyan
    Invoke-Step "Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true" {
        Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
    }
}

# --- R: add operators to role groups ---
if ($AddManagers) {
    Write-Host "`n--- Add eDiscovery Manager members (R) ---" -ForegroundColor Cyan
    foreach ($m in $AddManagers) {
        Invoke-Step ("Add-RoleGroupMember 'eDiscovery Manager' -Member {0}" -f $m) {
            Add-RoleGroupMember -Identity 'eDiscovery Manager' -Member $m -ErrorAction Stop
        }
    }
}
if ($AddAdministrators) {
    Write-Host "`n--- Add eDiscovery Administrator members (R lead group) ---" -ForegroundColor Cyan
    foreach ($a in $AddAdministrators) {
        Invoke-Step ("Add-RoleGroupMember 'eDiscovery Administrator' -Member {0}" -f $a) {
            Add-RoleGroupMember -Identity 'eDiscovery Administrator' -Member $a -ErrorAction Stop
        }
    }
}

# --- Pilot: build the readiness proof on the TEST account ---
if ($BuildProof) {
    Write-Host "`n--- Build readiness proof (TEST account only) ---" -ForegroundColor Cyan
    if (-not $ProofMailbox) {
        Write-Host "  ERROR: -BuildProof requires -ProofMailbox <test mailbox> (a dedicated NON-sensitive test account, Requirement 2.7)." -ForegroundColor Red
    } else {
        Write-Host ("  Proof custodian (TEST account): {0}" -f $ProofMailbox) -ForegroundColor DarkCyan
        Invoke-Step ("New-ComplianceCase -Name '{0}' -CaseType eDiscovery" -f $ProofCase) {
            if (-not (Get-ComplianceCase -Identity $ProofCase -ErrorAction SilentlyContinue)) {
                New-ComplianceCase -Name $ProofCase -CaseType eDiscovery | Out-Null
            }
        }
        Invoke-Step ("New-CaseHoldPolicy -Name '{0}' -Case '{1}' -ExchangeLocation {2}" -f $ProofHoldPolicy, $ProofCase, $ProofMailbox) {
            if (-not (Get-CaseHoldPolicy -Identity $ProofHoldPolicy -ErrorAction SilentlyContinue)) {
                New-CaseHoldPolicy -Name $ProofHoldPolicy -Case $ProofCase -ExchangeLocation $ProofMailbox | Out-Null
            }
        }
        Invoke-Step ("New-CaseHoldRule -Name '{0}' -Policy '{1}'" -f $ProofHoldRule, $ProofHoldPolicy) {
            if (-not (Get-CaseHoldRule -Identity $ProofHoldRule -ErrorAction SilentlyContinue)) {
                New-CaseHoldRule -Name $ProofHoldRule -Policy $ProofHoldPolicy | Out-Null
            }
        }
        Write-Host "`n  REMINDER: after proving preservation (05-testing.md Test 3), REMOVE the proof hold —" -ForegroundColor Yellow
        Write-Host "           Remove-CaseHoldRule '$ProofHoldRule'; Remove-CaseHoldPolicy '$ProofHoldPolicy'  (03-implementation.md Step 13)." -ForegroundColor Yellow
    }
}

if (-not ($EnableAudit -or $AddManagers -or $AddAdministrators -or $BuildProof)) {
    Write-Host "`n  Nothing selected. Choose -EnableAudit / -AddManagers / -AddAdministrators / -BuildProof. Defaults to DRY-RUN." -ForegroundColor Yellow
}

Write-Host ("`nRemediation {0}." -f $(if($DryRun){'preview complete (DRY-RUN — nothing changed)'}else{'applied'})) -ForegroundColor Green
Disconnect-ExchangeOnline -Confirm:$false | Out-Null
