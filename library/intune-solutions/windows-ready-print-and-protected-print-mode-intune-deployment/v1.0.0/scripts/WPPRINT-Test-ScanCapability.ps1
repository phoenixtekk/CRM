<#
.SYNOPSIS
    Flag multifunction scanners that may lose function under Windows Protected Print mode unless they
    support the driverless scan standards (Mopria / eSCL).

.DESCRIPTION
    Phase 1 assessment. Enumerates imaging/scanner devices and WSD scan devices and probes each host for
    the eSCL endpoint (IPP-over-HTTP on port 80/443, path /eSCL/ScannerCapabilities) to indicate whether
    a driverless scan path exists. Scanners with no eSCL path are flagged as scan blockers — devices that
    should stay OUT of WPP scope until an eSCL-capable path/replacement exists.

.HOW TO RUN
    Run on a target device on the same network as the MFDs:
        .\WPPRINT-Test-ScanCapability.ps1
        .\WPPRINT-Test-ScanCapability.ps1 -ScannerHosts 10.0.0.50,10.0.0.51

.EXPECTED RESULT
    A per-device table indicating whether an eSCL scan endpoint responded, plus a CSV. Advisory — confirm
    scan support with the vendor.

.NOTES
    Windows Ready Print / WPP deployment — read-only assessment. Windows PowerShell 5.1+.
#>
[CmdletBinding()]
param(
    [string[]]$ScannerHosts,
    [string]$OutputPath = "."
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$computer = $env:COMPUTERNAME

# Build a candidate host list: explicit -ScannerHosts, else printer port hosts (MFDs print + scan).
$hosts = @()
if ($ScannerHosts) {
    $hosts = $ScannerHosts
} else {
    try {
        foreach ($p in (Get-Printer -ErrorAction Stop)) {
            $port = Get-PrinterPort -Name $p.PortName -ErrorAction SilentlyContinue
            if ($port -and $port.PrinterHostAddress) { $hosts += $port.PrinterHostAddress }
        }
    } catch { }
    $hosts = $hosts | Sort-Object -Unique
}

if (-not $hosts) {
    Write-Host "No scanner/printer host addresses found. Pass -ScannerHosts to probe specific devices." -ForegroundColor Yellow
    return
}

function Test-Escl {
    param([string]$HostName)
    foreach ($scheme in @('http','https')) {
        $uri = "{0}://{1}/eSCL/ScannerCapabilities" -f $scheme, $HostName
        try {
            $resp = Invoke-WebRequest -Uri $uri -TimeoutSec 4 -UseBasicParsing -ErrorAction Stop
            if ($resp.StatusCode -eq 200 -and ($resp.Content -match 'ScannerCapabilities')) { return $true }
        } catch { }
    }
    return $false
}

$rows = @()
foreach ($h in $hosts) {
    $escl = Test-Escl -HostName $h
    $rows += [pscustomobject]@{
        Computer      = $computer
        Host          = $h
        eSCL_Scan     = $escl
        Classification = if ($escl) { 'Driverless scan OK (eSCL responded)' } else { 'Scan blocker (no eSCL) — keep out of WPP scope until verified' }
    }
}

$csv = Join-Path $OutputPath "WPPRINT-ScanCapability-$computer-$stamp.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8
$rows | Format-Table Host, eSCL_Scan, Classification -AutoSize

$blockers = @($rows | Where-Object { -not $_.eSCL_Scan })
Write-Host ("`nPotential scan blockers (no eSCL response): {0} of {1}" -f $blockers.Count, $rows.Count) -ForegroundColor $(if($blockers.Count){'Yellow'}else{'Green'})
Write-Host "Advisory only — a non-response can mean eSCL is on a non-standard path or disabled. Confirm scan support with the vendor before excluding or including." -ForegroundColor Gray
Write-Host "Exported: $csv" -ForegroundColor Green
