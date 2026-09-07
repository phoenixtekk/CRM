<#
.SYNOPSIS
    Report the Intune device-enrollment restrictions that can block an iOS/iPadOS enrollment — platform
    allow/block, personally-owned allow/block, and the per-user device limit (Phase 2C).

.DESCRIPTION
    Reads Get-MgDeviceManagementDeviceEnrollmentConfiguration and summarizes the platform-restriction
    and device-limit configurations, highlighting anything that would deny an iOS/iPadOS or
    personally-owned device.

.HOW TO RUN
    .\ENRLDX-Get-EnrollmentRestrictions.ps1
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    A table of enrollment-restriction configurations with the iOS platform / personal-ownership / device
    limit values called out.

.NOTES
    Intune Solutions — read-only diagnostic (Microsoft Graph). Scope:
    DeviceManagementServiceConfig.Read.All.
#>
[CmdletBinding()]
param(
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All' -Environment $Environment -NoWelcome

$configs = Get-MgDeviceManagementDeviceEnrollmentConfiguration -All -ErrorAction Stop | Sort-Object Priority
foreach ($c in $configs) {
    $type = $c.AdditionalProperties['@odata.type']
    Write-Host "`n[$($c.Priority)] $($c.DisplayName)  ($type)" -ForegroundColor Cyan

    if ($type -match 'PlatformRestrictions') {
        $ios = $c.AdditionalProperties['iosRestriction']
        if ($ios) {
            $blocked = $ios['platformBlocked']
            $personalBlocked = $ios['personalDeviceEnrollmentBlocked']
            Write-Host ("  iOS/iPadOS platformBlocked = {0}" -f $blocked) -ForegroundColor $(if($blocked){'Yellow'}else{'Green'})
            Write-Host ("  iOS/iPadOS personalDeviceEnrollmentBlocked = {0}" -f $personalBlocked) -ForegroundColor $(if($personalBlocked){'Yellow'}else{'Green'})
            if ($blocked) { Write-Host "  -> iOS/iPadOS is BLOCKED here — allow the platform (Phase 2C)." -ForegroundColor Yellow }
            if ($personalBlocked) { Write-Host "  -> Personally-owned iOS is BLOCKED — allow personal ownership for BYO (Phase 2C)." -ForegroundColor Yellow }
        }
    }
    elseif ($type -match 'LimitConfiguration') {
        $limit = $c.AdditionalProperties['limit']
        Write-Host ("  Device limit = {0}" -f $limit) -ForegroundColor Cyan
        Write-Host "  -> If the user already has $limit enrolled devices, new enrollment is denied (Phase 2C)." -ForegroundColor Gray
    }
}
Write-Host "`nCheck the assignment of any blocking restriction — it may target the user's group." -ForegroundColor Gray
