<#
.SYNOPSIS
    TIER1LIC-Report.ps1 — calculate per-publisher position (consumption vs entitlement) and write
    the exposure register.
.DESCRIPTION
    PURPOSE
        Aggregates the mapped metric quantities per product and compares them to entitlements to
        produce the per-publisher licensing position: consumption required by the metric versus
        entitlement held, the resulting position (shortfall or headroom), an exposure quantity, and a
        severity. Output is the per-publisher exposure register. Read-only — it calculates from the
        files you supply and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TIER1LIC-Report.ps1 `
            -MappingCsv .\mapping-Oracle.csv -EntitlementCsv .\entitlements-Oracle.csv `
            -Publisher Oracle [-OutCsv .\exposure-register-Oracle.csv]
        MappingCsv columns (from Validation): Product, Metric, MetricQuantity, Unit, Flag
        EntitlementCsv columns: Product, Metric, Entitled   (Entitled = licenses/PVU/users held)
    EXPECTED RESULTS
        A per-product table of consumption, entitlement, position, exposure, and severity, plus the
        exposure register CSV. Flagged (unmapped) rows are reported as unknown exposure, not zero.
.NOTES
    White-label SAM tooling — Asset Mgt. Read-only. Entitlement quantities and exact metric
    definitions are governed by your contracts and the publisher; confirm there.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $MappingCsv,
    [Parameter(Mandatory)] [string] $EntitlementCsv,
    [Parameter(Mandatory)] [ValidateSet('Oracle','IBM','SAP')] [string] $Publisher,
    [string] $OutCsv
)

foreach ($f in @($MappingCsv, $EntitlementCsv)) { if (-not (Test-Path $f)) { Write-Error "File not found: $f"; return } }
$map  = Import-Csv -Path $MappingCsv
$ent  = Import-Csv -Path $EntitlementCsv

Write-Host "`n=== Licensing position & exposure — $Publisher ===" -ForegroundColor Cyan

# Report unmapped rows as unknown exposure so they are never silently counted as compliant.
$unknown = @($map | Where-Object { $_.Flag })
if ($unknown.Count) {
    Write-Host ("Unknown exposure: {0} unmapped row(s) — resolve in Validation:" -f $unknown.Count) -ForegroundColor Yellow
    $unknown | ForEach-Object { Write-Host ("   {0}: {1}" -f $_.Product, $_.Flag) -ForegroundColor Yellow }
}

# Sum consumption per product+metric from the mapped rows.
$consumption = $map | Where-Object { -not $_.Flag } |
    Group-Object Product, Metric | ForEach-Object {
        $parts = $_.Name -split ', '
        [pscustomobject]@{
            Product  = $parts[0]
            Metric   = $parts[1]
            Consumed = [math]::Round((($_.Group | Measure-Object MetricQuantity -Sum).Sum), 2)
            Unit     = ($_.Group | Select-Object -First 1).Unit
        }
    }

# Index entitlements by product+metric.
$entIndex = @{}
foreach ($e in $ent) { $entIndex["$($e.Product)|$($e.Metric)"] = [double]$e.Entitled }

$register = foreach ($c in $consumption) {
    $entitled = if ($entIndex.ContainsKey("$($c.Product)|$($c.Metric)")) { $entIndex["$($c.Product)|$($c.Metric)"] } else { 0 }
    $gap = [math]::Round($c.Consumed - $entitled, 2)        # positive = shortfall (exposure), negative = headroom
    $position = if ($gap -gt 0) { 'SHORTFALL' } elseif ($gap -lt 0) { 'Headroom' } else { 'Balanced' }
    $severity = if ($gap -le 0) { 'None' }
                elseif ($entitled -gt 0 -and ($gap / $entitled) -ge 0.25) { 'High' }
                elseif ($entitled -eq 0) { 'High' }
                elseif (($gap / $entitled) -ge 0.10) { 'Medium' }
                else { 'Low' }
    [pscustomobject]@{
        Publisher = $Publisher; Product = $c.Product; Metric = $c.Metric; Unit = $c.Unit
        Consumed = $c.Consumed; Entitled = $entitled
        Exposure = [math]::Max($gap, 0); Headroom = [math]::Max(-$gap, 0)
        Position = $position; Severity = $severity; Owner = ''; Disposition = ''
    }
}

$register | Format-Table Product, Metric, Consumed, Entitled, Exposure, Headroom, Position, Severity -AutoSize | Out-Host
$totalExp = ($register | Measure-Object Exposure -Sum).Sum
Write-Host ("Products in shortfall: {0}" -f (@($register | Where-Object { $_.Position -eq 'SHORTFALL' }).Count)) -ForegroundColor $(if($totalExp){'Yellow'}else{'Green'})
Write-Host  "Assign an Owner and Disposition (remediate / acquire / accept-and-budget) to each shortfall row." -ForegroundColor Cyan

if ($OutCsv) { $register | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8; Write-Host "Exposure register written: $OutCsv" -ForegroundColor Green }
