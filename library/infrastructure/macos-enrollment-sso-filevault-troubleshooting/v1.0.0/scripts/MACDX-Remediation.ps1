<#
.SYNOPSIS
    MACDX-Remediation.ps1 — safe device Sync to re-pull policy on a macOS device (defaults to WhatIf).
.DESCRIPTION
    PURPOSE
        Applies the safest, least-disruptive fix the Diagnostic Playbook calls for: trigger an Intune
        device Sync so the Mac re-pulls its enrollment profile, configuration profiles (incl. the SSO
        extension and FileVault policy), and re-reports compliance. It reads device state from
        Microsoft Graph, then issues only the low-risk Sync action. It defaults to -WhatIf and makes
        no change until you re-run with -WhatIf:$false. It never wipes, erases, resets, retires, or
        deletes anything.
    HOW TO RUN
        Preview (no change, default):
            powershell -ExecutionPolicy Bypass -File .\MACDX-Remediation.ps1 -DeviceName device-name-or-serial
        Apply after reviewing:
            powershell -ExecutionPolicy Bypass -File .\MACDX-Remediation.ps1 -DeviceName device-name-or-serial -WhatIf:$false

        Required Graph scopes:
            DeviceManagementManagedDevices.Read.All                    (read device)
            DeviceManagementManagedDevices.PrivilegedOperations.All    (Sync action)
    EXPECTED RESULTS
        With the default -WhatIf: prints the intended safe action (Sync) and makes NO change (PASS).
        With -WhatIf:$false on a pilot device: issues the Sync and reports success. Allow a few
        minutes for check-in, then re-run MACDX-Validation to confirm the layer.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Device name or serial to act on (substring match). Required.
    [Parameter(Mandatory = $true)]
    [string]$DeviceName,

    # Safe action to perform. Only Sync is offered — deliberately the least-disruptive action.
    [ValidateSet('Sync')]
    [string]$Action = 'Sync',

    # Optional tenant id, e.g. your-tenant-id. Leave blank for interactive/default tenant.
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

# Default to preview: if the caller did not pass -WhatIf, force WhatIf on so nothing changes by accident.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
}

$RequiredScopes = @(
    'DeviceManagementManagedDevices.Read.All',
    'DeviceManagementManagedDevices.PrivilegedOperations.All'
)

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Run: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        if ($TenantId) { Connect-MgGraph -Scopes $RequiredScopes -TenantId $TenantId | Out-Null }
        else { Connect-MgGraph -Scopes $RequiredScopes | Out-Null }
    }
    Write-Host ("Connected as {0}." -f (Get-MgContext).Account) -ForegroundColor Green
}

function Get-TargetDevice {
    param([string]$Name)
    $all = @()
    $next = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        $all += $resp.value
        $next = $resp.'@odata.nextLink'
    }
    $all | Where-Object { $_.deviceName -like "*$Name*" -or $_.serialNumber -like "*$Name*" } | Select-Object -First 1
}

try {
    if ($WhatIfPreference) {
        Write-Host "[PREVIEW MODE] -WhatIf is on by default. No changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    }

    Connect-Graph
    $device = Get-TargetDevice -Name $DeviceName
    if (-not $device) {
        Write-Warning "No macOS device matched '$DeviceName'."
        exit 1
    }

    Write-Host ("Target: {0} (serial {1}, primary user {2})" -f $device.deviceName, $device.serialNumber, $device.userPrincipalName) -ForegroundColor Cyan

    $actionUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/syncDevice"
    $target = "{0} on {1}" -f $Action, $device.deviceName

    if ($PSCmdlet.ShouldProcess($target, "Issue Intune device action '$Action'")) {
        Invoke-MgGraphRequest -Method POST -Uri $actionUri | Out-Null
        Write-Host ("Action '{0}' issued to {1}." -f $Action, $device.deviceName) -ForegroundColor Green
        Write-Host "Allow a few minutes for the Mac to check in, then re-run MACDX-Validation for the relevant -Check layer to confirm." -ForegroundColor Green
    }
    else {
        Write-Host ("[WhatIf] Would issue '{0}' to {1}. No change made." -f $Action, $device.deviceName) -ForegroundColor Yellow
    }
}
catch {
    Write-Error ("Remediation failed: {0}" -f $_.Exception.Message)
    exit 1
}
