<#
.SYNOPSIS
    SAMPROG-Remediation.ps1 — safe remediation of SAM data gaps in the entitlement register.
.DESCRIPTION
    PURPOSE
        Cleans common data-quality gaps that block reconciliation, working only on a local export of
        `SAM Register - Entitlements - System of Record` (a CSV) — never on tenant data, contracts,
        or money. It flags duplicate product/SKU rows, rows missing an entitled quantity, and rows
        missing a renewal date, and (when applied) writes a normalized, de-duplicated copy you can
        re-import. Runs with -WhatIf by default, so it only reports unless you explicitly apply.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\SAMPROG-Remediation.ps1 `
                                -RegisterPath C:\SAM\entitlement-register.csv
        Apply:              ...\SAMPROG-Remediation.ps1 -RegisterPath C:\SAM\entitlement-register.csv `
                                -OutputPath C:\SAM\entitlement-register.clean.csv -WhatIf:$false
    EXPECTED RESULTS
        In preview: a list of duplicates and missing-field rows and what would change. When applied:
        a cleaned CSV at -OutputPath (duplicates collapsed, blanks flagged), leaving the original
        untouched.
.NOTES
    Asset Mgt — SAM Program. Local-file only; -WhatIf by default. The repeatable way.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][string]$RegisterPath,
    [string]$OutputPath
)

# Default to preview unless the caller turns -WhatIf off explicitly.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

if (-not (Test-Path $RegisterPath)) { throw "Register export not found: $RegisterPath" }
$rows = @(Import-Csv -Path $RegisterPath)
Write-Host "=== SAM Program — register remediation ===" -ForegroundColor Cyan
Write-Host ("Loaded {0} rows from {1}" -f $rows.Count, $RegisterPath)

# Duplicates by Product + SkuPartNumber
$dupGroups = $rows | Group-Object Product, SkuPartNumber | Where-Object { $_.Count -gt 1 }
Write-Host ("Duplicate product/SKU groups : {0}" -f @($dupGroups).Count) -ForegroundColor ($(if($dupGroups){'Yellow'}else{'Green'}))
foreach ($g in $dupGroups) { Write-Host ("  - {0}  (x{1})" -f $g.Name, $g.Count) -ForegroundColor Yellow }

# Missing entitled quantity
$missingQty = $rows | Where-Object { -not ($_.Entitled) -or $_.Entitled -notmatch '^\d+$' }
Write-Host ("Rows missing Entitled qty    : {0}" -f @($missingQty).Count) -ForegroundColor ($(if($missingQty){'Yellow'}else{'Green'}))

# Missing renewal date
$missingRenewal = $rows | Where-Object { -not ($_.RenewalDate) }
Write-Host ("Rows missing RenewalDate     : {0}" -f @($missingRenewal).Count) -ForegroundColor ($(if($missingRenewal){'Yellow'}else{'Green'}))

# Build a cleaned set: keep the first row per Product+SKU.
$clean = $rows | Group-Object Product, SkuPartNumber | ForEach-Object { $_.Group | Select-Object -First 1 }

if (-not $OutputPath) { $OutputPath = [System.IO.Path]::ChangeExtension($RegisterPath, 'clean.csv') }

if ($PSCmdlet.ShouldProcess($OutputPath, "Write cleaned register ($($clean.Count) rows, duplicates collapsed)")) {
    $clean | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host ("Wrote cleaned register: {0} ({1} rows)" -f $OutputPath, @($clean).Count) -ForegroundColor Green
    Write-Host "Review missing-field rows above and complete them in the system of record." -ForegroundColor Cyan
} else {
    Write-Host "`nPreview only (-WhatIf). Re-run with -WhatIf:`$false to write the cleaned register." -ForegroundColor Cyan
}
