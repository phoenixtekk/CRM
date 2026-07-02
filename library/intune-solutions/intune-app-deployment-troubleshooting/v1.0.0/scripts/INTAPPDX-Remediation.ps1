<#
.SYNOPSIS
    INTAPPDX-Remediation.ps1 — safely re-attempt a failed app install by forcing targeted device syncs (default -WhatIf).
.DESCRIPTION
    PURPOSE
        For an app and the devices that report failed, triggers a device sync so the
        Intune Management Extension re-attempts the pipeline (download, install, detect).
        This is the safe re-attempt/cleanup step after you have corrected the root-cause
        setting per the Diagnostic Playbook. It changes nothing on the app definition.
        Runs in preview mode by default and only shows the planned actions.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Remediation.ps1 -AppNameLike "your-app-name"
        Apply:
          powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Remediation.ps1 -AppNameLike "your-app-name" -WhatIf:$false

        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.ReadWrite.All
    EXPECTED RESULTS
        A list of failed devices that will be synced. In preview no change is made. When
        applied, each device is sent a sync action; re-run INTAPPDX-Validation.ps1 after a
        cycle to confirm the app reaches Installed/Detected.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; makes no change until you confirm.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string] $AppNameLike,
    [switch] $WhatIf = $true
)

$ErrorActionPreference = 'Stop'
# Honor -WhatIf default: unless the caller explicitly passes -WhatIf:$false, run in preview.
if ($WhatIf) { $WhatIfPreference = $true }

function Connect-Graph {
    $scopes = @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.ReadWrite.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-Graph
$base = 'https://graph.microsoft.com/beta'

$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100" |
        Where-Object { $_.displayName -like "*$AppNameLike*" }
if (-not $apps) { throw "No app found matching '$AppNameLike'." }

$targets = foreach ($app in $apps) {
    $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    $statuses | Where-Object installState -eq 'failed' | ForEach-Object {
        [pscustomobject]@{ AppName = $app.displayName; DeviceName = $_.deviceName; DeviceId = $_.deviceId; ErrorCode = $_.errorCode }
    }
}

if (-not $targets) { Write-Host "No devices in 'failed' state for the matched app(s). Nothing to re-attempt." -ForegroundColor Green; return }

Write-Host "Devices reporting 'failed' (candidates for re-attempt):" -ForegroundColor Cyan
$targets | Format-Table -AutoSize AppName, DeviceName, ErrorCode

if ($WhatIfPreference) {
    Write-Host "`nPREVIEW (-WhatIf): the above devices would be sent a sync action. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    return
}

foreach ($t in $targets) {
    if (-not $t.DeviceId) { Write-Host "Skipping $($t.DeviceName): no managed device id available." -ForegroundColor Yellow; continue }
    if ($PSCmdlet.ShouldProcess("$($t.DeviceName) [$($t.AppName)]", "Trigger device sync (re-attempt install)")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "$base/deviceManagement/managedDevices/$($t.DeviceId)/syncDevice" | Out-Null
            Write-Host "Sync triggered: $($t.DeviceName)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to trigger sync on $($t.DeviceName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`nDone. Allow a sync cycle, then run INTAPPDX-Validation.ps1 to confirm the app reaches Installed/Detected." -ForegroundColor Cyan
