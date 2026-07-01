<#
.SYNOPSIS
    TIER1LIC-Discovery.ps1 — assemble the tier-1 publisher deployment inventory from an export/CSV.
.DESCRIPTION
    PURPOSE
        Reads an installed-software / host inventory export (CSV) and produces the deployment
        baseline for one tier-1 publisher (Oracle / IBM / SAP): each install with host, product,
        edition, cores per host, virtualization host/cluster, and (for user metrics) authorized
        users. This is the input to metric mapping and position calculation. Read-only — it never
        contacts a publisher tool or changes a system; it operates only on the CSV you provide.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TIER1LIC-Discovery.ps1 `
            -InventoryCsv .\inventory.csv -Publisher Oracle [-OutCsv .\deployment-Oracle.csv]
        Expected CSV columns (generic; map your own export to these headers):
            Host, Publisher, Product, Edition, Cores, CoreFactor, Hypervisor, Cluster,
            AuthorizedUsers, UserType
    EXPECTED RESULTS
        A filtered, normalized deployment inventory for the publisher printed to the console and,
        if -OutCsv is given, written to CSV for the position worksheet.
.NOTES
    White-label SAM tooling — Asset Mgt. Read-only. Operates on inventory exports/CSV only;
    exact metric definitions are governed by your contracts and the publisher.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $InventoryCsv,
    [Parameter(Mandatory)] [ValidateSet('Oracle','IBM','SAP')] [string] $Publisher,
    [string] $OutCsv
)

if (-not (Test-Path $InventoryCsv)) { Write-Error "Inventory CSV not found: $InventoryCsv"; return }

Write-Host "`n=== Tier-1 deployment discovery — $Publisher ===" -ForegroundColor Cyan
$rows = Import-Csv -Path $InventoryCsv

# Filter to the requested publisher (case-insensitive); the export is assumed to tag each row.
$scope = $rows | Where-Object { $_.Publisher -and $_.Publisher.Trim().ToLower() -eq $Publisher.ToLower() }
if (-not $scope) { Write-Host "No rows for publisher '$Publisher' in the inventory." -ForegroundColor Yellow; return }

# Normalize: surface the fields each metric needs; blanks are left visible so Validation can flag them.
$deployment = foreach ($r in $scope) {
    [pscustomobject]@{
        Host            = $r.Host
        Publisher       = $Publisher
        Product         = $r.Product
        Edition         = $r.Edition
        Cores           = $r.Cores
        CoreFactor      = $r.CoreFactor
        Hypervisor      = $r.Hypervisor
        Cluster         = $r.Cluster
        AuthorizedUsers = $r.AuthorizedUsers
        UserType        = $r.UserType
    }
}

$deployment | Format-Table -AutoSize | Out-Host
Write-Host ("Installs found   : {0}" -f $deployment.Count) -ForegroundColor Green
Write-Host ("Distinct hosts   : {0}" -f (($deployment.Host | Sort-Object -Unique).Count))
Write-Host ("Distinct products: {0}" -f (($deployment.Product | Sort-Object -Unique).Count))

if ($OutCsv) { $deployment | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host "Written: $OutCsv" -ForegroundColor Green }
