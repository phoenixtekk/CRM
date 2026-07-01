<#
.SYNOPSIS
    CIS11-Compare-BenchmarkVersion.ps1 — diff a NEW CIS benchmark export against the current live baseline.
.DESCRIPTION
    PURPOSE
        Drives the benchmark-version update lifecycle (Maintenance Guide, Part B, Step 2). Compares a
        NEW CIS Windows 11 export (e.g. from the new Build Kit) against your CURRENT live baseline
        export, and reports which controls were ADDED, REMOVED, CHANGED (new recommended value), or
        moved LEVEL (L1<->L2). Pure file comparison — read-only, makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CIS11-Compare-BenchmarkVersion.ps1 ^
            -CurrentPath .\baseline-current.json -NewPath .\benchmark-new.json -CsvPath C:\Temp\cis-diff.csv
        Each JSON is an array of controls: [ { "Id":"1.1.1", "Name":"...", "Level":"L1", "Value":"24" } ]
        Export the CURRENT file from your live Intune baseline; export the NEW file from the new CIS
        Build Kit. (Control IDs/values are deferred to the official CIS Benchmark.)
    EXPECTED RESULTS
        Counts and lists of Added / Removed / Changed / Level-changed controls, and an optional CSV
        change record to attach to your approval ticket. Exit code 0 = identical, 1 = differences found.
.NOTES
    Intune Solutions — CIS Win11. Read-only. Use the output to assess/approve the version update.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$CurrentPath,
    [Parameter(Mandatory=$true)][string]$NewPath,
    [string]$CsvPath
)

foreach ($f in @($CurrentPath, $NewPath)) {
    if (-not (Test-Path $f)) { Write-Host "File not found: $f" -ForegroundColor Red; exit 2 }
}

$cur = @(Get-Content $CurrentPath -Raw | ConvertFrom-Json)
$new = @(Get-Content $NewPath -Raw | ConvertFrom-Json)
$curMap = @{}; $cur | ForEach-Object { $curMap[[string]$_.Id] = $_ }
$newMap = @{}; $new | ForEach-Object { $newMap[[string]$_.Id] = $_ }

$results = @()
# Added (in new, not in current)
foreach ($id in $newMap.Keys) { if (-not $curMap.ContainsKey($id)) { $results += [pscustomobject]@{ Change='ADDED'; Id=$id; Name=$newMap[$id].Name; Detail=("Level={0}, Value={1}" -f $newMap[$id].Level, $newMap[$id].Value) } } }
# Removed (in current, not in new)
foreach ($id in $curMap.Keys) { if (-not $newMap.ContainsKey($id)) { $results += [pscustomobject]@{ Change='REMOVED'; Id=$id; Name=$curMap[$id].Name; Detail='no longer in benchmark' } } }
# Changed value / level (in both)
foreach ($id in $newMap.Keys) {
    if ($curMap.ContainsKey($id)) {
        $c = $curMap[$id]; $n = $newMap[$id]
        if ("$($c.Value)" -ne "$($n.Value)") { $results += [pscustomobject]@{ Change='CHANGED'; Id=$id; Name=$n.Name; Detail=("value {0} -> {1}" -f $c.Value, $n.Value) } }
        if ("$($c.Level)" -ne "$($n.Level)") { $results += [pscustomobject]@{ Change='LEVEL'; Id=$id; Name=$n.Name; Detail=("level {0} -> {1}" -f $c.Level, $n.Level) } }
    }
}

Write-Host "=== CIS Win11 benchmark diff (current -> new) ===" -ForegroundColor Cyan
foreach ($g in @('ADDED','REMOVED','CHANGED','LEVEL')) {
    $set = $results | Where-Object Change -eq $g
    Write-Host ("`n{0}: {1}" -f $g, $set.Count) -ForegroundColor Cyan
    $set | ForEach-Object { Write-Host ("  [{0}] {1}  ({2})" -f $_.Id, $_.Name, $_.Detail) }
}
Write-Host ("`nTotal differences: {0}  (current={1} controls, new={2} controls)" -f $results.Count, $cur.Count, $new.Count) -ForegroundColor ($(if($results){'Yellow'}else{'Green'}))

if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved change record: $CsvPath" }

if ($results.Count -eq 0) { Write-Host "Baselines are identical — no version update needed." -ForegroundColor Green; exit 0 } else { exit 1 }
