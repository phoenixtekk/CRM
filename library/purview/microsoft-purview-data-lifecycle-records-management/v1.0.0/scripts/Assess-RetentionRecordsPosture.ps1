<#
.SYNOPSIS
  Read-only discovery of tenant retention & records posture across M365 workloads.
.DESCRIPTION
  Inventories existing retention labels (incl. record/regulatory flags), retention policies and rules
  with their workload locations and enabled state, event types, and file-plan descriptors — using
  Security & Compliance PowerShell. Writes a CSV baseline for design/overlap analysis. Makes no changes.
.EXAMPLE
  .\Assess-RetentionRecordsPosture.ps1 -OutputPath .\out
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: "Retention Posture - Tenant - Discovery" CSVs (labels, policies+locations, events)
  plus a console summary of overlaps to review against retention precedence. Read-only.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\out"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

function Save-Csv($rows, $name) {
    $file = Join-Path $OutputPath $name
    $rows | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
    Write-Host ("  wrote {0} row(s) -> {1}" -f (($rows | Measure-Object).Count), $file) -ForegroundColor Green
}

# --- Retention / record labels ---
Write-Host "Reading retention labels (Get-ComplianceTag)..." -ForegroundColor Cyan
$labels = @()
try {
    $labels = Get-ComplianceTag | ForEach-Object {
        [pscustomobject]@{
            Name             = $_.Name
            IsRecordLabel    = $_.IsRecordLabel
            Regulatory       = $_.Regulatory
            RetentionAction  = $_.RetentionAction
            RetentionDuration= $_.RetentionDuration
            RetentionType    = $_.RetentionType
            EventType        = $_.EventType
            HasReviewers     = [bool]($_.ReviewerEmail)
            Reviewers        = ($_.ReviewerEmail -join ';')
            FilePlanSet      = [bool]($_.FilePlanMetadata)
        }
    }
    Save-Csv $labels "Retention-Posture-Tenant-Labels.csv"
}
catch { Write-Warning "Could not read retention labels (need Records management scope / plan?): $_" }

# --- Retention policies + rules with locations ---
Write-Host "Reading retention policies + rules (Get-RetentionCompliancePolicy / -Rule)..." -ForegroundColor Cyan
$polRows = New-Object System.Collections.Generic.List[object]
try {
    $rules = @{}
    Get-RetentionComplianceRule -ErrorAction SilentlyContinue | ForEach-Object {
        $key = [string]$_.Policy
        if (-not $rules.ContainsKey($key)) { $rules[$key] = @() }
        $rules[$key] += $_
    }
    foreach ($p in Get-RetentionCompliancePolicy) {
        $r = @(); if ($rules.ContainsKey([string]$p.Guid)) { $r = $rules[[string]$p.Guid] } elseif ($rules.ContainsKey($p.Name)) { $r = $rules[$p.Name] }
        $polRows.Add([pscustomobject]@{
            Name                = $p.Name
            Enabled             = $p.Enabled
            Mode                = $p.Mode
            ExchangeLocation    = ($p.ExchangeLocation    -join ';')
            SharePointLocation  = ($p.SharePointLocation  -join ';')
            OneDriveLocation    = ($p.OneDriveLocation    -join ';')
            ModernGroupLocation = ($p.ModernGroupLocation -join ';')
            TeamsChannel        = ($p.TeamsChannelLocation -join ';')
            TeamsChat           = ($p.TeamsChatLocation    -join ';')
            AdaptiveScopes      = ($p.AdaptiveScopeLocation -join ';')
            RuleActions         = (($r | ForEach-Object { "$($_.RetentionComplianceAction)/$($_.RetentionDuration)" }) -join ' | ')
            PublishTags         = (($r | ForEach-Object { $_.PublishComplianceTag }) -join ';')
            ApplyTags           = (($r | ForEach-Object { $_.ApplyComplianceTag })   -join ';')
        })
    }
    Save-Csv $polRows "Retention-Posture-Tenant-Policies.csv"
}
catch { Write-Warning "Could not read retention policies/rules: $_" }

# --- Event types ---
Write-Host "Reading event types (Get-ComplianceRetentionEventType)..." -ForegroundColor Cyan
try {
    $events = Get-ComplianceRetentionEventType -ErrorAction Stop |
        Select-Object Name, Comment, @{n='Created';e={$_.WhenCreated}}
    Save-Csv $events "Retention-Posture-Tenant-EventTypes.csv"
}
catch { Write-Warning "Could not read event types (plan/scope?): $_" }

# --- Overlap / precedence hints ---
Write-Host ""
Write-Host "Overlap review (validate against retention precedence — retention>deletion; longest wins; explicit>implicit; shortest deletion wins):" -ForegroundColor Cyan
$tenantWide = $polRows | Where-Object { ($_.ExchangeLocation -match 'All') -or ($_.SharePointLocation -match 'All') -or ($_.OneDriveLocation -match 'All') }
if ($tenantWide) {
    Write-Host ("  {0} policy(ies) target an 'All' location — any new policy/label will overlap these:" -f ($tenantWide | Measure-Object).Count) -ForegroundColor Yellow
    $tenantWide | ForEach-Object { Write-Host ("    - {0} (Enabled={1})" -f $_.Name, $_.Enabled) -ForegroundColor Yellow }
}
else { Write-Host "  No 'All'-location policies detected." }

$regLabels = $labels | Where-Object { $_.Regulatory -eq $true }
if ($regLabels) { Write-Host ("  {0} REGULATORY (one-way) label(s) already exist — cannot be removed/shortened." -f ($regLabels | Measure-Object).Count) -ForegroundColor Yellow }

Write-Host ""
Write-Host "Assessment complete (read-only). Review the CSVs before Stage 2 design." -ForegroundColor Green
