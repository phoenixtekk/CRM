<#
.SYNOPSIS
    TEAMSSBC-Validation — Verify a Microsoft Teams Phone Direct Routing build is
    coherent: the named PSTN gateway exists and is healthy (SIP OPTIONS/Active),
    the routing chain is internally consistent, and pilot users are assigned.

.DESCRIPTION
    Runs a series of PASS/FAIL checks against the Direct Routing configuration
    created in the implementation guide. Read-only — no changes are made.

    Checks:
      G1  PSTN gateway exists, enabled, OPTIONS on (proxy Active when available).
      G2  Routing chain consistent (usages exist; routes reference an existing
          gateway + usage; policy references existing usages; emergency route is
          highest priority).
      G3  Each pilot user has the policy, a LineUri, and Enterprise Voice.

.PARAMETER GatewayFqdn
    The SBC FQDN registered as the PSTN gateway (e.g. sbc01.contoso.com).

.PARAMETER VoiceRoutingPolicy
    The voice routing policy to validate (e.g. "Voice Routing Policy – Standard User – Production").

.PARAMETER PilotUsers
    One or more user principal names to validate assignment for.

.PARAMETER EmergencyUsage
    Name of the emergency PSTN usage expected at highest-priority routing.
    Default: "PSTN Usage – Emergency – Production".

.EXAMPLE
    .\TEAMSSBC-Validation.ps1 -GatewayFqdn sbc01.contoso.com `
        -VoiceRoutingPolicy "Voice Routing Policy – Standard User – Production" `
        -PilotUsers user1@contoso.com,user2@contoso.com

.NOTES
    Solution : Microsoft Teams Phone Direct Routing with SBC (AudioCodes)
    Category : Azure Solutions — read-only.
    Module   : MicrosoftTeams
    Version  : 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GatewayFqdn,

    [Parameter(Mandatory = $true)]
    [string]$VoiceRoutingPolicy,

    [Parameter(Mandatory = $false)]
    [string[]]$PilotUsers = @(),

    [Parameter(Mandatory = $false)]
    [string]$EmergencyUsage = 'PSTN Usage – Emergency – Production'
)

$ErrorActionPreference = 'Stop'
$script:fail = 0

function Connect-IfNeeded {
    if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
        throw "MicrosoftTeams module is not installed. Run: Install-Module MicrosoftTeams -Scope CurrentUser"
    }
    Import-Module MicrosoftTeams -ErrorAction Stop
    try { $null = Get-CsTenant -ErrorAction Stop }
    catch { Connect-MicrosoftTeams | Out-Null }
}

function Assert {
    param([string]$Name, [bool]$Condition, [string]$Detail)
    if ($Condition) {
        Write-Host ("  [PASS] {0}" -f $Name) -ForegroundColor Green
    }
    else {
        Write-Host ("  [FAIL] {0}{1}" -f $Name, ($(if ($Detail) { " — $Detail" } else { '' }))) -ForegroundColor Red
        $script:fail++
    }
}

Connect-IfNeeded
Write-Host "=== Teams Phone Direct Routing Validation ===" -ForegroundColor Green

# ---- G1: Gateway exists and healthy ----
Write-Host "`n[G1] PSTN gateway / SIP OPTIONS health" -ForegroundColor Yellow
$gw = Get-CsOnlinePSTNGateway -Identity $GatewayFqdn -ErrorAction SilentlyContinue
Assert -Name "Gateway '$GatewayFqdn' exists" -Condition ([bool]$gw) -Detail "not found"
if ($gw) {
    Assert -Name "Gateway enabled" -Condition ([bool]$gw.Enabled)
    Assert -Name "SIP OPTIONS keep-alive enabled" -Condition ([bool]$gw.SendSipOptions) `
        -Detail "SendSipOptions is False; SBC cannot report Active"
    # Live OPTIONS/Active status is surfaced in the Teams admin center SBC page;
    # the cmdlet exposes configuration, so we validate config that drives health.
    Write-Host "  [INFO] Confirm 'Active' status in Teams admin center -> Voice -> Direct Routing -> SBCs" -ForegroundColor DarkGray
}

# ---- G2: Routing chain consistency ----
Write-Host "`n[G2] Voice routing chain consistency" -ForegroundColor Yellow
$usages = (Get-CsOnlinePstnUsage -Identity Global).Usage
$routes = Get-CsOnlineVoiceRoute
$policy = Get-CsOnlineVoiceRoutingPolicy -Identity $VoiceRoutingPolicy -ErrorAction SilentlyContinue

Assert -Name "Voice routing policy '$VoiceRoutingPolicy' exists" -Condition ([bool]$policy) -Detail "not found"

if ($policy) {
    foreach ($u in $policy.OnlinePstnUsages) {
        Assert -Name "Policy usage '$u' exists in Global usage list" -Condition ($usages -contains $u)
    }
    Assert -Name "Policy includes emergency usage '$EmergencyUsage'" `
        -Condition ($policy.OnlinePstnUsages -contains $EmergencyUsage) `
        -Detail "emergency usage not attached to policy"
}

# Routes that target our gateway must reference an existing usage.
$gwRoutes = $routes | Where-Object { $_.OnlinePstnGatewayList -contains $GatewayFqdn }
Assert -Name "At least one route targets '$GatewayFqdn'" -Condition ($gwRoutes.Count -gt 0)
foreach ($r in $gwRoutes) {
    foreach ($ru in $r.OnlinePstnUsages) {
        Assert -Name "Route '$($r.Identity)' usage '$ru' exists" -Condition ($usages -contains $ru)
    }
}

# Emergency route should be the highest priority (lowest Priority number) among gateway routes.
$emergencyRoutes = $gwRoutes | Where-Object { $_.OnlinePstnUsages -contains $EmergencyUsage }
if ($emergencyRoutes -and $gwRoutes) {
    $minPriority = ($gwRoutes | Measure-Object -Property Priority -Minimum).Minimum
    $emMin = ($emergencyRoutes | Measure-Object -Property Priority -Minimum).Minimum
    Assert -Name "Emergency route is highest priority" -Condition ($emMin -le $minPriority) `
        -Detail "a non-emergency route has higher priority and may shadow emergency dialing"
}
else {
    Assert -Name "Emergency route present for gateway" -Condition $false -Detail "no route with emergency usage targets the gateway"
}

# ---- G3: Pilot user assignment ----
if ($PilotUsers.Count -gt 0) {
    Write-Host "`n[G3] Pilot user assignment" -ForegroundColor Yellow
    foreach ($upn in $PilotUsers) {
        $usr = Get-CsOnlineUser -Identity $upn -ErrorAction SilentlyContinue
        if (-not $usr) {
            Assert -Name "User '$upn' found" -Condition $false -Detail "not found"
            continue
        }
        Assert -Name "$upn : Enterprise Voice enabled" -Condition ([bool]$usr.EnterpriseVoiceEnabled)
        Assert -Name "$upn : has LineUri (assigned number)" -Condition ([bool]$usr.LineUri)
        $assignedPolicy = if ($usr.OnlineVoiceRoutingPolicy) { "$($usr.OnlineVoiceRoutingPolicy)" } else { '' }
        Assert -Name "$upn : voice routing policy = '$VoiceRoutingPolicy'" `
            -Condition ($assignedPolicy -like "*$VoiceRoutingPolicy*") `
            -Detail "current: '$assignedPolicy'"
    }
}
else {
    Write-Host "`n[G3] No pilot users supplied — skipping user assignment checks." -ForegroundColor DarkGray
}

# ---- Result ----
Write-Host ""
if ($script:fail -eq 0) {
    Write-Host "VALIDATION RESULT: PASS — all checks passed." -ForegroundColor Green
    exit 0
}
else {
    Write-Host ("VALIDATION RESULT: FAIL — {0} check(s) failed." -f $script:fail) -ForegroundColor Red
    exit 1
}
