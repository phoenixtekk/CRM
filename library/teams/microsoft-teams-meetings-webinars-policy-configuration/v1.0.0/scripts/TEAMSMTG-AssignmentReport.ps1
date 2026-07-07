<#
.SYNOPSIS
  Scope/health helper (SAFE BY DEFAULT - reports unless -AssignGroup ... -Commit): reports group policy
  assignments and the effective meeting policy per sampled user, and can apply a ranked group policy
  assignment (New-CsGroupPolicyAssignment) to a named group.
.DESCRIPTION
  In report mode (default) it lists current group policy assignments for the chosen -PolicyType and, if
  -SampleGroup is given, resolves each member's effective policy so you can see who gets what and spot
  ranking surprises. In assign mode (-AssignGroup <name> -PolicyType <type> -PolicyName <policy> -Rank <n>)
  it previews (or, with -Commit, applies) a New-CsGroupPolicyAssignment - lower Rank = higher precedence.
  Group is resolved by displayName via Microsoft Graph. No stored credentials; modern auth only.
.EXAMPLE
  .\TEAMSMTG-AssignmentReport.ps1 -SampleGroup 'Meeting Scope - Exec - Group'
  # Report-only: current assignments + effective meeting policy for each exec-group member.
.EXAMPLE
  .\TEAMSMTG-AssignmentReport.ps1 -AssignGroup 'Meeting Scope - Exec - Group' -PolicyType TeamsMeetingPolicy `
      -PolicyName 'Meeting Policy - Exec - Prod' -Rank 1 -WhatIf
  # Preview the ranked assignment; re-run with -Commit (drop -WhatIf) to apply.
  # (PowerShell 5.1+/7+, MicrosoftTeams + Microsoft.Graph; Connect-MicrosoftTeams and
  #  Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'.)
.NOTES
  Expected results: report mode prints assignments + effective policy per user; assign mode creates the
  "Meeting Assignment - <cohort> - Group" via New-CsGroupPolicyAssignment only when -Commit is passed.
  A user in multiple assigned groups gets the lowest-Rank assignment for that policy type.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SampleGroup,
    [string]$AssignGroup,
    [ValidateSet('TeamsMeetingPolicy','TeamsEventsPolicy')]
    [string]$PolicyType = 'TeamsMeetingPolicy',
    [string]$PolicyName,
    [int]$Rank = 1,
    [switch]$Commit
)

function Confirm-TeamsConnected {
    try { Get-CsTenant -ErrorAction Stop | Out-Null; return $true }
    catch { try { Connect-MicrosoftTeams -ErrorAction Stop | Out-Null; return $true }
            catch { Write-Error "Connect-MicrosoftTeams failed: $($_.Exception.Message)"; return $false } }
}
function Resolve-GroupId([string]$DisplayName) {
    try { (Get-MgGroup -Filter "displayName eq '$DisplayName'" -ErrorAction Stop | Select-Object -First 1).Id }
    catch { Write-Error "Graph group lookup failed for '$DisplayName': $($_.Exception.Message) (Connect-MgGraph -Scopes Group.Read.All)"; $null }
}
if (-not (Confirm-TeamsConnected)) { return }

$doWrite = $Commit.IsPresent -and -not $WhatIfPreference

# ---- Assign mode -----------------------------------------------------------
if ($AssignGroup) {
    if (-not $PolicyName) { Write-Error "-PolicyName is required with -AssignGroup."; return }
    $gid = Resolve-GroupId $AssignGroup
    if (-not $gid) { return }

    if ($doWrite -and $PSCmdlet.ShouldProcess("$AssignGroup ($gid)", "New-CsGroupPolicyAssignment $PolicyType='$PolicyName' Rank=$Rank")) {
        try {
            New-CsGroupPolicyAssignment -GroupId $gid -PolicyType $PolicyType -PolicyName $PolicyName -Rank $Rank -ErrorAction Stop
            Write-Host "ASSIGNED  '$PolicyName' -> '$AssignGroup' (Rank $Rank) as Meeting Assignment - <cohort> - Group" -ForegroundColor Green
        } catch { Write-Warning "Assignment failed: $($_.Exception.Message)" }
    } else {
        Write-Host "WOULD ASSIGN  '$PolicyName' ($PolicyType) -> '$AssignGroup' at Rank $Rank" -ForegroundColor Yellow
        Write-Host "  (dry-run: re-run with -Commit and without -WhatIf to apply)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ---- Report mode (always runs) --------------------------------------------
Write-Host "Current group policy assignments ($PolicyType):" -ForegroundColor Green
try {
    $ga = Get-CsGroupPolicyAssignment -PolicyType $PolicyType -ErrorAction Stop
    if ($ga) {
        $ga | ForEach-Object {
            $gn = try { (Get-MgGroup -GroupId $_.GroupId -ErrorAction Stop).DisplayName } catch { $_.GroupId }
            [pscustomobject]@{ Group=$gn; PolicyName=$_.PolicyName; Rank=$_.Rank; GroupId=$_.GroupId }
        } | Sort-Object Rank | Format-Table -AutoSize
    } else { Write-Host "  (none)" -ForegroundColor DarkGray }
} catch { Write-Host "  Could not read assignments: $($_.Exception.Message)" -ForegroundColor DarkYellow }

if ($SampleGroup) {
    Write-Host "`nEffective $PolicyType per member of '$SampleGroup':" -ForegroundColor Green
    $gid = Resolve-GroupId $SampleGroup
    if ($gid) {
        try {
            $members = Get-MgGroupMember -GroupId $gid -All -ErrorAction Stop
            $out = foreach ($m in $members) {
                $upn = $m.AdditionalProperties.userPrincipalName
                if (-not $upn) { continue }
                $eff = try { (Get-CsUserPolicyAssignment -Identity $upn -PolicyType $PolicyType -ErrorAction Stop | Select-Object -First 1).PolicyName } catch { "ERR: $($_.Exception.Message)" }
                [pscustomobject]@{ User=$upn; EffectivePolicy=$(if([string]::IsNullOrEmpty($eff)){'Global (default)'}else{$eff}) }
            }
            $out | Format-Table -AutoSize
        } catch { Write-Host "  Membership lookup failed: $($_.Exception.Message)" -ForegroundColor DarkYellow }
    }
}
Write-Host "`nReminder: lower Rank = higher precedence when a user is in multiple assigned groups." -ForegroundColor Cyan
