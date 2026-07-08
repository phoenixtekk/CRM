<#
.SYNOPSIS
    IPASSESS-PilotRemediation.ps1 — validate ONE recommended fix in SIMULATION (SAFE: -WhatIf by default; never enforces).
.DESCRIPTION
    PURPOSE
        Proves the recommended remediation PATH for the top information-protection gap WITHOUT changing
        content or enforcing anything — the assessment's "pilot in simulation" step. With
        -Action AutoLabelSim it creates an AUTO-LABELING policy in SIMULATION mode
        (Mode = TestWithoutNotifications) that evaluates content and reports what it WOULD label and
        applies NO label to anything. With -Action LabelPublishPreview it prints the exact commands to
        publish an existing unpublished label to a small PILOT GROUP only (it does not run them unless you
        follow the printed guidance) so the publish path can be proven without a tenant-wide change.
        SAFE BY DEFAULT: prints intended actions under -WhatIf; creates the simulation policy only with
        -Commit; NEVER enables or enforces anything.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession).
        Dry-run (default, no change):
          .\IPASSESS-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -WhatIf
        Create the SIMULATION validation policy (labels nothing):
          .\IPASSESS-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -Commit
        Show the pilot-group label-publish path (prints commands only):
          .\IPASSESS-PilotRemediation.ps1 -Action LabelPublishPreview -SensitivityLabel "Confidential" -PilotGroup "Information Protection - Pilot Users"
    EXPECTED RESULTS
        AutoLabelSim: a policy named 'Information Protection - Pilot - Simulation' in SIMULATION mode
        exists (confirm in portal; Testing Test 8) and labels nothing; add a matching rule with your SIT
        conditions to see would-be matches. LabelPublishPreview: the exact New-LabelPolicy command scoped
        to the pilot group, printed for review. Nothing is created without -Commit; nothing is ever enforced.
.NOTES
    White-label Microsoft Purview tooling. SAFE-by-default (-WhatIf); simulation/pilot-group only. No
    credentials stored. HIGH-IMPACT changes are piloted in simulation per the category model — this script
    validates the fix path and DOES NOT enforce; enforcement/expansion is a separate change-controlled
    follow-on. Determinations (whether to remediate) remain with compliance/records/privacy/legal. No
    cmdlets invented.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AutoLabelSim","LabelPublishPreview")]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$SensitivityLabel,                                        # label DisplayName or GUID to validate
    [string]$SimPolicyName = "Information Protection - Pilot - Simulation",
    [string]$PilotGroup    = "Information Protection - Pilot Users",
    [switch]$Commit                                                   # without -Commit, nothing is created
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPASSESS Pilot Remediation — Action=$Action (SAFE: simulation/pilot-only; -Commit required to create) ===" -ForegroundColor Cyan

function Confirm-Change([string]$desc, [scriptblock]$change) {
    if (-not $Commit) { Write-Host "  [DRY-RUN] Would: $desc  (re-run with -Commit to create the simulation policy)" -ForegroundColor Yellow; return }
    if ($PSCmdlet.ShouldProcess($desc, "Create (simulation)")) {
        & $change
        Write-Host "  [DONE] $desc" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] $desc" -ForegroundColor Yellow
    }
}

switch ($Action) {

    "AutoLabelSim" {
        try { Get-Label -ErrorAction Stop | Out-Null }
        catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first." -ForegroundColor Red; return }

        # Guard: don't collide with an existing policy of the same name
        try {
            $existing = Get-AutoSensitivityLabelPolicy -Identity $SimPolicyName -ErrorAction Stop
            if ($existing) { Write-Host "  A policy named '$SimPolicyName' already exists (Mode=$($existing.Mode)). Review/remove it before recreating." -ForegroundColor Yellow; return }
        } catch { <# not found — good, we can create it #> }

        Write-Host "Creating auto-labeling policy '$SimPolicyName' in SIMULATION mode — it labels NOTHING; it only reports what it WOULD label." -ForegroundColor Cyan
        Confirm-Change "New-AutoSensitivityLabelPolicy '$SimPolicyName' (SIMULATION = TestWithoutNotifications), label '$SensitivityLabel', SharePoint/OneDrive" {
            # TestWithoutNotifications = simulation: evaluates content and reports would-be matches; applies no label.
            New-AutoSensitivityLabelPolicy -Name $SimPolicyName `
                -ApplySensitivityLabel $SensitivityLabel `
                -SharePointLocation "All" -OneDriveLocation "All" `
                -Mode "TestWithoutNotifications" -ErrorAction Stop | Out-Null
            Write-Host "  Now add a matching RULE with your sensitive-info-type conditions:" -ForegroundColor Cyan
            Write-Host "    New-AutoSensitivityLabelRule -Policy '$SimPolicyName' -Name '<rule>' -ContentContainsSensitiveInformation @(@{Name='<SIT>'}) -Workload 'SharePoint,OneDrive'" -ForegroundColor DarkGray
            Write-Host "  Then review SIMULATION results in the portal (Information Protection -> Auto-labeling -> the policy -> Simulation)." -ForegroundColor Cyan
        }
        Write-Host "This validates the fix PATH only. Review simulation results (Testing Test 8); enforcement/expansion is a separate follow-on, not this assessment." -ForegroundColor Yellow
    }

    "LabelPublishPreview" {
        try { Get-Label -ErrorAction Stop | Out-Null }
        catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first." -ForegroundColor Red; return }

        Write-Host "The lowest-risk pilot is publishing an EXISTING label to the pilot group ONLY. Review and run this command yourself under change control:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    New-LabelPolicy -Name 'Information Protection - Label Policy - Pilot' \`" -ForegroundColor Green
        Write-Host "        -Settings @{} \`" -ForegroundColor Green
        Write-Host "        -Labels '$SensitivityLabel' \`" -ForegroundColor Green
        Write-Host "        -ModernGroupLocation '$PilotGroup'" -ForegroundColor Green
        Write-Host ""
        Write-Host "  This publishes to the pilot group only — no one else is affected. Rollback: Remove-LabelPolicy 'Information Protection - Label Policy - Pilot'." -ForegroundColor Yellow
        Write-Host "  (Printed for review — this script does not create the label policy for you. Publishing scope is a change-controlled action.)" -ForegroundColor DarkGray
    }
}

if (-not $Commit -and $Action -eq "AutoLabelSim") {
    Write-Host "`nDRY-RUN complete — no policy created. Re-run with -Commit to create the SIMULATION validation policy (still labels nothing)." -ForegroundColor Yellow
}
Write-Host "Rollback the simulation pilot when done: Remove-AutoSensitivityLabelPolicy '$SimPolicyName' (it labeled nothing, so nothing reverts)." -ForegroundColor DarkGray
