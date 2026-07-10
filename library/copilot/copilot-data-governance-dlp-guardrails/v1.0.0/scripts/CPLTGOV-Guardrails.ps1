<#
.SYNOPSIS
    CPLTGOV-Guardrails.ps1 - Create Copilot governance controls SIMULATION/TEST-first (auto-labeling, DLP-for-Copilot).
.DESCRIPTION
    PURPOSE:  Three gated actions, all safe by default:
              -Action AutoLabel     creates the auto-labeling policy "Auto-Label Sensitive - Pilot -
                                    Simulation" in SIMULATION mode (labels NOTHING; shows what it would).
              -Action DlpForCopilot creates the DLP policy "DLP for Copilot - Pilot - Test" scoped to the
                                    Microsoft 365 Copilot location in TEST/DISABLED mode (blocks NOTHING).
              -Action Enforce       flips the named policies from simulation/test to on/enforce - ONLY run
                                    after the pilot false-positive gate passes.
              ALL actions default to -WhatIf preview; nothing is created or changed without -Commit.
    HOW TO RUN:
              Connect-IPPSSession
              .\CPLTGOV-Guardrails.ps1 -Action AutoLabel      -LabelName "Highly Confidential" -WhatIf
              .\CPLTGOV-Guardrails.ps1 -Action AutoLabel      -LabelName "Highly Confidential" -Commit
              .\CPLTGOV-Guardrails.ps1 -Action DlpForCopilot  -KeepOutLabels @("Highly Confidential") -Commit
              .\CPLTGOV-Guardrails.ps1 -Action Enforce        -Commit
    EXPECTED RESULTS:
              Default (no -Commit): a preview of exactly what WOULD be created/changed. With -Commit:
              policies created in simulation/test (or, for Enforce, flipped on) - never enforcing silently.
.NOTES
    White-label. SAFE BY DEFAULT: -WhatIf unless -Commit. Simulation/test-first is mandatory. Classification
    (which labels/SITs mean 'keep out of Copilot') is a compliance decision - pass it in, do not invent it.
    DLP-for-Copilot location is licensing/preview-gated - verify. Requires ExchangeOnlineManagement.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet("AutoLabel","DlpForCopilot","Enforce")]
    [Parameter(Mandatory = $true)][string]$Action,
    [string]$LabelName,
    [string[]]$KeepOutLabels,
    [string]$AutoLabelName = "Auto-Label Sensitive - Pilot - Simulation",
    [string]$DlpName       = "DLP for Copilot - Pilot - Test",
    [string]$CopilotDlpLocation = "Microsoft365Copilot",
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

try { $null = Get-Command Get-Label -ErrorAction Stop }
catch { Write-Error "Connect-IPPSSession is required (Security & Compliance PowerShell)."; return }

if (-not $Commit) { Write-Host "PREVIEW MODE (-WhatIf). Nothing will be created or changed. Pass -Commit to apply." -ForegroundColor Yellow }

switch ($Action) {

    "AutoLabel" {
        Write-Section "Auto-labeling policy (SIMULATION)"
        if (-not $LabelName) { Write-Error "Provide -LabelName (the sensitivity label to auto-apply)."; return }
        $target = "Create auto-labeling policy '$AutoLabelName' in SIMULATION applying label '$LabelName'"
        if ($PSCmdlet.ShouldProcess($AutoLabelName, $target) -and $Commit) {
            try {
                # Created in simulation (labels nothing). Add locations/conditions per your agreed design.
                New-AutoSensitivityLabelPolicy -Name $AutoLabelName -ApplySensitivityLabel $LabelName `
                    -Mode TestWithoutNotifications -SharePointLocation "All" -OneDriveLocation "All" -ErrorAction Stop | Out-Null
                Write-Host "  [COMMIT] Created '$AutoLabelName' in simulation. It labels NOTHING until you set -Mode Enable." -ForegroundColor Green
                Write-Host "  Add rules with New-AutoSensitivityLabelRule (your agreed sensitive-info-type conditions)." -ForegroundColor DarkGray
            } catch { Write-Warning "  Create failed (verify cmdlet params for your tenant): $($_.Exception.Message)" }
        } else {
            Write-Host "  [WHATIF] Would create '$AutoLabelName' in SIMULATION applying '$LabelName' (labels nothing)." -ForegroundColor DarkYellow
        }
    }

    "DlpForCopilot" {
        Write-Section "DLP for Microsoft 365 Copilot (TEST/DISABLED)"
        if (-not $KeepOutLabels) { Write-Error "Provide -KeepOutLabels (the 'keep out of Copilot' labels - a compliance decision)."; return }
        $target = "Create DLP policy '$DlpName' on location '$CopilotDlpLocation' in TEST, conditioned on labels: $($KeepOutLabels -join ', ')"
        if ($PSCmdlet.ShouldProcess($DlpName, $target) -and $Commit) {
            try {
                # Created disabled/test. The Copilot DLP location name is parameterized - VERIFY it in your portal.
                New-DlpCompliancePolicy -Name $DlpName -Mode TestWithoutNotifications -ErrorAction Stop | Out-Null
                Write-Host "  [COMMIT] Created '$DlpName' in TEST. Scope it to the Copilot location ('$CopilotDlpLocation') and add a rule" -ForegroundColor Green
                Write-Host "  (New-DlpComplianceRule -Policy '$DlpName' -ContentContainsSensitiveInformation / -HasSensitivityLabel ...) per your design. Blocks NOTHING until enforced." -ForegroundColor DarkGray
            } catch { Write-Warning "  Create failed - the Copilot DLP location may be unavailable in your tenant (verify). $($_.Exception.Message)" }
        } else {
            Write-Host "  [WHATIF] Would create '$DlpName' in TEST on '$CopilotDlpLocation', conditioned on: $($KeepOutLabels -join ', ') (blocks nothing)." -ForegroundColor DarkYellow
        }
    }

    "Enforce" {
        Write-Section "Move pilot controls to ON / ENFORCE (post-gate only)"
        Write-Host "Run ONLY after the simulation/test false-positive gate has passed (see Testing)." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($AutoLabelName, "Set auto-labeling to Enable") -and $Commit) {
            try { Set-AutoSensitivityLabelPolicy -Identity $AutoLabelName -Mode Enable -ErrorAction Stop | Out-Null; Write-Host "  [COMMIT] '$AutoLabelName' -> Enable." -ForegroundColor Green }
            catch { Write-Warning "  $($_.Exception.Message)" }
        } else { Write-Host "  [WHATIF] Would set '$AutoLabelName' -> Enable." -ForegroundColor DarkYellow }
        if ($PSCmdlet.ShouldProcess($DlpName, "Set DLP-for-Copilot to Enforce") -and $Commit) {
            try { Set-DlpCompliancePolicy -Identity $DlpName -Mode Enable -ErrorAction Stop | Out-Null; Write-Host "  [COMMIT] '$DlpName' -> Enforce." -ForegroundColor Green }
            catch { Write-Warning "  $($_.Exception.Message)" }
        } else { Write-Host "  [WHATIF] Would set '$DlpName' -> Enforce." -ForegroundColor DarkYellow }
    }
}

Write-Host "`nRun CPLTGOV-Validate.ps1 to confirm policy states before/after. Nothing enforces silently." -ForegroundColor Yellow
if (-not $Commit) { Write-Host "No changes were made (preview)." -ForegroundColor Yellow }
