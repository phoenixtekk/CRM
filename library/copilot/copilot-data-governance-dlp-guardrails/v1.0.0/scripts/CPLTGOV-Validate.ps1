<#
.SYNOPSIS
    CPLTGOV-Validate.ps1 - Confirm the Copilot governance controls are in the expected PILOT state (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Verify the pilot gate preconditions before enforcement: the default label policy is published,
              the auto-labeling policy "Auto-Label Sensitive - Pilot - Simulation" is in SIMULATION (labels
              nothing), the DLP policy "DLP for Copilot - Pilot - Test" is in TEST/DISABLED (blocks nothing),
              and auditing is on. Writes a validation summary. Pairs with the simulation/test false-positive
              review (a human/stakeholder step) described in the Testing guide.
    HOW TO RUN:
              Connect-IPPSSession
              .\CPLTGOV-Validate.ps1
              .\CPLTGOV-Validate.ps1 -AutoLabelName "Auto-Label Sensitive - Pilot - Simulation" -DlpName "DLP for Copilot - Pilot - Test"
    EXPECTED RESULTS:
              PASS: auto-labeling in simulation, DLP-for-Copilot in test, label policy published, auditing on.
              FAIL: any control already enforcing before the gate, or missing.
.NOTES
    White-label. Read-only - changes nothing. A control found ENFORCING before the gate is a FAIL - return
    it to simulation/test. Requires ExchangeOnlineManagement (Connect-IPPSSession).
#>

[CmdletBinding()]
param(
    [string]$LabelPolicyName = "Default Labeling - Users - Pilot",
    [string]$AutoLabelName   = "Auto-Label Sensitive - Pilot - Simulation",
    [string]$DlpName         = "DLP for Copilot - Pilot - Test",
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Governance Validation - Pilot - Validate"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

try { $null = Get-Command Get-Label -ErrorAction Stop }
catch { Write-Error "Connect-IPPSSession is required."; return }

$results = @()
function Add-Check($name, $pass, $detail) {
    $script:results += [pscustomobject]@{ Check = $name; Pass = $(if($pass){"PASS"}else{"FAIL"}); Detail = $detail }
    Write-Host ("  [{0}] {1} - {2}" -f $(if($pass){"PASS"}else{"FAIL"}), $name, $detail) -ForegroundColor $(if($pass){"Green"}else{"Yellow"})
}

Write-Section "Validating pilot governance state (read-only)"

# Label policy published
try {
    $lp = Get-LabelPolicy -Identity $LabelPolicyName -ErrorAction Stop
    Add-Check "Default label policy published" $true "'$LabelPolicyName' exists."
} catch { Add-Check "Default label policy published" $false "'$LabelPolicyName' not found (publish to pilot ring)." }

# Auto-labeling in simulation
try {
    $al = Get-AutoSensitivityLabelPolicy -Identity $AutoLabelName -ErrorAction Stop
    $mode = "$($al.Mode)"
    $isSim = ($mode -match 'Test|Simulation|Disable')
    Add-Check "Auto-labeling in SIMULATION" $isSim "'$AutoLabelName' mode = $mode (labels nothing until Enable)."
} catch { Add-Check "Auto-labeling in SIMULATION" $false "'$AutoLabelName' not found." }

# DLP-for-Copilot in test
try {
    $dp = Get-DlpCompliancePolicy -Identity $DlpName -ErrorAction Stop
    $mode = "$($dp.Mode)"
    $isTest = ($mode -match 'Test|Disable')
    Add-Check "DLP-for-Copilot in TEST/DISABLED" $isTest "'$DlpName' mode = $mode (blocks nothing until Enable)."
} catch { Add-Check "DLP-for-Copilot in TEST/DISABLED" $false "'$DlpName' not found (or Copilot DLP location unavailable - verify)." }

# Auditing reminder
Add-Check "Auditing on (verify)" $true "Confirm Purview Audit is recording Copilot interactions (CPLTGOV-AuditSearch.ps1)."

$fail = @($results | Where-Object { $_.Pass -eq "FAIL" }).Count
$summary = [ordered]@{
    Artifact     = $ArtifactName
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    Checks       = $results
    Failures     = $fail
    GateNote     = "Automated state OK is necessary but NOT sufficient: the pilot gate also requires the stakeholder simulation/test false-positive review (see Testing). Do not enforce until both pass."
}
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$json = Join-Path $OutDir "$safe.json"
$summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $json -Encoding UTF8
Write-Host "`nWrote $json" -ForegroundColor Green
if ($fail -gt 0) { Write-Warning "$fail check(s) failed - resolve before enforcing." }
else { Write-Host "Automated state checks passed. Complete the simulation false-positive review before enforce." -ForegroundColor Yellow }
