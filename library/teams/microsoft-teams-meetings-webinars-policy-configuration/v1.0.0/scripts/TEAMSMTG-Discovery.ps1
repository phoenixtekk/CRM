<#
.SYNOPSIS
  Discovery (READ-ONLY): produces the "Meeting Posture - Teams - Discovery" snapshot of Teams meeting
  policies, the events policy (webinars/town halls), org-wide meeting configuration, and existing group
  policy assignments. Makes no changes.
.DESCRIPTION
  Connects to Microsoft Teams (modern auth) and enumerates every Teams meeting policy
  (Get-CsTeamsMeetingPolicy) with the security-relevant settings (lobby, anonymous/PSTN join, cloud
  recording, transcription, presenter role, recording expiration), every events policy
  (Get-CsTeamsEventsPolicy), the org meeting configuration (Get-CsTeamsMeetingConfiguration, notably
  DisableAnonymousJoin), and current group policy assignments (Get-CsGroupPolicyAssignment). Read-only.
.EXAMPLE
  .\TEAMSMTG-Discovery.ps1
  # Read-only posture summary to the console.
.EXAMPLE
  .\TEAMSMTG-Discovery.ps1 -CsvFolder .\posture
  # Also export meeting policies, events policies, org config, and assignments to CSV in .\posture.
  # (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams.
  #  Government cloud: add -TeamsEnvironmentName, e.g. TeamsGCCH / TeamsDOD - verify for your cloud.)
.NOTES
  Expected results: one row per meeting policy and per events policy, the org meeting configuration, and
  the current group assignments. No changes are made. Use this to establish the baseline (Gate G0) before
  designing/configuring.
#>

[CmdletBinding()]
param(
    [string]$CsvFolder
)

function Confirm-TeamsConnected {
    try { Get-CsTenant -ErrorAction Stop | Out-Null; return $true }
    catch {
        Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Cyan
        try { Connect-MicrosoftTeams -ErrorAction Stop | Out-Null; return $true }
        catch { Write-Error "Connect-MicrosoftTeams failed: $($_.Exception.Message)"; return $false }
    }
}

if (-not (Confirm-TeamsConnected)) { return }

if ($CsvFolder -and -not (Test-Path $CsvFolder)) {
    New-Item -ItemType Directory -Path $CsvFolder -Force | Out-Null
}

# --- Meeting policies -------------------------------------------------------
Write-Host "`nMeeting Posture - Teams - Discovery : meeting policies" -ForegroundColor Green
$mp = Get-CsTeamsMeetingPolicy -ErrorAction SilentlyContinue | ForEach-Object {
    [pscustomobject]@{
        Identity                       = $_.Identity
        AutoAdmittedUsers              = $_.AutoAdmittedUsers
        AllowAnonymousUsersToJoin      = $_.AllowAnonymousUsersToJoinMeeting
        AllowPSTNUsersToBypassLobby    = $_.AllowPSTNUsersToBypassLobby
        AllowCloudRecording            = $_.AllowCloudRecording
        AllowTranscription             = $_.AllowTranscription
        DesignatedPresenterRoleMode    = $_.DesignatedPresenterRoleMode
        NewMeetingRecordingExpirationDays = $_.NewMeetingRecordingExpirationDays
        MeetingChatEnabledType         = $_.MeetingChatEnabledType
    }
}
$mp | Format-Table -AutoSize

# --- Events policy (webinars / town halls) ----------------------------------
Write-Host "`nMeeting Posture - Teams - Discovery : events policies (webinars / town halls)" -ForegroundColor Green
$ep = Get-CsTeamsEventsPolicy -ErrorAction SilentlyContinue | ForEach-Object {
    [pscustomobject]@{
        Identity      = $_.Identity
        AllowWebinars = $_.AllowWebinars
        AllowTownhalls= $_.AllowTownhalls
    }
}
if ($ep) { $ep | Format-Table -AutoSize } else { Write-Host "  (events policy cmdlet returned nothing - verify module version)" -ForegroundColor DarkYellow }

# --- Org meeting configuration ----------------------------------------------
Write-Host "`nMeeting Posture - Teams - Discovery : org meeting configuration (Meeting Config - Org - Prod)" -ForegroundColor Green
$cfg = $null
try {
    $cfg = Get-CsTeamsMeetingConfiguration -Identity Global -ErrorAction Stop |
        Select-Object DisableAnonymousJoin, DisableAnonymousJoinForWebinars -ErrorAction SilentlyContinue
    $cfg | Format-List
} catch {
    Write-Host "  Could not read meeting configuration: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# --- Group policy assignments ----------------------------------------------
Write-Host "`nMeeting Posture - Teams - Discovery : group policy assignments" -ForegroundColor Green
$ga = @()
foreach ($pt in 'TeamsMeetingPolicy','TeamsEventsPolicy') {
    try {
        Get-CsGroupPolicyAssignment -PolicyType $pt -ErrorAction Stop | ForEach-Object {
            $ga += [pscustomobject]@{
                PolicyType = $pt
                GroupId    = $_.GroupId
                PolicyName = $_.PolicyName
                Rank       = $_.Rank
            }
        }
    } catch {
        Write-Host "  No $pt group assignments (or cmdlet unavailable): $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}
if ($ga) { $ga | Format-Table -AutoSize } else { Write-Host "  (no group policy assignments found)" -ForegroundColor DarkGray }

# --- Optional CSV export ----------------------------------------------------
if ($CsvFolder) {
    $mp | Export-Csv -Path (Join-Path $CsvFolder 'meeting-policies.csv') -NoTypeInformation -Encoding UTF8
    if ($ep) { $ep | Export-Csv -Path (Join-Path $CsvFolder 'events-policies.csv') -NoTypeInformation -Encoding UTF8 }
    if ($cfg){ $cfg | Export-Csv -Path (Join-Path $CsvFolder 'org-meeting-config.csv') -NoTypeInformation -Encoding UTF8 }
    if ($ga) { $ga | Export-Csv -Path (Join-Path $CsvFolder 'group-assignments.csv') -NoTypeInformation -Encoding UTF8 }
    Write-Host "`nExported posture CSVs to $CsvFolder" -ForegroundColor Cyan
}

Write-Host "`nNext: agree the target baseline (Gate G0), then run TEAMSMTG-Set-MeetingPolicy.ps1 -WhatIf." -ForegroundColor Cyan
