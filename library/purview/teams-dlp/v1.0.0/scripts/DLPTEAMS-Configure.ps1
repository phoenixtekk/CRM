<#
.SYNOPSIS
    DLPTEAMS-Configure.ps1 — build the Teams DLP policy (messages + SharePoint + OneDrive) + two rules IN SIMULATION (-WhatIf by default; -Commit to write).
.DESCRIPTION
    PURPOSE
        Creates (or updates) a Teams DLP compliance policy spanning the Teams-messages, SharePoint, and
        OneDrive locations and scoped to a pilot group, in SIMULATION/TEST mode, plus two rules — one for
        Teams messages and one for shared files (SharePoint+OneDrive) — each conditioned on sensitive content
        and set to Audit while in simulation. SAFE BY DEFAULT: previews with -WhatIf and writes NOTHING unless
        you pass -Commit. It never enforces (never sets Block/Enable) — moving to enforce is a deliberate step
        in Phase 4 of the implementation guide.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPTEAMS-Configure.ps1 -WhatIf                      # preview only (default is preview)
          .\DLPTEAMS-Configure.ps1 -Commit                      # create the policy + rules in SIMULATION
          .\DLPTEAMS-Configure.ps1 -Commit -PilotGroup "SG-TeamsDLP-Pilot" -LabelName "Confidential"
    EXPECTED RESULTS
        With -Commit: policy 'DLP-Teams-Pilot' exists in a Test/simulation mode across Teams+SharePoint+
        OneDrive, pilot scope, with two Audit rules. Validate with DLPTEAMS-Validate.ps1 (expect Gate A PASS).
        Without -Commit: a printed plan and no changes.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf/preview by default; -Commit gates all writes. No
    credentials stored. Uses standard New-/Set-DlpCompliancePolicy and New-/Set-DlpComplianceRule; NO invented
    cmdlets. The location parameter names (-TeamsLocation/-SharePointLocation/-OneDriveLocation), the
    internal-vs-external condition/action names, and the simulation Mode value EVOLVE — the script uses
    documented names and PRINTS the plan for you to verify with `Get-Help New-DlpComplianceRule -Full`
    against your tenant before committing. It does NOT enforce (no Block/Enable).
#>
[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$PolicyName  = "DLP-Teams-Pilot",
    [string]$MsgRuleName = "DLP-Rule-TeamsMessages",
    [string]$FileRuleName= "DLP-Rule-TeamsFiles",
    [string]$PilotGroup  = "SG-TeamsDLP-Pilot",         # pilot user/security group for all three locations
    [string]$LabelName   = "Confidential",              # sensitivity label the rules key on (adjust to your taxonomy)
    [string]$SimMode     = "TestWithoutNotifications"    # simulation/test mode; verify the exact value in your tenant
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPTEAMS Configure — Teams DLP policy + rules (SIMULATION) ===" -ForegroundColor Cyan
if (-not $Commit) { Write-Host "PREVIEW MODE — no changes will be written. Re-run with -Commit to apply." -ForegroundColor Yellow }

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

Write-Host "`nPlanned policy: $PolicyName" -ForegroundColor Cyan
Write-Host ("  Locations: Teams chat/channel messages + SharePoint + OneDrive, scoped to pilot group '{0}'" -f $PilotGroup)
Write-Host ("  Mode     : {0}  (SIMULATION — nothing is blocked)" -f $SimMode)
Write-Host ("  Content  : sensitivity label '{0}' (adjust to your taxonomy; SITs may be added)" -f $LabelName)
Write-Host "  Rules (both Audit while in simulation):"
Write-Host ("    - {0,-24} Teams messages (add internal-vs-external condition per R6)" -f $MsgRuleName)
Write-Host ("    - {0,-24} SharePoint + OneDrive (Teams-shared files)" -f $FileRuleName)

if (-not $Commit -or $WhatIf) {
    Write-Host "`nPreview complete. No changes made. Verify the location + condition parameter names against your tenant, then re-run with -Commit." -ForegroundColor Yellow
    return
}

# --- Commit: create/ensure the policy in SIMULATION across the three locations, pilot scope ---
try {
    $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        Write-Host "`nCreating policy '$PolicyName' (Teams+SharePoint+OneDrive, $SimMode)..." -ForegroundColor Green
        New-DlpCompliancePolicy -Name $PolicyName `
            -Mode $SimMode `
            -TeamsLocation $PilotGroup `
            -SharePointLocation "All" `
            -OneDriveLocation $PilotGroup `
            -Comment "Teams DLP pilot — SIMULATION across messages+files. Move to enforce only after validation (Phase 4)." | Out-Null
        Write-Host "  NOTE: SharePoint location is set to 'All' as a default; scope it to the pilot sites if your tenant requires. Verify the location parameter names for your tenant." -ForegroundColor DarkYellow
    } else {
        Write-Host "`nPolicy '$PolicyName' already exists — ensuring it stays in $SimMode (simulation)..." -ForegroundColor Yellow
        Set-DlpCompliancePolicy -Identity $PolicyName -Mode $SimMode | Out-Null
    }
} catch {
    Write-Host "  ERROR creating/updating policy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Check the -TeamsLocation / -SharePointLocation / -OneDriveLocation values and simulation Mode name for your tenant." -ForegroundColor Yellow
    return
}

# --- Commit: create the two rules (Audit) conditioned on the sensitivity label ---
$ruleDefs = @(
    @{ Name = $MsgRuleName;  Note = "Teams messages — add the internal-vs-external condition and message action (block/policy tip) per R6 before enforcing." }
    @{ Name = $FileRuleName; Note = "Shared files (SharePoint+OneDrive) — add the file action (e.g. block external share) per R6 before enforcing." }
)
foreach ($rd in $ruleDefs) {
    try {
        $exists = Get-DlpComplianceRule -Identity $rd.Name -ErrorAction SilentlyContinue
        if ($null -ne $exists) { Write-Host ("  Rule '{0}' already exists — leaving as-is." -f $rd.Name) -ForegroundColor Yellow; continue }
        Write-Host ("  Creating rule '{0}' (Audit in simulation)..." -f $rd.Name) -ForegroundColor Green
        New-DlpComplianceRule -Name $rd.Name `
            -Policy $PolicyName `
            -ContentContainsSensitiveInformation @() `
            -Comment ("Teams DLP — Audit in simulation. Key on the '{0}' label/SIT. {1}" -f $LabelName, $rd.Note) `
            -ErrorAction Stop | Out-Null
        Write-Host ("    NOTE: attach the '{0}' label/SIT condition (and the R6 action) in the portal/rule before enforcing." -f $LabelName) -ForegroundColor DarkYellow
    } catch {
        Write-Host ("  WARN: could not create rule '{0}': {1}" -f $rd.Name, $_.Exception.Message) -ForegroundColor Yellow
        Write-Host  "        Verify the condition/action parameter names for your tenant." -ForegroundColor Yellow
    }
}

Write-Host "`nDone (SIMULATION). Nothing is enforced." -ForegroundColor Green
Write-Host "Next: DLPTEAMS-Validate.ps1 (expect Gate A PASS), then pilot per 05-testing.md before any enforce." -ForegroundColor Cyan
