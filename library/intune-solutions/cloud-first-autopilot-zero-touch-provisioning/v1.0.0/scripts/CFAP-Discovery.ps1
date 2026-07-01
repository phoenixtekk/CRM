<#
.SYNOPSIS
    CFAP-Discovery.ps1 — Autopilot / enrollment readiness discovery for Cloud-First Autopilot
    Zero-Touch Provisioning.

PURPOSE
    Read-only. Reports whether a device (and the tenant) is ready for cloud-first Autopilot
    provisioning: supported OS build/edition, join/enrollment state, hardware-hash capture, and
    whether the device is already registered as an Autopilot device in the tenant. Optionally exports
    the hardware hash CSV for manual registration.

HOW TO RUN
    Local readiness on the device being provisioned (no modules required for the local checks):
        powershell -ExecutionPolicy Bypass -File .\CFAP-Discovery.ps1

    Also export the hardware-hash CSV for manual Autopilot import:
        .\CFAP-Discovery.ps1 -ExportHash -OutputCsv C:\Temp\AutopilotHash.csv

    Also check tenant registration status via Microsoft Graph (requires the Microsoft Graph
    PowerShell SDK and DeviceManagementServiceConfig.Read.All):
        .\CFAP-Discovery.ps1 -CheckTenantRegistration

EXPECTED RESULTS
    A readiness summary: OS build/edition supported (Win10 21H2+/Win11, Pro/Ent/Edu), current join
    state (Entra joined / domain joined / MDM enrolled), whether a hardware hash was captured, and —
    with -CheckTenantRegistration — whether this device's serial is present in
    windowsAutopilotDeviceIdentities. Read-only; makes no changes.
#>
[CmdletBinding()]
param(
    [switch]$ExportHash,
    [string]$OutputCsv = "$env:TEMP\AutopilotHash.csv",
    [switch]$CheckTenantRegistration
)

$ErrorActionPreference = 'Stop'

function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

Write-Section 'Operating system'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
$build = [int]$os.BuildNumber
$serial = $bios.SerialNumber

[pscustomobject]@{
    ComputerName = $env:COMPUTERNAME
    OS           = $os.Caption
    Build        = $build
    Edition      = $edition
    Serial       = $serial
    Manufacturer = $cs.Manufacturer
    Model        = $cs.Model
} | Format-List

$supportedEdition = $edition -match 'Professional|Enterprise|Education'
$supportedBuild = $build -ge 19044   # Windows 10 21H2 = 19044; Windows 11 is higher
Write-Host ("OS edition supported : {0}" -f $supportedEdition)
Write-Host ("OS build supported   : {0} (build {1})" -f $supportedBuild, $build)

Write-Section 'Join / enrollment state (dsregcmd)'
$dsreg = & dsregcmd /status 2>$null
$aadJoined  = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$domJoined  = ($dsreg | Select-String 'DomainJoined\s*:\s*YES') -ne $null
$mdmUrl     = ($dsreg | Select-String 'MdmUrl\s*:\s*(\S+)')
Write-Host ("AzureAdJoined : {0}" -f $aadJoined)
Write-Host ("DomainJoined  : {0} (cloud-first expects NO)" -f $domJoined)
Write-Host ("MDM enrolled  : {0}" -f ([bool]$mdmUrl))

Write-Section 'Hardware hash capture'
$hashCaptured = $false
try {
    $session = Get-CimInstance -Namespace 'root\cimv2\mdm\dmmap' `
        -ClassName 'MDM_DevDetail_Ext01' -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
    if ($session.DeviceHardwareData) {
        $hashCaptured = $true
        Write-Host 'Hardware hash is available on this device.'
        if ($ExportHash) {
            [pscustomobject]@{
                'Device Serial Number' = $serial
                'Windows Product ID'   = ''
                'Hardware Hash'        = $session.DeviceHardwareData
            } | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
            Write-Host ("Exported hash CSV to {0}" -f $OutputCsv) -ForegroundColor Green
        }
    }
} catch {
    Write-Warning "Could not read hardware hash (run elevated, on the target device): $($_.Exception.Message)"
}

if ($CheckTenantRegistration) {
    Write-Section 'Tenant Autopilot registration (Microsoft Graph)'
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All' | Out-Null
        }
        $uri = "https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$serial')"
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
        if ($resp.value -and $resp.value.Count -gt 0) {
            Write-Host 'Device IS registered as an Autopilot device in the tenant:' -ForegroundColor Green
            $resp.value | ForEach-Object {
                [pscustomobject]@{
                    Serial            = $_.serialNumber
                    Model             = $_.model
                    GroupTag          = $_.groupTag
                    EnrollmentState   = $_.enrollmentState
                    DeploymentProfile = $_.deploymentProfileAssignmentStatus
                }
            } | Format-Table -AutoSize
        } else {
            Write-Warning "Device serial '$serial' is NOT registered as an Autopilot device. Import the hash (-ExportHash)."
        }
    } catch {
        Write-Warning "Graph check skipped/failed: $($_.Exception.Message)"
    }
}

Write-Section 'Readiness summary'
$ready = $supportedEdition -and $supportedBuild
[pscustomobject]@{
    SupportedEdition = $supportedEdition
    SupportedBuild   = $supportedBuild
    AzureAdJoined    = $aadJoined
    DomainJoined     = $domJoined
    HashCaptured     = $hashCaptured
    ReadyForCloudFirst = $ready
} | Format-List
if (-not $ready) { Write-Warning 'Device is not yet ready for cloud-first provisioning — resolve the items above.' }
