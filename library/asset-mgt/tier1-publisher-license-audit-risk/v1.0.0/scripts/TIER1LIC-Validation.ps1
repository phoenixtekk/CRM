<#
.SYNOPSIS
    TIER1LIC-Validation.ps1 — map each deployment to its licensing metric and flag what cannot map.
.DESCRIPTION
    PURPOSE
        For one tier-1 publisher, applies the recorded metric to each deployment row and produces the
        deployment-to-metric mapping: a metric quantity per install (processor cores adjusted by core
        factor, value units per core, named users by type, or document volume for digital access).
        Rows that cannot be mapped (missing metric, missing cores/core factor, sub-capacity claimed
        without a prerequisite) are flagged — an unmapped row is unknown exposure. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TIER1LIC-Validation.ps1 `
            -InventoryCsv .\deployment-Oracle.csv -Publisher Oracle [-OutCsv .\mapping-Oracle.csv]
        CSV columns (from Discovery): Host, Publisher, Product, Edition, Cores, CoreFactor,
            Hypervisor, Cluster, AuthorizedUsers, UserType [, Metric, SubCapacityProven, ValueUnitPerCore]
        Metric is the governing metric per product from your contract; supply it in the CSV or rely
        on the generic inference below (which you MUST confirm against the contract).
    EXPECTED RESULTS
        Per row: a computed metric quantity, or a clear flag. A summary of mapped vs flagged rows.
.NOTES
    White-label SAM tooling — Asset Mgt. Read-only. Counting rules summarized at a general level;
    exact core factors, user categories, and rates are governed by your contracts and the publisher.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $InventoryCsv,
    [Parameter(Mandatory)] [ValidateSet('Oracle','IBM','SAP')] [string] $Publisher,
    [string] $OutCsv
)

if (-not (Test-Path $InventoryCsv)) { Write-Error "Inventory CSV not found: $InventoryCsv"; return }
$rows = Import-Csv -Path $InventoryCsv | Where-Object { $_.Publisher.Trim().ToLower() -eq $Publisher.ToLower() }
if (-not $rows) { Write-Host "No rows for publisher '$Publisher'." -ForegroundColor Yellow; return }

Write-Host "`n=== Deployment-to-metric mapping — $Publisher ===" -ForegroundColor Cyan

function Get-Number($v) { $n = 0.0; if ([double]::TryParse(($v -as [string]), [ref]$n)) { $n } else { $null } }

$mapped = foreach ($r in $rows) {
    $flag = $null
    $qty  = $null
    $unit = $null

    # Metric comes from the contract; if absent, infer the publisher's typical metric but flag for confirmation.
    $metric = if ($r.PSObject.Properties.Name -contains 'Metric' -and $r.Metric) { $r.Metric }
              elseif ($Publisher -eq 'Oracle') { 'Processor' }
              elseif ($Publisher -eq 'IBM')    { 'PVU' }
              else                             { 'NamedUser' }

    switch -Regex ($metric) {
        # Oracle Processor: cores * core factor. Virtualization/cluster rules affect which cores count
        # (decide host/cluster/guest counting per topology — recorded upstream, not invented here).
        'Processor' {
            $cores = Get-Number $r.Cores; $cf = Get-Number $r.CoreFactor
            if ($null -eq $cores)        { $flag = 'missing cores' }
            elseif ($null -eq $cf)       { $flag = 'missing core factor' }
            else { $qty = [math]::Round($cores * $cf, 2); $unit = 'processor licenses' }
        }
        # IBM PVU: value units per core * cores. Sub-capacity only if the metering prerequisite is proven.
        'PVU' {
            $cores = Get-Number $r.Cores
            $vupc  = if ($r.PSObject.Properties.Name -contains 'ValueUnitPerCore') { Get-Number $r.ValueUnitPerCore } else { $null }
            $sub   = ($r.PSObject.Properties.Name -contains 'SubCapacityProven' -and $r.SubCapacityProven -match '^(?i)(true|yes|1)$')
            if ($null -eq $cores)        { $flag = 'missing cores' }
            elseif ($null -eq $vupc)     { $flag = 'missing value-unit-per-core (from contract)' }
            else {
                if (-not $sub) { $flag = 'sub-capacity not proven — counted full capacity' }
                $qty = [math]::Round($cores * $vupc, 0); $unit = 'PVU'
            }
        }
        # Oracle NUP / SAP named-user: count authorized users (per-program minimums and SAP user types
        # are contract-governed — confirm the type basis there).
        'NamedUser|NUP' {
            $users = Get-Number $r.AuthorizedUsers
            if ($null -eq $users)        { $flag = 'missing authorized users' }
            else { $qty = $users; $unit = if ($r.UserType) { "named users ($($r.UserType))" } else { 'named users' } }
        }
        # SAP digital access: document volume (supplied as AuthorizedUsers count substitute or a Documents column).
        'Digital' {
            $docs = if ($r.PSObject.Properties.Name -contains 'Documents') { Get-Number $r.Documents } else { Get-Number $r.AuthorizedUsers }
            if ($null -eq $docs)         { $flag = 'missing document volume' }
            else { $qty = $docs; $unit = 'documents' }
        }
        default { $flag = "unknown metric '$metric'" }
    }

    [pscustomobject]@{
        Host = $r.Host; Product = $r.Product; Metric = $metric
        MetricQuantity = $qty; Unit = $unit; Flag = $flag
    }
}

$mapped | Format-Table -AutoSize | Out-Host
$flagged = @($mapped | Where-Object { $_.Flag })
Write-Host ("Mapped rows  : {0}" -f ($mapped.Count - $flagged.Count)) -ForegroundColor Green
if ($flagged.Count) {
    Write-Host ("Flagged rows : {0} — resolve before calculating position:" -f $flagged.Count) -ForegroundColor Yellow
    $flagged | ForEach-Object { Write-Host ("   {0} / {1}: {2}" -f $_.Host, $_.Product, $_.Flag) -ForegroundColor Yellow }
} else { Write-Host "All rows mapped to a metric." -ForegroundColor Green }

if ($OutCsv) { $mapped | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host "Written: $OutCsv" -ForegroundColor Green }
