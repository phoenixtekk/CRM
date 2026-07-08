<#
.SYNOPSIS
    IPMEET-Check-Prereqs.ps1 — Prerequisite/health helper for meeting sensitivity labeling (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the tooling and tenant signals are in place before you configure meeting labels: the
        required PowerShell modules and connections, the Security & Compliance and Teams roles reachable,
        whether any Meetings-scoped labels already exist, and best-effort Teams-Premium / Meetings-scope
        availability signals. Read-only — makes no change. Supports the Assess step and the Testing Guide.
    HOW TO RUN
        .\IPMEET-Check-Prereqs.ps1
        PowerShell 5.1+/7+. Connect first with Connect-IPPSSession and Connect-MicrosoftTeams (modern-auth
        /MFA admin). No secret is stored in the script.
    EXPECTED RESULTS
        A PASS/GAP line per signal: modules present, connections live, Meetings-scoped labels present or
        absent, Teams meeting-policy readable. Any gap (e.g. Teams Premium not confirmed → Premium-only
        controls deferred) is reported, not guessed.
.NOTES
    Purview — Sensitivity Labeling for Meetings. Read-only. Verify your licensing/tenant: Teams Premium
    and the Meetings-scope capability gate the meeting-option protections; confirm both in the portal/
    licensing rather than inferring them from a script signal alone.
#>
[CmdletBinding()]
param(
    [string]$MeetingScopeMatch = 'Meeting'
)

function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Line([string]$Label, [bool]$Ok, [string]$Detail) {
    $tag = $(if ($Ok) { 'PASS' } else { 'GAP ' })
    $col = $(if ($Ok) { 'Green' } else { 'Yellow' })
    Write-Host ("{0,-26}: {1} — {2}" -f $Label, $tag, $Detail) -ForegroundColor $col
}

Write-Host "`n=== Sensitivity Labeling for Meetings — prerequisite / health check (read-only) ===" -ForegroundColor Cyan

# --- Modules ------------------------------------------------------------------------------------------
$exo   = [bool](Get-Module -ListAvailable -Name ExchangeOnlineManagement)
$teams = [bool](Get-Module -ListAvailable -Name MicrosoftTeams)
Line 'ExchangeOnlineManagement' $exo   $(if($exo){'installed'}else{'missing — Install-Module ExchangeOnlineManagement -Scope CurrentUser'})
Line 'MicrosoftTeams module'    $teams $(if($teams){'installed'}else{'missing — Install-Module MicrosoftTeams -Scope CurrentUser'})

# --- Connections --------------------------------------------------------------------------------------
$ippsOk = Test-Command 'Get-Label'
Line 'S&C PowerShell session'  $ippsOk $(if($ippsOk){'Get-Label available (Connect-IPPSSession live)'}else{'run Connect-IPPSSession'})

$teamsConn = Test-Command 'Get-CsTeamsMeetingPolicy'
Line 'Teams session'           $teamsConn $(if($teamsConn){'Get-CsTeamsMeetingPolicy available (Connect-MicrosoftTeams live)'}else{'run Connect-MicrosoftTeams'})

# --- Roles (best-effort: successful reads imply the role is present) ----------------------------------
if ($ippsOk) {
    try {
        $null = Get-LabelPolicy -ErrorAction Stop
        Line 'Purview label admin' $true 'Get-Label/Get-LabelPolicy succeed (Information Protection Admin / Compliance Admin)'
    } catch {
        Line 'Purview label admin' $false ("could not read label policies: {0}" -f $_.Exception.Message)
    }
}
if ($teamsConn) {
    try {
        $null = Get-CsTeamsMeetingPolicy -ErrorAction Stop
        Line 'Teams admin read' $true 'Get-CsTeamsMeetingPolicy succeeds (Teams Administrator)'
    } catch {
        Line 'Teams admin read' $false ("could not read Teams meeting policy: {0}" -f $_.Exception.Message)
    }
}

# --- Meetings-scoped labels already present? ----------------------------------------------------------
if ($ippsOk) {
    try {
        $labels = @(Get-Label -ErrorAction Stop)
        $meeting = @($labels | Where-Object { ($_.ContentType -match $MeetingScopeMatch) -or ($_.DisplayName -match $MeetingScopeMatch) })
        Line 'Meetings-scoped labels' ($meeting.Count -gt 0) ("{0} present matching '{1}'" -f $meeting.Count, $MeetingScopeMatch)
        if ($meeting.Count -eq 0) {
            Write-Host "    (none yet — author them per the Implementation Guide; verify the Meetings scope wording in ContentType for your tenant)" -ForegroundColor DarkGray
        }
    } catch {
        Line 'Meetings-scoped labels' $false ("could not enumerate labels: {0}" -f $_.Exception.Message)
    }
}

# --- Teams Premium / Meetings-scope availability (informational, verify in portal) --------------------
Write-Host "`nLicensing signals (verify against your own plan — do not rely on a script signal alone):" -ForegroundColor Cyan
Write-Host "  - Teams Premium gates the meeting-option protections (recording control, watermark, E2EE)." -ForegroundColor DarkGray
Write-Host "  - Confirm the 'Meetings and calendar events' scope is selectable when editing a label in the Purview portal." -ForegroundColor DarkGray
Write-Host "  - Check M365 admin center > Billing > Licenses for the sensitivity-label SKU and Teams Premium." -ForegroundColor DarkGray

Write-Host "`nRemediate any GAP before authoring/publishing meeting labels. Record deferred (Premium-gated) controls explicitly." -ForegroundColor Cyan
