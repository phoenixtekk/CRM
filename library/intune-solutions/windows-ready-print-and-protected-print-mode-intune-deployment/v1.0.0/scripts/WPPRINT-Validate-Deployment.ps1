<#
.SYNOPSIS
    Post-deployment validation for Windows Protected Print mode: confirm WPP is enabled, no third-party
    print drivers remain, and printers are using the Microsoft IPP Class Driver.

.DESCRIPTION
    Phase 4/7 validation. Checks the WPP registry state, enumerates installed printers/drivers and
    reports any remaining third-party (non-IPP-class) drivers, and confirms the target printer (if given)
    is bound to the Microsoft IPP Class Driver. Produces a pass/fail summary and a CSV of evidence.

.HOW TO RUN
    Run elevated on a validated device (or via Intune platform script / Proactive Remediation):
        .\WPPRINT-Validate-Deployment.ps1
        .\WPPRINT-Validate-Deployment.ps1 -TestPrinter "Contoso-MFD-3rdFloor"

.EXPECTED RESULT
    PASS when WPP is enabled and all printers use the IPP class driver; WARN listing any third-party
    drivers still present.

.NOTES
    Windows Ready Print / WPP deployment — read-only validation. Windows PowerShell 5.1+.
#>
[CmdletBinding()]
param(
    [string]$TestPrinter,
    [string]$OutputPath = "."
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$computer = $env:COMPUTERNAME
$pass = $true

# 1) WPP enabled?
$key = 'HKLM:\Software\Policies\Microsoft\Windows NT\Printers\WPP'
$wppEnabled = $false
try {
    $v = (Get-ItemProperty -Path $key -Name 'WindowsProtectedPrintGroupPolicyState' -ErrorAction Stop).WindowsProtectedPrintGroupPolicyState
    if ($v -eq 1) { $wppEnabled = $true }
} catch { }
Write-Host ("[{0}] WPP enabled" -f $(if($wppEnabled){'PASS'}else{'FAIL'})) -ForegroundColor $(if($wppEnabled){'Green'}else{'Red'})
if (-not $wppEnabled) { $pass = $false }

# 2) Remaining third-party drivers?
$thirdParty = @()
try {
    $thirdParty = @(Get-PrinterDriver -ErrorAction Stop | Where-Object { $_.Name -notlike '*Microsoft IPP Class Driver*' -and $_.Name -notlike '*Microsoft*Print*' })
} catch { }
if ($thirdParty.Count -eq 0) {
    Write-Host "[PASS] No third-party print drivers present" -ForegroundColor Green
} else {
    Write-Host ("[WARN] Third-party drivers still present: {0}" -f $thirdParty.Count) -ForegroundColor Yellow
    $thirdParty | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Yellow }
}

# 3) Printers bound to the IPP class driver?
$printerRows = @()
try {
    foreach ($p in (Get-Printer -ErrorAction Stop)) {
        $ipp = ($p.DriverName -like '*Microsoft IPP Class Driver*')
        if (-not $ipp) { $pass = $false }
        $printerRows += [pscustomobject]@{
            Computer = $computer; Printer = $p.Name; Driver = $p.DriverName
            UsesIppClassDriver = $ipp
        }
    }
} catch { }
$printerRows | Format-Table Printer, Driver, UsesIppClassDriver -AutoSize

# 4) Test printer specifically
if ($TestPrinter) {
    $tp = $printerRows | Where-Object { $_.Printer -eq $TestPrinter }
    if ($tp) {
        Write-Host ("[{0}] Test printer '{1}' uses the IPP class driver" -f $(if($tp.UsesIppClassDriver){'PASS'}else{'FAIL'}), $TestPrinter) -ForegroundColor $(if($tp.UsesIppClassDriver){'Green'}else{'Red'})
        if (-not $tp.UsesIppClassDriver) { $pass = $false }
    } else {
        Write-Host "[WARN] Test printer '$TestPrinter' not found on this device." -ForegroundColor Yellow
    }
}

$csv = Join-Path $OutputPath "WPPRINT-Validation-$computer-$stamp.csv"
$printerRows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

Write-Host ("`nOVERALL: {0}" -f $(if($pass -and $wppEnabled){'PASS'}else{'REVIEW'})) -ForegroundColor $(if($pass -and $wppEnabled){'Green'}else{'Yellow'})
Write-Host "Exported: $csv" -ForegroundColor Green
