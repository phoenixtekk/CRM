<#
.SYNOPSIS
    TEAMSROOMS-Validation — Validate one or more Teams Rooms resource accounts against
    the deployment gates (provisioned, licensed, calendar, policy). Doubles as the
    scope/readiness helper. READ-ONLY — makes no changes.

.DESCRIPTION
    For each room (a single UPN, a room-list file, or an Entra group of rooms), checks
    the tenant-side gates from Section 5:
      V1 Provisioned : RoomMailbox + AccountEnabled + UsageLocation + PasswordNeverExpires
      V2 Licensed    : a Teams Rooms SKU assigned (verify SkuPartNumber in your tenant)
      V3 Calendar    : AutoAccept; DeleteSubject/DeleteComments false; ProcessExternal true
      V4 Policy      : meeting & calling policies look room-specific
    Emits PASS/FAIL per room and a summary, and returns non-zero exit code if any FAIL,
    so it can gate an expansion pipeline. In-room join/media (V5) and Pro Management
    health (V6) are manual checks per Section 5. READ-ONLY.

.PARAMETER Upn
    A single room UPN to validate.

.PARAMETER RoomListPath
    Path to a text file of room UPNs (one per line).

.PARAMETER GroupId
    Entra group object id whose members are room accounts to validate (the pilot
    group, e.g. "Room Group - Pilot - Stage 1").

.EXAMPLE
    .\TEAMSROOMS-Validation.ps1 -Upn room-boardroom-a@contoso.com
    (PowerShell 5.1+/7+; ExchangeOnlineManagement + Microsoft.Graph + MicrosoftTeams;
     Connect-ExchangeOnline, Connect-MgGraph, Connect-MicrosoftTeams)

.EXAMPLE
    .\TEAMSROOMS-Validation.ps1 -GroupId 00000000-0000-0000-0000-000000000000

.NOTES
    Expected results: a per-room table of V1–V4 PASS/FAIL and an overall verdict.
    Exit code 0 = all rooms pass; 1 = at least one gate failed. Use before Expand.
#>

[CmdletBinding(DefaultParameterSetName = 'Upn')]
param(
    [Parameter(ParameterSetName = 'Upn', Mandatory)][string]$Upn,
    [Parameter(ParameterSetName = 'List', Mandatory)][string]$RoomListPath,
    [Parameter(ParameterSetName = 'Group', Mandatory)][string]$GroupId
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
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "User.Read.All","Organization.Read.All","Group.Read.All" | Out-Null }
try { $null = Get-CsTenant -ErrorAction Stop } catch { Connect-MicrosoftTeams | Out-Null }

# Resolve scope -> list of UPNs
switch ($PSCmdlet.ParameterSetName) {
    'Upn'   { $targets = @($Upn) }
    'List'  { $targets = Get-Content -Path $RoomListPath | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() } }
    'Group' { $targets = (Get-MgGroupMember -GroupId $GroupId -All | ForEach-Object {
                  (Get-MgUser -UserId $_.Id -Property UserPrincipalName -ErrorAction SilentlyContinue).UserPrincipalName
              }) | Where-Object { $_ } }
}
if (-not $targets) { Write-Host "No rooms in scope." -ForegroundColor Red; exit 1 }

Write-Host "Validating $($targets.Count) room(s)...`n" -ForegroundColor Yellow

$results = foreach ($t in $targets) {
    $mbx = Get-Mailbox -Identity $t -ErrorAction SilentlyContinue
    $cal = Get-CalendarProcessing -Identity $t -ErrorAction SilentlyContinue
    $mgu = Get-MgUser -UserId $t -Property Id,AccountEnabled,UsageLocation,PasswordPolicies -ErrorAction SilentlyContinue
    $lic = if ($mgu) { (Get-MgUserLicenseDetail -UserId $mgu.Id -ErrorAction SilentlyContinue).SkuPartNumber -join ';' } else { '' }
    $cs  = Get-CsOnlineUser -Identity $t -ErrorAction SilentlyContinue

    $v1 = ($mbx.RecipientTypeDetails -eq 'RoomMailbox') -and $mgu.AccountEnabled -and $mgu.UsageLocation -and ([string]$mgu.PasswordPolicies -like '*DisablePasswordExpiration*')
    $v2 = ($lic -match 'Teams_Rooms|MEETING_ROOM')  # verify exact SkuPartNumber in your tenant
    $v3 = ($cal.AutomateProcessing -eq 'AutoAccept') -and (-not $cal.DeleteSubject) -and (-not $cal.DeleteComments) -and $cal.ProcessExternalMeetingMessages
    $v4 = ($cs -and $cs.TeamsMeetingPolicy -like '*Teams Rooms*' -and $cs.TeamsCallingPolicy -like '*Teams Rooms*')

    [pscustomobject]@{
        Room       = $t
        V1_Provisioned = if ($v1) { 'PASS' } else { 'FAIL' }
        V2_Licensed    = if ($v2) { 'PASS' } else { 'FAIL' }
        V3_Calendar    = if ($v3) { 'PASS' } else { 'FAIL' }
        V4_Policy      = if ($v4) { 'PASS' } else { 'FAIL' }
        Overall        = if ($v1 -and $v2 -and $v3 -and $v4) { 'PASS' } else { 'FAIL' }
    }
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { $_.Overall -eq 'FAIL' })
Write-Host "`n$($results.Count - $failed.Count)/$($results.Count) room(s) PASS all gates. V5 (join/media) and V6 (Pro Management health) are manual — see Section 5." -ForegroundColor Green
if ($failed.Count -gt 0) { Write-Host "FAIL: $($failed.Room -join ', ')" -ForegroundColor Red; exit 1 } else { exit 0 }
