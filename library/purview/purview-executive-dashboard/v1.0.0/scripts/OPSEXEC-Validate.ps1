<#
.SYNOPSIS
    OPSEXEC-Validate.ps1 - validate the metric definition and latest snapshot before publishing the dashboard (read-only).
.DESCRIPTION
    PURPOSE
        Read-only quality gate for the executive dashboard. Checks "Exec Metrics - Compliance Signals -
        Definition" and the latest "Exec Trend - Monthly Snapshot - Baseline" entry for the faults that make
        an exec page WRONG, EMPTY, or STALE: every KPI has a source + thresholds; every in-scope denominator
        is set; every portal-only value has an owner, a value, and a read date INSIDE the refresh window;
        the Insider-Risk KPI is AGGREGATE-only (no name/case fields); and the trend store is present and
        append-only (monotonic timestamps). Read-only - changes nothing.
    HOW TO RUN
        powershell -File .\OPSEXEC-Validate.ps1 -DefinitionPath .\ExecMetrics.json -TrendPath .\Exec-Trend-Monthly-Snapshot-Baseline.json
        Optional: -OutPath to write the PASS/FAIL/WARN results to CSV.
    EXPECTED RESULTS
        A per-check PASS/FAIL/WARN table. PASS overall = no FAIL (WARN allowed with a recorded exception).
        A portal-only value older than refreshWindowDays is flagged for re-read before publish. No number is
        ever fabricated - an unlicensed/portal-unavailable source is a documented "verify", not a failure.
.NOTES
    Purview category - Executive Dashboard. Read-only. Enforces privacy-by-design on Insider Risk (aggregate
    only). No secrets. Verify source availability in your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DefinitionPath,
    [string]$TrendPath = ".\Exec-Trend-Monthly-Snapshot-Baseline.json",
    [string]$OutPath
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
if (-not (Test-Path $DefinitionPath)) { Write-Host "[FAIL] definition not found: $DefinitionPath" -ForegroundColor Red; return }
$def = Get-Content -Raw -Path $DefinitionPath | ConvertFrom-Json
$now = (Get-Date).ToUniversalTime()
$refresh = if ($def.refreshWindowDays) { [int]$def.refreshWindowDays } else { 35 }

$results = New-Object System.Collections.Generic.List[object]
function Add-R($check,$item,$status,$detail){ $results.Add([pscustomobject]@{ Check=$check; Item=$item; Status=$status; Detail=$detail }) }

# --- Denominators / in-scope set ---
if ($def.inScope -and $def.inScope.workloads -and @($def.inScope.workloads).Count -gt 0) {
    Add-R 'Denominators' 'inScope.workloads' 'PASS' ("workloads: {0}" -f ($def.inScope.workloads -join ','))
} else { Add-R 'Denominators' 'inScope.workloads' 'FAIL' 'No in-scope workloads set - coverage percentages have no denominator' }

# --- Per-KPI checks ---
foreach ($sectionName in $def.sections.PSObject.Properties.Name) {
    foreach ($kpi in $def.sections.$sectionName) {
        $name = $kpi.kpi
        if ([string]::IsNullOrWhiteSpace($kpi.source)) { Add-R 'Source' $name 'FAIL' 'No source defined'; continue }
        # thresholds required except for trend rows
        if ("$($kpi.source)" -notmatch '^trend:') {
            if ($kpi.thresholds -and ($kpi.thresholds.PSObject.Properties.Name -contains 'green')) { Add-R 'Thresholds' $name 'PASS' '' }
            else { Add-R 'Thresholds' $name 'WARN' 'No green/amber thresholds - KPI cannot be RAG-scored' }
        }
        # portal-only values: owner + value + read date within window
        if ("$($kpi.source)" -match '^portal:') {
            if ($null -eq $kpi.value) { Add-R 'PortalValue' $name 'WARN' "No value entered (owner: $($kpi.readBy)) - page will show 'not entered'" }
            elseif ([string]::IsNullOrWhiteSpace($kpi.readDate)) { Add-R 'PortalValue' $name 'FAIL' 'Value entered without a read date' }
            else {
                $rd = $null; [datetime]::TryParse($kpi.readDate,[ref]$rd) | Out-Null
                if (-not $rd) { Add-R 'PortalValue' $name 'FAIL' "Unparseable read date: $($kpi.readDate)" }
                elseif ($rd.ToUniversalTime() -lt $now.AddDays(-$refresh)) { Add-R 'PortalValue' $name 'WARN' "STALE - read $($kpi.readDate) (> $refresh d) - re-read before publish" }
                else { Add-R 'PortalValue' $name 'PASS' "read $($kpi.readDate)" }
            }
        }
        # Insider Risk privacy check - aggregate only, no identifying fields
        if ($name -match '(?i)insider' -or "$($kpi.source)" -match '(?i)InsiderRisk') {
            $props = @($kpi.PSObject.Properties.Name)
            $bad = @($props | Where-Object { $_ -match '(?i)name|user|upn|case|alertId|subject' })
            if ($bad.Count -gt 0) { Add-R 'Privacy(InsiderRisk)' $name 'FAIL' ("Identifying field(s) present: {0} - MUST be aggregate/severity only" -f ($bad -join ',')) }
            else { Add-R 'Privacy(InsiderRisk)' $name 'PASS' 'Aggregate/severity only' }
        }
    }
}

# --- Trend store: present + append-only (monotonic timestamps) ---
Write-Section 'Trend store'
if (-not (Test-Path $TrendPath)) {
    Add-R 'Trend' 'store' 'WARN' 'No trend store yet - trend accrues from the first OPSEXEC-Report.ps1 run'
} else {
    try {
        $trend = @(Get-Content -Raw -Path $TrendPath | ConvertFrom-Json)
        $times = @($trend | ForEach-Object { [datetime]$_.asOf })
        $sorted = @($times | Sort-Object)
        if ($times.Count -lt 2) { Add-R 'Trend' 'store' 'WARN' "$($times.Count) snapshot(s) - two points are not yet a trend" }
        elseif (($times -join '|') -ne ($sorted -join '|')) { Add-R 'Trend' 'store' 'FAIL' 'Snapshot timestamps not monotonic - store may have been overwritten/reordered' }
        else { Add-R 'Trend' 'store' 'PASS' "$($times.Count) append-only snapshots" }
    } catch { Add-R 'Trend' 'store' 'FAIL' "Trend store unreadable: $($_.Exception.Message)" }
}

if ($OutPath) { $results | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8 }

Write-Section 'Result'
$results | Format-Table -AutoSize | Out-String | Write-Host
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$warn = @($results | Where-Object Status -eq 'WARN').Count
if ($fail -gt 0) { Write-Host "$fail FAIL - fix before publishing the dashboard." -ForegroundColor Red }
elseif ($warn -gt 0) { Write-Host "0 FAIL, $warn WARN - re-read any STALE portal value; WARN allowed only with a recorded exception." -ForegroundColor Yellow }
else { Write-Host 'All checks PASS - safe to publish.' -ForegroundColor Green }
if ($OutPath) { Write-Host ("Results -> {0}" -f $OutPath) -ForegroundColor Green }
