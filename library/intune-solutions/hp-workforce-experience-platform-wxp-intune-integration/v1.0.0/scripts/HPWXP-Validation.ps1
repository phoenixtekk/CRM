<#
.SYNOPSIS
    HPWXP-Validation.ps1 — validate assignment and per-device install state of the HP WXP agent app.
.DESCRIPTION
    PURPOSE
        Validates the HP Workforce Experience Platform (WXP) agent Intune Win32/LOB app is assigned to
        the intended group and installing on target devices. Confirms the app exists (matched by
        -AppName, default 'HP WXP Agent'), that it is assigned (optionally to a specific -GroupId), and
        reports each device's install state (Installed / Failed / Pending / Not applicable) from the
        app's deviceStatuses. Read-only. This validates the AGENT-VIA-INTUNE half of the integration;
        the tenant-connector half is checked by HPWXP-Discovery.ps1.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HPWXP-Validation.ps1 -AppName "HP WXP Agent - Pilot"
        Optional: -GroupId your-entra-group-object-id  (assert the app is assigned to this group)
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementApps.Read.All
    EXPECTED RESULTS
        A PASS/FAIL summary: app found, assigned (to -GroupId if supplied), and a per-device install-state
        table. PASS when the app is assigned and pilot devices report Installed.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$AppName = 'HP WXP Agent - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the HP WXP agent app (exact name first, then contains)
$app = $null
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'HP WXP')"
    $app = @($apps.value | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1)
    if (-not $app) { $app = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($AppName) -or $_.displayName -match 'HP WXP' } | Select-Object -First 1) }
    if ($app -is [array]) { $app = $app[0] }
} catch {}
$results.Add( (R 'HP WXP agent app found' ($null -ne $app) $(if ($app) { "'$($app.displayName)' (id $($app.id))" } else { "Not found: $AppName" })) )

if (-not $app) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — HP WXP agent app not found.' -ForegroundColor Yellow; return }

# Assignment
$groups = @(); $assigned = $false; $toGroup = $false
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'App is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
if ($GroupId) { $results.Add( (R 'Assigned to the specified group' $toGroup "GroupId=$GroupId") ) }

# Per-device install state
$deviceRows = @()
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    $deviceRows = @($stat.value | ForEach-Object {
        [pscustomobject]@{ Device = $_.deviceName; User = $_.userPrincipalName; State = $_.installState }
    })
} catch {}
$installed = @($deviceRows | Where-Object { $_.State -match 'installed' }).Count
$results.Add( (R 'At least one device reports Installed' ($installed -gt 0) "$installed device(s) Installed of $(@($deviceRows).Count)") )

$results | Format-Table -AutoSize
if ($deviceRows.Count) { Write-Host ''; Write-Host 'Per-device install state:' -ForegroundColor Cyan; $deviceRows | Format-Table -AutoSize }

$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — HP WXP agent app is assigned and installing.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }
