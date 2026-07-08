<#
.SYNOPSIS
    PURVDSPM-Reduce-Oversharing.ps1 — create/adjust oversharing-reduction controls, pilot-in-simulation-first (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        The reduction helper for DSPM for AI. Depending on -Action it: creates an AUTO-LABELING policy in
        SIMULATION mode (labels nothing yet), creates a DLP policy for AI in TEST mode (enforces nothing),
        produces the prioritized SharingReview list, or flips named pilot policies from simulation/test to
        enforced. SAFE BY DEFAULT: prints intended actions under -WhatIf; makes changes only with -Commit,
        and even then creates policies in simulation/test — never enforcing on creation.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession).
        Dry-run (default, no change):
          .\PURVDSPM-Reduce-Oversharing.ps1 -Action AutoLabel -Scope "Oversharing Reduction - Pilot - Stage1" -SensitivityLabel "Confidential" -WhatIf
        Create pilot auto-labeling in SIMULATION:
          .\PURVDSPM-Reduce-Oversharing.ps1 -Action AutoLabel -SensitivityLabel "Confidential" -Commit
        Create pilot DLP for AI in TEST (VERIFY -DlpAiLocation for your tenant):
          .\PURVDSPM-Reduce-Oversharing.ps1 -Action DlpForAI -SensitivityLabel "Confidential" -DlpAiLocation "<verify-in-portal>" -Commit
        Produce the sharing-review target list from the oversharing export:
          .\PURVDSPM-Reduce-Oversharing.ps1 -Action SharingReview -OversharingCsv .\Oversharing-Report-Sites-Assess.csv
        Enforce (flip named pilot policies) AFTER the gate passes:
          .\PURVDSPM-Reduce-Oversharing.ps1 -Action Enforce -Commit
    EXPECTED RESULTS
        AutoLabel/DlpForAI: named policy exists in simulation/test (confirm in portal, Testing Test 8).
        SharingReview: Oversharing-Reduction-Targets.csv of prioritized sites. Enforce: named policies
        moved to on/enforce. Nothing is enforced without -Commit AND a deliberate -Action Enforce.
.NOTES
    White-label Microsoft Purview tooling. SAFE-by-default (-WhatIf). No credentials stored. HIGH-IMPACT
    changes are piloted in simulation/test first per the category model — DO NOT enforce until the pilot
    gate (Testing Test 9) passes.
    VERIFY IN YOUR TENANT: the DLP location that scopes a policy to Microsoft 365 Copilot / AI evolves and
    is licensing-dependent — pass it via -DlpAiLocation after confirming the exact name in Purview → DLP;
    this script does NOT assume it. This helper does not change SharePoint sharing directly (SharingReview
    only produces the target list); apply site-access/sharing restrictions via site owners / the portal /
    SharePoint Advanced Management under change control.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AutoLabel","DlpForAI","SharingReview","Enforce")]
    [string]$Action,

    [string]$Scope = "Oversharing Reduction - Pilot - Stage1",
    [string]$SensitivityLabel,                       # label DisplayName or GUID to apply / protect
    [string]$DlpAiLocation,                          # VERIFY in portal: the Copilot/AI DLP location name
    [string]$AutoLabelPolicyName = "Auto-Label Sensitive - Pilot - Simulation",
    [string]$DlpPolicyName       = "DLP for AI - Pilot - Test",
    [string]$OversharingCsv      = ".\Oversharing-Report-Sites-Assess.csv",
    [string]$TargetsOutPath      = ".\Oversharing-Reduction-Targets.csv",
    [switch]$Commit                                  # without -Commit, nothing is created/changed
)

$ErrorActionPreference = "Stop"
Write-Host "=== PURVDSPM Reduce Oversharing — Action=$Action (SAFE: simulation/test; -Commit required to change) ===" -ForegroundColor Cyan

# SharingReview needs no S&C session; the others do
if ($Action -ne "SharingReview") {
    try { Get-Label -ErrorAction Stop | Out-Null }
    catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first." -ForegroundColor Red; return }
}

function Confirm-Change([string]$desc, [scriptblock]$change) {
    if (-not $Commit) { Write-Host "  [DRY-RUN] Would: $desc  (re-run with -Commit to apply)" -ForegroundColor Yellow; return }
    if ($PSCmdlet.ShouldProcess($desc, "Apply")) {
        & $change
        Write-Host "  [DONE] $desc" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] $desc" -ForegroundColor Yellow
    }
}

switch ($Action) {

    "AutoLabel" {
        if (-not $SensitivityLabel) { Write-Host "-SensitivityLabel is required (the label to auto-apply)." -ForegroundColor Red; return }
        Write-Host "Creating auto-labeling policy '$AutoLabelPolicyName' in SIMULATION mode (labels nothing yet)." -ForegroundColor Cyan
        Confirm-Change "New-AutoSensitivityLabelPolicy '$AutoLabelPolicyName' (SIMULATION), label '$SensitivityLabel', SharePoint/OneDrive" {
            # TestWithoutNotifications = simulation: evaluates and reports what it WOULD label, applies nothing.
            New-AutoSensitivityLabelPolicy -Name $AutoLabelPolicyName `
                -ApplySensitivityLabel $SensitivityLabel `
                -SharePointLocation "All" -OneDriveLocation "All" `
                -Mode "TestWithoutNotifications" -ErrorAction Stop | Out-Null
            Write-Host "  Now add a matching auto-labeling RULE (New-AutoSensitivityLabelRule) with your sensitive-info-type conditions, then review simulation results in the portal." -ForegroundColor Cyan
        }
        Write-Host "Reminder: review SIMULATION results (Testing Test 9) before turning it on via -Action Enforce." -ForegroundColor Yellow
    }

    "DlpForAI" {
        if (-not $SensitivityLabel) { Write-Host "-SensitivityLabel is required (the labeled content to keep out of AI)." -ForegroundColor Red; return }
        if (-not $DlpAiLocation) {
            Write-Host "-DlpAiLocation not supplied. The DLP location that scopes a policy to Microsoft 365 Copilot / AI is" -ForegroundColor Red
            Write-Host "  licensing-dependent and evolving — CONFIRM the exact location name in Purview → DLP, then pass it via -DlpAiLocation." -ForegroundColor Red
            Write-Host "  This script does not assume the location name. Prefer the DSPM-for-AI one-click 'protect sensitive data in Copilot' policy in the portal if present." -ForegroundColor Yellow
            return
        }
        Write-Host "Creating DLP policy '$DlpPolicyName' in TEST mode (enforces nothing) for AI location '$DlpAiLocation'." -ForegroundColor Cyan
        Confirm-Change "New-DlpCompliancePolicy '$DlpPolicyName' (TEST) scoped to '$DlpAiLocation'" {
            # TestWithoutNotifications = test/simulation: matches are logged, nothing is blocked.
            New-DlpCompliancePolicy -Name $DlpPolicyName -Mode "TestWithoutNotifications" -ErrorAction Stop | Out-Null
            Write-Host "  Policy created in TEST. Now add a rule scoping the '$DlpAiLocation' location and the label '$SensitivityLabel' condition (New-DlpComplianceRule) per your portal's current DLP-for-AI parameters." -ForegroundColor Cyan
        }
        Write-Host "Reminder: review TEST matches (Testing Test 9) before enforcing." -ForegroundColor Yellow
    }

    "SharingReview" {
        if (-not (Test-Path $OversharingCsv)) { Write-Host "Oversharing export not found: $OversharingCsv (run PURVDSPM-AIExposure.ps1 first)." -ForegroundColor Red; return }
        Write-Host "Building prioritized sharing-review target list from $OversharingCsv ..." -ForegroundColor Cyan
        $data = Import-Csv -Path $OversharingCsv
        $targets = $data | Where-Object Site | Group-Object Site |
            Sort-Object Count -Descending |
            ForEach-Object { [pscustomobject]@{ Site = $_.Name; BroadShareEvents = $_.Count; Scope = $Scope; Action = "Review site access / restrict sharing with site owner" } }
        $targets | Export-Csv -Path $TargetsOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  {0} target site(s) written to {1}  (Oversharing Reduction - Targets)" -f @($targets).Count, $TargetsOutPath) -ForegroundColor Green
        Write-Host "  This helper does NOT change sharing. Restrict access via site owners / portal / SharePoint Advanced Management under change control." -ForegroundColor Yellow
    }

    "Enforce" {
        Write-Host "Flipping named PILOT policies from simulation/test to enforced. Only run AFTER the pilot gate passes (Testing Test 9)." -ForegroundColor Yellow
        # Auto-labeling: TestWithoutNotifications -> Enable (turn the label on)
        Confirm-Change "Set-AutoSensitivityLabelPolicy '$AutoLabelPolicyName' -Mode Enable" {
            Set-AutoSensitivityLabelPolicy -Identity $AutoLabelPolicyName -Mode "Enable" -ErrorAction Stop
        }
        # DLP: TestWithoutNotifications -> Enable (enforce)
        Confirm-Change "Set-DlpCompliancePolicy '$DlpPolicyName' -Mode Enable" {
            Set-DlpCompliancePolicy -Identity $DlpPolicyName -Mode "Enable" -ErrorAction Stop
        }
        Write-Host "  Widen scope to 'Oversharing Reduction - Broad - Stage2' as a separate change-controlled step." -ForegroundColor Cyan
    }
}

if (-not $Commit -and $Action -ne "SharingReview") {
    Write-Host "`nDRY-RUN complete — no changes made. Re-run with -Commit to create the simulation/test policy." -ForegroundColor Yellow
}
