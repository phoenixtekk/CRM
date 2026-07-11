<#
.SYNOPSIS
    WSMCA-Report.ps1 — read-only workshop summary report: MDA alerts by severity plus shadow-IT and
    OAuth-risk shortlist templates for Labs 1 and 3.
.DESCRIPTION
    PURPOSE
        Produces a compact, read-only summary for the end of the Defender for Cloud Apps workshop: a
        count of Defender-for-Cloud-Apps alerts by severity/status, the most recent alerts, and
        fill-in templates for the "ShadowIT-Shortlist - CloudApps Lab - Pilot" and
        "OAuthRisk-Shortlist - CloudApps Lab - Pilot" (authored in the portal during the labs).
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMCA-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMCA-Report.ps1 -OutputPath .\wsmca-report.html
        Run as Security Reader / Security Administrator; consent read-only scopes when prompted.
    EXPECTED RESULTS
        A console summary and an HTML report file. The shortlist sections are templates because
        app-sanctioning and consent-revocation decisions belong to the customer's security/business
        functions.
.NOTES
    White-label. Read-only. Makes no changes.
    Licensing/preview facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\wsmca-report.html"
)

$ErrorActionPreference = 'Continue'
foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Microsoft.Graph modules (one-time)..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue

Write-Host "`n=== Defender for Cloud Apps workshop — summary report (read-only) ===" -ForegroundColor Cyan
try { Connect-MgGraph -Scopes 'SecurityAlert.Read.All' -NoWelcome -ErrorAction Stop }
catch { Write-Host "  Could not connect: $($_.Exception.Message)" -ForegroundColor Red; return }

$alerts = @()
try { $alerts = Get-MgSecurityAlertV2 -All -ErrorAction Stop | Where-Object { $_.ServiceSource -match 'CloudApp' -or $_.DetectionSource -match 'CloudApp' } }
catch { Write-Host "  Alert read failed: $($_.Exception.Message)" -ForegroundColor Yellow }

$bySev = $alerts | Group-Object Severity | Sort-Object Name
Write-Host ("Total MDA alerts: {0}" -f $alerts.Count) -ForegroundColor Green
$bySev | ForEach-Object { Write-Host ("   {0}: {1}" -f $_.Name,$_.Count) }

$rows = ($alerts | Sort-Object CreatedDateTime -Descending | Select-Object -First 15 | ForEach-Object {
    "<tr><td>$($_.Title)</td><td>$($_.Severity)</td><td>$($_.Status)</td><td>$($_.CreatedDateTime)</td></tr>" }) -join "`n"
$sevRows = ($bySev | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" }) -join "`n"

$html = @"
<html><head><meta charset='utf-8'><title>Defender for Cloud Apps Workshop — Summary</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}h1,h2{color:#0b5}
table{border-collapse:collapse;margin:8px 0}td,th{border:1px solid #ccc;padding:6px 10px;text-align:left}
.note{background:#f5f5f5;padding:10px;border-left:4px solid #0b5}</style></head><body>
<h1>Defender for Cloud Apps Workshop — Summary Report</h1>
<p>Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Read-only. White-label.</p>
<h2>MDA alerts by severity</h2><table><tr><th>Severity</th><th>Count</th></tr>$sevRows</table>
<h2>Most recent MDA alerts</h2><table><tr><th>Title</th><th>Severity</th><th>Status</th><th>Created</th></tr>$rows</table>
<h2>Shadow-IT shortlist (Lab 1 — fill in from Cloud Discovery)</h2>
<div class='note'>Top risky discovered apps with a recommended disposition. App-sanctioning is the customer's decision.</div>
<table><tr><th>#</th><th>App</th><th>Risk score</th><th>Users/traffic</th><th>Disposition (sanction/restrict/block-later)</th></tr>
<tr><td>1</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>2</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>3</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr></table>
<h2>OAuth-risk shortlist (Lab 3 — fill in from OAuth apps)</h2>
<div class='note'>Riskiest OAuth apps by consent scope / publisher verification. Consent revocation is an approval-gated change.</div>
<table><tr><th>#</th><th>App</th><th>Permission level</th><th>Verified publisher?</th><th>Action (approval required)</th></tr>
<tr><td>1</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>2</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
<tr><td>3</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr></table>
</body></html>
"@
$html | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nSaved report to $OutputPath (read-only)." -ForegroundColor Cyan
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
