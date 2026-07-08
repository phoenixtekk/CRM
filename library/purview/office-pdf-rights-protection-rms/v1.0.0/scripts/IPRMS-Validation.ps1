<#
.SYNOPSIS
    IPRMS-Validation.ps1 — read-only check that a label's effective encryption settings (enabled, protection type, rights, offline, expiry) match the signed-off design.
.DESCRIPTION
    Reads a sensitivity label's resolved encryption settings and compares them against the intended
    rights-protection design: encryption enabled, protection type (Template vs UserDefined), a rights
    definition present (and, if supplied, containing the expected identity), offline-access days, and
    content expiry. Read-only - makes no changes. Run it on each protection label before publishing and
    again after expansion.
.EXAMPLE
    .\IPRMS-Validation.ps1 -LabelName "Confidential\All Employees" -ExpectType Template
    Validates the label is Template-encrypted with a rights definition, offline, and expiry set.
.EXAMPLE
    .\IPRMS-Validation.ps1 -LabelName "Highly Confidential\Named Recipients" -ExpectType Template -ExpectIdentity "grp-rms-named-recipients@contoso.com"
    Also checks the rights definition grants the named group (and flags if it grants AuthenticatedUsers instead).
.EXAMPLE
    .\IPRMS-Validation.ps1 -LabelName "Confidential\Recipients Only" -ExpectType UserDefined
    Validates the label uses user-defined permissions (Do Not Forward / Encrypt-Only).
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession). Role: Information
    Protection Admin (read).
    Expected results: PASS = every expected setting resolves as designed (all green). FAIL = a setting is
    missing/wrong (red) - re-run IPRMS-LabelProtection.ps1 for that label and re-validate. A grant that
    resolves to AuthenticatedUsers where a NAMED group was expected is a FAIL (over-broad).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LabelName,
    [ValidateSet('Template','UserDefined')][string]$ExpectType = 'Template',
    [string]$ExpectIdentity
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    Connect-IPPSSession -ShowBanner:$false
}

function Check([string]$name, [bool]$ok, [string]$detail) {
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    $col = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} {2}" -f $tag, $name, $detail) -ForegroundColor $col
    return $ok
}

Write-Host "=== IPRMS validation: $LabelName (read-only) ===" -ForegroundColor Cyan
$l = Get-Label -Identity $LabelName -ErrorAction SilentlyContinue
if (-not $l) { Write-Host "  [FAIL] Label '$LabelName' not found." -ForegroundColor Red; return }

$results = @()

$results += Check 'Encryption enabled' ([bool]$l.EncryptionEnabled) "(EncryptionEnabled=$($l.EncryptionEnabled))"

$type = "$($l.EncryptionProtectionType)"
$results += Check "Protection type = $ExpectType" ($type -match $ExpectType) "(type='$type')"

$rights = "$($l.EncryptionRightsDefinitions)"
if ($ExpectType -eq 'Template') {
    $results += Check 'Rights definition present' ([bool]$rights) "(rights='$([Regex]::Match($rights,'^.{0,80}').Value)')"
    if ($ExpectIdentity) {
        $hasId = $rights -match [regex]::Escape($ExpectIdentity)
        $results += Check "Grants expected identity ($ExpectIdentity)" $hasId '(named-audience check)'
        if ($rights -match 'AuthenticatedUsers' -and $ExpectIdentity -notmatch 'AuthenticatedUsers') {
            $results += Check 'NOT over-broad (no AuthenticatedUsers)' $false '(grant includes AuthenticatedUsers but a NAMED group was expected - over-broad)'
        }
    }
    $offline = "$($l.EncryptionOfflineAccessDays)"
    $results += Check 'Offline-access days set' ([bool]$offline) "(offlineDays='$offline')"
    $expiry = "$($l.EncryptionContentExpiredOnDateInDaysOrNever)"
    $results += Check 'Content expiry set' ([bool]$expiry) "(expiry='$expiry')"
} else {
    $dnf = [bool]$l.EncryptionDoNotForward
    $prompt = [bool]$l.EncryptionPromptUser
    $results += Check 'User-defined (DNF or Encrypt-Only)' ($dnf -or $prompt) "(DoNotForward=$dnf, PromptUser=$prompt)"
}

$passCount = ($results | Where-Object { $_ }).Count
Write-Host ("`n=== {0}/{1} checks passed ===" -f $passCount, $results.Count) -ForegroundColor $(if ($passCount -eq $results.Count) { 'Green' } else { 'Yellow' })
if ($passCount -ne $results.Count) { Write-Host 'Resolve FAIL items with IPRMS-LabelProtection.ps1 before publishing/expanding.' -ForegroundColor Yellow }
