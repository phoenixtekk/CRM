<#
.SYNOPSIS
    IPMANREC-Validation.ps1 — read-only check that a label policy's effective settings (mandatory / default / downgrade / Outlook) and a label's recommend mode match the signed-off design.
.DESCRIPTION
    Reads a sensitivity label policy's resolved advanced settings and compares them against the intended
    mandatory-vs-recommended design (mandatory on, default label set, downgrade justification on, Outlook
    relaxation as intended), and optionally checks a label's Office-app auto-labeling mode is RECOMMEND
    (not Automatic). Read-only - makes no changes. Run it on the pilot policy before expanding, and on
    the broad policy after.
.EXAMPLE
    .\IPMANREC-Validation.ps1 -PolicyName "LabelPolicy - Pilot - Ring1"
    Validates the pilot policy's effective settings against the expected design.
.EXAMPLE
    .\IPMANREC-Validation.ps1 -PolicyName "LabelPolicy - Broad - AllUsers" -ExpectOutlookRelaxed -RecommendLabel "Confidential\All Employees"
    Also expects Outlook mandatory to be relaxed and checks the recommend label's mode.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession).
    Role: Information Protection Admin (read).
    Expected results: PASS = every expected setting resolves as designed (all green). FAIL = a setting is
    missing/wrong (red) - re-run IPMANREC-PolicyConfig.ps1 for that lever and re-validate.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [string]$ExpectDefaultLabel = 'General',
    [switch]$ExpectOutlookRelaxed,
    [string]$RecommendLabel
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

function Get-AdvSetting($policy, [string]$key) {
    try {
        $s = $policy.Settings | Where-Object { $_ -match [regex]::Escape($key) }
        if ($s) { return ($s -join '; ') }
    } catch { }
    return ''
}
function Check([string]$name, [bool]$ok, [string]$detail) {
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    $col = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} {2}" -f $tag, $name, $detail) -ForegroundColor $col
    return $ok
}

Write-Host "=== IPMANREC validation: $PolicyName (read-only) ===" -ForegroundColor Cyan
$p = Get-LabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $p) { Write-Host "  [FAIL] Policy '$PolicyName' not found." -ForegroundColor Red; return }

$results = @()

$mand = Get-AdvSetting $p 'Mandatory'
$results += Check 'Mandatory labeling' ($mand -match 'true') "(setting: '$mand')"

$def = Get-AdvSetting $p 'DefaultLabelId'
$results += Check 'Default label set' ([bool]$def) "(setting: '$def'; expected label: $ExpectDefaultLabel)"

$dg = Get-AdvSetting $p 'Justification'
$results += Check 'Downgrade justification' ([bool]$dg) "(setting: '$dg') - verify the exact key in your tenant"

$outlook = Get-AdvSetting $p 'DisableMandatoryInOutlook'
if ($ExpectOutlookRelaxed) {
    $results += Check 'Outlook relaxed (send not blocked)' ($outlook -match 'true') "(setting: '$outlook')"
} else {
    $results += Check 'Outlook strict (matches design)' (-not ($outlook -match 'true')) "(setting: '$outlook')"
}

if ($RecommendLabel) {
    Write-Host "`n--- Recommend-label mode: $RecommendLabel ---" -ForegroundColor Cyan
    $l = Get-Label -Identity $RecommendLabel -ErrorAction SilentlyContinue
    if ($l) {
        $isRec = ($l.ApplyAutoTaggingRecommendation -eq $true) -or ($l.Settings -match 'recommend')
        $isAuto = ($l.ApplyAutoTagging -eq $true) -or ($l.Settings -match 'autotagging')
        $results += Check 'Label is RECOMMEND (not Automatic)' ($isRec -and -not $isAuto) "(recommend=$isRec, automatic=$isAuto)"
    } else {
        $results += Check 'Recommend label exists' $false "(label '$RecommendLabel' not found)"
    }
}

$passCount = ($results | Where-Object { $_ }).Count
Write-Host ("`n=== {0}/{1} checks passed ===" -f $passCount, $results.Count) -ForegroundColor $(if ($passCount -eq $results.Count) { 'Green' } else { 'Yellow' })
if ($passCount -ne $results.Count) { Write-Host 'Resolve FAIL items with IPMANREC-PolicyConfig.ps1 before expanding.' -ForegroundColor Yellow }
