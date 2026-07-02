<#
.SYNOPSIS
    DYNTGT-Set-DynamicGroupFilter.ps1 — create a dynamic security group and/or an assignment filter.
.DESCRIPTION
    PURPOSE
        Builds the dynamic targeting taxonomy: creates an Entra dynamic device security group from a
        membership rule, and/or an Intune assignment filter from a filter rule, using the
        <Purpose> – <Scope> – <Stage> naming convention. Idempotent — skips creation if the named
        object already exists.
    HOW TO RUN
        Create a dynamic group:
          powershell -ExecutionPolicy Bypass -File .\DYNTGT-Set-DynamicGroupFilter.ps1 -GroupName "Corp Devices – Windows – All" -MembershipRule '(device.deviceOSType -eq "Windows") and (device.deviceOwnership -eq "Company")'
        Create an assignment filter:
          ... -FilterName "OS Version – Windows 11 – Include" -FilterPlatform windows10AndLater -FilterRule '(device.osVersion -startsWith "10.0.2")'
        Requires Microsoft Graph SDK and scopes Group.ReadWrite.All,
        DeviceManagementConfiguration.ReadWrite.All.
    EXPECTED RESULTS
        The named dynamic group and/or assignment filter created (or reported as already present).
.NOTES
    White-label — Intune Solutions. Creates objects (write).
#>
[CmdletBinding()] param(
    [string]$GroupName,
    [string]$MembershipRule,
    [string]$FilterName,
    [ValidateSet('windows10AndLater','iOS','android','androidForWork','macOS','windows81AndLater')][string]$FilterPlatform = 'windows10AndLater',
    [string]$FilterRule
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.ReadWrite.All','DeviceManagementConfiguration.ReadWrite.All' -NoWelcome

if ($GroupName -and $MembershipRule) {
    $exists = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id" -f $GroupName)).value | Select-Object -First 1
    if ($exists) { Write-Host ("Group '{0}' already exists — skipping." -f $GroupName) -ForegroundColor Yellow }
    else {
        $mailNick = ($GroupName -replace '[^A-Za-z0-9]', '')
        $body = @{
            displayName                   = $GroupName
            mailEnabled                   = $false
            mailNickname                  = $mailNick
            securityEnabled               = $true
            groupTypes                    = @('DynamicMembership')
            membershipRule                = $MembershipRule
            membershipRuleProcessingState = 'On'
        }
        Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host ("Created dynamic group '{0}'." -f $GroupName) -ForegroundColor Green
    }
}

if ($FilterName -and $FilterRule) {
    $existsF = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/assignmentFilters').value | Where-Object displayName -eq $FilterName | Select-Object -First 1
    if ($existsF) { Write-Host ("Filter '{0}' already exists — skipping." -f $FilterName) -ForegroundColor Yellow }
    else {
        $bodyF = @{ displayName = $FilterName; platform = $FilterPlatform; rule = $FilterRule; description = 'Created by DYNTGT-Set-DynamicGroupFilter.ps1' }
        Invoke-MgGraphRequest -Method POST -Uri '/beta/deviceManagement/assignmentFilters' -Body ($bodyF | ConvertTo-Json -Depth 5) | Out-Null
        Write-Host ("Created assignment filter '{0}' [{1}]." -f $FilterName, $FilterPlatform) -ForegroundColor Green
    }
}

if (-not (($GroupName -and $MembershipRule) -or ($FilterName -and $FilterRule))) {
    Write-Host "Nothing to do: supply -GroupName + -MembershipRule and/or -FilterName + -FilterRule." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
