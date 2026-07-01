<#
.SYNOPSIS
    WS1MAC-Validation.ps1 — per-device enrollment + parity check for migrated Macs (Intune, Graph).
.DESCRIPTION
    PURPOSE
        For a given migrated Mac (or all Macs in a migration ring group), confirms it is enrolled and
        managed by Intune and that the named parity objects applied: the settings-catalog parity
        policy, custom .mobileconfig parity profiles, and shell-script parity. Reports each object's
        state for the device so you can confirm parity before expanding. Read-only against Microsoft
        Graph (Intune).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1MAC-Validation.ps1 -DeviceName "MAC-001"
        powershell -ExecutionPolicy Bypass -File .\WS1MAC-Validation.ps1 -ParityNameLike "WS1MAC Parity"
        Requires the Microsoft Graph PowerShell SDK and these read scopes:
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        For each matched Mac: enrolled/managed-by status, and per parity object (settings catalog,
        custom profile, shell script) the device's applied state (succeeded / error / not applied).
        Nothing is changed.
.NOTES
    Migrations — Workspace ONE to Intune macOS. Read-only against Graph.
#>
[CmdletBinding()] param(
    [string]$DeviceName,
    [string]$ParityNameLike = 'WS1MAC Parity'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

# Resolve target Macs
$uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'&`$select=id,deviceName,managementAgent,enrolledDateTime,complianceState"
if ($DeviceName) { $uri = "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS' and deviceName eq '$DeviceName'&`$select=id,deviceName,managementAgent,enrolledDateTime,complianceState" }
$macs = (Invoke-MgGraphRequest -Method GET -Uri $uri).value
if (-not $macs) { Write-Host "No matching managed Mac found (check -DeviceName)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host "=== WS1->Intune macOS — per-device enrollment + parity ===" -ForegroundColor Cyan

# Pre-fetch parity objects once
$cps     = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies?`$filter=startswith(name,'$ParityNameLike')").value
$dcs     = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=startswith(displayName,'$ParityNameLike')").value
$scripts = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts").value | Where-Object { $_.displayName -like "$ParityNameLike*" }

foreach ($m in $macs) {
    Write-Host ("`nMac: {0}" -f $m.deviceName) -ForegroundColor Cyan
    Write-Host ("  Managed by   : {0}" -f $m.managementAgent) -ForegroundColor ($(if($m.managementAgent -match 'mdm'){'Green'}else{'Yellow'}))
    Write-Host ("  Enrolled     : {0}" -f $m.enrolledDateTime)
    Write-Host ("  Compliance   : {0}" -f $m.complianceState)

    Write-Host "  Settings-catalog parity:" -ForegroundColor Cyan
    foreach ($p in $cps) {
        $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$($p.id)/deviceStatuses").value | Where-Object { $_.deviceDisplayName -eq $m.deviceName }
        $state = if ($st) { $st.status } else { 'not applied' }
        Write-Host ("    - {0}: {1}" -f $p.name, $state)
    }
    Write-Host "  Custom .mobileconfig parity:" -ForegroundColor Cyan
    foreach ($p in $dcs) {
        $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($p.id)/deviceStatuses").value | Where-Object { $_.deviceDisplayName -eq $m.deviceName }
        $state = if ($st) { $st.status } else { 'not applied' }
        Write-Host ("    - {0}: {1}" -f $p.displayName, $state)
    }
    Write-Host "  Shell-script parity:" -ForegroundColor Cyan
    foreach ($s in $scripts) {
        $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceShellScripts/$($s.id)/deviceRunStates?`$expand=managedDevice").value | Where-Object { $_.managedDevice.deviceName -eq $m.deviceName }
        $state = if ($st) { $st.runState } else { 'not applied' }
        Write-Host ("    - {0}: {1}" -f $s.displayName, $state)
    }
}

Write-Host "`nValidation complete. For a ring-wide rollup, run WS1MAC-Report.ps1." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
