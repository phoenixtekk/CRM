<#
.SYNOPSIS
    OPSADOPT-Validation.ps1 — read-only champion & ring COVERAGE diff: compares an expected champions roster (and intended wave membership) against actual Microsoft Graph champions-group and ring-group membership. Makes no changes.
.DESCRIPTION
    PURPOSE
        Proves adoption COVERAGE. Reads the actual members of the champions group and the adoption ring group
        from Microsoft Graph and diffs them against the expected roster CSV (one champion per in-scope area,
        plus intended ring members), flagging: areas with NO champion, champions missing from the group,
        expected ring members absent, and unexpected members present. Read-only.
    HOW TO RUN
        Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'
        .\OPSADOPT-Validation.ps1 -RosterCsv .\Champions-Roster.csv `
            -ChampionsGroup "Champions - Purview - Adoption" -RingGroup "Adoption Ring - Purview - Wave1"
        Roster CSV columns: Area, ChampionUpn, [RingMember] (Yes/No), [Wave]
        PowerShell 5.1+/7+; requires Microsoft.Graph. Read-only Graph scopes only.
    EXPECTED RESULTS
        A coverage report: every in-scope Area mapped to a champion present in the group (PASS), plus lists of
        missing champions, uncovered areas, absent expected ring members, and unexpected members. Full
        coverage with no gaps = pass.
.NOTES
    Purview — Adoption Program. Read-only (no Group.ReadWrite here). Champion coverage is a program KPI; the
    roster is the attestation baseline. Verify group names/scopes for your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RosterCsv,
    [Parameter(Mandatory=$true)][string]$ChampionsGroup,
    [string]$RingGroup,
    [string]$CsvPath
)

if (-not (Get-Command Get-MgGroup -ErrorAction SilentlyContinue)) {
    Write-Error "Microsoft.Graph not available. Install-Module Microsoft.Graph and Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All'."
    return
}
if (-not (Test-Path $RosterCsv)) { Write-Error "Roster CSV not found at $RosterCsv."; return }

$roster = Import-Csv $RosterCsv
if (-not ($roster | Get-Member -Name 'ChampionUpn' -MemberType NoteProperty)) {
    Write-Error "Roster CSV must have at least 'Area' and 'ChampionUpn' columns. Found: $(( $roster | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -join ', ')"
    return
}

function Get-GroupUpns {
    param([string]$Name)
    $g = Get-MgGroup -Filter "displayName eq '$Name'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $g) { Write-Warning "Group '$Name' not found."; return @() }
    @(Get-MgGroupMember -GroupId $g.Id -All | ForEach-Object { $_.AdditionalProperties.userPrincipalName } | Where-Object { $_ })
}

Write-Host "=== Champion & Ring Coverage - Purview - Adoption ===" -ForegroundColor Cyan
$champUpns = Get-GroupUpns -Name $ChampionsGroup
$ringUpns  = if ($RingGroup) { Get-GroupUpns -Name $RingGroup } else { @() }

$results = New-Object System.Collections.Generic.List[object]

# 1) Every in-scope area must have a champion, and that champion must be in the champions group.
$coveredAreas = 0
foreach ($row in $roster) {
    $area = [string]$row.Area; $upn = [string]$row.ChampionUpn
    if (-not $upn) { $results.Add([pscustomobject]@{ Check='AreaCoverage'; Item=$area; Status='FAIL'; Detail='No champion named for area' }); continue }
    if ($champUpns -contains $upn) { $coveredAreas++; $results.Add([pscustomobject]@{ Check='AreaCoverage'; Item=$area; Status='PASS'; Detail=$upn }) }
    else { $results.Add([pscustomobject]@{ Check='AreaCoverage'; Item=$area; Status='FAIL'; Detail="Champion $upn not in group '$ChampionsGroup'" }) }
}

# 2) Ring membership diff (if a ring is given): expected (RingMember=Yes) vs actual.
if ($RingGroup) {
    $expectedRing = @($roster | Where-Object { $_.PSObject.Properties.Name -contains 'RingMember' -and $_.RingMember -match '^(Yes|Y|True|1)$' } | ForEach-Object { [string]$_.ChampionUpn })
    foreach ($u in $expectedRing) { if ($ringUpns -notcontains $u) { $results.Add([pscustomobject]@{ Check='RingExpected'; Item=$u; Status='FAIL'; Detail="Expected in ring '$RingGroup' but absent" }) } }
    foreach ($u in $ringUpns)     { if ($expectedRing -notcontains $u) { $results.Add([pscustomobject]@{ Check='RingUnexpected'; Item=$u; Status='WARN'; Detail="In ring but not expected by roster" }) } }
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Status -eq 'FAIL').Count
$warn = @($results | Where-Object Status -eq 'WARN').Count
Write-Host ("Areas covered: {0}/{1}  |  FAIL: {2}  WARN: {3}" -f $coveredAreas, @($roster).Count, $fail, $warn) -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
if ($fail -eq 0) { Write-Host "Coverage PASS: every in-scope area has a champion in the group." -ForegroundColor Green }
else { Write-Warning "Coverage gaps present — close them before piloting the behavior in this wave." }

if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved coverage report to {0}" -f $CsvPath) -ForegroundColor Green }
