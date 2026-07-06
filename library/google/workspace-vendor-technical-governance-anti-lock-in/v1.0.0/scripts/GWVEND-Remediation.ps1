<#
.SYNOPSIS
    GWVEND-Remediation.ps1 — record a governance remediation action against a non-conformant design.
.DESCRIPTION
    PURPOSE
        Applies a reviewed governance decision to a design in the vendor design register: set the
        disposition (Approved / Approved-with-conditions / Rejected), attach a condition, or record a
        time-boxed exception with a close date. It is intended to be run after a design has been
        reviewed against the anti-lock-in criteria and escalated per the runbook — it updates the
        register of record, it does not change any live system. Defaults to -WhatIf, so a plain run
        only PREVIEWS the register change and writes nothing. Provide the register path as
        'your-register.csv' and the design id as 'GWVEND-001' (no angle brackets).
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\GWVEND-Remediation.ps1 -RegisterPath .\vendor-design-register.csv -DesignId GWVEND-001 -Disposition "Approved-with-conditions" -Condition "Adopt SCIM provisioning; document exit path"
        Apply after review:
            powershell -ExecutionPolicy Bypass -File .\GWVEND-Remediation.ps1 -RegisterPath .\vendor-design-register.csv -DesignId GWVEND-001 -Disposition "Approved-with-conditions" -Condition "Adopt SCIM provisioning; document exit path" -WhatIf:$false
        Optional: -ExceptionCloseDate 2026-09-30 to record a time-boxed exception.
    EXPECTED RESULTS
        In preview: the exact register fields that WOULD change for the design. When applied: the
        register file is updated in place (a .bak backup is written first). Re-run
        GWVEND-Validation.ps1 to confirm the design is now dispositioned/conformant.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$RegisterPath,
    [Parameter(Mandatory)] [string]$DesignId,
    [ValidateSet('Approved','Approved-with-conditions','Rejected')] [string]$Disposition,
    [string]$Condition,
    [string]$ExceptionCloseDate
)

if ($RegisterPath -match '\.json$') { throw "This helper edits CSV registers; export to CSV or edit JSON by hand." }
if (-not (Test-Path $RegisterPath)) { throw "Register not found: $RegisterPath" }

$register = @(Import-Csv -Path $RegisterPath)
$target = $register | Where-Object { $_.DesignId -eq $DesignId }
if (-not $target) { Write-Host "Design $DesignId not found in register." -ForegroundColor Yellow; return }

Write-Host "`n=== Vendor Governance Remediation — $(Get-Date -Format s) ===" -ForegroundColor Cyan
Write-Host ("Target: {0}  [{1}]" -f $target.Title, $target.DesignId) -ForegroundColor White

$changes = @()
if ($Disposition)        { $changes += "Disposition: '$($target.Disposition)' -> '$Disposition'" }
if ($Condition)          { $changes += "Conditions:  '$($target.Conditions)' -> '$Condition'" }
if ($ExceptionCloseDate) { $changes += "ExceptionCloseDate: '$($target.ExceptionCloseDate)' -> '$ExceptionCloseDate'" }
if (-not $changes) { Write-Host "Nothing to change — supply -Disposition, -Condition, or -ExceptionCloseDate." -ForegroundColor Yellow; return }

foreach ($chg in $changes) { Write-Host ("    {0}" -f $chg) }

if ($PSCmdlet.ShouldProcess("register entry $DesignId", "apply " + ($changes -join '; '))) {
    Copy-Item -Path $RegisterPath -Destination ($RegisterPath + '.bak') -Force
    if ($Disposition)        { $target.Disposition        = $Disposition }
    if ($Condition)          { $target.Conditions         = $Condition }
    if ($ExceptionCloseDate) { $target.ExceptionCloseDate = $ExceptionCloseDate }
    $register | Export-Csv -Path $RegisterPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`n  APPLIED. Backup written to {0}.bak" -f $RegisterPath) -ForegroundColor Green
    Write-Host "  Re-run GWVEND-Validation.ps1 to confirm." -ForegroundColor Cyan
} else {
    Write-Host "`n  [WhatIf] no changes written. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
}
