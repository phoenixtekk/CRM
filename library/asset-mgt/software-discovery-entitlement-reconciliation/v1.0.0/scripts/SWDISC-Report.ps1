<#
.SYNOPSIS
    SWDISC-Report.ps1 — build the reconciliation ledger (installed vs entitled per SKU) and the exception register.
.DESCRIPTION
    PURPOSE
        Normalizes the discovery inventory to SKUs, deduplicates per device + SKU, aggregates the
        installed quantity per SKU, and matches it against the entitlement register to produce:
          - "Reconciliation Ledger - SKU vs Entitlement - Validate" (installed, entitled, position).
          - "Exception Register - Unmatched & Edge Cases - Validate" (installs with no SKU, and SKUs
            with installs but no entitlement).
        Read-only: reads CSVs and writes report CSVs; changes no source system.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SWDISC-Report.ps1 `
            -InventoryCsv .\Installed-Software-Inventory.csv `
            -NormalizationMapCsv .\Normalization-Map.csv `
            -EntitlementRegisterCsv .\Entitlement-Register.csv `
            -LedgerCsv .\Reconciliation-Ledger.csv `
            -ExceptionCsv .\Exception-Register.csv
        Map columns: Publisher, Title, SKU.  Register columns: SKU, EntitledQty, Metric.
    EXPECTED RESULTS
        A console summary of over/under/balanced SKUs, plus the ledger and exception-register CSVs.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only reporting.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [Parameter(Mandatory)][string]$NormalizationMapCsv,
    [Parameter(Mandatory)][string]$EntitlementRegisterCsv,
    [string]$LedgerCsv = ".\Reconciliation-Ledger.csv",
    [string]$ExceptionCsv = ".\Exception-Register.csv"
)
foreach ($f in @($InventoryCsv,$NormalizationMapCsv,$EntitlementRegisterCsv)) { if (-not (Test-Path $f)) { throw "Not found: $f" } }

$inv = Import-Csv $InventoryCsv
$map = Import-Csv $NormalizationMapCsv
$reg = Import-Csv $EntitlementRegisterCsv

$lookup = @{}
foreach ($m in $map) { $k = ("{0}|{1}" -f $m.Publisher, $m.Title).ToLower().Trim(); if (-not $lookup.ContainsKey($k)) { $lookup[$k] = $m.SKU } }
$entitled = @{}
foreach ($r in $reg) { if ($r.SKU) { $entitled[$r.SKU] = [int]$r.EntitledQty } }

# Normalize + deduplicate on Device|SKU, then count installs per SKU.
$seen = New-Object System.Collections.Generic.HashSet[string]
$installPerSku = @{}
$exceptions = New-Object System.Collections.Generic.List[object]
foreach ($row in $inv) {
    $k = ("{0}|{1}" -f $row.Publisher, $row.Title).ToLower().Trim()
    $sku = $lookup[$k]
    if (-not $sku) {
        $exceptions.Add([pscustomobject]@{ Type='Unmatched-Install'; SKU=''; Source=$row.Source; Device=$row.Device; Publisher=$row.Publisher; Title=$row.Title; Version=$row.Version; Reason='No normalization rule resolved this title to a SKU' })
        continue
    }
    $dedupe = ("{0}|{1}" -f $row.Device, $sku).ToLower()
    if ($seen.Add($dedupe)) {
        if ($installPerSku.ContainsKey($sku)) { $installPerSku[$sku]++ } else { $installPerSku[$sku] = 1 }
    }
}

# Build the ledger across the union of installed and entitled SKUs.
$allSkus = New-Object System.Collections.Generic.HashSet[string]
foreach ($s in $installPerSku.Keys) { [void]$allSkus.Add($s) }
foreach ($s in $entitled.Keys)      { [void]$allSkus.Add($s) }

$ledger = New-Object System.Collections.Generic.List[object]
foreach ($sku in $allSkus) {
    $inst = if ($installPerSku.ContainsKey($sku)) { $installPerSku[$sku] } else { 0 }
    $ent  = if ($entitled.ContainsKey($sku))      { $entitled[$sku] }      else { 0 }
    $pos  = if ($inst -gt $ent) { 'Over-deployed' } elseif ($inst -lt $ent) { 'Under-deployed' } else { 'Balanced' }
    $ledger.Add([pscustomobject]@{ SKU=$sku; Installed=$inst; Entitled=$ent; Net=($ent - $inst); Position=$pos })
    if ($inst -gt 0 -and $ent -eq 0) {
        $exceptions.Add([pscustomobject]@{ Type='Installed-NoEntitlement'; SKU=$sku; Source=''; Device=''; Publisher=''; Title=''; Version=''; Reason='SKU has installs but no entitlement in the register' })
    }
}

$ledger = $ledger | Sort-Object Position, @{e='Net';Descending=$false}
Write-Host "=== Reconciliation Ledger — SKU vs Entitlement ===" -ForegroundColor Cyan
$ledger | Format-Table -AutoSize
$over  = @($ledger | Where-Object Position -eq 'Over-deployed').Count
$under = @($ledger | Where-Object Position -eq 'Under-deployed').Count
$bal   = @($ledger | Where-Object Position -eq 'Balanced').Count
Write-Host ("Over-deployed: {0}  Under-deployed: {1}  Balanced: {2}" -f $over,$under,$bal) -ForegroundColor Cyan
Write-Host ("Exceptions: {0}" -f $exceptions.Count) -ForegroundColor ($(if($exceptions.Count){'Yellow'}else{'Green'}))

$ledger     | Export-Csv -Path $LedgerCsv -NoTypeInformation
$exceptions | Export-Csv -Path $ExceptionCsv -NoTypeInformation
Write-Host ("Wrote ledger    : {0}" -f $LedgerCsv) -ForegroundColor Green
Write-Host ("Wrote exceptions: {0}" -f $ExceptionCsv) -ForegroundColor Green
