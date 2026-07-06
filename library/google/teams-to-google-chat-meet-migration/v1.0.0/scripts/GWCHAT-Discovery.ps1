<#
.SYNOPSIS
    GWCHAT-Discovery.ps1 — baseline the Microsoft Teams source estate for a Chat & Meet migration.
.DESCRIPTION
    PURPOSE
        Captures the Teams source-estate baseline the channel-to-space mapping and wave plan are built
        from: the count of teams, their standard channels, per-channel membership, and group signals,
        read from the Microsoft Teams / Microsoft 365 source through Microsoft Graph. Read-only — it
        supports the Assess step and moves no messages, creates no spaces, and changes nothing on either
        platform. File volumes, meeting counts, and integrations the API cannot read are recorded by
        hand into the baseline artifact.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCHAT-Discovery.ps1
        Optional: -CsvPath .\gwchat-baseline.csv to export a per-team channel summary.
        Optional: -MaxTeams 200 to sample large estates.
        Requires the Microsoft Graph PowerShell SDK. On first run, consent to the read scopes:
        Team.ReadBasic.All, Channel.ReadBasic.All, ChannelMember.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A baseline summary: total teams, total standard channels, average channels per team, and a
        per-team channel/member table, with a PASS/GAP line per signal you record against the
        Requirements checklist as GWCHAT Discovery - Teams Estate - Baseline.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [int]$MaxTeams = 0
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Team.ReadBasic.All','Channel.ReadBasic.All','ChannelMember.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Teams -> Chat/Meet migration — source-estate discovery ===" -ForegroundColor Cyan

# Enumerate teams (groups with a team resource).
$teams = @()
try {
    $next = "/v1.0/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')&`$select=id,displayName&`$top=999"
    do {
        $r = Invoke-MgGraphRequest -Method GET -Uri $next
        $teams += $r.value
        $next = $r.'@odata.nextLink'
    } while ($next)
} catch {
    Write-Host ("Teams                  : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}
$totalTeams = @($teams).Count
Write-Host ("Teams (total)          : {0}" -f $totalTeams)

if ($MaxTeams -gt 0 -and $totalTeams -gt $MaxTeams) {
    Write-Host ("Sampling first {0} of {1} teams (-MaxTeams)." -f $MaxTeams, $totalTeams) -ForegroundColor Yellow
    $teams = $teams | Select-Object -First $MaxTeams
}

# Per-team standard channels and membership.
$rows = @()
$totalChannels = 0
foreach ($t in $teams) {
    $channels = @()
    try {
        $cr = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/teams/{0}/channels?`$select=id,displayName,membershipType" -f $t.id)
        $channels = @($cr.value | Where-Object { $_.membershipType -eq 'standard' -or -not $_.membershipType })
    } catch {
        Write-Host ("  channels unreadable for team {0}: {1}" -f $t.displayName, $_.Exception.Message) -ForegroundColor Yellow
    }
    $memberCount = 0
    try {
        $mr = Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/teams/{0}/members?`$select=id" -f $t.id)
        $memberCount = @($mr.value).Count
    } catch {}
    $totalChannels += @($channels).Count
    $rows += [pscustomobject]@{
        Team            = $t.displayName
        TeamId          = $t.id
        StandardChannels= @($channels).Count
        Members         = $memberCount
    }
}

Write-Host ("Standard channels      : {0}" -f $totalChannels)
$avg = if ($totalTeams -gt 0) { [math]::Round($totalChannels / [math]::Max(@($teams).Count,1), 1) } else { 0 }
Write-Host ("Avg channels per team  : {0}" -f $avg)

# Groups / distribution lists (adoption/notification context).
$groups = 0
try {
    $next = "/v1.0/groups?`$select=id&`$top=999"
    do { $g = Invoke-MgGraphRequest -Method GET -Uri $next; $groups += @($g.value).Count; $next = $g.'@odata.nextLink' } while ($next)
    Write-Host ("Groups / dist. lists   : {0}" -f $groups)
} catch {
    Write-Host ("Groups / dist. lists   : not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($rows.Count -gt 0) {
    Write-Host "`n--- Per-team channel/member table (top 25) ---" -ForegroundColor Cyan
    $rows | Sort-Object StandardChannels -Descending | Select-Object -First 25 | Format-Table -AutoSize
}

# Signals
$teamsOk    = $totalTeams -gt 0
$channelsOk = $totalChannels -gt 0
Write-Host ""
Write-Host ("Signal — teams estate  : {0}" -f ($(if($teamsOk){'PASS — teams enumerable for space mapping'}else{'GAP — confirm Teams read access'}))) -ForegroundColor ($(if($teamsOk){'Green'}else{'Yellow'}))
Write-Host ("Signal — channels      : {0}" -f ($(if($channelsOk){'PASS — channels readable for channel->space mapping'}else{'GAP — confirm channel read scope'}))) -ForegroundColor ($(if($channelsOk){'Green'}else{'Yellow'}))

Write-Host "`nRecord these counts in GWCHAT Discovery - Teams Estate - Baseline, then add per-channel file" -ForegroundColor Cyan
Write-Host "volumes, recurring-meeting counts, and integrations by hand. 1:1/private chats are out of scope" -ForegroundColor Cyan
Write-Host "for the native channel migration — set that expectation in the mapping and adoption comms." -ForegroundColor Cyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved {0}" -f $CsvPath)
}

Disconnect-MgGraph | Out-Null
