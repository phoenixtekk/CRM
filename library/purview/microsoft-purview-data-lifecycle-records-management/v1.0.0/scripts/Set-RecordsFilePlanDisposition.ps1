<#
.SYNOPSIS
  Records / file-plan / event-type / disposition config helper (-WhatIf/dry-run by default).
.DESCRIPTION
  Creates/verifies file-plan descriptors (authority, category, sub-category, citation, department,
  reference id), event types for event-based retention, and validates records/disposition wiring
  (record & regulatory-record labels and their reviewer emails) from a JSON config. Reports intended
  changes by default; only writes when -Commit is passed. Refuses regulatory setup unless
  -AllowRegulatory + -SignOffRef. Disposition items themselves are actioned in the Purview portal.
.EXAMPLE
  .\Set-RecordsFilePlanDisposition.ps1 -ConfigPath .\records-design.json
  # Dry-run: prints descriptors/event types it WOULD create and validates disposition config. Add -Commit to apply.
.EXAMPLE
  .\Set-RecordsFilePlanDisposition.ps1 -ConfigPath .\records-design.json -Commit
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
.NOTES
  Expected results: file-plan descriptors + event types exist; reviewed record labels report their
  reviewers; a note to grant reviewers the Disposition Management role. Dry-run prints intent only.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [switch]$Commit,
    [switch]$AllowRegulatory,
    [string]$SignOffRef
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ConfigPath)) { throw "Config not found: $ConfigPath" }
$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$apply = $Commit.IsPresent
Write-Host ("== Set-RecordsFilePlanDisposition — {0} ==" -f ($(if ($apply) { 'COMMIT' } else { 'DRY-RUN (-WhatIf)' }))) -ForegroundColor Cyan
Write-Host ""

# ---------------- File-plan descriptors ----------------
# Map config section -> creating cmdlet. Extra params (e.g. citation url) handled inline.
$descriptorMap = @(
    @{ Section='authorities';    Cmd='New-FilePlanPropertyAuthority' },
    @{ Section='categories';     Cmd='New-FilePlanPropertyCategory' },
    @{ Section='subCategories';  Cmd='New-FilePlanPropertySubCategory' },
    @{ Section='departments';    Cmd='New-FilePlanPropertyDepartment' },
    @{ Section='referenceIds';   Cmd='New-FilePlanPropertyReferenceId' }
)

foreach ($d in $descriptorMap) {
    foreach ($name in @($cfg.filePlan.($d.Section))) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        Write-Host ("[FILEPLAN] {0}: {1}" -f $d.Cmd, $name) -ForegroundColor Yellow
        if (-not (Get-Command $d.Cmd -ErrorAction SilentlyContinue)) {
            Write-Warning ("   cmdlet {0} not available — Records management plan/scope required." -f $d.Cmd); continue
        }
        if ($apply -and $PSCmdlet.ShouldProcess($name, $d.Cmd)) {
            try { & $d.Cmd -Name $name -ErrorAction Stop | Out-Null; Write-Host "   -> created" -ForegroundColor Green }
            catch { Write-Warning ("   {0}" -f $_.Exception.Message) }
        }
        else { Write-Host "   -> would create (dry-run)" }
    }
}

# Citations carry a URL
foreach ($c in @($cfg.filePlan.citations)) {
    if (-not $c.name) { continue }
    Write-Host ("[FILEPLAN] New-FilePlanPropertyCitation: {0} ({1})" -f $c.name, $c.url) -ForegroundColor Yellow
    if ($apply -and (Get-Command New-FilePlanPropertyCitation -ErrorAction SilentlyContinue) -and $PSCmdlet.ShouldProcess($c.name, "New-FilePlanPropertyCitation")) {
        try { New-FilePlanPropertyCitation -Name $c.name -CitationUrl $c.url -ErrorAction Stop | Out-Null; Write-Host "   -> created" -ForegroundColor Green }
        catch { Write-Warning ("   {0}" -f $_.Exception.Message) }
    }
    elseif (-not $apply) { Write-Host "   -> would create (dry-run)" }
}

# ---------------- Event types ----------------
foreach ($e in @($cfg.eventTypes)) {
    if (-not $e.name) { continue }
    $exists = $null
    try { $exists = Get-ComplianceRetentionEventType -Identity $e.name -ErrorAction SilentlyContinue } catch { }
    Write-Host ("[EVENT TYPE] {0}: {1}" -f ($(if ($exists) { 'VERIFY' } else { 'CREATE' }), $e.name)) -ForegroundColor Yellow
    if (-not $exists) {
        if ($apply -and $PSCmdlet.ShouldProcess($e.name, "New-ComplianceRetentionEventType")) {
            try { New-ComplianceRetentionEventType -Name $e.name -Comment $e.comment -ErrorAction Stop | Out-Null; Write-Host "   -> created" -ForegroundColor Green }
            catch { Write-Warning ("   {0}" -f $_.Exception.Message) }
        }
        elseif (-not $apply) { Write-Host "   -> would create (dry-run)" }
    }
    else { Write-Host "   -> exists" }
}

# ---------------- Records / disposition validation (read-only checks) ----------------
Write-Host ""
Write-Host "Records & disposition validation:" -ForegroundColor Cyan
foreach ($r in @($cfg.recordLabels)) {
    $isReg = [bool]$r.regulatory
    if ($isReg -and (-not $AllowRegulatory -or [string]::IsNullOrWhiteSpace($SignOffRef))) {
        Write-Warning ("  '{0}' is REGULATORY (one-way). Validation only; to create/modify re-run with -AllowRegulatory -SignOffRef <ref> via Set-RetentionPolicyAndLabels.ps1." -f $r.name)
    }
    $tag = Get-ComplianceTag -Identity $r.name -ErrorAction SilentlyContinue
    if ($tag) {
        $revs = @($tag.ReviewerEmail)
        Write-Host ("  [{0}] record={1} regulatory={2} reviewers={3}" -f $r.name, $tag.IsRecordLabel, $tag.Regulatory, ($(if ($revs.Count) { $revs -join ';' } else { '(none)' }))) -ForegroundColor Green
        if ($r.dispositionReview -and -not $revs.Count) {
            Write-Warning ("    -> configured for disposition review but has NO reviewers; add -ReviewerEmail and ensure they are in the Disposition Management role group.")
        }
    }
    else { Write-Warning ("  [{0}] not found — create it first via Set-RetentionPolicyAndLabels.ps1." -f $r.name) }
}

Write-Host ""
Write-Host "NOTE: Disposition items are reviewed in the Purview portal (Records management -> Disposition)." -ForegroundColor Cyan
Write-Host "      Ensure every reviewer email above is a member of the 'Disposition Management' role group." -ForegroundColor Cyan
Write-Host ""
if (-not $apply) { Write-Host "DRY-RUN complete — no changes made. Re-run with -Commit to apply." -ForegroundColor Green }
else { Write-Host "COMMIT complete — validate records lock + disposition routing on the pilot (Section 5)." -ForegroundColor Green }
