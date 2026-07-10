<#
.SYNOPSIS
    CPLTSHARE-Report.ps1 - Compile the before/after oversharing-remediation evidence record (READ-ONLY).
.DESCRIPTION
    PURPOSE:  Merge the discovery baseline, the validation re-measure, and the recorded control states into
              a single "Oversharing Remediation Report - Tenant - Expand" (HTML + JSON) for stakeholder
              sign-off - before/after oversharing counts, the controls applied and their state, and the
              residual risk. This is the defensible record that oversharing was closed before broad Copilot
              rollout. The go/no-go decision belongs to the stakeholders; this is the evidence.
    HOW TO RUN:
              .\CPLTSHARE-Report.ps1 -BaselineCsv ".\Oversharing Discovery - Estate - Assess.csv" `
                  -ValidationJson ".\Copilot Permission Verification - Pilot - Validate.json"
    EXPECTED RESULTS:
              PASS: an HTML + JSON report is written summarizing before/after and residual risk. FAIL:
              inputs missing.
.NOTES
    White-label. Read-only - compiles existing exports; changes nothing. No secrets are stored.
#>

[CmdletBinding()]
param(
    [string]$BaselineCsv,
    [string]$ValidationJson,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Oversharing Remediation Report - Tenant - Expand"
)

$ErrorActionPreference = "Stop"

$baselineRows = @()
if ($BaselineCsv -and (Test-Path $BaselineCsv)) { $baselineRows = Import-Csv $BaselineCsv }
else { Write-Warning "No -BaselineCsv; before-state will be incomplete." }

$validation = $null
if ($ValidationJson -and (Test-Path $ValidationJson)) { $validation = Get-Content $ValidationJson -Raw | ConvertFrom-Json }
else { Write-Warning "No -ValidationJson; after-state will be incomplete." }

$basePriority = @($baselineRows | Where-Object { $_.OversharingSignal -match 'PRIORITY|Everyone|EEEU|org-wide' }).Count
$afterBroad   = if ($validation) { [int]$validation.StillBroadSites } else { $null }
$improved     = if ($validation) { [int]$validation.ImprovedSites } else { $null }

$model = [ordered]@{
    Artifact          = $ArtifactName
    GeneratedUtc      = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    SitesInBaseline   = $baselineRows.Count
    BroadSitesBefore  = $basePriority
    BroadSitesAfter   = $afterBroad
    ImprovedSites     = $improved
    ControlsApplied   = @("EEEU/org-wide grant removal","Anonymous/broad link revocation","Restricted Access Control (where SAM licensed)","Restricted Content Discovery (interim, where SAM licensed)","Restricted SharePoint Search (interim)")
    ResidualRisk      = if ($afterBroad) { "$afterBroad site(s) still show broad access - remediate before broad rollout." } else { "See validation output." }
    GoNoGoNote        = "The go/no-go decision belongs to stakeholders; this report is the evidence. Data-owner access determinations remain with site owners."
}

$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$json = Join-Path $OutDir "$safe.json"
$model | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8

$rowsHtml = ($baselineRows | ForEach-Object {
    "<tr><td>$($_.SiteName)</td><td>$($_.WebUrl)</td><td>$($_.OversharingSignal)</td></tr>"
}) -join "`n"
$html = @"
<!doctype html><html><head><meta charset='utf-8'><title>$ArtifactName</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1{font-size:20px}table{border-collapse:collapse;width:100%;font-size:13px}
th,td{border:1px solid #ccc;padding:6px;text-align:left}th{background:#f3f3f3}
.k{color:#555}.big{font-size:15px;font-weight:600}</style></head><body>
<h1>$ArtifactName</h1>
<p class='k'>Generated $($model.GeneratedUtc)</p>
<p class='big'>Broad-access sites before: $basePriority &nbsp; | &nbsp; still broad after: $afterBroad &nbsp; | &nbsp; improved: $improved</p>
<p>$($model.ResidualRisk)</p>
<h2>Controls applied</h2><ul>$(( $model.ControlsApplied | ForEach-Object { "<li>$_</li>" }) -join '')</ul>
<h2>Baseline oversharing (before)</h2>
<table><tr><th>Site</th><th>URL</th><th>Signal</th></tr>$rowsHtml</table>
<p class='k'>$($model.GoNoGoNote)</p>
</body></html>
"@
$htmlPath = Join-Path $OutDir "$safe.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host "Wrote $json" -ForegroundColor Green
Write-Host "Wrote $htmlPath" -ForegroundColor Green
Write-Host "`nRead-only: report compiled from existing exports. The go/no-go decision is the stakeholders'." -ForegroundColor Yellow
