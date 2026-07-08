<#
.SYNOPSIS
  Create/update retention labels with single- or multi-stage disposition review (SAFE: -WhatIf by default).
.DESCRIPTION
  Reads a JSON design of disposition-review labels and creates or updates retain-then-delete retention
  labels (New-ComplianceTag / Set-ComplianceTag) with either single-stage (-ReviewerEmail) or multi-stage
  (-MultiStageReviewProperty) review, optionally publishing them to the pilot scope. Dry-run by default —
  echoes the exact cmdlet intent (including the multi-stage property JSON for verification) and only writes
  when -Commit is passed. Never approves, extends, or deletes a disposition.
.EXAMPLE
  .\Set-DispositionReview.ps1 -DesignPath .\disposition-design.json -WhatIf
  # Preview only — echoes New-/Set-ComplianceTag intent and the multi-stage property so you can verify it.
.EXAMPLE
  .\Set-DispositionReview.ps1 -DesignPath .\disposition-design.json -Commit
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
  # Writes the labels. Regulatory labels require -AllowRegulatory -SignOffRef and are out of normal scope.
.NOTES
  Expected results (dry-run): per-label plan showing action/duration/trigger and the review config
  (single vs multi-stage stages+reviewers). With -Commit: labels exist as designed. VERIFY the
  -MultiStageReviewProperty shape against current Microsoft docs / your tenant before committing —
  the multi-stage schema has changed across releases.
  Design JSON (array):
    [ {
        "Name":"Disposition Label - Records-7yr - Pilot",
        "RetentionDuration":2555, "RetentionType":"ModificationAgeInDays",
        "Review":"single", "Reviewers":["disposition-reviewers-records@contoso.com"]
      },
      {
        "Name":"Disposition Label - Contracts-7yr-MS - Pilot",
        "RetentionDuration":2555, "RetentionType":"ModificationAgeInDays",
        "Review":"multi",
        "Stages":[ {"StageName":"Records","Reviewers":["...records@contoso.com"]},
                   {"StageName":"Compliance","Reviewers":["...compliance@contoso.com"]},
                   {"StageName":"Legal","Reviewers":["...legal@contoso.com"]} ]
      } ]
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DesignPath,
    [switch]$Commit,
    [switch]$WhatIf,
    [switch]$AllowRegulatory,
    [string]$SignOffRef
)

$ErrorActionPreference = 'Stop'
$doWrite = $Commit.IsPresent -and -not $WhatIf.IsPresent
$mode = if ($doWrite) { "COMMIT" } else { "DRY-RUN (-WhatIf default; pass -Commit to write)" }
Write-Host "== Set-DispositionReview — $mode ==" -ForegroundColor Cyan

if (-not (Test-Path $DesignPath)) { throw "Design file not found: $DesignPath" }
$design = Get-Content -Raw -Path $DesignPath | ConvertFrom-Json
if (-not $design) { throw "Design file is empty or invalid JSON: $DesignPath" }

function Get-ExistingTag($name) { try { return Get-ComplianceTag -Identity $name -ErrorAction Stop } catch { return $null } }

foreach ($d in @($design)) {
    if (-not $d.Name) { Write-Warning "Skipping an entry with no Name."; continue }
    Write-Host ("`n--- {0} ---" -f $d.Name) -ForegroundColor White

    if ($d.Regulatory -eq $true -and -not ($AllowRegulatory -and $SignOffRef)) {
        Write-Warning "Regulatory label refused — requires -AllowRegulatory and -SignOffRef (records/legal sign-off). Skipping."
        continue
    }

    $dur     = if ($d.RetentionDuration) { [int]$d.RetentionDuration } else { throw "RetentionDuration required for $($d.Name)" }
    $trigger = if ($d.RetentionType) { [string]$d.RetentionType } else { 'ModificationAgeInDays' }

    # Build review parameters
    $reviewKind = ([string]$d.Review).ToLower()
    $commonDesc = "action=KeepAndDelete duration=$dur trigger=$trigger"

    $multiJson = $null
    if ($reviewKind -eq 'multi') {
        if (-not $d.Stages) { throw "Review=multi requires a Stages array for $($d.Name)" }
        $stagesArr = @()
        foreach ($s in @($d.Stages)) {
            $stagesArr += [ordered]@{ StageName = [string]$s.StageName; Reviewers = @($s.Reviewers) }
        }
        # NOTE: property shape has changed across releases — verify before committing.
        $multiJson = @{ MultiStageReviewSettings = $stagesArr } | ConvertTo-Json -Depth 5
        Write-Host ("  Review: MULTI-STAGE ({0} stage(s)) — {1}" -f $stagesArr.Count, $commonDesc) -ForegroundColor Cyan
        Write-Host "  -MultiStageReviewProperty (VERIFY this shape against current docs/your tenant):" -ForegroundColor Yellow
        Write-Host ($multiJson -split "`n" | ForEach-Object { "      $_" }) -ForegroundColor DarkYellow
    }
    elseif ($reviewKind -eq 'single') {
        if (-not $d.Reviewers) { throw "Review=single requires Reviewers for $($d.Name)" }
        Write-Host ("  Review: SINGLE-STAGE reviewers=[{0}] — {1}" -f (@($d.Reviewers) -join ';'), $commonDesc) -ForegroundColor Cyan
    }
    else {
        Write-Warning "Review kind '$($d.Review)' not recognised for $($d.Name) (expected 'single' or 'multi'). Skipping."
        continue
    }

    $existing = Get-ExistingTag $d.Name
    $verb = if ($existing) { "UPDATE (Set-ComplianceTag)" } else { "CREATE (New-ComplianceTag)" }
    Write-Host ("  Plan: {0}" -f $verb) -ForegroundColor Green

    if (-not $doWrite) {
        Write-Host "  [DRY-RUN] no change written." -ForegroundColor DarkGray
        continue
    }

    # ---- COMMIT ----
    try {
        $params = @{ RetentionAction = 'KeepAndDelete'; RetentionDuration = $dur; RetentionType = $trigger }
        if ($reviewKind -eq 'single') { $params['ReviewerEmail'] = @($d.Reviewers) }
        if ($reviewKind -eq 'multi')  { $params['MultiStageReviewProperty'] = $multiJson }
        if ($d.Regulatory -eq $true)  { $params['Regulatory'] = $true }

        if ($existing) {
            Set-ComplianceTag -Identity $d.Name @params -ErrorAction Stop
            Write-Host "  [COMMIT] updated." -ForegroundColor Green
        } else {
            New-ComplianceTag -Name $d.Name @params -ErrorAction Stop
            Write-Host "  [COMMIT] created." -ForegroundColor Green
        }
        if ($d.Regulatory -eq $true) { Write-Host ("  [AUDIT] regulatory label committed under sign-off ref: {0}" -f $SignOffRef) -ForegroundColor Yellow }
    } catch {
        Write-Warning ("  Failed on {0}: {1}" -f $d.Name, $_)
        if ($reviewKind -eq 'multi') { Write-Warning "  If -MultiStageReviewProperty was rejected, verify the current property schema and multi-stage plan availability." }
    }
}

Write-Host "`nDone. This script never approves/extends/deletes a disposition — reviewers act in the portal (Records management -> Disposition)." -ForegroundColor Cyan
if (-not $doWrite) { Write-Host "Re-run with -Commit to apply." -ForegroundColor Yellow }
