<#
.SYNOPSIS
    CREDGUARD-Validation.ps1 — validate assignment and per-device applied state of a credential-protection profile.
.DESCRIPTION
    PURPOSE
        Validates that a Windows credential-theft-protection profile (Credential Guard, LSASS protection,
        WDigest, Remote Credential Guard, WinRM, or Windows LAPS) is assigned to the intended group and
        applied on target devices. Confirms the profile exists (Settings Catalog or template), that it is
        assigned, and reports each Windows device's applied state (Succeeded / Error / Not applied).
        Read-only. Validates the endpoint credential-protection controls only, not RDP host hardening or
        domain settings.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Validation.ps1 -ProfileName "Credential Guard - Pilot"
        Optional: -GroupId your-entra-group-object-id  (assert the profile is assigned to this group)
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL summary: profile found, assigned (to -GroupId if supplied), and a per-device
        applied-state table. PASS when the profile is assigned and pilot devices report Succeeded.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'Credential Guard - Pilot',
    [string]$GroupId
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Locate the profile by name (Settings Catalog first, then endpoint-protection template)
$profile = $null; $kind = 'none'
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; $kind = 'catalog'; break } }
    if (-not $profile) {
        $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
        foreach ($p in @($tpl.value)) { if ($p.displayName -eq $ProfileName) { $profile = $p; $kind = 'template'; break } }
    }
} catch {}
$pName = if ($profile) { if ($kind -eq 'catalog') { $profile.name } else { $profile.displayName } } else { $null }
$results.Add( (R 'Credential-protection profile found' ($null -ne $profile) $(if ($profile) { "'$pName' ($kind, id $($profile.id))" } else { "Not found: $ProfileName" })) )

if (-not $profile) { $results | Format-Table -AutoSize; Write-Host 'OVERALL: FAIL — profile not found.' -ForegroundColor Yellow; return }

# Assignment + per-device applied state (endpoint differs by profile kind)
$base = if ($kind -eq 'catalog') { "configurationPolicies/$($profile.id)" } else { "deviceConfigurations/$($profile.id)" }

$groups = @(); $assigned = $false; $toGroup = $false
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/assignments"
    $groups = @($asg.value | ForEach-Object { $_.target.groupId } | Where-Object { $_ })
    $assigned = @($asg.value).Count -gt 0
    if ($GroupId) { $toGroup = $groups -contains $GroupId }
} catch {}
$results.Add( (R 'Profile is assigned' $assigned "$(@($groups).Count) group assignment(s)") )
if ($GroupId) { $results.Add( (R 'Assigned to the specified group' $toGroup "GroupId=$GroupId") ) }

$deviceRows = @()
try {
    $statusPath = if ($kind -eq 'catalog') { "$base/deviceStatuses" } else { "$base/deviceStatuses" }
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$statusPath"
    $deviceRows = @($stat.value | ForEach-Object {
        [pscustomobject]@{ Device = $_.deviceDisplayName; User = $_.userPrincipalName; State = $_.status }
    })
} catch {}
$succeeded = @($deviceRows | Where-Object { $_.State -match 'success|compliant' }).Count
$results.Add( (R 'At least one device reports applied' ($succeeded -gt 0) "$succeeded device(s) Succeeded of $(@($deviceRows).Count)") )

$results | Format-Table -AutoSize
if ($deviceRows.Count) { Write-Host ''; Write-Host 'Per-device applied state:' -ForegroundColor Cyan; $deviceRows | Format-Table -AutoSize }

$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host "OVERALL: PASS — '$pName' is assigned and applying." -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed." -ForegroundColor Yellow }
