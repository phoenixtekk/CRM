<#
.SYNOPSIS
    GWMIGPROG-Report.ps1 — render migration-program progress and per-wave coverage.
.DESCRIPTION
    PURPOSE
        Produces the standing program report: waves complete vs planned, users migrated vs the total
        source population, and per-wave coverage. It reads the wave plan from a CSV (one row per wave
        with planned/migrated counts and status) and cross-checks the total population against the
        Microsoft 365 source through Microsoft Graph. Read-only against Graph — it modifies nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWMIGPROG-Report.ps1 `
            -WavePlanCsv .\gwmigprog-wave-plan.csv -CsvPath .\gwmigprog-progress.csv
        The wave-plan CSV should include columns: Wave, PlannedUsers, MigratedUsers, Status
        (Planned/InProgress/Complete). Requires the Microsoft Graph PowerShell SDK and User.Read.All
        (used only to read the total source-user count for the coverage denominator).
    EXPECTED RESULTS
        A per-wave progress table, program totals (waves complete, users migrated vs source total,
        overall coverage %), and an optional CSV export. No source data is modified.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WavePlanCsv,
    [string]$CsvPath
)

if (-not (Test-Path $WavePlanCsv)) { throw "Wave-plan CSV not found: $WavePlanCsv" }
$plan = @(Import-Csv -Path $WavePlanCsv)
if ($plan.Count -eq 0) { throw "Wave-plan CSV has no rows: $WavePlanCsv" }

# Total source population (coverage denominator) from Microsoft Graph.
$sourceTotal = $null
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome
    $count = 0
    $next = "/v1.0/users?`$select=id&`$top=999"
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $next; $count += @($r.value).Count; $next = $r.'@odata.nextLink' } while ($next)
    $sourceTotal = $count
    Disconnect-MgGraph | Out-Null
} catch {
    Write-Host ("Could not read source total from Graph ({0}); using plan sum as denominator." -f $_.Exception.Message) -ForegroundColor Yellow
}

$rows = foreach ($w in $plan) {
    $planned  = [int]($w.PlannedUsers)
    $migrated = [int]($w.MigratedUsers)
    $pct = if ($planned -gt 0) { [math]::Round(100 * $migrated / $planned, 1) } else { 0 }
    [pscustomobject]@{
        Wave         = $w.Wave
        Planned      = $planned
        Migrated     = $migrated
        WaveCoverage = "$pct%"
        Status       = $w.Status
    }
}

Write-Host "`n=== Migration program — per-wave progress ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize

$wavesComplete = @($plan | Where-Object { $_.Status -eq 'Complete' }).Count
$totalPlanned  = ($plan | Measure-Object -Property PlannedUsers -Sum).Sum
$totalMigrated = ($plan | Measure-Object -Property MigratedUsers -Sum).Sum
$denominator   = if ($sourceTotal) { $sourceTotal } else { [int]$totalPlanned }
$overallPct    = if ($denominator -gt 0) { [math]::Round(100 * $totalMigrated / $denominator, 1) } else { 0 }

Write-Host "=== Program totals ===" -ForegroundColor Cyan
Write-Host ("Waves complete            : {0} of {1}" -f $wavesComplete, $plan.Count)
Write-Host ("Users migrated            : {0} of {1} ({2})" -f $totalMigrated, $denominator, ($(if($sourceTotal){'source total from Graph'}else{'plan total — Graph unavailable'})))
Write-Host ("Overall coverage          : {0}%" -f $overallPct) -ForegroundColor ($(if($overallPct -ge 100){'Green'}else{'Cyan'}))
$remaining = $denominator - $totalMigrated
if ($remaining -gt 0) { Write-Host ("Remaining to migrate      : {0}" -f $remaining) -ForegroundColor Yellow }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved {0}" -f $CsvPath) }
