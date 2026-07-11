<#
.SYNOPSIS
    SOPEIS-Report.ps1 — before/after metrics for the tuning engagement: conflict/error counts,
    non-compliant proportion, and coverage % per policy type.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Solution Optimization — Endpoint Security with Microsoft
        Intune" solution. Computes the key optimization metrics from Intune/Graph and — with
        -SaveBaseline — writes them as the 'before' snapshot. On later runs, -BaselinePath
        compares current metrics to the baseline so the improvement is measurable (this is what
        proves the estate got better). Makes no changes.
    HOW TO RUN
        # Capture the BEFORE baseline (Implementation Step 1):
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Report.ps1 -SaveBaseline
        # Measure the AFTER delta (Implementation Step 6):
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Report.ps1 -BaselinePath .\sopeis-baseline.json
        Requires Microsoft.Graph.Authentication with DeviceManagementManagedDevices.Read.All and
        DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A metrics block (conflict/error count, non-compliant proportion, coverage %). With
        -SaveBaseline: writes sopeis-baseline.json. With -BaselinePath: prints the delta per metric.
.NOTES
    White-label. Read-only. Coverage is share of managed devices receiving at least one
    endpoint-security/compliance policy in scope; refine the denominator to your estate as needed.
#>
[CmdletBinding()]
param(
    [switch]$SaveBaseline,
    [string]$BaselinePath,
    [int]$SampleSize = 100,
    [string]$OutFile = ".\sopeis-baseline.json"
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome | Out-Null }

Write-Host "`n=== SOPEIS before/after metrics (read-only) ===" -ForegroundColor Cyan
$metrics = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

# --- Managed devices sample ---
$devs = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$select=id,deviceName,complianceState&`$top={0}" -f $SampleSize)).value
$total = $devs.Count
$metrics.DevicesSampled = $total

# --- Non-compliant proportion ---
$nonCompliant = ($devs | Where-Object { $_.complianceState -notin 'compliant','unknown' }).Count
$nonCompPct = if ($total) { [math]::Round(100.0 * $nonCompliant / $total, 1) } else { 0 }
$metrics.NonCompliantPct = $nonCompPct
Write-Host ("   Non-compliant proportion ... {0}%  ({1}/{2})" -f $nonCompPct, $nonCompliant, $total)

# --- Conflict/error count + coverage (share receiving >=1 config state) ---
$conflict = 0; $error = 0; $covered = 0
foreach ($d in $devs) {
    try {
        $st = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates?`$select=state" -f $d.id) -ErrorAction SilentlyContinue).value
        if ($st -and $st.Count -gt 0) { $covered++ }
        $conflict += ($st | Where-Object { $_.state -eq 'conflict' }).Count
        $error    += ($st | Where-Object { $_.state -eq 'error' }).Count
    } catch {}
}
$coveragePct = if ($total) { [math]::Round(100.0 * $covered / $total, 1) } else { 0 }
$metrics.ConflictCount = $conflict
$metrics.ErrorCount = $error
$metrics.CoveragePct = $coveragePct
Write-Host ("   Conflicts / errors ......... {0} / {1}" -f $conflict, $error)
Write-Host ("   Policy coverage ............ {0}%" -f $coveragePct)

# --- Save or compare ---
if ($SaveBaseline) {
    $metrics | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
    Write-Host ("`nBaseline saved: {0}  (this is the 'before' — tune, then re-run with -BaselinePath)" -f $OutFile) -ForegroundColor Green
} elseif ($BaselinePath -and (Test-Path $BaselinePath)) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    Write-Host "`n-- Delta vs baseline (improvement = conflicts/non-compliant down, coverage up) --" -ForegroundColor Cyan
    function Delta($label, $now, $was, $lowerIsBetter) {
        $d = [math]::Round($now - $was, 1)
        $good = if ($lowerIsBetter) { $d -le 0 } else { $d -ge 0 }
        $arrow = if ($d -eq 0) { '=' } elseif ($d -gt 0) { '+' } else { '' }
        Write-Host ("   {0,-26} {1} -> {2}  ({3}{4})" -f $label, $was, $now, $arrow, $d) -ForegroundColor $(if ($good) { 'Green' } else { 'Yellow' })
    }
    Delta 'Conflict count'      $metrics.ConflictCount  $base.ConflictCount  $true
    Delta 'Error count'         $metrics.ErrorCount     $base.ErrorCount     $true
    Delta 'Non-compliant %'     $metrics.NonCompliantPct $base.NonCompliantPct $true
    Delta 'Coverage %'          $metrics.CoveragePct    $base.CoveragePct    $false
} else {
    Write-Host "`n(No -SaveBaseline and no valid -BaselinePath — metrics shown above only.)" -ForegroundColor DarkGray
}
