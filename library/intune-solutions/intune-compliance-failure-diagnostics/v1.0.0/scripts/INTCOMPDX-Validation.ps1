<#
.SYNOPSIS
    INTCOMPDX-Validation.ps1 — read the per-device, per-setting compliance failure with the raw reason (read-only).
.DESCRIPTION
    PURPOSE
        For a named device (or all non-compliant devices), returns each failing setting
        with its state and the raw failure reason string, and flags whether the setting is
        built-in, a Custom compliance rule, or an Error (could-not-evaluate) state. This is
        the authoritative per-setting failure for diagnosis. Read-only. Replace the sample
        value your-device-name with a real device name.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDX-Validation.ps1 -DeviceName your-device-name

        Required Graph scopes:
            DeviceManagementManagedDevices.Read.All
            DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A list of failing settings per device with state (Not compliant / Error) and the
        reason. Empty failure set = the device passes (pass gate). Any authorization error
        means missing scopes/role.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$DeviceName,
    [switch]$AllNonCompliant,
    [string]$OutputCsv
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    $scopes = @(
        'DeviceManagementManagedDevices.Read.All',
        'DeviceManagementConfiguration.Read.All'
    )
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or -not ($scopes | Where-Object { $ctx.Scopes -contains $_ })) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-Graph

# Resolve target devices
if ($DeviceName) {
    $devices = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'" -f $DeviceName)
} elseif ($AllNonCompliant) {
    $devices = Invoke-GraphGetAll -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=complianceState eq 'noncompliant'"
} else {
    throw "Specify -DeviceName your-device-name or -AllNonCompliant."
}

if (-not $devices) { Write-Warning "No matching devices found."; return }

$rows = foreach ($d in $devices) {
    Write-Host "`n=== $($d.deviceName) [$($d.complianceState)] ===" -ForegroundColor Cyan

    # Per-policy compliance states for this device
    $states = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/deviceCompliancePolicyStates" -f $d.id)
    foreach ($s in $states) {
        # Per-setting states within the policy
        $settings = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/{0}/deviceCompliancePolicyStates/{1}/settingStates" -f $d.id, $s.id)
        foreach ($set in $settings) {
            if ($set.state -in @('nonCompliant', 'error', 'conflict')) {
                $isCustom = ($set.setting -like '*customCompliance*' -or $set.settingName -like '*Custom*')
                [pscustomobject]@{
                    Device      = $d.deviceName
                    Policy      = $s.displayName
                    Setting     = $set.settingName
                    State       = $set.state
                    RuleType    = if ($isCustom) { 'Custom' } elseif ($set.state -eq 'error') { 'Built-in (Error)' } else { 'Built-in' }
                    Reason      = $set.errorDescription
                }
            }
        }
    }
}

if ($rows) {
    $rows | Format-Table -AutoSize -Wrap
    if ($OutputCsv) {
        $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host "`nSaved failures to $OutputCsv" -ForegroundColor Green
    }
} else {
    Write-Host "`nNo failing settings found — device(s) pass per-setting validation." -ForegroundColor Green
}

Write-Host "`nValidation complete (read-only)." -ForegroundColor Green
