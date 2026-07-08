<#
.SYNOPSIS
    OPSHEALTH-Report.ps1 — roll the scored checks into a health scorecard + export the Remediation Register (read-only).
.DESCRIPTION
    PURPOSE
        Produces the leadership rollup for the health check: per-domain (Policy P / Coverage C / Roles R)
        Healthy / At Risk / Gap counts and an overall HEALTH RATING, and exports the Remediation Register
        to CSV as the baseline for the next run. It reads the scored register (a CSV you built from the
        Discovery + ScopeCheck findings). Read-only — it summarizes and exports, it changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-Report.ps1 -RegisterCsv .\opshealth-register.csv
        powershell -ExecutionPolicy Bypass -File .\OPSHEALTH-Report.ps1 -RegisterCsv .\in.csv -OutCsv .\opshealth-scorecard.csv
        The register CSV columns: Finding, Domain (P/C/R), Rating (Healthy/At Risk/Gap), Severity, Owner,
        'Owning capability', 'Recommended action'.
    EXPECTED RESULTS
        A per-domain Healthy/At Risk/Gap table, the overall health rating, and (with -OutCsv) the register
        written out for circulation. PASS = the rollup reconciles with the portal (the portal is
        authoritative) and every non-Healthy row has an owner and severity.
.NOTES
    White-label. Read-only. No credentials in code. The portal is authoritative — reconcile before issuing.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string] $RegisterCsv,
    [string] $OutCsv
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

if (-not (Test-Path $RegisterCsv)) { Write-Error ("Register CSV not found: {0}" -f $RegisterCsv); return }
$rows = @(Import-Csv -Path $RegisterCsv)
Write-Host ("`n=== Microsoft Purview Health Check — scorecard ({0} rows) ===" -f $rows.Count) -ForegroundColor Cyan

# --- Per-domain Healthy / At Risk / Gap counts -----------------------------------------------------
Write-Section 'Per-domain rating counts'
$domains = @{ 'P' = 'Policy health'; 'C' = 'Coverage'; 'R' = 'Roles' }
$table = foreach ($d in $domains.Keys) {
    $dr = @($rows | Where-Object { $_.Domain -eq $d })
    [pscustomobject]@{
        Domain   = ("{0} ({1})" -f $d, $domains[$d])
        Healthy  = @($dr | Where-Object { $_.Rating -eq 'Healthy' }).Count
        AtRisk   = @($dr | Where-Object { $_.Rating -eq 'At Risk' }).Count
        Gap      = @($dr | Where-Object { $_.Rating -eq 'Gap' }).Count
    }
}
$table | Format-Table -AutoSize

# --- Overall health rating -------------------------------------------------------------------------
Write-Section 'Overall health rating'
$gapCount    = @($rows | Where-Object { $_.Rating -eq 'Gap' }).Count
$atRiskCount = @($rows | Where-Object { $_.Rating -eq 'At Risk' }).Count
$highGaps    = @($rows | Where-Object { $_.Rating -eq 'Gap' -and $_.Severity -eq 'High' }).Count
$overall = if ($gapCount -eq 0 -and $atRiskCount -eq 0) { 'HEALTHY' }
           elseif ($highGaps -gt 0 -or $gapCount -gt 0) { 'GAP' }
           else { 'AT RISK' }
$color = switch ($overall) { 'HEALTHY' {'Green'} 'AT RISK' {'Yellow'} default {'Red'} }
Write-Host ("  Overall: {0}   (High-severity Gaps: {1}, Gaps: {2}, At Risk: {3})" -f $overall, $highGaps, $gapCount, $atRiskCount) -ForegroundColor $color

# --- Completeness check: owner + severity on every non-Healthy row ---------------------------------
Write-Section 'Register completeness (Gate 8)'
$missing = @($rows | Where-Object { $_.Rating -ne 'Healthy' -and ([string]::IsNullOrWhiteSpace($_.Owner) -or [string]::IsNullOrWhiteSpace($_.Severity)) })
if ($missing.Count -eq 0) { Write-Host '  PASS — every non-Healthy finding has an owner and a severity.' -ForegroundColor Green }
else { Write-Host ("  FAIL — {0} non-Healthy finding(s) missing owner/severity:" -f $missing.Count) -ForegroundColor Red; $missing | Select-Object Finding, Domain, Rating | Format-Table -AutoSize }

# --- Export ----------------------------------------------------------------------------------------
if ($OutCsv) {
    $rows | Sort-Object @{e={ switch ($_.Severity) { 'High'{0} 'Medium'{1} default{2} } }} | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("`nRemediation Register exported to {0} (baseline for the next run)." -f $OutCsv) -ForegroundColor Green
}
Write-Host 'Reconcile the rollup with the portal (authoritative) before circulating. Determination items remain pending their governance owner.' -ForegroundColor DarkYellow
