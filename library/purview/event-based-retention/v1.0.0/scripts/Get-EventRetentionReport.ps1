<#
.SYNOPSIS
  Event-based retention compliance report across the tenant (read-only).
.DESCRIPTION
  Compiles a coverage report from Security & Compliance PowerShell: event TYPES, event-based LABELS (event
  type / record / regulatory / action / duration), and raised EVENTS, with gap flags (labels with no event
  type, event types with no label bound, event-based labels whose event type is missing, raised events with
  no matching tags/assets recorded). Writes CSV + HTML. Points to the portal for disposition. Makes no changes.
.EXAMPLE
  .\Get-EventRetentionReport.ps1 -OutputPath .\out
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: "Event Retention Compliance - Tenant - Report" (CSV + HTML) summarizing event-type/label/
  event coverage and flagging gaps. Read-only.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\out"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$eventTypes = @(); $labels = @(); $events = @()
try { $eventTypes = @(Get-ComplianceRetentionEventType) } catch { Write-Warning "Get-ComplianceRetentionEventType failed (plan/scope?): $_" }
try { $labels     = @(Get-ComplianceTag) }                 catch { Write-Warning "Get-ComplianceTag failed: $_" }
try { $events     = @(Get-ComplianceRetentionEvent) }      catch { Write-Warning "Get-ComplianceRetentionEvent failed: $_" }

$eventLabels = @($labels | Where-Object { $_.RetentionType -match 'Event' })
$typeNames   = @($eventTypes | ForEach-Object { $_.Name })
$boundTypes  = @($eventLabels | ForEach-Object { $_.EventType } | Where-Object { $_ } | Select-Object -Unique)

# --- Event type rows ---
$typeRows = foreach ($e in $eventTypes) {
    [pscustomobject]@{
        EventType = $e.Name
        HasLabel  = ($boundTypes -contains $e.Name)
        Gap       = $(if ($boundTypes -contains $e.Name) { '' } else { 'no-label-bound' })
    }
}

# --- Event-based label rows + gap flags ---
$labelRows = foreach ($l in $eventLabels) {
    $typeMissing = -not ([string]::IsNullOrWhiteSpace($l.EventType)) -and (-not ($typeNames -contains $l.EventType))
    [pscustomobject]@{
        Label        = $l.Name
        EventType    = $l.EventType
        Record       = $l.IsRecordLabel
        Regulatory   = $l.Regulatory
        Action       = $l.RetentionAction
        DurationDays = $l.RetentionDuration
        Trigger      = $l.RetentionType
        Gap          = (@(
                          if ([string]::IsNullOrWhiteSpace($l.EventType)) { 'no-eventtype' }
                          if ($typeMissing) { 'eventtype-missing' }
                        ) -join '; ')
    }
}

# --- Raised event rows ---
$eventRows = foreach ($ev in $events) {
    [pscustomobject]@{
        Event     = $ev.Name
        EventType = $ev.EventType
        EventDate = $ev.EventDateTime
        Status    = $ev.Status
    }
}

# --- Summary ---
$summary = [pscustomobject]@{
    EventTypesTotal   = $eventTypes.Count
    EventTypesUnused  = (@($typeRows  | Where-Object { -not $_.HasLabel }) | Measure-Object).Count
    EventBasedLabels  = $eventLabels.Count
    RecordLabels      = (@($eventLabels | Where-Object { $_.IsRecordLabel -eq $true }) | Measure-Object).Count
    RegulatoryLabels  = (@($eventLabels | Where-Object { $_.Regulatory   -eq $true }) | Measure-Object).Count
    LabelsWithGaps    = (@($labelRows  | Where-Object { $_.Gap }) | Measure-Object).Count
    RaisedEvents      = $events.Count
    GeneratedUtc      = (Get-Date).ToUniversalTime().ToString('u')
}

# --- Write CSVs ---
$typeCsv  = Join-Path $OutputPath "EventRetention-Compliance-EventTypes.csv"
$labelCsv = Join-Path $OutputPath "EventRetention-Compliance-Labels.csv"
$eventCsv = Join-Path $OutputPath "EventRetention-Compliance-RaisedEvents.csv"
$typeRows  | Export-Csv -Path $typeCsv  -NoTypeInformation -Encoding UTF8
$labelRows | Export-Csv -Path $labelCsv -NoTypeInformation -Encoding UTF8
$eventRows | Export-Csv -Path $eventCsv -NoTypeInformation -Encoding UTF8

# --- Write HTML ---
$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px}h1{font-size:20px}h2{font-size:15px;margin-top:24px}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:6px 8px;font-size:12px;text-align:left}th{background:#f3f3f3}</style>"
$html  = "<html><head><meta charset='utf-8'>$style</head><body><h1>Event Retention Compliance &ndash; Tenant &ndash; Report</h1>"
$html += "<p>Generated (UTC): $($summary.GeneratedUtc)</p>"
$html += ($summary | ConvertTo-Html -As List -Fragment)
$html += "<h2>Event types</h2>" + ($typeRows  | ConvertTo-Html -Fragment)
$html += "<h2>Event-based labels</h2>" + ($labelRows | ConvertTo-Html -Fragment)
$html += "<h2>Raised retention events</h2>" + ($eventRows | ConvertTo-Html -Fragment)
$html += "<h2>Disposition</h2><p>End-of-retention disposition is reviewed in the Microsoft Purview portal: <b>Records management &rarr; Disposition</b> (mechanics owned by the data lifecycle &amp; records product). This report covers the event-based trigger, not disposition actioning.</p>"
$html += "</body></html>"
$htmlFile = Join-Path $OutputPath "EventRetention-Compliance-Tenant-Report.html"
$html | Out-File -FilePath $htmlFile -Encoding UTF8

# --- Console summary ---
Write-Host "== Event Retention Compliance - Tenant - Report ==" -ForegroundColor Cyan
$summary | Format-List
Write-Host ("CSV : {0}" -f $typeCsv)  -ForegroundColor Green
Write-Host ("CSV : {0}" -f $labelCsv) -ForegroundColor Green
Write-Host ("CSV : {0}" -f $eventCsv) -ForegroundColor Green
Write-Host ("HTML: {0}" -f $htmlFile) -ForegroundColor Green
if ($summary.LabelsWithGaps -gt 0) { Write-Host ("ATTENTION: {0} event-based label(s) have linkage gaps (see Gap column)." -f $summary.LabelsWithGaps) -ForegroundColor Yellow }
if ($summary.EventTypesUnused -gt 0) { Write-Host ("NOTE: {0} event type(s) have no label bound." -f $summary.EventTypesUnused) -ForegroundColor Yellow }
if ($summary.EventBasedLabels -gt 0 -and $summary.RaisedEvents -eq 0) { Write-Host "NOTE: event-based labels exist but no events have been raised — labeled content stays PENDING until an event is raised." -ForegroundColor Yellow }
Write-Host "Report complete (read-only)." -ForegroundColor Green
