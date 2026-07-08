<#
.SYNOPSIS
    CMPDASH-Report.ps1 — Consolidated Risk & Compliance Dashboard generator: collect signals + render HTML/CSV (read-only).
.DESCRIPTION
    PURPOSE
        The dashboard generator. Reads each 'live' Purview signal (DLP / sensitivity-label / retention
        policy enumeration via Security & Compliance PowerShell, and activity volume via
        Search-UnifiedAuditLog over the config window), merges the 'owner-captured' figures already
        recorded in RiskComplianceDashboard.config.json (Compliance Manager, Insider Risk, Communication
        Compliance, DSPM — aggregate-only), applies the RAG thresholds, writes the normalized dataset
        RiskComplianceDashboard.data.json, and renders RiskComplianceDashboard.html + .csv with one tile
        per signal (value + RAG colour + source badge). Read-only: reads posture, writes only local
        artifacts, changes no policy, and never reads HR-sensitive case content.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPDASH-Report.ps1 -WindowDays 30
        Connect first: Connect-IPPSSession as a least-privilege reader (DLP/label/retention + audit read).
        PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        RiskComplianceDashboard.data.json, RiskComplianceDashboard.html, and RiskComplianceDashboard.csv
        written locally; unlicensed/unreadable signals shown as "not licensed / verify your tenant".
.NOTES
    Purview category — Risk & Compliance Dashboard. Read-only. HR-sensitive feeds are aggregate-only,
    owner-captured. RAG thresholds are your policy. Determinations deferred to compliance/records/legal.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = "./RiskComplianceDashboard.config.json",
    [string]$DataPath   = "./RiskComplianceDashboard.data.json",
    [string]$HtmlPath   = "./RiskComplianceDashboard.html",
    [string]$CsvPath    = "./RiskComplianceDashboard.csv",
    [int]$WindowDays    = 30
)

if (-not (Test-Path $ConfigPath)) { Write-Host "Config not found at $ConfigPath — run CMPDASH-Set-Configuration.ps1 -Commit first." -ForegroundColor Yellow; return }
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
if ($config.windowDays) { $WindowDays = $config.windowDays }

$rows = @()
function Add-Row($key,$title,$value,$rag,$source,$note) {
    $script:rows += [pscustomobject]@{ key=$key; title=$title; value=$value; rag=$rag; source=$source; note=$note; timestamp=(Get-Date).ToString("s") }
}

Write-Host "=== CMPDASH-Report — collect + render (read-only) ===" -ForegroundColor Cyan

# --- LIVE: DLP ---
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    $enforced = ($dlp | Where-Object { $_.Mode -eq 'Enable' }).Count
    $sim      = ($dlp | Where-Object { $_.Mode -like 'Test*' }).Count
    $vol = $null
    try {
        $end = Get-Date; $start = $end.AddDays(-$WindowDays)
        $audit = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType ComplianceDLPExchange -ResultSize 5000 -ErrorAction Stop
        $vol = ($audit | Measure-Object).Count
    } catch { $vol = 'n/a (audit ingestion off or no permission)' }
    $rag = if ($enforced -eq 0 -and $sim -gt 0) { 'amber' } elseif ($dlp.Count -eq 0) { 'red' } else { 'green' }
    Add-Row 'dlp' 'Data Loss Prevention' ("policies {0} (enforced {1}/sim {2}); DLP audit events ~{3}" -f $dlp.Count,$enforced,$sim,$vol) $rag 'live' 'match volume from unified audit log (Exchange record type shown; extend per workload)'
} catch { Add-Row 'dlp' 'Data Loss Prevention' 'not licensed / verify your tenant' 'grey' 'live' 'unable to read Get-DlpCompliancePolicy' }

# --- LIVE: sensitivity labels ---
try {
    $labels = Get-Label -ErrorAction Stop
    $lp = @(); try { $lp = Get-LabelPolicy -ErrorAction Stop } catch {}
    $rag = if ($labels.Count -gt 0) { 'green' } else { 'amber' }
    Add-Row 'sensitivityLabels' 'Sensitivity labels' ("published labels {0}; label policies {1}" -f $labels.Count,$lp.Count) $rag 'live' ''
} catch { Add-Row 'sensitivityLabels' 'Sensitivity labels' 'not licensed / verify your tenant' 'grey' 'live' 'unable to read Get-Label' }

# --- LIVE: retention ---
try {
    $ret = Get-RetentionCompliancePolicy -ErrorAction Stop
    $rag = if ($ret.Count -gt 0) { 'green' } else { 'amber' }
    Add-Row 'retention' 'Data lifecycle & records' ("retention policies {0}" -f $ret.Count) $rag 'live' 'workload coverage: confirm Exchange/SPO/OneDrive/Teams in the portal'
} catch { Add-Row 'retention' 'Data lifecycle & records' 'not licensed / verify your tenant' 'grey' 'live' 'unable to read Get-RetentionCompliancePolicy' }

# --- LIVE: audit ---
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = $cfg.UnifiedAuditLogIngestionEnabled
    Add-Row 'audit' 'Audit' ("unified audit-log ingestion {0}" -f ($(if($on){'ENABLED'}else{'DISABLED'}))) ($(if($on){'green'}else{'red'})) 'live' 'Standard vs Premium + retention: verify your licensing/tenant'
} catch { Add-Row 'audit' 'Audit' 'unable to read / verify your tenant' 'grey' 'live' '' }

# --- OWNER-CAPTURED: merge figures already recorded in the config (never invented) ---
foreach ($s in ($config.signals | Where-Object { $_.source -eq 'owner-captured' })) {
    $val = if ($s.PSObject.Properties.Name -contains 'capturedValue' -and $s.capturedValue) { $s.capturedValue } else { 'awaiting owner capture — verify your licensing/tenant' }
    $captured = if ($s.capturedOn) { $s.capturedOn } else { 'never' }
    $rag = if (-not $s.capturedOn) { 'grey' } else { 'green' }
    Add-Row $s.key $s.title ("{0}  (captured on {1}, owner {2})" -f $val,$captured,$s.owner) $rag 'owner-captured' $s.note
}

# --- Persist normalized dataset ---
$rows | ConvertTo-Json -Depth 6 | Out-File -FilePath $DataPath -Encoding utf8
$rows | Select-Object key,title,value,rag,source,note,timestamp | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $DataPath and $CsvPath" -ForegroundColor Green

# --- Render simple, dependency-free HTML dashboard ---
$colour = @{ green='#2e7d32'; amber='#ef6c00'; red='#c62828'; grey='#607d8b' }
$tiles = ($rows | ForEach-Object {
    $c = $colour[$_.rag]; if (-not $c) { $c = '#607d8b' }
    $badge = if ($_.source -eq 'live') { 'LIVE' } else { 'OWNER-CAPTURED' }
    "<div style='border-left:8px solid $c;padding:12px 16px;margin:8px;border:1px solid #ddd;border-radius:6px;min-width:280px;flex:1'>" +
    "<div style='font-size:12px;color:#888'>$badge</div>" +
    "<div style='font-weight:600;font-size:16px'>$([System.Web.HttpUtility]::HtmlEncode($_.title))</div>" +
    "<div style='margin-top:6px'>$([System.Web.HttpUtility]::HtmlEncode([string]$_.value))</div>" +
    "<div style='margin-top:6px;font-size:12px;color:#999'>$([System.Web.HttpUtility]::HtmlEncode([string]$_.note))</div></div>"
}) -join "`n"
$genOn = (Get-Date).ToString("u")
$html = @"
<!doctype html><html><head><meta charset='utf-8'><title>Risk &amp; Compliance Dashboard — Microsoft Purview</title></head>
<body style='font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222'>
<h2>Risk &amp; Compliance Dashboard — Microsoft Purview</h2>
<p style='color:#777'>Generated $genOn · window ${WindowDays}d · RAG thresholds are your policy. Regulatory/records/legal determinations are deferred to the governance functions. Insider Risk &amp; Communication Compliance are aggregate-only.</p>
<div style='display:flex;flex-wrap:wrap'>$tiles</div>
</body></html>
"@
Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
$html | Out-File -FilePath $HtmlPath -Encoding utf8
Write-Host "Rendered $HtmlPath" -ForegroundColor Green
Write-Host "`nNext: CMPDASH-Validation.ps1 to reconcile the live tiles against the portal." -ForegroundColor Cyan
