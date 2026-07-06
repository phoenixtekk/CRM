<#
.SYNOPSIS
    GWVEND-Validation.ps1 — score designs against the anti-lock-in criteria and check disposition state.
.DESCRIPTION
    PURPOSE
        Read-only conformance check over the vendor design register. It (1) scores every design on
        the four anti-lock-in criteria — portability, data ownership, standards conformance, exit
        criteria — from the register's Pass/Fail/Unknown fields; (2) confirms every entry has a
        disposition and that no build-status design is missing a passed criterion; and (3) flags any
        exception that is past its close date. Provide the register path as 'your-register.csv'
        (no angle brackets).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWVEND-Validation.ps1 -RegisterPath .\vendor-design-register.csv
        Optional: -DesignId GWVEND-001 to score a single design.
        No live-system access is required for scoring; the register file is the input.
    EXPECTED RESULTS
        PASS/FAIL lines per design against the four criteria, a list of undispositioned or
        non-conformant build-status designs, and any past-due exception. No changes are made.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$RegisterPath,
    [string]$DesignId
)

function Import-Register {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Register not found: $Path" }
    if ($Path -match '\.json$') { return @(Get-Content -Path $Path -Raw | ConvertFrom-Json) }
    return @(Import-Csv -Path $Path)
}

$criteria = @('Portability','DataOwnership','StandardsConformance','ExitCriteria')

Write-Host "`n=== Anti-Lock-In Validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$register = Import-Register -Path $RegisterPath
if ($DesignId) { $register = @($register | Where-Object { $_.DesignId -eq $DesignId }) }

$nonConformant = @()
$undispositioned = @()

foreach ($d in $register) {
    Write-Host ("`n• {0}  [{1}]  status: {2}" -f $d.Title, $d.DesignId, `
        ($(if($d.Status){$d.Status}else{'<unspecified>'}))) -ForegroundColor White

    $failed = @()
    $missing = @()
    foreach ($c in $criteria) {
        $val = if ($d.$c) { "$($d.$c)".Trim() } else { '' }
        switch -Regex ($val) {
            '^(Pass|PASS|Yes|Y|True)$'  { Write-Host ("    PASS  {0}" -f $c) -ForegroundColor Green }
            '^(Fail|FAIL|No|N|False)$'  { Write-Host ("    FAIL  {0}" -f $c) -ForegroundColor Red; $failed += $c }
            default                     { Write-Host ("    ????  {0} (not scored)" -f $c) -ForegroundColor Yellow; $missing += $c }
        }
    }

    $disp = if ($d.Disposition) { "$($d.Disposition)".Trim() } else { '' }
    if (-not $disp) { $undispositioned += $d.DesignId }

    # A design at build status must have all four criteria passed and an Approved disposition.
    $isBuild = ($d.Status -match 'build|approved|in-?progress')
    if ($isBuild -and ($failed.Count -gt 0 -or $missing.Count -gt 0 -or $disp -notmatch 'Approved')) {
        $nonConformant += [pscustomobject]@{
            DesignId = $d.DesignId; Title = $d.Title
            Failed = ($failed -join ','); Unscored = ($missing -join ','); Disposition = $disp
        }
    }
}

Write-Host "`n-- Summary --" -ForegroundColor Cyan
if ($undispositioned.Count) {
    Write-Host ("  WARN: {0} design(s) with NO disposition: {1}" -f $undispositioned.Count, ($undispositioned -join ', ')) -ForegroundColor Yellow
} else {
    Write-Host "  PASS: every design has a disposition." -ForegroundColor Green
}

if ($nonConformant.Count) {
    Write-Host ("  FAIL: {0} build-status design(s) not conformant:" -f $nonConformant.Count) -ForegroundColor Red
    $nonConformant | Format-Table DesignId, Failed, Unscored, Disposition -AutoSize -Wrap
} else {
    Write-Host "  PASS: no build-status design fails a criterion or lacks an Approved disposition." -ForegroundColor Green
}

# Past-due exceptions
Write-Host "`n-- Exceptions --" -ForegroundColor Cyan
$now = Get-Date
$pastDue = @($register | Where-Object {
    $_.ExceptionCloseDate -and ($_.ExceptionCloseDate -as [datetime]) -and ([datetime]$_.ExceptionCloseDate -lt $now)
})
if ($pastDue.Count) {
    Write-Host ("  WARN: {0} exception(s) past close date (standing lock-in debt):" -f $pastDue.Count) -ForegroundColor Yellow
    $pastDue | Format-Table DesignId, Title, @{n='CloseDate';e={([datetime]$_.ExceptionCloseDate).ToString('yyyy-MM-dd')}} -AutoSize
} else {
    Write-Host "  PASS: no past-due exceptions." -ForegroundColor Green
}
