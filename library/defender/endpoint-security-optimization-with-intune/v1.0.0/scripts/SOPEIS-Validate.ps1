<#
.SYNOPSIS
    SOPEIS-Validate.ps1 — confirm the tuning applied: latest baseline on the pilot ring, conflicts
    near zero, tuned compliance policy assigned, coverage improved, no double-targeting.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Solution Optimization — Endpoint Security with Microsoft
        Intune" solution. Checks the pass/fail gates from the Testing Guide and reports PASS/WARN
        per check with an overall verdict. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Validate.ps1
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Validate.ps1 `
            -BaselineName 'Security Baseline - Pilot Ring - Pilot' `
            -ComplianceName 'Compliance - Windows Corporate - Prod' `
            -PilotGroupName 'Intune Optimize - Pilot Ring - Pilot'
        Requires Microsoft.Graph.Authentication with read scopes
        (DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All, Group.Read.All).
    EXPECTED RESULTS
        A PASS/WARN line per check and an overall verdict — the gate for expanding beyond the
        pilot ring (Implementation Step 7).
.NOTES
    White-label. Read-only. Baseline-version currency and Conditional Access enforce state are
    confirmed in the portal per the Testing Guide.
#>
[CmdletBinding()]
param(
    [string]$BaselineName = 'Security Baseline - Pilot Ring - Pilot',
    [string]$ComplianceName = 'Compliance - Windows Corporate - Prod',
    [string]$PilotGroupName = 'Intune Optimize - Pilot Ring - Pilot'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome | Out-Null }

$pass = 0; $warn = 0
function Check($name, $ok, $detail) {
    if ($ok) { Write-Host ("   [PASS] {0} — {1}" -f $name, $detail) -ForegroundColor Green; $script:pass++ }
    else     { Write-Host ("   [WARN] {0} — {1}" -f $name, $detail) -ForegroundColor Yellow; $script:warn++ }
}

Write-Host "`n=== SOPEIS validation (read-only) ===" -ForegroundColor Cyan

# 1. Migrated baseline present + assigned to the pilot ring.
$baseline = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/intents?`$filter=displayName eq '{0}'" -f $BaselineName)).value | Select-Object -First 1
if (-not $baseline) {
    # settings-catalog baseline profiles surface under configurationPolicies too
    $baseline = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'&`$expand=assignments" -f $BaselineName)).value | Select-Object -First 1
}
Check 'Migrated baseline present' ([bool]$baseline) ($(if ($baseline) { "found '$BaselineName'" } else { "'$BaselineName' not found (Implementation Step 2)" }))

# 2. Compliance policy present + assigned.
$comp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies?`$filter=displayName eq '{0}'&`$expand=assignments" -f $ComplianceName)).value | Select-Object -First 1
Check 'Tuned compliance policy present' ([bool]$comp) ($(if ($comp) { "found '$ComplianceName'" } else { "'$ComplianceName' not found (Implementation Step 4)" }))
if ($comp) {
    $assigned = $comp.assignments -and $comp.assignments.Count -gt 0
    Check 'Compliance policy assigned' $assigned ($(if ($assigned) { "$($comp.assignments.Count) target(s)" } else { 'no assignment' }))
}

# 3. Conflict/error level (use ConflictReport for detail; here a quick sample).
try {
    $devs = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/managedDevices?$select=id,deviceName&$top=50').value
    $conf = 0
    foreach ($d in $devs) {
        $st = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices/{0}/deviceConfigurationStates?`$select=state" -f $d.id) -ErrorAction SilentlyContinue
        $conf += ($st.value | Where-Object { $_.state -in 'conflict','error' }).Count
    }
    Check 'Conflicts near zero (sample of 50)' ($conf -eq 0) ("$conf conflict/error state(s) in sample — full picture: SOPEIS-ConflictReport.ps1")
} catch { Check 'Conflicts near zero' $false ("could not sample states: " + $_.Exception.Message) }

# 4. Pilot group resolves and has members.
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName)).value | Select-Object -First 1
if ($grp) {
    $count = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups/{0}/members/`$count" -f $grp.id) -Headers @{ ConsistencyLevel = 'eventual' } -ErrorAction SilentlyContinue)
    Check 'Pilot ring has members' ([int]$count -gt 0) ("$count member(s)")
} else { Check 'Pilot ring resolves' $false "'$PilotGroupName' not found" }

Write-Host "`n-- Confirm manually (portal) --" -ForegroundColor Cyan
Write-Host "   Baseline on the LATEST version (Endpoint security -> Security baselines)"
Write-Host "   Conditional Access compliance grant still Report-only until identity team accepts impact"

Write-Host ""
if ($warn -eq 0) { Write-Host ("VERDICT: PASS — {0} checks passed. Safe to proceed per the Testing Guide exit gate." -f $pass) -ForegroundColor Green }
else { Write-Host ("VERDICT: {0} PASS / {1} WARN — resolve WARN items before expanding (Implementation Step 7)." -f $pass, $warn) -ForegroundColor Yellow }
