<#
.SYNOPSIS
    Report the Intune MDM user scope (All / Some / None) and whether a specific user falls inside it —
    Phase 2B.

.DESCRIPTION
    Reads the Mobility (MDM and WIP) "Microsoft Intune" configuration via Graph
    (beta /policies/mobileDeviceManagementPolicies) and shows the MDM user scope and included groups.
    If -UserPrincipalName is supplied and scope is a group, it checks the user's membership.

.HOW TO RUN
    .\ENRLDX-Get-MdmUserScope.ps1
    .\ENRLDX-Get-MdmUserScope.ps1 -UserPrincipalName user@contoso.com
    Sovereign cloud: add  -Environment USGov.

.EXPECTED RESULT
    The MDM user scope for Microsoft Intune, the scoped groups, and (if a user is given) a YES/NO on
    whether that user is inside the scope.

.NOTES
    Intune Solutions — read-only diagnostic (Microsoft Graph, beta). Scope: Policy.Read.All,
    Directory.Read.All. The portal (Entra > Devices > Mobility) is the source of truth if the beta
    endpoint changes.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$Environment = "Global"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Policy.Read.All','Directory.Read.All','GroupMember.Read.All' -Environment $Environment -NoWelcome

# The Microsoft Intune MDM policy application id
$intuneMdmAppId = '0000000a-0000-0000-c000-000000000000'
$resp = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/policies/mobileDeviceManagementPolicies?$expand=includedGroups' -ErrorAction Stop
$policies = $resp.value
$intune = $policies | Where-Object { $_.appliesTo -ne $null -or $_.displayName -match 'Intune' }
if (-not $intune) { $intune = $policies }

foreach ($p in $intune) {
    $name = $p.displayName
    $scope = $p.appliesTo   # all | none | selected
    Write-Host "MDM policy: $name" -ForegroundColor Cyan
    Write-Host "  MDM user scope (appliesTo): $scope" -ForegroundColor $(if($scope -eq 'all'){'Green'}elseif($scope -eq 'none'){'Yellow'}else{'Cyan'})
    $groups = @($p.includedGroups)
    if ($groups) { Write-Host "  Included groups: $(( $groups | ForEach-Object { $_.displayName }) -join ', ')" }

    if ($scope -eq 'none') { Write-Host "  -> Scope is NONE: no user can enroll. Set to All or a group (Phase 2B)." -ForegroundColor Yellow }
    if ($scope -eq 'all')  { Write-Host "  -> Scope is ALL: every licensed user is in scope; MDM scope is not the cause." -ForegroundColor Green }

    if ($UserPrincipalName -and $scope -eq 'selected' -and $groups) {
        $u = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -Property id -ErrorAction SilentlyContinue
        $inScope = $false
        foreach ($g in $groups) {
            $members = Get-MgGroupMember -GroupId $g.id -All -ErrorAction SilentlyContinue
            if ($members.Id -contains $u.Id) { $inScope = $true }
        }
        if ($inScope) { Write-Host "  -> $UserPrincipalName IS in the MDM scope group." -ForegroundColor Green }
        else { Write-Host "  -> $UserPrincipalName is NOT in any MDM scope group — this blocks enrollment (Phase 2B)." -ForegroundColor Yellow }
    }
}
