<#
.SYNOPSIS
    TEAMSSBC-Remediation — Apply safe, targeted fixes to a single named user's
    Microsoft Teams Phone Direct Routing assignment: (re)grant the voice routing
    policy and/or assign a phone number.

.DESCRIPTION
    Addresses the most common per-user gaps surfaced by TEAMSSBC-Validation:
    a missing voice routing policy grant or a missing/incorrect phone number.

    SAFE BY DEFAULT. The script runs in dry-run (-WhatIf style) mode and only
    REPORTS what it would do unless -Apply is specified. With -Apply it performs:
      - Grant-CsOnlineVoiceRoutingPolicy   (if -VoiceRoutingPolicy supplied)
      - Grant-CsTenantDialPlan             (if -DialPlan supplied)
      - Set-CsPhoneNumberAssignment        (if -PhoneNumber supplied)

.PARAMETER Identity
    The user principal name to remediate (e.g. user@contoso.com).

.PARAMETER VoiceRoutingPolicy
    Voice routing policy to (re)grant, e.g.
    "Voice Routing Policy – Standard User – Production".

.PARAMETER DialPlan
    Optional tenant dial plan to grant, e.g.
    "Dial Plan – Standard User – Production".

.PARAMETER PhoneNumber
    Optional E.164 number to assign as a Direct Routing number, e.g. +12065550123.

.PARAMETER Apply
    Perform the changes. Omit to preview only (default, read-only).

.EXAMPLE
    .\TEAMSSBC-Remediation.ps1 -Identity user@contoso.com `
        -VoiceRoutingPolicy "Voice Routing Policy – Standard User – Production"
    # Preview only (no changes).

.EXAMPLE
    .\TEAMSSBC-Remediation.ps1 -Identity user@contoso.com `
        -VoiceRoutingPolicy "Voice Routing Policy – Standard User – Production" `
        -PhoneNumber +12065550123 -Apply
    # Applies the policy grant and number assignment.

.NOTES
    Solution : Microsoft Teams Phone Direct Routing with SBC (AudioCodes)
    Category : Azure Solutions — read-only.
    Module   : MicrosoftTeams
    Version  : 1.0.0
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Identity,

    [Parameter(Mandatory = $false)]
    [string]$VoiceRoutingPolicy,

    [Parameter(Mandatory = $false)]
    [string]$DialPlan,

    [Parameter(Mandatory = $false)]
    [string]$PhoneNumber,

    [Parameter(Mandatory = $false)]
    [switch]$Apply
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
Write-Host "=== Teams Phone Direct Routing Remediation ===" -ForegroundColor Green
if (-not $Apply) {
    Write-Host "DRY-RUN: no changes will be made. Re-run with -Apply to execute." -ForegroundColor Yellow
}

$user = Get-CsOnlineUser -Identity $Identity -ErrorAction SilentlyContinue
if (-not $user) { throw "User '$Identity' not found." }

Write-Host "`nCurrent state for $Identity :" -ForegroundColor Cyan
Write-Host ("  EnterpriseVoiceEnabled : {0}" -f $user.EnterpriseVoiceEnabled)
Write-Host ("  LineUri                : {0}" -f $user.LineUri)
Write-Host ("  VoiceRoutingPolicy     : {0}" -f $user.OnlineVoiceRoutingPolicy)
Write-Host ("  TenantDialPlan         : {0}" -f $user.TenantDialPlan)

function Invoke-Action {
    param([string]$Description, [scriptblock]$Action)
    if ($Apply) {
        if ($PSCmdlet.ShouldProcess($Identity, $Description)) {
            & $Action
            Write-Host "  [DONE] $Description" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  [WOULD DO] $Description" -ForegroundColor Yellow
    }
}

Write-Host "`nPlanned remediation:" -ForegroundColor Cyan

if ($VoiceRoutingPolicy) {
    Invoke-Action -Description "Grant voice routing policy '$VoiceRoutingPolicy'" -Action {
        Grant-CsOnlineVoiceRoutingPolicy -Identity $Identity -PolicyName $VoiceRoutingPolicy
    }
}

if ($DialPlan) {
    Invoke-Action -Description "Grant tenant dial plan '$DialPlan'" -Action {
        Grant-CsTenantDialPlan -Identity $Identity -PolicyName $DialPlan
    }
}

if ($PhoneNumber) {
    Invoke-Action -Description "Assign Direct Routing number '$PhoneNumber'" -Action {
        Set-CsPhoneNumberAssignment -Identity $Identity -PhoneNumber $PhoneNumber -PhoneNumberType DirectRouting
    }
}

if (-not ($VoiceRoutingPolicy -or $DialPlan -or $PhoneNumber)) {
    Write-Host "  (nothing specified — supply -VoiceRoutingPolicy, -DialPlan, and/or -PhoneNumber)" -ForegroundColor DarkGray
}

Write-Host "`nRemediation complete." -ForegroundColor Green
if (-not $Apply) { Write-Host "Re-run with -Apply to make these changes." -ForegroundColor Yellow }
