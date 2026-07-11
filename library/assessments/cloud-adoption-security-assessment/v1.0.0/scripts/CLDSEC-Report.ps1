<#
.SYNOPSIS
    CLDSEC-Report.ps1 — read-only roll-up of the discovery outputs into a scored, risk-ranked findings report.
.DESCRIPTION
    PURPOSE
        Consumes the CSV/JSON produced by CLDSEC-Discovery.ps1, CLDSEC-SecureScore.ps1, and
        CLDSEC-ConditionalAccess.ps1 from the input folder and produces: a per-pillar maturity score
        (0-100) against the recorded reference baseline, an overall maturity rating, and a risk-ranked
        findings list where each item is tagged Critical/High/Medium/Low (impact x exposure) and mapped to
        a suggested remediation area. It reads files only — it makes no tenant calls and changes nothing.
    HOW TO RUN
        pwsh -File .\CLDSEC-Report.ps1 -InputFolder "<findings folder>" -Label "CloudSecAssessment - Estate - Full" -Baseline "Microsoft security baselines + Secure Score (verify version)"
    EXPECTED RESULTS
        A Markdown findings report and a CSV of ranked findings written to the input folder, plus an
        on-screen summary (per-pillar scores + top risks). Read-only.
.NOTES
    White-label. Read-only. Reads the discovery outputs only; makes no tenant changes.
    Scoring is a transparent heuristic — adjust weights to your organization's agreed model.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$InputFolder,
    [Parameter(Mandatory=$true)][string]$Label,
    [string]$Baseline = 'Microsoft security baselines + Secure Score (verify current version)'
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $InputFolder)) { Write-Host "Input folder not found: $InputFolder" -ForegroundColor Red; return }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Write-Host "CLDSEC report — '$Label' (read-only)`n" -ForegroundColor Cyan

# --- Load the most recent posture file ---------------------------------------
$postureFile = Get-ChildItem -Path $InputFolder -Filter 'CLDSEC-posture-*.csv' -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $postureFile) { Write-Host "No CLDSEC-posture-*.csv in $InputFolder — run CLDSEC-Discovery.ps1 first." -ForegroundColor Red; return }
$posture = Import-Csv $postureFile.FullName
Write-Host "Loaded posture: $($postureFile.Name) ($($posture.Count) rows)" -ForegroundColor Green

# CA gaps (optional)
$caFile = Get-ChildItem -Path $InputFolder -Filter 'CLDSEC-ca-gaps-*.csv' -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
$caGaps = if ($caFile) { Import-Csv $caFile.FullName } else { @() }

# --- Risk model --------------------------------------------------------------
# State -> base severity; pillar weight tunes the maturity contribution.
$stateSeverity = @{ 'GAP'='High'; 'REVIEW'='Medium'; 'unknown'='Medium'; 'partial/on'='Low'; 'present'='Low'; 'ok'='Low' }
$pillarWeight  = @{ 'Identity'=1.3; 'Endpoints'=1.2; 'Data'=1.0; 'Applications'=1.0; 'Infrastructure'=1.1; 'Network'=1.0 }
$sevRank       = @{ 'Critical'=4; 'High'=3; 'Medium'=2; 'Low'=1 }
$remediationMap = @{
    'Identity'      = 'Identity & Conditional Access hardening / Zero-Trust identity'
    'Endpoints'     = 'Intune compliance + Defender XDR unified onboarding'
    'Data'          = 'Cloud App / DLP + Purview information protection'
    'Applications'  = 'App governance + Defender for Cloud Apps'
    'Infrastructure'= 'Defender for Cloud (CSPM) posture management'
    'Network'       = 'Network segmentation / private-endpoint hardening'
}

# --- Build findings ----------------------------------------------------------
$findings = New-Object System.Collections.Generic.List[object]
foreach ($row in $posture) {
    $sev = if ($stateSeverity.ContainsKey($row.State)) { $stateSeverity[$row.State] } else { 'Medium' }
    if ($sev -eq 'Low') { continue }   # only report gaps/reviews as findings
    # Escalate Identity GAPs one level (identity is the primary breach vector)
    if ($row.Pillar -eq 'Identity' -and $sev -eq 'High') { $sev = 'Critical' }
    $findings.Add([pscustomobject]@{
        Pillar     = $row.Pillar
        Finding    = $row.Control
        State      = $row.State
        Severity   = $sev
        Detail     = $row.Detail
        RemediateWith = $remediationMap[$row.Pillar]
    })
}
foreach ($g in $caGaps) {
    if ($g.Status -eq 'GAP') {
        $findings.Add([pscustomobject]@{
            Pillar='Identity'; Finding="Conditional Access: $($g.Check)"; State='GAP'; Severity='Critical';
            Detail=$g.Detail; RemediateWith=$remediationMap['Identity'] })
    } elseif ($g.Status -eq 'REVIEW') {
        $findings.Add([pscustomobject]@{
            Pillar='Identity'; Finding="Conditional Access: $($g.Check)"; State='REVIEW'; Severity='Medium';
            Detail=$g.Detail; RemediateWith=$remediationMap['Identity'] })
    }
}
$ranked = $findings | Sort-Object @{Expression={$sevRank[$_.Severity]};Descending=$true}, Pillar

# --- Per-pillar maturity score (0-100) ---------------------------------------
$scores = foreach ($pillar in $pillarWeight.Keys) {
    $rows = @($posture | Where-Object Pillar -eq $pillar)
    if ($rows.Count -eq 0) { $score = 0 }
    else {
        $good = @($rows | Where-Object { $_.State -in @('present','ok','partial/on') }).Count
        $score = [math]::Round(($good / $rows.Count) * 100)
    }
    [pscustomobject]@{ Pillar=$pillar; Maturity=$score; Weight=$pillarWeight[$pillar]; ItemsAssessed=$rows.Count }
}
$overall = if (($scores | Measure-Object).Count -gt 0) {
    $wsum = ($scores | ForEach-Object { $_.Maturity * $_.Weight } | Measure-Object -Sum).Sum
    $wtot = ($scores | Measure-Object Weight -Sum).Sum
    [math]::Round($wsum / [math]::Max($wtot,1))
} else { 0 }

Write-Host "`n--- Per-pillar maturity (baseline: $Baseline) ---" -ForegroundColor Cyan
$scores | Sort-Object Maturity | Format-Table -AutoSize
Write-Host "Overall weighted maturity: $overall / 100" -ForegroundColor Green
Write-Host "`n--- Top findings by risk ---" -ForegroundColor Cyan
$ranked | Select-Object -First 15 Severity,Pillar,Finding,RemediateWith | Format-Table -AutoSize

# --- Write outputs -----------------------------------------------------------
$ranked | Export-Csv -Path (Join-Path $InputFolder "CLDSEC-findings-ranked-$stamp.csv") -NoTypeInformation -Encoding UTF8

$md = @()
$md += "# Cloud Adoption Security Assessment — Findings Report"
$md += ""
$md += "- **Run label:** $Label"
$md += "- **Reference baseline:** $Baseline"
$md += "- **Run date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$md += "- **Overall weighted maturity:** $overall / 100"
$md += ""
$md += "> Read-only, point-in-time snapshot. Risk-acceptance and remediation-priority decisions, and any"
$md += "> regulatory / records / legal mapping, are the customer's — this report supplies the evidence."
$md += ""
$md += "## Per-pillar maturity"
$md += "| Pillar | Maturity /100 | Items assessed |"
$md += "|---|---|---|"
foreach ($s in ($scores | Sort-Object Maturity)) { $md += "| $($s.Pillar) | $($s.Maturity) | $($s.ItemsAssessed) |" }
$md += ""
$md += "## Risk-ranked findings"
$md += "| Severity | Pillar | Finding | Detail | Remediate with |"
$md += "|---|---|---|---|---|"
foreach ($f in $ranked) { $md += "| $($f.Severity) | $($f.Pillar) | $($f.Finding) | $($f.Detail) | $($f.RemediateWith) |" }
$md += ""
$md += "## Suggested phased roadmap"
$md += "- **Phase 1 — Quick wins:** the Critical/High identity + coverage-gap items (block legacy auth, admin MFA, enable an owned Defender plan)."
$md += "- **Phase 2 — Foundational:** MFA/CA coverage, device compliance gates, DLP baseline, Defender for Cloud plans."
$md += "- **Phase 3 — Strategic:** PIM/least-privilege, data-classification program, network segmentation, landing-zone governance."
$mdPath = Join-Path $InputFolder "CLDSEC-findings-report-$stamp.md"
$md -join "`n" | Out-File -FilePath $mdPath -Encoding UTF8

Write-Host "`nSaved report: $mdPath" -ForegroundColor Green
Write-Host "Saved ranked findings CSV. Read-only; nothing was changed." -ForegroundColor Green
