<#
.SYNOPSIS
    OPSEXEC-Report.ps1 - render the executive one-pager from the metric definition and append a trend snapshot (read-only vs Purview).
.DESCRIPTION
    PURPOSE
        Reads "Exec Metrics - Compliance Signals - Definition" (from OPSEXEC-Configure.ps1), collects the
        API-readable KPIs (label/retention coverage, DLP/activity counts) via Security & Compliance
        PowerShell, uses the portal-entered values (with their read dates) for portal-only KPIs, RAG-scores
        each against its thresholds, and renders the one-page "Exec Dashboard - One Pager - <Stage>" (HTML +
        CSV). It then APPENDS the cycle's snapshot to "Exec Trend - Monthly Snapshot - Baseline" so trend
        accrues over time. Read-only against Purview - the only writes are the report files and the trend
        store. Insider-risk KPIs are carried as AGGREGATE counts by severity only (no names, no case detail).
    HOW TO RUN
        powershell -File .\OPSEXEC-Report.ps1 -DefinitionPath .\ExecMetrics.json -Stage Pilot
        powershell -File .\OPSEXEC-Report.ps1 -DefinitionPath .\ExecMetrics.json -Stage Publish
        Requires ExchangeOnlineManagement (Connect-IPPSSession). -TrendPath overrides the trend store path;
        -OutDir sets where the one-pager lands. Interactive modern-auth; no secrets.
    EXPECTED RESULTS
        An HTML one-pager + a CSV of KPI/value/RAG, and one appended row in the trend store. PASS = every KPI
        shows either a collected value or an explicit "not licensed / portal-read - verify" - never a
        fabricated number - and the trend store grew by exactly one snapshot.
.NOTES
    Purview category - Executive Dashboard. Read-only vs Purview. Trend store is APPEND-ONLY - never
    overwrite it. Keep Insider Risk AGGREGATE/de-identified. Sources are licensing-/tenant-dependent; some
    are portal-only. No client names; no secrets.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DefinitionPath,
    [ValidateSet('Pilot','Publish')][string]$Stage = 'Pilot',
    [string]$UserPrincipalName,
    [string]$TrendPath = ".\Exec-Trend-Monthly-Snapshot-Baseline.json",
    [string]$OutDir = "."
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
if (-not (Test-Path $DefinitionPath)) { Write-Host "[FAIL] definition not found: $DefinitionPath (run OPSEXEC-Configure.ps1 first)." -ForegroundColor Red; return }
$def = Get-Content -Raw -Path $DefinitionPath | ConvertFrom-Json
$asOf = (Get-Date).ToUniversalTime()

# --- Connect (read-only) for API-readable KPIs ---
$connected = $false
if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    $cp = @{ ShowBanner=$false }; if ($UserPrincipalName) { $cp['UserPrincipalName']=$UserPrincipalName }
    try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; $connected = $true } catch { Write-Host "  [WARN] Connect-IPPSSession failed: $($_.Exception.Message)" -ForegroundColor Yellow }
} else { Write-Host '  [WARN] ExchangeOnlineManagement not installed - API KPIs will show portal-read/verify.' -ForegroundColor Yellow }

# --- Collect a small set of API-readable signals (honest: null/verify where unreachable) ---
function Get-ApiValue($kpi,$source) {
    if (-not $connected) { return $null }
    try {
        switch -Regex ($source) {
            'RetentionPolicies' {
                $r = @(Get-RetentionCompliancePolicy -ErrorAction Stop)
                return @($r | Where-Object { $_.Enabled -ne $false }).Count   # count of enabled retention policies (a coverage proxy - confirm denominator in the definition)
            }
            'ActivityExplorer' {
                if (Get-Command Export-ActivityExplorerData -ErrorAction SilentlyContinue) {
                    $end = (Get-Date); $start = $end.AddDays(-30)
                    $data = Export-ActivityExplorerData -StartTime $start -EndTime $end -PageSize 100 -ErrorAction Stop
                    return @($data).Count   # indicative; align filters to your portal view (severity/workload)
                } else { return $null }
            }
            'ContentExplorer' {
                if (Get-Command Export-ContentExplorerData -ErrorAction SilentlyContinue) { return $null } # preview/tenant-dependent - leave for portal read unless confirmed
                else { return $null }
            }
            default { return $null }
        }
    } catch { return $null }
}

function Get-Rag($value,$thr,$unit) {
    if ($null -eq $value -or $null -eq $thr) { return 'NA' }
    $g = $thr.green; $a = $thr.amber
    # For "higher is better" (percent coverage / score) green>=g; for "lower is better" (counts) green<=g.
    if ($g -ge $a) { if ($value -ge $g) {'GREEN'} elseif ($value -ge $a) {'AMBER'} else {'RED'} }
    else           { if ($value -le $g) {'GREEN'} elseif ($value -le $a) {'AMBER'} else {'RED'} }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($sectionName in $def.sections.PSObject.Properties.Name) {
    foreach ($kpi in $def.sections.$sectionName) {
        $val = $null; $note = ''
        if ("$($kpi.source)" -match '^api:') {
            $val = Get-ApiValue $kpi.kpi $kpi.source
            if ($null -eq $val) { $note = 'portal-read / verify tenant (API not available or empty)' }
        } elseif ("$($kpi.source)" -match '^portal:') {
            $val = $kpi.value
            if ($null -eq $val) { $note = "portal value not entered (owner: $($kpi.readBy))" }
            elseif ($kpi.readDate) {
                $rd = [datetime]$kpi.readDate
                if ($rd -lt $asOf.AddDays(-[int]$def.refreshWindowDays)) { $note = "STALE - portal value read $($kpi.readDate) (> $($def.refreshWindowDays)d)" }
            }
        } elseif ("$($kpi.source)" -match '^trend:') { $note = 'trend section - see trend store' }
        $rag = Get-Rag $val $kpi.thresholds $kpi.unit
        $rows.Add([pscustomobject]@{
            Section=$sectionName; KPI=$kpi.kpi; Value=$val; Unit=$kpi.unit; RAG=$rag; AsOf=$asOf.ToString('u'); Note=$note
        })
    }
}

# --- Emit CSV + a self-contained HTML one-pager ---
$csvPath  = Join-Path $OutDir ("Exec-Dashboard-One-Pager-$Stage.csv")
$htmlPath = Join-Path $OutDir ("Exec-Dashboard-One-Pager-$Stage.html")
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
$ragColor = @{ GREEN='#1a7f37'; AMBER='#9a6700'; RED='#b42318'; NA='#57606a' }
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("<html><head><meta charset='utf-8'><title>Executive Compliance Dashboard - $Stage</title></head><body style='font-family:Segoe UI,Arial,sans-serif'>")
[void]$sb.Append("<h2>Executive Compliance &amp; Data-Risk Dashboard</h2><p>Stage: $Stage &middot; As of $($asOf.ToString('u'))</p>")
foreach ($sec in ($rows | Group-Object Section)) {
    [void]$sb.Append("<h3 style='text-transform:capitalize'>$($sec.Name)</h3><table cellpadding='6' style='border-collapse:collapse'>")
    foreach ($r in $sec.Group) {
        $c = $ragColor["$($r.RAG)"]; $shown = if ($null -ne $r.Value) { "$($r.Value) $($r.Unit)" } else { '&mdash;' }
        [void]$sb.Append("<tr><td style='border:1px solid #ddd'>$($r.KPI)</td><td style='border:1px solid #ddd'><b>$shown</b></td><td style='border:1px solid #ddd;color:#fff;background:$c'>$($r.RAG)</td><td style='border:1px solid #ddd;color:#666'>$($r.Note)</td></tr>")
    }
    [void]$sb.Append("</table>")
}
[void]$sb.Append("<p style='color:#666;font-size:12px'>Insider-risk values are aggregate counts by severity only. Values marked 'portal-read/verify' are not fabricated. Regulatory/records/legal determinations are deferred.</p></body></html>")
$sb.ToString() | Set-Content -Path $htmlPath -Encoding UTF8

# --- Append the trend snapshot (APPEND-ONLY) ---
$snapshot = [ordered]@{
    asOf = $asOf.ToString('o'); stage = $Stage
    kpis = @($rows | Where-Object { $_.Section -ne 'trend' } | ForEach-Object { @{ kpi=$_.KPI; value=$_.Value; rag=$_.RAG } })
}
$trend = @()
if (Test-Path $TrendPath) { try { $trend = @(Get-Content -Raw -Path $TrendPath | ConvertFrom-Json) } catch { $trend = @() } }
$trend += $snapshot
$trend | ConvertTo-Json -Depth 8 | Out-File -FilePath $TrendPath -Encoding UTF8

Write-Section 'Exec Dashboard - One Pager'
$rows | Format-Table Section,KPI,Value,Unit,RAG,Note -AutoSize | Out-String | Write-Host
Write-Host ("One-pager -> {0}  (+ {1})" -f $htmlPath, $csvPath) -ForegroundColor Green
Write-Host ("Trend store appended -> {0}  ({1} snapshot(s) total)  [Exec Trend - Monthly Snapshot - Baseline]" -f $TrendPath, $trend.Count) -ForegroundColor Green
Write-Host 'Reminder: the trend store is APPEND-ONLY - never overwrite it. Portal-only KPIs must be re-read within the refresh window (run OPSEXEC-Validate.ps1).' -ForegroundColor Yellow
