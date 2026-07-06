<#
.SYNOPSIS
    GWCOEX-Set-ScopeTargeting.ps1 — Point the coexistence scope at the pilot or all users (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Control how widely coexistence mail routing applies. During Pilot, the outbound
        relay to Google is scoped to the pilot group via a transport rule so only pilot
        recipients relay; during Expand, the scope is widened to all users. This script
        creates or updates the scoping transport rule for the coexistence connector.
        It runs in preview (-WhatIf) mode by default and only changes the tenant with -Apply.
    HOW TO RUN
        Preview scoping to the pilot group (default):
          powershell -ExecutionPolicy Bypass -File .\GWCOEX-Set-ScopeTargeting.ps1 -Scope Pilot -PilotGroup 'Coexistence - Pilot Members'
        Apply expand to all users:
          powershell -ExecutionPolicy Bypass -File .\GWCOEX-Set-ScopeTargeting.ps1 -Scope AllUsers -Apply
        Uses the Exchange Online module; run as an Exchange administrator.
    EXPECTED RESULTS
        In preview: the scope change that WOULD be made (pilot-group-only vs all users).
        With -Apply: the transport rule is created/updated accordingly. PASS = the active
        scope matches the requested -Scope.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [ValidateSet('Pilot','AllUsers')]
    [string] $Scope = 'Pilot',
    [string] $PilotGroup = 'Coexistence - Pilot Members',
    [string] $ConnectorName = 'Coexistence - EXO->Google Connector',
    [string] $RuleName = 'Coexistence - Scope Targeting',
    [switch] $Apply,
    [string] $UserPrincipalName
)

$ErrorActionPreference = 'Stop'
$whatIf = -not $Apply
$mode = if ($whatIf) { 'PREVIEW (-WhatIf)' } else { 'APPLY' }

function Connect-Exo {
    param([string] $Upn)
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement module not found. Run: Install-Module ExchangeOnlineManagement"
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        if ($Upn) { Connect-ExchangeOnline -UserPrincipalName $Upn -ShowBanner:$false }
        else      { Connect-ExchangeOnline -ShowBanner:$false }
    }
}

try {
    Connect-Exo -Upn $UserPrincipalName
    Write-Host "==== GWCOEX SCOPE TARGETING — MODE: $mode  SCOPE: $Scope ====" -ForegroundColor Cyan

    if (-not (Get-OutboundConnector -Identity $ConnectorName -ErrorAction SilentlyContinue)) {
        Write-Host "  NOTE: outbound connector '$ConnectorName' not found. Create it first (GWCOEX-Remediation.ps1)." -ForegroundColor Yellow
    }

    $existing = Get-TransportRule -Identity $RuleName -ErrorAction SilentlyContinue

    if ($Scope -eq 'Pilot') {
        if (-not (Get-Recipient -Identity $PilotGroup -ErrorAction SilentlyContinue)) {
            throw "Pilot group '$PilotGroup' not found. Create it before scoping to Pilot."
        }
        Write-Host "  Plan: restrict coexistence relay so only members of '$PilotGroup' route via '$ConnectorName'." -ForegroundColor Yellow
        if ($existing) {
            Set-TransportRule -Identity $RuleName -SentToMemberOf $PilotGroup `
                -RouteMessageOutboundConnector $ConnectorName -WhatIf:$whatIf
        } else {
            New-TransportRule -Name $RuleName -SentToMemberOf $PilotGroup `
                -RouteMessageOutboundConnector $ConnectorName -WhatIf:$whatIf | Out-Null
        }
    }
    else {  # AllUsers
        Write-Host "  Plan: remove pilot scoping so the whole shared domain relays via '$ConnectorName'." -ForegroundColor Yellow
        if ($existing) {
            # Disable/remove the pilot-only transport rule; the connector's RecipientDomains then governs scope for all users.
            Remove-TransportRule -Identity $RuleName -Confirm:$false -WhatIf:$whatIf
        } else {
            Write-Host "  No pilot scoping rule present — connector already applies to all users. No change." -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    if ($whatIf) {
        Write-Host "PREVIEW ONLY — nothing changed. Re-run with -Apply to set scope to '$Scope'." -ForegroundColor Cyan
    } else {
        Write-Host "APPLIED — coexistence scope set to '$Scope'." -ForegroundColor Green
    }
}
finally {
    if (Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        Disconnect-ExchangeOnline -Confirm:$false | Out-Null
    }
}
