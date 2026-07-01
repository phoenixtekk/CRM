<#
.SYNOPSIS
    IOSSDM-Set-SharedDeviceTargeting.ps1 — create the dynamic 'iOS – Shared Devices' group.

.DESCRIPTION
    PURPOSE
        Creates a dynamic DEVICE group whose membership rule matches the shared iPhones by their ADE
        enrollment profile name, so a phone joins 'iOS – Shared Devices' automatically the moment it
        enrolls. Assign the kiosk, restrictions, and compliance policies plus the Cisco Webex app to
        this group. Idempotent — skips the group if it already exists.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSSDM-Set-SharedDeviceTargeting.ps1 -WhatIf                              # preview
        .\IOSSDM-Set-SharedDeviceTargeting.ps1 -EnrollmentProfileName "iOS Shared – ADE – Pilot"

    EXPECTED RESULTS
        A dynamic device group 'iOS – Shared Devices' exists in Entra, with a membership rule matching
        the ADE enrollment profile name. New shared iPhones populate it automatically.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Creates a group; supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$GroupName = 'iOS – Shared Devices',
    [string]$EnrollmentProfileName = 'iOS Shared – ADE – Pilot',
    [string]$MailNickname = 'ios-shared-devices'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.ReadWrite.All' | Out-Null

# Already exists?
$existing = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName.Replace("'","''"))).value
if ($existing) {
    Write-Host "Group '$GroupName' already exists (id $($existing[0].id)) — skipping." -ForegroundColor Yellow
    return
}

# Dynamic device rule: match shared iPhones by ADE enrollment profile name (and iOS).
$rule = "(device.deviceOSType -eq `"iPad`" -or device.deviceOSType -eq `"iPhone`" -or device.deviceOSType -eq `"iOS`") -and (device.enrollmentProfileName -eq `"$EnrollmentProfileName`")"

$body = @{
    displayName                   = $GroupName
    description                   = 'Dynamic group of shared, DEM-enrolled iOS iPhones (kiosk/Webex). Managed by IOSSDM solution.'
    mailEnabled                   = $false
    mailNickname                  = $MailNickname
    securityEnabled               = $true
    groupTypes                    = @('DynamicMembership')
    membershipRule                = $rule
    membershipRuleProcessingState = 'On'
}

if ($PSCmdlet.ShouldProcess($GroupName, "Create dynamic device group with rule: $rule")) {
    $new = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host "Created '$GroupName' (id $($new.id))." -ForegroundColor Green
    Write-Host "Membership rule: $rule"
    Write-Host 'Next: assign the kiosk/restrictions/compliance profiles and the Cisco Webex app to this group.'
} else {
    Write-Host "[WhatIf] Would create '$GroupName' with rule: $rule"
}
