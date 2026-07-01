<#
.SYNOPSIS
    STIG-Compare-StigVersion.ps1 — diff a NEW DISA STIG export against the current live baseline.
.DESCRIPTION
    PURPOSE
        Drives the STIG-release update lifecycle (Maintenance Guide, Part B, Step 2). Compares a NEW
        DISA Windows 10/11 STIG export (e.g. from the new STIG Viewer / SCAP content) against your
        CURRENT live baseline export, and reports which rules were ADDED, REMOVED, CHANGED (new
        required value), or moved SEVERITY (CAT I/II/III). Pure file comparison — read-only, makes no
        changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\STIG-Compare-StigVersion.ps1 ^
            -CurrentPath .\baseline-current.json -NewPath .\stig-new.json -CsvPath C:\Temp\stig-diff.csv
        Each JSON is an array of rules: [ { "RuleId":"SV-...", "Name":"...", "Cat":"CAT II", "Value":"14" } ]
        Export the CURRENT file from your live Intune baseline; export the NEW file from the new DISA
        STIG release. (Rule IDs/values are deferred to the official DISA STIG / STIG Viewer.)
    EXPECTED RESULTS
        Counts and lists of Added / Removed / Changed / Severity-changed rules, and an optional CSV
        change record to attach to your approval ticket. Exit code 0 = identical, 1 = differences found.
.NOTES
    Intune Solutions — DISA STIG Win10/11. Read-only. Use the output to assess/approve the release update.
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
$curMap = @{}; $cur | ForEach-Object { $curMap[[string]$_.RuleId] = $_ }
$newMap = @{}; $new | ForEach-Object { $newMap[[string]$_.RuleId] = $_ }

$results = @()
# Added (in new, not in current)
foreach ($id in $newMap.Keys) { if (-not $curMap.ContainsKey($id)) { $results += [pscustomobject]@{ Change='ADDED'; RuleId=$id; Name=$newMap[$id].Name; Detail=("Cat={0}, Value={1}" -f $newMap[$id].Cat, $newMap[$id].Value) } } }
# Removed (in current, not in new)
foreach ($id in $curMap.Keys) { if (-not $newMap.ContainsKey($id)) { $results += [pscustomobject]@{ Change='REMOVED'; RuleId=$id; Name=$curMap[$id].Name; Detail='no longer in STIG' } } }
# Changed value / severity (in both)
foreach ($id in $newMap.Keys) {
    if ($curMap.ContainsKey($id)) {
        $c = $curMap[$id]; $n = $newMap[$id]
        if ("$($c.Value)" -ne "$($n.Value)") { $results += [pscustomobject]@{ Change='CHANGED'; RuleId=$id; Name=$n.Name; Detail=("value {0} -> {1}" -f $c.Value, $n.Value) } }
        if ("$($c.Cat)" -ne "$($n.Cat)") { $results += [pscustomobject]@{ Change='SEVERITY'; RuleId=$id; Name=$n.Name; Detail=("severity {0} -> {1}" -f $c.Cat, $n.Cat) } }
    }
}

Write-Host "=== DISA STIG Win10/11 diff (current -> new) ===" -ForegroundColor Cyan
foreach ($g in @('ADDED','REMOVED','CHANGED','SEVERITY')) {
    $set = $results | Where-Object Change -eq $g
    Write-Host ("`n{0}: {1}" -f $g, $set.Count) -ForegroundColor Cyan
    $set | ForEach-Object { Write-Host ("  [{0}] {1}  ({2})" -f $_.RuleId, $_.Name, $_.Detail) }
}
Write-Host ("`nTotal differences: {0}  (current={1} rules, new={2} rules)" -f $results.Count, $cur.Count, $new.Count) -ForegroundColor ($(if($results){'Yellow'}else{'Green'}))

if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved change record: $CsvPath" }

if ($results.Count -eq 0) { Write-Host "Baselines are identical — no release update needed." -ForegroundColor Green; exit 0 } else { exit 1 }
