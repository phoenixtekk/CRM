<#
.SYNOPSIS
  Read-only discovery of Teams external-access, guest, and shared-channel posture (no changes made).
.DESCRIPTION
  Captures the full external-collaboration posture in one pass: federation configuration
  (allowed/blocked domains, open-federation state), external access policies, Teams guest
  configuration, channels policy (shared-channel switches), Entra cross-tenant access Default + partner
  settings, the guest count, and a stale-guest assessment. Writes a JSON baseline for design/rollback.
  Read-only: it calls only Get-* cmdlets.
.EXAMPLE
  .\Get-TeamsExternalGuestPosture.ps1 -OutputPath .\posture-baseline.json
  (PowerShell 5.1+/7+, MicrosoftTeams + Microsoft.Graph; connect with Connect-MicrosoftTeams / Connect-MgGraph)
.NOTES
  Expected results: a JSON file plus a console summary. Cross-tenant and guest-inactivity sections are
  skipped with a notice if the Graph modules/permissions or licensing are unavailable ("verify in your tenant").
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".\posture-baseline.json",
    [int]$InactiveDays  = 90
)

$ErrorActionPreference = 'Stop'
$posture = [ordered]@{ generatedUtc = (Get-Date).ToUniversalTime().ToString('o') }

# --- Teams (MicrosoftTeams module) -------------------------------------------------
try {
    if (-not (Get-Module MicrosoftTeams -ListAvailable)) { throw "MicrosoftTeams module not installed." }
    if (-not (Get-CsTenantFederationConfiguration -ErrorAction SilentlyContinue)) { Connect-MicrosoftTeams | Out-Null }

    $fed = Get-CsTenantFederationConfiguration
    $posture.federation = [ordered]@{
        AllowFederatedUsers  = $fed.AllowFederatedUsers
        AllowPublicUsers     = $fed.AllowPublicUsers
        AllowedDomains       = ($fed.AllowedDomains | Out-String).Trim()
        BlockedDomains       = ($fed.BlockedDomains | Out-String).Trim()
    }
    $posture.externalAccessPolicies = @(
        Get-CsExternalAccessPolicy | Select-Object Identity, EnableFederationAccess, EnablePublicCloudAccess
    )

    $client = Get-CsTeamsClientConfiguration -Identity Global
    $posture.guest = [ordered]@{
        AllowGuestUser = $client.AllowGuestUser
        Meeting        = Get-CsTeamsGuestMeetingConfiguration   | Select-Object AllowIPVideo, ScreenSharingMode, AllowMeetNow
        Messaging      = Get-CsTeamsGuestMessagingConfiguration | Select-Object AllowUserEditMessage, AllowUserDeleteMessage, AllowUserChat
        Calling        = Get-CsTeamsGuestCallingConfiguration   | Select-Object AllowPrivateCalling
    }

    $posture.channelsPolicies = @(
        Get-CsTeamsChannelsPolicy | Select-Object Identity, AllowSharedChannelCreation,
            AllowChannelSharingToExternalUser, AllowUserToParticipateInExternalSharedChannel
    )
    Write-Host "[OK] Teams federation, guest, and channels posture captured." -ForegroundColor Green
}
catch {
    Write-Warning "Teams posture incomplete: $($_.Exception.Message)"
    $posture.teamsError = $_.Exception.Message
}

# --- Entra cross-tenant access + guests (Microsoft Graph) --------------------------
try {
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes "Policy.Read.All","CrossTenantInformation.ReadBasic.All","User.Read.All","AuditLog.Read.All" | Out-Null
    }

    $posture.crossTenantDefault = Get-MgPolicyCrossTenantAccessPolicyDefault |
        Select-Object B2bCollaborationInbound, B2bCollaborationOutbound, B2bDirectConnectInbound, B2bDirectConnectOutbound
    $posture.crossTenantPartners = @(
        Get-MgPolicyCrossTenantAccessPolicyPartner | Select-Object TenantId, IsServiceProvider
    )
    $posture.guestInvitePolicy = (Get-MgPolicyAuthorizationPolicy).AllowInvitesFrom

    # Guests + stale assessment (sign-in activity is licensing-dependent; flagged if unavailable)
    $guests = Get-MgUser -Filter "userType eq 'Guest'" -All `
                -Property Id,DisplayName,Mail,UserType,CreatedDateTime,SignInActivity -ErrorAction Stop
    $cutoff = (Get-Date).AddDays(-$InactiveDays)
    $stale  = $guests | Where-Object {
        $last = $_.SignInActivity.LastSignInDateTime
        (-not $last) -or ($last -lt $cutoff)
    }
    $posture.guestSummary = [ordered]@{
        totalGuests   = $guests.Count
        inactiveDays  = $InactiveDays
        staleGuests   = $stale.Count
    }
    Write-Host "[OK] Cross-tenant + guest posture captured ($($guests.Count) guests, $($stale.Count) stale)." -ForegroundColor Green
}
catch {
    Write-Warning "Entra/Graph posture skipped (verify Graph module, permissions, and licensing in your tenant): $($_.Exception.Message)"
    $posture.graphError = $_.Exception.Message
}

$posture | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "`nPosture baseline written to $OutputPath" -ForegroundColor Cyan
