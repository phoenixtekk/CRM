<#
.SYNOPSIS
    GWVEND-Report.ps1 — review/finding report over the vendor design register.
.DESCRIPTION
    PURPOSE
        Read-only review report. Per design it presents the four anti-lock-in criteria results
        (portability, data ownership, standards conformance, exit criteria), the disposition
        (Approved / Approved-with-conditions / Rejected / none), any open conditions, and any
        exception with its close date. It ranks designs by review risk (failed or unscored criteria,
        no disposition, past-due exception) so the highest-attention designs surface first — the
        record an escalation needs. Provide the register path as 'your-register.csv'
        (no angle brackets).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWVEND-Report.ps1 -RegisterPath .\vendor-design-register.csv
        Optional: -CsvPath .\gwvend-findings.csv to export the finding rows.
        No live-system access is required; the register file is the input.
    EXPECTED RESULTS
        A ranked finding table (highest review risk first) with criteria results, disposition, open
        conditions, and exceptions. No changes are made.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$RegisterPath,
    [string]$CsvPath
)

function Import-Register {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Register not found: $Path" }
    if ($Path -match '\.json$') { return @(Get-Content -Path $Path -Raw | ConvertFrom-Json) }
    return @(Import-Csv -Path $Path)
}

$criteria = @('Portability','DataOwnership','StandardsConformance','ExitCriteria')
$now = Get-Date

Write-Host "`n=== Vendor Governance Finding Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$register = Import-Register -Path $RegisterPath
$findings = @()

foreach ($d in $register) {
    $risk = 0
    $reasons = @()
    $results = @{}
    foreach ($c in $criteria) {
        $val = if ($d.$c) { "$($d.$c)".Trim() } else { '' }
        if     ($val -match '^(Pass|PASS|Yes|Y|True)$')  { $results[$c] = 'Pass' }
        elseif ($val -match '^(Fail|FAIL|No|N|False)$')  { $results[$c] = 'Fail'; $risk += 3; $reasons += "fail:$c" }
        else                                             { $results[$c] = '?';    $risk += 2; $reasons += "unscored:$c" }
    }

    $disp = if ($d.Disposition) { "$($d.Disposition)".Trim() } else { '' }
    if (-not $disp) { $risk += 2; $reasons += 'no disposition' }
    if ($disp -match 'Reject') { $risk += 1; $reasons += 'rejected' }

    $exceptionNote = ''
    if ($d.ExceptionCloseDate -and ($d.ExceptionCloseDate -as [datetime])) {
        $close = [datetime]$d.ExceptionCloseDate
        $exceptionNote = $close.ToString('yyyy-MM-dd')
        if ($close -lt $now) { $risk += 2; $reasons += 'exception past due' }
    }

    $findings += [pscustomobject]@{
        Risk        = $risk
        DesignId    = $d.DesignId
        Title       = $d.Title
        Owner       = $d.Owner
        Portability = $results['Portability']
        DataOwn     = $results['DataOwnership']
        Standards   = $results['StandardsConformance']
        Exit        = $results['ExitCriteria']
        Disposition = ($(if($disp){$disp}else{'<none>'}))
        Conditions  = $d.Conditions
        Exception   = $exceptionNote
        Reasons     = ($reasons -join '; ')
    }
}

Write-Host "`n-- Findings (highest review risk first) --" -ForegroundColor Cyan
$findings | Sort-Object Risk -Descending |
    Format-Table Risk, DesignId, Owner, Portability, DataOwn, Standards, Exit, Disposition, Reasons -AutoSize -Wrap

$open = @($findings | Where-Object { $_.Conditions })
if ($open.Count) {
    Write-Host "`n-- Open conditions --" -ForegroundColor Cyan
    $open | Format-Table DesignId, Disposition, Conditions -AutoSize -Wrap
}

if ($CsvPath) {
    $findings | Sort-Object Risk -Descending | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} findings to {1}" -f $findings.Count, $CsvPath) -ForegroundColor Green
}
