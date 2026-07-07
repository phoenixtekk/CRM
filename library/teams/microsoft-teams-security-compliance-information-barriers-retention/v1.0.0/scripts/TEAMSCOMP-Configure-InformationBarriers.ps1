<#
.SYNOPSIS
  Information-barrier segment + policy config helper (dry-run / -WhatIf by default; writes only with -Commit).
.DESCRIPTION
  Creates two named organization segments (from a compliance-defined directory attribute) and a
  block/allow information-barrier policy between them, following the naming convention
  '<Purpose> - <Scope> - <Stage>'. Safe by default: previews every action with -WhatIf and makes NO
  change unless -Commit is passed. Policy application (tenant-wide enforcement) runs only when the
  explicit -StartApplication switch is supplied. Determinations (which populations, which attribute,
  block vs allow) come from compliance/legal — this only implements them.
.EXAMPLE
  .\TEAMSCOMP-Configure-InformationBarriers.ps1 -SegmentAName "GroupA" -SegmentAFilter "Department -eq 'GroupA'" -SegmentBName "GroupB" -SegmentBFilter "Department -eq 'GroupB'"
  # dry-run (-WhatIf) — shows what would be created, changes nothing
.EXAMPLE
  .\TEAMSCOMP-Configure-InformationBarriers.ps1 -SegmentAName "GroupA" -SegmentAFilter "Department -eq 'GroupA'" -SegmentBName "GroupB" -SegmentBFilter "Department -eq 'GroupB'" -Commit
  # creates the segments + Inactive block policy for real
  (PowerShell 5.1+/7+, ExchangeOnlineManagement; connect via Connect-IPPSSession)
.NOTES
  Expected results: with no -Commit, WhatIf preview lines only. With -Commit, two segments and one
  Inactive IB policy are created; run TEAMSCOMP-Validation.ps1 then activate and apply per the guide.
  White-label. No credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SegmentAName,
    [Parameter(Mandatory)][string]$SegmentAFilter,
    [Parameter(Mandatory)][string]$SegmentBName,
    [Parameter(Mandatory)][string]$SegmentBFilter,
    [ValidateSet('Block','Allow')][string]$Relationship = 'Block',
    [string]$Stage = 'Pilot',
    [switch]$Commit,           # actually write (otherwise -WhatIf dry-run)
    [switch]$StartApplication  # tenant-wide enforcement — explicit opt-in only
)

$whatIf = -not $Commit
if ($whatIf) { Write-Host "DRY-RUN (-WhatIf): no changes will be made. Pass -Commit to apply." -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop

$segA = "IB Segment - $SegmentAName - Prod"
$segB = "IB Segment - $SegmentBName - Prod"
$policy = "IB Policy - $SegmentAName-$($Relationship.ToLower())s-$SegmentBName - $Stage"

Write-Host "`n=== Configure information barriers ===" -ForegroundColor Cyan
Write-Host ("  Segment A : {0}  [{1}]" -f $segA, $SegmentAFilter)
Write-Host ("  Segment B : {0}  [{1}]" -f $segB, $SegmentBFilter)
Write-Host ("  Policy    : {0}  ({1})" -f $policy, $Relationship)

# --- Segments ------------------------------------------------------------------
if (-not (Get-OrganizationSegment -ErrorAction SilentlyContinue | Where-Object Name -eq $segA)) {
    New-OrganizationSegment -Name $segA -UserGroupFilter $SegmentAFilter -WhatIf:$whatIf
} else { Write-Host "  Segment A already exists — skipping." -ForegroundColor Gray }

if (-not (Get-OrganizationSegment -ErrorAction SilentlyContinue | Where-Object Name -eq $segB)) {
    New-OrganizationSegment -Name $segB -UserGroupFilter $SegmentBFilter -WhatIf:$whatIf
} else { Write-Host "  Segment B already exists — skipping." -ForegroundColor Gray }

# --- Policy (created Inactive; activate separately after review) ----------------
if (-not (Get-InformationBarrierPolicy -ErrorAction SilentlyContinue | Where-Object Name -eq $policy)) {
    if ($Relationship -eq 'Block') {
        New-InformationBarrierPolicy -Name $policy -AssignedSegment $segA -SegmentsBlocked $segB -State Inactive -WhatIf:$whatIf
    } else {
        New-InformationBarrierPolicy -Name $policy -AssignedSegment $segA -SegmentsAllowed $segB -State Inactive -WhatIf:$whatIf
    }
    Write-Host "  Policy created Inactive. Review, then: Set-InformationBarrierPolicy -Identity '$policy' -State Active" -ForegroundColor Green
} else { Write-Host "  Policy already exists — skipping." -ForegroundColor Gray }

# --- Application (tenant-wide) — explicit opt-in only ---------------------------
if ($StartApplication) {
    if ($whatIf) {
        Write-Host "  [WhatIf] Would run Start-InformationBarrierPoliciesApplication (tenant-wide)." -ForegroundColor Yellow
    } else {
        Write-Host "  Starting IB policy application (tenant-wide evaluation)..." -ForegroundColor Yellow
        Start-InformationBarrierPoliciesApplication
        Write-Host "  Monitor with: Get-InformationBarrierPoliciesApplicationStatus" -ForegroundColor Green
    }
} else {
    Write-Host "  Application NOT started (no -StartApplication). Activate the policy and apply per the guide." -ForegroundColor Gray
}

Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
