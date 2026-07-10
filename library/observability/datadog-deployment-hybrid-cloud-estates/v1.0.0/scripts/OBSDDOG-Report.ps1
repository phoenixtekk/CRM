<#
.SYNOPSIS
    OBSDDOG-Report.ps1 — Datadog inventory/coverage report via the API (read-only).
.DESCRIPTION
    PURPOSE
        Produces the coverage/cost evidence for the deployment: hosts reporting (grouped by env/service
        tag), the monitors and their current states, the SLO status/error budget, and a host-count
        snapshot to watch against the cost plan. Use it to confirm coverage climbs per rollout wave and
        to spot agent sprawl (dead hosts still counted). Read-only — queries the Datadog API only.
    HOW TO RUN
        $env:DD_API_KEY = (Read-From-Secret-Store); $env:DD_APP_KEY = (Read-From-Secret-Store)
        powershell -ExecutionPolicy Bypass -File .\OBSDDOG-Report.ps1 -Site api.datadoghq.com -CsvFolder C:\Temp\obsddog
    EXPECTED RESULTS
        Console summary + optional CSVs: hosts by tag, monitor states, SLO status, and total host count.
        Compare across waves; investigate any unexpected host-count growth (cost).
    NOTES
        White-label. Read-only. Keys read from the environment/secret store, never printed. Ingestion/host
        pricing is a Datadog-side decision — verify in Datadog's docs.
.EXAMPLE
    .\OBSDDOG-Report.ps1 -Site api.datadoghq.com
#>
[CmdletBinding()] param(
    [string]$Site = 'api.datadoghq.com',   # verify your org's site
    [string]$CsvFolder
)

if (-not ($env:DD_API_KEY -and $env:DD_APP_KEY)) {
    throw 'DD_API_KEY and DD_APP_KEY must be set from the secret store before running.'
}
$headers = @{ 'DD-API-KEY' = $env:DD_API_KEY; 'DD-APPLICATION-KEY' = $env:DD_APP_KEY }
$base = "https://$Site/api/v1"

function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

# --- Hosts reporting (by env/service tag) -------------------------------------
Write-Host "`n=== Hosts reporting ===" -ForegroundColor Cyan
try {
    $hosts = Invoke-RestMethod -Uri "$base/hosts?count=1000" -Headers $headers -Method Get -ErrorAction Stop
    $rows = $hosts.host_list | ForEach-Object {
        [pscustomobject]@{
            Host    = $_.name
            Up      = $_.up
            Env     = (($_.tags_by_source.Datadog | Where-Object { $_ -like 'env:*' }) -join ';')
            Service = (($_.tags_by_source.Datadog | Where-Object { $_ -like 'service:*' }) -join ';')
        }
    }
    $rows | Format-Table -AutoSize
    Save-Csv $rows 'hosts'
    Write-Host ("  Total hosts reporting: {0}  (watch against the cost plan)" -f $rows.Count) -ForegroundColor Yellow
} catch { Write-Host "  (could not list hosts: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- Monitors + states --------------------------------------------------------
Write-Host "`n=== Monitors (OBSDDOG-*) and states ===" -ForegroundColor Cyan
try {
    $mons = Invoke-RestMethod -Uri "$base/monitor" -Headers $headers -Method Get -ErrorAction Stop
    $mrows = $mons | Where-Object { $_.name -like 'OBSDDOG-*' } |
        ForEach-Object { [pscustomobject]@{ Name=$_.name; Type=$_.type; State=$_.overall_state } }
    $mrows | Format-Table -AutoSize
    Save-Csv $mrows 'monitors'
} catch { Write-Host "  (could not list monitors: $($_.Exception.Message))" -ForegroundColor Yellow }

# --- SLO status ---------------------------------------------------------------
Write-Host "`n=== SLOs (OBSDDOG-*) ===" -ForegroundColor Cyan
try {
    $slos = Invoke-RestMethod -Uri "$base/slo" -Headers $headers -Method Get -ErrorAction Stop
    $srows = $slos.data | Where-Object { $_.name -like 'OBSDDOG-*' } |
        ForEach-Object { [pscustomobject]@{ Name=$_.name; Type=$_.type; Target=($_.thresholds.target -join ';') } }
    $srows | Format-Table -AutoSize
    Save-Csv $srows 'slos'
} catch { Write-Host "  (could not list SLOs: $($_.Exception.Message))" -ForegroundColor Yellow }

Write-Host "`nReport complete. Track host/monitor/SLO coverage per wave; investigate host-count growth (cost)." -ForegroundColor Cyan
