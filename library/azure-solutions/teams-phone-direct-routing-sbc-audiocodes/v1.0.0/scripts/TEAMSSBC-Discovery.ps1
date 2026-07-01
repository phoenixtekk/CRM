<#
.SYNOPSIS
    TEAMSSBC-Discovery — Read the current Microsoft Teams Phone Direct Routing
    configuration (PSTN gateways, voice routes, PSTN usages, voice routing
    policies, dial plans, and voice-enabled users).

.DESCRIPTION
    Connects to Microsoft Teams (MicrosoftTeams module) and enumerates the
    existing Direct Routing / voice configuration to establish a baseline before
    any change is made. Optionally writes each collection to CSV.

    READ-ONLY. This script makes no changes to the tenant.

.PARAMETER OutputPath
    Optional directory to write CSV exports. If omitted, results are written to
    the pipeline / console only.

.EXAMPLE
    .\TEAMSSBC-Discovery.ps1

.EXAMPLE
    .\TEAMSSBC-Discovery.ps1 -OutputPath .\baseline

.NOTES
    Solution : Microsoft Teams Phone Direct Routing with SBC (AudioCodes)
    Category : Azure Solutions — read-only.
    Module   : MicrosoftTeams
    Version  : 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Connect-IfNeeded {
    if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
        throw "MicrosoftTeams module is not installed. Run: Install-Module MicrosoftTeams -Scope CurrentUser"
    }
    Import-Module MicrosoftTeams -ErrorAction Stop
    try {
        $null = Get-CsTenant -ErrorAction Stop
    }
    catch {
        Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Cyan
        Connect-MicrosoftTeams | Out-Null
    }
}

function Export-IfRequested {
    param(
        [Parameter(Mandatory)][object]$Data,
        [Parameter(Mandatory)][string]$Name
    )
    if ($OutputPath) {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        $file = Join-Path $OutputPath "$Name.csv"
        $Data | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
        Write-Host "  -> $file" -ForegroundColor DarkGray
    }
}

Connect-IfNeeded

Write-Host "=== Teams Phone Direct Routing Discovery ===" -ForegroundColor Green

Write-Host "`n[1/6] PSTN Gateways (SBCs)" -ForegroundColor Yellow
$gateways = Get-CsOnlinePSTNGateway |
    Select-Object Identity, Fqdn, SipSignalingPort, Enabled, SendSipOptions,
                  MediaBypass, MaxConcurrentSessions, ForwardPai, ForwardCallHistory
$gateways | Format-Table -AutoSize
Export-IfRequested -Data $gateways -Name 'pstn-gateways'

Write-Host "`n[2/6] PSTN Usages" -ForegroundColor Yellow
$usages = (Get-CsOnlinePstnUsage -Identity Global).Usage |
    ForEach-Object { [pscustomobject]@{ Usage = $_ } }
$usages | Format-Table -AutoSize
Export-IfRequested -Data $usages -Name 'pstn-usages'

Write-Host "`n[3/6] Voice Routes" -ForegroundColor Yellow
$routes = Get-CsOnlineVoiceRoute |
    Select-Object Identity, Priority, NumberPattern,
                  @{N='OnlinePstnGatewayList';E={ $_.OnlinePstnGatewayList -join ';' }},
                  @{N='OnlinePstnUsages';E={ $_.OnlinePstnUsages -join ';' }}
$routes | Sort-Object Priority | Format-Table -AutoSize
Export-IfRequested -Data $routes -Name 'voice-routes'

Write-Host "`n[4/6] Voice Routing Policies" -ForegroundColor Yellow
$policies = Get-CsOnlineVoiceRoutingPolicy |
    Select-Object Identity, @{N='OnlinePstnUsages';E={ $_.OnlinePstnUsages -join ';' }}
$policies | Format-Table -AutoSize
Export-IfRequested -Data $policies -Name 'voice-routing-policies'

Write-Host "`n[5/6] Tenant Dial Plans" -ForegroundColor Yellow
$dialPlans = Get-CsTenantDialPlan |
    Select-Object Identity, Description,
                  @{N='NormalizationRuleCount';E={ $_.NormalizationRules.Count }}
$dialPlans | Format-Table -AutoSize
Export-IfRequested -Data $dialPlans -Name 'dial-plans'

Write-Host "`n[6/6] Voice-Enabled Users" -ForegroundColor Yellow
$users = Get-CsOnlineUser -Filter 'EnterpriseVoiceEnabled -eq $true' -ErrorAction SilentlyContinue |
    Select-Object UserPrincipalName, LineUri, EnterpriseVoiceEnabled,
                  OnlineVoiceRoutingPolicy, TenantDialPlan
if (-not $users) {
    # Fallback for environments where -Filter on this property is unsupported.
    $users = Get-CsOnlineUser |
        Where-Object { $_.EnterpriseVoiceEnabled } |
        Select-Object UserPrincipalName, LineUri, EnterpriseVoiceEnabled,
                      OnlineVoiceRoutingPolicy, TenantDialPlan
}
$users | Format-Table -AutoSize
Export-IfRequested -Data $users -Name 'voice-enabled-users'

Write-Host "`nDiscovery complete." -ForegroundColor Green
if ($OutputPath) { Write-Host "CSV baseline written to: $OutputPath" -ForegroundColor Green }
