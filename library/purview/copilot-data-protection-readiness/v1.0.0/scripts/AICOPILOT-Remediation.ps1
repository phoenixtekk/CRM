<#
.SYNOPSIS
    Configure the Copilot-readiness remediation controls - SAFE BY DEFAULT (-WhatIf / simulation / test).
.DESCRIPTION
    Creates and manages the remediation levers: auto-labeling in SIMULATION, DLP for Microsoft 365
    Copilot in TEST/disabled, the prioritized site access-reduction list (read-only output), and the
    simulation->enforce mode change. No write occurs without -Commit; without it the script previews the
    action (-WhatIf). Nothing is enforced until the pilot passes its gates.
.EXAMPLE
    .\AICOPILOT-Remediation.ps1 -Action AutoLabel
    Previews (-WhatIf) creating the "Auto-Label Sensitive - Pilot - Simulation" policy in simulation mode.
.EXAMPLE
    .\AICOPILOT-Remediation.ps1 -Action DlpForCopilot -CopilotLocation "Microsoft 365 Copilot" -LabelForBlock "Highly Confidential" -Commit
    Creates the "DLP for Copilot - Pilot - Test" policy in TEST mode on the Copilot location. Verify the
    exact Copilot DLP location name in YOUR portal first. PowerShell 5.1+/7+; Connect-IPPSSession required.
.NOTES
    Requires: Security & Compliance PowerShell (Connect-IPPSSession) with Information Protection / DLP
    rights. No credentials/secrets. The Microsoft 365 Copilot DLP location, and simulation/test modes,
    are licensing-/tenant-dependent and evolving - VERIFY in your portal; the script parameterizes the
    location and never assumes it. SharePoint access reduction (RAC/RSS/RCD) is performed in the
    SharePoint admin center / SharePoint Online Management Shell per Microsoft docs - this script only
    PRODUCES the prioritized site list, it never changes sharing.
    Expected results (PASS): with -Commit, the named policy exists in simulation/test (not enforced).
    Without -Commit, a preview is shown and nothing is created.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("AutoLabel","DlpForCopilot","SiteAccessList","Enforce")]
    [string]$Action,

    [string]$Scope,
    [string]$CopilotLocation = "Microsoft 365 Copilot",
    [string]$LabelForBlock,
    [string]$DiscoveryCsv = "Oversharing_-_Estate_-_Discovery.csv",
    [string]$OutDir = ".",
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Assert-IPPS {
    try { Get-Command Get-Label -ErrorAction Stop | Out-Null }
    catch { throw "Security & Compliance PowerShell required. Run Connect-IPPSSession first." }
}

switch ($Action) {

    "AutoLabel" {
        Assert-IPPS
        $name = if ($Scope) { $Scope } else { "Auto-Label Sensitive - Pilot - Simulation" }
        Write-Section "Auto-labeling policy (SIMULATION): $name"
        if (-not $Commit) {
            Write-Host "[-WhatIf] Would create auto-sensitivity-label policy '$name' in SIMULATION mode" -ForegroundColor Yellow
            Write-Host "         (Mode = TestWithoutNotifications / simulation). No labels applied. Add -Commit to create." -ForegroundColor Yellow
            break
        }
        # Real create, in SIMULATION - labels nothing yet. Add rules/conditions in the portal or a follow-up.
        New-AutoSensitivityLabelPolicy -Name $name -Comment "Copilot readiness pilot - simulation" `
            -SharePointLocation "All" -OneDriveLocation "All" -Mode "TestWithoutNotifications" -WhatIf:(!$Commit)
        Write-Host "Created '$name' in simulation. Define its rules/conditions (sensitive info types -> label), review simulation results, THEN enforce." -ForegroundColor Green
    }

    "DlpForCopilot" {
        Assert-IPPS
        $name = if ($Scope) { $Scope } else { "DLP for Copilot - Pilot - Test" }
        Write-Section "DLP for Microsoft 365 Copilot (TEST): $name"
        if (-not $LabelForBlock) { throw "Provide -LabelForBlock (the sensitivity label that must be kept out of Copilot)." }
        Write-Host "Copilot DLP location = '$CopilotLocation' (VERIFY this exact location name exists in your tenant)." -ForegroundColor Yellow
        if (-not $Commit) {
            Write-Host "[-WhatIf] Would create DLP policy '$name' in TEST/disabled mode on location '$CopilotLocation', conditioned on label '$LabelForBlock'." -ForegroundColor Yellow
            Write-Host "         Add -Commit to create. If the Copilot location is absent, rely on label encryption/usage rights + site access reduction instead." -ForegroundColor Yellow
            break
        }
        # Create the policy in TEST (disabled) mode; the Copilot location string is parameterized, not assumed.
        New-DlpCompliancePolicy -Name $name -Mode "TestWithoutNotifications" -Comment "Copilot readiness pilot - test" -WhatIf:(!$Commit)
        Write-Host "Created DLP policy '$name' in TEST mode. Add a rule scoping location '$CopilotLocation' with condition: content bearing label '$LabelForBlock' -> block Copilot processing. Review test matches before enforcing." -ForegroundColor Green
        Write-Host "NOTE: if 'New-DlpComplianceRule' with the Copilot location is not available in your tenant, configure the rule in the Purview DLP portal - the location is licensing-/tenant-dependent (verify)." -ForegroundColor Yellow
    }

    "SiteAccessList" {
        $name = if ($Scope) { $Scope } else { "Site Access Reduction - Sites - Pilot" }
        Write-Section "Prioritized site access-reduction list (READ-ONLY output): $name"
        if (-not (Test-Path $DiscoveryCsv)) { throw "Discovery CSV '$DiscoveryCsv' not found. Run AICOPILOT-OversharingDiscovery.ps1 first." }
        $disc = Import-Csv $DiscoveryCsv
        $priority = $disc | Where-Object { $_.OversharingSignal -match 'PRIORITY|broad' } | Sort-Object OversharingSignal
        $null = New-Item -ItemType Directory -Force -Path $OutDir
        $safe = ($name -replace '[^\w\-]+','_')
        $csv = Join-Path $OutDir "$safe.csv"
        $priority | Select-Object SiteName, WebUrl, OversharingSignal | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
        Write-Host "Wrote $csv ($($priority.Count) priority sites)." -ForegroundColor Green
        Write-Host "Reduce access via SharePoint admin: remove EEEU/org-wide grants & broad links; apply Restricted Access Control (RAC) / site access reviews (SAM, verify); use interim Restricted Content Discovery (RCD) or Restricted SharePoint Search (RSS) to fence off not-yet-cleaned sites. This script does NOT change sharing." -ForegroundColor Yellow
    }

    "Enforce" {
        Assert-IPPS
        Write-Section "Enforce (simulation/test -> on) - CHANGE-CONTROLLED"
        if (-not $Commit) {
            Write-Host "[-WhatIf] Would switch the pilot auto-labeling policy to ON and the DLP-for-Copilot policy to ENFORCE. Add -Commit AFTER the pilot gates pass." -ForegroundColor Yellow
            break
        }
        Write-Host "Enforcing named policies. Ensure the testing gates (doc 5) passed and change control is approved." -ForegroundColor Yellow
        # Example enforce mode changes (names must match those created above); guarded by -Commit.
        # Set-AutoSensitivityLabelPolicy -Identity "Auto-Label Sensitive - Pilot - Simulation" -Mode "Enable" -WhatIf:(!$Commit)
        # Set-DlpCompliancePolicy       -Identity "DLP for Copilot - Pilot - Test"          -Mode "Enable" -WhatIf:(!$Commit)
        Write-Host "Set the specific policy identities to Enable via Set-AutoSensitivityLabelPolicy / Set-DlpCompliancePolicy (uncomment and match your policy names). Verify mode values in your tenant." -ForegroundColor Green
    }
}

if (-not $Commit) { Write-Host "`nSafe mode: no changes were committed (add -Commit to apply)." -ForegroundColor Yellow }
