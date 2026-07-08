<#
.SYNOPSIS
    CLSSIT-Test.ps1 — read-only accuracy tester: runs corpus files through a built-in SIT and reports match/confidence per file.
.DESCRIPTION
    PURPOSE
        Scores a sensitive information type against a folder of clearly-fake corpus files (positive and
        negative / look-alike samples). For each file it reports whether the SIT matched and at what
        confidence, so you can prove positives are detected and look-alike negatives are rejected before
        you build any policy. Read-only — classifies text, changes nothing. Uses Test-DataClassification
        where present in the tenant; if the cmdlet is unavailable it prints the portal Test steps instead.
    HOW TO RUN
        powershell -File .\CLSSIT-Test.ps1 -SensitiveType 'Credit Card Number' -Path .\corpus\payment-card\ -CsvPath .\CLSSIT-TestResults.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession). Use ONLY fake/synthetic data.
    EXPECTED RESULTS
        A per-file table: FileName, Matched (True/False), Confidence, InstanceCount. PASS signal: files in
        a 'positives' path match at the target confidence; files in a 'negatives' path do not match.
.NOTES
    Purview — Sensitive Information Types Implementation. Read-only. Never place real sensitive data in the corpus.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SensitiveType,
    [Parameter(Mandatory)][string]$Path,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== SIT accuracy test: '{0}' (read-only) ===" -f $SensitiveType) -ForegroundColor Cyan

if (-not (Test-Path $Path)) { Write-Host ("Path not found: {0}" -f $Path) -ForegroundColor Red; return }
$files = Get-ChildItem -Path $Path -File -Recurse -Include *.txt,*.csv,*.log,*.md -ErrorAction SilentlyContinue
if (-not $files) { Write-Host 'No text corpus files (*.txt,*.csv,*.log,*.md) found under the path.' -ForegroundColor Yellow; return }

$hasTestCmd = [bool](Get-Command Test-DataClassification -ErrorAction SilentlyContinue)
if (-not $hasTestCmd) {
    Write-Host 'Test-DataClassification is not available in this tenant/session.' -ForegroundColor Yellow
    Write-Host 'Fallback — test each SIT in the portal:' -ForegroundColor Yellow
    Write-Host '  Purview portal -> Data classification -> Classifiers -> Sensitive info types -> [SIT] -> Test -> upload the corpus file.' -ForegroundColor Yellow
    Write-Host 'The portal reports match + confidence per file. Re-run this script if the cmdlet becomes available.' -ForegroundColor Yellow
    return
}

$results = foreach ($f in $files) {
    $text = Get-Content -Path $f.FullName -Raw -ErrorAction SilentlyContinue
    $matched = $false; $conf = ''; $count = 0
    try {
        # Test-DataClassification returns the classifications detected in the supplied text.
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        $r = Test-DataClassification -TestTextExtractionResults $bytes -ErrorAction Stop
        $hit = $r.ClassificationResults | Where-Object { $_.Name -eq $SensitiveType -or $_.ClassificationName -eq $SensitiveType }
        if ($hit) { $matched = $true; $conf = ($hit.Confidence | Select-Object -First 1); $count = ($hit.Count | Select-Object -First 1) }
    } catch {
        $conf = "ERR: $($_.Exception.Message)"
    }
    [pscustomobject]@{
        FileName      = $f.Name
        RelativePath  = $f.FullName.Substring($Path.TrimEnd('\','/').Length).TrimStart('\','/')
        Matched       = $matched
        Confidence    = $conf
        InstanceCount = $count
    }
}

$results | Sort-Object RelativePath | Format-Table FileName, Matched, Confidence, InstanceCount -AutoSize

$pos = @($results | Where-Object { $_.RelativePath -match 'positive' })
$neg = @($results | Where-Object { $_.RelativePath -match 'negative' })
if ($pos.Count) {
    $posHit = @($pos | Where-Object { $_.Matched }).Count
    Write-Host ("Positives matched: {0}/{1}" -f $posHit, $pos.Count) -ForegroundColor ($(if ($posHit -eq $pos.Count) {'Green'} else {'Yellow'}))
}
if ($neg.Count) {
    $negHit = @($neg | Where-Object { $_.Matched }).Count
    Write-Host ("Negatives that (wrongly) matched: {0}/{1}" -f $negHit, $neg.Count) -ForegroundColor ($(if ($negHit -eq 0) {'Green'} else {'Yellow'}))
}

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Results exported to {0}" -f $CsvPath) -ForegroundColor Green
}
Write-Host 'Done. Feed misses/false-hits into Phase 4 tuning (confidence, instance count, or a tuned SIT copy).' -ForegroundColor Cyan
