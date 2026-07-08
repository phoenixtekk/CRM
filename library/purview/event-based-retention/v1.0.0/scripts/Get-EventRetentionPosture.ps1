<#
.SYNOPSIS
  Event-based retention discovery / posture inventory (read-only).
.DESCRIPTION
  Inventories existing event TYPES (Get-ComplianceRetentionEventType), existing event-based LABELS
  (Get-ComplianceTag filtered to an Event* retention type, with EventType and record/regulatory flags), the
  label POLICIES that publish/auto-apply them, and any raised retention EVENTS (Get-ComplianceRetentionEvent).
  Flags duplicates and orphans (labels with no event type, event types with no label). Writes CSVs. No changes.
.EXAMPLE
  .\Get-EventRetentionPosture.ps1 -OutputPath .\out
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: "Event Retention Posture - Tenant - Discovery" CSVs listing event types, event-based
  labels + their event type, label policies, and raised events, with duplicate/orphan flags. Read-only.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\out"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$eventTypes = @(); $labels = @(); $policies = @(); $events = @()
try { $eventTypes = @(Get-ComplianceRetentionEventType) } catch { Write-Warning "Get-ComplianceRetentionEventType failed (plan/scope?): $_" }
try { $labels     = @(Get-ComplianceTag) }                 catch { Write-Warning "Get-ComplianceTag failed: $_" }
try { $policies   = @(Get-RetentionCompliancePolicy) }     catch { Write-Warning "Get-RetentionCompliancePolicy failed: $_" }
try { $events     = @(Get-ComplianceRetentionEvent) }      catch { Write-Warning "Get-ComplianceRetentionEvent failed: $_" }

# --- Event-based labels only (retention type mentions Event) ---
$eventLabels = @($labels | Where-Object { $_.RetentionType -match 'Event' })

# --- Event type rows + orphan flag (event type with no label bound) ---
$boundTypes = @($eventLabels | ForEach-Object { $_.EventType } | Where-Object { $_ } | Select-Object -Unique)
$eventTypeRows = foreach ($e in $eventTypes) {
    [pscustomobject]@{
        EventType = $e.Name
        Guid      = $e.Guid
        HasLabel  = ($boundTypes -contains $e.Name)
        Flag      = if ($boundTypes -contains $e.Name) { '' } else { 'no-label-bound' }
    }
}

# --- Event-based label rows + orphan flag (label whose event type does not exist) ---
$typeNames = @($eventTypes | ForEach-Object { $_.Name })
$labelRows = foreach ($l in $eventLabels) {
    $typeExists = [string]::IsNullOrWhiteSpace($l.EventType) -or ($typeNames -contains $l.EventType)
    [pscustomobject]@{
        Label        = $l.Name
        EventType    = $l.EventType
        Record       = $l.IsRecordLabel
        Regulatory   = $l.Regulatory
        Action       = $l.RetentionAction
        DurationDays = $l.RetentionDuration
        Trigger      = $l.RetentionType
        Flag         = (@(
                          if ([string]::IsNullOrWhiteSpace($l.EventType)) { 'event-trigger-no-eventtype' }
                          elseif (-not $typeExists) { 'eventtype-missing' }
                        ) -join '; ')
    }
}

# --- Label policy rows referencing event-based labels ---
$eventLabelNames = @($eventLabels | ForEach-Object { $_.Name })
$policyRows = foreach ($p in $policies) {
    $rules = @()
    try { $rules = @(Get-RetentionComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue) } catch {}
    $taggedEvent = @($rules | Where-Object { $eventLabelNames -contains $_.PublishComplianceTag -or $eventLabelNames -contains $_.ApplyComplianceTag })
    if ($taggedEvent.Count -gt 0 -or $p.Name -like "*EventBased*") {
        [pscustomobject]@{
            Policy    = $p.Name
            Enabled   = $p.Enabled
            Publishes = (@($rules | ForEach-Object { $_.PublishComplianceTag }) -join ', ')
            AutoApply = (@($rules | ForEach-Object { $_.ApplyComplianceTag })  -join ', ')
        }
    }
}

# --- Raised events ---
$eventRows = foreach ($ev in $events) {
    [pscustomobject]@{
        Event     = $ev.Name
        EventType = $ev.EventType
        EventDate = $ev.EventDateTime
        Status    = $ev.Status
    }
}

# --- Duplicate event-type name detection ---
$dupTypes = @($eventTypes | Group-Object Name | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })

# --- Write CSVs ---
$paths = @{
    Types    = Join-Path $OutputPath "EventRetention-Posture-EventTypes.csv"
    Labels   = Join-Path $OutputPath "EventRetention-Posture-Labels.csv"
    Policies = Join-Path $OutputPath "EventRetention-Posture-Policies.csv"
    Events   = Join-Path $OutputPath "EventRetention-Posture-RaisedEvents.csv"
}
$eventTypeRows | Export-Csv -Path $paths.Types    -NoTypeInformation -Encoding UTF8
$labelRows     | Export-Csv -Path $paths.Labels   -NoTypeInformation -Encoding UTF8
$policyRows    | Export-Csv -Path $paths.Policies -NoTypeInformation -Encoding UTF8
$eventRows     | Export-Csv -Path $paths.Events   -NoTypeInformation -Encoding UTF8

# --- Console summary ---
Write-Host "== Event Retention Posture - Tenant - Discovery ==" -ForegroundColor Cyan
Write-Host ("Event types:        {0}" -f $eventTypes.Count)
Write-Host ("Event-based labels: {0}" -f $eventLabels.Count)
Write-Host ("Raised events:      {0}" -f $events.Count)
$paths.Values | ForEach-Object { Write-Host ("CSV : {0}" -f $_) -ForegroundColor Green }

if ($dupTypes.Count -gt 0) { Write-Host ("ATTENTION: duplicate event-type name(s): {0}" -f ($dupTypes -join ', ')) -ForegroundColor Yellow }
$orphanLabels = @($labelRows | Where-Object { $_.Flag })
if ($orphanLabels.Count -gt 0) { Write-Host ("ATTENTION: {0} event-based label(s) with linkage issues (see Flag column)." -f $orphanLabels.Count) -ForegroundColor Yellow }
$unusedTypes = @($eventTypeRows | Where-Object { -not $_.HasLabel })
if ($unusedTypes.Count -gt 0) { Write-Host ("NOTE: {0} event type(s) have no label bound (yet)." -f $unusedTypes.Count) -ForegroundColor Yellow }
Write-Host "Discovery complete (read-only)." -ForegroundColor Green
