<#
.SYNOPSIS
    Compile the Copilot data-protection go/no-go readiness record (READ-ONLY).
.DESCRIPTION
    Assembles the readiness evidence for stakeholder sign-off: the before/after oversharing picture, the
    remediation controls applied and their state (label policy, auto-labeling, DLP-for-Copilot), and the
    residual risk. Writes "Copilot Readiness - Tenant - GoNoGo". The go/no-go DECISION is the
    stakeholders' (compliance/records/privacy/legal); this report is the evidence, not the determination.
    Read-only; changes nothing.
.EXAMPLE
    .\AICOPILOT-ReadinessReport.ps1 -BeforeCsv Oversharing_-_Estate_-_Discovery.csv
    Compiles the go/no-go record from the current control states and the before-state discovery export.
.EXAMPLE
    .\AICOPILOT-ReadinessReport.ps1 -BeforeCsv before.csv -AfterCsv after.csv -OutDir C:\Temp\CopilotReadiness
    Includes an after-state re-measure for before/after comparison. PowerShell 5.1+/7+; Connect-IPPSSession required.
.NOTES
    Requires: Security & Compliance PowerShell (Connect-IPPSSession); no credentials/secrets.
    Expected results (PASS): a complete, internally consistent go/no-go record is written for sign-off.
    FAIL: missing control states or missing before-state export - remediate the gap and re-report.
#>

[CmdletBinding()]
param(
    [string]$BeforeCsv = "Oversharing_-_Estate_-_Discovery.csv",
    [string]$AfterCsv,
    [string]$LabelPolicyName = "Default Labeling - Users - Pilot",
    [string]$AutoLabelName   = "Auto-Label Sensitive - Pilot - Simulation",
    [string]$DlpPolicyName   = "DLP for Copilot - Pilot - Test",
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Readiness - Tenant - GoNoGo"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
try { Get-Command Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Error "Security & Compliance PowerShell required. Run Connect-IPPSSession first."; return }

function Get-BroadCount($csvPath) {
    if (-not (Test-Path $csvPath)) { return $null }
    $d = Import-Csv $csvPath
    return @($d | Where-Object { $_.OversharingSignal -match 'PRIORITY|broad' }).Count
}

Write-Section "Before/after oversharing"
$beforeBroad = Get-BroadCount $BeforeCsv
$afterBroad  = if ($AfterCsv) { Get-BroadCount $AfterCsv } else { $null }
Write-Host ("Broad-access sites BEFORE: {0}" -f ($beforeBroad ?? "n/a"))
if ($AfterCsv) { Write-Host ("Broad-access sites AFTER:  {0}" -f ($afterBroad ?? "n/a")) }

Write-Section "Control states"
function State($getCmd,$name) { try { $o = & $getCmd -Identity $name -ErrorAction Stop; if ($o) { "present (mode=$($o.Mode))" } else { "MISSING" } } catch { "MISSING" } }
$labelState = try { if (Get-LabelPolicy -Identity $LabelPolicyName -ErrorAction Stop) { "published" } else { "MISSING" } } catch { "MISSING" }
$autoState  = State { param($Identity) Get-AutoSensitivityLabelPolicy -Identity $Identity } $AutoLabelName
$dlpState   = State { param($Identity) Get-DlpCompliancePolicy -Identity $Identity } $DlpPolicyName

Write-Host "Default label policy '$LabelPolicyName': $labelState"
Write-Host "Auto-labeling '$AutoLabelName': $autoState"
Write-Host "DLP-for-Copilot '$DlpPolicyName': $dlpState"

$record = [ordered]@{
    Artifact = $ArtifactName
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    Oversharing = [ordered]@{ BroadSitesBefore = $beforeBroad; BroadSitesAfter = $afterBroad }
    Controls = [ordered]@{
        DefaultLabelPolicy = $labelState
        AutoLabeling       = $autoState
        DlpForCopilot      = $dlpState
    }
    ResidualRisk = "List remaining broad-access sites and any interim RSS/RCD-fenced sites (remediation debt) here."
    Determination = "GO / NO-GO is decided by compliance/records/privacy/legal against the agreed criteria (Requirement 2.8). This record is evidence only."
    Boundaries = "Feature availability (DLP-for-Copilot, SAM/RSS/RCD/RAC, container/mandatory labeling) is licensing-/tenant-dependent and evolving - verified in-portal, not asserted."
}
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$jsonPath = Join-Path $OutDir "$safe.json"
$record | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-Host "`nWrote $jsonPath" -ForegroundColor Green
Write-Host "Read-only: no changes were made. Route this record to the named approvers for the go/no-go decision." -ForegroundColor Yellow
