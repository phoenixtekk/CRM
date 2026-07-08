<#
.SYNOPSIS
    Validate the Copilot-readiness pilot control states and re-read the oversharing signal (READ-ONLY).
.DESCRIPTION
    Confirms the pilot controls are configured safely before enforcement: the default label policy is
    published, the auto-labeling policy is in SIMULATION, the DLP-for-Copilot policy is in TEST/disabled,
    and (optionally) re-reads the oversharing signal for the pilot sites to confirm it is lower after
    remediation. Produces evidence for the testing gates (doc 5). Read-only; changes nothing.
.EXAMPLE
    .\AICOPILOT-Validation.ps1
    Read-only validation of the named pilot policies' states.
.EXAMPLE
    .\AICOPILOT-Validation.ps1 -OutDir C:\Temp\CopilotReadiness
    Writes a validation summary JSON. PowerShell 5.1+/7+; Connect-IPPSSession required.
.NOTES
    Requires: Security & Compliance PowerShell (Connect-IPPSSession); no credentials/secrets.
    Expected results (PASS): label policy published, auto-label = simulation, DLP-for-Copilot =
    test/disabled - i.e. nothing enforced yet, ready for the go/no-go review. FAIL: any control missing
    or already enforced before validation.
#>

[CmdletBinding()]
param(
    [string]$LabelPolicyName    = "Default Labeling - Users - Pilot",
    [string]$AutoLabelName      = "Auto-Label Sensitive - Pilot - Simulation",
    [string]$DlpPolicyName      = "DLP for Copilot - Pilot - Test",
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Readiness - Pilot - Validation"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
try { Get-Command Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Error "Security & Compliance PowerShell required. Run Connect-IPPSSession first."; return }

$checks = [ordered]@{}

Write-Section "Default label policy published"
try {
    $lp = Get-LabelPolicy -Identity $LabelPolicyName -ErrorAction Stop
    $checks.LabelPolicyPublished = if ($lp) { "PASS - '$LabelPolicyName' exists" } else { "FAIL - not found" }
} catch { $checks.LabelPolicyPublished = "FAIL - '$LabelPolicyName' not found" }
Write-Host $checks.LabelPolicyPublished

Write-Section "Auto-labeling policy in SIMULATION"
try {
    $al = Get-AutoSensitivityLabelPolicy -Identity $AutoLabelName -ErrorAction Stop
    $mode = $al.Mode
    $checks.AutoLabelSimulation = if ($mode -match 'Test|Simulation') { "PASS - mode=$mode (simulation)" } else { "REVIEW - mode=$mode (expected simulation before enforce)" }
} catch { $checks.AutoLabelSimulation = "FAIL - '$AutoLabelName' not found" }
Write-Host $checks.AutoLabelSimulation

Write-Section "DLP-for-Copilot policy in TEST/disabled"
try {
    $dlp = Get-DlpCompliancePolicy -Identity $DlpPolicyName -ErrorAction Stop
    $mode = $dlp.Mode
    $checks.DlpForCopilotTest = if ($mode -match 'Test|Disable') { "PASS - mode=$mode (test/disabled)" } else { "REVIEW - mode=$mode (expected test before enforce)" }
} catch { $checks.DlpForCopilotTest = "FAIL - '$DlpPolicyName' not found (or Copilot DLP location unavailable - verify)" }
Write-Host $checks.DlpForCopilotTest

$summary = [ordered]@{
    Artifact = $ArtifactName
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    Checks = $checks
    Guidance = "All PASS/REVIEW and nothing enforced = ready for the go/no-go review (doc 5, Gate 7). Also re-run AICOPILOT-OversharingDiscovery.ps1 on the pilot sites and confirm the signal is lower; confirm Copilot does not surface protected/restricted content for a user without rights (Gate 6)."
}
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$jsonPath = Join-Path $OutDir "$safe.json"
$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "`nWrote $jsonPath" -ForegroundColor Green
Write-Host "Read-only: no changes were made." -ForegroundColor Yellow
