<#
.SYNOPSIS
    CMPFRAME-Report.ps1 — build the "RAF Coverage - Matrix" and shared-control leverage report (read-only).
.DESCRIPTION
    PURPOSE
        Produces the framework coverage report from the local artifacts CMPFRAME-Configuration.ps1 writes
        (RAF-Crosswalk-Register.csv, and optionally RAF-Evidence-Register.csv): per regulation, how many
        shared controls cover it and their implementation/evidence status; the shared-control leverage
        (how many regulations each control scores against); and the framework-specific gap list. Optionally
        snapshots Compliance Manager role-group separation for the report. Read-only — no tenant changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Report.ps1 -CrosswalkPath .\out\RAF-Crosswalk-Register.csv
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Report.ps1 -CrosswalkPath .\out\RAF-Crosswalk-Register.csv -EvidencePath .\out\RAF-Evidence-Register.csv -OutDir .\report -IncludeRoles
        The crosswalk CSV is the RAF-Crosswalk-Register.csv produced by CMPFRAME-Configuration.ps1 -Commit.
        -IncludeRoles connects Security & Compliance PowerShell (Connect-IPPSSession) to snapshot role groups.
    EXPECTED RESULTS
        A printed coverage matrix and leverage report, and (with -OutDir) RAF-Coverage-Matrix.csv written
        locally. Compliance Manager score/adequacy is NOT asserted here — coverage counts controls mapped
        and evidenced, not whether the evidence satisfies a regulation (a compliance/legal determination).
.NOTES
    Purview — Regulatory Assessment Framework. Read-only. Compliance Manager has no broad read API for
    assessment scores, so this report is built from the local crosswalk/evidence artifacts plus optional
    role-group reads — never from invented cmdlets. Verify template/score data in the Purview portal.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CrosswalkPath,
    [string]$EvidencePath,
    [string]$OutDir,
    [switch]$IncludeRoles
)

if (-not (Test-Path $CrosswalkPath)) { Write-Error "Crosswalk file not found: $CrosswalkPath (run CMPFRAME-Configuration.ps1 -Commit first)"; return }
try { $cw = @(Import-Csv -Path $CrosswalkPath -ErrorAction Stop) } catch { Write-Error "Could not read crosswalk: $($_.Exception.Message)"; return }
if ($cw.Count -eq 0) { Write-Error 'Crosswalk CSV has no rows.'; return }

$evidence = @{}
if ($EvidencePath -and (Test-Path $EvidencePath)) {
    foreach ($e in @(Import-Csv -Path $EvidencePath)) { $evidence[$e.Control] = $e }
}

function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# --- Shared-control leverage (map once, assess many) ---
Write-Section 'Shared-control leverage'
$leverage = $cw | Sort-Object { [int]$_.MappedCount } -Descending
foreach ($c in $leverage) {
    $n = [int]$c.MappedCount
    $tag = if ($n -ge 2) { 'shared' } else { 'single' }
    Write-Host ("  [{0}] {1}  ->  {2} regulation(s)" -f $tag, $c.Control, $n)
}
$sharedCount = @($cw | Where-Object { [int]$_.MappedCount -ge 2 }).Count
Write-Host ("  {0} of {1} controls are shared (cover >=2 regulations)." -f $sharedCount, $cw.Count) -ForegroundColor DarkGray

# --- Per-regulation coverage matrix ---
Write-Section 'RAF Coverage - Matrix'
$regMap = @{}
foreach ($c in $cw) {
    foreach ($reg in @(($c.Regulations) -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        if (-not $regMap.ContainsKey($reg)) { $regMap[$reg] = @() }
        $regMap[$reg] += $c.Control
    }
}
$matrix = @()
foreach ($reg in ($regMap.Keys | Sort-Object)) {
    $controls = $regMap[$reg]
    $evidenced = @($controls | Where-Object { $evidence.ContainsKey($_) -and $evidence[$_].TestStatus -and $evidence[$_].TestStatus -ne 'Not assessed' }).Count
    $row = [pscustomobject]@{
        Regulation      = $reg
        SharedControls  = $controls.Count
        Evidenced       = $evidenced
        AwaitingEvidence= ($controls.Count - $evidenced)
    }
    $matrix += $row
    Write-Host ("  {0}: {1} shared control(s), {2} evidenced, {3} awaiting evidence" -f $reg, $row.SharedControls, $row.Evidenced, $row.AwaitingEvidence)
}
Write-Host '  NOTE: "SharedControls" is coverage by the canonical set; the framework-specific GAP is whatever the regulation template requires beyond these — confirm the gap in the Purview portal assessment.' -ForegroundColor DarkGray

# --- Optional role-group separation snapshot ---
if ($IncludeRoles) {
    Write-Section 'Compliance Manager role separation (snapshot)'
    try {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-IPPSSession -WarningAction SilentlyContinue | Out-Null
        $groups = 'Compliance Manager Administrators','Compliance Manager Assessors','Compliance Manager Contributors','Compliance Manager Readers'
        foreach ($g in $groups) {
            try {
                $m = @(Get-RoleGroupMember -Identity $g -ErrorAction Stop)
                Write-Host ("  {0}: {1} member(s)" -f $g, $m.Count)
            } catch { Write-Host ("  {0}: not found / not readable — {1}" -f $g, $_.Exception.Message) -ForegroundColor DarkYellow }
        }
    } catch { Write-Host ("  Could not read role groups: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow }
}

# --- Write matrix ---
if ($OutDir) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    try { $matrix | Export-Csv -Path (Join-Path $OutDir 'RAF-Coverage-Matrix.csv') -NoTypeInformation -Encoding UTF8; Write-Host ("`nWrote RAF-Coverage-Matrix.csv to {0}" -f $OutDir) -ForegroundColor Green }
    catch { Write-Warning "Could not write matrix: $($_.Exception.Message)" }
}

Write-Host "`nCoverage counts controls mapped and evidenced — NOT whether the evidence satisfies a regulation (a compliance/records/legal determination)." -ForegroundColor DarkGray
