<#
.SYNOPSIS
  Configure Teams external-access, guest, and shared-channel settings (dry-run by default; -Commit to apply).
.DESCRIPTION
  Applies the designed external-collaboration configuration: the federation model (allow-list of approved
  domains), the per-user external access policy ("External Access Policy - Pilot"), the Teams guest master
  toggle, and the shared-channel channels policy ("Teams Channels Policy - SharedCh-Pilot"). SAFE-BY-DEFAULT:
  every change is previewed and made only when -Commit is passed. No hardcoded credentials.
.EXAMPLE
  .\Set-TeamsExternalGuestConfig.ps1 -AllowedDomains "contoso.com","fabrikam.com" -WhatIf   # dry-run
  .\Set-TeamsExternalGuestConfig.ps1 -AllowedDomains "contoso.com" -EnableSharedChannels -Commit
  (PowerShell 5.1+/7+, MicrosoftTeams; connect with Connect-MicrosoftTeams)
.NOTES
  Expected results: a preview of each intended change; with -Commit the named policies exist and settings
  are updated. Assign the policies to your pilot group with Grant-CsExternalAccessPolicy /
  Grant-CsTeamsChannelsPolicy after this runs. Pilot-first: do not commit tenant-wide without validation.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string[]]$AllowedDomains,
    [switch]$AllowFederatedUsers = $true,
    [switch]$AllowPublicUsers,                 # consumer Teams/Skype; default OFF
    [switch]$AllowGuestUser,
    [string]$ExternalAccessPolicyName = "External Access Policy - Pilot",
    [string]$ChannelsPolicyName       = "Teams Channels Policy - SharedCh-Pilot",
    [switch]$EnableSharedChannels,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
# -Commit gates real writes; without it (or with -WhatIf) everything is a preview.
$doIt = $Commit.IsPresent -and $PSCmdlet.ShouldProcess("tenant", "apply external/guest/shared-channel config")

if (-not (Get-CsTenantFederationConfiguration -ErrorAction SilentlyContinue)) { Connect-MicrosoftTeams | Out-Null }

# 1. Federation model (allow-list) --------------------------------------------------
if ($AllowedDomains) {
    $list = New-CsEdgeAllowList -AllowedDomain ($AllowedDomains | ForEach-Object { New-CsEdgeDomainPattern -Domain $_ })
    if ($doIt) {
        Set-CsTenantFederationConfiguration -AllowedDomains $list `
            -AllowFederatedUsers:$AllowFederatedUsers -AllowPublicUsers:$AllowPublicUsers
        Write-Host "[APPLIED] Federation allow-list: $($AllowedDomains -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "[WHATIF] Would set federation allow-list: $($AllowedDomains -join ', ') (public=$AllowPublicUsers)" -ForegroundColor Yellow
    }
}

# 2. Per-user external access policy ------------------------------------------------
$eap = Get-CsExternalAccessPolicy -Identity $ExternalAccessPolicyName -ErrorAction SilentlyContinue
if ($doIt) {
    if ($eap) {
        Set-CsExternalAccessPolicy -Identity $ExternalAccessPolicyName -EnableFederationAccess $true -EnablePublicCloudAccess:$AllowPublicUsers
    } else {
        New-CsExternalAccessPolicy -Identity $ExternalAccessPolicyName -EnableFederationAccess $true -EnablePublicCloudAccess:$AllowPublicUsers
    }
    Write-Host "[APPLIED] External access policy '$ExternalAccessPolicyName' set." -ForegroundColor Green
} else {
    Write-Host "[WHATIF] Would create/update external access policy '$ExternalAccessPolicyName'." -ForegroundColor Yellow
}

# 3. Guest master toggle ------------------------------------------------------------
if ($PSBoundParameters.ContainsKey('AllowGuestUser')) {
    if ($doIt) {
        Set-CsTeamsClientConfiguration -Identity Global -AllowGuestUser:$AllowGuestUser
        Write-Host "[APPLIED] Teams guest access AllowGuestUser=$AllowGuestUser." -ForegroundColor Green
    } else {
        Write-Host "[WHATIF] Would set Teams guest access AllowGuestUser=$AllowGuestUser." -ForegroundColor Yellow
    }
}

# 4. Shared-channel channels policy -------------------------------------------------
$on = $EnableSharedChannels.IsPresent
$cp = Get-CsTeamsChannelsPolicy -Identity $ChannelsPolicyName -ErrorAction SilentlyContinue
if ($doIt) {
    $params = @{
        AllowSharedChannelCreation                    = $on
        AllowChannelSharingToExternalUser             = $on
        AllowUserToParticipateInExternalSharedChannel = $on
    }
    if ($cp) { Set-CsTeamsChannelsPolicy -Identity $ChannelsPolicyName @params }
    else     { New-CsTeamsChannelsPolicy -Identity $ChannelsPolicyName @params }
    Write-Host "[APPLIED] Channels policy '$ChannelsPolicyName' (sharedChannels=$on)." -ForegroundColor Green
} else {
    Write-Host "[WHATIF] Would create/update channels policy '$ChannelsPolicyName' (sharedChannels=$on)." -ForegroundColor Yellow
}

if (-not $Commit) { Write-Host "`nDry-run complete. Re-run with -Commit to apply. Assign policies to your pilot group afterward." -ForegroundColor Cyan }
