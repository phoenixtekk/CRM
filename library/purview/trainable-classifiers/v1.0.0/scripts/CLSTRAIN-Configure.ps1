<#
.SYNOPSIS
    CLSTRAIN-Configure.ps1 — wire a PUBLISHED trainable classifier into an auto-labeling policy IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Builds the WIRING that acts on a trainable classifier: creates (or updates) an auto-sensitivity-label
        policy scoped to a pilot, in SIMULATION/TEST mode, that applies a target sensitivity label, plus a
        rule intended to reference the trainable/built-in classifier as its condition. SAFE BY DEFAULT:
        previews with -WhatIf and writes NOTHING unless you pass -Commit. It never enforces (never sets
        Enable) and never creates/publishes a classifier (that is a portal action).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\CLSTRAIN-Configure.ps1 -WhatIf                          # preview only (default is preview)
          .\CLSTRAIN-Configure.ps1 -Commit                          # create the auto-label policy + rule in SIMULATION
          .\CLSTRAIN-Configure.ps1 -Commit -PilotGroup "SG-Classifier-Pilot" -LabelName "Confidential" -ClassifierName "TC-Contracts"
    EXPECTED RESULTS
        With -Commit: auto-labeling policy 'AL-Classifier-Pilot' exists in a Test/simulation mode, pilot
        scope, applying the target label, with a rule to host the classifier condition. Validate with
        CLSTRAIN-Validate.ps1 (expect Gate B PASS). Without -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No
    credentials stored. Uses standard New-/Set-AutoSensitivityLabelPolicy and New-/Set-AutoSensitivityLabel
    Rule; NO invented cmdlets. HOW a trainable classifier is referenced as a rule condition, and the exact
    simulation Mode value, EVOLVE — the script creates the simulation policy/rule shell and PRINTS that you
    must attach/verify the classifier condition (Get-Help New-AutoSensitivityLabelRule -Full) or set it in the
    portal. It does NOT enforce (no Enable) and does NOT create/publish a classifier.
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName     = "AL-Classifier-Pilot",
    [string]$RuleName       = "AL-Rule-Contracts",
    [string]$PilotGroup     = "SG-Classifier-Pilot",       # pilot scope for the auto-labeling policy
    [string]$LabelName      = "Confidential",              # sensitivity label to auto-apply (must be PUBLISHED)
    [string]$ClassifierName = "TC-Contracts",              # PUBLISHED trainable (or built-in) classifier to reference
    [string]$SimMode        = "TestWithoutNotifications"    # simulation/test mode; verify the exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSTRAIN Configure — wire classifier into auto-labeling (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Out-Null }
catch {
    try { Get-Label -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Not connected to Security & Compliance PowerShell (or auto-labeling unlicensed). Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
        return
    }
}

Write-Host "`nPlanned wiring: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Scope      : pilot group '{0}'" -f $PilotGroup)
Write-Host ("  Mode       : {0}  (SIMULATION — nothing is applied)" -f $SimMode)
Write-Host ("  Applies    : sensitivity label '{0}'  (must be PUBLISHED)" -f $LabelName)
Write-Host ("  Rule       : {0}  -> reference PUBLISHED classifier '{1}' as the condition" -f $RuleName, $ClassifierName)
Write-Host  "  Precheck   : confirm '$ClassifierName' is PUBLISHED in the portal and passed its accuracy gate (R7) first."

if (-not $Commit -or $WhatIf) {
    Write-Host "`nPreview complete. No changes made. Confirm the classifier is published + how it is referenced as a condition, then re-run with -Commit." -ForegroundColor Yellow
    return
}

# --- Commit: create/ensure the auto-labeling policy in SIMULATION, pilot scope, applying the label ---
try {
    $existing = Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        Write-Host "`nCreating auto-labeling policy '$PolicyName' ($SimMode, applies '$LabelName')..." -ForegroundColor Green
        New-AutoSensitivityLabelPolicy -Name $PolicyName `
            -ApplySensitivityLabel $LabelName `
            -Mode $SimMode `
            -SharePointLocation "All" `
            -Comment "Classifier wiring — SIMULATION. Enforce only after accuracy (R7) + simulation validation (Phase 5)." | Out-Null
        Write-Host "  NOTE: locations set to SharePoint 'All' as a default — scope to the pilot sites per your tenant. Verify location parameters." -ForegroundColor DarkYellow
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-AutoSensitivityLabelPolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating auto-labeling policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Confirm the label '$LabelName' is published, and verify the -Mode / location parameter names for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create the rule shell to host the classifier condition ---
try {
    $exists = Get-AutoSensitivityLabelRule -Identity $RuleName -ErrorAction SilentlyContinue
    if ($null -ne $exists) {
        Write-Host ("  Rule '{0}' already exists — leaving as-is." -f $RuleName) -ForegroundColor Yellow
    } else {
        Write-Host ("  Creating rule '{0}' (simulation)..." -f $RuleName) -ForegroundColor Green
        New-AutoSensitivityLabelRule -Name $RuleName `
            -Policy $PolicyName `
            -Comment ("Auto-label rule to reference published classifier '{0}'. Attach/verify the trainable-classifier condition per Get-Help or in the portal." -f $ClassifierName) `
            -ErrorAction Stop | Out-Null
        Write-Host ("    ACTION REQUIRED: attach the trainable-classifier condition ('{0}') to this rule." -f $ClassifierName) -ForegroundColor DarkYellow
        Write-Host  "    Verify the exact condition parameter with: Get-Help New-AutoSensitivityLabelRule -Full  (or set it in the portal)." -ForegroundColor DarkYellow
    }
} catch {
    Write-Host ("  WARN: could not create rule '{0}': {1}" -f $RuleName, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host  "        The trainable-classifier condition may need to be set in the portal — verify the parameter shape for your tenant." -ForegroundColor Yellow
}

Write-Host "`nDone (SIMULATION). Nothing is applied. Confirm the classifier condition is attached, then validate." -ForegroundColor Green
Write-Host "Next: CLSTRAIN-Validate.ps1 (expect Gate B PASS), then run the simulation per 05-testing.md before any enforce." -ForegroundColor Cyan
