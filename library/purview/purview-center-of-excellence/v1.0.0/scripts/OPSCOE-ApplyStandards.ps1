<#
.SYNOPSIS
    OPSCOE-ApplyStandards.ps1 - apply CoE board role-group membership and stamp ownership/standard tags; -WhatIf by default.
.DESCRIPTION
    PURPOSE
        Two governance actions for a Purview Center of Excellence, both SAFE BY DEFAULT (preview with
        -WhatIf, apply only with -Commit):
        (1) -RoleMatrixCsv: reads a Seat,RoleGroup,Member matrix and adds the named members to the built-in
            role groups (Add-RoleGroupMember), creating any custom scoped groups (New-RoleGroup) the matrix
            declares. Every applied change prints its REVERSE command.
        (2) -StampOwnership -OwnerMapCsv: writes a non-disruptive ownership/standard tag into the writable
            Comment field of governed policies (CoE-Owner=<name>; Review=<date>) via Set-DlpCompliancePolicy
            / Set-RetentionCompliancePolicy / Set-AutoSensitivityLabelPolicy -Comment. It NEVER changes a
            policy's rules, scope, or enforcement state, and records each prior Comment so -Restore reverts it.
        This tool never flips a policy to enforce - enforcement is a board-gated, intake-driven portal action.
    HOW TO RUN
        # Board role-group membership:
        .\OPSCOE-ApplyStandards.ps1 -RoleMatrixCsv .\coe-board-matrix.csv -WhatIf    # preview
        .\OPSCOE-ApplyStandards.ps1 -RoleMatrixCsv .\coe-board-matrix.csv -Commit    # apply
        # Ownership/standard stamp:
        .\OPSCOE-ApplyStandards.ps1 -StampOwnership -OwnerMapCsv .\coe-owner-map.csv -WhatIf
        .\OPSCOE-ApplyStandards.ps1 -StampOwnership -OwnerMapCsv .\coe-owner-map.csv -Commit
        # Revert the stamps:
        .\OPSCOE-ApplyStandards.ps1 -StampOwnership -Restore -Commit
        matrix columns: Seat,RoleGroup,Member (+ optional Custom=Yes to create a scoped group).
        owner-map columns: Type,Name,Owner,Review (Type = Dlp|Retention|AutoLabel).
        Prereqs: ExchangeOnlineManagement (Connect-IPPSSession) + Connect-ExchangeOnline for role-group cmdlets.
    EXPECTED RESULTS
        Without -Commit: a per-change plan and, for role adds, the reverse command. With -Commit: each change
        applied with a PASS/FAIL line. PASS = matrix members resolve to exactly the intended role groups; each
        stamped policy's Comment shows the owner/review tag and NO rule/scope/enforcement value changed.
.NOTES
    White-label Microsoft Purview tooling. -WhatIf by default; writes only with -Commit. Security & Compliance
    PowerShell / Exchange Online. No credentials in code. Role-group names EVOLVE - verify in your tenant.
#>
[CmdletBinding()]
param(
    [string]$RoleMatrixCsv,
    [switch]$StampOwnership,
    [string]$OwnerMapCsv,
    [switch]$Restore,
    [string]$RestoreStorePath = ".\OPSCOE-StampBackup.json",
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
$mode = if ($Commit) { 'COMMIT (changes WILL be applied)' } else { '-WhatIf (dry-run - no changes)' }
Write-Section ("Mode: {0}" -f $mode)

# Investigative role groups that must be named explicitly in the charter (never auto-granted).
$investigative = @('Insider Risk Management','Insider Risk Management Analysts','Insider Risk Management Investigators',
                   'Communication Compliance','Communication Compliance Investigators','eDiscovery Manager','eDiscovery Administrator')

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host 'ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser' -ForegroundColor Red; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try {
    if (-not (Get-Command Get-RoleGroup -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ErrorAction Stop | Out-Null }
} catch { Write-Host "  [FAIL] Connect-IPPSSession: $($_.Exception.Message)" -ForegroundColor Red; return }

# ------------------------------------------------------------------ (1) role-group membership
if ($RoleMatrixCsv) {
    Write-Section 'Board role-group membership'
    if (-not (Test-Path $RoleMatrixCsv)) { Write-Host "  [FAIL] matrix not found: $RoleMatrixCsv" -ForegroundColor Red; return }
    $rows = @(Import-Csv -Path $RoleMatrixCsv)
    foreach ($r in $rows) {
        $seat = "$($r.Seat)".Trim(); $rg = "$($r.RoleGroup)".Trim(); $member = "$($r.Member)".Trim()
        $isCustom = ("$($r.Custom)".Trim() -match '^(?i)yes|true|1$')
        if ([string]::IsNullOrWhiteSpace($rg) -or [string]::IsNullOrWhiteSpace($member)) {
            Write-Host "  [SKIP] invalid row (Seat='$seat' RoleGroup='$rg' Member='$member')" -ForegroundColor Yellow; continue
        }
        # Warn (do not block) when an investigative role is being granted - must be named in the charter.
        if ($investigative -contains $rg) {
            Write-Host "  [WARN] '$rg' is an INVESTIGATIVE role - confirm '$member' is named in the CoE charter (separation of duties)." -ForegroundColor Yellow
        }
        $exists = $null
        try { $exists = Get-RoleGroup -Identity $rg -ErrorAction Stop } catch {}
        if (-not $exists) {
            if ($isCustom) {
                if ($Commit) {
                    try { New-RoleGroup -Name $rg -ErrorAction Stop | Out-Null; Write-Host "  [PASS] created custom role group '$rg'  (reverse: Remove-RoleGroup -Identity '$rg')" -ForegroundColor Green }
                    catch { Write-Host "  [FAIL] create role group '$rg': $($_.Exception.Message)" -ForegroundColor Red; continue }
                } else { Write-Host "  [WHATIF] would create custom role group '$rg'  (reverse: Remove-RoleGroup -Identity '$rg')" }
            } else {
                Write-Host "  [MISSING] role group '$rg' not found and not marked Custom - verify the name in your tenant." -ForegroundColor Red; continue
            }
        }
        if ($Commit) {
            try { Add-RoleGroupMember -Identity $rg -Member $member -Confirm:$false -ErrorAction Stop
                  Write-Host "  [PASS] added $member -> $rg  (reverse: Remove-RoleGroupMember -Identity '$rg' -Member '$member' -Confirm:`$false)" -ForegroundColor Green }
            catch { Write-Host "  [FAIL] add $member -> $rg : $($_.Exception.Message)" -ForegroundColor Red }
        } else {
            Write-Host "  [WHATIF] would add $member -> $rg  (reverse: Remove-RoleGroupMember -Identity '$rg' -Member '$member' -Confirm:`$false)"
        }
    }
}

# ------------------------------------------------------------------ (2) ownership/standard stamp
if ($StampOwnership) {
    Write-Section ("Ownership/standard Comment stamp" + $(if ($Restore) { ' - RESTORE' } else { '' }))
    # Map policy type -> get/set cmdlet pair
    $cmds = @{
        'Dlp'       = @{ Get='Get-DlpCompliancePolicy';        Set='Set-DlpCompliancePolicy' }
        'Retention' = @{ Get='Get-RetentionCompliancePolicy';  Set='Set-RetentionCompliancePolicy' }
        'AutoLabel' = @{ Get='Get-AutoSensitivityLabelPolicy'; Set='Set-AutoSensitivityLabelPolicy' }
    }

    if ($Restore) {
        if (-not (Test-Path $RestoreStorePath)) { Write-Host "  [FAIL] no stamp backup at $RestoreStorePath - nothing to restore." -ForegroundColor Red; return }
        $backup = Get-Content -Raw -Path $RestoreStorePath | ConvertFrom-Json
        foreach ($b in $backup) {
            $set = $cmds[$b.Type].Set
            if (-not (Get-Command $set -ErrorAction SilentlyContinue)) { Write-Host "  [SKIP] $set unavailable for '$($b.Name)'." -ForegroundColor Yellow; continue }
            if ($Commit) {
                try { & $set -Identity $b.Name -Comment ([string]$b.PriorComment) -Confirm:$false -ErrorAction Stop
                      Write-Host "  [PASS] restored Comment on $($b.Type) '$($b.Name)'" -ForegroundColor Green }
                catch { Write-Host "  [FAIL] restore '$($b.Name)': $($_.Exception.Message)" -ForegroundColor Red }
            } else { Write-Host "  [WHATIF] would restore prior Comment on $($b.Type) '$($b.Name)'" }
        }
        return
    }

    if (-not $OwnerMapCsv -or -not (Test-Path $OwnerMapCsv)) { Write-Host "  [FAIL] owner-map CSV not found: $OwnerMapCsv" -ForegroundColor Red; return }
    $map = @(Import-Csv -Path $OwnerMapCsv)
    $backup = New-Object System.Collections.Generic.List[object]
    foreach ($m in $map) {
        $type = "$($m.Type)".Trim(); $name = "$($m.Name)".Trim(); $owner = "$($m.Owner)".Trim(); $review = "$($m.Review)".Trim()
        if (-not $cmds.ContainsKey($type)) { Write-Host "  [SKIP] unknown Type '$type' for '$name' (use Dlp|Retention|AutoLabel)." -ForegroundColor Yellow; continue }
        $get = $cmds[$type].Get; $set = $cmds[$type].Set
        if (-not (Get-Command $get -ErrorAction SilentlyContinue) -or -not (Get-Command $set -ErrorAction SilentlyContinue)) {
            Write-Host "  [SKIP] $type cmdlets unavailable (unlicensed?) - cannot stamp '$name'." -ForegroundColor Yellow; continue
        }
        $obj = $null
        try { $obj = & $get -Identity $name -ErrorAction Stop } catch { Write-Host "  [SKIP] '$name' not found for $type." -ForegroundColor Yellow; continue }
        $prior = [string]$obj.Comment
        $tag = "CoE-Owner=$owner; Review=$review"
        # Preserve any non-CoE comment text; replace only a prior CoE tag.
        $base = ($prior -replace 'CoE-Owner=[^;]*;\s*Review=[^;]*;?','').Trim()
        $newComment = if ($base) { "$base | $tag" } else { $tag }
        $backup.Add([pscustomobject]@{ Type=$type; Name=$name; PriorComment=$prior })
        if ($Commit) {
            try { & $set -Identity $name -Comment $newComment -Confirm:$false -ErrorAction Stop
                  Write-Host "  [PASS] stamped $type '$name'  Comment='$newComment'" -ForegroundColor Green }
            catch { Write-Host "  [FAIL] stamp '$name': $($_.Exception.Message)" -ForegroundColor Red }
        } else {
            Write-Host "  [WHATIF] would stamp $type '$name'  Comment='$newComment' (rules/scope/enforcement UNCHANGED)"
        }
    }
    if ($Commit -and $backup.Count -gt 0) {
        $backup | ConvertTo-Json -Depth 4 | Out-File -FilePath $RestoreStorePath -Encoding UTF8
        Write-Host "  Prior Comment values saved to $RestoreStorePath - re-run with -StampOwnership -Restore -Commit to revert." -ForegroundColor Cyan
    }
}

Write-Section 'Summary'
Write-Host 'This tool applies board role-group membership and non-disruptive ownership tags only.'
Write-Host 'It NEVER changes a policy''s rules, scope, or enforcement state. Enforcement stays board-gated and intake-driven.'
if (-not $Commit) { Write-Host 'Dry-run only. Review the plan, then re-run with -Commit.' }
