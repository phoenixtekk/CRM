<#
.SYNOPSIS
    COMGMT-Validation.ps1 — Per-device co-management state validation (READ-ONLY).

PURPOSE
    Confirms a Windows device is co-managed by Configuration Manager and Intune,
    and reports which authority owns each co-management workload (compliance,
    device configuration, Endpoint Protection, resource access, client apps,
    Office Click-to-Run, Windows Update). Makes no changes.

HOW TO RUN
    Run locally on a co-managed device in an elevated PowerShell session:
        .\COMGMT-Validation.ps1

EXPECTED RESULTS
    CoManaged = True when the device is enrolled in Intune alongside the
    Configuration Manager client, plus a per-workload list showing the authority
    (ConfigMgr or Intune) based on the co-management workload flags. Read-only.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

# Entra/MDM enrollment indicator.
$dsreg = & dsregcmd /status 2>$null
$mdmEnrolled = [bool]($dsreg | Select-String -Pattern 'MdmUrl\s*:\s*http')
$azureAdJoined = [bool]($dsreg | Select-String -Pattern 'AzureAdJoined\s*:\s*YES')

# ConfigMgr client present.
$ccmRunning = (Get-Service -Name 'CcmExec' -ErrorAction SilentlyContinue).Status -eq 'Running'

$coManaged = $mdmEnrolled -and $ccmRunning

# Co-management workload authority bitmask. ConfigMgr stores the enabled (moved
# to Intune) workloads as a flags value; a set bit means Intune owns that workload.
$flagsKey = 'HKLM:\SOFTWARE\Microsoft\CCM\CoManagementFlags'
$comgmtFlags = (Get-ItemProperty -Path $flagsKey -ErrorAction SilentlyContinue).ComanagementFlags

if ($null -eq $comgmtFlags) { $comgmtFlags = 0 }

# Workload bit values as documented for the co-management workload slider.
$workloads = [ordered]@{
    'Compliance policies'   = 0x01
    'Device configuration'  = 0x10
    'Endpoint Protection'   = 0x02
    'Resource access'       = 0x04
    'Client apps'           = 0x20
    'Office Click-to-Run'   = 0x40
    'Windows Update'        = 0x08
}

Write-Host "ComputerName : $env:COMPUTERNAME"
Write-Host "AzureAdJoined: $azureAdJoined"
Write-Host "MDM Enrolled : $mdmEnrolled"
Write-Host "ConfigMgr    : $ccmRunning"
Write-Host "CoManaged    : $coManaged"
Write-Host ''
Write-Host 'Workload authority (per slider):'

foreach ($w in $workloads.GetEnumerator()) {
    $owner = if (($comgmtFlags -band $w.Value) -ne 0) { 'Intune' } else { 'ConfigMgr' }
    '{0,-22} {1}' -f $w.Key, $owner
}

if (-not $coManaged) {
    Write-Warning 'Device does NOT appear co-managed. Confirm Intune enrollment and ConfigMgr client (see Troubleshooting A).'
}
