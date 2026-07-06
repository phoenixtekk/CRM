<#
.SYNOPSIS
    GWCHAT-Report.ps1 — render Teams -> Chat/Meet migration coverage and adoption.
.DESCRIPTION
    PURPOSE
        Produces the standing coverage/adoption report: channels mapped vs spaces created, users
        planned vs active, and per-wave coverage. It reads the channel-to-space mapping from a CSV
        (one row per channel with its target space and status) and optionally cross-checks the total
        source population against the Microsoft Teams / Microsoft 365 source through Microsoft Graph
        for the coverage denominator. Read-only against Graph — it modifies nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCHAT-Report.ps1 `
            -MappingCsv .\gwchat-mapping.csv -CsvPath .\gwchat-coverage.csv
        The mapping CSV should include columns: Team, Channel, Space, Wave, SpaceCreated (true/false),
        MembersActive (integer), MembersPlanned (integer), Status (Planned/InProgress/Complete).
        Requires the Microsoft Graph PowerShell SDK and User.Read.All (used only to read the source-user
        count for the coverage denominator; skipped if Graph is unavailable).
    EXPECTED RESULTS
        A per-wave coverage table (channels, spaces created, members active vs planned), program totals
        (spaces created vs mapped, users active, overall coverage %), and an optional CSV export. No
        source data is modified.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MappingCsv,
    [string]$CsvPath
)

if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
$map = @(Import-Csv -Path $MappingCsv)
if ($map.Count -eq 0) { throw "Mapping CSV has no rows: $MappingCsv" }

# Optional source population (coverage denominator) from Microsoft Graph.
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
    Write-Host ("Could not read source total from Graph ({0}); using mapping totals only." -f $_.Exception.Message) -ForegroundColor Yellow
}

# Per-wave rollup.
$byWave = $map | Group-Object Wave | Sort-Object Name
$waveRows = foreach ($w in $byWave) {
    $chan       = @($w.Group).Count
    $created    = @($w.Group | Where-Object { $_.SpaceCreated -match '^(?i:true|1|yes)$' }).Count
    $active     = ($w.Group | Measure-Object -Property MembersActive -Sum).Sum
    $planned    = ($w.Group | Measure-Object -Property MembersPlanned -Sum).Sum
    $pct        = if ($planned -gt 0) { [math]::Round(100 * $active / $planned, 1) } else { 0 }
    [pscustomobject]@{
        Wave           = $w.Name
        Channels       = $chan
        SpacesCreated  = $created
        MembersActive  = $active
        MembersPlanned = $planned
        AdoptionPct    = "$pct%"
    }
}

Write-Host "`n=== Teams -> Chat/Meet migration — per-wave coverage ===" -ForegroundColor Cyan
$waveRows | Format-Table -AutoSize

$totalChannels = $map.Count
$totalCreated  = @($map | Where-Object { $_.SpaceCreated -match '^(?i:true|1|yes)$' }).Count
$totalActive   = ($map | Measure-Object -Property MembersActive -Sum).Sum
$totalPlanned  = ($map | Measure-Object -Property MembersPlanned -Sum).Sum
$denominator   = if ($sourceTotal) { $sourceTotal } else { [int]$totalPlanned }
$spacePct      = if ($totalChannels -gt 0) { [math]::Round(100 * $totalCreated / $totalChannels, 1) } else { 0 }
$adoptPct      = if ($denominator -gt 0) { [math]::Round(100 * $totalActive / $denominator, 1) } else { 0 }

Write-Host "=== Program totals ===" -ForegroundColor Cyan
Write-Host ("Spaces created            : {0} of {1} channels ({2}%)" -f $totalCreated, $totalChannels, $spacePct) -ForegroundColor ($(if($spacePct -ge 100){'Green'}else{'Cyan'}))
Write-Host ("Users active in Chat/Meet : {0} of {1} ({2})" -f $totalActive, $denominator, ($(if($sourceTotal){'source total from Graph'}else{'planned total — Graph unavailable'})))
Write-Host ("Overall adoption          : {0}%" -f $adoptPct) -ForegroundColor ($(if($adoptPct -ge 100){'Green'}else{'Cyan'}))
$remaining = $totalChannels - $totalCreated
if ($remaining -gt 0) { Write-Host ("Channels still to create  : {0}" -f $remaining) -ForegroundColor Yellow }

if ($CsvPath) { $waveRows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved {0}" -f $CsvPath) }
