<#
.SYNOPSIS
    TEAMSROOMS-Discovery — Read-only assessment of Microsoft Teams Rooms readiness:
    room mailboxes, their calendar processing, Teams Rooms licensing, and the
    Teams meeting/calling policy each room account is granted. Makes NO changes.

.DESCRIPTION
    Connects to Exchange Online, Microsoft Graph, and Microsoft Teams and builds a
    baseline for Teams Rooms deployment: which room mailboxes exist, whether their
    calendar processing matches the Teams Rooms standard, whether a Teams Rooms
    license is assigned, and which meeting/calling policies apply. Optionally
    exports each collection to CSV. READ-ONLY.

.PARAMETER RoomIdentity
    Optional UPN/SMTP of a single room to assess. If omitted, all room mailboxes
    (RecipientTypeDetails = RoomMailbox) are assessed.

.PARAMETER OutputPath
    Optional directory for CSV exports. If omitted, results go to the console only.

.EXAMPLE
    .\TEAMSROOMS-Discovery.ps1
    (assess every room mailbox; PowerShell 5.1+/7+; ExchangeOnlineManagement,
     Microsoft.Graph, MicrosoftTeams modules; connect with Connect-ExchangeOnline,
     Connect-MgGraph, Connect-MicrosoftTeams)

.EXAMPLE
    .\TEAMSROOMS-Discovery.ps1 -RoomIdentity room-boardroom-a@contoso.com -OutputPath .\baseline

.NOTES
    Expected results: a table (and optional CSV) per room showing mailbox type,
    key calendar-processing values, Teams Rooms license (if any), and policy grants.
    Nothing is modified — safe to run any time.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RoomIdentity,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Assert-Module {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Install)
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        throw "$Name module is not installed. Run: $Install"
    }
    Import-Module $Name -ErrorAction Stop
}

function Connect-Services {
    Assert-Module -Name ExchangeOnlineManagement -Install "Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    Assert-Module -Name Microsoft.Graph          -Install "Install-Module Microsoft.Graph -Scope CurrentUser"
    Assert-Module -Name MicrosoftTeams           -Install "Install-Module MicrosoftTeams -Scope CurrentUser"

    if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
        Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    }
    try { $null = Get-MgContext -ErrorAction Stop; if (-not (Get-MgContext)) { throw } } catch {
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All" | Out-Null
    }
    try { $null = Get-CsTenant -ErrorAction Stop } catch {
        Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Cyan
        Connect-MicrosoftTeams | Out-Null
    }
}

function Export-IfRequested {
    param([Parameter(Mandatory)][object]$Data, [Parameter(Mandatory)][string]$Name)
    if ($OutputPath) {
        if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
        $file = Join-Path $OutputPath "$Name.csv"
        $Data | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8
        Write-Host "  -> $file" -ForegroundColor DarkGray
    }
}

Connect-Services

Write-Host "=== Teams Rooms Discovery (read-only) ===" -ForegroundColor Green

# 1. Room mailboxes
Write-Host "`n[1/2] Room mailboxes" -ForegroundColor Yellow
if ($RoomIdentity) {
    $rooms = @(Get-Mailbox -Identity $RoomIdentity -ErrorAction Stop)
} else {
    $rooms = @(Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited)
}
if (-not $rooms -or $rooms.Count -eq 0) { Write-Host "No room mailboxes found." -ForegroundColor Red; return }

# 2. Per-room assessment
Write-Host "[2/2] Assessing $($rooms.Count) room(s)..." -ForegroundColor Yellow
$report = foreach ($m in $rooms) {
    $upn  = $m.PrimarySmtpAddress.ToString()
    $cal  = Get-CalendarProcessing -Identity $upn -ErrorAction SilentlyContinue
    $mgu  = Get-MgUser -UserId $upn -Property Id,AccountEnabled,UsageLocation,PasswordPolicies -ErrorAction SilentlyContinue
    $lic  = if ($mgu) { (Get-MgUserLicenseDetail -UserId $mgu.Id -ErrorAction SilentlyContinue).SkuPartNumber -join ';' } else { '' }
    $cs   = Get-CsOnlineUser -Identity $upn -ErrorAction SilentlyContinue

    [pscustomobject]@{
        DisplayName                    = $m.DisplayName
        Upn                            = $upn
        RecipientTypeDetails           = $m.RecipientTypeDetails
        AccountEnabled                 = $mgu.AccountEnabled
        UsageLocation                  = $mgu.UsageLocation
        PasswordNeverExpires           = ([string]$mgu.PasswordPolicies -like '*DisablePasswordExpiration*')
        Licenses                       = $lic
        HasTeamsRoomsLicense           = ($lic -match 'Teams_Rooms|MEETING_ROOM')  # verify exact SkuPartNumber in your tenant
        AutomateProcessing             = $cal.AutomateProcessing
        DeleteSubject                  = $cal.DeleteSubject
        DeleteComments                 = $cal.DeleteComments
        AddOrganizerToSubject          = $cal.AddOrganizerToSubject
        ProcessExternalMeetingMessages = $cal.ProcessExternalMeetingMessages
        AllowConflicts                 = $cal.AllowConflicts
        TeamsMeetingPolicy             = $cs.TeamsMeetingPolicy
        TeamsCallingPolicy             = $cs.TeamsCallingPolicy
    }
}

$report | Format-Table DisplayName,Upn,HasTeamsRoomsLicense,AutomateProcessing,DeleteSubject,TeamsMeetingPolicy -AutoSize
Export-IfRequested -Data $report -Name 'teams-rooms-assessment'

Write-Host "`nDiscovery complete. Review flags: HasTeamsRoomsLicense (verify SKU), DeleteSubject/DeleteComments should be False, AutomateProcessing should be AutoAccept." -ForegroundColor Green
if ($OutputPath) { Write-Host "CSV baseline written to: $OutputPath" -ForegroundColor Green }
