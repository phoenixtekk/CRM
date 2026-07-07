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
    White-label — Intune Solutions. Creates a group; supports -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$GroupName = 'iOS – Shared Devices',
    [string]$EnrollmentProfileName = 'iOS Shared – ADE – Pilot',
    [string]$MailNickname = 'ios-shared-devices',
    # First-party 'Intune Provisioning Client' service principal (aka 'Intune Autopilot
    # ConfidentialClient'). For an ASSIGNED shared-device group, this SP must OWN the group or
    # enrollment-time grouping leaves it empty. Matched by AppId, not display name.
    [string]$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.ReadWrite.All' | Out-Null

function Test-ProvisioningClientOwner {
    # READ-ONLY: report whether the Intune Provisioning Client SP owns the targeting group.
    param([string]$GroupId, [string]$Name, [string]$AppId)
    try {
        $owners = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId/owners").value
        if ($owners | Where-Object { $_.appId -eq $AppId }) {
            Write-Host "  OK  : Intune Provisioning Client (AppId $AppId) is an Owner of '$Name'." -ForegroundColor Green
        } else {
            Write-Host "  NOTE: Intune Provisioning Client (AppId $AppId) is NOT an Owner of '$Name'." -ForegroundColor Yellow
            Write-Host "        For an ASSIGNED shared-device group, enrollment-time grouping needs this owner or the group stays empty at enrollment." -ForegroundColor Yellow
            Write-Host "        Add it: Entra > Groups > '$Name' > Owners > Add owners, search by AppId $AppId (not the display name)."
        }
    } catch {
        Write-Host "  NOTE: could not read owners of '$Name' ($($_.Exception.Message))." -ForegroundColor DarkGray
    }
}

# Already exists?
$existing = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName.Replace("'","''"))).value
if ($existing) {
    Write-Host "Group '$GroupName' already exists (id $($existing[0].id)) — skipping." -ForegroundColor Yellow
    Test-ProvisioningClientOwner -GroupId $existing[0].id -Name $GroupName -AppId $ProvisioningClientAppId
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
    Test-ProvisioningClientOwner -GroupId $new.id -Name $GroupName -AppId $ProvisioningClientAppId
    Write-Host 'Next: assign the kiosk/restrictions/compliance profiles and the Cisco Webex app to this group.'
} else {
    Write-Host "[WhatIf] Would create '$GroupName' with rule: $rule"
}
