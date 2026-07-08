<#
.SYNOPSIS
  Inventory disposition-review posture across retention labels (read-only; makes no changes).
.DESCRIPTION
  Enumerates retention labels and, for retain-then-delete labels, whether disposition review is enabled
  (single- vs multi-stage), the review stages and their reviewers, plus Disposition Management role-group
  membership. Flags the key gaps: retain-then-delete labels that auto-delete with NO review, reviewers not
  in Disposition Management, and empty/unresolved stages. Writes CSVs. Read-only.
.EXAMPLE
  .\Assess-DispositionPosture.ps1 -OutputPath .\out
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: "Disposition Posture - Tenant - Discovery" CSVs (labels + role-group members) and a
  console summary highlighting auto-delete-no-review labels and reviewers missing from Disposition
  Management. Read-only — no writes.
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

# Normalise Disposition Management member identities (name / email) for cross-check
$dmSet = @{}
foreach ($m in $dmMembers) {
    foreach ($id in @($m.Name, $m.PrimarySmtpAddress, $m.WindowsLiveID, $m.DisplayName)) {
        if ($id) { $dmSet[[string]$id.ToLower()] = $true }
    }
}
function In-DM($email) { if (-not $email) { return $false }; return [bool]$dmSet[[string]$email.ToLower()] }

# --- Parse review configuration off each label (defensive: properties vary by module/plan) ---
function Get-ReviewStages($label) {
    # Returns an array of [pscustomobject]@{ Stage; Reviewers }
    $stages = @()
    # Single-stage: ReviewerEmail
    if ($label.ReviewerEmail) {
        $stages += [pscustomobject]@{ Stage = 'Stage1(single)'; Reviewers = @($label.ReviewerEmail) }
    }
    # Multi-stage: MultiStageReviewProperty (shape varies across releases — parse defensively)
    $ms = $label.MultiStageReviewProperty
    if ($ms) {
        try {
            $obj = if ($ms -is [string]) { $ms | ConvertFrom-Json -ErrorAction Stop } else { $ms }
            $settings = $obj.MultiStageReviewSettings
            if ($settings) {
                $i = 0
                foreach ($s in @($settings)) {
                    $i++
                    $name = if ($s.StageName) { $s.StageName } else { "Stage$i" }
                    $stages += [pscustomobject]@{ Stage = ("Stage{0}:{1}" -f $i, $name); Reviewers = @($s.Reviewers) }
                }
            } else {
                $stages += [pscustomobject]@{ Stage = 'multi-stage(unparsed)'; Reviewers = @() }
            }
        } catch {
            $stages += [pscustomobject]@{ Stage = 'multi-stage(parse-failed — verify shape)'; Reviewers = @() }
        }
    }
    return $stages
}

$labelRows = foreach ($l in $labels) {
    $isRTD    = ($l.RetentionAction -eq 'KeepAndDelete')
    $stages   = @(Get-ReviewStages $l)
    $reviewed = ($stages.Count -gt 0)
    $allReviewers = @($stages | ForEach-Object { $_.Reviewers } | Where-Object { $_ }) | Select-Object -Unique
    $notInDM  = @($allReviewers | Where-Object { -not (In-DM $_) })
    $emptyStages = @($stages | Where-Object { (@($_.Reviewers) | Measure-Object).Count -eq 0 })

    $gaps = @()
    if ($isRTD -and -not $reviewed) { $gaps += 'AUTO-DELETE-NO-REVIEW' }
    if ($reviewed -and $notInDM.Count -gt 0) { $gaps += ("reviewers-not-in-DM:{0}" -f ($notInDM -join ',')) }
    if ($emptyStages.Count -gt 0) { $gaps += 'empty-stage' }
    if (-not $isRTD -and $reviewed) { $gaps += 'review-on-non-delete-label?' }

    [pscustomobject]@{
        Label           = $l.Name
        RetentionAction = $l.RetentionAction
        DurationDays    = $l.RetentionDuration
        Trigger         = $l.RetentionType
        IsRecordLabel   = $l.IsRecordLabel
        Regulatory      = $l.Regulatory
        ReviewEnabled   = $reviewed
        StageCount      = $stages.Count
        Stages          = (($stages | ForEach-Object { "{0}=[{1}]" -f $_.Stage, ($_.Reviewers -join ';') }) -join ' | ')
        Gap             = ($gaps -join '; ')
    }
}

$dmRows = foreach ($m in $dmMembers) {
    [pscustomobject]@{
        Member = $m.Name
        Email  = $m.PrimarySmtpAddress
        Type   = $m.RecipientType
    }
}

# --- Write CSVs ---
$labelCsv = Join-Path $OutputPath "Disposition-Posture-Tenant-Labels.csv"
$dmCsv    = Join-Path $OutputPath "Disposition-Posture-Tenant-DispositionManagement.csv"
$labelRows | Export-Csv -Path $labelCsv -NoTypeInformation -Encoding UTF8
$dmRows    | Export-Csv -Path $dmCsv    -NoTypeInformation -Encoding UTF8

# --- Summary ---
$autoDelNoReview = @($labelRows | Where-Object { $_.Gap -match 'AUTO-DELETE-NO-REVIEW' })
$reviewersMissing = @($labelRows | Where-Object { $_.Gap -match 'reviewers-not-in-DM' })
$summary = [pscustomobject]@{
    LabelsTotal            = (@($labels) | Measure-Object).Count
    RetainThenDeleteLabels = (@($labels | Where-Object { $_.RetentionAction -eq 'KeepAndDelete' }) | Measure-Object).Count
    ReviewEnabledLabels    = (@($labelRows | Where-Object { $_.ReviewEnabled }) | Measure-Object).Count
    MultiStageLabels       = (@($labelRows | Where-Object { $_.StageCount -gt 1 }) | Measure-Object).Count
    AutoDeleteNoReview     = $autoDelNoReview.Count
    ReviewersNotInDM       = $reviewersMissing.Count
    DispositionMgmtMembers = (@($dmMembers) | Measure-Object).Count
    GeneratedUtc           = (Get-Date).ToUniversalTime().ToString('u')
}

Write-Host "== Disposition Posture - Tenant - Discovery (read-only) ==" -ForegroundColor Cyan
$summary | Format-List
Write-Host ("CSV : {0}" -f $labelCsv) -ForegroundColor Green
Write-Host ("CSV : {0}" -f $dmCsv)    -ForegroundColor Green
if ($autoDelNoReview.Count -gt 0) {
    Write-Host ("ATTENTION: {0} retain-then-delete label(s) AUTO-DELETE with no review — confirm with records/legal whether review is required:" -f $autoDelNoReview.Count) -ForegroundColor Yellow
    $autoDelNoReview | ForEach-Object { Write-Host ("   - {0}" -f $_.Label) -ForegroundColor Yellow }
}
if ($reviewersMissing.Count -gt 0) {
    Write-Host ("ATTENTION: {0} reviewed label(s) have reviewers NOT in Disposition Management — they cannot act on the queue." -f $reviewersMissing.Count) -ForegroundColor Yellow
}
Write-Host "Assessment complete (read-only)." -ForegroundColor Green
