<#
.SYNOPSIS
    TEAMSROOMS-HealthReport — Produce a fleet health/inventory report for Microsoft
    Teams Rooms: account state, licensing, calendar-processing conformance, and
    policy grants, flagging non-conformant rooms. READ-ONLY.

.DESCRIPTION
    Builds an inventory of every room mailbox (or a supplied list) and evaluates each
    against the Teams Rooms standard, emitting an object per room plus a summary. Writes
    CSV and (optionally) a simple HTML report. Note: live device/firmware health telemetry
    lives in the Teams Rooms Pro Management portal and the Teams admin center; this report
    covers the tenant-side configuration health that PowerShell can read. READ-ONLY.

.PARAMETER RoomListPath
    Optional path to a text file of room UPNs (one per line). If omitted, all room
    mailboxes are reported.

.PARAMETER OutputPath
    Directory for the CSV/HTML output. Defaults to the current directory.

.PARAMETER Html
    Also emit an HTML report alongside the CSV.

.EXAMPLE
    .\TEAMSROOMS-HealthReport.ps1 -OutputPath .\reports -Html
    (PowerShell 5.1+/7+; ExchangeOnlineManagement + Microsoft.Graph + MicrosoftTeams;
     Connect-ExchangeOnline, Connect-MgGraph, Connect-MicrosoftTeams)

.NOTES
    Expected results: teams-rooms-health-<date>.csv (and .html) listing every room with
    a Conformant = True/False verdict and the specific gaps. Pair with the Pro Management
    portal for device firmware/online health.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$RoomListPath,
    [Parameter(Mandatory = $false)][string]$OutputPath = '.',
    [Parameter(Mandatory = $false)][switch]$Html
)

$ErrorActionPreference = 'Stop'

function Assert-Module {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Install)
    if (-not (Get-Module -ListAvailable -Name $Name)) { throw "$Name not installed. Run: $Install" }
    Import-Module $Name -ErrorAction Stop
}

Assert-Module -Name ExchangeOnlineManagement -Install "Install-Module ExchangeOnlineManagement -Scope CurrentUser"
Assert-Module -Name Microsoft.Graph          -Install "Install-Module Microsoft.Graph -Scope CurrentUser"
Assert-Module -Name MicrosoftTeams           -Install "Install-Module MicrosoftTeams -Scope CurrentUser"
if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) { Connect-ExchangeOnline -ShowBanner:$false | Out-Null }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All" | Out-Null }
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

# Resolve the room set
if ($RoomListPath) {
    $upns  = Get-Content -Path $RoomListPath | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
    $rooms = foreach ($u in $upns) { Get-Mailbox -Identity $u -ErrorAction SilentlyContinue }
} else {
    $rooms = Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited
}
if (-not $rooms) { Write-Host "No rooms to report." -ForegroundColor Red; return }

Write-Host "Evaluating $($rooms.Count) room(s)..." -ForegroundColor Yellow

$rows = foreach ($m in $rooms) {
    $upn = $m.PrimarySmtpAddress.ToString()
    $cal = Get-CalendarProcessing -Identity $upn -ErrorAction SilentlyContinue
    $mgu = Get-MgUser -UserId $upn -Property Id,AccountEnabled,UsageLocation,PasswordPolicies -ErrorAction SilentlyContinue
    $lic = if ($mgu) { (Get-MgUserLicenseDetail -UserId $mgu.Id -ErrorAction SilentlyContinue).SkuPartNumber -join ';' } else { '' }
    $cs  = Get-CsOnlineUser -Identity $upn -ErrorAction SilentlyContinue

    $gaps = New-Object System.Collections.Generic.List[string]
    if (-not $mgu.AccountEnabled)                                   { $gaps.Add('AccountDisabled') }
    if (-not $mgu.UsageLocation)                                    { $gaps.Add('NoUsageLocation') }
    if ([string]$mgu.PasswordPolicies -notlike '*DisablePasswordExpiration*') { $gaps.Add('PasswordCanExpire') }
    if ($lic -notmatch 'Teams_Rooms|MEETING_ROOM')                 { $gaps.Add('NoTeamsRoomsLicense?') }  # verify SKU
    if ($cal.AutomateProcessing -ne 'AutoAccept')                  { $gaps.Add('NotAutoAccept') }
    if ($cal.DeleteSubject)                                        { $gaps.Add('DeleteSubjectTrue') }
    if ($cal.DeleteComments)                                       { $gaps.Add('DeleteCommentsTrue') }
    if ($cs -and $cs.TeamsMeetingPolicy -notlike '*Teams Rooms*')  { $gaps.Add('MeetingPolicyNotRoom') }

    [pscustomobject]@{
        DisplayName        = $m.DisplayName
        Upn                = $upn
        AccountEnabled     = $mgu.AccountEnabled
        UsageLocation      = $mgu.UsageLocation
        Licenses           = $lic
        AutomateProcessing = $cal.AutomateProcessing
        TeamsMeetingPolicy = $cs.TeamsMeetingPolicy
        TeamsCallingPolicy = $cs.TeamsCallingPolicy
        Conformant         = ($gaps.Count -eq 0)
        Gaps               = ($gaps -join ', ')
    }
}

$date = Get-Date -Format 'yyyy-MM-dd'
$csv  = Join-Path $OutputPath "teams-rooms-health-$date.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$total = $rows.Count
$ok    = ($rows | Where-Object Conformant).Count
Write-Host "`nRooms: $total  Conformant: $ok  Non-conformant: $($total - $ok)" -ForegroundColor Green
Write-Host "CSV: $csv" -ForegroundColor Green
$rows | Format-Table DisplayName,Conformant,Gaps -AutoSize

if ($Html) {
    $htmlPath = Join-Path $OutputPath "teams-rooms-health-$date.html"
    $style = "<style>body{font-family:Segoe UI,Arial,sans-serif}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:6px}</style>"
    $rows | ConvertTo-Html -Title "Teams Rooms Health $date" -Head $style `
        -PreContent "<h2>Teams Rooms Health — $date</h2><p>Rooms: $total | Conformant: $ok | Non-conformant: $($total-$ok)</p>" |
        Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "HTML: $htmlPath" -ForegroundColor Green
}
