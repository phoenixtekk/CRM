<#
.SYNOPSIS
  Disposition-review evidence/compliance report across the tenant (read-only; makes no changes).
.DESCRIPTION
  Compiles per-label disposition-review configuration (single/multi-stage, stages, reviewers), Disposition
  Management coverage, and gap flags (auto-delete-no-review labels, reviewers not in Disposition Management,
  empty stages) into CSV + HTML. Points reviewers to the portal Disposition export and the audit log for the
  item-level proof of disposal (disposition items are not enumerable via a supported cmdlet). Makes no changes.
.EXAMPLE
  .\Get-DispositionEvidenceReport.ps1 -OutputPath .\out
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: "Disposition Evidence - Tenant - Report" (CSV + HTML) summarising review configuration
  and coverage, flagging gaps, and pointing to Records management -> Disposition (portal export) plus
  Search-UnifiedAuditLog for per-item proof of disposal. Read-only.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\out",
    [string]$DispositionRoleGroup = "Disposition Management"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$labels = @(); $dmMembers = @()
try { $labels = Get-ComplianceTag } catch { Write-Warning "Get-ComplianceTag failed (plan/scope?): $_" }
try { $dmMembers = Get-RoleGroupMember -Identity $DispositionRoleGroup } catch { Write-Warning "Get-RoleGroupMember '$DispositionRoleGroup' failed: $_" }

$dmSet = @{}
foreach ($m in $dmMembers) { foreach ($id in @($m.PrimarySmtpAddress, $m.Name)) { if ($id) { $dmSet[[string]$id.ToLower()] = $true } } }
function In-DM($email) { if (-not $email) { return $false }; return $dmSet.ContainsKey([string]$email.ToLower()) }

function Get-ReviewStages($label) {
    $stages = @()
    if ($label.ReviewerEmail) { $stages += [pscustomobject]@{ Stage='Stage1(single)'; Reviewers=@($label.ReviewerEmail) } }
    $ms = $label.MultiStageReviewProperty
    if ($ms) {
        try {
            $obj = if ($ms -is [string]) { $ms | ConvertFrom-Json -ErrorAction Stop } else { $ms }
            $i = 0
            foreach ($s in @($obj.MultiStageReviewSettings)) {
                $i++; $name = if ($s.StageName) { $s.StageName } else { "Stage$i" }
                $stages += [pscustomobject]@{ Stage=("Stage{0}:{1}" -f $i,$name); Reviewers=@($s.Reviewers) }
            }
            if ($i -eq 0) { $stages += [pscustomobject]@{ Stage='multi-stage(unparsed — verify shape)'; Reviewers=@() } }
        } catch { $stages += [pscustomobject]@{ Stage='multi-stage(parse-failed — verify shape)'; Reviewers=@() } }
    }
    return $stages
}

$rows = foreach ($l in $labels | Where-Object { $_.RetentionAction -eq 'KeepAndDelete' -or $_.ReviewerEmail -or $_.MultiStageReviewProperty }) {
    $stages = @(Get-ReviewStages $l)
    $reviewed = ($stages.Count -gt 0)
    $reviewers = @($stages | ForEach-Object { $_.Reviewers } | Where-Object { $_ }) | Select-Object -Unique
    $notInDM = @($reviewers | Where-Object { -not (In-DM $_) })
    $emptyStages = @($stages | Where-Object { (@($_.Reviewers) | Measure-Object).Count -eq 0 })
    $gaps = @()
    if ($l.RetentionAction -eq 'KeepAndDelete' -and -not $reviewed) { $gaps += 'AUTO-DELETE-NO-REVIEW' }
    if ($reviewed -and $notInDM.Count -gt 0) { $gaps += 'reviewers-not-in-DM' }
    if ($emptyStages.Count -gt 0) { $gaps += 'empty-stage' }
    [pscustomobject]@{
        Label         = $l.Name
        Action        = $l.RetentionAction
        DurationDays  = $l.RetentionDuration
        ReviewEnabled = $reviewed
        Type          = if ($stages.Count -gt 1) { 'multi-stage' } elseif ($reviewed) { 'single-stage' } else { 'none' }
        StageCount    = $stages.Count
        Stages        = (($stages | ForEach-Object { "{0}=[{1}]" -f $_.Stage, ($_.Reviewers -join ';') }) -join ' | ')
        ReviewersNotInDM = ($notInDM -join ';')
        Gap           = ($gaps -join '; ')
    }
}

$summary = [pscustomobject]@{
    RetainThenDeleteLabels = (@($labels | Where-Object { $_.RetentionAction -eq 'KeepAndDelete' }) | Measure-Object).Count
    ReviewEnabledLabels    = (@($rows | Where-Object { $_.ReviewEnabled }) | Measure-Object).Count
    SingleStageLabels      = (@($rows | Where-Object { $_.Type -eq 'single-stage' }) | Measure-Object).Count
    MultiStageLabels       = (@($rows | Where-Object { $_.Type -eq 'multi-stage' }) | Measure-Object).Count
    AutoDeleteNoReview     = (@($rows | Where-Object { $_.Gap -match 'AUTO-DELETE-NO-REVIEW' }) | Measure-Object).Count
    LabelsReviewersNotInDM = (@($rows | Where-Object { $_.Gap -match 'reviewers-not-in-DM' }) | Measure-Object).Count
    DispositionMgmtMembers = (@($dmMembers) | Measure-Object).Count
    GeneratedUtc           = (Get-Date).ToUniversalTime().ToString('u')
}

# --- CSV ---
$csv = Join-Path $OutputPath "Disposition-Evidence-Tenant-Labels.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

# --- HTML ---
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:20px}h2{font-size:15px;margin-top:24px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 8px;font-size:12px;text-align:left}th{background:#f3f3f3}.gap{color:#b00}</style>"
$html  = "<html><head><meta charset='utf-8'>$style</head><body><h1>Disposition Evidence &ndash; Tenant &ndash; Report</h1>"
$html += "<p>Generated (UTC): $($summary.GeneratedUtc)</p>"
$html += ($summary | ConvertTo-Html -As List -Fragment)
$html += "<h2>Disposition-review configuration by label</h2>" + ($rows | ConvertTo-Html -Fragment)
$html += "<h2>Proof of disposal (item-level evidence)</h2><p>Disposed items are <b>not enumerable via a supported cmdlet</b>. For per-item proof of disposal (what was disposed, who approved each stage, when), export from the Microsoft Purview portal: <b>Records management &rarr; Disposition</b>, and corroborate with the audit log via <code>Search-UnifiedAuditLog</code>. Confirm reviewers are in the <b>Disposition Management</b> role group and that the pending-disposition backlog is being worked.</p>"
$html += "<h2>Notes</h2><p>Multi-stage review configuration and its property shape are plan-dependent and have changed across releases &mdash; <b>verify in your tenant</b>. This report reflects configuration; item-level truth lives in the portal export + audit log.</p>"
$html += "</body></html>"
$htmlFile = Join-Path $OutputPath "Disposition-Evidence-Tenant-Report.html"
$html | Out-File -FilePath $htmlFile -Encoding UTF8

# --- Console ---
Write-Host "== Disposition Evidence - Tenant - Report (read-only) ==" -ForegroundColor Cyan
$summary | Format-List
Write-Host ("CSV : {0}" -f $csv) -ForegroundColor Green
Write-Host ("HTML: {0}" -f $htmlFile) -ForegroundColor Green
if ($summary.AutoDeleteNoReview -gt 0) { Write-Host ("ATTENTION: {0} retain-then-delete label(s) auto-delete with NO review — confirm with records/legal." -f $summary.AutoDeleteNoReview) -ForegroundColor Yellow }
if ($summary.LabelsReviewersNotInDM -gt 0) { Write-Host ("ATTENTION: {0} reviewed label(s) have reviewers not in Disposition Management — they cannot act." -f $summary.LabelsReviewersNotInDM) -ForegroundColor Yellow }
Write-Host "Report complete (read-only). Item-level proof of disposal: portal Disposition export + Search-UnifiedAuditLog." -ForegroundColor Green
