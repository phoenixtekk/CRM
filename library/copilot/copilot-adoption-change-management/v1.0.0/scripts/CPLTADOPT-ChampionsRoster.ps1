<#
.SYNOPSIS
    CPLTADOPT-ChampionsRoster.ps1 — build and check the Copilot champions network coverage.
.DESCRIPTION
    PURPOSE
        Read-only roster and coverage check for the champions network. Lists the members of
        'Copilot Champions Network - Tenant - Steady' with their department and job title, then reports
        which of your target departments have at least one champion and which are UNCOVERED — so you
        know exactly where to recruit. Peer-led adoption depends on per-department coverage; this makes
        the gaps visible.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPLTADOPT-ChampionsRoster.ps1
        Optional: -ChampionsGroup 'Copilot Champions Network - Tenant - Steady'
        Optional: -TargetDepartments 'Sales','Finance','IT','HR','Executive'
        Optional: -CsvPath .\cpltadopt-champions.csv
        Consents to Group.Read.All, User.Read.All, Directory.Read.All (read-only).
    EXPECTED RESULTS
        A champions roster (name, department, title) and a coverage summary listing covered and
        UNCOVERED target departments. No changes are made.
.NOTES
    White-label — Copilot. Read-only.
#>
[CmdletBinding()]
param(
    [string]$ChampionsGroup = 'Copilot Champions Network - Tenant - Steady',
    [string[]]$TargetDepartments = @('Sales','Finance','IT','HR','Executive'),
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','User.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== Copilot Champions Roster & Coverage — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$grp = Get-MgGroup -Filter "displayName eq '$ChampionsGroup'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $grp) {
    Write-Warning "Champions group '$ChampionsGroup' not found. Create it (Entra -> Groups -> New group) and add at least one champion per department (Implementation Step 3)."
    Disconnect-MgGraph | Out-Null
    return
}

$members = Get-MgGroupMember -GroupId $grp.Id -All -ErrorAction SilentlyContinue
$roster = @()
foreach ($m in $members) {
    $u = Get-MgUser -UserId $m.Id -Property 'displayName','userPrincipalName','department','jobTitle' -ErrorAction SilentlyContinue
    if (-not $u) { continue }
    $roster += [pscustomobject]@{ Name=$u.DisplayName; Upn=$u.UserPrincipalName; Department=$u.Department; Title=$u.JobTitle }
    Write-Host ("• {0,-26} {1,-16} {2}" -f $u.DisplayName, ($(if($u.Department){$u.Department}else{'<none>'})), $u.JobTitle)
}
Write-Host ("`nChampions: {0}" -f $roster.Count)

Write-Host "`n--- Department coverage ---" -ForegroundColor Cyan
$covered = @($roster | ForEach-Object { $_.Department } | Where-Object { $_ } | Select-Object -Unique)
foreach ($d in $TargetDepartments) {
    $has = $covered | Where-Object { $_ -like "*$d*" }
    if ($has) { Write-Host ("  COVERED   {0}" -f $d) -ForegroundColor Green }
    else      { Write-Host ("  UNCOVERED {0}  <- recruit a champion here" -f $d) -ForegroundColor Yellow }
}

if ($CsvPath) {
    $roster | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported roster to {0}" -f $CsvPath) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
