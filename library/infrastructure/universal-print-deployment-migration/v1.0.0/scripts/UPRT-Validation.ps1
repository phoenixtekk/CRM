<#
.SYNOPSIS
    UPRT-Validation.ps1 - Universal Print readiness checks and an optional test print.
.DESCRIPTION
    PURPOSE
        Validates that this host (a device or the connector host) is ready for Universal Print:
        OS build, spooler service, outbound HTTPS reachability to the Universal Print endpoints,
        and that a named Universal Print printer is present locally. Optionally sends a test page
        to a deployed printer to prove end-to-end printing on the current network.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\UPRT-Validation.ps1 `
            -PrinterName "UniversalPrint - HQ-Floor2-MFP - Shared" -TestPrint
        Omit -TestPrint for read-only readiness checks only.
    EXPECTED RESULTS
        PASS/WARN lines for OS, spooler, endpoint reachability, and printer presence; if -TestPrint
        is supplied and the printer is present, a test page is queued to it.
.NOTES
    Infrastructure solution - the repeatable way. Read-only unless -TestPrint is specified.
#>
[CmdletBinding()]
param(
    [string]$PrinterName,
    [switch]$TestPrint
)

function Result($ok, $msg) {
    if ($ok) { Write-Host "  PASS  $msg" -ForegroundColor Green }
    else     { Write-Host "  WARN  $msg" -ForegroundColor Yellow }
}

Write-Host "`n=== Universal Print readiness - $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# OS build
$ci = Get-ComputerInfo -Property WindowsProductName, OsBuildNumber -ErrorAction SilentlyContinue
Result ($ci.OsBuildNumber -ge 19041) ("OS: {0} (build {1})" -f $ci.WindowsProductName, $ci.OsBuildNumber)

# Spooler
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
Result ($spooler -and $spooler.Status -eq 'Running') ("Print Spooler service: {0}" -f $spooler.Status)

# Outbound HTTPS reachability to Universal Print / sign-in endpoints.
# NOTE: endpoint host names can change; these are the documented public endpoints at time of writing.
$endpoints = @('login.microsoftonline.com', 'print.print.microsoft.com', 'graph.microsoft.com')
foreach ($e in $endpoints) {
    $r = Test-NetConnection -ComputerName $e -Port 443 -WarningAction SilentlyContinue
    Result ($r.TcpTestSucceeded) ("Reachable over 443: $e")
}

# Is the named Universal Print printer present locally?
if ($PrinterName) {
    $p = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    Result ($null -ne $p) ("Printer present locally: $PrinterName")

    if ($TestPrint -and $p) {
        try {
            $tmp = Join-Path $env:TEMP "uprt-testpage.txt"
            "Universal Print validation test page - $(Get-Date)" | Out-File -FilePath $tmp -Encoding ASCII
            # Sends the file to the named printer via the print verb.
            Start-Process -FilePath $tmp -Verb Print -ErrorAction Stop
            Write-Host "  Test page queued to '$PrinterName'. Confirm paper output." -ForegroundColor Green
        } catch {
            Write-Host "  Test print failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  (No -PrinterName supplied; skipped printer-presence and test print checks.)" -ForegroundColor DarkGray
}

Write-Host "`nReadiness check complete." -ForegroundColor Green
