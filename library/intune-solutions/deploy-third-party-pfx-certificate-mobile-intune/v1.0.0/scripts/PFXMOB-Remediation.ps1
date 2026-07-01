<#
.SYNOPSIS
    PFXMOB-Remediation.ps1 — safely re-assign/repair the certificate delivery profile and re-trigger
    device sync. DEFAULTS TO -WhatIf (no changes unless you pass -Apply).
.DESCRIPTION
    PURPOSE
        Addresses the most common cause of "PFX exists in Graph but won't deploy": the delivery
        profile is not assigned to the device's group, or the device has not synced. This script:
          1. Confirms the delivery profile exists and is assigned to the target group; if missing,
             ADDS the group assignment (Path A: PKCS imported certificate profile;
             Path B: custom PKCS12 profile).
          2. Re-triggers a sync on the targeted managed devices so the profile re-applies.
        It is intentionally conservative: by default it only REPORTS what it would do.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\PFXMOB-Remediation.ps1 `
                                -ProfileName 'PFX Imported - iOS App Cert - Pilot' -GroupName 'iOS App Cert - Pilot'
        Apply changes:      add  -Apply
    EXPECTED RESULTS
        WhatIf: a list of the assignment/sync actions that WOULD be taken.
        Apply : the group assignment added (if missing) and a sync requested on member devices.
.NOTES
    Workplace Marketplace — Intune Solutions. Write actions require -Apply and the
    DeviceManagementConfiguration.ReadWrite.All / DeviceManagementManagedDevices.PrivilegedOperations.All
    scopes. Documented Graph endpoints (deviceConfigurations/assign, managedDevices/syncDevice).
#>
[CmdletBinding(SupportsShouldProcess)] param(
    [Parameter(Mandatory)] [string] $ProfileName,
    [Parameter(Mandatory)] [string] $GroupName,
    [switch] $Apply
)
# -WhatIf semantics: default to preview unless -Apply is given.
if (-not $Apply) { $WhatIfPreference = $true; Write-Host "[WhatIf default] No changes will be made. Pass -Apply to execute." -ForegroundColor Yellow }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = if ($Apply) {
    @('DeviceManagementConfiguration.ReadWrite.All','Group.Read.All','DeviceManagementManagedDevices.PrivilegedOperations.All','DeviceManagementManagedDevices.Read.All')
} else {
    @('DeviceManagementConfiguration.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All')
}
Connect-MgGraph -Scopes $scopes -NoWelcome

# Resolve profile + group.
$profile = (Invoke-MgGraphRequest -Method GET `
    -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations').value |
    Where-Object { $_.displayName -eq $ProfileName } | Select-Object -First 1
if (-not $profile) { Write-Host "Profile '$ProfileName' not found. Create it per the Implementation Guide first." -ForegroundColor Red; return }

$gEnc = [uri]::EscapeDataString($GroupName)
$group = (Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$gEnc'").value | Select-Object -First 1
if (-not $group) { Write-Host "Group '$GroupName' not found." -ForegroundColor Red; return }

# 1. Ensure the group is assigned to the profile.
$assignments = (Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$($profile.id)/assignments").value
$already = $assignments | Where-Object { $_.target.groupId -eq $group.id }
if ($already) {
    Write-Host ("Assignment OK: '{0}' already targets '{1}'." -f $ProfileName, $GroupName) -ForegroundColor Green
} else {
    if ($PSCmdlet.ShouldProcess($ProfileName, "Add group assignment -> $GroupName")) {
        $keep = @($assignments | ForEach-Object { @{ target = $_.target } })
        $keep += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $group.id } }
        $body = @{ assignments = $keep } | ConvertTo-Json -Depth 6
        Invoke-MgGraphRequest -Method POST -ContentType 'application/json' `
            -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$($profile.id)/assign" -Body $body | Out-Null
        Write-Host ("Assigned '{0}' -> '{1}'." -f $ProfileName, $GroupName) -ForegroundColor Green
    }
}

# 2. Re-trigger sync on iOS members so the profile re-applies.
$members = (Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/groups/$($group.id)/members").value
foreach ($m in $members) {
    $devName = $m.displayName
    $md = (Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '$([uri]::EscapeDataString($devName))'").value | Select-Object -First 1
    if (-not $md -or $md.operatingSystem -notmatch 'iOS|iPadOS') { continue }
    if ($PSCmdlet.ShouldProcess($devName, 'Trigger Intune sync')) {
        Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$($md.id)/syncDevice" | Out-Null
        Write-Host ("Sync requested: {0}" -f $devName) -ForegroundColor Green
    }
}

Write-Host "`nRe-run PFXMOB-Validation.ps1 after a policy cycle." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
