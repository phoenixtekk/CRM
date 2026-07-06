<#
.SYNOPSIS
    MACDX-Set-ScopeTargeting.ps1 — build/adjust pilot target groups for macOS devices (defaults to WhatIf).
.DESCRIPTION
    PURPOSE
        Fixes the group-based targeting the Diagnostic Playbook relies on: ensures a pilot/target
        Entra security group exists and adds the named macOS device (its Entra device object) to it,
        so a device starts receiving the SSO-extension, FileVault, or compliance-supporting profile
        it was missing. It reads current membership from Microsoft Graph and only adds the member you
        name. It defaults to -WhatIf and makes no change until you re-run with -WhatIf:$false. It
        never removes members or deletes groups.
    HOW TO RUN
        Preview (no change, default):
            powershell -ExecutionPolicy Bypass -File .\MACDX-Set-ScopeTargeting.ps1 -GroupName pilot-group-name -DeviceName device-name-or-serial
        Apply after reviewing:
            powershell -ExecutionPolicy Bypass -File .\MACDX-Set-ScopeTargeting.ps1 -GroupName pilot-group-name -DeviceName device-name-or-serial -WhatIf:$false

        Required Graph scopes:
            Group.ReadWrite.All
            GroupMember.ReadWrite.All
            Device.Read.All
            DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        With the default -WhatIf: prints the intended group and membership change and makes NO change
        (PASS). With -WhatIf:$false on a pilot group: creates the group if needed and adds the device,
        then reports the new membership. Allow time for policy/app assignment to flow, then re-run
        MACDX-Validation.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    # Name of the Entra security group to target (created if it does not exist). Required.
    [Parameter(Mandatory = $true)]
    [string]$GroupName,

    # Device name or serial to add to the group (substring match). Required.
    [Parameter(Mandatory = $true)]
    [string]$DeviceName,

    # Optional tenant id, e.g. your-tenant-id. Leave blank for interactive/default tenant.
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
    $WhatIfPreference = $true
}

$RequiredScopes = @(
    'Group.ReadWrite.All',
    'GroupMember.ReadWrite.All',
    'Device.Read.All',
    'DeviceManagementManagedDevices.Read.All'
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

try {
    if ($WhatIfPreference) {
        Write-Host "[PREVIEW MODE] -WhatIf is on by default. No changes will be made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
    }

    Connect-Graph

    # --- Find the Intune managed macOS device, then map to its Entra device object id ---
    $mdAll = @()
    $next = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        $mdAll += $resp.value
        $next = $resp.'@odata.nextLink'
    }
    $md = $mdAll | Where-Object { $_.deviceName -like "*$DeviceName*" -or $_.serialNumber -like "*$DeviceName*" } | Select-Object -First 1
    if (-not $md) { Write-Warning "No managed macOS device matched '$DeviceName'."; exit 1 }

    $azureDeviceId = $md.azureADDeviceId
    $entraDev = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$azureDeviceId'").value | Select-Object -First 1
    if (-not $entraDev) { Write-Warning "Could not resolve the Entra device object for '$($md.deviceName)'."; exit 1 }
    Write-Host ("Device: {0} (Entra object id {1})" -f $md.deviceName, $entraDev.id) -ForegroundColor Cyan

    # --- Find or (plan to) create the group ---
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'").value | Select-Object -First 1

    if (-not $grp) {
        if ($PSCmdlet.ShouldProcess($GroupName, "Create Entra security group")) {
            $mailNick = ($GroupName -replace '[^a-zA-Z0-9]', '')
            $body = @{
                displayName     = $GroupName
                mailEnabled     = $false
                mailNickname    = $mailNick
                securityEnabled = $true
            }
            $grp = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups" -Body ($body | ConvertTo-Json)
            Write-Host ("Created group '{0}' (id {1})." -f $GroupName, $grp.id) -ForegroundColor Green
        }
        else {
            Write-Host ("[WhatIf] Would create Entra security group '{0}'." -f $GroupName) -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ("Group '{0}' already exists (id {1})." -f $GroupName, $grp.id) -ForegroundColor Cyan
    }

    # --- Add the device as a member (only if the group is known) ---
    if ($grp -and $grp.id) {
        $already = $false
        try {
            $members = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/members?`$select=id").value
            $already = [bool]($members | Where-Object { $_.id -eq $entraDev.id })
        }
        catch { }

        if ($already) {
            Write-Host ("Device is already a member of '{0}'. Nothing to do." -f $GroupName) -ForegroundColor Green
        }
        elseif ($PSCmdlet.ShouldProcess("$($md.deviceName) -> $GroupName", "Add device to group")) {
            $ref = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($entraDev.id)" }
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/members/`$ref" -Body ($ref | ConvertTo-Json) | Out-Null
            Write-Host ("Added {0} to '{1}'. Allow time for the profile/app assignment to flow, then re-run MACDX-Validation." -f $md.deviceName, $GroupName) -ForegroundColor Green
        }
        else {
            Write-Host ("[WhatIf] Would add {0} to '{1}'. No change made." -f $md.deviceName, $GroupName) -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ("[WhatIf] Group '{0}' would need to exist before the device can be added." -f $GroupName) -ForegroundColor Yellow
    }
}
catch {
    Write-Error ("Set-ScopeTargeting failed: {0}" -f $_.Exception.Message)
    exit 1
}
