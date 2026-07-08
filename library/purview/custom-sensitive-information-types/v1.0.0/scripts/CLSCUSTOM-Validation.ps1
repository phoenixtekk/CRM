<#
.SYNOPSIS
    CLSCUSTOM-Validation.ps1 — read-only precision validation of a custom SIT against positive/negative samples.
.DESCRIPTION
    PURPOSE
        Runs Test-DataClassification for a custom sensitive information type against curated POSITIVE
        samples (should match) and NEGATIVE / look-alike samples (must not match), compares each result
        to its expected outcome, and reports true positives, FALSE positives, FALSE negatives, and the
        confidence each sample returned. This is the precision gate: it must pass before the SIT is
        referenced by any consuming policy. Read-only — it only TESTS text, it changes nothing.
    HOW TO RUN
        # Samples CSV with columns: Text,Expected  (Expected = Match | NoMatch)
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Validation.ps1 `
            -SitName 'Custom SIT - Employee ID - Pilot' -SamplesCsv .\CustomSIT-Samples.csv
        powershell -ExecutionPolicy Bypass -File .\CLSCUSTOM-Validation.ps1 `
            -SitName 'Custom SIT - Employee ID - Pilot' -SamplesCsv .\CustomSIT-Samples.csv -OutCsv .\Validation-Report.csv
        Requires ExchangeOnlineManagement; connects with Connect-IPPSSession. Handle real sample data
        per your data-handling policy.
    EXPECTED RESULTS
        The "Custom SIT Validation - Report": per-sample match/no-match + confidence, and totals —
        TP / FP / FN. PASS when positives match (at the intended confidence) and negatives do not.
        Any FP or FN means tune the SIT (Implementation Step 5) and re-validate.
.NOTES
    Purview — Custom Sensitive Information Types. Read-only (Test-DataClassification only). No
    credentials stored. Confidence thresholds: High 85 / Medium 75 / Low 65 — verify against your
    tenant's current behavior.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SitName,       # e.g. 'Custom SIT - Employee ID - Pilot'
    [Parameter(Mandatory)][string]$SamplesCsv,     # CSV: Text,Expected (Expected = Match | NoMatch)
    [int]$MinConfidence = 75,                       # confidence at/above which a positive counts as matched
    [string]$OutCsv
)

if (-not (Test-Path -LiteralPath $SamplesCsv)) { Write-Error "Samples CSV not found: $SamplesCsv"; return }
$samples = @(Import-Csv -LiteralPath $SamplesCsv)
if ($samples.Count -eq 0) { Write-Error 'Samples CSV is empty.'; return }
if (-not ($samples[0].PSObject.Properties.Name -contains 'Text') -or
    -not ($samples[0].PSObject.Properties.Name -contains 'Expected')) {
    Write-Error "Samples CSV must have columns: Text,Expected (Expected = Match | NoMatch)."; return
}

# --- Connect ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null }
catch { Write-Error "Connect-IPPSSession failed: $($_.Exception.Message)."; return }

Write-Host ("=== Custom SIT Validation - Report : {0} ===" -f $SitName) -ForegroundColor Cyan
Write-Host ("Match threshold  : confidence >= {0}" -f $MinConfidence)
Write-Host ("Samples          : {0}" -f $samples.Count)
Write-Host ''

$results = @()
$tp = 0; $fp = 0; $fn = 0; $tn = 0
foreach ($row in $samples) {
    $expected = "$($row.Expected)".Trim()
    $matched  = $false
    $conf     = 0
    try {
        $r = Test-DataClassification -TestTextItem $row.Text -ClassificationNames $SitName -ErrorAction Stop
        # Test-DataClassification returns classification results with a Confidence and Count per SIT.
        $hit = $null
        if ($r) { $hit = @($r.ClassificationResults | Where-Object { $_.Confidence -ge 0 } | Sort-Object Confidence -Descending)[0] }
        if ($hit) { $conf = [int]$hit.Confidence; $matched = ($hit.Count -gt 0 -and $conf -ge $MinConfidence) }
    } catch {
        Write-Host ("  [error testing sample] {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    }

    $outcome = if ($expected -eq 'Match'   -and $matched)      { $tp++; 'TP (correct match)' }
               elseif ($expected -eq 'NoMatch' -and -not $matched) { $tn++; 'TN (correct no-match)' }
               elseif ($expected -eq 'NoMatch' -and $matched)      { $fp++; 'FP (FALSE POSITIVE)' }
               else                                                { $fn++; 'FN (FALSE NEGATIVE)' }

    $color = if ($outcome -like 'FP*' -or $outcome -like 'FN*') { 'Red' } else { 'Green' }
    $preview = if ($row.Text.Length -gt 50) { $row.Text.Substring(0,50) + '...' } else { $row.Text }
    Write-Host ("  [{0,-22}] conf={1,3}  exp={2,-7}  '{3}'" -f $outcome, $conf, $expected, $preview) -ForegroundColor $color

    $results += [pscustomobject]@{
        Text = $row.Text; Expected = $expected; Matched = $matched; Confidence = $conf; Outcome = $outcome
    }
}

Write-Host ''
Write-Host '=== Totals ===' -ForegroundColor Cyan
Write-Host ("  True positives  (TP): {0}" -f $tp) -ForegroundColor Green
Write-Host ("  True negatives  (TN): {0}" -f $tn) -ForegroundColor Green
Write-Host ("  FALSE positives (FP): {0}" -f $fp) -ForegroundColor ($(if ($fp -gt 0) {'Red'} else {'Green'}))
Write-Host ("  FALSE negatives (FN): {0}" -f $fn) -ForegroundColor ($(if ($fn -gt 0) {'Red'} else {'Green'}))
Write-Host ''
if ($fp -eq 0 -and $fn -eq 0) {
    Write-Host '  PASS — positives match and negatives do not. Proceed to pilot in a consuming policy (simulation).' -ForegroundColor Green
} else {
    Write-Host '  FAIL — tune the SIT (regex / supporting evidence / proximity / confidence) and re-validate (Implementation Step 5).' -ForegroundColor Red
    if ($fp -gt 0) { Write-Host '    FP > 0: the SIT is too broad — tighten it.' -ForegroundColor Red }
    if ($fn -gt 0) { Write-Host '    FN > 0: the SIT is too tight — loosen it.' -ForegroundColor Red }
}

if ($OutCsv) {
    try { $results | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
          Write-Host ("`nValidation report written to {0}" -f $OutCsv) -ForegroundColor Green }
    catch { Write-Warning "Could not write CSV: $($_.Exception.Message)" }
}
