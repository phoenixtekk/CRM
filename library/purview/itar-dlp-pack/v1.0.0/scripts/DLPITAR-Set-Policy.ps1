<#
.SYNOPSIS
    DLPITAR-Set-Policy.ps1 — plan/create the ITAR technical-data egress DLP policy in SIMULATION, and promote/rollback under control (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Configuration/remediation tool for the ITAR technical-data DLP policy. It DEFAULTS TO -WhatIf
        (preview only) and writes NOTHING until you re-run with -Commit. Its jobs:
          * Create the policy "ITAR Technical-Data Egress - AllWorkloads - Pilot" and its detection rule
            "Technical-Data Egress Rule - Markings+Label - v1" in a SIMULATION/TEST mode
            (TestWithNotifications / TestWithoutNotifications) — nothing blocks.
          * The rule keys on the technical-data classification (a custom SIT and/or the
            "Export Controlled // ITAR" sensitivity label) with the ITAR-relevant egress condition
            (recipient/scope is OUTSIDE the organization) and the staged action (Block / notify).
          * -PromoteToEnforce sets the policy Mode = Enable (the configured egress action applies).
          * -Disable rolls the policy back to Disable (instant, non-enforcing).
        The exact rule conditions (label condition, external-recipient scope, action) may be finished in
        the PORTAL where a parameter is not exposed in your tenant — the script creates a safe
        simulation-mode shell and prints precisely what to complete. It never enforces without
        -PromoteToEnforce -Commit, and never hard-codes credentials.
    HOW TO RUN
        Preview the intended policy (default, no change):
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Set-Policy.ps1 -SitName "Technical Data SIT - Export Markings - Custom"
        Create it in SIMULATION mode (still no enforcement):
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Set-Policy.ps1 -SitName "Technical Data SIT - Export Markings - Custom" -Mode TestWithNotifications -Commit
        Promote to ENFORCE (in a change window, after gates pass):
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit
        Roll back:
          powershell -ExecutionPolicy Bypass -File .\DLPITAR-Set-Policy.ps1 -Disable -Commit

        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) and a Compliance Administrator / DLP
        Compliance Management admin (MFA-capable, Requirement 2.2). Verify capability/paths against your
        licensing/tenant. No credentials in code.
    EXPECTED RESULTS
        In preview: the intended policy/rule plan and any remaining portal steps, with no change. With
        -Commit: the policy is created in SIMULATION (or promoted/disabled as requested). PASS = plan
        prints / the requested state is applied without error. Confirm mode with Get-DlpCompliancePolicy.
.NOTES
    White-label. CHANGE tool — defaults to -WhatIf; simulation-first; enforce only via -PromoteToEnforce -Commit.
    Security & Compliance PowerShell. No credentials in code. Uses documented DLP cmdlets; portal finishes what PowerShell does not expose.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string] $PolicyName = 'ITAR Technical-Data Egress - AllWorkloads - Pilot',
    [string] $RuleName   = 'Technical-Data Egress Rule - Markings+Label - v1',
    [string] $SitName    = 'Technical Data SIT - Export Markings - Custom',
    [string] $LabelName  = 'Export Controlled // ITAR',
    [string] $PilotGroup = 'ITAR Pilot Ring - Stage1',
    [ValidateSet('TestWithNotifications','TestWithoutNotifications')]
    [string] $Mode       = 'TestWithNotifications',
    [switch] $PromoteToEnforce,
    [switch] $Disable,
    [switch] $Commit,
    [string] $ConnectionUri = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
)

if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = -not $Commit }
$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

Write-Section 'Intended plan for the ITAR technical-data egress policy'
Write-Host ("Policy : {0}" -f $PolicyName)
Write-Host ("Rule   : {0}" -f $RuleName)
Write-Host ("Detect : SIT '{0}'  AND/OR  sensitivity label '{1}'  (prefer the label — most durable)" -f $SitName, $LabelName)
Write-Host  "Egress : recipient / share scope is OUTSIDE the organization  ->  Block (with policy tip / override per design)"
Write-Host ("Scope  : Exchange, SharePoint, OneDrive, Teams (Endpoint where licensed); target group '{0}'" -f $PilotGroup)
Write-Host  "Mode   : SIMULATION first ($Mode) — nothing blocks until -PromoteToEnforce -Commit."

if ($WhatIfPreference) { Write-Host ''; Write-Host 'MODE: PREVIEW (-WhatIf) — nothing will be changed. Re-run with -Commit to apply.' -ForegroundColor Yellow }
else                   { Write-Host ''; Write-Host 'MODE: APPLY (-Commit).' -ForegroundColor Red }

if (-not $Commit) {
    Write-Host ''
    Write-Host 'Plan-only (no -Commit). Portal path if you prefer to build it there:'
    Write-Host '  purview.microsoft.com -> Data loss prevention -> Policies -> Create policy.'
    return
}

try {
    Write-Section 'Connecting to Security & Compliance PowerShell'
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
        Connect-IPPSSession -ConnectionUri $ConnectionUri | Out-Null
    }
    Write-Host 'Connected.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect: {0}" -f $_.Exception.Message); return }

$existing = $null
try { $existing = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue } catch {}

# --- Rollback path ----------------------------------------------------------------------------------
if ($Disable) {
    Write-Section 'Rollback: set policy to Disable (non-enforcing)'
    if (-not $existing) { Write-Host ("Policy '{0}' not found — nothing to disable." -f $PolicyName) -ForegroundColor Yellow; return }
    if ($PSCmdlet.ShouldProcess($PolicyName, 'Set DLP policy Mode = Disable')) {
        try {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode 'Disable' -ErrorAction Stop | Out-Null
            Write-Host ("Policy '{0}' set to Disable. It no longer enforces (allow propagation time)." -f $PolicyName) -ForegroundColor Green
            Write-Host 'Stamp this into Change Record - ITAR DLP - ChangeControl.'
        }
        catch { Write-Warning ("Could not disable the policy: {0}" -f $_.Exception.Message) }
    }
    return
}

# --- Promote to enforce ------------------------------------------------------------------------------
if ($PromoteToEnforce) {
    Write-Section 'Promote to ENFORCE (Mode = Enable) — the configured egress action will apply'
    if (-not $existing) { Write-Host ("Policy '{0}' not found. Create it in simulation first." -f $PolicyName) -ForegroundColor Yellow; return }
    Write-Host ("Current mode: {0}" -f $existing.Mode)
    if ($PSCmdlet.ShouldProcess($PolicyName, 'Set DLP policy Mode = Enable (ENFORCE)')) {
        try {
            Set-DlpCompliancePolicy -Identity $PolicyName -Mode 'Enable' -ErrorAction Stop | Out-Null
            Write-Host ("Policy '{0}' promoted to ENFORCE (Mode = Enable)." -f $PolicyName) -ForegroundColor Green
            Write-Host 'Verify with a controlled synthetic test; rollback with -Disable -Commit if needed.'
            Write-Host 'Stamp this into Change Record - ITAR DLP - ChangeControl.'
        }
        catch { Write-Warning ("Could not promote the policy: {0}" -f $_.Exception.Message) }
    }
    return
}

# --- Create in simulation ----------------------------------------------------------------------------
Write-Section 'Create the policy + rule in SIMULATION mode'
if ($existing) {
    Write-Host ("Policy '{0}' already exists (Mode: {1}). Not recreating it." -f $PolicyName, $existing.Mode) -ForegroundColor Yellow
} else {
    if ($PSCmdlet.ShouldProcess($PolicyName, "Create DLP policy in SIMULATION mode ($Mode)")) {
        try {
            New-DlpCompliancePolicy -Name $PolicyName -Mode $Mode `
                -Comment 'ITAR technical-data egress control — SIMULATION first. Finish label/external-scope conditions and pilot scoping in the portal; promote via -PromoteToEnforce -Commit.' `
                -ExchangeLocation 'All' -SharePointLocation 'All' -OneDriveLocation 'All' -TeamsLocation 'All' `
                -ErrorAction Stop | Out-Null
            Write-Host ("Created '{0}' in SIMULATION mode ({1})." -f $PolicyName, $Mode) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Could not create the policy shell: {0}" -f $_.Exception.Message)
            Write-Host 'Create it in the portal instead (Data loss prevention -> Policies).'
            return
        }
    } else { Write-Host ("WOULD create '{0}' in SIMULATION mode." -f $PolicyName) -ForegroundColor Yellow; return }
}

# Attempt the detection rule with documented parameters; fall back to portal instructions.
$rule = $null
try { $rule = Get-DlpComplianceRule -Identity $RuleName -ErrorAction SilentlyContinue } catch {}
if ($rule) {
    Write-Host ("Rule '{0}' already exists — not recreating." -f $RuleName) -ForegroundColor Yellow
} elseif ($PSCmdlet.ShouldProcess($RuleName, 'Create DLP rule (technical-data + external-scope, notify only in simulation)')) {
    try {
        $sitCondition = @(@{ Name = $SitName; minCount = '1' })
        New-DlpComplianceRule -Name $RuleName -Policy $PolicyName `
            -ContentContainsSensitiveInformation $sitCondition `
            -AccessScope 'NotInOrganization' `
            -NotifyUser 'SiteAdmin','LastModifier','Owner' `
            -Comment 'Simulation: matches technical-data SIT sent/shared outside the org. Add the "Export Controlled // ITAR" label condition and confirm the Block action in the portal before enforcing.' `
            -ErrorAction Stop | Out-Null
        Write-Host ("Created rule '{0}' (notify only — no BlockAccess in simulation)." -f $RuleName) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Could not create the rule via cmdlet: {0}" -f $_.Exception.Message)
        Write-Host 'Finish the rule in the portal (see below) — some conditions may be portal-only in your tenant.'
    }
}

Write-Section 'Finish in the portal, then validate'
Write-Host ("1. Add the label condition: content has sensitivity label '{0}' (most durable ITAR signal)." -f $LabelName)
Write-Host  "2. Confirm the external-recipient / external-sharing scope and the Block action + policy tip wording."
Write-Host ("3. Scope the policy to the pilot group '{0}' (and Endpoint locations where E5/onboarding allow)." -f $PilotGroup)
Write-Host  "4. Keep it in SIMULATION; run DLPITAR-Validation.ps1 and follow 05-testing.md."
Write-Host  "5. Promote only after every gate passes and export/legal confirm (Requirement 2.6):"
Write-Host  "     DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit"
Write-Host  "Verify condition/action availability and paths against your licensing/tenant."
