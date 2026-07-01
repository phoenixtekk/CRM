<#
.SYNOPSIS
    LICCOMP-Discovery.ps1 — collect a deployment/usage inventory for the in-scope product.
.DESCRIPTION
    PURPOSE
        Builds the "Deployment Inventory - <Publisher/Product> - Discovered" input for the ELP.
        Reads installed-software data from a generic inventory CSV export (your discovery tool,
        Intune, or Configuration Manager) and/or the local machine, filters to the in-scope product,
        and writes a normalized per-install CSV. Read-only — it changes nothing.
    HOW TO RUN
        From a CSV export:
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Discovery.ps1 `
            -InventoryCsv .\inventory-export.csv -ProductName "Acme Designer" -CsvPath .\deployment.csv
        From the local machine (no CSV input):
          powershell -ExecutionPolicy Bypass -File .\LICCOMP-Discovery.ps1 -ProductName "Acme Designer" -CsvPath .\deployment.csv
    EXPECTED RESULTS
        A console summary of matched installs by edition/version and a per-install CSV
        (Device, Product, Edition, Version, Source) for the Deployment Inventory artifact.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only. Generic CSV in / CSV out.
#>
[CmdletBinding()]
param(
    [string]$InventoryCsv,
    [Parameter(Mandatory)] [string]$ProductName,
    [string]$CsvPath
)

Write-Host "`n=== License deployment discovery — product: $ProductName ===" -ForegroundColor Cyan
$rows = @()

if ($InventoryCsv) {
    if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv" }
    Write-Host "Reading inventory export: $InventoryCsv" -ForegroundColor Gray
    $data = Import-Csv -Path $InventoryCsv
    # Map common column names defensively; expect Device, Name/Product, Edition, Version.
    foreach ($r in $data) {
        $name = $r.Product; if (-not $name) { $name = $r.Name }; if (-not $name) { $name = $r.DisplayName }
        if ($name -and $name -like "*$ProductName*") {
            $dev = $r.Device; if (-not $dev) { $dev = $r.DeviceName }; if (-not $dev) { $dev = $r.ComputerName }
            $rows += [pscustomobject]@{
                Device  = $dev
                Product = $name
                Edition = $r.Edition
                Version = $r.Version
                Source  = "InventoryCsv"
            }
        }
    }
} else {
    Write-Host "No InventoryCsv supplied — reading local installed software." -ForegroundColor Gray
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($k in $keys) {
        Get-ItemProperty $k -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*$ProductName*" } |
            ForEach-Object {
                $rows += [pscustomobject]@{
                    Device  = $env:COMPUTERNAME
                    Product = $_.DisplayName
                    Edition = $_.DisplayName
                    Version = $_.DisplayVersion
                    Source  = "LocalRegistry"
                }
            }
    }
}

Write-Host ("Matched installs: {0}" -f $rows.Count) -ForegroundColor Cyan
if ($rows.Count -gt 0) {
    $rows | Group-Object Edition | Sort-Object Count -Descending |
        Select-Object Count, @{n='Edition';e={$_.Name}} | Format-Table -AutoSize
}
if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved deployment inventory: $CsvPath" -ForegroundColor Green }
