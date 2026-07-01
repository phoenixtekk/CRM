<#
.SYNOPSIS
    PSAUTO-Report.ps1 — fleet-wide Intune remediation results (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes how an Intune remediation (proactive remediation) is doing across the fleet: how
        many devices are without issues, remediated, or failed, so you can see convergence and chase
        laggards. Reads the remediation's per-device run states from Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PSAUTO-Report.ps1 -ScriptName "Endpoint Drift Remediation - Windows - Production" -CsvPath C:\Temp\psauto.csv
        Requires the Microsoft Graph SDK and DeviceManagementConfiguration.Read.All +
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A per-state count (Without issues / Remediated / Failed / Pending) for the named remediation
        and an optional per-device CSV (device, detection state, remediation state, last run time).
.NOTES
    Endpoint automation toolkit — the repeatable way. Read-only against Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ScriptName,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Find the remediation (device health script) by display name
$scripts = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceHealthScripts?`$filter=displayName eq '$ScriptName'").value
if (-not $scripts) { Write-Host "No remediation named '$ScriptName' found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
$id = $scripts[0].id

# Pull per-device run states
$rows = @()
$uri = "/beta/deviceManagement/deviceHealthScripts/$id/deviceRunStates?`$expand=managedDevice"
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($s in $r.value) {
        $rows += [pscustomobject]@{
            Device          = $s.managedDevice.deviceName
            DetectionState  = $s.detectionState
            RemediationState= $s.remediationState
            LastRun         = $s.lastStateUpdateDateTime
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host "`n=== Remediation: $ScriptName ===" -ForegroundColor Cyan
$rows | Group-Object RemediationState | Sort-Object Name | Select-Object Count, @{n='RemediationState';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total devices reporting: {0}" -f $rows.Count) -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
