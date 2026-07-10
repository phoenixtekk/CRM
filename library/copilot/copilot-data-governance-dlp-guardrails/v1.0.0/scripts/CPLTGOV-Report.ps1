<#
.SYNOPSIS
    CPLTGOV-Report.ps1 - Compile the Copilot data-governance evidence record (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Merge the label-coverage baseline, the validation state, and the audit-capture confirmation
              into a single "Copilot Governance Report - Tenant - Expand" (HTML + JSON) for stakeholder
              sign-off - label coverage before/after, the controls applied and their state, audit capture,
              and residual risk. The classification and acceptable-use determinations remain the
              stakeholders'; this is the evidence, not the decision.
    HOW TO RUN:
              .\CPLTGOV-Report.ps1 -CoverageJson ".\Copilot Label Coverage - Estate - Assess.json" `
                  -ValidationJson ".\Copilot Governance Validation - Pilot - Validate.json" `
                  -AuditJson ".\Copilot Interaction Audit - Tenant - Validate.json"
    EXPECTED RESULTS:
              PASS: an HTML + JSON governance report is written. FAIL: inputs missing.
.NOTES
    White-label. Read-only - compiles existing exports; changes nothing. No secrets are stored.
#>

[CmdletBinding()]
param(
    [string]$CoverageJson,
    [string]$ValidationJson,
    [string]$AuditJson,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Copilot Governance Report - Tenant - Expand"
)

$ErrorActionPreference = "Stop"
function Read-Json($p) { if ($p -and (Test-Path $p)) { Get-Content $p -Raw | ConvertFrom-Json } else { $null } }

$cov = Read-Json $CoverageJson;   if (-not $cov) { Write-Warning "No -CoverageJson; coverage will be incomplete." }
$val = Read-Json $ValidationJson; if (-not $val) { Write-Warning "No -ValidationJson; control state will be incomplete." }
$aud = Read-Json $AuditJson;      if (-not $aud) { Write-Warning "No -AuditJson; audit capture will be incomplete." }

$labelCount   = if ($cov) { [int]$cov.LabelCount } else { $null }
$dlpAvail     = if ($cov) { "$($cov.CopilotDlpAvailability)" } else { "unknown" }
$failures     = if ($val) { [int]$val.Failures } else { $null }
$auditEvents  = if ($aud) { [int]$aud.EventCount } else { $null }
$trailOk      = if ($aud) { [bool]$aud.TrailConfirmed } else { $false }

$model = [ordered]@{
    Artifact          = $ArtifactName
    GeneratedUtc      = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    PublishedLabels   = $labelCount
    CopilotDlpAvailability = $dlpAvail
    ValidationFailures= $failures
    AuditEvents       = $auditEvents
    AuditTrailConfirmed = $trailOk
    ControlsApplied   = @("Default labeling (pilot)","Auto-labeling (simulation -> on)","DLP for Microsoft 365 Copilot (test -> enforce)","Prompt/response guardrails (responsible-use mapping)","Audit + eDiscovery of Copilot interactions")
    ResidualRisk      = if ($failures) { "$failures validation check(s) failed - resolve before/again after enforce." } else { "See validation output; confirm false-positive review passed." }
    Determination     = "Classification and acceptable-AI-use determinations remain with compliance/records/legal. This report is the technical evidence."
}

$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$json = Join-Path $OutDir "$safe.json"
$model | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8

$controls = ($model.ControlsApplied | ForEach-Object { "<li>$_</li>" }) -join ''
$html = @"
<!doctype html><html><head><meta charset='utf-8'><title>$ArtifactName</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1{font-size:20px}.k{color:#555}.big{font-size:15px;font-weight:600}
table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px}</style></head><body>
<h1>$ArtifactName</h1>
<p class='k'>Generated $($model.GeneratedUtc)</p>
<p class='big'>Published labels: $labelCount &nbsp;|&nbsp; Copilot DLP: $dlpAvail &nbsp;|&nbsp; Validation failures: $failures &nbsp;|&nbsp; Audit events: $auditEvents (trail confirmed: $trailOk)</p>
<h2>Controls applied</h2><ul>$controls</ul>
<h2>Residual risk</h2><p>$($model.ResidualRisk)</p>
<p class='k'>$($model.Determination)</p>
</body></html>
"@
$htmlPath = Join-Path $OutDir "$safe.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host "Wrote $json" -ForegroundColor Green
Write-Host "Wrote $htmlPath" -ForegroundColor Green
Write-Host "`nRead-only: report compiled from existing exports. Classification determinations remain the stakeholders'." -ForegroundColor Yellow
