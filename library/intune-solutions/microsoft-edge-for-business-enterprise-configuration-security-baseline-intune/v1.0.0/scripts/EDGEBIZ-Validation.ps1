<#
.SYNOPSIS
    EDGEBIZ-Validation.ps1 — validate assignment and per-device applied state of the Microsoft Edge for
    Business configuration baseline (Intune, Windows).
.DESCRIPTION
    PURPOSE
        Validates the Settings Catalog Edge baseline profile ('Edge for Business - Baseline - Pilot') is
        assigned to the intended group and applied on target Windows devices. Confirms the profile exists,
        that it is assigned (and, if -GroupId is supplied, to that group), and reports each device's applied
        state (Succeeded / Error / Conflict / Not applied). Read-only. Validates the Windows Edge baseline
        profile only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDGEBIZ-Validation.ps1 -ProfileName "Edge for Business - Baseline - Pilot"
        Optional: -GroupId your-entra-group-object-id  (assert the profile is assigned to this group)
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL summary: profile found, assigned (to -GroupId if supplied), and a per-device applied-state
        table. PASS when the profile is assigned and pilot devices report Succeeded.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'Edge for Business - Baseline - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the Settings Catalog Edge baseline profile
$profile = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $s = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($s | ConvertTo-Json -Depth 25)") -match 'microsoft_edge.*passwordmanager') { $profile = $pol; break }
        }
    }
} catch {}
$results.Add( (R 'Edge baseline profile found' ($null -ne $profile) $(if ($profile) { "'$($profile.name)' (id $($profile.id))" } else { "Not found: $ProfileName" })) )

if (-not $profile) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — profile not found.' -ForegroundColor Yellow; return }

# Assignment
$groups = @(); $assigned = $false; $toGroup = $false
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'Profile is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
if ($GroupId) { $results.Add( (R 'Assigned to the specified group' $toGroup "GroupId=$GroupId") ) }

# Per-device applied state (settings-catalog uses deviceStatuses on configurationPolicies)
$deviceRows = @()
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/deviceStatuses"
    $deviceRows = @($stat.value | ForEach-Object {
        [pscustomobject]@{ Device = $_.deviceDisplayName; User = $_.userPrincipalName; State = $_.status }
    })
} catch {}
$succeeded = @($deviceRows | Where-Object { $_.State -match 'success|compliant' }).Count
$conflict  = @($deviceRows | Where-Object { $_.State -match 'conflict' }).Count
$results.Add( (R 'At least one device reports applied' ($succeeded -gt 0) "$succeeded Succeeded of $(@($deviceRows).Count); $conflict conflict(s)") )

$results | Format-Table -AutoSize
if ($deviceRows.Count) { Write-Host ''; Write-Host 'Per-device applied state:' -ForegroundColor Cyan; $deviceRows | Format-Table -AutoSize }
if ($conflict -gt 0) { Write-Host ''; Write-Host "NOTE: $conflict device(s) report CONFLICT — reconcile the Settings Catalog baseline with the Edge security baseline (Best Practices)." -ForegroundColor Yellow }

$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — Edge baseline is assigned and applying.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }
