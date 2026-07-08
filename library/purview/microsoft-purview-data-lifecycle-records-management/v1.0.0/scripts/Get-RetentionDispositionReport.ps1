<#
.SYNOPSIS
  Retention & disposition compliance report across the tenant (read-only).
.DESCRIPTION
  Compiles a coverage report from Security & Compliance PowerShell: retention labels (record/regulatory/
  event/reviewed counts), retention policies with workload locations + enabled state, event types, and
  file-plan descriptor coverage on labels. Writes CSV + HTML. Points reviewers to the Purview portal
  Disposition queue (disposition items are not enumerable via a supported cmdlet). Makes no changes.
.EXAMPLE
  .\Get-RetentionDispositionReport.ps1 -OutputPath .\out
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: "Lifecycle Compliance - Tenant - Report" (CSV + HTML) summarizing label/policy/event
  coverage and flagging gaps (labels without file-plan descriptors, reviewed labels without reviewers,
  policies still disabled). Read-only.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\out"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$labels = @(); $policies = @(); $events = @()
try { $labels   = Get-ComplianceTag } catch { Write-Warning "Get-ComplianceTag failed (plan/scope?): $_" }
try { $policies = Get-RetentionCompliancePolicy } catch { Write-Warning "Get-RetentionCompliancePolicy failed: $_" }
try { $events   = Get-ComplianceRetentionEventType } catch { Write-Warning "Get-ComplianceRetentionEventType failed: $_" }

# --- Label rows + gap flags ---
$labelRows = foreach ($l in $labels) {
    $reviewed  = [bool]$l.ReviewerEmail
    $hasFP     = [bool]$l.FilePlanMetadata
    [pscustomobject]@{
        Label           = $l.Name
        Record          = $l.IsRecordLabel
        Regulatory      = $l.Regulatory
        Action          = $l.RetentionAction
        DurationDays    = $l.RetentionDuration
        Trigger         = $l.RetentionType
        EventType       = $l.EventType
        Reviewed        = $reviewed
        FilePlanTagged  = $hasFP
        Gap             = (@(
                            if ($reviewed -eq $false -and $l.IsRecordLabel -eq $true) { 'record-no-review?' }
                            if ($hasFP -eq $false) { 'no-fileplan-descriptors' }
                          ) -join '; ')
    }
}

# --- Policy rows + gap flags ---
$policyRows = foreach ($p in $policies) {
    $locs = @()
    foreach ($m in @(
        @{n='Exchange';v=$p.ExchangeLocation}, @{n='SPO';v=$p.SharePointLocation}, @{n='OneDrive';v=$p.OneDriveLocation},
        @{n='Groups';v=$p.ModernGroupLocation}, @{n='TeamsChannel';v=$p.TeamsChannelLocation}, @{n='TeamsChat';v=$p.TeamsChatLocation},
        @{n='Adaptive';v=$p.AdaptiveScopeLocation}
    )) { if ($m.v) { $locs += ("{0}:{1}" -f $m.n, ($m.v -join ',')) } }
    [pscustomobject]@{
        Policy    = $p.Name
        Enabled   = $p.Enabled
        Mode      = $p.Mode
        Locations = ($locs -join ' | ')
        Gap       = (@( if ($p.Enabled -eq $false) { 'disabled' } ) -join '; ')
    }
}

# --- Summary counts ---
$summary = [pscustomobject]@{
    LabelsTotal        = ($labels   | Measure-Object).Count
    RecordLabels       = (@($labels | Where-Object { $_.IsRecordLabel -eq $true }) | Measure-Object).Count
    RegulatoryLabels   = (@($labels | Where-Object { $_.Regulatory   -eq $true }) | Measure-Object).Count
    EventBasedLabels   = (@($labels | Where-Object { $_.RetentionType -match 'Event' }) | Measure-Object).Count
    ReviewedLabels     = (@($labels | Where-Object { $_.ReviewerEmail }) | Measure-Object).Count
    LabelsMissingFP    = (@($labelRows | Where-Object { $_.FilePlanTagged -eq $false }) | Measure-Object).Count
    PoliciesTotal      = ($policies | Measure-Object).Count
    PoliciesEnabled    = (@($policies | Where-Object { $_.Enabled -eq $true }) | Measure-Object).Count
    EventTypes         = ($events   | Measure-Object).Count
    GeneratedUtc       = (Get-Date).ToUniversalTime().ToString('u')
}

# --- Write CSVs ---
$labelCsv  = Join-Path $OutputPath "Lifecycle-Compliance-Tenant-Labels.csv"
$policyCsv = Join-Path $OutputPath "Lifecycle-Compliance-Tenant-Policies.csv"
$labelRows  | Export-Csv -Path $labelCsv  -NoTypeInformation -Encoding UTF8
$policyRows | Export-Csv -Path $policyCsv -NoTypeInformation -Encoding UTF8

# --- Write HTML ---
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:20px}h2{font-size:15px;margin-top:24px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 8px;font-size:12px;text-align:left}th{background:#f3f3f3}.gap{color:#b00}</style>"
$html  = "<html><head><meta charset='utf-8'>$style</head><body><h1>Lifecycle Compliance &ndash; Tenant &ndash; Report</h1>"
$html += "<p>Generated (UTC): $($summary.GeneratedUtc)</p>"
$html += ($summary | ConvertTo-Html -As List -Fragment)
$html += "<h2>Retention labels</h2>" + ($labelRows  | ConvertTo-Html -Fragment)
$html += "<h2>Retention policies</h2>" + ($policyRows | ConvertTo-Html -Fragment)
$html += "<h2>Disposition</h2><p>Disposition items are reviewed in the Microsoft Purview portal: <b>Records management &rarr; Disposition</b>. Confirm reviewers are in the <b>Disposition Management</b> role group and that the pending-disposition backlog is being worked.</p>"
$html += "</body></html>"
$htmlFile = Join-Path $OutputPath "Lifecycle-Compliance-Tenant-Report.html"
$html | Out-File -FilePath $htmlFile -Encoding UTF8

# --- Console summary ---
Write-Host "== Lifecycle Compliance - Tenant - Report ==" -ForegroundColor Cyan
$summary | Format-List
Write-Host ("CSV : {0}" -f $labelCsv) -ForegroundColor Green
Write-Host ("CSV : {0}" -f $policyCsv) -ForegroundColor Green
Write-Host ("HTML: {0}" -f $htmlFile) -ForegroundColor Green
if ($summary.LabelsMissingFP -gt 0) { Write-Host ("ATTENTION: {0} label(s) lack file-plan descriptors." -f $summary.LabelsMissingFP) -ForegroundColor Yellow }
if ($summary.PoliciesTotal -gt 0 -and $summary.PoliciesEnabled -eq 0) { Write-Host "ATTENTION: no retention policy is enabled (expected during pilot; confirm before Expand)." -ForegroundColor Yellow }
Write-Host "Report complete (read-only)." -ForegroundColor Green
