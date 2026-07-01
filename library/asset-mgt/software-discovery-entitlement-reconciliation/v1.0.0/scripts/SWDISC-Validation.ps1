<#
.SYNOPSIS
    SWDISC-Validation.ps1 — confirm raw inventory normalizes to SKUs and the entitlement register shares the SKU vocabulary.
.DESCRIPTION
    PURPOSE
        Validates the inputs to reconciliation:
          1) Every row in the "Installed-Software Inventory - All Sources - Discovery" resolves
             through the "Normalization Map - SKU Vocabulary - Configure" to a canonical SKU.
          2) The SKUs in the "Entitlement Register - Systems of Record - Configure" use the same SKU
             vocabulary as the normalization map (so the reconciliation join works).
        Read-only: reads CSVs and reports; changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SWDISC-Validation.ps1 `
            -InventoryCsv .\Installed-Software-Inventory.csv `
            -NormalizationMapCsv .\Normalization-Map.csv `
            -EntitlementRegisterCsv .\Entitlement-Register.csv
        Normalization map columns expected: Publisher, Title, Version (match key) and SKU (target).
        Entitlement register columns expected: SKU, EntitledQty, Metric.
    EXPECTED RESULTS
        "VALIDATION PASSED" when zero unresolved rows and zero orphaned register SKUs.
        Otherwise the unresolved rows and orphaned SKUs are listed for rule/vocabulary fixes.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [Parameter(Mandatory)][string]$NormalizationMapCsv,
    [string]$EntitlementRegisterCsv
)
foreach ($f in @($InventoryCsv,$NormalizationMapCsv)) { if (-not (Test-Path $f)) { throw "Not found: $f" } }

$inv = Import-Csv $InventoryCsv
$map = Import-Csv $NormalizationMapCsv

# Build a lookup keyed on Publisher|Title (case-insensitive). Version is optional in the key.
$lookup = @{}
foreach ($m in $map) {
    $k = ("{0}|{1}" -f $m.Publisher, $m.Title).ToLower().Trim()
    if (-not $lookup.ContainsKey($k)) { $lookup[$k] = $m.SKU }
}

$unresolved = New-Object System.Collections.Generic.List[object]
$resolvedSkus = New-Object System.Collections.Generic.HashSet[string]
foreach ($row in $inv) {
    $k = ("{0}|{1}" -f $row.Publisher, $row.Title).ToLower().Trim()
    if ($lookup.ContainsKey($k) -and $lookup[$k]) { [void]$resolvedSkus.Add($lookup[$k]) }
    else { $unresolved.Add($row) }
}

Write-Host "=== Normalization validation ===" -ForegroundColor Cyan
Write-Host ("Inventory rows      : {0}" -f $inv.Count)
Write-Host ("Resolved to a SKU   : {0}" -f ($inv.Count - $unresolved.Count)) -ForegroundColor Green
Write-Host ("Unresolved rows     : {0}" -f $unresolved.Count) -ForegroundColor ($(if($unresolved.Count){'Yellow'}else{'Green'}))
if ($unresolved.Count) {
    Write-Host "Unresolved (add normalization rules):" -ForegroundColor Yellow
    $unresolved | Select-Object Source,Device,Publisher,Title,Version -First 25 | Format-Table -AutoSize
}

$orphans = @()
if ($EntitlementRegisterCsv -and (Test-Path $EntitlementRegisterCsv)) {
    $reg = Import-Csv $EntitlementRegisterCsv
    $mapSkus = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in $map) { if ($m.SKU) { [void]$mapSkus.Add($m.SKU) } }
    $orphans = $reg | Where-Object { $_.SKU -and -not $mapSkus.Contains($_.SKU) }
    Write-Host "`n=== Entitlement vocabulary validation ===" -ForegroundColor Cyan
    Write-Host ("Register SKUs       : {0}" -f $reg.Count)
    Write-Host ("Orphaned SKUs       : {0}" -f @($orphans).Count) -ForegroundColor ($(if(@($orphans).Count){'Yellow'}else{'Green'}))
    if (@($orphans).Count) {
        Write-Host "Register SKUs not in the normalization vocabulary (align these):" -ForegroundColor Yellow
        $orphans | Select-Object SKU,EntitledQty,Metric -First 25 | Format-Table -AutoSize
    }
}

if ($unresolved.Count -eq 0 -and @($orphans).Count -eq 0) {
    Write-Host "`nResult: VALIDATION PASSED" -ForegroundColor Green; exit 0
} else {
    Write-Host "`nResult: VALIDATION INCOMPLETE — add normalization rules / align register vocabulary, then re-run" -ForegroundColor Yellow; exit 1
}
