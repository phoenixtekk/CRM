<#
.SYNOPSIS
    IMGLIFE-Discovery.ps1 - discover the current provisioning, enrollment, and inventory state of a device.
.DESCRIPTION
    PURPOSE
        Inventories the local device's lifecycle-relevant state so you know how it is provisioned and
        managed: OS build and hardware identity (manufacturer/model/serial), Entra join + Intune
        (MDM) enrollment via dsregcmd, the Intune Management Extension service, and whether a
        Configuration Manager (SCCM) client is present (the imaging alternative). Run on a device to
        confirm where it sits in the procure -> deploy -> refresh -> retire flow.
    HOW TO RUN
        Elevated, on the device:
          powershell -ExecutionPolicy Bypass -File .\IMGLIFE-Discovery.ps1
    EXPECTED RESULTS
        A summary of OS, hardware identity, Entra/MDM enrollment state, Intune extension presence,
        and whether the ConfigMgr client is installed - so you can tell Autopilot/Intune-managed
        devices from task-sequence-imaged (ConfigMgr) ones.
.NOTES
    Infrastructure solution - the repeatable way. Read-only (no changes made).
#>
[CmdletBinding()]
param()

Write-Host "`n=== Device lifecycle discovery - $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# OS and hardware identity (the inventory keys).
$ci = Get-ComputerInfo -ErrorAction SilentlyContinue
$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
Write-Host "`n-- OS and hardware identity --" -ForegroundColor Cyan
Write-Host ("  OS           : {0} (build {1})" -f $ci.WindowsProductName, $ci.OsBuildNumber)
Write-Host ("  Manufacturer : {0}" -f $ci.CsManufacturer)
Write-Host ("  Model        : {0}" -f $ci.CsModel)
Write-Host ("  Serial       : {0}" -f $bios.SerialNumber)

# Entra join + MDM (Intune) enrollment state.
Write-Host "`n-- Entra join + MDM enrollment (dsregcmd) --" -ForegroundColor Cyan
try {
    $ds = (dsregcmd /status) 2>$null
    foreach ($key in 'AzureAdJoined', 'EnterpriseJoined', 'DomainJoined', 'MDMUrl', 'TenantName') {
        $line = $ds | Where-Object { $_ -match "^\s*$key\s*:" } | Select-Object -First 1
        if ($line) { Write-Host ("  {0}" -f $line.Trim()) }
    }
} catch {
    Write-Host "  dsregcmd unavailable: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Intune Management Extension (present on Intune-managed devices).
Write-Host "`n-- Intune Management Extension --" -ForegroundColor Cyan
$ime = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if ($ime) { Write-Host ("  Service present, status: {0}" -f $ime.Status) -ForegroundColor Green }
else      { Write-Host "  Not installed (device may not be Intune-managed yet)." -ForegroundColor Yellow }

# Configuration Manager client (the task-sequence imaging alternative).
Write-Host "`n-- Configuration Manager (SCCM) client --" -ForegroundColor Cyan
$ccm = Get-Service -Name CcmExec -ErrorAction SilentlyContinue
if ($ccm) { Write-Host ("  ConfigMgr client present, status: {0} (task-sequence imaging path)" -f $ccm.Status) -ForegroundColor Yellow }
else      { Write-Host "  No ConfigMgr client (cloud/Autopilot path)." -ForegroundColor DarkGray }

Write-Host "`nDiscovery complete. Use IMGLIFE-Validation.ps1 to confirm provisioning readiness." -ForegroundColor Green
