<#
.SYNOPSIS
    SWDISC-Remediation.ps1 — safely apply queued normalization-map fixes for unmatched titles (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Closes mapping gaps without touching any source system. It reads a queue of pending alias
        rules (Publisher, Title, SKU) — typically the unmatched rows triaged from the
        "Exception Register - Unmatched & Edge Cases - Validate" — and appends the new rules to the
        "Normalization Map - SKU Vocabulary - Configure", skipping any rule that already exists.
        SAFE BY DEFAULT: runs with -WhatIf and only previews the changes. Re-run with -WhatIf:$false
        to commit. A timestamped backup of the map is written before any write.
    HOW TO RUN
        Preview : powershell -ExecutionPolicy Bypass -File .\SWDISC-Remediation.ps1 `
                      -NormalizationMapCsv .\Normalization-Map.csv -PendingRulesCsv .\Pending-Rules.csv
        Commit  : powershell -ExecutionPolicy Bypass -File .\SWDISC-Remediation.ps1 `
                      -NormalizationMapCsv .\Normalization-Map.csv -PendingRulesCsv .\Pending-Rules.csv -WhatIf:$false
        Pending rules columns expected: Publisher, Title, SKU.
    EXPECTED RESULTS
        Preview: lists rules that WOULD be added. Commit: appends new rules and reports the count.
        Re-run SWDISC-Validation.ps1 afterward to confirm the previously unmatched rows now resolve.
.NOTES
    Workplace Marketplace — Asset Mgt. Only this script writes; it defaults to -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)][string]$NormalizationMapCsv,
    [Parameter(Mandatory)][string]$PendingRulesCsv
)
# Default to preview unless the caller explicitly passes -WhatIf:$false.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }
foreach ($f in @($NormalizationMapCsv,$PendingRulesCsv)) { if (-not (Test-Path $f)) { throw "Not found: $f" } }

$map     = @(Import-Csv $NormalizationMapCsv)
$pending = @(Import-Csv $PendingRulesCsv)

$existing = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in $map) { [void]$existing.Add( ("{0}|{1}" -f $m.Publisher, $m.Title).ToLower().Trim() ) }

$toAdd = New-Object System.Collections.Generic.List[object]
foreach ($p in $pending) {
    if (-not $p.SKU) { Write-Host ("  SKIP (no SKU): {0} / {1}" -f $p.Publisher,$p.Title) -ForegroundColor Yellow; continue }
    $k = ("{0}|{1}" -f $p.Publisher, $p.Title).ToLower().Trim()
    if ($existing.Contains($k)) { Write-Host ("  SKIP (exists): {0} / {1}" -f $p.Publisher,$p.Title); continue }
    $toAdd.Add([pscustomobject]@{ Publisher=$p.Publisher; Title=$p.Title; SKU=$p.SKU })
    [void]$existing.Add($k)
}

Write-Host ("`n{0} new normalization rule(s) to add." -f $toAdd.Count) -ForegroundColor Cyan
$toAdd | Format-Table -AutoSize

if ($toAdd.Count -eq 0) { Write-Host "Nothing to do." -ForegroundColor Green; return }

if ($PSCmdlet.ShouldProcess($NormalizationMapCsv, "Append $($toAdd.Count) normalization rule(s)")) {
    $backup = "$NormalizationMapCsv.$(Get-Date -Format yyyyMMdd-HHmmss).bak"
    Copy-Item $NormalizationMapCsv $backup
    Write-Host "Backup written: $backup" -ForegroundColor Green
    $toAdd | Export-Csv -Path $NormalizationMapCsv -NoTypeInformation -Append
    Write-Host ("Committed {0} rule(s) to {1}." -f $toAdd.Count, $NormalizationMapCsv) -ForegroundColor Green
    Write-Host "Re-run SWDISC-Validation.ps1 to confirm the rows now resolve." -ForegroundColor Green
}
else {
    Write-Host "Preview only (-WhatIf). Re-run with -WhatIf:`$false to commit." -ForegroundColor Yellow
}
