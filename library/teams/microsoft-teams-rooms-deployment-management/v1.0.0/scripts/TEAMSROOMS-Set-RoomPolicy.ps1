<#
.SYNOPSIS
    TEAMSROOMS-Set-RoomPolicy — Apply the Teams Rooms calendar-processing standard
    and grant the room's Teams meeting/calling policies. SAFE BY DEFAULT — dry-run
    unless -Commit is passed.

.DESCRIPTION
    Configures a room resource account to the Teams Rooms standard:
      - Calendar processing (AutoAccept; keep subject/body; process external invites;
        no double-booking) via Set-CalendarProcessing (Exchange Online).
      - Grant a Teams meeting policy and a Teams calling policy to the room account
        via Grant-CsTeamsMeetingPolicy / Grant-CsTeamsCallingPolicy (MicrosoftTeams).
    The named policies must already exist in the Teams admin center. Without -Commit
    the script only REPORTS the actions it would take. No credentials are stored.

.PARAMETER Upn
    UPN / primary SMTP of the room account, e.g. room-boardroom-a@contoso.com.

.PARAMETER MeetingPolicy
    Name of an existing Teams meeting policy, e.g. "Meeting Policy - Teams Rooms - Prod".

.PARAMETER CallingPolicy
    Name of an existing Teams calling policy, e.g. "Calling Policy - Teams Rooms - Prod".

.PARAMETER AdditionalResponse
    Text for the room auto-reply (AddAdditionalResponse).

.PARAMETER Commit
    Actually perform the changes. Omit for a dry run (default).

.EXAMPLE
    .\TEAMSROOMS-Set-RoomPolicy.ps1 -Upn room-boardroom-a@contoso.com `
        -MeetingPolicy "Meeting Policy - Teams Rooms - Prod" `
        -CallingPolicy "Calling Policy - Teams Rooms - Prod"   # dry run

.EXAMPLE
    .\TEAMSROOMS-Set-RoomPolicy.ps1 -Upn room-boardroom-a@contoso.com `
        -MeetingPolicy "Meeting Policy - Teams Rooms - Prod" `
        -CallingPolicy "Calling Policy - Teams Rooms - Prod" -Commit
    (PowerShell 5.1+/7+; ExchangeOnlineManagement + MicrosoftTeams;
     Connect-ExchangeOnline, Connect-MicrosoftTeams)

.NOTES
    Expected results: dry-run prints each step as [WHATIF]; -Commit applies them as
    [OK]. Verify with TEAMSROOMS-Validation.ps1 (T3, T4).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Upn,
    [Parameter(Mandatory)][string]$MeetingPolicy,
    [Parameter(Mandatory)][string]$CallingPolicy,
    [Parameter(Mandatory = $false)][string]$AdditionalResponse = "This room is a Microsoft Teams Room. Add it to your Teams meeting to enable one-touch join.",
    [Parameter(Mandatory = $false)][switch]$Commit
)

$ErrorActionPreference = 'Stop'
$tag = if ($Commit) { '[OK]     ' } else { '[WHATIF] ' }

function Assert-Module {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Install)
    if (-not (Get-Module -ListAvailable -Name $Name)) { throw "$Name not installed. Run: $Install" }
    Import-Module $Name -ErrorAction Stop
}

Assert-Module -Name ExchangeOnlineManagement -Install "Install-Module ExchangeOnlineManagement -Scope CurrentUser"
Assert-Module -Name MicrosoftTeams           -Install "Install-Module MicrosoftTeams -Scope CurrentUser"
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

# Confirm target is a room mailbox
$mbx = Get-Mailbox -Identity $Upn -ErrorAction SilentlyContinue
if (-not $mbx) { throw "Mailbox $Upn not found." }
if ($mbx.RecipientTypeDetails -ne 'RoomMailbox') { throw "$Upn is $($mbx.RecipientTypeDetails), not a RoomMailbox." }

if (-not $Commit) { Write-Host "DRY RUN — no changes will be made. Re-run with -Commit to apply.`n" -ForegroundColor Yellow }

# --- 1. Calendar processing (Teams Rooms standard) ---
Write-Host "$tag Set-CalendarProcessing on $Upn (AutoAccept; keep subject/body; process external; no conflicts)" -ForegroundColor Cyan
if ($Commit) {
    Set-CalendarProcessing -Identity $Upn `
        -AutomateProcessing AutoAccept `
        -AddOrganizerToSubject $false -DeleteSubject $false -DeleteComments $false `
        -RemovePrivateProperty $false `
        -AddAdditionalResponse $true -AdditionalResponse $AdditionalResponse `
        -ProcessExternalMeetingMessages $true `
        -AllowConflicts $false
}

# --- 2. Verify named policies exist, then grant ---
$mp = Get-CsTeamsMeetingPolicy -Identity $MeetingPolicy -ErrorAction SilentlyContinue
if (-not $mp) { Write-Warning "Meeting policy '$MeetingPolicy' not found. Create it in Teams admin center first." }
else {
    Write-Host "$tag Grant-CsTeamsMeetingPolicy '$MeetingPolicy' to $Upn" -ForegroundColor Cyan
    if ($Commit) { Grant-CsTeamsMeetingPolicy -Identity $Upn -PolicyName $MeetingPolicy }
}

$cp = Get-CsTeamsCallingPolicy -Identity $CallingPolicy -ErrorAction SilentlyContinue
if (-not $cp) { Write-Warning "Calling policy '$CallingPolicy' not found. Create it in Teams admin center first." }
else {
    Write-Host "$tag Grant-CsTeamsCallingPolicy '$CallingPolicy' to $Upn" -ForegroundColor Cyan
    if ($Commit) { Grant-CsTeamsCallingPolicy -Identity $Upn -PolicyName $CallingPolicy }
}

$state = if ($Commit) { 'Changes applied' } else { 'Dry run only' }
Write-Host "`nDone. $state. Verify with TEAMSROOMS-Validation.ps1." -ForegroundColor Green
