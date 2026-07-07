<#
.SYNOPSIS
  Validate live external/guest/shared-channel posture against a target baseline (read-only PASS/FAIL).
.DESCRIPTION
  Compares the current tenant posture - federation model (allow-list domains, public users), Teams guest
  toggle, shared-channel channels policy, and Entra cross-tenant B2B direct-connect defaults - against a
  target baseline JSON, and reports PASS/FAIL per setting. This is the automated form of the validation
  gates. Read-only: it only reads settings; it never changes anything.
.EXAMPLE
  .\Test-TeamsExternalGuestBaseline.ps1 -BaselinePath .\target-baseline.json
  (PowerShell 5.1+/7+, MicrosoftTeams + Microsoft.Graph; connect with Connect-MicrosoftTeams / Connect-MgGraph)
.NOTES
  Expected results: a PASS/FAIL line per checked setting and a non-zero exit code if any gate fails, so it
  can run in a pipeline. Build the baseline from Get-TeamsExternalGuestPosture.ps1 output edited to the
  design target. Checks requiring Graph are reported as SKIP if the module/licensing is unavailable.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaselinePath,
    [string]$ChannelsPolicyName = "Teams Channels Policy - SharedCh-Pilot"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $BaselinePath)) { throw "Baseline not found: $BaselinePath" }
$target = Get-Content $BaselinePath -Raw | ConvertFrom-Json
$fail = 0

function Assert-Setting($name, $actual, $expected) {
    if ($null -eq $expected) { Write-Host "[SKIP] $name (no target set)" -ForegroundColor DarkGray; return }
    if ("$actual" -eq "$expected") { Write-Host "[PASS] $name = $actual" -ForegroundColor Green }
    else { Write-Host "[FAIL] $name: actual='$actual' expected='$expected'" -ForegroundColor Red; $script:fail++ }
}

# --- Teams checks ------------------------------------------------------------------
try {
    if (-not (Get-CsTenantFederationConfiguration -ErrorAction SilentlyContinue)) { Connect-MicrosoftTeams | Out-Null }
    $fed = Get-CsTenantFederationConfiguration
    Assert-Setting "Federation.AllowFederatedUsers" $fed.AllowFederatedUsers $target.federation.AllowFederatedUsers
    Assert-Setting "Federation.AllowPublicUsers"    $fed.AllowPublicUsers    $target.federation.AllowPublicUsers

    if ($target.federation.AllowedDomains) {
        $actualDomains = ($fed.AllowedDomains | Out-String).Trim()
        Assert-Setting "Federation.AllowedDomains" $actualDomains ($target.federation.AllowedDomains).Trim()
    }

    Assert-Setting "Guest.AllowGuestUser" (Get-CsTeamsClientConfiguration -Identity Global).AllowGuestUser $target.guest.AllowGuestUser

    $cp = Get-CsTeamsChannelsPolicy -Identity $ChannelsPolicyName -ErrorAction SilentlyContinue
    if ($cp -and $target.channelsPolicy) {
        Assert-Setting "Channels.AllowSharedChannelCreation" $cp.AllowSharedChannelCreation $target.channelsPolicy.AllowSharedChannelCreation
        Assert-Setting "Channels.AllowChannelSharingToExternalUser" $cp.AllowChannelSharingToExternalUser $target.channelsPolicy.AllowChannelSharingToExternalUser
        Assert-Setting "Channels.AllowUserToParticipateInExternalSharedChannel" $cp.AllowUserToParticipateInExternalSharedChannel $target.channelsPolicy.AllowUserToParticipateInExternalSharedChannel
    } else { Write-Host "[SKIP] Channels policy '$ChannelsPolicyName' not found or no target." -ForegroundColor DarkGray }
}
catch { Write-Warning "Teams checks incomplete: $($_.Exception.Message)"; $fail++ }

# --- Cross-tenant direct-connect defaults (Graph) ----------------------------------
try {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "Policy.Read.All" | Out-Null }
    $def = Get-MgPolicyCrossTenantAccessPolicyDefault
    if ($target.crossTenantDefault) {
        Assert-Setting "CrossTenant.B2bDirectConnectInbound.state"  $def.B2bDirectConnectInbound.InboundTrust  $target.crossTenantDefault.B2bDirectConnectInboundState
        Assert-Setting "CrossTenant.B2bDirectConnectOutbound.state" ($def.B2bDirectConnectOutbound.Applications.AccessType) $target.crossTenantDefault.B2bDirectConnectOutboundState
    }
}
catch { Write-Host "[SKIP] Cross-tenant checks (verify Graph module/permissions in your tenant): $($_.Exception.Message)" -ForegroundColor DarkGray }

Write-Host ""
if ($fail -gt 0) { Write-Host "VALIDATION RESULT: FAIL ($fail setting(s) drifted)" -ForegroundColor Red; exit 1 }
else { Write-Host "VALIDATION RESULT: PASS (all checked settings match baseline)" -ForegroundColor Green; exit 0 }
