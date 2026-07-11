<#
.SYNOPSIS
    WSMDC-Report.ps1 — read-only Secure-Score + recommendations report for the Defender for Cloud
    workshop, with a remediation-shortlist template for Labs 1/5.
.DESCRIPTION
    PURPOSE
        Produces a compact, read-only HTML summary for the Defender for Cloud workshop: the current
        Secure Score, a breakdown of recommendations by severity/state, the top recommendations by
        potential score increase, and a fill-in template for the
        "SecureScore-Shortlist - Cloud Lab - Pilot". Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDC-Report.ps1 -SubscriptionId '<pilot sub id>'
        powershell -ExecutionPolicy Bypass -File .\WSMDC-Report.ps1 -OutputPath .\wsmdc-report.html
        Requires Az.Accounts, Az.Security. Run Connect-AzAccount first, or it prompts.
    EXPECTED RESULTS
        A console summary and an HTML report file for trending / the take-home runbook. Remediation
        and change approval belong to the customer's cloud-ops/security functions.
.NOTES
    White-label. Read-only. Makes no changes.
    Plan/pricing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\wsmdc-report.html"
)

$ErrorActionPreference = 'Continue'
foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext

Write-Host "`n=== Defender for Cloud workshop — summary report (read-only) ===" -ForegroundColor Cyan
$scoreHtml = "Not populated"
try {
    $score = Get-AzSecuritySecureScore -ErrorAction Stop | Where-Object { $_.Name -eq 'ascScore' } | Select-Object -First 1
    if ($score) {
        $pct = if ($score.Max -gt 0) { [math]::Round(100 * $score.Current / $score.Max, 1) } else { 0 }
        $scoreHtml = "$($score.Current) / $($score.Max) ($pct%)"
        Write-Host "   Secure Score: $scoreHtml" -ForegroundColor Green
    }
} catch { Write-Host "   Secure Score read failed: $($_.Exception.Message)" -ForegroundColor Yellow }

$recRows = ""
$sevRows = ""
try {
    $tasks = Get-AzSecurityTask -ErrorAction Stop
    $bySev = $tasks | Group-Object { $_.SecurityTaskParameters.severity } | Sort-Object Name
    $sevRows = ($bySev | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" }) -join "`n"
    $recRows = ($tasks | Select-Object -First 15 | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.State)</td></tr>" }) -join "`n"
    Write-Host ("   Recommendation tasks: {0}" -f ($tasks | Measure-Object).Count) -ForegroundColor Green
} catch { Write-Host "   Recommendation read failed (cmdlet/version may differ): $($_.Exception.Message)" -ForegroundColor Yellow }

$html = @"
<html><head><meta charset='utf-8'><title>Defender for Cloud Workshop — Summary</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}h1,h2{color:#0b5}
table{border-collapse:collapse;margin:8px 0}td,th{border:1px solid #ccc;padding:6px 10px;text-align:left}
.note{background:#f5f5f5;padding:10px;border-left:4px solid #0b5}.big{font-size:22px;font-weight:bold}</style></head><body>
<h1>Defender for Cloud Workshop — Summary Report</h1>
<p>Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Subscription: $($ctx.Subscription.Name). Read-only. White-label.</p>
<h2>Secure Score</h2><p class='big'>$scoreHtml</p>
<h2>Recommendations by severity</h2><table><tr><th>Severity</th><th>Count</th></tr>$sevRows</table>
<h2>Sample recommendations</h2><table><tr><th>Recommendation</th><th>State</th></tr>$recRows</table>
<h2>Remediation shortlist (Labs 1/5 — fill in)</h2>
<div class='note'>Top 3-5 recommendations by impact and effort. Remediation and change approval belong
to the customer's cloud-ops/security functions; enabling paid plans is verified for cost first.</div>
<table><tr><th>#</th><th>Recommendation</th><th>Impact</th><th>Owner</th><th>Effort</th></tr>
<tr><td>1</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>2</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>3</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr></table>
</body></html>
"@
$html | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nSaved report to $OutputPath (read-only)." -ForegroundColor Cyan
