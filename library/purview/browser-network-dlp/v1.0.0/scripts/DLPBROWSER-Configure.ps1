<#
.SYNOPSIS
    DLPBROWSER-Configure.ps1 — build the Browser & Network DLP policy + upload-restriction rule IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Creates (or ensures) a Devices-scoped DLP compliance policy for the "upload to a restricted cloud
        service domain / access from an unallowed browser" scenario, in SIMULATION/TEST mode, plus one
        upload-restriction rule set to Audit while in simulation. SAFE BY DEFAULT: previews with -WhatIf and
        writes NOTHING unless you pass -Commit. It never enforces (never sets Block/Enable) and it does NOT
        script the Endpoint DLP browser/domain SETTINGS (the sensitive service domain group + unallowed
        browsers) — those are portal-managed; the script PRINTS what to configure there and keys the rule to
        a sensitivity label. Moving to enforce is a deliberate step in the implementation guide.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPBROWSER-Configure.ps1 -WhatIf                       # preview only (default is preview)
          .\DLPBROWSER-Configure.ps1 -Commit                       # create policy + rule in SIMULATION
          .\DLPBROWSER-Configure.ps1 -Commit -PilotGroup "SG-DLPBROWSER-Pilot" -LabelName "Confidential"
    EXPECTED RESULTS
        With -Commit: policy 'Browser & Network DLP - Devices - Pilot' exists in a Test/simulation mode,
        Devices location, pilot scope, with one Audit upload-restriction rule. Validate with
        DLPBROWSER-Validate.ps1 (expect Gate A PASS). Without -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No
    credentials stored. Uses standard New-/Set-DlpCompliancePolicy and New-/Set-DlpComplianceRule; NO invented
    cmdlets. The endpoint upload-restriction Setting name/value and the simulation Mode value EVOLVE — the
    script uses documented names and PRINTS them for you to verify (Get-Help New-DlpComplianceRule -Full)
    against your tenant before committing. It does NOT enforce (no Block/Enable) and does NOT script the
    sensitive service domain group / unallowed browsers (portal-managed — verify path in your tenant).
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName  = "Browser & Network DLP - Devices - Pilot",
    [string]$RuleName    = "Restrict Upload to Unsanctioned Domains - Rule",
    [string]$PilotGroup  = "SG-DLPBROWSER-Pilot",              # pilot user/security group for the Devices scope
    [string]$LabelName   = "Confidential",                      # sensitivity label the rule keys on (adjust to your taxonomy)
    [string]$DomainGroup = "Unsanctioned & Personal Cloud - Domain Group",  # portal-managed sensitive service domain group (reference only)
    [string]$SimMode     = "TestWithoutNotifications"           # simulation/test mode; verify the exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPBROWSER Configure — Browser & Network DLP policy + rule (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

# --- The plan ---
# The upload restriction is realized through the Endpoint DLP browser/domain SETTINGS (the sensitive service
# domain group '$DomainGroup' + unallowed browsers, set to Audit during simulation) which are PORTAL-MANAGED.
# This script builds the Devices-scoped POLICY + RULE (which DO have a supported PowerShell surface) keyed to
# the sensitivity label, in simulation. VERIFY the endpoint-restriction Setting name/value for your tenant
# (Get-Help New-DlpComplianceRule -Full) before -Commit; they evolve.
$RestrictionSetting = "Upload"   # documented upload-restriction activity name — VERIFY in your tenant

Write-Host "`nPlanned policy: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Location : Devices (endpoint), scoped to pilot group '{0}'" -f $PilotGroup)
Write-Host ("  Mode     : {0}  (SIMULATION — nothing is blocked)" -f $SimMode)
Write-Host ("  Content  : sensitivity label '{0}' (adjust to your taxonomy; SITs may be added)" -f $LabelName)
Write-Host ("  Rule     : {0}  (activity={1} = Audit in simulation)" -f $RuleName, $RestrictionSetting)
Write-Host "`nPORTAL-MANAGED (configure/verify by hand — this script does NOT script these):" -ForegroundColor DarkYellow
Write-Host ("    - Sensitive service domain group '{0}' — add the unsanctioned/personal-cloud destinations; action=Audit for the pilot." -f $DomainGroup) -ForegroundColor DarkYellow
Write-Host  "    - Unallowed browsers list — per the design (steer users to Edge / extension-equipped Chrome/Firefox)." -ForegroundColor DarkYellow
Write-Host  "    Path: Purview > Data Loss Prevention > Endpoint DLP settings > Browser and domain restrictions to sensitive data (verify path)." -ForegroundColor DarkYellow

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
            -Comment "Browser & Network DLP pilot — SIMULATION. Move to enforce only after validation (implementation guide)." | Out-Null
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Check the -EndpointDlpLocation value and simulation Mode name for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create the upload-restriction rule (Audit) conditioned on the sensitivity label ---
try {
    $exists = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue
    if ($null -ne $exists) {
        Write-Host ("  Rule '{0}' already exists — leaving as-is." -f $RuleName) -ForegroundColor Yellow
    } else {
        $restriction = @(@{ "Setting" = $RestrictionSetting; "Value" = "Audit" })
        Write-Host ("  Creating rule '{0}' (activity {1} = Audit)..." -f $RuleName, $RestrictionSetting) -ForegroundColor Green
        New-DlpComplianceRule -Name $RuleName `
            -Policy $PolicyName `
            -ContentContainsSensitiveInformation @() `
            -EndpointDlpRestrictions $restriction `
            -Comment ("Browser & Network DLP upload restriction — Audit in simulation. Attach the '{0}' label/SIT condition and the '{1}' sensitive service domain group per the implementation guide." -f $LabelName, $DomainGroup) `
            -ErrorAction Stop | Out-Null
        Write-Host ("    NOTE: attach the '{0}' label condition (and the '{1}' domain-group scope in the portal) before enforcing." -f $LabelName, $DomainGroup) -ForegroundColor DarkYellow
    }
} catch {
    Write-Host ("  WARN: could not create rule '{0}': {1}" -f $RuleName, $_.Exception.Message) -ForegroundColor Yellow
    Write-Host  "        Verify the EndpointDlpRestrictions Setting name/value and the label condition parameters for your tenant." -ForegroundColor Yellow
}

Write-Host "`nDone (SIMULATION). Nothing is enforced." -ForegroundColor Green
Write-Host "Next: DLPBROWSER-Validate.ps1 (expect Gate A PASS), then pilot per 05-testing.md before any enforce." -ForegroundColor Cyan
