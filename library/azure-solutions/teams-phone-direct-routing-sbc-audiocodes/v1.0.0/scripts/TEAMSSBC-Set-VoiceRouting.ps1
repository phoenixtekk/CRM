<#
.SYNOPSIS
    TEAMSSBC-Set-VoiceRouting — Create the Microsoft Teams Phone Direct Routing
    voice routing stack from parameters: a PSTN gateway (SBC), PSTN usages, a
    voice route, and a voice routing policy.

.DESCRIPTION
    Builds the named routing objects in the correct dependency order:
      1. New-CsOnlinePSTNGateway        (pair the SBC by FQDN)
      2. Set-CsOnlinePstnUsage          (add the named PSTN usage to Global)
      3. New-CsOnlineVoiceRoute         (route matching pattern -> gateway + usage)
      4. New-CsOnlineVoiceRoutingPolicy (policy referencing the usage)

    SAFE BY DEFAULT. Supports -WhatIf to preview every action without changing
    the tenant. Existing objects are detected and updated rather than duplicated.

    NOTE: This script intentionally builds the standard/domestic stack from
    parameters. The dedicated emergency usage/route is created and validated
    separately per the implementation guide (kept highest priority) so emergency
    routing is reviewed deliberately.

.PARAMETER GatewayFqdn
    Public FQDN of the SBC to pair, e.g. sbc01.contoso.com.

.PARAMETER SipSignalingPort
    SIP TLS signaling port. Default 5061.

.PARAMETER MaxConcurrentSessions
    Max concurrent sessions on the gateway. Default 100.

.PARAMETER PstnUsage
    Name of the PSTN usage to create/reuse.
    Default "PSTN Usage – Domestic – Production".

.PARAMETER VoiceRouteName
    Name of the voice route to create.
    Default "Voice Route – Domestic Outbound – Production".

.PARAMETER NumberPattern
    Regex pattern for the route. Default matches E.164 (^\+\d{7,15}$).
    Tighten to your real dialing plan in production.

.PARAMETER RoutePriority
    Priority for the voice route (lower = higher priority). Default 1.
    Keep the dedicated emergency route at priority 0.

.PARAMETER VoiceRoutingPolicy
    Name of the voice routing policy to create/reuse.
    Default "Voice Routing Policy – Standard User – Production".

.EXAMPLE
    .\TEAMSSBC-Set-VoiceRouting.ps1 -GatewayFqdn sbc01.contoso.com -WhatIf
    # Preview the full build.

.EXAMPLE
    .\TEAMSSBC-Set-VoiceRouting.ps1 -GatewayFqdn sbc01.contoso.com `
        -NumberPattern '^\+1\d{10}$'
    # Build with a North American E.164 pattern.

.NOTES
    Solution : Microsoft Teams Phone Direct Routing with SBC (AudioCodes)
    Category : Azure Solutions — read-only.
    Module   : MicrosoftTeams
    Version  : 1.0.0
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$GatewayFqdn,

    [Parameter(Mandatory = $false)]
    [int]$SipSignalingPort = 5061,

    [Parameter(Mandatory = $false)]
    [int]$MaxConcurrentSessions = 100,

    [Parameter(Mandatory = $false)]
    [string]$PstnUsage = 'PSTN Usage – Domestic – Production',

    [Parameter(Mandatory = $false)]
    [string]$VoiceRouteName = 'Voice Route – Domestic Outbound – Production',

    [Parameter(Mandatory = $false)]
    [string]$NumberPattern = '^\+\d{7,15}$',

    [Parameter(Mandatory = $false)]
    [int]$RoutePriority = 1,

    [Parameter(Mandatory = $false)]
    [string]$VoiceRoutingPolicy = 'Voice Routing Policy – Standard User – Production'
)

$ErrorActionPreference = 'Stop'

function Connect-IfNeeded {
    if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
        throw "MicrosoftTeams module is not installed. Run: Install-Module MicrosoftTeams -Scope CurrentUser"
    }
    Import-Module MicrosoftTeams -ErrorAction Stop
    try { $null = Get-CsTenant -ErrorAction Stop }
    catch { Connect-MicrosoftTeams | Out-Null }
}

Connect-IfNeeded
Write-Host "=== Teams Phone Direct Routing — Build Voice Routing ===" -ForegroundColor Green

# ---- 1. PSTN gateway (pair the SBC) ----
Write-Host "`n[1/4] PSTN gateway: $GatewayFqdn" -ForegroundColor Yellow
$existingGw = Get-CsOnlinePSTNGateway -Identity $GatewayFqdn -ErrorAction SilentlyContinue
if ($existingGw) {
    Write-Host "  Gateway already exists — leaving as-is (use Set-CsOnlinePSTNGateway to modify)." -ForegroundColor DarkGray
}
else {
    if ($PSCmdlet.ShouldProcess($GatewayFqdn, "New-CsOnlinePSTNGateway (TLS $SipSignalingPort, OPTIONS on, SRTP)")) {
        New-CsOnlinePSTNGateway `
            -Fqdn $GatewayFqdn `
            -SipSignalingPort $SipSignalingPort `
            -Enabled $true `
            -SendSipOptions $true `
            -MaxConcurrentSessions $MaxConcurrentSessions `
            -MediaBypass $false `
            -ForwardCallHistory $true `
            -ForwardPai $true | Out-Null
        Write-Host "  [DONE] Gateway paired." -ForegroundColor Green
    }
}

# ---- 2. PSTN usage ----
Write-Host "`n[2/4] PSTN usage: $PstnUsage" -ForegroundColor Yellow
$usages = (Get-CsOnlinePstnUsage -Identity Global).Usage
if ($usages -contains $PstnUsage) {
    Write-Host "  Usage already present in Global usage list." -ForegroundColor DarkGray
}
else {
    if ($PSCmdlet.ShouldProcess('Global', "Add PSTN usage '$PstnUsage'")) {
        Set-CsOnlinePstnUsage -Identity Global -Usage @{Add = $PstnUsage} | Out-Null
        Write-Host "  [DONE] Usage added." -ForegroundColor Green
    }
}

# ---- 3. Voice route ----
Write-Host "`n[3/4] Voice route: $VoiceRouteName" -ForegroundColor Yellow
$existingRoute = Get-CsOnlineVoiceRoute -Identity $VoiceRouteName -ErrorAction SilentlyContinue
if ($existingRoute) {
    if ($PSCmdlet.ShouldProcess($VoiceRouteName, "Set-CsOnlineVoiceRoute (update pattern/gateway/usage)")) {
        Set-CsOnlineVoiceRoute -Identity $VoiceRouteName `
            -Priority $RoutePriority `
            -NumberPattern $NumberPattern `
            -OnlinePstnGatewayList @($GatewayFqdn) `
            -OnlinePstnUsages @($PstnUsage) | Out-Null
        Write-Host "  [DONE] Route updated." -ForegroundColor Green
    }
}
else {
    if ($PSCmdlet.ShouldProcess($VoiceRouteName, "New-CsOnlineVoiceRoute (priority $RoutePriority, pattern $NumberPattern)")) {
        New-CsOnlineVoiceRoute -Identity $VoiceRouteName `
            -Priority $RoutePriority `
            -NumberPattern $NumberPattern `
            -OnlinePstnGatewayList @($GatewayFqdn) `
            -OnlinePstnUsages @($PstnUsage) | Out-Null
        Write-Host "  [DONE] Route created." -ForegroundColor Green
    }
}

# ---- 4. Voice routing policy ----
Write-Host "`n[4/4] Voice routing policy: $VoiceRoutingPolicy" -ForegroundColor Yellow
$existingPolicy = Get-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy -ErrorAction SilentlyContinue
if ($existingPolicy) {
    if ($PSCmdlet.ShouldProcess($VoiceRoutingPolicy, "Set-CsOnlineVoiceRoutingPolicy (ensure usage attached)")) {
        $newUsages = @($existingPolicy.OnlinePstnUsages)
        if ($newUsages -notcontains $PstnUsage) { $newUsages += $PstnUsage }
        Set-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy -OnlinePstnUsages $newUsages | Out-Null
        Write-Host "  [DONE] Policy updated." -ForegroundColor Green
    }
}
else {
    if ($PSCmdlet.ShouldProcess($VoiceRoutingPolicy, "New-CsOnlineVoiceRoutingPolicy")) {
        New-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy -OnlinePstnUsages @($PstnUsage) | Out-Null
        Write-Host "  [DONE] Policy created." -ForegroundColor Green
    }
}

Write-Host "`nBuild complete." -ForegroundColor Green
Write-Host "Next: create the dedicated emergency usage/route (priority 0) and the tenant dial plan," -ForegroundColor Cyan
Write-Host "then grant the policy and assign numbers to pilot users (see 03-implementation.md)." -ForegroundColor Cyan
