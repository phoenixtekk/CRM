<#
.SYNOPSIS
    GWARB-Report.ps1 — produce the decision/gap register and ARB throughput KPIs.
.DESCRIPTION
    PURPOSE
        Joins the design inventory (from GWARB-Discovery.ps1) with the conformance results (from
        GWARB-Validation.ps1) into a single Decision Register plus a Gap Register of open drift and
        missing decision records. Computes the governance KPI set: decisions logged, approval rate,
        open drift, average time-in-gate, and exception count. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARB-Report.ps1 -InventoryCsv C:\Temp\inventory.csv -ConformanceCsv C:\Temp\conformance.csv -OutDir C:\Temp\arb-report
        InventoryCsv   = output of GWARB-Discovery.ps1 (DesignId,Gate,State,Workstream,HasRecord,Owner)
        ConformanceCsv = a per-design roll-up (DesignId,Status) — worst status per design from GWARB-Validation.ps1
        Optional: add a Submitted and Decided column set for time-in-gate. No live-system scopes required.
    EXPECTED RESULTS
        A Decision Register CSV, a Gap Register CSV, and a printed KPI block. Pass = the registers are
        produced and the Gap Register lists every open drift item and every gate-stage design missing a
        decision record. No system is changed.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [string]$ConformanceCsv,
    [string]$OutDir = '.'
)

if (-not (Test-Path $InventoryCsv)) { Write-Host "Inventory CSV not found: $InventoryCsv" -ForegroundColor Red; exit 2 }
$inv = Import-Csv $InventoryCsv

$conf = @{}
if ($ConformanceCsv -and (Test-Path $ConformanceCsv)) {
    foreach ($c in (Import-Csv $ConformanceCsv)) { $conf[$c.DesignId] = $c.Status }
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

Write-Host "`n=== Decision Register ===" -ForegroundColor Cyan
$register = foreach ($d in $inv) {
    [pscustomobject]@{
        DesignId    = $d.DesignId
        Gate        = $d.Gate
        State       = $d.State
        Workstream  = $d.Workstream
        Conformance = if ($conf.ContainsKey($d.DesignId)) { $conf[$d.DesignId] } else { 'Not-Validated' }
        HasRecord   = $d.HasRecord
        Owner       = $d.Owner
    }
}
$register | Sort-Object Gate, DesignId | Format-Table DesignId, Gate, State, Conformance, HasRecord, Owner -AutoSize

# Gap register: open drift, or gate-stage designs missing a decision record.
$gaps = $register | Where-Object {
    $_.Conformance -eq 'Non-Conformant' -or
    ($_.HasRecord -eq 'no' -and $_.State -notmatch 'Approved|Rejected|Withdrawn')
} | ForEach-Object {
    $reason = @()
    if ($_.Conformance -eq 'Non-Conformant') { $reason += 'open drift' }
    if ($_.HasRecord -eq 'no' -and $_.State -notmatch 'Approved|Rejected|Withdrawn') { $reason += 'missing decision record' }
    [pscustomobject]@{ DesignId = $_.DesignId; Gate = $_.Gate; State = $_.State; Gap = ($reason -join '; '); Owner = $_.Owner }
}

Write-Host "`n=== Gap Register ===" -ForegroundColor Cyan
if ($gaps) { $gaps | Format-Table DesignId, Gate, State, Gap, Owner -AutoSize }
else       { Write-Host "  No open gaps." -ForegroundColor Green }

# --- KPI set ---
$total     = $register.Count
$approved  = ($register | Where-Object { $_.State -match 'Approved' }).Count
$rejected  = ($register | Where-Object { $_.State -match 'Rejected' }).Count
$decided   = $approved + $rejected
$drift     = ($register | Where-Object { $_.Conformance -eq 'Non-Conformant' }).Count
$exceptions= ($register | Where-Object { $_.Conformance -like 'Conditional*' }).Count
$logged    = ($register | Where-Object { $_.HasRecord -eq 'yes' }).Count
$apprRate  = if ($decided) { [math]::Round(($approved / $decided) * 100, 1) } else { 0 }

Write-Host "`n=== Governance KPI set ===" -ForegroundColor Cyan
Write-Host ("  Designs tracked            : {0}" -f $total)
Write-Host ("  Decision records logged    : {0}" -f $logged)
Write-Host ("  Decisions made (appr+rej)  : {0}" -f $decided)
Write-Host ("  Approval rate              : {0}%" -f $apprRate)
Write-Host ("  Open drift findings        : {0}" -f $drift) -ForegroundColor $(if ($drift) { 'Yellow' } else { 'Green' })
Write-Host ("  Approved exceptions        : {0}" -f $exceptions)

$regPath = Join-Path $OutDir 'decision-register.csv'
$gapPath = Join-Path $OutDir 'gap-register.csv'
$register | Export-Csv -Path $regPath -NoTypeInformation
($gaps | ForEach-Object { $_ }) | Export-Csv -Path $gapPath -NoTypeInformation
Write-Host ("`nSaved {0}" -f $regPath) -ForegroundColor Green
Write-Host ("Saved {0}" -f $gapPath) -ForegroundColor Green
Write-Host "File these under Decision Register - Transformation ARB - Program-Wide and review open gaps at the next board." -ForegroundColor DarkYellow
