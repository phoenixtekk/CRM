<#
.SYNOPSIS
    HIPAACOMP-Remediation — Safe, targeted remediation for a named clinical
    endpoint (Intune + Defender).

.DESCRIPTION
    Performs safe, low-impact remediation for a single named device: re-evaluates
    Intune compliance (sync) and can trigger a Defender quick scan, to recover a
    device that has drifted out of compliance. SAFETY: defaults to read-only
    -WhatIf — it reports the action it WOULD take and changes nothing. It performs
    the action only when -Apply is supplied. No destructive operations; it never
    wipes, retires, deletes, or reconfigures policy.

    Phase: Operate / Remediate. Use after Validation flags a FAIL for a device.

.PARAMETER DeviceName
    Required. The exact device name to remediate.

.PARAMETER Action
    What to do: 'Sync' (re-evaluate compliance, default), 'DefenderScan' (quick
    scan), or 'Both'.

.PARAMETER Apply
    Switch. When present, performs the action. Omitted = -WhatIf preview only.

.EXAMPLE
    .\HIPAACOMP-Remediation.ps1 -DeviceName "CLIN-LT-014"
    # Preview only (read-only) - shows what would happen.

.EXAMPLE
    .\HIPAACOMP-Remediation.ps1 -DeviceName "CLIN-LT-014" -Action Both -Apply
    # Triggers sync + Defender quick scan on the named device.

.NOTES
    Healthcare Solutions — read-only.

    Defaults to -WhatIf; only -Apply performs the action. Requires the Microsoft
    Graph PowerShell SDK with scopes:
      DeviceManagementManagedDevices.ReadWrite.All (only used when -Apply),
      DeviceManagementManagedDevices.Read.All
    Record remediation actions in the evidence store under change control (R12).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $DeviceName,

    [ValidateSet("Sync", "DefenderScan", "Both")]
    [string] $Action = "Sync",

    [switch] $Apply
)

$ErrorActionPreference = 'Stop'
$mode = if ($Apply) { "APPLY" } else { "WHATIF (read-only preview)" }
Write-Host ("HIPAACOMP-Remediation - mode: {0}" -f $mode)

$scopes = @("DeviceManagementManagedDevices.Read.All")
if ($Apply) { $scopes += "DeviceManagementManagedDevices.ReadWrite.All" }

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome }
}
catch { Write-Error "Microsoft Graph connection failed: $($_.Exception.Message)"; return }

$baseUri = "https://graph.microsoft.com/v1.0"

# Resolve device
try {
    $resp = Invoke-MgGraphRequest -Method GET -Uri ("{0}/deviceManagement/managedDevices?`$filter=deviceName eq '{1}'&`$select=id,deviceName,operatingSystem,complianceState,isEncrypted" -f $baseUri, $DeviceName)
    $dev = $resp.value | Select-Object -First 1
}
catch { Write-Error "Could not query device: $($_.Exception.Message)"; return }

if (-not $dev) { Write-Warning "Device '$DeviceName' not found."; return }

Write-Host ("Target: {0}  OS={1}  Compliance={2}  Encrypted={3}" -f $dev.deviceName, $dev.operatingSystem, $dev.complianceState, [bool]$dev.isEncrypted)

$deviceId = $dev.id

function Invoke-Step {
    param([string]$Name, [string]$Uri, [string]$Body)
    if (-not $Apply) {
        Write-Host ("[WHATIF] Would POST {0}  ->  {1}" -f $Name, $Uri)
        return
    }
    try {
        if ($Body) { Invoke-MgGraphRequest -Method POST -Uri $Uri -Body $Body | Out-Null }
        else       { Invoke-MgGraphRequest -Method POST -Uri $Uri | Out-Null }
        Write-Host ("[APPLIED] {0}" -f $Name)
    }
    catch { Write-Warning ("[FAILED] {0}: {1}" -f $Name, $_.Exception.Message) }
}

if ($Action -in @("Sync", "Both")) {
    Invoke-Step -Name "syncDevice (re-evaluate compliance)" `
        -Uri ("{0}/deviceManagement/managedDevices/{1}/syncDevice" -f $baseUri, $deviceId)
}

if ($Action -in @("DefenderScan", "Both")) {
    $body = '{ "quickScan": true }'
    Invoke-Step -Name "windowsDefenderScan (quick)" `
        -Uri ("{0}/deviceManagement/managedDevices/{1}/windowsDefenderScan" -f $baseUri, $deviceId) `
        -Body $body
}

Write-Host ""
if ($Apply) {
    Write-Host "Remediation requested. Re-run HIPAACOMP-Validation.ps1 after an evaluation cycle to confirm PASS."
    Write-Host "Record this action (device, action, operator, time) in the evidence store under change control (R12)."
} else {
    Write-Host "No changes made (preview). Re-run with -Apply to perform the action."
}
