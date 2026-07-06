<#
.SYNOPSIS
    MACRUN-Remediation.ps1 — safe common Mac fixes for Intune-managed macOS (defaults to WhatIf).
.DESCRIPTION
    PURPOSE
        Applies the safe, least-disruptive common fixes the runbooks call for on a Mac: trigger an
        Intune device Sync (re-check-in / re-evaluate compliance), or Rotate the FileVault personal
        recovery key (generate and escrow a fresh key). It reads device state from Microsoft Graph,
        then issues only the low-risk Intune device action requested. It defaults to -WhatIf and makes
        no change until you re-run with -WhatIf:$false. It never wipes, erases, resets, retires, or
        deletes anything, and it never disables FileVault.
    HOW TO RUN
        Preview (no change, default):
            powershell -ExecutionPolicy Bypass -File .\MACRUN-Remediation.ps1 -DeviceName device-name-or-serial -Action Sync
        Apply after reviewing:
            powershell -ExecutionPolicy Bypass -File .\MACRUN-Remediation.ps1 -DeviceName device-name-or-serial -Action Sync -WhatIf:$false

        Required Graph scopes:
            DeviceManagementManagedDevices.Read.All   (read device)
            DeviceManagementManagedDevices.PrivilegedOperations.All   (Sync / Rotate FileVault key)
    EXPECTED RESULTS
        With the default -WhatIf: prints the intended safe action and makes NO change (PASS).
        With -WhatIf:$false on a pilot Mac: issues the chosen Intune action and reports success. For
        RotateFileVaultKey, re-run MACRUN-Validation afterward to confirm the NEW key is escrowed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Mac name or serial to act on (substring match). Required.
    [Parameter(Mandatory = $true)]
    [string]$DeviceName,

    # Safe action to perform. Sync is the default; RotateFileVaultKey escrows a fresh recovery key.
    [ValidateSet('Sync', 'RotateFileVaultKey')]
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

    $actionUri = switch ($Action) {
        'Sync'               { "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/syncDevice" }
        'RotateFileVaultKey' { "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($device.id)/rotateFileVaultKey" }
    }

    if ($Action -eq 'RotateFileVaultKey') {
        Write-Host "NOTE: RotateFileVaultKey generates and escrows a NEW personal recovery key. Confirm escrow with MACRUN-Validation afterward before retiring the old key. It does NOT disable FileVault." -ForegroundColor Yellow
    }

    $target = "{0} on {1}" -f $Action, $device.deviceName
    if ($PSCmdlet.ShouldProcess($target, "Issue Intune device action '$Action'")) {
        Invoke-MgGraphRequest -Method POST -Uri $actionUri | Out-Null
        Write-Host ("Action '{0}' issued to {1}." -f $Action, $device.deviceName) -ForegroundColor Green
        Write-Host "Allow a few minutes for the Mac to check in, then re-run MACRUN-Validation to confirm." -ForegroundColor Green
    }
    else {
        Write-Host ("[WhatIf] Would issue '{0}' to {1}. No change made." -f $Action, $device.deviceName) -ForegroundColor Yellow
    }
}
catch {
    Write-Error ("Remediation failed: {0}" -f $_.Exception.Message)
    exit 1
}
