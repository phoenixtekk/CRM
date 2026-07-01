<#
.SYNOPSIS
    EPICWS-Discovery.ps1 — Inventories a clinical workstation's printers, default printer, peripherals, and power settings.

.DESCRIPTION
    PURPOSE
        Reports, on the device it runs on, the current state relevant to Epic clinical-workstation
        standardization: installed printers (and order), the default printer, recognized clinical
        peripherals (signature pad / document scanner / badge reader, matched by driver/service name),
        and key power/display/timeout settings. Use during Assess (Implementation Step 1) to capture
        the pre-change baseline, and any time to inventory a device. Read-only.

    HOW TO RUN
        On the device, in a normal PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\EPICWS-Discovery.ps1
        Optionally pass name patterns for your peripheral drivers/services:
            .\EPICWS-Discovery.ps1 -SignaturePadLike 'Topaz|SigPad' -ScannerLike 'Fujitsu|Scanner' -BadgeReaderLike 'RFIDeas|pcProx|Imprivata'

    EXPECTED RESULTS
        A printer table (with the default flagged), a peripheral-recognition table, and a power-settings
        summary. Save the output as the device's pre-change baseline and attach it to the change ticket.
        Use the printer names to confirm your unit mapping before deploying.

.NOTES
    Healthcare Solutions — read-only. Makes no changes. Reports device/printer/app state only; never
    captures patient data.
    Peripheral driver/service names are vendor-specific — pass the correct patterns from your hardware
    standard via -SignaturePadLike / -ScannerLike / -BadgeReaderLike.
#>
[CmdletBinding()]
param(
    [string]$SignaturePadLike = 'Topaz|SigLite|SigPad|Wacom|ePad',
    [string]$ScannerLike      = 'Scanner|Fujitsu|Canon DR|Kodak|TWAIN|WIA',
    [string]$BadgeReaderLike  = 'RFIDeas|pcProx|HID Global|Imprivata|OMNIKEY|proximity'
)

Write-Host "`n=== EPIC Clinical Workstation Discovery ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

# 1) Printers + default
try {
    $printers = Get-Printer -ErrorAction Stop
    $default  = (Get-CimInstance Win32_Printer -ErrorAction SilentlyContinue | Where-Object { $_.Default }).Name
    Write-Host "`n-- Installed printers --" -ForegroundColor Cyan
    $printers | Select-Object Name, DriverName, PortName,
        @{n='Default';e={ if ($_.Name -eq $default) { '* DEFAULT *' } else { '' } }} |
        Format-Table -AutoSize
    Write-Host ("Default printer: " + ($(if ($default) { $default } else { '(none set)' }))) -ForegroundColor Yellow
} catch {
    Write-Host "Could not enumerate printers: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2) Clinical peripherals (driver + service recognition)
function Test-Peripheral([string]$Label, [string]$Pattern) {
    $drv = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
           Where-Object { $_.DeviceName -match $Pattern -or $_.Description -match $Pattern } |
           Select-Object -First 1
    $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $Pattern -or $_.Name -match $Pattern } | Select-Object -First 1
    [pscustomobject]@{
        Peripheral = $Label
        Recognized = [bool]($drv -or $svc)
        Source     = $(if ($drv) { "Driver: $($drv.DeviceName)" } elseif ($svc) { "Service: $($svc.DisplayName)" } else { 'not detected' })
    }
}
Write-Host "`n-- Clinical peripherals --" -ForegroundColor Cyan
@(
    Test-Peripheral 'Signature pad'  $SignaturePadLike
    Test-Peripheral 'Document scanner' $ScannerLike
    Test-Peripheral 'Badge/prox reader' $BadgeReaderLike
) | Format-Table -AutoSize

# 3) Unknown devices (peripherals that failed to install a driver)
$unknown = Get-CimInstance Win32_PNPEntity -ErrorAction SilentlyContinue |
           Where-Object { $_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0 }
if ($unknown) {
    Write-Host "Devices with a driver problem (may include an unrecognized peripheral):" -ForegroundColor Yellow
    $unknown | Select-Object Name, ConfigManagerErrorCode | Format-Table -AutoSize
}

# 4) Power / display settings (clinical always-on check)
Write-Host "`n-- Power & display (AC / plugged in) --" -ForegroundColor Cyan
try {
    $scheme = (powercfg /getactivescheme) 2>$null
    Write-Host $scheme
    Write-Host "Standby (AC) / Monitor-timeout (AC):"
    (powercfg /q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE) 2>$null | Select-String 'Current AC Power Setting Index'
    (powercfg /q SCHEME_CURRENT SUB_VIDEO VIDEOIDLE)   2>$null | Select-String 'Current AC Power Setting Index'
} catch {
    Write-Host "Could not read power settings: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`nDone. Save this output as the pre-change baseline for the change ticket." -ForegroundColor Green
