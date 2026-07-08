<#
.SYNOPSIS
    AIEXPOSE-PilotRemediation.ps1 — validate a recommended fix for a top exposure risk in SIMULATION (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Proves the recommended remediation PATH for a priority exposure risk WITHOUT changing content or
        enforcing anything — the assessment's "pilot in simulation" step. Depending on -Action it either
        creates an AUTO-LABELING policy in SIMULATION mode (evaluates and reports what it WOULD label,
        applies nothing) so you can validate that labeling would land on the right content, or produces a
        prioritized SHARING-restriction target list from the risk register for site owners to act on.
        SAFE BY DEFAULT: prints intended actions under -WhatIf; creates the simulation policy only with
        -Commit; NEVER enforces. Turning a validated fix into an enforced program is a follow-on
        engagement, not this assessment.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession).
        Dry-run (default, no change):
          .\AIEXPOSE-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -WhatIf
        Create the SIMULATION validation policy (labels nothing):
          .\AIEXPOSE-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -Commit
        Produce the sharing-restriction target list from the register (no S&C session needed):
          .\AIEXPOSE-PilotRemediation.ps1 -Action SharingTargets -RiskRegisterCsv .\AIEXPOSE-RiskRegister-Estate-Rank.csv
    EXPECTED RESULTS
        AutoLabelSim: a named policy in SIMULATION mode exists (confirm in portal; Testing Test 8), labels
        nothing. SharingTargets: .\AIEXPOSE-SharingTargets.csv of prioritized sites for site-owner review.
        Nothing is created without -Commit; nothing is ever enforced by this script.
.NOTES
    White-label Microsoft Purview tooling. SAFE-by-default (-WhatIf); simulation-only. No credentials
    stored. HIGH-IMPACT changes are piloted in simulation per the category model — this script validates
    the fix path and DOES NOT enforce; enforcement/expansion is a separate change-controlled follow-on.
    This helper does not change SharePoint sharing directly (SharingTargets only produces the list); apply
    restrictions via site owners / the portal / SharePoint Advanced Management under change control.
    Determinations (whether to remediate) remain with compliance/records/privacy/legal. No cmdlets invented.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("AutoLabelSim","SharingTargets")]
    [string]$Action,

    [string]$SensitivityLabel,                                   # label DisplayName or GUID to validate
    [string]$SimPolicyName   = "Exposure Remediation - Pilot - Simulation",
    [string]$RiskRegisterCsv = ".\AIEXPOSE-RiskRegister-Estate-Rank.csv",
    [string]$TargetsOutPath  = ".\AIEXPOSE-SharingTargets.csv",
    [switch]$Commit                                              # without -Commit, nothing is created
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIEXPOSE Pilot Remediation — Action=$Action (SAFE: simulation-only; -Commit required to create) ===" -ForegroundColor Cyan

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
        if (-not $SensitivityLabel) { Write-Host "-SensitivityLabel is required (the label whose fit you are validating)." -ForegroundColor Red; return }

        Write-Host "Creating auto-labeling policy '$SimPolicyName' in SIMULATION mode — it labels NOTHING; it only reports what it WOULD label." -ForegroundColor Cyan
        Confirm-Change "New-AutoSensitivityLabelPolicy '$SimPolicyName' (SIMULATION), label '$SensitivityLabel', SharePoint/OneDrive" {
            # TestWithoutNotifications = simulation: evaluates content and reports would-be matches; applies no label.
            New-AutoSensitivityLabelPolicy -Name $SimPolicyName `
                -ApplySensitivityLabel $SensitivityLabel `
                -SharePointLocation "All" -OneDriveLocation "All" `
                -Mode "TestWithoutNotifications" -ErrorAction Stop | Out-Null
            Write-Host "  Now add a matching auto-labeling RULE (New-AutoSensitivityLabelRule) with your sensitive-info-type conditions, then review SIMULATION results in the portal." -ForegroundColor Cyan
        }
        Write-Host "This validates the fix PATH only. Review simulation results (Testing Test 8-9); enforcement/expansion is a separate follow-on, not this assessment." -ForegroundColor Yellow
    }

    "SharingTargets" {
        if (-not (Test-Path $RiskRegisterCsv)) { Write-Host "Risk register not found: $RiskRegisterCsv (run AIEXPOSE-RiskRegister.ps1 first)." -ForegroundColor Red; return }
        Write-Host "Building prioritized sharing-restriction target list from $RiskRegisterCsv ..." -ForegroundColor Cyan
        $reg = Import-Csv -Path $RiskRegisterCsv
        $targets = $reg | Where-Object { $_.RiskType -like "Oversharing*" -and $_.RiskItem } |
            Sort-Object { [int]$_.Score } -Descending |
            ForEach-Object { [pscustomobject]@{ Site = $_.RiskItem; Score = $_.Score; Action = "Review site access / restrict sharing with site owner (under change control)" } }
        $targets | Export-Csv -Path $TargetsOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("  {0} target site(s) written to {1}  (Sharing restriction targets)" -f @($targets).Count, $TargetsOutPath) -ForegroundColor Green
        Write-Host "  This helper does NOT change sharing. Restrict access via site owners / portal / SharePoint Advanced Management under change control." -ForegroundColor Yellow
    }
}

if (-not $Commit -and $Action -eq "AutoLabelSim") {
    Write-Host "`nDRY-RUN complete — no policy created. Re-run with -Commit to create the SIMULATION validation policy (still labels nothing)." -ForegroundColor Yellow
}
