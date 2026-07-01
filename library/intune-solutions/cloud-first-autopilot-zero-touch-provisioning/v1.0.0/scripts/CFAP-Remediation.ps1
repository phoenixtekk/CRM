<#
.SYNOPSIS
    CFAP-Remediation.ps1 — Safe remediation of failed cloud-first Autopilot provisioning.

PURPOSE
    Attempts safe, reversible fixes for a device that did not finish provisioning: force an MDM sync,
    re-trigger the management/enrollment scheduled tasks so apps and policy re-evaluate, and (via
    Microsoft Graph, optional) issue a device sync action to the Intune managed device. Runs in
    -WhatIf mode BY DEFAULT — it prints what it would do and changes nothing until you pass -Execute.

    This script does NOT unenroll, reset, wipe, or re-image. Those are deliberate manual actions.

HOW TO RUN
    Preview only (default, no changes):
        powershell -ExecutionPolicy Bypass -File .\CFAP-Remediation.ps1

    Apply the safe local remediation (force sync + re-run management tasks):
        .\CFAP-Remediation.ps1 -Execute

    Also send an Intune device-sync action via Graph (requires Microsoft Graph SDK +
    DeviceManagementManagedDevices.PrivilegedOperations.All):
        .\CFAP-Remediation.ps1 -Execute -GraphSync

EXPECTED RESULTS
    In default (-WhatIf) mode: a list of the remediation actions that WOULD run. With -Execute: an MDM
    sync is triggered and the management scheduled tasks are re-run; with -GraphSync a syncDevice
    action is posted to the managed device. Re-run CFAP-Validation.ps1 afterward to confirm.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$Execute,
    [switch]$GraphSync
)

$ErrorActionPreference = 'Stop'
# Default to WhatIf unless the operator explicitly passes -Execute.
if (-not $Execute) { $WhatIfPreference = $true }

function Invoke-Step {
    param([string]$Description, [scriptblock]$Action)
    if ($PSCmdlet.ShouldProcess($Description)) {
        try { & $Action; Write-Host ("DONE: {0}" -f $Description) -ForegroundColor Green }
        catch { Write-Warning ("FAILED: {0} -> {1}" -f $Description, $_.Exception.Message) }
    } else {
        Write-Host ("WHATIF: would {0}" -f $Description) -ForegroundColor Yellow
    }
}

Write-Host '=== CFAP Remediation (safe; default -WhatIf) ===' -ForegroundColor Cyan

# 1) Force MDM sync via the enrollment scheduled task(s)
Invoke-Step 'force MDM/Intune sync (PushLaunch scheduled task)' {
    $tasks = Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -EA SilentlyContinue |
             Where-Object { $_.TaskName -match 'PushLaunch|Schedule' }
    if (-not $tasks) { throw 'No EnterpriseMgmt sync tasks found (device may not be MDM enrolled).' }
    $tasks | ForEach-Object { Start-ScheduledTask -TaskPath $_.TaskPath -TaskName $_.TaskName }
}

# 2) Re-run device management/enrollment evaluation
Invoke-Step 're-run deviceenroller / mdm policy evaluation' {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList '/c /AutoEnrollMDM' -NoNewWindow -Wait -EA SilentlyContinue
}

# 3) Trigger a Windows Update / app re-scan (provisioning apps)
Invoke-Step 'trigger Windows Update scan (USO) for provisioning content' {
    Start-Process -FilePath "$env:WINDIR\System32\usoclient.exe" -ArgumentList 'StartScan' -NoNewWindow -EA SilentlyContinue
}

# 4) Optional Graph-side device sync action
if ($GraphSync) {
    Invoke-Step 'post Intune syncDevice action via Microsoft Graph' {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        if (-not (Get-MgContext)) {
            Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.PrivilegedOperations.All','DeviceManagementManagedDevices.Read.All' | Out-Null
        }
        $serial = (Get-CimInstance Win32_BIOS).SerialNumber
        $md = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$serial'").value
        if (-not $md) { throw "No managedDevice found for serial $serial." }
        $id = $md[0].id
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices('$id')/syncDevice" | Out-Null
    }
}

Write-Host "`nRe-run CFAP-Validation.ps1 to confirm the device is now compliant." -ForegroundColor Cyan
if (-not $Execute) { Write-Host 'No changes were made (default -WhatIf). Re-run with -Execute to apply.' -ForegroundColor Yellow }
