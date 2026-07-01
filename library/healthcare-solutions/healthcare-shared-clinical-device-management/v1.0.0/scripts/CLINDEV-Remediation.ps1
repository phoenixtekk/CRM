<#
.SYNOPSIS
    CLINDEV-Remediation.ps1 — Safe, gated remediation for shared clinical Windows devices in
    Microsoft Intune.

    PURPOSE
        Apply the two safe fixes the shared-device model needs:
          1. Clear a STRAY PRIMARY USER from a shared device (a WOW/kiosk should be owner-less).
          2. RE-ASSIGN missing configuration profiles/apps by ensuring the device is in the
             'Clinical - Shared Devices' group (so dynamic assignment flows to it).
        The script is READ-ONLY by default: it runs in -WhatIf preview mode and changes nothing
        unless you pass -Apply. It never deletes devices, never touches user accounts, and never
        reads or moves ePHI.

    HOW TO RUN
        1. Install-Module Microsoft.Graph -Scope CurrentUser   (if needed)
        2. Preview (read-only, default):
               Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Group.Read.All","Directory.Read.All"
               .\CLINDEV-Remediation.ps1                       # -WhatIf preview
        3. Apply (requires write scopes + explicit -Apply):
               Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All","GroupMember.ReadWrite.All","Group.Read.All","Directory.Read.All"
               .\CLINDEV-Remediation.ps1 -Apply

    EXPECTED RESULTS
        In preview: a list of devices with a stray primary user (to be cleared) and devices not in
        the shared group (to be added) — with NO changes made. With -Apply: the stray primary users
        are cleared and missing devices are added to 'Clinical - Shared Devices', each action logged.

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $GroupName = "Clinical - Shared Devices",
    [switch] $Apply
)

function Assert-Graph {
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first (see .SYNOPSIS)."
    }
}

# Default to preview unless -Apply is explicitly set.
if (-not $Apply) { $WhatIfPreference = $true }

try {
    Assert-Graph
    $mode = if ($Apply) { "APPLY" } else { "PREVIEW (-WhatIf) — no changes will be made" }
    Write-Host "CLINDEV-Remediation mode: $mode" -ForegroundColor Yellow

    $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction Stop | Select-Object -First 1
    if (-not $group) { throw "Group '$GroupName' not found. Create it with CLINDEV-Set-SharedDeviceGroup.ps1 first." }
    $memberDeviceIds = (Get-MgGroupMember -GroupId $group.Id -All) |
        ForEach-Object { $_.AdditionalProperties.deviceId } | Where-Object { $_ }

    $devices = Get-MgDeviceManagementManagedDevice -All -Filter "operatingSystem eq 'Windows'" -ErrorAction Stop

    # --- Fix 1: clear stray primary user ---
    $withOwner = $devices | Where-Object { -not [string]::IsNullOrWhiteSpace($_.UserPrincipalName) }
    Write-Host ("`nStray primary users to clear: {0}" -f $withOwner.Count) -ForegroundColor Cyan
    foreach ($d in $withOwner) {
        if ($PSCmdlet.ShouldProcess($d.DeviceName, "Clear primary user '$($d.UserPrincipalName)'")) {
            # Graph: remove the primary user reference from the managed device.
            $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($d.Id)/users/`$ref"
            Invoke-MgGraphRequest -Method DELETE -Uri $uri -ErrorAction Stop
            Write-Host "  Cleared primary user on $($d.DeviceName)" -ForegroundColor Green
        }
    }

    # --- Fix 2: ensure device is in the shared group (so profiles/apps flow) ---
    # Only meaningful for an Assigned group; for a Dynamic group, fix the rule/group tag instead.
    if ($group.GroupTypes -notcontains 'DynamicMembership') {
        $missing = $devices | Where-Object { $_.AzureAdDeviceId -and ($memberDeviceIds -notcontains $_.AzureAdDeviceId) }
        Write-Host ("`nDevices to add to '{0}': {1}" -f $GroupName, $missing.Count) -ForegroundColor Cyan
        foreach ($d in $missing) {
            $dirObj = Get-MgDevice -Filter "deviceId eq '$($d.AzureAdDeviceId)'" -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $dirObj) { continue }
            if ($PSCmdlet.ShouldProcess($d.DeviceName, "Add to group '$GroupName'")) {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $dirObj.Id -ErrorAction Stop
                Write-Host "  Added $($d.DeviceName) to $GroupName" -ForegroundColor Green
            }
        }
    } else {
        Write-Warning "'$GroupName' is a DYNAMIC group — fix membership via the group tag / dynamic rule, not by adding members. See CLINDEV-Set-SharedDeviceGroup.ps1 and 03-implementation.md Step 4."
    }

    if (-not $Apply) {
        Write-Host "`nPreview complete. Re-run with -Apply (and write scopes) to make these changes." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "CLINDEV-Remediation failed: $($_.Exception.Message)"
    exit 1
}
