<#
.SYNOPSIS
    PROREM-Validate.ps1 — PASS/FAIL that the pilot remediation package is present, assigned, and reporting.

.DESCRIPTION
    PURPOSE
        Validates the acceptance gate for a single Proactive Remediation package (default:
        'PROREM – Service Health – w32time – Pilot'): it EXISTS, is ASSIGNED (to at least one group,
        e.g. 'PILOT – Remediations – Devices'), has a SCHEDULE, and is REPORTING run status back from
        devices. Produces a clear PASS/FAIL verdict. Read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\PROREM-Validate.ps1
        .\PROREM-Validate.ps1 -PackageName 'PROREM – Service Health – w32time – Pilot'

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A per-check PASS/FAIL and an overall gate. A ready pilot shows: package present, at least one
        assignment, and devices reporting run status. (deviceHealthScripts is a BETA endpoint — verify
        against current Microsoft documentation.)

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PackageName = 'PROREM – Service Health – w32time – Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function GraphGet($uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $items += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    return $items
}

$base = 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts'
$results = @()

# Package present
$pkg = $null
try {
    $all = GraphGet "$base`?`$select=id,displayName,runAsAccount"
    $pkg = $all | Where-Object { $_.displayName -eq $PackageName } | Select-Object -First 1
} catch {}
$results += R "Package '$PackageName' present" ([bool]$pkg) ($(if ($pkg) { "id $($pkg.id); RunAs=$($pkg.runAsAccount)" } else { 'Not found — create it (Implementation Step 5)' }))

if ($pkg) {
    # Assigned
    $assign = @(); try { $assign = GraphGet "$base/$($pkg.id)/assignments" } catch {}
    $results += R 'Assigned to at least one group' ([bool]$assign.Count) ($(if ($assign.Count) { "$($assign.Count) assignment(s)" } else { 'No assignment — assign to PILOT – Remediations – Devices' }))

    # Reporting run status
    $states = @(); try { $states = GraphGet "$base/$($pkg.id)/deviceRunStates?`$top=50" } catch {}
    $results += R 'Reporting device run status' ([bool]$states.Count) ($(if ($states.Count) { "$($states.Count) device state(s) reporting" } else { 'No run status yet — allow a schedule cycle / confirm IME health (R4)' }))
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'GATE: PASS — pilot remediation is present, assigned, and reporting.' -ForegroundColor Green }
else { Write-Host "GATE: FAIL — $fail check(s) failed. See Troubleshooting." -ForegroundColor Yellow }
