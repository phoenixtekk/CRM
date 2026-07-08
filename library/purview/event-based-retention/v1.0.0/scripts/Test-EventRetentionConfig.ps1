<#
.SYNOPSIS
  Validate the event-based retention configuration against the design (read-only).
.DESCRIPTION
  For each item in the JSON design, confirms the event TYPE exists, the LABEL exists with an event trigger
  bound to the CORRECT event type and the designed action/duration/record status, and (where named) the
  label POLICY is pilot-scoped. Reports PASS/FAIL per check. Makes no changes — this is the Stage 5 gate.
.EXAMPLE
  .\Test-EventRetentionConfig.ps1 -ConfigPath .\event-design.json
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: every designed event type + label exists and is correctly linked and scoped -> overall
  PASS; any missing/mislinked/mis-scoped artifact -> FAIL with the specific reason. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,
    [string]$OutputPath = ".\out"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$results = New-Object System.Collections.Generic.List[object]
function Add-Check($area, $name, $pass, $detail) {
    $results.Add([pscustomobject]@{ Area = $area; Item = $name; Result = $(if ($pass) { 'PASS' } else { 'FAIL' }); Detail = $detail })
    $color = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}: {2} — {3}" -f $area, $name, $(if ($pass) { 'PASS' } else { 'FAIL' }), $detail) -ForegroundColor $color
}

Write-Host "== Test-EventRetentionConfig (read-only) ==" -ForegroundColor Cyan

# --- Event types ---
foreach ($t in @($cfg.eventTypes)) {
    $name = if ($t.PSObject.Properties.Name -contains 'name') { $t.name } else { $t }
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    $et = $null
    try { $et = Get-ComplianceRetentionEventType -Identity $name -ErrorAction SilentlyContinue } catch {}
    Add-Check 'EventType' $name ([bool]$et) $(if ($et) { 'exists' } else { 'MISSING — create in config mode' })
}

# --- Labels ---
foreach ($l in @($cfg.labels)) {
    $lbl = $null
    try { $lbl = Get-ComplianceTag -Identity $l.name -ErrorAction SilentlyContinue } catch {}
    if (-not $lbl) { Add-Check 'Label' $l.name $false 'MISSING'; continue }

    $isEvent = ($lbl.RetentionType -match 'Event')
    Add-Check 'Label' $l.name $isEvent $(if ($isEvent) { "event trigger ($($lbl.RetentionType))" } else { "NOT event-based (RetentionType=$($lbl.RetentionType))" })

    $typeOk = ($lbl.EventType -eq $l.eventType)
    Add-Check 'Label-EventType' $l.name $typeOk $(if ($typeOk) { "bound to '$($l.eventType)'" } else { "bound to '$($lbl.EventType)', expected '$($l.eventType)'" })

    if ($l.retentionDuration) {
        $durOk = ([string]$lbl.RetentionDuration -eq [string]$l.retentionDuration)
        Add-Check 'Label-Duration' $l.name $durOk ("actual=$($lbl.RetentionDuration) expected=$($l.retentionDuration)")
    }
    if ($l.PSObject.Properties.Name -contains 'isRecordLabel') {
        $recOk = ([bool]$lbl.IsRecordLabel -eq [bool]$l.isRecordLabel)
        Add-Check 'Label-Record' $l.name $recOk ("actual=$([bool]$lbl.IsRecordLabel) expected=$([bool]$l.isRecordLabel)")
    }
}

# --- Label policies (pilot scope) ---
foreach ($pol in @($cfg.labelPolicies)) {
    $name = if ($pol.PSObject.Properties.Name -contains 'name') { $pol.name } else { $pol }
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    $p = $null
    try { $p = Get-RetentionCompliancePolicy -Identity $name -ErrorAction SilentlyContinue } catch {}
    if (-not $p) { Add-Check 'LabelPolicy' $name $false 'MISSING'; continue }
    $scoped = ($name -like "*Pilot*") -or ($p.SharePointLocation -and ($p.SharePointLocation -notcontains 'All'))
    Add-Check 'LabelPolicy' $name $scoped $(if ($scoped) { 'pilot-scoped' } else { 'NOT pilot-scoped (targets All?) — confirm before Expand' })
}

# --- Summary ---
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' })
$csv = Join-Path $OutputPath "EventRetention-Validation.csv"
$results | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host ("CSV : {0}" -f $csv) -ForegroundColor Green
if ($fail.Count -eq 0) { Write-Host "VALIDATION PASS — configuration matches the design. Proceed per the Stage 5 gate." -ForegroundColor Green }
else { Write-Host ("VALIDATION FAIL — {0} check(s) failed. Resolve before expanding." -f $fail.Count) -ForegroundColor Red }
