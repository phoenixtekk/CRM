<#
.SYNOPSIS
    Inventory installed print drivers and printers, flagging third-party (V3/V4) drivers vs the built-in
    Microsoft IPP Class Driver — i.e., what Windows Protected Print mode (WPP) would remove.

.DESCRIPTION
    Phase 1 assessment. Lists each printer and its driver, marks whether the driver is the Microsoft IPP
    Class Driver (driverless / Ready-Print) or a third-party vendor driver, and summarizes how many
    printers would be affected if WPP were enabled.

.HOW TO RUN
    Run elevated on a target device (or deploy via an Intune platform script / Proactive Remediation):
        .\WPPRINT-Get-PrintDriverInventory.ps1
        .\WPPRINT-Get-PrintDriverInventory.ps1 -OutputPath C:\Temp

.EXPECTED RESULT
    A per-printer table (printer, driver, IPP-class vs third-party) plus a CSV, and a count of printers
    that rely on a third-party driver.

.NOTES
    Windows Ready Print / WPP deployment — read-only assessment. Windows PowerShell 5.1+.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = "."
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$computer = $env:COMPUTERNAME
$ippClassPattern = 'Microsoft IPP Class Driver'

$rows = @()
try {
    $printers = Get-Printer -ErrorAction Stop
} catch {
    Write-Warning "Get-Printer failed: $($_.Exception.Message)"
    $printers = @()
}

foreach ($p in $printers) {
    $driverName = $p.DriverName
    $isIpp = $false
    if ($driverName -like "*$ippClassPattern*") { $isIpp = $true }
    $rows += [pscustomobject]@{
        Computer     = $computer
        Printer      = $p.Name
        Driver       = $driverName
        PortName     = $p.PortName
        Shared       = $p.Shared
        Type         = $p.Type
        DriverKind   = if ($isIpp) { 'IPP-Class (Ready-Print)' } else { 'Third-party (WPP would remove)' }
        WppImpact    = if ($isIpp) { 'Keep' } else { 'At risk' }
    }
}

# Also list the installed driver store entries and their version (V3/V4 indication)
$driverRows = @()
try {
    foreach ($d in (Get-PrinterDriver -ErrorAction Stop)) {
        $isIpp = ($d.Name -like "*$ippClassPattern*")
        $driverRows += [pscustomobject]@{
            Computer   = $computer
            DriverName = $d.Name
            Version    = $d.MajorVersion
            Kind       = if ($isIpp) { 'IPP-Class (Ready-Print)' } else { 'Third-party' }
        }
    }
} catch {
    Write-Warning "Get-PrinterDriver failed: $($_.Exception.Message)"
}

$printerCsv = Join-Path $OutputPath "WPPRINT-PrinterInventory-$computer-$stamp.csv"
$driverCsv  = Join-Path $OutputPath "WPPRINT-DriverInventory-$computer-$stamp.csv"
$rows       | Export-Csv $printerCsv -NoTypeInformation -Encoding UTF8
$driverRows | Export-Csv $driverCsv  -NoTypeInformation -Encoding UTF8

$rows | Sort-Object WppImpact, Printer | Format-Table Printer, Driver, DriverKind -AutoSize
$atRisk = @($rows | Where-Object { $_.WppImpact -eq 'At risk' })
Write-Host ("`nThird-party-driver printers (WPP would remove): {0} of {1}" -f $atRisk.Count, $rows.Count) -ForegroundColor $(if ($atRisk.Count){'Yellow'}else{'Green'})
if ($atRisk.Count) {
    Write-Host "These need a Mopria/IPP or Universal Print replacement before this device enters WPP scope:" -ForegroundColor Yellow
    $atRisk | ForEach-Object { Write-Host "  - $($_.Printer)  [$($_.Driver)]" }
}
Write-Host "`nExported: $printerCsv" -ForegroundColor Green
Write-Host "Exported: $driverCsv" -ForegroundColor Green
