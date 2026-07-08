<#
.SYNOPSIS
  Wire disposition reviewers into the Disposition Management role group (SAFE: -WhatIf by default).
.DESCRIPTION
  Validates each review stage's reviewer set against a JSON design and ensures every reviewer is a member of
  the Disposition Management role group so they can see/act on the queue. Reports over-grants (members not in
  any stage) and empty stages. Dry-run by default — only adds members when -Commit is passed. Enforces role
  separation; never approves a disposition.
.EXAMPLE
  .\Set-DispositionReviewers.ps1 -DesignPath .\disposition-design.json -WhatIf
  # Preview: which reviewers are missing from Disposition Management, which members are over-granted.
.EXAMPLE
  .\Set-DispositionReviewers.ps1 -DesignPath .\disposition-design.json -Commit
  # (PowerShell 5.1+/7+; module ExchangeOnlineManagement. Connect first: Connect-IPPSSession)
  # Adds the designed reviewers to Disposition Management. Does NOT remove anyone (removal is manual, gated).
.NOTES
  Expected results (dry-run): per-reviewer status (in-DM / missing) and a list of over-granted members.
  With -Commit: missing reviewers are added to Disposition Management. Uses the same design JSON as
  Set-DispositionReview.ps1 (single: Reviewers[]; multi: Stages[].Reviewers[]).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DesignPath,
    [switch]$Commit,
    [switch]$WhatIf,
    [string]$DispositionRoleGroup = "Disposition Management"
)

$ErrorActionPreference = 'Stop'
$doWrite = $Commit.IsPresent -and -not $WhatIf.IsPresent
$mode = if ($doWrite) { "COMMIT" } else { "DRY-RUN (-WhatIf default; pass -Commit to write)" }
Write-Host "== Set-DispositionReviewers — $mode ==" -ForegroundColor Cyan

if (-not (Test-Path $DesignPath)) { throw "Design file not found: $DesignPath" }
$design = Get-Content -Raw -Path $DesignPath | ConvertFrom-Json
if (-not $design) { throw "Design file is empty or invalid JSON: $DesignPath" }

# Collect the full designed reviewer set (across single + multi-stage labels)
$designedReviewers = New-Object System.Collections.Generic.List[string]
foreach ($d in @($design)) {
    if ($d.Reviewers) { foreach ($r in @($d.Reviewers)) { if ($r) { $designedReviewers.Add([string]$r) } } }
    if ($d.Stages)    { foreach ($s in @($d.Stages)) { foreach ($r in @($s.Reviewers)) { if ($r) { $designedReviewers.Add([string]$r) } } } }
}
$designedReviewers = @($designedReviewers | Select-Object -Unique)
if ($designedReviewers.Count -eq 0) { Write-Warning "No reviewers found in the design (Reviewers[] / Stages[].Reviewers[])."; }

# Current Disposition Management membership
$dmMembers = @()
try { $dmMembers = Get-RoleGroupMember -Identity $DispositionRoleGroup -ErrorAction Stop }
catch { throw "Get-RoleGroupMember -Identity '$DispositionRoleGroup' failed — confirm the role group exists and you can read it. $_" }

$dmSet = @{}
foreach ($m in $dmMembers) {
    foreach ($id in @($m.PrimarySmtpAddress, $m.Name, $m.WindowsLiveID, $m.DisplayName)) {
        if ($id) { $dmSet[[string]$id.ToLower()] = $m }
    }
}
function In-DM($email) { return $dmSet.ContainsKey([string]$email.ToLower()) }

# --- Report + optionally add missing reviewers ---
$missing = @()
Write-Host "`n-- Designed reviewers vs Disposition Management --" -ForegroundColor White
foreach ($r in $designedReviewers) {
    if (In-DM $r) {
        Write-Host ("  [OK]      {0} — in {1}" -f $r, $DispositionRoleGroup) -ForegroundColor Green
    } else {
        $missing += $r
        Write-Host ("  [MISSING] {0} — NOT in {1} (cannot act on the queue)" -f $r, $DispositionRoleGroup) -ForegroundColor Yellow
    }
}

if ($missing.Count -gt 0 -and $doWrite) {
    Write-Host "`n-- Adding missing reviewers to Disposition Management --" -ForegroundColor White
    foreach ($r in $missing) {
        try {
            Add-RoleGroupMember -Identity $DispositionRoleGroup -Member $r -ErrorAction Stop
            Write-Host ("  [COMMIT] added {0}" -f $r) -ForegroundColor Green
        } catch {
            Write-Warning ("  Failed to add {0}: {1} (confirm the account/group is mailbox- or mail-enabled and resolvable)" -f $r, $_)
        }
    }
} elseif ($missing.Count -gt 0) {
    Write-Host ("`n[DRY-RUN] {0} reviewer(s) would be added to {1}. Re-run with -Commit." -f $missing.Count, $DispositionRoleGroup) -ForegroundColor DarkGray
}

# --- Over-grant report (members not referenced by any designed stage) — role separation hygiene ---
$designedSet = @{}; foreach ($r in $designedReviewers) { $designedSet[[string]$r.ToLower()] = $true }
$overGranted = @()
foreach ($m in $dmMembers) {
    $matched = $false
    foreach ($id in @($m.PrimarySmtpAddress, $m.Name)) { if ($id -and $designedSet.ContainsKey([string]$id.ToLower())) { $matched = $true } }
    if (-not $matched) { $overGranted += ($m.PrimarySmtpAddress, $m.Name -join ' / ') }
}
if ($overGranted.Count -gt 0) {
    Write-Host "`n-- Over-grant review (members of Disposition Management NOT in the design) --" -ForegroundColor White
    Write-Host "   Verify these are intended reviewers; remove non-reviewers to preserve role separation (manual: Remove-RoleGroupMember)." -ForegroundColor Yellow
    $overGranted | ForEach-Object { Write-Host ("   - {0}" -f $_) -ForegroundColor Yellow }
}

Write-Host ("`nSummary: designed reviewers={0}, missing-from-DM={1}, over-granted={2}." -f $designedReviewers.Count, $missing.Count, $overGranted.Count) -ForegroundColor Cyan
Write-Host "This script never removes members and never approves a disposition. Removal is a deliberate, change-controlled manual action." -ForegroundColor Cyan
if (-not $doWrite) { Write-Host "Re-run with -Commit to add missing reviewers." -ForegroundColor Yellow }
