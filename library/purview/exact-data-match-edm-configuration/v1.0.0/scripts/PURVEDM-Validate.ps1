<#
.SYNOPSIS
    PURVEDM-Validate.ps1 — Validate that an EDM SIT matches (and correctly ignores) sample values (READ-ONLY).
.DESCRIPTION
    PURPOSE
        Runs sample text through Test-DataClassification against a named EDM sensitive information type
        (SIT) and reports whether it matched, at what confidence. Use it to prove the two headline EDM
        gates: an in-data value (with a supporting element) MATCHES, and a not-in-data / unsupported
        value does NOT. Read-only: it evaluates text you pass in and changes nothing.
        IMPORTANT: pass only values you are AUTHORIZED to use for testing (a small sanctioned test set),
        never real production records pasted ad hoc.
    HOW TO RUN
        # Test an in-data positive sample (should match):
        powershell -File .\PURVEDM-Validate.ps1 -SitName 'EDM - Customer Account Match' `
            -Text 'Account 10058822 for Smith, contact smith@contoso.com'
        # Test a not-in-data negative sample (should NOT match):
        powershell -File .\PURVEDM-Validate.ps1 -SitName 'EDM - Customer Account Match' `
            -Text 'Account 99999999 for Nobody' -ExpectMatch:$false
        # Test several samples from a file (one per line):
        powershell -File .\PURVEDM-Validate.ps1 -SitName 'EDM - Customer Account Match' -TextFile .\samples.txt
        Requires Security & Compliance PowerShell (Connect-IPPSSession). Allow EDM indexing time after upload.
    EXPECTED RESULTS
        Prints MATCH/NO-MATCH + confidence per sample and PASS/FAIL against -ExpectMatch (default: expect
        a match). A not-in-data value returning NO-MATCH is the core EDM validation (Gate B).
.NOTES
    Purview — Exact Data Match. Read-only. Pass only sanctioned test values. No secrets in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SitName,
    [string]$Text,
    [string]$TextFile,
    [bool]$ExpectMatch = $true,
    [string]$UserPrincipalName
)

if (-not $Text -and -not $TextFile) { Write-Host 'Provide -Text "<sample>" or -TextFile <path>.' -ForegroundColor Red; return }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Test-DataClassification -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

# Confirm the SIT exists
$sit = $null
try { $sit = Get-DlpSensitiveInformationType -Identity $SitName -ErrorAction Stop } catch {}
if (-not $sit) {
    Write-Host ("SIT '{0}' not found. Check the exact name with Get-DlpSensitiveInformationType." -f $SitName) -ForegroundColor Red
    return
}
Write-Host ("=== Validating SIT '{0}' ===" -f $SitName) -ForegroundColor Cyan
Write-Host ("Expectation: samples SHOULD {0}match." -f ($(if ($ExpectMatch) { '' } else { 'NOT ' })))
Write-Host 'NOTE: allow EDM indexing time after upload before trusting a NO-MATCH.' -ForegroundColor DarkGray

$samples = @()
if ($Text)     { $samples += $Text }
if ($TextFile) {
    if (-not (Test-Path $TextFile)) { Write-Host ("TextFile not found: {0}" -f $TextFile) -ForegroundColor Red; return }
    $samples += @(Get-Content -Path $TextFile | Where-Object { $_.Trim() -ne '' })
}

$pass = 0; $fail = 0; $i = 0
foreach ($s in $samples) {
    $i++
    $matched = $false; $conf = $null
    try {
        $res = Test-DataClassification -TextToClassify $s -ClassificationNames $SitName -ErrorAction Stop
        $hit = $res.ClassificationResults | Where-Object { $_.Name -eq $SitName -or $_.ClassificationName -eq $SitName }
        if ($hit) {
            $countVal = ($hit | Select-Object -First 1).Count
            if ($null -ne $countVal -and $countVal -gt 0) { $matched = $true }
            $conf = ($hit | Select-Object -First 1).Confidence
        }
    } catch {
        Write-Host ("  [{0}] Test-DataClassification error: {1}" -f $i, $_.Exception.Message) -ForegroundColor Yellow
    }
    $verdict = if ($matched) { 'MATCH' } else { 'NO-MATCH' }
    $ok = ($matched -eq $ExpectMatch)
    if ($ok) { $pass++ } else { $fail++ }
    $color = if ($ok) { 'Green' } else { 'Red' }
    $snippet = if ($s.Length -gt 60) { $s.Substring(0,60) + '...' } else { $s }
    Write-Host ("  [{0}] {1}{2} -> {3}  (\"{4}\")" -f $i, $verdict, ($(if ($conf) { " conf=$conf" } else { '' })), ($(if ($ok) { 'PASS' } else { 'FAIL' })), $snippet) -ForegroundColor $color
}

Write-Host ("`nResult: {0} PASS, {1} FAIL (of {2} sample(s))." -f $pass, $fail, $samples.Count) -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
if ($fail -gt 0) {
    Write-Host 'If in-data values do NOT match: check indexing time, the source header row, and the primary-element choice (see 06-troubleshooting.md).' -ForegroundColor Yellow
    Write-Host 'If not-in-data values DO match: the SIT may rely only on the primary element with no supporting-element requirement — tighten the rule.' -ForegroundColor Yellow
}
