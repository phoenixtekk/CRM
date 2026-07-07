<#
.SYNOPSIS
    TEAMSAPPS-Configure.ps1 — SAFELY create/update Teams app permission + setup policies from a definition. Defaults to -WhatIf.
.DESCRIPTION
    PURPOSE
        Configures the governance policies: an app permission policy that allows only the vetted app
        list per class (Microsoft / third-party / custom), and an app setup policy that pins the
        approved core apps and sets whether users may pin/sideload. SAFE BY DEFAULT — runs in -WhatIf
        mode (prints the policy bodies it WOULD create/update) unless -Commit is supplied. Uses the
        MicrosoftTeams cmdlets New-/Set-CsTeamsAppPermissionPolicy and New-/Set-CsTeamsAppSetupPolicy.
    HOW TO RUN
        Dry-run (default, NO changes):
          .\TEAMSAPPS-Configure.ps1
        Apply:
          .\TEAMSAPPS-Configure.ps1 -Commit
        Custom names / vetted list:
          .\TEAMSAPPS-Configure.ps1 -PermissionPolicyName 'App Permission Policy - Pilot - Pilot' `
              -VettedAppIds @('<appId1>','<appId2>') -PinnedAppIds @('<appId1>') -Commit
        (PowerShell 5.1+/7+; MicrosoftTeams module; Connect-MicrosoftTeams)
    EXPECTED RESULTS
        -WhatIf: prints the permission-policy allow lists and setup-policy pinned set that WOULD be
        applied; nothing changes. -Commit: the named policies are created or updated in place.
.NOTES
    Teams — Microsoft Teams Apps & Integration Governance. Default mode makes NO changes.
    App-permission-policy management is transitioning to the Manage apps model — verify behavior in your tenant.
#>
[CmdletBinding()]
param(
    [string]$PermissionPolicyName = 'App Permission Policy - Pilot - Pilot',
    [string]$SetupPolicyName      = 'App Setup Policy - Standard - Prod',
    [string[]]$VettedAppIds       = @(),   # Teams app IDs allowed for third-party + custom classes
    [string[]]$PinnedAppIds       = @(),   # Teams app IDs pinned in the app bar (in order)
    [ValidateSet('AllowedAppList','BlockedAppList','AllApps','NoApps')]
    [string]$ThirdPartyMode       = 'AllowedAppList',
    [bool]$AllowUserPinning       = $true,
    [bool]$AllowSideLoading       = $false,  # custom-app upload; keep off unless LOB uploads are permitted
    [switch]$Commit                          # absent = -WhatIf (default, no changes)
)

$WhatIf = -not $Commit
$mode = if ($WhatIf) { 'WHATIF (no changes)' } else { 'COMMIT (applying changes)' }

if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) { Install-Module MicrosoftTeams -Scope CurrentUser -Force -AllowClobber }
Import-Module MicrosoftTeams -ErrorAction Stop
Connect-MicrosoftTeams | Out-Null

Write-Host ("=== TEAMSAPPS Configure [{0}] ===" -f $mode) -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })

# Build the allowed-app objects for the permission policy (New-CsTeamsAppPermissionPolicy uses
# -DefaultCatalogApps / -GlobalCatalogApps / -PrivateCatalogApps with New-CsTeamsAppPermissionPolicyApp).
$allowedApps = @()
foreach ($id in $VettedAppIds) { $allowedApps += (New-CsTeamsAppPermissionPolicyApp -Id $id) }

Write-Host ('--- Permission policy "{0}" ---' -f $PermissionPolicyName) -ForegroundColor Cyan
Write-Host ('    Third-party (GlobalCatalog) mode: {0}; vetted apps: {1}' -f $ThirdPartyMode, $VettedAppIds.Count)
Write-Host ('    Custom (PrivateCatalog) mode:     {0}' -f $ThirdPartyMode)

if ($WhatIf) {
    Write-Host ('WOULD ensure permission policy "{0}" allowing only {1} vetted app(s) for third-party/custom classes' -f $PermissionPolicyName, $VettedAppIds.Count) -ForegroundColor Yellow
} else {
    $exists = Get-CsTeamsAppPermissionPolicy -Identity $PermissionPolicyName -ErrorAction SilentlyContinue
    $params = @{
        GlobalCatalogAppsType  = $ThirdPartyMode
        PrivateCatalogAppsType = $ThirdPartyMode
        DefaultCatalogAppsType = 'AllowedAppList'   # Microsoft apps: allow the approved set
        GlobalCatalogApps      = $allowedApps
        PrivateCatalogApps     = $allowedApps
    }
    if ($exists) { Set-CsTeamsAppPermissionPolicy -Identity $PermissionPolicyName @params; Write-Host ('OK    updated permission policy "{0}"' -f $PermissionPolicyName) -ForegroundColor Green }
    else         { New-CsTeamsAppPermissionPolicy -Identity $PermissionPolicyName @params; Write-Host ('OK    created permission policy "{0}"' -f $PermissionPolicyName) -ForegroundColor Green }
}

# --- Setup policy: pinned apps + pinning/sideloading ---
$pinnedApps = @()
foreach ($id in $PinnedAppIds) { $pinnedApps += (New-CsTeamsAppSetupPolicyApp -Id $id) }

Write-Host ('--- Setup policy "{0}" ---' -f $SetupPolicyName) -ForegroundColor Cyan
Write-Host ('    Pinned apps: {0}; AllowUserPinning: {1}; AllowSideLoading (custom upload): {2}' -f $PinnedAppIds.Count, $AllowUserPinning, $AllowSideLoading)

if ($WhatIf) {
    Write-Host ('WOULD ensure setup policy "{0}" pinning {1} app(s), AllowUserPinning={2}, AllowSideLoading={3}' -f $SetupPolicyName, $PinnedAppIds.Count, $AllowUserPinning, $AllowSideLoading) -ForegroundColor Yellow
} else {
    $exists = Get-CsTeamsAppSetupPolicy -Identity $SetupPolicyName -ErrorAction SilentlyContinue
    $params = @{ PinnedAppBarApps = $pinnedApps; AllowUserPinning = $AllowUserPinning; AllowSideLoading = $AllowSideLoading }
    if ($exists) { Set-CsTeamsAppSetupPolicy -Identity $SetupPolicyName @params; Write-Host ('OK    updated setup policy "{0}"' -f $SetupPolicyName) -ForegroundColor Green }
    else         { New-CsTeamsAppSetupPolicy -Identity $SetupPolicyName @params; Write-Host ('OK    created setup policy "{0}"' -f $SetupPolicyName) -ForegroundColor Green }
}

Write-Host ("=== {0}: done ({1}) ===" -f $mode, $(if($WhatIf){'no changes made'}else{'applied'})) -ForegroundColor Cyan
Disconnect-MicrosoftTeams | Out-Null
