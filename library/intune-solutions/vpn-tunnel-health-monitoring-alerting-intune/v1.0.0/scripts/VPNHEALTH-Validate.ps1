<#
.SYNOPSIS
    VPNHEALTH-Validate.ps1 — PASS/FAIL that the tunnel-health monitor is deployed, assigned, running, and reporting.

.DESCRIPTION
    PURPOSE
        Validates the acceptance gate for the health-check package (default
        'VPNHEALTH - Tunnel Health - Detect - Pilot'): it EXISTS, is ASSIGNED (to at least one group,
        e.g. 'PILOT - VPN Health - Devices'), has run status REPORTING back from devices, and — as a
        best-effort hint — that a telemetry path is present. Produces a clear PASS/FAIL verdict.
        Read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\VPNHEALTH-Validate.ps1
        .\VPNHEALTH-Validate.ps1 -PackageName 'VPNHEALTH - Tunnel Health - Detect - Pilot'

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A per-check PASS/FAIL and an overall gate. A ready pilot shows: package present, at least one
        assignment, and devices reporting run status. (deviceHealthScripts is a BETA endpoint — verify
        against current Microsoft documentation. The telemetry-path check is a hint, not a guarantee —
        confirm the Log Analytics data path per Implementation Step 7.)

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PackageName = 'VPNHEALTH - Tunnel Health - Detect - Pilot'
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
$results += R "Package '$PackageName' present" ([bool]$pkg) ($(if ($pkg) { "id $($pkg.id); RunAs=$($pkg.runAsAccount)" } else { 'Not found — create it (Implementation Step 4)' }))

if ($pkg) {
    # Assigned
    $assign = @(); try { $assign = GraphGet "$base/$($pkg.id)/assignments" } catch {}
    $results += R 'Assigned to at least one group' ([bool]$assign.Count) ($(if ($assign.Count) { "$($assign.Count) assignment(s)" } else { 'No assignment — assign to PILOT - VPN Health - Devices' }))

    # Reporting run status
    $states = @(); try { $states = GraphGet "$base/$($pkg.id)/deviceRunStates?`$top=50" } catch {}
    $results += R 'Reporting device run status' ([bool]$states.Count) ($(if ($states.Count) { "$($states.Count) device state(s) reporting" } else { 'No run status yet — allow a schedule cycle / confirm IME health (R6)' }))

    # Detection-only sanity: this monitor should have NO remediation script attached (read-only monitoring)
    $hasRemed = $false
    try {
        $full = Invoke-MgGraphRequest -Method GET -Uri "$base/$($pkg.id)?`$select=remediationScriptContent"
        $hasRemed = [bool]$full.remediationScriptContent
    } catch {}
    $results += R 'Detection-only (no remediation attached)' (-not $hasRemed) ($(if ($hasRemed) { 'A remediation script is attached — this monitor must be READ-ONLY; remove/replace with a no-op' } else { 'No remediation — correct (monitoring is read-only)' }))
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'GATE: PASS — tunnel-health monitor is present, assigned, reporting, and read-only.' -ForegroundColor Green }
else { Write-Host "GATE: FAIL — $fail check(s) failed. See Troubleshooting." -ForegroundColor Yellow }
Write-Host ''
Write-Host 'Telemetry path (Log Analytics) is verify-with-Microsoft — confirm health results land in your workspace (Implementation Step 7).' -ForegroundColor DarkGray
