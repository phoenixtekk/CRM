<#
.SYNOPSIS
    M365SECG-Report.ps1 — read-only point-in-time posture report for a GCC High tenant (audit-ready).
.DESCRIPTION
    PURPOSE
        Produces a dated posture report for a Microsoft 365 GCC High tenant suitable for auditors and
        leadership: Secure Score summary, count of available control profiles, top open improvement
        actions, Conditional Access inventory, and Gov licensing. Read-only. Writes an HTML and a text
        report. Set your own values for placeholders such as your-output-folder.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\M365SECG-Report.ps1 -OutputFolder ".\M365SECG-output"
        (Graph scopes: SecurityEvents.Read.All, Policy.Read.All, Directory.Read.All;
         connects with -Environment USGov)
    EXPECTED RESULTS
        Two report files (HTML + TXT) written to the output folder, each stamped with date and the
        confirmed USGov environment. PASS when files are written; the console prints the summary.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [string]$OutputFolder = ".\M365SECG-output",
    [string]$Environment  = "USGov"
)

$ErrorActionPreference = "Stop"

function Connect-USGovGraph {
    param([string[]]$Scopes, [string]$Env)
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx -or $ctx.Environment -ne $Env) {
        Write-Host "Connecting to Microsoft Graph ($Env / GCC High = https://graph.microsoft.us)..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $Env -Scopes $Scopes | Out-Null
        $ctx = Get-MgContext
    }
    if ($ctx.Environment -ne $Env) {
        throw "Connected environment is '$($ctx.Environment)', expected '$Env'. Reconnect with -Environment $Env (GCC High must not use Commercial)."
    }
    return $ctx
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
}
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

$scopes = @("SecurityEvents.Read.All","Policy.Read.All","Directory.Read.All")
$ctx = Connect-USGovGraph -Scopes $scopes -Env $Environment

$stamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm 'UTC'K"
$txt     = Join-Path $OutputFolder "M365SECG-Report-$stamp.txt"
$html    = Join-Path $OutputFolder "M365SECG-Report-$stamp.html"

# --- Gather -------------------------------------------------------------------
$score = $null
try { $score = Get-MgSecuritySecureScore -Top 1 -ErrorAction Stop | Select-Object -First 1 } catch {}
$pct = if ($score -and $score.MaxScore) { [math]::Round(($score.CurrentScore/$score.MaxScore)*100,1) } else { 0 }

$profileCount = 0
try { $profileCount = (Get-MgSecuritySecureScoreControlProfile -All -ErrorAction Stop | Measure-Object).Count } catch {}

$topActions = @()
if ($score -and $score.ControlScores) {
    $topActions = $score.ControlScores |
        Sort-Object { [double]($_.AdditionalProperties.maxScore) - [double]$_.Score } -Descending |
        Select-Object -First 10
}

$caList = @()
try { $caList = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop } catch {}

$skuList = @()
try { $skuList = Get-MgSubscribedSku -All -ErrorAction Stop } catch {}

# --- Text report --------------------------------------------------------------
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("===================================================================")
[void]$sb.AppendLine(" Microsoft 365 Security Baseline & Audit Readiness - POSTURE REPORT")
[void]$sb.AppendLine(" Edition : Government (GCC High)   Environment: $($ctx.Environment)")
[void]$sb.AppendLine(" Tenant  : $($ctx.TenantId)")
[void]$sb.AppendLine(" Graph   : https://graph.microsoft.us   Generated: $dateStr")
[void]$sb.AppendLine("===================================================================")
[void]$sb.AppendLine("")
if ($score) {
    [void]$sb.AppendLine(("Secure Score : {0} / {1}  ({2}%)" -f $score.CurrentScore,$score.MaxScore,$pct))
} else {
    [void]$sb.AppendLine("Secure Score : unavailable (verify Gov Defender SKU + Security Reader role)")
}
[void]$sb.AppendLine(("Control profiles available in this GCC High tenant : {0}" -f $profileCount))
[void]$sb.AppendLine("(GCC High omits some Commercial recommendations by design - see gcc-high-parity-notes.)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Top open improvement actions (by point gap):")
if ($topActions.Count -gt 0) {
    foreach ($a in $topActions) {
        [void]$sb.AppendLine(("  - {0}  (score {1})" -f $a.ControlName, $a.Score))
    }
} else { [void]$sb.AppendLine("  (none returned)") }
[void]$sb.AppendLine("")
[void]$sb.AppendLine(("Conditional Access policies : {0}" -f ($caList | Measure-Object).Count))
foreach ($p in $caList) { [void]$sb.AppendLine(("  [{0}] {1}" -f $p.State,$p.DisplayName)) }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Licensing (confirm Gov SKUs; CMMC L1-5 needs G5 Gov):")
foreach ($s in $skuList) { [void]$sb.AppendLine(("  {0} (enabled {1}, consumed {2})" -f $s.SkuPartNumber,$s.PrepaidUnits.Enabled,$s.ConsumedUnits)) }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("This report was generated READ-ONLY against the US Gov (GCC High) cloud.")
$sb.ToString() | Out-File -FilePath $txt -Encoding UTF8

# --- HTML report --------------------------------------------------------------
$rows = ($topActions | ForEach-Object { "<tr><td>$([System.Web.HttpUtility]::HtmlEncode($_.ControlName))</td><td>$($_.Score)</td></tr>" }) -join "`n"
if (-not $rows) { $rows = "<tr><td colspan='2'>(none returned)</td></tr>" }
$caRows = ($caList | ForEach-Object { "<tr><td>$($_.State)</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.DisplayName))</td></tr>" }) -join "`n"
$scoreCell = if ($score) { "$($score.CurrentScore) / $($score.MaxScore) ($pct%)" } else { "unavailable" }

$htmlDoc = @"
<html><head><meta charset='utf-8'><title>M365SECG Posture Report (GCC High)</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#1b1b1b}
h1{font-size:20px}h2{font-size:15px;margin-top:22px}
table{border-collapse:collapse;width:100%;margin-top:8px}
th,td{border:1px solid #ccc;padding:6px 8px;text-align:left;font-size:13px}
th{background:#f2f2f2}.meta{color:#555;font-size:12px}</style></head><body>
<h1>Microsoft 365 Security Baseline &amp; Audit Readiness — Posture Report</h1>
<p class='meta'>Edition: Government (GCC High) &middot; Environment: $($ctx.Environment) &middot;
Tenant: $($ctx.TenantId) &middot; Graph: https://graph.microsoft.us &middot; Generated: $dateStr</p>
<h2>Secure Score</h2><p><strong>$scoreCell</strong> &middot; Control profiles available in this GCC High tenant: <strong>$profileCount</strong></p>
<p class='meta'>GCC High omits some Commercial recommendations by design — see gcc-high-parity-notes.</p>
<h2>Top open improvement actions</h2><table><tr><th>Control</th><th>Score</th></tr>$rows</table>
<h2>Conditional Access policies</h2><table><tr><th>State</th><th>Name</th></tr>$caRows</table>
<p class='meta'>Generated READ-ONLY against the US Gov (GCC High) cloud.</p>
</body></html>
"@
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
$htmlDoc | Out-File -FilePath $html -Encoding UTF8

Write-Host "`nPosture report generated (GCC High / USGov):" -ForegroundColor Green
Write-Host "  TXT : $txt"
Write-Host "  HTML: $html"
Write-Host "This run was READ-ONLY. Archive these files as audit evidence." -ForegroundColor Green
