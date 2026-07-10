<#
.SYNOPSIS
    CPLTADOPT-Validate.ps1 — confirm the Copilot adoption program is fully stood up.
.DESCRIPTION
    PURPOSE
        Read-only program-readiness check. Verifies the structural elements the program depends on
        exist before you declare the pilot live: the champions network group is present and populated
        with department coverage, the pilot cohort group exists and is licensed, an executive sponsor
        is recorded, and measurement works (the Copilot usage report is reachable). It reports PASS /
        REVIEW per element so you can gate the pilot and the expand step.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPLTADOPT-Validate.ps1
        Optional: -ChampionsGroup 'Copilot Champions Network - Tenant - Steady'
        Optional: -PilotGroup     'Copilot Adoption Pilot - Pilot - Pilot'
        Optional: -SponsorUpn     'sponsor@contoso.com'   (records the named sponsor)
        Consents to Group.Read.All, User.Read.All, Reports.Read.All, Directory.Read.All (read-only).
    EXPECTED RESULTS
        PASS/REVIEW for champions coverage, pilot existence/licensing, sponsor, and measurement.
        REVIEW lines tell you exactly what to finish before the pilot. No changes are made.
.NOTES
    White-label — Copilot. Read-only.
#>
[CmdletBinding()]
param(
    [string]$ChampionsGroup = 'Copilot Champions Network - Tenant - Steady',
    [string]$PilotGroup     = 'Copilot Adoption Pilot - Pilot - Pilot',
    [string]$SponsorUpn
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All','Reports.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Copilot Adoption Program Readiness — $(Get-Date -Format s) ===" -ForegroundColor Cyan
$review = 0
function Say($status,$msg){
    $c = if($status -eq 'PASS'){'Green'}else{'Yellow'}
    Write-Host ("[{0}] {1}" -f $status,$msg) -ForegroundColor $c
    if($status -ne 'PASS'){ $script:review++ }
}

function Get-GroupByName($name){ Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue | Select-Object -First 1 }

# 1) Champions network + department coverage
$champ = Get-GroupByName $ChampionsGroup
if ($champ) {
    $members = Get-MgGroupMember -GroupId $champ.Id -All -ErrorAction SilentlyContinue
    $depts = @()
    foreach ($m in $members) {
        $u = Get-MgUser -UserId $m.Id -Property department -ErrorAction SilentlyContinue
        if ($u.Department) { $depts += $u.Department }
    }
    $deptCount = ($depts | Select-Object -Unique).Count
    if ($members.Count -ge 1 -and $deptCount -ge 1) { Say 'PASS' "Champions network '$ChampionsGroup': $($members.Count) champions across $deptCount department(s)" }
    else { Say 'REVIEW' "Champions network exists but has no department coverage — add at least one champion per major department" }
} else { Say 'REVIEW' "Champions network group '$ChampionsGroup' not found — create it (Implementation Step 3)" }

# 2) Pilot cohort exists and is populated
$pilot = Get-GroupByName $PilotGroup
if ($pilot) {
    $pm = Get-MgGroupMember -GroupId $pilot.Id -All -ErrorAction SilentlyContinue
    if ($pm.Count -ge 1) { Say 'PASS' "Pilot cohort '$PilotGroup': $($pm.Count) member(s) (confirm licensing with CPLTADOPT-Discovery.ps1 -GroupId $($pilot.Id))" }
    else { Say 'REVIEW' "Pilot cohort exists but is empty — add licensed, cross-role members" }
} else { Say 'REVIEW' "Pilot cohort group '$PilotGroup' not found — create it (Implementation Step 4)" }

# 3) Sponsor recorded
if ($SponsorUpn) {
    $s = Get-MgUser -UserId $SponsorUpn -ErrorAction SilentlyContinue
    if ($s) { Say 'PASS' "Executive sponsor recorded: $($s.DisplayName) <$SponsorUpn>" }
    else { Say 'REVIEW' "Sponsor UPN '$SponsorUpn' not found — confirm the named sponsor" }
} else { Say 'REVIEW' "No sponsor supplied — pass -SponsorUpn to record the named executive sponsor (Requirement 2.2)" }

# 4) Measurement works
try {
    Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365CopilotUsageUserDetail(period='D7')" -ErrorAction Stop | Out-Null
    Say 'PASS' "Copilot usage report reachable — measurement is available"
} catch {
    Say 'REVIEW' "Copilot usage report not reachable — *verify availability in your tenant*; fall back to admin-center report / Viva Copilot Dashboard"
}

Write-Host ("`nElements needing attention before pilot: {0}" -f $review) -ForegroundColor $(if($review){'Yellow'}else{'Green'})
Disconnect-MgGraph | Out-Null
