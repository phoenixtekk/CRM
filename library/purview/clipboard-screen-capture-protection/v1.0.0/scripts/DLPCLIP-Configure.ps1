<#
.SYNOPSIS
    DLPCLIP-Configure.ps1 — build the Endpoint DLP policy + clipboard & screen-capture rule IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Creates (or updates) an Endpoint DLP compliance policy scoped to the Devices location and a pilot scope,
        in SIMULATION/TEST mode, plus one rule that restricts COPY TO CLIPBOARD and SCREEN CAPTURE of sensitive
        (labelled or SIT-matched) content, set to Audit while in simulation. SAFE BY DEFAULT: previews with
        -WhatIf and writes NOTHING unless you pass -Commit. It never enforces (never sets Block/Enable) — moving
        to enforce is a deliberate portal/PowerShell step in Phase 4/5 of the implementation guide.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPCLIP-Configure.ps1 -WhatIf                      # preview only (default is preview)
          .\DLPCLIP-Configure.ps1 -Commit                      # create the policy + rule in SIMULATION
          .\DLPCLIP-Configure.ps1 -Commit -PilotGroup "DLP Pilot Ring - Stage1" -LabelName "Confidential"
    EXPECTED RESULTS
        With -Commit: policy 'DLP - Endpoint Clipboard+Screen - Simulation' exists in a Test/simulation mode,
        Devices location, pilot scope, with a clipboard+screen-capture Audit rule. Validate with
        DLPCLIP-Validate.ps1 (expect Gate A PASS). Without -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No credentials
    stored. Uses standard New-/Set-DlpCompliancePolicy and New-/Set-DlpComplianceRule; NO invented cmdlets. The
    exact EndpointDlpRestrictions Setting names/values and the simulation Mode value EVOLVE — and SCREEN CAPTURE
    IS NEWER / MAY BE IN PREVIEW — so the script PRINTS the planned Setting names for you to verify with
    `Get-Help New-DlpComplianceRule -Full` (and current Microsoft docs) against your tenant before committing.
    Recommended pattern: build the rule ONCE in the portal, read it back with DLPCLIP-Discovery.ps1 to learn the
    exact Setting shape in your tenant, then use -Commit. It does NOT enforce (no Block/Enable). VERIFY LICENSING.
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName  = "DLP - Endpoint Clipboard+Screen - Simulation",
    [string]$RuleName    = "DLP - Endpoint Clipboard+Screen - Rule",
    [string]$PilotGroup  = "DLP Pilot Ring - Stage1",       # pilot user/security group for the Devices scope
    [string]$LabelName   = "Confidential",                   # sensitivity label the rule keys on (adjust to your taxonomy)
    [string]$SimMode     = "TestWithoutNotifications"        # simulation/test mode; verify the exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPCLIP Configure — clipboard & screen-capture Endpoint DLP policy (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red
    return
}

# --- The plan: one rule restricting the two endpoint activities, each Audit-in-simulation, keyed on a label ---
# NOTE: the Setting names below are the documented activity names. VERIFY them for your tenant
# (Get-Help New-DlpComplianceRule -Full + Microsoft docs) before -Commit; they evolve and screen capture may be preview.
$restrictions = @(
    @{ Setting = "CopyToClipboard"; Value = "Audit"; Note = "Copy sensitive content to clipboard / paste to app or browser" }
    @{ Setting = "ScreenCapture";   Value = "Audit"; Note = "Screenshot of sensitive content (NEWER / MAY BE IN PREVIEW — verify tenant)" }
)

Write-Host "`nPlanned policy: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Location : Devices (endpoint), scoped to pilot group '{0}'" -f $PilotGroup)
Write-Host ("  Mode     : {0}  (SIMULATION — nothing is blocked)" -f $SimMode)
Write-Host ("  Content  : sensitivity label '{0}' (adjust to your taxonomy; SITs may be added)" -f $LabelName)
Write-Host ("  Rule     : {0}  (both activities Audit while in simulation):" -f $RuleName)
foreach ($r in $restrictions) { Write-Host ("    - activity={0,-16} value={1,-6} {2}" -f $r.Setting, $r.Value, $r.Note) }

if (-not $Commit -or $WhatIf) {
    Write-Host "`nPreview complete. No changes made. Verify the Setting names above against your tenant, then re-run with -Commit." -ForegroundColor Yellow
    return
}

# --- Commit: create/ensure the policy in SIMULATION on the Devices location, pilot scope ---
try {
    $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        Write-Host "`nCreating policy '$PolicyName' (Devices location, $SimMode)..." -ForegroundColor Green
        New-DlpCompliancePolicy -Name $PolicyName `
            -Mode $SimMode `
            -EndpointDlpLocation $PilotGroup `
            -Comment "Clipboard & screen-capture Endpoint DLP pilot — SIMULATION. Move to enforce only after validation (Phase 4/5)." | Out-Null
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Check the -EndpointDlpLocation value and simulation Mode name for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create the clipboard + screen-capture rule (Audit) conditioned on the sensitivity label ---
try {
    $exists = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue
    if ($null -ne $exists) {
        Write-Host ("  Rule '{0}' already exists — leaving as-is (adjust in the portal if needed)." -f $RuleName) -ForegroundColor Yellow
    } else {
        $restriction = @($restrictions | ForEach-Object { @{ "Setting" = $_.Setting; "Value" = $_.Value } })
        Write-Host ("  Creating rule '{0}' (CopyToClipboard=Audit, ScreenCapture=Audit)..." -f $RuleName) -ForegroundColor Green
        New-DlpComplianceRule -Name $RuleName `
            -Policy $PolicyName `
            -ContentContainsSensitiveInformation @() `
            -EndpointDlpRestrictions $restriction `
            -Comment "Endpoint DLP clipboard + screen-capture — Audit in simulation. Attach the label/SIT condition + allow-list per implementation guide before enforcing." `
            -ErrorAction Stop | Out-Null
        Write-Host ("    NOTE: attach the '{0}' label condition (and/or SITs) and any allowed-app/browser exceptions in the portal/rule before enforcing." -f $LabelName) -ForegroundColor DarkYellow
    }
} catch {
    Write-Host ("  WARN: could not create rule '{0}': {1}" -f $RuleName, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host  "        Verify the EndpointDlpRestrictions Setting name/value (screen capture may be preview) and the label condition parameters for your tenant." -ForegroundColor Yellow
    Write-Host  "        Fallback: build the rule once in the portal, then read it back with DLPCLIP-Discovery.ps1 to learn the exact shape." -ForegroundColor Yellow
}

Write-Host "`nDone (SIMULATION). Nothing is enforced." -ForegroundColor Green
Write-Host "Next: DLPCLIP-Validate.ps1 (expect Gate A PASS), then pilot per 05-testing.md before any enforce." -ForegroundColor Cyan
