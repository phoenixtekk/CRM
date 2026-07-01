<#
.SYNOPSIS
    EHEM-Discovery.ps1 — endpoint health monitoring readiness and current posture (read-only).
.DESCRIPTION
    PURPOSE
        Reports the OS build, Entra-join / MDM-enrollment state, diagnostic-data (telemetry) level,
        time since last restart, and basic resource snapshot — the signals that determine whether a
        device is ready to be monitored by Intune Endpoint analytics.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\EHEM-Discovery.ps1
    EXPECTED RESULTS
        OS build, join/MDM state, telemetry level, restart age, and a readiness verdict. Read-only —
        makes no changes.
.NOTES
    Endpoint Health & Digital Experience Monitoring — Infrastructure. Read-only.
#>
[CmdletBinding()] param()

Write-Host "`n=== Endpoint health monitoring — posture ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS                 : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

# Entra join / MDM enrollment
$joined = 'unknown'; $mdm = 'unknown'
try {
    $ds = & dsregcmd /status 2>$null
    if ($ds -match 'AzureAdJoined\s*:\s*YES') { $joined = 'AzureAD joined' }
    elseif ($ds -match 'DomainJoined\s*:\s*YES') { $joined = 'Domain joined' } else { $joined = 'not joined' }
    if ($ds -match 'MdmUrl\s*:\s*https') { $mdm = 'MDM enrolled' } else { $mdm = 'no MDM URL' }
} catch { }
Write-Host ("Join state         : {0}" -f $joined)
Write-Host ("MDM enrollment     : {0}" -f $mdm)

# Diagnostic data (telemetry) level — Endpoint analytics needs at least Required
$tel = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -ErrorAction SilentlyContinue).AllowTelemetry
$telText = switch ($tel) { 0 {'0 Security (too low)'} 1 {'1 Required (OK)'} 2 {'2 Enhanced'} 3 {'3 Optional'} default {'not set by policy (Windows default applies)'} }
Write-Host ("Diagnostic data    : {0}" -f $telText)

# Restart age (stale devices are a common degradation source)
$boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime
if ($boot) {
    $age = [int]((New-TimeSpan -Start $boot -End (Get-Date)).TotalDays)
    Write-Host ("Last restart       : {0}  ({1} days ago)" -f $boot, $age)
}

# Resource snapshot
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
if ($os) {
    $freeGB = [math]::Round($os.FreePhysicalMemory/1MB,1); $totGB = [math]::Round($os.TotalVisibleMemorySize/1MB,1)
    Write-Host ("Memory             : {0} GB free of {1} GB" -f $freeGB, $totGB)
}

# Readiness verdict
$ready = ($ci.OsBuildNumber) -and ($mdm -eq 'MDM enrolled') -and ($tel -ge 1 -or $null -eq $tel)
if ($ready) { Write-Host "`nReadiness          : READY for Endpoint analytics" -ForegroundColor Green }
else { Write-Host "`nReadiness          : NOT READY — enroll in MDM and allow Required diagnostic data" -ForegroundColor Yellow }
