<#
.SYNOPSIS
  Event-based retention config/remediation helper (-WhatIf/dry-run by default).
.DESCRIPTION
  From a JSON design, creates/verifies event TYPES (New-ComplianceRetentionEventType) and event-based LABELS
  (New-ComplianceTag -RetentionType EventAgeInDays -EventType ...). With -RaiseEvent it raises a retention
  event (New-ComplianceRetentionEvent) against asset IDs / keywords to START the retention clock. Reports
  intended changes by default; only writes when -Commit is passed. Refuses regulatory-record labels unless
  -AllowRegulatory -SignOffRef is supplied. Raise real events only through change control; test on disposable
  assets.
.EXAMPLE
  .\Set-EventTypesAndLabels.ps1 -ConfigPath .\event-design.json
  # Dry-run: prints every event type / label it WOULD create. Add -Commit to apply.
.EXAMPLE
  .\Set-EventTypesAndLabels.ps1 -RaiseEvent -EventName "Retention Event – TEST-Termination – Pilot" `
     -EventType "Event Type – Employee-Termination" -EventTags "Retention Label – Termination-7yr – Pilot" `
     -AssetId "TEST-ASSET-001" -Commit
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: each designed event type + event-based label exists with the correct event linkage,
  action and duration; with -RaiseEvent, a retention event is raised that (after propagation) starts the
  clock on the matching content. Dry-run prints intent only; no credentials in code.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # --- Config mode (event types + labels) ---
    [string]$ConfigPath,

    # --- Raise-event mode ---
    [switch]$RaiseEvent,
    [string]$EventName,
    [string]$EventType,
    [string[]]$EventTags,
    [string[]]$AssetId,
    [string[]]$Keywords,
    [datetime]$EventDateTime = (Get-Date),

    # Apply changes. Without this, the script only reports intended changes.
    [switch]$Commit,

    # Required to create one-way regulatory-record labels (must also pass -SignOffRef).
    [switch]$AllowRegulatory,
    [string]$SignOffRef
)

$ErrorActionPreference = 'Stop'
$apply = $Commit.IsPresent
$mode  = if ($apply) { "COMMIT" } else { "DRY-RUN (-WhatIf)" }
Write-Host "== Set-EventTypesAndLabels — $mode ==" -ForegroundColor Cyan

# =================== RAISE-EVENT MODE ===================
if ($RaiseEvent) {
    if ([string]::IsNullOrWhiteSpace($EventName) -or [string]::IsNullOrWhiteSpace($EventType)) {
        throw "-RaiseEvent requires -EventName and -EventType."
    }
    if (-not $AssetId -and -not $Keywords) {
        throw "-RaiseEvent requires at least one of -AssetId or -Keywords (nothing would match otherwise)."
    }

    # Preflight: the event type must exist and any named label should be event-based on this type.
    $etExists = $null
    try { $etExists = Get-ComplianceRetentionEventType -Identity $EventType -ErrorAction SilentlyContinue } catch {}
    if (-not $etExists) { Write-Warning ("Event type '{0}' not found — create it first (config mode)." -f $EventType) }

    foreach ($t in @($EventTags)) {
        if ([string]::IsNullOrWhiteSpace($t)) { continue }
        $lbl = $null
        try { $lbl = Get-ComplianceTag -Identity $t -ErrorAction SilentlyContinue } catch {}
        if (-not $lbl) { Write-Warning ("Label '{0}' not found." -f $t) }
        elseif ($lbl.RetentionType -notmatch 'Event') { Write-Warning ("Label '{0}' is not event-based (RetentionType={1})." -f $t, $lbl.RetentionType) }
        elseif ($lbl.EventType -and $lbl.EventType -ne $EventType) { Write-Warning ("Label '{0}' is bound to event type '{1}', not '{2}'." -f $t, $lbl.EventType, $EventType) }
    }

    Write-Host ("[EVENT] RAISE '{0}'" -f $EventName) -ForegroundColor Yellow
    Write-Host ("   eventType={0} eventDate={1}" -f $EventType, $EventDateTime.ToString('u'))
    Write-Host ("   assetIds={0} keywords={1} tags={2}" -f ($AssetId -join ','), ($Keywords -join ','), ($EventTags -join ','))
    Write-Host "   NOTE: raising an event STARTS retention clocks on matching content. Test on disposable assets only." -ForegroundColor Magenta

    if ($apply -and $PSCmdlet.ShouldProcess($EventName, "New-ComplianceRetentionEvent")) {
        $ep = @{ Name = $EventName; EventType = $EventType; EventDateTime = $EventDateTime }
        if ($EventTags) { $ep.EventTags = @($EventTags) }
        if ($AssetId)   { $ep.AssetId   = @($AssetId) }
        if ($Keywords)  { $ep.Keywords  = @($Keywords) }
        New-ComplianceRetentionEvent @ep | Out-Null
        Write-Host "   -> event raised. Allow for propagation (hours to days), then validate the clock start." -ForegroundColor Green
    } else {
        Write-Host "   -> would raise event (dry-run). Re-run with -Commit to raise." -ForegroundColor Green
    }
    return
}

# =================== CONFIG MODE (event types + labels) ===================
if ([string]::IsNullOrWhiteSpace($ConfigPath)) { throw "Provide -ConfigPath (config mode) or -RaiseEvent (raise mode)." }
if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# ---------------- Event types ----------------
foreach ($t in @($cfg.eventTypes)) {
    $name = if ($t.PSObject.Properties.Name -contains 'name') { $t.name } else { $t }
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    $existing = $null
    try { $existing = Get-ComplianceRetentionEventType -Identity $name -ErrorAction SilentlyContinue } catch {}
    $verb = if ($existing) { "EXISTS" } else { "CREATE" }
    Write-Host ("[EVENT TYPE] {0}: {1}" -f $verb, $name) -ForegroundColor Yellow
    if (-not $existing) {
        if ($apply -and $PSCmdlet.ShouldProcess($name, "New-ComplianceRetentionEventType")) {
            New-ComplianceRetentionEventType -Name $name | Out-Null
            Write-Host "   -> created" -ForegroundColor Green
        } else { Write-Host "   -> would create (dry-run)" }
    } else { Write-Host "   -> reuse existing (do not duplicate)" }
}

# ---------------- Event-based labels ----------------
foreach ($l in @($cfg.labels)) {
    $isReg = [bool]$l.regulatory
    if ($isReg -and (-not $AllowRegulatory -or [string]::IsNullOrWhiteSpace($SignOffRef))) {
        Write-Warning ("SKIP regulatory label '{0}' — regulatory records are ONE-WAY. Re-run with -AllowRegulatory -SignOffRef <ref>." -f $l.name)
        continue
    }
    if ([string]::IsNullOrWhiteSpace($l.eventType)) {
        Write-Warning ("Label '{0}' has no eventType — an event-based label must name an event type. Skipping." -f $l.name)
        continue
    }

    $existing = $null
    try { $existing = Get-ComplianceTag -Identity $l.name -ErrorAction SilentlyContinue } catch {}
    $verb = if ($existing) { "VERIFY" } else { "CREATE" }
    Write-Host ("[LABEL] {0}: {1}" -f $verb, $l.name) -ForegroundColor Yellow
    $retType = if ($l.retentionType) { $l.retentionType } else { 'EventAgeInDays' }
    Write-Host ("   action={0} durationDays={1} type={2} eventType={3} record={4} regulatory={5}" -f `
        $l.retentionAction, $l.retentionDuration, $retType, $l.eventType, [bool]$l.isRecordLabel, $isReg)

    if (-not $existing) {
        $p = @{
            Name            = $l.name
            RetentionAction = $l.retentionAction
            RetentionType   = $retType          # event trigger, e.g. EventAgeInDays
            EventType       = $l.eventType
        }
        if ($l.retentionDuration) { $p.RetentionDuration = $l.retentionDuration }
        if ($l.isRecordLabel)     { $p.IsRecordLabel = $true }
        if ($isReg)               { $p.Regulatory = $true }
        if ($l.comment)           { $p.Comment = $l.comment }

        if ($apply -and $PSCmdlet.ShouldProcess($l.name, "New-ComplianceTag (event-based)")) {
            if ($isReg) { Write-Host ("   [regulatory sign-off: {0}]" -f $SignOffRef) -ForegroundColor Magenta }
            New-ComplianceTag @p | Out-Null
            Write-Host "   -> created (pending until an event is raised)" -ForegroundColor Green
        } else { Write-Host "   -> would create (dry-run)" }
    } else {
        Write-Host "   -> exists; verify event trigger, event type, action and duration against design"
    }
}

Write-Host ""
if (-not $apply) { Write-Host "DRY-RUN complete — no changes made. Re-run with -Commit to apply." -ForegroundColor Green }
else { Write-Host "COMMIT complete — labels are PENDING until their event is raised; publish to the pilot and validate before Expand." -ForegroundColor Green }
