<#
.SYNOPSIS
    Test each installed printer for driverless (Mopria / IPP class driver) readiness — reachability over
    IPP/IPPS and whether the Microsoft IPP Class Driver is available — classifying each as Ready-Print
    eligible or a blocker.

.DESCRIPTION
    Phase 1 assessment. For every printer with a TCP/IP or WSD port, probes the common IPP/IPPS ports
    (631 and 443) to indicate whether the device can be reached driverlessly, and confirms the Microsoft
    IPP Class Driver is present on the machine. This is an indicator, not a Mopria certification check —
    confirm certification with the printer vendor.

.HOW TO RUN
    Run on a target device on the same network as the printers:
        .\WPPRINT-Test-MopriaReadiness.ps1
        .\WPPRINT-Test-MopriaReadiness.ps1 -OutputPath C:\Temp

.EXPECTED RESULT
    A per-printer table with IPP/IPPS reachability and a Ready-Print eligibility classification, plus a CSV.

.NOTES
    Windows Ready Print / WPP deployment — read-only assessment. Windows PowerShell 5.1+.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = "."
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$computer = $env:COMPUTERNAME

$ippDriverPresent = $false
try {
    if (Get-PrinterDriver -ErrorAction Stop | Where-Object { $_.Name -like '*Microsoft IPP Class Driver*' }) {
        $ippDriverPresent = $true
    }
} catch { }
Write-Host ("Microsoft IPP Class Driver present: {0}" -f $ippDriverPresent) -ForegroundColor $(if($ippDriverPresent){'Green'}else{'Yellow'})
if (-not $ippDriverPresent) {
    Write-Host "  The IPP class driver ships with Windows by default; its absence is unusual — investigate before enabling WPP." -ForegroundColor Yellow
}

function Test-PortOpen {
    param([string]$HostName, [int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(1500, $false)
        if ($ok -and $client.Connected) { $client.EndConnect($iar); $client.Close(); return $true }
        $client.Close(); return $false
    } catch { return $false }
}

$rows = @()
try { $printers = Get-Printer -ErrorAction Stop } catch { $printers = @() }
foreach ($p in $printers) {
    $portHost = $null
    try {
        $port = Get-PrinterPort -Name $p.PortName -ErrorAction SilentlyContinue
        if ($port) { $portHost = $port.PrinterHostAddress }
    } catch { }
    if (-not $portHost) { $portHost = $p.PortName }

    $ipp = $false; $ipps = $false
    if ($portHost -and $portHost -match '\.' ) {
        $ipp  = Test-PortOpen -HostName $portHost -Port 631
        $ipps = Test-PortOpen -HostName $portHost -Port 443
    }
    $isIppDriver = ($p.DriverName -like '*Microsoft IPP Class Driver*')
    $eligible = ($isIppDriver -or $ipp -or $ipps)

    $rows += [pscustomobject]@{
        Computer      = $computer
        Printer       = $p.Name
        Host          = $portHost
        UsesIppDriver = $isIppDriver
        IPP_631       = $ipp
        IPPS_443      = $ipps
        Classification = if ($eligible) { 'Ready-Print eligible (verify Mopria cert)' } else { 'Blocker (no driverless path detected)' }
    }
}

$csv = Join-Path $OutputPath "WPPRINT-MopriaReadiness-$computer-$stamp.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8
$rows | Format-Table Printer, Host, UsesIppDriver, IPP_631, IPPS_443, Classification -AutoSize

$blockers = @($rows | Where-Object { $_.Classification -like 'Blocker*' })
Write-Host ("`nBlockers (no driverless path detected): {0} of {1}" -f $blockers.Count, $rows.Count) -ForegroundColor $(if($blockers.Count){'Yellow'}else{'Green'})
Write-Host "Note: reachability is an indicator only — confirm Mopria certification with the printer vendor and that IPP/IPPS is enabled on the device." -ForegroundColor Gray
Write-Host "Exported: $csv" -ForegroundColor Green
