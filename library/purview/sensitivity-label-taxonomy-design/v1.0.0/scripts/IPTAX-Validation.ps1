<#
.SYNOPSIS
    IPTAX-Validation.ps1 — read-only conformance check: is the built taxonomy structured and protected as designed?
.DESCRIPTION
    Validates the built sensitivity-label taxonomy against the intended design: order (least -> most),
    parent/sublabel structure (parents group only, no protection), per-label protection/marking, and —
    with -Full — that the pilot label policy is scoped to the intended group. Read-only — makes no
    changes. Run after IPTAX-TaxonomyConfig.ps1 and before broad publish.
.EXAMPLE
    .\IPTAX-Validation.ps1
    Checks structure, order, and per-label protection/marking; prints PASS/FAIL per check.
.EXAMPLE
    .\IPTAX-Validation.ps1 -Full -PolicyName "SL Policy - Pilot - Ring1"
    Also validates that the named label policy is published and scoped.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin (read).
    Expected results: PASS = every check green (structure/order/protection match design; policy scoped).
    FAIL = a parent applies protection, order is wrong, a sublabel is missing protection, or the policy
    is unscoped/absent — each printed as FAIL with the offending label/policy.
#>
[CmdletBinding()]
param(
    [switch]$Full,
    [string]$PolicyName = 'SL Policy - Pilot - Ring1'
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false }

# Expected design (keep in sync with IPTAX-TaxonomyConfig.ps1).
$expectedParents   = @('SL-Confidential','SL-HighlyConf')
$expectedMarkOnly  = @('SL-Public','SL-Internal')
$expectedEncrypted = @('SL-Conf-AllEmp','SL-Conf-Trusted','SL-HighlyConf-AllEmp','SL-HighlyConf-Specified')
$expectedOrder     = @('SL-Public','SL-Internal','SL-Confidential','SL-Conf-AllEmp','SL-Conf-Trusted','SL-HighlyConf','SL-HighlyConf-AllEmp','SL-HighlyConf-Specified')

$fail = 0
function Check([string]$name, [bool]$ok, [string]$detail) {
    if ($ok) { Write-Host ("  PASS  {0}" -f $name) -ForegroundColor Green }
    else     { Write-Host ("  FAIL  {0} — {1}" -f $name, $detail) -ForegroundColor Red; $script:fail++ }
}

$labels = Get-Label -ErrorAction SilentlyContinue
$byName = @{}; foreach ($l in $labels) { $byName[$l.Name] = $l }

Write-Host '=== IPTAX design-conformance validation (read-only) ===' -ForegroundColor Cyan

# 1. All expected labels exist
Write-Host "`n--- Presence ---" -ForegroundColor Cyan
foreach ($n in $expectedOrder) {
    Check "exists: $n" ([bool]$byName[$n]) 'label not found — build it with IPTAX-TaxonomyConfig.ps1'
}

# 2. Parents group only (no encryption, no marking)
Write-Host "`n--- Parents group only ---" -ForegroundColor Cyan
foreach ($n in $expectedParents) {
    $l = $byName[$n]; if (-not $l) { continue }
    $protected = [bool]$l.EncryptionEnabled -or [bool]($l.ApplyContentMarkingFooterEnabled -or $l.ApplyContentMarkingHeaderEnabled -or $l.ApplyWaterMarkingEnabled)
    Check "parent no-protection: $n" (-not $protected) 'a parent must group only — no encryption/marking'
}

# 3. Mark-only tiers mark, do not encrypt
Write-Host "`n--- Mark-only tiers ---" -ForegroundColor Cyan
foreach ($n in $expectedMarkOnly) {
    $l = $byName[$n]; if (-not $l) { continue }
    Check "mark-only: $n" ((-not $l.EncryptionEnabled) -and [bool]$l.ApplyContentMarkingFooterEnabled) 'expected footer marking and NO encryption'
}

# 4. Protected sublabels encrypt
Write-Host "`n--- Protected sublabels ---" -ForegroundColor Cyan
foreach ($n in $expectedEncrypted) {
    $l = $byName[$n]; if (-not $l) { continue }
    $hasRights = [bool]$l.EncryptionEnabled -and [bool]$l.EncryptionRightsDefinitions
    Check "encrypts+rights: $n" $hasRights 'expected EncryptionEnabled with a rights definition (by group)'
    Check "has parent: $n" ([bool]$l.ParentId) 'sublabel should link to a parent'
}

# 5. Order (least -> most) — expected names should appear in ascending Priority order
Write-Host "`n--- Order ---" -ForegroundColor Cyan
$present = $expectedOrder | Where-Object { $byName[$_] }
$actualOrder = ($labels | Where-Object { $present -contains $_.Name } | Sort-Object Priority).Name
$orderOk = -not (Compare-Object $present $actualOrder -SyncWindow 0)
Check 'ascending sensitivity order' $orderOk ("expected: {0} | actual: {1}" -f ($present -join ','), ($actualOrder -join ','))

# 6. Full: policy scoped
if ($Full) {
    Write-Host "`n--- Label policy scope ---" -ForegroundColor Cyan
    $pol = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    Check "policy exists: $PolicyName" ([bool]$pol) 'label policy not found — publish it (Implementation Step 5)'
    if ($pol) {
        $scoped = [bool]($pol.ModernGroupLocation) -or [bool]($pol.ExchangeLocation)
        Check "policy scoped: $PolicyName" $scoped 'policy has no publish location — add a pilot/broad scope'
    }
}

Write-Host ("`n=== Validation complete: {0} ===" -f $(if($fail -eq 0){'ALL PASS'}else{"$fail FAIL"})) -ForegroundColor $(if($fail -eq 0){'Green'}else{'Red'})
if ($fail -gt 0) { exit 1 }
