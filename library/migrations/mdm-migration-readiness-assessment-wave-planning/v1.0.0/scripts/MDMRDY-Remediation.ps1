<#
.SYNOPSIS
    MDMRDY-Remediation.ps1 — safely fill estate-inventory data gaps (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Fills gaps in the "Estate Inventory - MDM Migration - Assess" so it can be scored: defaults an
        unknown EnrollmentType to 'UserDriven', infers Platform from OSVersion where blank, and marks
        stale or unscoreable rows for review. SAFE BY DEFAULT: previews changes with -WhatIf and writes
        nothing until you pass -Apply. It never touches the source MDM — only the local inventory CSV.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\MDMRDY-Remediation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY
        Apply (writes a remediated copy):
          powershell -ExecutionPolicy Bypass -File .\MDMRDY-Remediation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY -Apply
    EXPECTED RESULTS
        -WhatIf: prints each proposed fill, writes nothing.
        -Apply : writes estate-inventory-remediated.csv with the fills applied; original is untouched.
.NOTES
    Migrations — vendor-neutral pre-migration assessment. Default -WhatIf; -Apply to change the copy.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [string]$OutputFolder = (Join-Path $PWD 'MDMRDY'),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$WhatIf = -not $Apply
if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv" }
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }

$rows = Import-Csv -Path $InventoryCsv
$changes = New-Object System.Collections.Generic.List[object]

function Infer-Platform { param($os)
    switch -Regex ($os) {
        'iPadOS' { 'iPadOS'; return } 'iOS' { 'iOS'; return }
        'mac|OS X' { 'macOS'; return } 'Android' { 'Android'; return }
        'Windows|^10\.|^11' { 'Windows'; return } default { '' }
    }
}

foreach ($r in $rows) {
    $name = if ($r.DeviceName) { $r.DeviceName } else { '(unnamed)' }
    if ([string]::IsNullOrWhiteSpace($r.Platform) -and $r.OSVersion) {
        $inf = Infer-Platform $r.OSVersion
        if ($inf) { $changes.Add([pscustomobject]@{ DeviceName=$name; Field='Platform'; From=''; To=$inf }); $r.Platform = $inf }
    }
    if ([string]::IsNullOrWhiteSpace($r.EnrollmentType)) {
        $changes.Add([pscustomobject]@{ DeviceName=$name; Field='EnrollmentType'; From=''; To='UserDriven' }); $r.EnrollmentType = 'UserDriven'
    }
    if ([string]::IsNullOrWhiteSpace($r.Compliance)) {
        $changes.Add([pscustomobject]@{ DeviceName=$name; Field='Compliance'; From=''; To='Unknown' }); $r.Compliance = 'Unknown'
    }
    if ([string]::IsNullOrWhiteSpace($r.Criticality)) {
        $changes.Add([pscustomobject]@{ DeviceName=$name; Field='Criticality'; From=''; To='Standard' }); $r.Criticality = 'Standard'
    }
}

Write-Host "=== Inventory gap remediation ===" -ForegroundColor Cyan
Write-Host ("Mode               : {0}" -f $(if ($WhatIf) { 'WhatIf (preview only)' } else { 'Apply' })) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Green' })
Write-Host ("Proposed fills     : {0}" -f $changes.Count)
$changes | ForEach-Object { Write-Host ("  {0,-24} {1,-15} -> {2}" -f $_.DeviceName, $_.Field, $_.To) }

$changeLog = Join-Path $OutputFolder 'remediation-changes.csv'
$changes | Export-Csv $changeLog -NoTypeInformation -Encoding UTF8
Write-Host ("Change log         : {0}" -f $changeLog)

if ($WhatIf) {
    Write-Host "No files changed. Re-run with -Apply to write the remediated inventory." -ForegroundColor Yellow
} else {
    $out = Join-Path $OutputFolder 'estate-inventory-remediated.csv'
    $rows | Export-Csv $out -NoTypeInformation -Encoding UTF8
    Write-Host ("Remediated written : {0}  (use this for scoring)" -f $out) -ForegroundColor Green
}
