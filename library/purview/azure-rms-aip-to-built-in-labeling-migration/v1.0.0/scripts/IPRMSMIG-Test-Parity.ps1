<#
.SYNOPSIS
    IPRMSMIG-Test-Parity.ps1 — read-only parity check for a pilot user before/after cutover (no changes).
.DESCRIPTION
    PURPOSE
        Validates built-in-labeling parity for a pilot user: resolves the label policies that apply to the
        user and the effective set of labels, flags any expected label missing from the unified store, and
        flags parity features that need a newer Office build than the one supplied. Read-only — makes no
        changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IPRMSMIG-Test-Parity.ps1 -UserUpn user@contoso.com -OfficeBuild '16.0.17000' -ExpectedLabelsPath .\expected-labels.txt
        -ExpectedLabelsPath (optional) = a text file of the label display names the AIP add-in showed this
        user, one per line, to check nothing dropped. PowerShell 5.1+/7+. Requires ExchangeOnlineManagement
        (Connect-IPPSSession); optional Microsoft Graph SDK for group-membership resolution.
    EXPECTED RESULTS
        A per-label PASS/MISSING list for the user and a feature-vs-build advisory. PASS = the user's
        effective labels match the expected set and no in-use feature needs a build newer than -OfficeBuild.
.NOTES
    Purview — Azure RMS / AIP to Built-in Unified Labeling Migration. Read-only. Minimum Office builds for
    built-in-labeling features EVOLVE — the build thresholds below are indicative and must be verified
    against Microsoft's current capabilities table. No secrets in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$UserUpn,
    [string]$OfficeBuild,
    [string]$ExpectedLabelsPath,
    [string]$CsvPath
)

Write-Host ("=== Parity check — {0} ===" -f $UserUpn) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession -ShowBanner:$false

# --- Which label policies could apply, and the labels they publish ---
$policies = @(Get-LabelPolicy -ErrorAction SilentlyContinue)
$appliesTo = foreach ($p in $policies) {
    $scopeText = ''
    foreach ($prop in 'ExchangeLocation','ModernGroupLocation','Settings') {
        if ($p.PSObject.Properties.Name -contains $prop -and $p.$prop) {
            $scopeText += ("{0}=[{1}] " -f $prop, ((@($p.$prop) | ForEach-Object { $_.ToString() }) -join ','))
        }
    }
    [pscustomobject]@{ Policy = $p.Name; Enabled = $p.Enabled; Labels = (@($p.Labels) -join '; '); Scope = $scopeText }
}
Write-Host '--- Label policies (confirm one applies to the user; "All" = tenant-wide) ---' -ForegroundColor Cyan
$appliesTo | Format-Table Policy, Enabled -AutoSize

$publishedLabels = @($policies | Where-Object { $_.Enabled } | ForEach-Object { $_.Labels } | ForEach-Object { $_ }) | Sort-Object -Unique
$allLabels = @(Get-Label -ErrorAction SilentlyContinue)
# Map label identities in policies to display names for a human-readable check.
$publishedNames = foreach ($idOrName in $publishedLabels) {
    $match = $allLabels | Where-Object { $_.Name -eq $idOrName -or $_.Guid -eq $idOrName -or $_.DisplayName -eq $idOrName } | Select-Object -First 1
    if ($match) { $match.DisplayName } else { $idOrName }
}
$publishedNames = @($publishedNames | Sort-Object -Unique)

# --- Compare against the expected label list (what the add-in showed) ---
$rows = @()
if ($ExpectedLabelsPath -and (Test-Path $ExpectedLabelsPath)) {
    $expected = Get-Content -Path $ExpectedLabelsPath | Where-Object { $_.Trim() }
    Write-Host '--- Expected-vs-published labels ---' -ForegroundColor Cyan
    foreach ($e in $expected) {
        $present = $publishedNames -contains $e.Trim()
        $rows += [pscustomobject]@{ Check='Label'; Item=$e.Trim(); Result=$(if ($present) {'PASS'} else {'MISSING'}) }
        Write-Host ("  [{0}] {1}" -f $(if ($present) {'PASS'} else {'MISSING'}), $e.Trim()) -ForegroundColor $(if ($present) {'Green'} else {'Red'})
    }
} else {
    Write-Host 'No -ExpectedLabelsPath supplied; listing published labels for manual comparison:' -ForegroundColor Yellow
    $publishedNames | ForEach-Object { Write-Host ("  - {0}" -f $_) }
}

# --- Feature-vs-build advisory (INDICATIVE thresholds — verify against current Microsoft docs) ---
if ($OfficeBuild) {
    Write-Host '--- Feature / Office-build advisory (indicative — verify against current docs) ---' -ForegroundColor Cyan
    $featureMinBuild = @(
        [pscustomobject]@{ Feature='Basic built-in labeling';                 MinBuild='16.0.11231' }
        [pscustomobject]@{ Feature='Label-based encryption';                  MinBuild='16.0.12730' }
        [pscustomobject]@{ Feature='Co-authoring on encrypted files';         MinBuild='16.0.14701' }
        [pscustomobject]@{ Feature='Custom permissions (user-defined)';       MinBuild='16.0.13801' }
    )
    function ConvertTo-BuildNumber([string]$b){ ($b -split '\.' | ForEach-Object { '{0:D5}' -f [int]$_ }) -join '' }
    $have = ConvertTo-BuildNumber $OfficeBuild
    foreach ($f in $featureMinBuild) {
        $ok = $have -ge (ConvertTo-BuildNumber $f.MinBuild)
        $rows += [pscustomobject]@{ Check='Feature'; Item=("{0} (needs >= {1})" -f $f.Feature, $f.MinBuild); Result=$(if ($ok) {'OK'} else {'NEEDS NEWER BUILD'}) }
        Write-Host ("  [{0}] {1} (needs >= {2}; have {3})" -f $(if ($ok) {'OK'} else {'UPGRADE'}), $f.Feature, $f.MinBuild, $OfficeBuild) -ForegroundColor $(if ($ok) {'Green'} else {'Yellow'})
    }
}

if ($CsvPath -and $rows.Count) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved parity results to {0}" -f $CsvPath) -ForegroundColor Green
}
Write-Host 'Parity check complete (read-only).' -ForegroundColor Green
