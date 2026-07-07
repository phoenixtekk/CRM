<#
.SYNOPSIS
  Validation (READ-ONLY): pass/fail check that the named meeting policies exist and match the design, the
  org anonymous-join stance is set, group assignments/ranks are in place, and sampled users resolve to the
  expected effective meeting policy. Emits "Meeting Validation - Teams - Report". Makes no changes.
.DESCRIPTION
  Confirms each expected meeting policy exists (Get-CsTeamsMeetingPolicy), reads the org meeting
  configuration (Get-CsTeamsMeetingConfiguration DisableAnonymousJoin), lists group policy assignments
  (Get-CsGroupPolicyAssignment), and - if -SampleGroup is given - resolves each member's effective meeting
  policy (Get-CsUserPolicyAssignment) via Microsoft Graph membership. Every check yields PASS/FAIL. This is
  the read-only companion to the live meeting tests in the Testing guide (lobby/recording/presenter must
  still be confirmed in a real meeting).
.EXAMPLE
  .\TEAMSMTG-Validation.ps1
  # Read-only PASS/FAIL of policy existence, org anonymous stance, and assignments.
.EXAMPLE
  .\TEAMSMTG-Validation.ps1 -SampleGroup 'Meeting Scope - Pilot - Group' -CsvPath .\pilot-validation.csv
  # Also resolve effective policy for each pilot member and export the report.
  # (PowerShell 5.1+/7+, MicrosoftTeams + Microsoft.Graph; Connect-MicrosoftTeams and
  #  Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'.)
.NOTES
  Expected results: one PASS/FAIL row per check. All PASS (plus the live tests 5-10 in the Testing guide)
  is the gate to expand to the next wave.
#>

[CmdletBinding()]
param(
    [string]$SampleGroup,
    [string]$CsvPath
)

function Confirm-TeamsConnected {
    try { Get-CsTenant -ErrorAction Stop | Out-Null; return $true }
    catch {
        try { Connect-MicrosoftTeams -ErrorAction Stop | Out-Null; return $true }
        catch { Write-Error "Connect-MicrosoftTeams failed: $($_.Exception.Message)"; return $false }
    }
}
if (-not (Confirm-TeamsConnected)) { return }

$rows = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Check,[string]$Target,[bool]$Pass,[string]$Detail) {
    $rows.Add([pscustomobject]@{ Check=$Check; Target=$Target; Result=($(if($Pass){'PASS'}else{'FAIL'})); Detail=$Detail })
}

# 1) Expected policies exist
$expected = 'Meeting Policy - Standard - Prod','Meeting Policy - Exec - Prod','Meeting Policy - Restricted - Prod'
$present  = (Get-CsTeamsMeetingPolicy -ErrorAction SilentlyContinue).Identity
foreach ($e in $expected) {
    Add-Check 'Policy exists' $e ($present -contains $e) $(if($present -contains $e){'found'}else{'missing - run Set-MeetingPolicy -Commit'})
}

# 2) Org anonymous-join stance set
try {
    $cfg = Get-CsTeamsMeetingConfiguration -Identity Global -ErrorAction Stop
    Add-Check 'Org anonymous stance' 'Meeting Config - Org - Prod' ($null -ne $cfg.DisableAnonymousJoin) "DisableAnonymousJoin=$($cfg.DisableAnonymousJoin)"
} catch {
    Add-Check 'Org anonymous stance' 'Meeting Config - Org - Prod' $false $_.Exception.Message
}

# 3) Group assignments present
$anyAssign = $false
try {
    $ga = Get-CsGroupPolicyAssignment -PolicyType TeamsMeetingPolicy -ErrorAction Stop
    $anyAssign = [bool]$ga
    foreach ($a in $ga) { Add-Check 'Group assignment' $a.PolicyName $true "GroupId=$($a.GroupId) Rank=$($a.Rank)" }
} catch { }
if (-not $anyAssign) { Add-Check 'Group assignment' 'TeamsMeetingPolicy' $false 'no meeting-policy group assignments found' }

# 4) Effective policy per sampled user
if ($SampleGroup) {
    try {
        $grp = Get-MgGroup -Filter "displayName eq '$SampleGroup'" -ErrorAction Stop | Select-Object -First 1
        if (-not $grp) { throw "group '$SampleGroup' not found via Graph" }
        $members = Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction Stop
        foreach ($m in $members) {
            $upn = $m.AdditionalProperties.userPrincipalName
            if (-not $upn) { continue }
            try {
                $eff = Get-CsUserPolicyAssignment -Identity $upn -PolicyType TeamsMeetingPolicy -ErrorAction Stop
                $name = ($eff | Select-Object -First 1).PolicyName
                Add-Check 'Effective policy' $upn ($null -ne $name) "effective=$([string]::IsNullOrEmpty($name) ? 'Global (default)' : $name)"
            } catch {
                Add-Check 'Effective policy' $upn $false $_.Exception.Message
            }
        }
    } catch {
        Add-Check 'Effective policy' $SampleGroup $false "Graph lookup failed: $($_.Exception.Message) (Connect-MgGraph -Scopes Group.Read.All,User.Read.All)"
    }
}

Write-Host "`nMeeting Validation - Teams - Report" -ForegroundColor Green
$rows | Format-Table Check, Target, Result, Detail -AutoSize

$fail = ($rows | Where-Object Result -eq 'FAIL').Count
if ($fail) { Write-Host "`n$fail check(s) FAILED - resolve before expanding." -ForegroundColor Red }
else       { Write-Host "`nAll read-only checks PASS. Confirm the live meeting tests (lobby/recording/presenter) before expanding." -ForegroundColor Green }

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Exported report to $CsvPath" -ForegroundColor Cyan }
