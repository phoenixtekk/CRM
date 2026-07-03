<#
.SYNOPSIS
    INCIDENTG-Remediation.ps1 — Safe, scoped common-fix helper for a NAMED object on GCC High (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Performs a small set of well-understood, scoped remediations during an incident on a GCC High
        tenant, always against a single NAMED object — never broadly:
        RevokeSessions (revoke a compromised user's refresh tokens), EnableConnector (re-enable a named
        Exchange Online mail-flow connector), and EnableInboundRule (re-enable a named transport rule).
        It connects only to the US Gov endpoints and is preview-only by default: it changes NOTHING unless
        you pass -Apply, and only ever touches the object you name.
    HOW TO RUN
        Preview (default, makes NO change):
          powershell -ExecutionPolicy Bypass -File .\INCIDENTG-Remediation.ps1 -Action RevokeSessions -Target "user@agency.gov"
        Apply for real (deliberate):
          powershell -ExecutionPolicy Bypass -File .\INCIDENTG-Remediation.ps1 -Action EnableConnector -Target "Inbound from Gateway" -Apply
        First run installs modules: Install-Module Microsoft.Graph, ExchangeOnlineManagement -Scope CurrentUser
        Graph scopes requested (RevokeSessions): User.RevokeSessions.All, User.ReadWrite.All
        Connects with -Environment USGov (Graph) and -ExchangeEnvironmentName O365USGovGCCHigh (EXO);
        sign in at login.microsoftonline.us.
    EXPECTED RESULTS
        Without -Apply: prints the planned action and exits without changing anything (pass = no change).
        With -Apply: performs only the single named action against the US Gov endpoint and prints the result
        for the Incident Record.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateSet('RevokeSessions','EnableConnector','EnableInboundRule')]
    [string]$Action,
    [Parameter(Mandatory)][string]$Target,
    [string]$ExchangeEnvironmentName = "O365USGovGCCHigh",
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

# Default to preview unless -Apply is explicitly given.
if (-not $Apply) { $WhatIfPreference = $true }

function Write-Plan { param($msg) Write-Host ("[PLAN] {0}" -f $msg) -ForegroundColor Yellow }
function Write-Done { param($msg) Write-Host ("[DONE] {0}" -f $msg) -ForegroundColor Green }

switch ($Action) {

    'RevokeSessions' {
        Write-Plan ("Revoke all sign-in sessions (refresh tokens) for user '{0}'." -f $Target)
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        # -Environment USGov -> graph.microsoft.us via login.microsoftonline.us (GCC High).
        Connect-MgGraph -Environment USGov -Scopes "User.RevokeSessions.All","User.ReadWrite.All" -NoWelcome
        try {
            if ($PSCmdlet.ShouldProcess($Target, "Revoke sign-in sessions")) {
                Invoke-MgGraphRequest -Method POST `
                    -Uri "https://graph.microsoft.us/v1.0/users/$Target/revokeSignInSessions" | Out-Null
                Write-Done ("Revoked sessions for '{0}'. User must re-authenticate." -f $Target)
            } else {
                Write-Host "WhatIf: no change made. Re-run with -Apply to revoke." -ForegroundColor Cyan
            }
        }
        finally { try { Disconnect-MgGraph | Out-Null } catch {} }
    }

    'EnableConnector' {
        Write-Plan ("Re-enable Exchange Online mail-flow connector '{0}'." -f $Target)
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline -ExchangeEnvironmentName $ExchangeEnvironmentName -ShowBanner:$false
        try {
            $conn = Get-OutboundConnector -Identity $Target -ErrorAction SilentlyContinue
            $type = 'Outbound'
            if (-not $conn) { $conn = Get-InboundConnector -Identity $Target -ErrorAction SilentlyContinue; $type = 'Inbound' }
            if (-not $conn) { throw "Connector '$Target' not found (inbound or outbound)." }
            if ($PSCmdlet.ShouldProcess($Target, "Enable $type connector")) {
                if ($type -eq 'Outbound') { Set-OutboundConnector -Identity $Target -Enabled $true }
                else { Set-InboundConnector -Identity $Target -Enabled $true }
                Write-Done ("Enabled {0} connector '{1}'." -f $type, $Target)
            } else {
                Write-Host "WhatIf: no change made. Re-run with -Apply to enable." -ForegroundColor Cyan
            }
        }
        finally { Disconnect-ExchangeOnline -Confirm:$false }
    }

    'EnableInboundRule' {
        Write-Plan ("Re-enable Exchange Online transport (mail flow) rule '{0}'." -f $Target)
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline -ExchangeEnvironmentName $ExchangeEnvironmentName -ShowBanner:$false
        try {
            $rule = Get-TransportRule -Identity $Target -ErrorAction Stop
            if ($PSCmdlet.ShouldProcess($Target, "Enable transport rule")) {
                Enable-TransportRule -Identity $Target
                Write-Done ("Enabled transport rule '{0}'." -f $Target)
            } else {
                Write-Host "WhatIf: no change made. Re-run with -Apply to enable." -ForegroundColor Cyan
            }
        }
        finally { Disconnect-ExchangeOnline -Confirm:$false }
    }
}

Write-Host "`nRecord this action (and its outcome) in the Incident Record Template - Incident - Lifecycle." -ForegroundColor Cyan
