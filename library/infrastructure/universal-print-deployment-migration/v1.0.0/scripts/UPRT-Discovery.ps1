<#
.SYNOPSIS
    UPRT-Discovery.ps1 - discover existing print servers, queues, and drivers.
.DESCRIPTION
    PURPOSE
        Inventories the current print environment using the PrintManagement module:
        installed printers (queues), their drivers, ports, and share/publish state, plus the
        installed driver list. Run on each print server so you know exactly what must be
        migrated to Universal Print and later retired.
    HOW TO RUN
        Elevated, on each print server:
        powershell -ExecutionPolicy Bypass -File .\UPRT-Discovery.ps1
        Optional: -ComputerName <server> to query a remote print server (needs RPC access).
    EXPECTED RESULTS
        A per-queue table (name, driver, port, shared/published) and the installed driver list,
        which becomes the registration plan for Universal Print.
.NOTES
    Infrastructure solution - the repeatable way. Read-only (no changes made).
    Requires the PrintManagement module (in-box on Windows with the Print role / RSAT).
#>
[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME
)

Import-Module PrintManagement -ErrorAction SilentlyContinue

Write-Host "`n=== Print environment discovery - $ComputerName ===" -ForegroundColor Cyan

try {
    $printers = Get-Printer -ComputerName $ComputerName -ErrorAction Stop
} catch {
    Write-Host "Could not enumerate printers on $ComputerName : $($_.Exception.Message)" -ForegroundColor Yellow
    return
}

Write-Host "`n-- Print queues --" -ForegroundColor Cyan
$printers |
    Select-Object Name, DriverName, PortName, Shared, ShareName, Published, Type |
    Format-Table -AutoSize

Write-Host "-- Per-queue configuration --" -ForegroundColor Cyan
foreach ($p in $printers) {
    try {
        $cfg = Get-PrintConfiguration -PrinterName $p.Name -ComputerName $ComputerName -ErrorAction Stop
        Write-Host ("  {0,-30} color={1}  duplex={2}  paper={3}" -f $p.Name, $cfg.Color, $cfg.DuplexingMode, $cfg.PaperSize)
    } catch {
        Write-Host ("  {0,-30} (configuration unavailable)" -f $p.Name) -ForegroundColor Yellow
    }
}

Write-Host "`n-- Installed drivers --" -ForegroundColor Cyan
try {
    Get-PrinterDriver -ComputerName $ComputerName -ErrorAction Stop |
        Select-Object Name, Manufacturer, PrinterEnvironment |
        Format-Table -AutoSize
} catch {
    Write-Host "  Driver list unavailable: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ("Summary: {0} queue(s) found on {1}." -f $printers.Count, $ComputerName) -ForegroundColor Green
Write-Host "Mark each printer as Universal Print-ready or connector-attached, then proceed to registration." -ForegroundColor Green
