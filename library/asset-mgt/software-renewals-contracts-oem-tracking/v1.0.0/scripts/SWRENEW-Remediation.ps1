<#
.SYNOPSIS
    SWRENEW-Remediation.ps1 — safely fill missing renewal records and advance closed renewals.
.DESCRIPTION
    PURPOSE
        Fixes two repository gaps the lifecycle depends on, safely: (1) inserts placeholder values
        for missing fields (a default NoticePeriodDays and AutoRenew=No) so incomplete records are
        visible and trackable pending confirmation, and (2) for renewals marked closed this cycle,
        advances RenewalDate by one term so the next cycle is scheduled. Runs in preview mode by
        default (-WhatIf); writes only when -WhatIf is removed, and backs up the CSV first.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\SWRENEW-Remediation.ps1 -CsvPath .\repository.csv -WhatIf
        Apply changes:      powershell -ExecutionPolicy Bypass -File .\SWRENEW-Remediation.ps1 -CsvPath .\repository.csv
    EXPECTED RESULTS
        With -WhatIf: a list of the changes that WOULD be made, no file written. Without -WhatIf: a
        timestamped backup is written next to the CSV, then the repository is updated and saved.
.NOTES
    Software Asset Management — repeatable renewal/contract process. Default -WhatIf (safe).
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [int]$DefaultNoticePeriodDays = 30,
    [int]$TermMonths = 12
)

# Default to preview unless the caller explicitly passes -WhatIf:$false
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

Write-Host "=== Software Renewals — Remediation ===" -ForegroundColor Cyan
if (-not (Test-Path $CsvPath)) { Write-Host "Repository not found: $CsvPath" -ForegroundColor Red; exit 1 }

$rows = @(Import-Csv $CsvPath)
$changes = 0

foreach ($r in $rows) {
    # (1) fill missing tracking fields with safe placeholders
    if (-not $r.NoticePeriodDays) {
        if ($PSCmdlet.ShouldProcess($r.ContractId, "set NoticePeriodDays=$DefaultNoticePeriodDays (placeholder)")) {
            $r.NoticePeriodDays = $DefaultNoticePeriodDays; $changes++
        } else { $changes++ }
    }
    if (-not $r.AutoRenew) {
        if ($PSCmdlet.ShouldProcess($r.ContractId, "set AutoRenew=No (placeholder)")) {
            $r.AutoRenew = 'No'; $changes++
        } else { $changes++ }
    }
    # (2) advance a renewal marked closed this cycle (column 'Closed' = Yes)
    if ($r.PSObject.Properties.Name -contains 'Closed' -and $r.Closed -eq 'Yes' -and $r.RenewalDate) {
        $next = ([datetime]$r.RenewalDate).AddMonths($TermMonths).ToString('yyyy-MM-dd')
        if ($PSCmdlet.ShouldProcess($r.ContractId, "advance RenewalDate $($r.RenewalDate) -> $next and clear Closed")) {
            $r.RenewalDate = $next; $r.Closed = ''; $changes++
        } else { $changes++ }
    }
}

if ($WhatIfPreference) {
    Write-Host ("`nPreview only: {0} change(s) would be made. Re-run without -WhatIf to apply." -f $changes) -ForegroundColor Yellow
    exit 0
}

if ($changes -gt 0) {
    $backup = "$CsvPath.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item $CsvPath $backup -Force
    Write-Host ("Backup written: {0}" -f $backup) -ForegroundColor Green
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Applied {0} change(s) and saved {1}." -f $changes, $CsvPath) -ForegroundColor Green
} else {
    Write-Host "No changes needed." -ForegroundColor Green
}
