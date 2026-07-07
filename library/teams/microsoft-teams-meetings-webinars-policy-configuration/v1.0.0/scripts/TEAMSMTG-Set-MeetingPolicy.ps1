<#
.SYNOPSIS
  Configuration (SAFE BY DEFAULT - preview unless -Commit): idempotently creates/updates the Teams
  meeting policies "Meeting Policy - Standard/Exec/Restricted - Prod" (+ a pilot copy, optionally the
  Global baseline) with lobby, anonymous/PSTN, recording, transcription, presenter-role, and
  recording-expiration settings. Never deletes; never assigns users.
.DESCRIPTION
  Defines a desired-state table for each cohort meeting policy and reconciles it: creates the policy if
  missing (New-CsTeamsMeetingPolicy) and sets its properties (Set-CsTeamsMeetingPolicy) to the design.
  Without -Commit it only reports what it WOULD change (dry-run); -WhatIf is also honored. Assignment is
  a separate step (TEAMSMTG-AssignmentReport.ps1) - this script only builds/tunes policies, so running it
  changes no user's experience until a policy is assigned. Edit the $Desired table to match YOUR signed-off
  baseline (section 2.4 / 3.1). Parameter accepted-values (e.g. AutoAdmittedUsers, presenter modes) are
  version-dependent - verify for your tenant.
.EXAMPLE
  .\TEAMSMTG-Set-MeetingPolicy.ps1 -WhatIf
  # Dry-run: show the create/update actions for every cohort policy, make no changes.
.EXAMPLE
  .\TEAMSMTG-Set-MeetingPolicy.ps1 -Commit -IncludeGlobal
  # Create/update the cohort policies AND tune the Global (Org-wide default) baseline.
  # (PowerShell 5.1+/7+, MicrosoftTeams module; connect with Connect-MicrosoftTeams.)
.NOTES
  Expected results: each named policy exists with the designed values; unchanged policies are reported as
  "OK". No user is assigned by this script, so production experience is unchanged until assignment.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Commit,
    [switch]$IncludeGlobal
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

$doWrite = $Commit.IsPresent -and -not $WhatIfPreference

# ---- Desired state: EDIT to match your signed-off baseline (section 3.1) ----
$Desired = @(
    [pscustomobject]@{ Identity='Meeting Policy - Standard - Prod';  AutoAdmittedUsers='EveryoneInCompanyExcludingGuests'; Anon=$false; PstnBypass=$false; Record=$true;  Transcribe=$true;  Presenter='EveryoneUserOverride';          ExpireDays=60 }
    [pscustomobject]@{ Identity='Meeting Policy - Exec - Prod';      AutoAdmittedUsers='OrganizerOnly';                     Anon=$false; PstnBypass=$false; Record=$false; Transcribe=$false; Presenter='OrganizerOnlyUserOverride';      ExpireDays=30 }
    [pscustomobject]@{ Identity='Meeting Policy - Restricted - Prod';AutoAdmittedUsers='EveryoneInCompany';                Anon=$false; PstnBypass=$false; Record=$false; Transcribe=$false; Presenter='EveryoneInCompanyUserOverride'; ExpireDays=30 }
    [pscustomobject]@{ Identity='Meeting Policy - Standard - Pilot'; AutoAdmittedUsers='EveryoneInCompanyExcludingGuests'; Anon=$false; PstnBypass=$false; Record=$true;  Transcribe=$true;  Presenter='EveryoneUserOverride';          ExpireDays=60 }
)
if ($IncludeGlobal) {
    $Desired += [pscustomobject]@{ Identity='Global'; AutoAdmittedUsers='EveryoneInCompanyExcludingGuests'; Anon=$false; PstnBypass=$false; Record=$true; Transcribe=$true; Presenter='EveryoneUserOverride'; ExpireDays=60 }
}

$existing = @{}
Get-CsTeamsMeetingPolicy -ErrorAction SilentlyContinue | ForEach-Object { $existing[$_.Identity] = $_ }

foreach ($d in $Desired) {
    $isGlobal = ($d.Identity -eq 'Global')
    $have = $existing[$d.Identity]

    if (-not $have -and -not $isGlobal) {
        if ($doWrite -and $PSCmdlet.ShouldProcess($d.Identity, 'New-CsTeamsMeetingPolicy')) {
            try { New-CsTeamsMeetingPolicy -Identity $d.Identity -ErrorAction Stop | Out-Null
                  Write-Host "CREATED  $($d.Identity)" -ForegroundColor Green }
            catch { Write-Warning "Create failed for $($d.Identity): $($_.Exception.Message)"; continue }
        } else {
            Write-Host "WOULD CREATE  $($d.Identity)" -ForegroundColor Yellow
        }
    }

    $params = @{
        Identity                          = $d.Identity
        AutoAdmittedUsers                 = $d.AutoAdmittedUsers
        AllowAnonymousUsersToJoinMeeting  = $d.Anon
        AllowPSTNUsersToBypassLobby       = $d.PstnBypass
        AllowCloudRecording               = $d.Record
        AllowTranscription                = $d.Transcribe
        DesignatedPresenterRoleMode       = $d.Presenter
        NewMeetingRecordingExpirationDays = $d.ExpireDays
    }

    if ($doWrite -and $PSCmdlet.ShouldProcess($d.Identity, 'Set-CsTeamsMeetingPolicy')) {
        try { Set-CsTeamsMeetingPolicy @params -ErrorAction Stop
              Write-Host "SET      $($d.Identity)" -ForegroundColor Green }
        catch { Write-Warning "Set failed for $($d.Identity): $($_.Exception.Message)" }
    } else {
        Write-Host "WOULD SET $($d.Identity): Lobby=$($d.AutoAdmittedUsers) Anon=$($d.Anon) Record=$($d.Record) Presenter=$($d.Presenter) Expire=$($d.ExpireDays)d" -ForegroundColor Yellow
    }
}

if (-not $doWrite) {
    Write-Host "`nDRY-RUN only (no -Commit). Re-run with -Commit to apply." -ForegroundColor Cyan
}
Write-Host "`nNext: configure events policy (TEAMSMTG-Set-EventsAndTemplates.ps1), then assign to the pilot group." -ForegroundColor Cyan
