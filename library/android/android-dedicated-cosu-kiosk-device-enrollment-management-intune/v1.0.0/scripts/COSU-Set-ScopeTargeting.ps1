<#
.SYNOPSIS
    COSU-Set-ScopeTargeting.ps1 — build the dynamic dedicated-device group keyed on the enrollment profile (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Creates the Entra DYNAMIC DEVICE group this solution targets policy and apps at — dedicated
        (COSU) devices have no user, so everything is assigned to a device group whose membership rule
        matches the enrollment profile name. Idempotent: skips the group if it already exists. Also
        reports the group's current member count so you can confirm devices are landing in scope.
        Default -WhatIf; pass -Apply to make changes.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\COSU-Set-ScopeTargeting.ps1
        Apply:             ... -Apply
        Custom names:      ... -Apply -DeviceGroup 'Android Dedicated - Devices - Prod' -EnrollmentProfileName 'Android Dedicated - COSU - Prod'
        Requires the Microsoft Graph PowerShell SDK and delegated scope: Group.ReadWrite.All.
    EXPECTED RESULTS
        The dynamic device group exists with the membership rule
        (device.enrollmentProfileName -eq "<profile>") and processing enabled; its member count is
        reported. Assign the kiosk profile and managed Google Play apps (Required) to this group next.
.NOTES
    Android category — Android dedicated (COSU)/kiosk. Default -WhatIf. Dynamic device group needs Entra ID P1+.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$DeviceGroup           = 'Android Dedicated - Devices - Pilot',
    [string]$EnrollmentProfileName = 'Android Dedicated - COSU - Pilot',
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All' -NoWelcome

Write-Host "=== Dedicated (COSU) device-group scope targeting ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to make changes)" -ForegroundColor Yellow }

$rule = ('(device.enrollmentProfileName -eq "{0}")' -f $EnrollmentProfileName)

$ge = $DeviceGroup.Replace("'","''")
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1

if ($grp) {
    Write-Host ("  OK   : group '{0}' exists (id {1})." -f $DeviceGroup, $grp.id) -ForegroundColor Green
    if ($grp.membershipRule) { Write-Host ("         rule: {0}" -f $grp.membershipRule) }
    if ("$($grp.membershipRule)" -notlike "*$EnrollmentProfileName*") {
        Write-Host ("  NOTE : existing rule does not reference '{0}' — review it matches your enrollment profile." -f $EnrollmentProfileName) -ForegroundColor Yellow
    }
    try {
        $count = ((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value).Count
        Write-Host ("         current members: {0} device(s)." -f $count)
    } catch {}
} elseif ($PSCmdlet.ShouldProcess($DeviceGroup, "Create dynamic device group")) {
    $nick = ($DeviceGroup -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{
        displayName                   = $DeviceGroup
        description                   = "Dedicated (COSU) devices enrolled with '$EnrollmentProfileName'."
        mailEnabled                   = $false
        mailNickname                  = $nick
        securityEnabled               = $true
        groupTypes                    = @('DynamicMembership')
        membershipRule                = $rule
        membershipRuleProcessingState = 'On'
    } | ConvertTo-Json
    try {
        $new = Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups" -Body $body -ContentType 'application/json'
        Write-Host ("  DONE : created dynamic device group '{0}' (id {1})." -f $DeviceGroup, $new.id) -ForegroundColor Green
        Write-Host ("         rule: {0}" -f $rule)
    } catch {
        Write-Host ("  FAIL : could not create group: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "         Dynamic groups require Entra ID P1+; verify licensing." -ForegroundColor DarkGray
    }
} else {
    Write-Host ("  WOULD: create dynamic device group '{0}' with rule {1}" -f $DeviceGroup, $rule) -ForegroundColor Cyan
}

Write-Host "`nNext: assign managed Google Play apps (Required-to-device) and the kiosk profile to this group (Implementation Steps 4-5)." -ForegroundColor DarkGray
Write-Host "Dedicated devices have no user — always target the DEVICE group, never a user." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
