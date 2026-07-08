<#
.SYNOPSIS
    PURVASSESS-Report.ps1 — Build the findings register, priority matrix, and capability scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Turns the PURVASSESS-Discovery.ps1 inventory into the assessment deliverables with no changes:
        a findings register (capability, observation, evidence source, risk, recommendation, priority),
        a P1/P2/P3 priority matrix, and a per-capability coverage/maturity scorecard. Findings that are
        regulatory/records/legal determinations are marked "decision: governance owner," not decided here.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVASSESS-Report.ps1 -InFile .\inventory.json -OutDir .\out
        Consumes the JSON from PURVASSESS-Discovery.ps1 -OutFile. Read-only; writes CSV/JSON deliverables
        to -OutDir only.
    EXPECTED RESULTS
        out\Purview-Assessment-Tenant-Findings.csv, out\Purview-Assessment-Priorities-P1P2P3.csv,
        out\Purview-Assessment-Capabilities-Scorecard.csv — matching the named artifacts in the docs.
.NOTES
    Purview category — Tenant Assessment. Read-only. Priorities are heuristic starting points; final
    priority and any regulatory/records/legal determination are the customer's governance decision.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InFile,     # inventory JSON from PURVASSESS-Discovery.ps1
    [string]$OutDir = '.'                       # where to write the deliverable CSVs
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InFile)) { throw "Inventory file not found: $InFile (run PURVASSESS-Discovery.ps1 -OutFile first)" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$inv = Get-Content $InFile -Raw | ConvertFrom-Json

$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($cap,$obs,$src,$risk,$rec,$prio){
    $findings.Add([pscustomobject]@{
        Capability=$cap; Observation=$obs; EvidenceSource=$src; Risk=$risk; Recommendation=$rec; Priority=$prio; Status='open'
    })
}
function Cap($n){ if ($inv.PSObject.Properties.Name -contains $n) { $inv.$n } else { $null } }

# --- Information Protection ---
$labels = Cap 'InformationProtection.Labels'
if ($labels -and $labels.state -eq 'enabled') {
    if (-not $labels.data -or @($labels.data).Count -eq 0) {
        Add-Finding 'Information Protection' 'No sensitivity labels defined' 'Get-Label' 'Sensitive data is unclassified; DLP/auto-labeling have nothing to key on' 'Define a sensitivity label taxonomy (governance decision on tiers), then publish' 'P2'
    }
    $lp = Cap 'InformationProtection.LabelPolicies'
    if ($lp -and (-not $lp.data -or @($lp.data).Count -eq 0)) {
        Add-Finding 'Information Protection' 'Labels exist but no label policy publishes them' 'Get-LabelPolicy' 'Labels are invisible to users; taxonomy is unused' 'Publish a label policy to a pilot scope, then expand' 'P2'
    }
    $al = Cap 'InformationProtection.AutoLabeling'
    if ($al -and $al.data) { foreach ($a in $al.data) { if ($a.Mode -match 'Test|Simulat') { Add-Finding 'Information Protection' "Auto-labeling policy '$($a.Name)' stuck in simulation (Mode=$($a.Mode))" 'Get-AutoSensitivityLabelPolicy' 'Sensitive content is detected but never labeled/protected' 'Review simulation results with the data owner, then enable (governed)' 'P2' } } }
}

# --- DLP ---
$dlp = Cap 'DLP.Policies'
if ($dlp -and $dlp.state -eq 'enabled') {
    if (-not $dlp.data -or @($dlp.data).Count -eq 0) {
        Add-Finding 'DLP' 'No DLP policies configured' 'Get-DlpCompliancePolicy' 'No automated protection against sensitive-data leakage' 'Stand up baseline DLP (separate build engagement) — start in simulation' 'P1'
    } else {
        foreach ($p in $dlp.data) {
            if ($p.Mode -eq 'Enable') { Add-Finding 'DLP' "DLP policy '$($p.Name)' is enforced (Mode=Enable)" 'Get-DlpCompliancePolicy' 'If it was enforced without a pilot it may block legitimate work' 'Confirm it was piloted; if not, move to simulation (PURVASSESS-Remediate -Fix DlpToSimulation) and re-baseline' 'P1'
            } else { Add-Finding 'DLP' "DLP policy '$($p.Name)' Mode=$($p.Mode)" 'Get-DlpCompliancePolicy' 'Informational — coverage/mode captured' 'Confirm intended workloads are covered' 'P3' }
        }
    }
}

# --- Retention ---
$ret = Cap 'Retention.Policies'
if ($ret -and $ret.state -eq 'enabled' -and $ret.data) {
    foreach ($r in $ret.data) {
        if ($r.Enabled -eq $false) { Add-Finding 'Data Lifecycle & Records' "Retention policy '$($r.Name)' is DISABLED" 'Get-RetentionCompliancePolicy' 'Records/retention intent is not being applied' 'Records owner decides if it should run; if yes, enable (PURVASSESS-Remediate -Fix EnableRetentionPolicy). DECISION: governance owner' 'P1' }
    }
} elseif ($ret -and $ret.state -eq 'enabled' -and (-not $ret.data)) {
    Add-Finding 'Data Lifecycle & Records' 'No retention policies configured' 'Get-RetentionCompliancePolicy' 'No data lifecycle/records controls in place' 'Define retention per the records schedule (governance) — separate build' 'P2'
}

# --- Audit ---
$audit = Cap 'Audit.Ingestion'
if ($audit -and $audit.state -eq 'enabled' -and $audit.data -and (-not $audit.data.UnifiedAuditLogIngestionEnabled)) {
    Add-Finding 'Audit' 'Unified audit log ingestion is OFF' 'Get-AdminAuditLogConfig' 'No audit trail is being written; audit is not retroactive' 'Enable it (PURVASSESS-Remediate -Fix EnableUnifiedAudit)' 'P1'
}

# --- Portal-only capabilities -> manual-review findings ---
foreach ($n in 'InsiderRiskManagement','CommunicationCompliance','DSPM','ComplianceManager','UnifiedCatalog') {
    $c = Cap $n
    if ($c -and $c.state -eq 'portal-only') {
        Add-Finding $n 'Portal-only capability — not readable via PowerShell' 'Purview portal' 'Configuration hygiene/coverage unknown until manually reviewed' "Review manually: $($c.review). Verify your licensing/tenant" 'P2'
    }
}

# --- Emit deliverables ---
$fFindings = Join-Path $OutDir 'Purview-Assessment-Tenant-Findings.csv'
$findings | Export-Csv -Path $fFindings -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $fFindings ($($findings.Count) findings) — 'Purview Assessment - Tenant - Findings'" -ForegroundColor Green

$fPrio = Join-Path $OutDir 'Purview-Assessment-Priorities-P1P2P3.csv'
$findings | Group-Object Priority | Select-Object @{n='Priority';e={$_.Name}}, @{n='Count';e={$_.Count}} | Sort-Object Priority |
    Export-Csv -Path $fPrio -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $fPrio — 'Purview Assessment - Priorities - P1P2P3'" -ForegroundColor Green

$score = foreach ($p in $inv.PSObject.Properties) {
    [pscustomobject]@{ Capability=$p.Name; State=$p.Value.state; Findings=@($findings | Where-Object { $_.Capability -like ("*"+($p.Name -replace '\..*','')+"*") }).Count }
}
$fScore = Join-Path $OutDir 'Purview-Assessment-Capabilities-Scorecard.csv'
$score | Export-Csv -Path $fScore -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $fScore — 'Purview Assessment - Capabilities - Scorecard'" -ForegroundColor Green

Write-Host "`nPriority summary:" -ForegroundColor Cyan
$findings | Group-Object Priority | Sort-Object Name | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Name, $_.Count) }
Write-Host "Priorities are heuristic starting points; regulatory/records/legal findings are governance decisions." -ForegroundColor White
