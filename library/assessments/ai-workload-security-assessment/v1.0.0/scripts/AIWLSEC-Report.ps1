<#
.SYNOPSIS
    AIWLSEC-Report.ps1 — read-only roll-up of the AI review outputs into a risk-ranked findings report.
.DESCRIPTION
    PURPOSE
        Consumes the CSVs produced by AIWLSEC-Discovery.ps1, AIWLSEC-NetworkIsolation.ps1, and
        AIWLSEC-ContentSafety.ps1 from the input folder and produces a per-resource findings list where each
        item is tagged Critical/High/Medium/Low (impact x exposure) and mapped to the paired build solution
        that remediates it (AIFOUNDRY / AIRAG / AISAFETY / AILZ). It reads files only — no tenant calls,
        changes nothing. Preview-dependent items are carried as "verify", not asserted as hard gaps.
    HOW TO RUN
        pwsh -File .\AIWLSEC-Report.ps1 -InputFolder "<findings folder>" -Label "AIWorkloadSec - Estate - Full" -Baseline "Microsoft AI security baseline (verify version)"
    EXPECTED RESULTS
        A Markdown findings report and a ranked-findings CSV written to the input folder, plus an on-screen
        summary. Read-only.
.NOTES
    White-label. Read-only. Reads the review outputs only; makes no changes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$InputFolder,
    [Parameter(Mandatory=$true)][string]$Label,
    [string]$Baseline = 'Microsoft AI security baseline + paired-solution target state (verify current version)'
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $InputFolder)) { Write-Host "Input folder not found: $InputFolder" -ForegroundColor Red; return }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Write-Host "AIWLSEC report — '$Label' (read-only)`n" -ForegroundColor Cyan

function Get-Latest([string]$pattern){
    Get-ChildItem -Path $InputFolder -Filter $pattern -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
$postureFile = Get-Latest 'AIWLSEC-posture-*.csv'
if (-not $postureFile) { Write-Host "No AIWLSEC-posture-*.csv in $InputFolder — run AIWLSEC-Discovery.ps1 first." -ForegroundColor Red; return }
$posture = Import-Csv $postureFile.FullName
Write-Host "Loaded posture: $($postureFile.Name) ($($posture.Count) resources)" -ForegroundColor Green
$netFile = Get-Latest 'AIWLSEC-network-*.csv';        $net = if ($netFile){ Import-Csv $netFile.FullName } else { @() }
$csFile  = Get-Latest 'AIWLSEC-contentsafety-*.csv';  $cs  = if ($csFile){ Import-Csv $csFile.FullName } else { @() }

$sevRank = @{ 'Critical'=4; 'High'=3; 'Medium'=2; 'Low'=1 }
$remediation = @{
    'PUBLIC'='AIFOUNDRY (private endpoint + disable public access)'
    'KEYS-ON'='AIFOUNDRY (disable local auth + managed identity RBAC)'
    'API-KEYS-ALLOWED'='AIRAG/AIFOUNDRY (RBAC-only on AI Search)'
    'NO-SUBDOMAIN'='AIFOUNDRY (custom subdomain — required for keyless + private endpoint)'
    'NO-PRIVATE-EP'='AIFOUNDRY/AILZ (private endpoint on the VNet)'
    'DEPLOY-NO-FILTER'='AISAFETY (attach a content-filter/RAI policy)'
    'NO-DIAG'='AILZ (diagnostics to Log Analytics)'
    'NO-CONTENT-FILTER'='AISAFETY (attach a content-filter/RAI policy)'
}
$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($res,$issue,$sev,$detail,$fix){
    $findings.Add([pscustomobject]@{ Resource=$res; Issue=$issue; Severity=$sev; Detail=$detail; RemediateWith=$fix })
}

# From posture Risk column
foreach ($r in $posture) {
    if ($r.Risk -and $r.Risk -ne 'ok') {
        foreach ($tag in ($r.Risk -split ',')) {
            $tag = $tag.Trim()
            $sev = switch ($tag) {
                'PUBLIC'          { 'High' }
                'KEYS-ON'         { 'High' }
                'API-KEYS-ALLOWED'{ 'High' }
                'NO-PRIVATE-EP'   { 'Medium' }
                'NO-SUBDOMAIN'    { 'Medium' }
                'DEPLOY-NO-FILTER'{ 'High' }
                'NO-DIAG'         { 'Low' }
                default           { 'Medium' }
            }
            # A public + keyless-disabled resource is the classic Critical combination
            if ($tag -eq 'PUBLIC' -and $r.Risk -match 'KEYS-ON') { $sev = 'Critical' }
            $fix = if ($remediation.ContainsKey($tag)) { $remediation[$tag] } else { 'AIFOUNDRY/AISAFETY' }
            Add-Finding "$($r.Type): $($r.Name)" $tag $sev $r.Risk $fix
        }
    }
}
# Content-safety findings
foreach ($d in $cs) {
    if ($d.Verdict -like 'FINDING*') {
        Add-Finding "$($d.Account) / $($d.Deployment)" 'NO-CONTENT-FILTER' 'High' $d.Verdict $remediation['NO-CONTENT-FILTER']
    }
}

$ranked = $findings | Sort-Object @{Expression={$sevRank[$_.Severity]};Descending=$true}, Resource
$counts = $ranked | Group-Object Severity | ForEach-Object { "$($_.Name)=$($_.Count)" }

Write-Host "`n--- Findings by severity ---" -ForegroundColor Cyan
Write-Host ($counts -join '  ')
Write-Host "`n--- Top findings ---" -ForegroundColor Cyan
$ranked | Select-Object -First 20 Severity,Resource,Issue,RemediateWith | Format-Table -AutoSize

$ranked | Export-Csv -Path (Join-Path $InputFolder "AIWLSEC-findings-ranked-$stamp.csv") -NoTypeInformation -Encoding UTF8

$md = @()
$md += "# AI Workload Security Assessment — Findings Report"
$md += ""
$md += "- **Run label:** $Label"
$md += "- **AI security baseline:** $Baseline"
$md += "- **Run date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$md += "- **Resources assessed:** $($posture.Count)"
$md += "- **Findings:** $($ranked.Count)  ($($counts -join ', '))"
$md += ""
$md += "> Read-only, point-in-time snapshot. Acceptable-AI-use policy, data-classification, risk-acceptance,"
$md += "> and any regulatory / legal mapping are the customer's decisions. Preview-dependent safety features"
$md += "> are flagged to *verify current availability*, not asserted as hard gaps."
$md += ""
$md += "## Risk-ranked findings"
$md += "| Severity | Resource | Issue | Detail | Remediate with |"
$md += "|---|---|---|---|---|"
foreach ($f in $ranked) { $md += "| $($f.Severity) | $($f.Resource) | $($f.Issue) | $($f.Detail) | $($f.RemediateWith) |" }
$md += ""
$md += "## Verify by inspection (not machine-scored)"
$md += "- **RAG index permission-trimming** — confirm each AI Search index backing a RAG app enforces document-level access (Implementation Step 2.4). A non-trimmed index over sensitive data is **Critical** → remediate with **AIRAG**."
$md += "- **Hard-coded secrets** — confirm no keys in connection strings / app settings (move to Key Vault) → **AIFOUNDRY**."
$md += "- **Higher-order safety controls** (prompt shields, groundedness) — *verify availability* → **AISAFETY**."
$md += ""
$md += "## Suggested phased roadmap"
$md += "- **Phase 1 — Quick wins:** disable public access, attach content-filter policies, disable local auth where already keyless-capable (AIFOUNDRY/AISAFETY)."
$md += "- **Phase 2 — Foundational:** private endpoints + DNS, managed identity + least-privilege RBAC, secrets to Key Vault (AIFOUNDRY); permission-trim RAG indexes (AIRAG)."
$md += "- **Phase 3 — Strategic:** responsible-AI governance, prompt-shield/groundedness rollout, AI landing-zone guardrails (AISAFETY/AILZ)."
$mdPath = Join-Path $InputFolder "AIWLSEC-findings-report-$stamp.md"
$md -join "`n" | Out-File -FilePath $mdPath -Encoding UTF8

Write-Host "`nSaved report: $mdPath" -ForegroundColor Green
Write-Host "Saved ranked findings CSV. Read-only; nothing was changed." -ForegroundColor Green
