<#
.SYNOPSIS
    DLPUSB-Configure.ps1 — build the removable-media Endpoint DLP policy + rule IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Creates (or updates) a removable-media Endpoint DLP compliance policy scoped to the Devices location
        and a pilot scope, in SIMULATION/TEST mode, plus one rule — copy sensitive content to removable/USB
        storage — conditioned on sensitive content and set to Audit while in simulation, with the corporate
        device group as the approved exception. SAFE BY DEFAULT: previews with -WhatIf and writes NOTHING
        unless you pass -Commit. It never enforces (never sets Block/Enable) and never deploys the DEVICE-
        CONTROL policy (that is a management-tool action) — moving to enforce is a deliberate step in Phase 6.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPUSB-Configure.ps1 -WhatIf                        # preview only (default is preview)
          .\DLPUSB-Configure.ps1 -Commit                        # create the policy + rule in SIMULATION
          .\DLPUSB-Configure.ps1 -Commit -PilotGroup "SG-USB-Pilot" -LabelName "Confidential"
    EXPECTED RESULTS
        With -Commit: policy 'EDLP-USB-Pilot' exists in a Test/simulation mode, Devices location, pilot
        scope, with one Audit removable-media rule. Validate with DLPUSB-Validate.ps1 (expect Gate A PASS).
        Without -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No
    credentials stored. Uses standard New-/Set-DlpCompliancePolicy and New-/Set-DlpComplianceRule; NO invented
    cmdlets. The exact removable-media restriction Setting name/value and the simulation Mode value EVOLVE —
    the script uses documented names and PRINTS them for you to verify with `Get-Help New-DlpComplianceRule
    -Full` against your tenant before committing. It does NOT enforce (no Block/Enable) and does NOT deploy
    device control.
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName  = "EDLP-USB-Pilot",
    [string]$RuleName    = "EDLP-Rule-USB",
    [string]$PilotGroup  = "SG-USB-Pilot",            # pilot user/security group for the Devices scope
    [string]$LabelName   = "Confidential",            # sensitivity label the rule keys on (adjust to your taxonomy)
    [string]$DeviceGroup = "USBG-Corporate",          # approved removable-media device group (Endpoint DLP settings)
    [string]$SimMode     = "TestWithoutNotifications"  # simulation/test mode; verify the exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPUSB Configure — removable-media Endpoint DLP policy + rule (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

# --- The plan: one removable-media rule, Audit-in-simulation, keyed on a sensitivity label ---
# NOTE: the endpoint-restriction Setting name below is the documented removable-media activity name. VERIFY it
# for your tenant (Get-Help New-DlpComplianceRule -Full) before -Commit; it evolves.
$restrictionSetting = "RemovableMedia"

Write-Host "`nPlanned policy: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Location : Devices (endpoint), scoped to pilot group '{0}'" -f $PilotGroup)
Write-Host ("  Mode     : {0}  (SIMULATION — nothing is blocked)" -f $SimMode)
Write-Host ("  Content  : sensitivity label '{0}' (adjust to your taxonomy; SITs may be added)" -f $LabelName)
Write-Host ("  Rule     : {0}  activity={1}=Audit  (allow-list device group '{2}' in Endpoint DLP settings)" -f $RuleName, $restrictionSetting, $DeviceGroup)
Write-Host "  Device CONTROL (device-aware layer) is deployed via your management tooling — NOT by this script."

if (-not $Commit -or $WhatIf) {
    Write-Host "`nPreview complete. No changes made. Verify the Setting name above against your tenant, then re-run with -Commit." -ForegroundColor Yellow
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
            -Comment "Removable-media Endpoint DLP pilot — SIMULATION. Move to enforce only after validation (Phase 6)." | Out-Null
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Check the -EndpointDlpLocation value and simulation Mode name for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create the removable-media rule (Audit) conditioned on the sensitivity label ---
try {
    $exists = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue
    if ($null -ne $exists) {
        Write-Host ("  Rule '{0}' already exists — leaving as-is." -f $RuleName) -ForegroundColor Yellow
    } else {
        $restriction = @(@{ "Setting" = $restrictionSetting; "Value" = "Audit" })
        Write-Host ("  Creating rule '{0}' (activity {1} = Audit)..." -f $RuleName, $restrictionSetting) -ForegroundColor Green
        New-DlpComplianceRule -Name $RuleName `
            -Policy $PolicyName `
            -ContentContainsSensitiveInformation @() `
            -EndpointDlpRestrictions $restriction `
            -Comment ("Removable-media Endpoint DLP — Audit in simulation. Add the '{0}' label/SIT condition and the '{1}' allow-list per implementation guide." -f $LabelName, $DeviceGroup) `
            -ErrorAction Stop | Out-Null
        Write-Host ("    NOTE: attach the '{0}' label condition and the '{1}' device-group exception in the portal/rule before enforcing." -f $LabelName, $DeviceGroup) -ForegroundColor DarkYellow
    }
} catch {
    Write-Host ("  WARN: could not create rule '{0}': {1}" -f $RuleName, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host  "        Verify the EndpointDlpRestrictions Setting name/value and the label condition parameters for your tenant." -ForegroundColor Yellow
}

Write-Host "`nDone (SIMULATION). Nothing is enforced; the device-control layer is deployed separately in your management tool (Phase 4)." -ForegroundColor Green
Write-Host "Next: DLPUSB-Validate.ps1 (expect Gate A PASS), then pilot per 05-testing.md before any enforce." -ForegroundColor Cyan
