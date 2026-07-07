<#
.SYNOPSIS
  Re-enable (or disable) a client protocol on a mailbox - SAFE BY DEFAULT: dry-run report only
  unless -Commit is passed; records the prior value for rollback.
.DESCRIPTION
  Sets MAPI/EWS/OWA/ActiveSync enablement on a mailbox via Set-CASMailbox. By default it makes
  NO change: it reports the current value and the intended change (dry-run). Pass -Commit to
  apply, or -WhatIf to preview through PowerShell's ShouldProcess. The recorded prior value is
  printed so it can be used as the rollback. This is the only state-changing tool in the toolkit;
  run it under change control (Diagnostic Playbook section E).
.EXAMPLE
  .\Set-MailboxProtocolAccess.ps1 -Identity user@contoso.com -Protocol Mapi -Enabled $true
  # DRY-RUN: shows current MAPI value and what would change. No change made.
.EXAMPLE
  .\Set-MailboxProtocolAccess.ps1 -Identity user@contoso.com -Protocol Mapi -Enabled $true -Commit
  (PowerShell 5.1+/7+, ExchangeOnlineManagement module; connect with Connect-ExchangeOnline)
.NOTES
  Expected results: dry-run prints CURRENT vs INTENDED and 'No change made (dry-run)'. With
  -Commit, prints the applied change plus 'Rollback: set <Protocol> back to <priorValue>'.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Identity,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Mapi','Ews','OWA','ActiveSync')]
    [string]$Protocol,

    [Parameter(Mandatory = $true)]
    [bool]$Enabled,

    [Parameter()]
    [switch]$Commit
)

function Ensure-ExoConnected {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement (EXO V3) module not found. Install-Module ExchangeOnlineManagement."
    }
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    try { Get-ConnectionInformation -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Connecting to Exchange Online (modern auth)..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    }
}

# Map friendly protocol name to the Set-CASMailbox parameter and Get-CASMailbox property.
$paramName = switch ($Protocol) {
    'Mapi'       { 'MapiEnabled' }
    'Ews'        { 'EwsEnabled' }
    'OWA'        { 'OWAEnabled' }
    'ActiveSync' { 'ActiveSyncEnabled' }
}

Ensure-ExoConnected

$cas = Get-CASMailbox -Identity $Identity -ErrorAction Stop
$current = $cas.$paramName
Write-Host "Mailbox : $Identity" -ForegroundColor Cyan
Write-Host "Protocol: $Protocol ($paramName)"
Write-Host "CURRENT : $current"
Write-Host "INTENDED: $Enabled"

if ($current -eq $Enabled) {
    Write-Host "No change needed - already $Enabled." -ForegroundColor Green
    return
}

if (-not $Commit) {
    Write-Host "No change made (dry-run). Re-run with -Commit to apply, under change control." -ForegroundColor Yellow
    Write-Host "Rollback if applied: set $paramName back to $current" -ForegroundColor Yellow
    return
}

$splat = @{ Identity = $Identity; $paramName = $Enabled; ErrorAction = 'Stop' }
if ($PSCmdlet.ShouldProcess($Identity, "Set $paramName = $Enabled")) {
    Set-CASMailbox @splat
    Write-Host "APPLIED : $paramName = $Enabled" -ForegroundColor Green
    Write-Host "Rollback: .\Set-MailboxProtocolAccess.ps1 -Identity $Identity -Protocol $Protocol -Enabled `$$($current.ToString().ToLower()) -Commit" -ForegroundColor Yellow
    Write-Host "Validate: Get-CASMailbox $Identity | Select $paramName ; then re-run the D2 gate." -ForegroundColor Cyan
}
