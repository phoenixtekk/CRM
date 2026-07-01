<#
.SYNOPSIS
    EXOMIG-Report.ps1 - Migration status / throughput report for an Exchange Online
    tenant-to-tenant migration. READ-ONLY.

    PURPOSE:
        Summarize migration progress per wave - counts of completed / failed /
        in-progress mailboxes and total GB moved. Reads a status CSV exported from
        the migration engine (Quest On Demand, ShareGate, BitTitan, or native
        Get-MigrationUser output), or, with -FromTenant, reads native migration
        state live from the target tenant.

    HOW TO RUN:
        From an engine status export:
            .\EXOMIG-Report.ps1 -StatusCsv .\quest-status.csv -OutputFolder .\reports
        From native cross-tenant migration batches (connect to target first):
            .\EXOMIG-Report.ps1 -FromTenant -TargetUpn admin@target.onmicrosoft.com -OutputFolder .\reports

        Expected StatusCsv columns (case-insensitive, mapped flexibly):
            Wave, Identity, Status, SizeGB     (Status e.g. Completed/Failed/Syncing/Synced)

    EXPECTED RESULTS:
        A per-wave summary table, an overall summary, and a timestamped report CSV
        in -OutputFolder. No changes made.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding(DefaultParameterSetName='Csv')]
param(
    [Parameter(Mandatory, ParameterSetName='Csv')][string] $StatusCsv,
    [Parameter(Mandatory, ParameterSetName='Tenant')][switch] $FromTenant,
    [Parameter(ParameterSetName='Tenant')][string] $TargetUpn,
    [string] $OutputFolder = ".\reports"
)

$ErrorActionPreference = 'Stop'

function Normalize-Status {
    param([string] $s)
    switch -Regex ($s) {
        'complet|synced|finalized' { 'Completed'; break }
        'fail|error'               { 'Failed'; break }
        'sync|progress|active|stag' { 'InProgress'; break }
        default                    { if ($s) { $s } else { 'Unknown' } }
    }
}

$rows = New-Object System.Collections.Generic.List[object]

if ($PSCmdlet.ParameterSetName -eq 'Csv') {
    if (-not (Test-Path $StatusCsv)) { throw "Status CSV not found: $StatusCsv" }
    foreach ($r in Import-Csv $StatusCsv) {
        $rows.Add([pscustomobject]@{
            Wave     = if ($r.Wave) { $r.Wave } else { 'Unassigned' }
            Identity = $r.Identity
            Status   = Normalize-Status $r.Status
            SizeGB   = [double]($r.SizeGB)
        })
    }
}
else {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Write-Host "Connecting to TARGET tenant for native migration state..." -ForegroundColor Cyan
    if ($TargetUpn) { Connect-ExchangeOnline -UserPrincipalName $TargetUpn -ShowBanner:$false }
    else            { Connect-ExchangeOnline -ShowBanner:$false }
    try {
        foreach ($mu in Get-MigrationUser -ResultSize Unlimited) {
            $stat = $null
            try { $stat = Get-MigrationUserStatistics -Identity $mu.Identity -ErrorAction Stop } catch {}
            $gb = 0
            if ($stat -and $stat.BytesTransferred) {
                $gb = [math]::Round(($stat.BytesTransferred.ToBytes() / 1GB), 3)
            }
            $rows.Add([pscustomobject]@{
                Wave     = $mu.BatchId
                Identity = $mu.Identity
                Status   = Normalize-Status $mu.Status
                SizeGB   = $gb
            })
        }
    } finally {
        Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    }
}

if ($rows.Count -eq 0) { Write-Warning "No migration records found."; return }

# ---- Per-wave summary --------------------------------------------------------
$summary = $rows | Group-Object Wave | ForEach-Object {
    $g = $_.Group
    [pscustomobject]@{
        Wave       = $_.Name
        Total      = $g.Count
        Completed  = ($g | Where-Object Status -eq 'Completed').Count
        InProgress = ($g | Where-Object Status -eq 'InProgress').Count
        Failed     = ($g | Where-Object Status -eq 'Failed').Count
        GBMoved    = [math]::Round((($g | Measure-Object SizeGB -Sum).Sum), 2)
    }
}

Write-Host ""
Write-Host "==== MIGRATION STATUS BY WAVE ====" -ForegroundColor Green
$summary | Sort-Object Wave | Format-Table -AutoSize

$tot = [pscustomobject]@{
    Wave='ALL WAVES'; Total=$rows.Count
    Completed =($rows | Where-Object Status -eq 'Completed').Count
    InProgress=($rows | Where-Object Status -eq 'InProgress').Count
    Failed    =($rows | Where-Object Status -eq 'Failed').Count
    GBMoved   =[math]::Round((($rows | Measure-Object SizeGB -Sum).Sum),2)
}
Write-Host ("TOTAL: {0} mailboxes | {1} completed | {2} in progress | {3} failed | {4} GB moved" -f `
    $tot.Total,$tot.Completed,$tot.InProgress,$tot.Failed,$tot.GBMoved) -ForegroundColor Cyan

if ($tot.Failed -gt 0) {
    Write-Host ""
    Write-Host "FAILED mailboxes:" -ForegroundColor Red
    $rows | Where-Object Status -eq 'Failed' | Select-Object Wave, Identity | Format-Table -AutoSize
}

# ---- Persist -----------------------------------------------------------------
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $OutputFolder "migration-report-$stamp.csv"
$summary + $tot | Export-Csv $out -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host "Report written to: $out" -ForegroundColor Green
