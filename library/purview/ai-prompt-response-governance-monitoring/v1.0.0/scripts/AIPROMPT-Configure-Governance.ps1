<#
.SYNOPSIS
    AIPROMPT-Configure-Governance.ps1 — configure AI governance policy; safe by default (-WhatIf / test mode).
.DESCRIPTION
    PURPOSE
        The configuration/remediation helper. Creates a DLP-for-AI (Copilot) policy in TEST mode, prints the
        Communication-Compliance scope/reviewer/anonymization checklist to build in the portal (privacy-
        sensitive — NOT auto-created), checks the insider-risk risky-AI-usage surface, and (Enforce) flips the
        named DLP policy from test to on. Defaults to -WhatIf; writes require -Commit.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell:
          Connect-IPPSSession
          .\AIPROMPT-Configure-Governance.ps1 -Action DlpForAI -DlpAiLocation "<your-Copilot-location>" -WhatIf
          .\AIPROMPT-Configure-Governance.ps1 -Action DlpForAI -DlpAiLocation "<your-Copilot-location>" -Commit
          .\AIPROMPT-Configure-Governance.ps1 -Action CommComplianceReview     # read-only checklist
          .\AIPROMPT-Configure-Governance.ps1 -Action InsiderRiskCheck          # read-only
          .\AIPROMPT-Configure-Governance.ps1 -Action Enforce -Commit           # test -> on
    EXPECTED RESULTS
        DlpForAI (dry-run): prints the policy it WOULD create, changes nothing. With -Commit: creates
        "AI Prompt DLP - Copilot - Test" in TEST mode. Enforce: sets that policy Mode to Enable. Neither the
        Communication-Compliance policy nor any content is silently changed.
.NOTES
    White-label Microsoft Purview tooling. Safe-by-default. No credentials stored.
    VERIFY IN YOUR TENANT: the DLP location that scopes a policy to Microsoft 365 Copilot/AI is licensing-
    dependent and evolving — this script REQUIRES -DlpAiLocation and never assumes it. Communication Compliance
    policy creation is privacy-sensitive and its parameters vary; this script prints a checklist to build it in
    the portal rather than creating it.
#>
[CmdletBinding()]
param(
    [ValidateSet("DlpForAI","CommComplianceReview","InsiderRiskCheck","Enforce")]
    [string]$Action = "CommComplianceReview",
    [string]$PolicyName = "AI Prompt DLP - Copilot - Test",
    [string]$Scope = "AI Governance - Pilot - Ring1",
    [string]$DlpAiLocation,                                   # REQUIRED for DlpForAI/Enforce — never assumed
    [string[]]$SensitiveInfoTypes = @("Credit Card Number","U.S. Social Security Number (SSN)"),
    [switch]$Commit,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$doWrite = $Commit -and (-not $WhatIf)
Write-Host "=== AIPROMPT Configure Governance — Action=$Action (safe by default) ===" -ForegroundColor Cyan
if (-not $doWrite) { Write-Host "DRY-RUN: no changes will be made. Add -Commit (without -WhatIf) to apply writes." -ForegroundColor Yellow }

switch ($Action) {

    "CommComplianceReview" {
        # Read-only checklist — the Communication Compliance policy is built in the portal (privacy-sensitive).
        Write-Host "`nCommunication Compliance AI policy — build in the portal, confirm each item:" -ForegroundColor Cyan
        @(
          "Name it: 'AI Interactions - Copilot - CommCompliance'",
          "Scope ONLY to the pilot ring: '$Scope' (not tenant-wide)",
          "Monitored source: Microsoft 365 Copilot / AI interactions (VERIFY the source exists in your tenant)",
          "Conditions: agreed sensitive-info / data-leak / offensive classifiers (Step 3 design)",
          "PRIVACY: anonymization ON (Settings -> Privacy) — reviewers see pseudonymized aliases",
          "ROLES: Analysts (pseudonymized) and Investigators (gated) are DIFFERENT accounts",
          "Reviewers assigned; retention/scope agreed with HR/privacy/legal"
        ) | ForEach-Object { Write-Host "  [ ] $_" }
        if (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue) {
            try {
                $existing = @(Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "(?i)copilot|(\bAI\b)" })
                Write-Host ("`n  Existing AI-related Communication Compliance policies: {0}" -f $existing.Count) -ForegroundColor Gray
            } catch {}
        }
    }

    "DlpForAI" {
        if (-not (Get-Command New-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
            Write-Host "New-DlpCompliancePolicy not available — connect S&C PowerShell (Connect-IPPSSession) and confirm DLP licensing." -ForegroundColor Red; return
        }
        if (-not $DlpAiLocation) {
            Write-Host "`n-DlpAiLocation is REQUIRED and not assumed. Confirm the Microsoft 365 Copilot / AI DLP location in Purview -> DLP -> Create," -ForegroundColor Red
            Write-Host "then pass it, e.g.  -DlpAiLocation '<Copilot location name>'. (Or use the DSPM-for-AI one-click policy in the portal.)" -ForegroundColor Red
            return
        }
        Write-Host "`nWould create DLP policy:" -ForegroundColor Cyan
        Write-Host ("  Name     : {0}" -f $PolicyName)
        Write-Host ("  Mode     : TEST (TestWithoutNotifications) — enforces nothing")
        Write-Host ("  Location : {0}" -f $DlpAiLocation)
        Write-Host ("  Match    : {0}" -f ($SensitiveInfoTypes -join ", "))
        if ($doWrite) {
            $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Host "  Policy already exists — leaving as-is (idempotent). Use -Action Enforce to change its mode." -ForegroundColor Yellow
            } else {
                # NOTE: parameter names for the Copilot location vary by tenant/version — see .NOTES. Confirm before -Commit.
                New-DlpCompliancePolicy -Name $PolicyName -Mode TestWithoutNotifications -Comment "AI Prompt DLP - Copilot - Test ($Scope)" -ErrorAction Stop | Out-Null
                Write-Host "  Created (TEST mode). Add the Copilot/AI LOCATION and the matching rule in the portal or via New-DlpComplianceRule, then verify it is TEST before validating." -ForegroundColor Green
            }
        } else {
            Write-Host "  (dry-run — nothing created)" -ForegroundColor Yellow
        }
    }

    "InsiderRiskCheck" {
        # Read-only presence check for the (preview/licensing-dependent) risky-AI-usage surface.
        $present = [bool](Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue)
        if ($present) {
            try { $irp = @(Get-InsiderRiskPolicy -ErrorAction SilentlyContinue); Write-Host ("Insider Risk reachable — {0} policy(ies). Confirm the risky-AI-usage template (preview) in the portal before staging 'Risky AI Usage - Pilot - Monitor'." -f $irp.Count) -ForegroundColor Green }
            catch { Write-Host "Insider Risk cmdlet present but not readable — check role/licensing." -ForegroundColor Yellow }
        } else {
            Write-Host "Insider Risk cmdlets not available — the risky-AI-usage step is optional (Impl Step 6). VERIFY availability in your tenant; if absent, rely on Communication Compliance + monitoring." -ForegroundColor Yellow
        }
    }

    "Enforce" {
        if (-not (Get-Command Set-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Write-Host "Set-DlpCompliancePolicy not available — connect S&C PowerShell." -ForegroundColor Red; return }
        $pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
        if (-not $pol) { Write-Host "Policy '$PolicyName' not found — create it with -Action DlpForAI -Commit first." -ForegroundColor Red; return }
        Write-Host ("`nWould set '{0}' Mode: {1} -> Enable (enforce). GATE: only after Testing Test 8 passes + HR/privacy/legal sign-off." -f $PolicyName, $pol.Mode) -ForegroundColor Cyan
        if ($doWrite) {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode Enable -ErrorAction Stop
            Write-Host "  Enforced. Rollback: Set-DlpCompliancePolicy -Identity '$PolicyName' -Mode TestWithoutNotifications" -ForegroundColor Green
        } else {
            Write-Host "  (dry-run — mode unchanged)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nNext: validate with AIPROMPT-Validate.ps1 before any enforce/expand." -ForegroundColor Cyan
