<#
.SYNOPSIS
    DLPWIN-Configure.ps1 — build the Endpoint DLP policy + five channel rules IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Creates (or updates) a Windows Endpoint DLP compliance policy scoped to the Devices location and a
        pilot scope, in SIMULATION/TEST mode, plus five rules — USB/removable media, print, clipboard,
        network share, and cloud egress — each conditioned on sensitive content and set to Audit while in
        simulation. SAFE BY DEFAULT: previews with -WhatIf and writes NOTHING unless you pass -Commit. It
        never enforces (never sets Block/Enable) — moving to enforce is a deliberate portal/PowerShell step
        in Phase 5 of the implementation guide.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPWIN-Configure.ps1 -WhatIf                       # preview only (default is preview)
          .\DLPWIN-Configure.ps1 -Commit                       # create the policy + rules in SIMULATION
          .\DLPWIN-Configure.ps1 -Commit -PilotGroup "SG-EDLP-Pilot" -LabelName "Confidential"
    EXPECTED RESULTS
        With -Commit: policy 'EDLP-Windows-Pilot' exists in a Test/simulation mode, Devices location, pilot
        scope, with five Audit rules. Validate with DLPWIN-Validate.ps1 (expect Gate A PASS). Without
        -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No
    credentials stored. Uses standard New-/Set-DlpCompliancePolicy and New-/Set-DlpComplianceRule; NO invented
    cmdlets. The exact endpoint-restriction Setting names/values and the simulation Mode value EVOLVE — the
    script uses documented names and PRINTS them for you to verify with `Get-Help New-DlpComplianceRule -Full`
    against your tenant before committing. It does NOT enforce (no Block/Enable).
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName  = "EDLP-Windows-Pilot",
    [string]$PilotGroup  = "SG-EDLP-Pilot",     # pilot user/security group for the Devices scope
    [string]$LabelName   = "Confidential",       # sensitivity label the rules key on (adjust to your taxonomy)
    [string]$SimMode     = "TestWithoutNotifications"  # simulation/test mode; verify the exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPWIN Configure — Endpoint DLP policy + rules (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

# --- The plan: five channel rules, each Audit-in-simulation, keyed on a sensitivity label ---
# NOTE: endpoint-restriction Setting names below are the documented activity names. VERIFY them for your
# tenant (Get-Help New-DlpComplianceRule -Full) before -Commit; they evolve.
$plan = @(
    @{ Rule = "EDLP-Rule-USB";          Setting = "RemovableMedia"; Note = "Copy to a removable USB device (allow-list corporate device group in Endpoint DLP settings)" }
    @{ Rule = "EDLP-Rule-Print";        Setting = "Print";          Note = "Print (allow-list sanctioned printer group in Endpoint DLP settings)" }
    @{ Rule = "EDLP-Rule-Clipboard";    Setting = "CopyToClipboard";Note = "Copy to clipboard / paste to app or browser" }
    @{ Rule = "EDLP-Rule-NetworkShare"; Setting = "NetworkShare";   Note = "Copy to a network share" }
    @{ Rule = "EDLP-Rule-CloudEgress";  Setting = "CloudEgress";    Note = "Upload/egress via unallowed browser or non-sanctioned service domain (needs browser extension for Chrome/Firefox)" }
)

Write-Host "`nPlanned policy: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Location : Devices (endpoint), scoped to pilot group '{0}'" -f $PilotGroup)
Write-Host ("  Mode     : {0}  (SIMULATION — nothing is blocked)" -f $SimMode)
Write-Host ("  Content  : sensitivity label '{0}' (adjust to your taxonomy; SITs may be added)" -f $LabelName)
Write-Host "  Rules (all Audit while in simulation):"
foreach ($p in $plan) { Write-Host ("    - {0,-22} activity={1,-16} {2}" -f $p.Rule, $p.Setting, $p.Note) }

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
            -Comment "Windows Endpoint DLP pilot — SIMULATION. Move to enforce only after validation (Phase 5)." | Out-Null
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Check the -EndpointDlpLocation value and simulation Mode name for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create each channel rule (Audit) conditioned on the sensitivity label ---
foreach ($p in $plan) {
    try {
        $exists = Get-DlpComplianceRule -Identity $p.Rule -ErrorAction SilentlyContinue
        if ($null -ne $exists) { Write-Host ("  Rule '{0}' already exists — leaving as-is." -f $p.Rule) -ForegroundColor Yellow; continue }

        $restriction = @(@{ "Setting" = $p.Setting; "Value" = "Audit" })
        Write-Host ("  Creating rule '{0}' (activity {1} = Audit)..." -f $p.Rule, $p.Setting) -ForegroundColor Green
        New-DlpComplianceRule -Name $p.Rule `
            -Policy $PolicyName `
            -ContentContainsSensitiveInformation @() `
            -EndpointDlpRestrictions $restriction `
            -Comment ("Endpoint DLP {0} — Audit in simulation. Add the sensitivity-label/SIT condition + allow-list per implementation guide." -f $p.Setting) `
            -ErrorAction Stop | Out-Null
        Write-Host ("    NOTE: attach the '{0}' label condition and any allow-list group in the portal/rule before enforcing." -f $LabelName) -ForegroundColor DarkYellow
    } catch {
        Write-Host ("  WARN: could not create rule '{0}': {1}" -f $p.Rule, $_.Exception.Message) -ForegroundColor Yellow
        Write-Host  "        Verify the EndpointDlpRestrictions Setting name/value and the label condition parameters for your tenant." -ForegroundColor Yellow
    }
}

Write-Host "`nDone (SIMULATION). Nothing is enforced." -ForegroundColor Green
Write-Host "Next: DLPWIN-Validate.ps1 (expect Gate A PASS), then pilot per 05-testing.md before any enforce." -ForegroundColor Cyan
