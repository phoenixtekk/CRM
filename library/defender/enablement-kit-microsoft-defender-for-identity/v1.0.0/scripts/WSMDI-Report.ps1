<#
.SYNOPSIS
    WSMDI-Report.ps1 — read-only workshop summary report: identity alerts by severity plus an ISPM
    remediation shortlist starter for Lab 4.
.DESCRIPTION
    PURPOSE
        Produces a compact, read-only summary the facilitator can share at the end of the Defender
        for Identity workshop: a count of Defender-for-Identity alerts by severity/status, the most
        recent alerts, and a template for the "ISPM-Shortlist - Identity Lab - Pilot" (the top
        recommendations to remediate later, captured in the portal during Lab 4). Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMDI-Report.ps1 -OutputPath .\wsmdi-report.html
        Run as Security Reader / Security Administrator; consent read-only scopes when prompted.
    EXPECTED RESULTS
        A console summary and an HTML report file. The ISPM section is a fill-in template because the
        prioritized recommendation list is authored in the portal (the choice of what to remediate,
        and change approval, belong to the customer's security/ops functions).
.NOTES
    White-label. Read-only. Makes no changes.
    Licensing/preview facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\wsmdi-report.html"
)

$ErrorActionPreference = 'Continue'
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

Write-Host "`n=== Defender for Identity workshop — summary report (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'SecurityAlert.Read.All' -NoWelcome -ErrorAction Stop }
catch { Write-Host "  Could not connect: $($_.Exception.Message)" -ForegroundColor Red; return }

$alerts = @()
try {
    $alerts = Get-MgSecurityAlertV2 -All -ErrorAction Stop |
        Where-Object { $_.ServiceSource -match 'Identity' -or $_.DetectionSource -match 'Identity' }
} catch { Write-Host "  Alert read failed: $($_.Exception.Message)" -ForegroundColor Yellow }

$bySev = $alerts | Group-Object Severity | Sort-Object Name
$byStatus = $alerts | Group-Object Status | Sort-Object Name
Write-Host ("Total MDI alerts: {0}" -f $alerts.Count) -ForegroundColor Green
$bySev | ForEach-Object { Write-Host ("   {0}: {1}" -f $_.Name, $_.Count) }

$rows = ($alerts | Sort-Object CreatedDateTime -Descending | Select-Object -First 15 | ForEach-Object {
    "<tr><td>$($_.Title)</td><td>$($_.Severity)</td><td>$($_.Status)</td><td>$($_.CreatedDateTime)</td></tr>"
}) -join "`n"

$sevRows = ($bySev | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" }) -join "`n"

$html = @"
<html><head><meta charset='utf-8'><title>Defender for Identity Workshop — Summary</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1,h2{color:#0b5}table{border-collapse:collapse;margin:8px 0}td,th{border:1px solid #ccc;padding:6px 10px;text-align:left}
.note{background:#f5f5f5;padding:10px;border-left:4px solid #0b5}</style></head><body>
<h1>Defender for Identity Workshop — Summary Report</h1>
<p>Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Read-only. White-label.</p>
<h2>MDI alerts by severity</h2><table><tr><th>Severity</th><th>Count</th></tr>$sevRows</table>
<h2>Most recent MDI alerts</h2><table><tr><th>Title</th><th>Severity</th><th>Status</th><th>Created</th></tr>$rows</table>
<h2>ISPM remediation shortlist (Lab 4 — fill in from the portal)</h2>
<div class='note'>Capture the top 3-5 Identity Security Posture Management recommendations from
Secure Score / Exposure management, ranked by impact and effort. Remediation and change approval
belong to the customer's security/ops functions.</div>
<table><tr><th>#</th><th>Recommendation</th><th>Risk addressed</th><th>Owner</th><th>Priority</th></tr>
<tr><td>1</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>2</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>3</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr></table>
</body></html>
"@
$html | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nSaved report to $OutputPath (read-only)." -ForegroundColor Cyan
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
