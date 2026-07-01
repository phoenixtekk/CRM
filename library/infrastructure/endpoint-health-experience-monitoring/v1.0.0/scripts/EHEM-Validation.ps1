<#
.SYNOPSIS
    EHEM-Validation.ps1 — confirm this device is ready to report to Intune Endpoint analytics (read-only).
.DESCRIPTION
    PURPOSE
        Verifies the device is MDM-enrolled and that diagnostic data (telemetry) is at the Required
        level or higher, which Endpoint analytics needs to collect startup, reliability, and resource
        signals. Reports a clear PASS/FAIL.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\EHEM-Validation.ps1
    EXPECTED RESULTS
        "MONITORING READY" when MDM enrolled and diagnostic data is sufficient; otherwise "NOT READY"
        with the reason. Read-only — makes no changes. Exit 0 on pass, 1 on fail.
.NOTES
    Endpoint Health & Digital Experience Monitoring — Infrastructure. Read-only.
#>
[CmdletBinding()] param()

Write-Host "=== Endpoint analytics validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# MDM enrollment
$mdm = $false
try { $ds = & dsregcmd /status 2>$null; if ($ds -match 'MdmUrl\s*:\s*https') { $mdm = $true } } catch { }
Write-Host ("MDM enrolled        : {0}" -f ($(if($mdm){'YES'}else{'NO'}))) -ForegroundColor ($(if($mdm){'Green'}else{'Yellow'}))

# Diagnostic data level (>=1 Required is sufficient for Endpoint analytics)
$tel = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -ErrorAction SilentlyContinue).AllowTelemetry
$telOk = ($tel -ge 1) -or ($null -eq $tel)   # null = no policy forcing it below Required; Windows default is acceptable
Write-Host ("Diagnostic data >=Required : {0}  (value: {1})" -f ($(if($telOk){'YES'}else{'NO'})), ($(if($null -eq $tel){'not set by policy'}else{$tel}))) -ForegroundColor ($(if($telOk){'Green'}else{'Yellow'}))

# Device has booted recently enough to produce startup data
$boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime
if ($boot) { Write-Host ("Last restart        : {0}" -f $boot) }

if ($mdm -and $telOk) { Write-Host "`nResult: MONITORING READY" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT READY — enroll in MDM (EHEM-Remediation.ps1) and allow Required diagnostic data" -ForegroundColor Yellow; exit 1 }
