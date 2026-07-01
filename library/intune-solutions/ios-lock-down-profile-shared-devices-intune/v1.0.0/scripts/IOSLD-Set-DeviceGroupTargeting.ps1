<#
.SYNOPSIS
    IOSLD-Set-DeviceGroupTargeting.ps1 — build the shared and corporate iPhone device groups.

.DESCRIPTION
    PURPOSE
        Creates BOTH targeting groups as dynamic DEVICE groups whose membership rules match phones by
        their ADE enrollment profile name, so each phone joins the correct group automatically the
        moment it enrolls:
          - 'iOS - Shared Devices'    <- enrollmentProfileName = the SHARED ADE profile
          - 'iOS - Corporate Devices' <- enrollmentProfileName = the CORPORATE ADE profile
        Assign the lock-down (restrictions + optional kiosk) profiles to the shared group, and the
        lighter baseline to the corporate group. Idempotent — skips any group that already exists.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSLD-Set-DeviceGroupTargeting.ps1 -WhatIf        # preview both
        .\IOSLD-Set-DeviceGroupTargeting.ps1 `
            -SharedEnrollmentProfileName "iOS Shared – ADE – Pilot" `
            -CorpEnrollmentProfileName   "iOS Corporate – ADE – Pilot"

    EXPECTED RESULTS
        Two dynamic device groups exist in Entra, each with a membership rule keyed on the matching ADE
        enrollment profile name. New iPhones populate the correct group automatically.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Creates groups; supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SharedGroupName              = 'iOS – Shared Devices',
    [string]$CorporateGroupName           = 'iOS – Corporate Devices',
    [string]$SharedEnrollmentProfileName  = 'iOS Shared – ADE – Pilot',
    [string]$CorpEnrollmentProfileName    = 'iOS Corporate – ADE – Pilot',
    [string]$SharedMailNickname           = 'ios-shared-devices',
    [string]$CorpMailNickname             = 'ios-corporate-devices'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.ReadWrite.All' | Out-Null

function New-DynamicDeviceGroup($GroupName, $MailNickname, $EnrollmentProfileName, $Description) {
    $existing = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName.Replace("'","''"))).value
    if ($existing) {
        Write-Host "Group '$GroupName' already exists (id $($existing[0].id)) — skipping." -ForegroundColor Yellow
        return
    }
    $rule = "(device.deviceOSType -eq `"iPhone`" -or device.deviceOSType -eq `"iPad`" -or device.deviceOSType -eq `"iOS`") -and (device.enrollmentProfileName -eq `"$EnrollmentProfileName`")"
    $body = @{
        displayName                   = $GroupName
        description                   = $Description
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
    } else {
        Write-Host "[WhatIf] Would create '$GroupName' with rule: $rule"
    }
}

New-DynamicDeviceGroup $SharedGroupName    $SharedMailNickname $SharedEnrollmentProfileName 'Dynamic group of shared, no-user-affinity, locked-down iOS iPhones. Managed by the IOSLD solution.'
New-DynamicDeviceGroup $CorporateGroupName $CorpMailNickname   $CorpEnrollmentProfileName   'Dynamic group of corporate, user-affinity iOS iPhones (lighter baseline). Managed by the IOSLD solution.'

Write-Host ''
Write-Host 'Next: assign the lock-down (restrictions + optional kiosk) profiles to the shared group,'
Write-Host 'and the corporate baseline profile + corporate apps to the corporate group.'
Disconnect-MgGraph | Out-Null
